import SwiftUI
import SwiftData

/// The root view of the app. Swipe horizontally to page between screens
/// (Log, Queue). The header, footer, and background stay fixed and
/// crossfade smoothly; only the content list slides between pages.
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext

    /// All records, used to derive the flat ordered list for the detail pager.
    @Query(sort: \Record.createdAt, order: .reverse) private var allRecords: [Record]

    @State private var selectedTab: RecordType = .logged
    @State private var mediaFilter: MediaType?
    @State private var searchText = ""
    @State private var showingNewRecord = false
    @State private var showingAddFilm = false
    @State private var showingAddBook = false
    @State private var showingAddTV = false
    @State private var newRecordMediaType: MediaType = .film
    @State private var selectedRecord: Record?

    /// Toast message shown briefly after moving a queue item to the log.
    @State private var toastMessage: String?

    /// Whether all month sections are currently expanded.
    @State private var allSectionsExpanded = true
    /// Incremented each time expand/collapse changes,
    /// so MonthSectionView can react via onChange.
    @State private var expandCollapseTrigger = 0

    private var isQueue: Bool { selectedTab == .queued }

    /// Flat ordered list of records for the current tab, matching RecordListView's filters.
    private var currentTabRecords: [Record] {
        var results = allRecords.filter { $0.recordType == selectedTab }

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
            // Animated background
            (isQueue ? ImprintColors.primary : ImprintColors.paper)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header — crossfades theme on tab change
                header

                // Divider
                Rectangle()
                    .fill(isQueue ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder)
                    .frame(height: 1)
                    .padding(.horizontal, 32)

                // Only the content area pages via TabView
                TabView(selection: $selectedTab) {
                    ForEach(RecordType.allPages) { page in
                        RecordListView(
                            recordType: page,
                            mediaFilter: mediaFilter,
                            searchText: searchText,
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

            // Toast message
            if let message = toastMessage {
                VStack {
                    Spacer()

                    Text(message)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(isQueue ? ImprintColors.paper : ImprintColors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isQueue ? ImprintColors.darkSurfaceBg : ImprintColors.searchBg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    isQueue ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder,
                                    lineWidth: 2
                                )
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(.bottom, 130)
                .allowsHitTesting(false)
                .zIndex(10)
            }

            // Fixed footer — crossfades theme on tab change
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
        }
        .animation(.easeInOut(duration: 0.35), value: selectedTab)
        .onChange(of: selectedTab) { _, _ in
            mediaFilter = nil
            searchText = ""
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
        .fullScreenCover(item: $selectedRecord) { record in
            let records = currentTabRecords
            let idx = records.firstIndex(where: { $0.id == record.id }) ?? 0
            RecordDetailPager(records: records, initialIndex: idx) { name in
                // Small delay so the toast appears after the cover dismisses
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showToast("\(name) moved to log")
                }
            }
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        withAnimation(.easeOut(duration: 0.3)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                toastMessage = nil
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(alignment: .bottom) {
                Text(selectedTab.label)
                    .font(ImprintFonts.pageTitle)
                    .foregroundStyle(isQueue ? ImprintColors.paper : ImprintColors.primary)
                    .contentTransition(.numericText())

                Spacer()

                DotIndicator(currentPage: selectedTab, isDark: isQueue)
            }

            MediaFilterBar(selection: $mediaFilter, isDark: isQueue)
        }
        .padding(.horizontal, 32)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Record.self, inMemory: true)
}
