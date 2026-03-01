import SwiftUI
import SwiftData

/// The root view of the app. Shows Log or Queue view with custom header,
/// scrollable content, and a footer toolbar with search.
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: RecordType = .logged
    @State private var mediaFilter: MediaType?
    @State private var searchText = ""
    @State private var showingNewRecord = false
    @State private var selectedRecord: Record?

    /// Whether all month sections are currently expanded.
    @State private var allSectionsExpanded = true
    /// Incremented each time the user taps the expand/collapse-all button,
    /// so MonthSectionView can react via onChange.
    @State private var expandCollapseTrigger = 0

    private var isQueue: Bool { selectedTab == .queued }

    var body: some View {
        ZStack {
            // Background
            (isQueue ? ImprintColors.primary : ImprintColors.paper)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Divider
                Rectangle()
                    .fill(isQueue ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder)
                    .frame(height: 1)
                    .padding(.horizontal, 32)

                // Content
                RecordListView(
                    recordType: selectedTab,
                    mediaFilter: mediaFilter,
                    searchText: searchText,
                    isDark: isQueue,
                    allExpanded: allSectionsExpanded,
                    expandTrigger: expandCollapseTrigger,
                    onSelectRecord: { record in
                        selectedRecord = record
                    }
                )
            }

            // Footer overlay
            FooterToolbar(
                searchText: $searchText,
                isDark: isQueue,
                placeholder: isQueue ? "Search queue" : "Search log",
                allExpanded: allSectionsExpanded,
                onAdd: { showingNewRecord = true },
                onToggleExpand: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        allSectionsExpanded.toggle()
                        expandCollapseTrigger += 1
                    }
                }
            )
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showingNewRecord) {
            RecordFormView(initialRecordType: selectedTab)
        }
        .sheet(item: $selectedRecord) { record in
            RecordDetailView(record: record, isDark: isQueue)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(alignment: .bottom) {
                Text(selectedTab.label)
                    .font(ImprintFonts.pageTitle)
                    .foregroundStyle(isQueue ? ImprintColors.paper : ImprintColors.primary)

                Spacer()

                // Tab toggle button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = isQueue ? .logged : .queued
                        mediaFilter = nil
                        searchText = ""
                    }
                } label: {
                    ImprintLogo()
                        .fill(isQueue ? ImprintColors.paper : ImprintColors.primary, style: FillStyle(eoFill: true))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(isQueue ? 180 : 0))
                }
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
