import SwiftUI
import SwiftData

/// Displays a filtered, sorted list of records for a given record type.
/// For logged records, groups them by month with collapsible sections and bar charts.
/// For queued records, shows a flat list.
struct RecordListView: View {

    let recordType: RecordType
    let categoryFilter: Category?
    let searchText: String
    let isDark: Bool
    let allExpanded: Bool
    let expandTrigger: Int
    let onSelectRecord: (Record) -> Void

    @Query private var allRecords: [Record]
    @Query(filter: #Predicate<Category> { $0.isEnabled }, sort: \Category.sortOrder)
    private var enabledCategories: [Category]

    @Environment(\.modelContext) private var modelContext

    init(
        recordType: RecordType,
        categoryFilter: Category?,
        searchText: String,
        isDark: Bool = false,
        allExpanded: Bool = true,
        expandTrigger: Int = 0,
        onSelectRecord: @escaping (Record) -> Void
    ) {
        self.recordType = recordType
        self.categoryFilter = categoryFilter
        self.searchText = searchText
        self.isDark = isDark
        self.allExpanded = allExpanded
        self.expandTrigger = expandTrigger
        self.onSelectRecord = onSelectRecord

        let typeRaw = recordType.rawValue
        _allRecords = Query(
            filter: #Predicate<Record> { record in
                record.recordTypeRaw == typeRaw
            },
            sort: \.createdAt,
            order: .reverse
        )
    }

    /// Records after applying category filter, enabled categories, and search text.
    private var filteredRecords: [Record] {
        let enabledIds = Set(enabledCategories.map(\.persistentModelID))
        var results = allRecords.filter { record in
            guard let cat = record.category else { return false }
            return enabledIds.contains(cat.persistentModelID)
        }

        if let categoryFilter {
            let filterId = categoryFilter.persistentModelID
            results = results.filter { $0.category?.persistentModelID == filterId }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter { record in
                record.name.lowercased().contains(query)
                || (record.firstTextFieldValue?.lowercased().contains(query) ?? false)
                || (record.note?.lowercased().contains(query) ?? false)
            }
        }

        return results
    }

    var body: some View {
        Group {
            if filteredRecords.isEmpty {
                emptyState
            } else if recordType == .logged {
                loggedContent
            } else {
                queuedContent
            }
        }
    }

    // MARK: - Logged View (Monthly Sections)

    private var loggedContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                let groups = groupRecordsByMonth(filteredRecords)

                ForEach(groups) { group in
                    MonthSectionView(
                        group: group,
                        showBarChart: categoryFilter == nil,
                        searchText: searchText,
                        allExpanded: allExpanded,
                        expandTrigger: expandTrigger,
                        isDark: isDark
                    ) { record in
                        onSelectRecord(record)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .padding(.bottom, 220) // Space for footer
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Queued View (Flat List)

    private var queuedContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(Array(filteredRecords.enumerated()), id: \.element.persistentModelID) { index, record in
                    Button {
                        onSelectRecord(record)
                    } label: {
                        RecordRowView(record: record, isDark: isDark)
                    }
                    .buttonStyle(.plain)
                    .staggeredAppearance(index: index)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .padding(.bottom, 220)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Text(recordType == .logged ? "No logged records yet" : "No queued records yet")
                .font(ImprintFonts.jetBrainsMedium(16))
                .foregroundStyle(ImprintColors.secondaryText(isDark))

            Text(recordType == .logged
                ? "Tap + to log something you've done."
                : "Tap + to save something for later.")
                .font(ImprintFonts.jetBrainsRegular(14))
                .foregroundStyle(ImprintColors.secondaryText(isDark))
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 48)
    }
}
