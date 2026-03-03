import SwiftUI
import SwiftData

/// The root view of the app. Swipe horizontally to page between screens
/// (Log, Queue). The header, footer, and background stay fixed and
/// crossfade smoothly; only the content list slides between pages.
///
/// Settings is presented as an overlay sheet (z-index layers):
///   z4 – global @layal handle chip (always visible)
///   z3 – settings content (title + X + body)
///   z2 – settings blue background sheet
///   z1 – underlying page (header, list, footer — untouched)
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext

    /// All records, used to derive the flat ordered list for the detail pager.
    @Query(sort: \Record.createdAt, order: .reverse) private var allRecords: [Record]

    @AppStorage("disabledMediaTypes") private var disabledMediaTypesRaw = ""

    @State private var selectedTab: RecordType = .logged
    @State private var mediaFilter: MediaType?
    @State private var searchText = ""
    @State private var showingNewRecord = false
    @State private var showingAddFilm = false
    @State private var showingAddBook = false
    @State private var showingAddTV = false
    @State private var newRecordMediaType: MediaType = .film
    @State private var selectedRecord: Record?

    @State private var showingSettings = false

    /// Toast message shown briefly after moving a queue item to the log.
    @State private var toastMessage: String?
    @State private var toastVisible = false
    /// Name pending for toast after fullScreenCover finishes dismissing.
    @State private var pendingToastName: String?

    /// Whether all month sections are currently expanded.
    @State private var allSectionsExpanded = true
    /// Incremented each time expand/collapse changes,
    /// so MonthSectionView can react via onChange.
    @State private var expandCollapseTrigger = 0

    private var isQueue: Bool { selectedTab == .queued }

    /// Media types the user has enabled in Settings.
    private var enabledTypes: [MediaType] {
        enabledMediaTypes(disabledRaw: disabledMediaTypesRaw)
    }

    /// Flat ordered list of records for the current tab, matching RecordListView's filters.
    private var currentTabRecords: [Record] {
        let disabled = disabledMediaTypeSet(from: disabledMediaTypesRaw)
        var results = allRecords.filter { $0.recordType == selectedTab && !disabled.contains($0.mediaTypeRaw) }

        if let mediaFilter {
            results = results.filter { $0.mediaType == mediaFilter }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter { record in
                record.name.lowercased().contains(query)
                || (record.creatorLabel?.lowercased().contains(query) ?? false)
                || (record.note?.lowercased().contains(query) ?? false)
            }
        }

        return results
    }

    var body: some View {
        ZStack {

            // ── z1: Underlying page ──────────────────────────────
            // Background
            (isQueue ? ImprintColors.primary : ImprintColors.paper)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                VStack(spacing: 0) {
                    // Divider
                    Rectangle()
                        .fill(isQueue ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder)
                        .frame(height: 1)
                        .padding(.horizontal, 32)

                    // Content pages
                    TabView(selection: $selectedTab) {
                        ForEach(RecordType.allPages) { page in
                            RecordListView(
                                recordType: page,
                                mediaFilter: mediaFilter,
                                searchText: searchText,
                                enabledMediaTypes: enabledTypes,
                                isDark: page == .queued,
                                allExpanded: allSectionsExpanded,
                                expandTrigger: expandCollapseTrigger,
                                onSelectRecord: { record in
                                    selectedRecord = record
                                }
                            )
                            .tag(page)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }

            // Toast message
            VStack {
                Spacer()

                (Text(toastMessage ?? "").font(ImprintFonts.jetBrainsBold(12))
                 + Text(" added to Log").font(ImprintFonts.jetBrainsMedium(12)))
                    .foregroundStyle(ImprintColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ImprintColors.accentBlue)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
                    .scaleEffect(toastVisible ? 1.0 : 0.9)
                    .opacity(toastVisible ? 1.0 : 0.0)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 148)
            .allowsHitTesting(false)
            .zIndex(10)

            // Footer
            FooterToolbar(
                searchText: $searchText,
                isDark: isQueue,
                placeholder: isQueue ? "Search queue" : "Search log",
                onAdd: { mediaType in
                    if mediaType == .film {
                        showingAddFilm = true
                    } else if mediaType == .tv {
                        showingAddTV = true
                    } else if mediaType == .book {
                        showingAddBook = true
                    } else {
                        newRecordMediaType = mediaType
                        showingNewRecord = true
                    }
                }
            )
            .allowsHitTesting(!showingSettings)

            // ── z2: Settings background sheet ────────────────────
            ImprintColors.accentBlueBold
                .ignoresSafeArea()
                .opacity(showingSettings ? 1 : 0)
                .allowsHitTesting(false)
                .zIndex(20)

            // ── z3: Shared title bar + settings body ─────────────
            VStack(spacing: 0) {
                sharedTitleBar
                    .zIndex(1) // keep title above settings body

                if showingSettings {
                    SettingsView()
                        .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
            .zIndex(25)

            // ── z4: Global handle chip ───────────────────────────
            VStack {
                Spacer()
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showingSettings.toggle()
                        }
                    } label: {
                        Text("@layal")
                            .font(ImprintFonts.jetBrainsBold(14))
                            .foregroundStyle(ImprintColors.accentBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(showingSettings ? ImprintColors.paper : Color.clear))
                            .overlay(Capsule().strokeBorder(showingSettings ? ImprintColors.paper : ImprintColors.accentBlue, lineWidth: 2))
                    }
                    .frame(height: 48)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .ignoresSafeArea(edges: .bottom)
            .zIndex(30)

        }
        .animation(.easeInOut(duration: 0.35), value: selectedTab)
        .animation(.easeInOut(duration: 0.25), value: showingSettings)
        .environment(\.enabledMediaTypes, enabledTypes)
        .onChange(of: selectedTab) { _, _ in
            searchText = ""
        }
        .onChange(of: disabledMediaTypesRaw) { _, _ in
            // Clear the active filter if its type was just disabled
            if let mediaFilter, !enabledTypes.contains(mediaFilter) {
                self.mediaFilter = nil
            }
        }
        .sheet(isPresented: $showingAddFilm) {
            AddFilmView(initialRecordType: selectedTab)
        }
        .sheet(isPresented: $showingAddTV) {
            AddTVView(initialRecordType: selectedTab)
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView(initialRecordType: selectedTab)
        }
        .sheet(isPresented: $showingNewRecord) {
            RecordFormView(initialRecordType: selectedTab, initialMediaType: newRecordMediaType)
        }
        .fullScreenCover(item: $selectedRecord, onDismiss: {
            if let name = pendingToastName {
                pendingToastName = nil
                showToast(name)
            }
        }) { record in
            let records = currentTabRecords
            let idx = records.firstIndex(where: { $0.id == record.id }) ?? 0
            RecordDetailPager(records: records, initialIndex: idx) { name in
                pendingToastName = name
            }
        }
    }

    // MARK: - Toast

    private func showToast(_ name: String) {
        toastMessage = name
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            toastVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                toastVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                toastMessage = nil
            }
        }
    }

    // MARK: - Header (z1 — Log / Queue only, no title)

    private var header: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Spacer matching the title bar height so content aligns below it
            Color.clear.frame(height: 34)

            MediaFilterBar(selection: $mediaFilter, isDark: isQueue)
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 16)
    }

    // MARK: - Shared title bar (z3 — morphs between Log/Queue ↔ Settings)

    private var sharedTitleBar: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(showingSettings ? "Settings" : selectedTab.label)
                .font(ImprintFonts.pageTitle)
                .foregroundStyle(
                    showingSettings ? ImprintColors.paper
                    : isQueue ? ImprintColors.paper
                    : ImprintColors.primary
                )
                .contentTransition(.numericText())

            Spacer()

            if showingSettings {
                // Close button
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showingSettings = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ImprintColors.accentBlueLight)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            } else {
                // Dot page indicator — toggles Log / Queue
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        selectedTab = isQueue ? .logged : .queued
                    }
                } label: {
                    DotIndicator(currentPage: selectedTab, isDark: isQueue)
                        .frame(height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Record.self, inMemory: true)
}
