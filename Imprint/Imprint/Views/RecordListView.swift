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
            LazyVStack(alignment: .leading, spacing: ImprintSpacing.space300) {
                let groups = groupRecordsByMonth(filteredRecords)

                ForEach(groups) { group in
                    MonthSectionView(
                        group: group,
                        searchText: searchText,
                        allExpanded: allExpanded,
                        expandTrigger: expandTrigger,
                        isDark: isDark
                    ) { record in
                        onSelectRecord(record)
                    }
                }
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.top, ImprintSpacing.space300)
            .padding(.bottom, footerClearance)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Queued View (Flat List)

    private var queuedContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: ImprintSpacing.space200) {
                ForEach(Array(filteredRecords.enumerated()), id: \.element.persistentModelID) { index, record in
                    Button {
                        onSelectRecord(record)
                    } label: {
                        RecordRowView(record: record, isDark: isDark, showDate: false)
                    }
                    .buttonStyle(.plain)
                    .staggeredAppearance(index: index)
                }
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.top, ImprintSpacing.space300)
            .padding(.bottom, footerClearance)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: ImprintSpacing.size200) {
            Spacer()

            Text(recordType == .logged ? "No logged records yet" : "No queued records yet")
                .font(ImprintFonts.body16Medium)
                .lineSpacing(ImprintFonts.body16LineSpacing)
                .foregroundStyle(ImprintColors.textSubtler)

            Text(recordType == .logged
                ? "Tap + to log something you've done."
                : "Tap + to save something for later.")
                .font(ImprintFonts.body14Medium)
                .foregroundStyle(ImprintColors.textSubtler)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, ImprintSpacing.size800)
    }

    // MARK: - Constants

    /// Bottom padding to clear the floating footer toolbar.
    private var footerClearance: CGFloat { 220 }
}
