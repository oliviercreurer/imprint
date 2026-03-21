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

    /// All enabled categories for filtering.
    @Query(filter: #Predicate<Category> { $0.isEnabled }, sort: \Category.sortOrder)
    private var enabledCategories: [Category]

    @AppStorage("appearanceMode") private var appearanceMode = "light"

    @State private var selectedTab: RecordType = .logged
    @State private var categoryFilter: Category?
    @State private var searchText = ""
    /// Debounced copy of searchText — drives filtering after a short delay.
    @State private var debouncedSearchText = ""
    /// Task handle for the debounce timer so we can cancel on each keystroke.
    @State private var debounceTask: Task<Void, Never>?
    @State private var showingNewRecord = false
    @State private var newRecordCategory: Category?
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
    private var isDark: Bool { appearanceMode == "dark" }

    /// Flat ordered list of records for the current tab, matching RecordListView's filters.
    private var currentTabRecords: [Record] {
        let enabledIds = Set(enabledCategories.map(\.persistentModelID))
        var results = allRecords.filter { record in
            guard record.recordType == selectedTab else { return false }
            guard let cat = record.category else { return false }
            return enabledIds.contains(cat.persistentModelID)
        }

        if let categoryFilter {
            let filterId = categoryFilter.persistentModelID
            results = results.filter { $0.category?.persistentModelID == filterId }
        }

        if !debouncedSearchText.isEmpty {
            let query = debouncedSearchText.lowercased()
            results = results.filter { record in
                record.name.lowercased().contains(query)
                || (record.firstTextFieldValue?.lowercased().contains(query) ?? false)
                || (record.note?.lowercased().contains(query) ?? false)
            }
        }

        return results
    }

    var body: some View {
        ZStack {

            // ── z1: Underlying page ──────────────────────────────
            // Background
            (isDark ? ImprintColors.primary : ImprintColors.paper)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                VStack(spacing: 0) {
                    // Content pages
                    TabView(selection: $selectedTab) {
                        ForEach(RecordType.allPages) { page in
                            RecordListView(
                                recordType: page,
                                categoryFilter: categoryFilter,
                                searchText: debouncedSearchText,
                                isDark: isDark,
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
                isDark: isDark,
                onAdd: { category in
                    newRecordCategory = category
                    showingNewRecord = true
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
        .onChange(of: searchText) { _, newValue in
            debounceTask?.cancel()
            if newValue.isEmpty {
                // Clear immediately so the list snaps back without delay
                debouncedSearchText = ""
            } else {
                debounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    guard !Task.isCancelled else { return }
                    debouncedSearchText = newValue
                }
            }
        }
        .onChange(of: selectedTab) { _, _ in
            searchText = ""
            debouncedSearchText = ""
            debounceTask?.cancel()
        }
        .sheet(isPresented: $showingNewRecord) {
            RecordFormView(
                initialRecordType: selectedTab,
                initialCategory: newRecordCategory
            )
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
        .onAppear {
            // Seed default categories on first launch
            CategorySeeder.seedIfNeeded(context: modelContext)
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

    @FocusState private var isSearchFocused: Bool

    // MARK: - Header (z1 — Log / Queue only, no title)

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Spacer matching the title bar height + 12pt breathing room below title
            Color.clear.frame(height: 46)

            MediaFilterBar(selection: $categoryFilter, isDark: isDark)

            // Search bar
            HStack(spacing: 8) {
                TextField("", text: $searchText, prompt:
                    Text(isQueue ? "Search queue" : "Search log")
                        .font(ImprintFonts.searchPlaceholder)
                        .foregroundStyle(isDark ? ImprintColors.darkSecondary : ImprintColors.secondary)
                )
                .font(ImprintFonts.searchPlaceholder)
                .foregroundStyle(isDark ? ImprintColors.paper : ImprintColors.primary)
                .focused($isSearchFocused)
                .submitLabel(.done)
                .onSubmit { isSearchFocused = false }

                // Clear / dismiss button when focused or has text
                if isSearchFocused || !searchText.isEmpty {
                    Button {
                        if searchText.isEmpty {
                            isSearchFocused = false
                        } else {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: searchText.isEmpty ? "keyboard.chevron.compact.down" : "xmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isDark ? ImprintColors.darkSecondary : ImprintColors.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(isDark ? ImprintColors.darkSurfaceBg : ImprintColors.searchBg)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder,
                        lineWidth: 2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
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
                    : isDark ? ImprintColors.paper
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
                    DotIndicator(currentPage: selectedTab, isDark: isDark)
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
        .modelContainer(for: [Category.self, FieldDefinition.self, FieldValue.self, Record.self], inMemory: true)
}
