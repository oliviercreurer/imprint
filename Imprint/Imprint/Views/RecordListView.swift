import SwiftUI
import SwiftData

/// Displays a filtered, sorted list of records for a given record type.
/// For logged records, groups them by month with collapsible sections and bar charts.
/// For queued records, shows a flat list.
struct RecordListView: View {

    let recordType: RecordType
    let mediaFilter: MediaType?
    let searchText: String
    let enabledMediaTypes: [MediaType]
    let isDark: Bool
    let allExpanded: Bool
    let expandTrigger: Int
    let onSelectRecord: (Record) -> Void

    @Query private var allRecords: [Record]
    @Environment(\.modelContext) private var modelContext

    init(
        recordType: RecordType,
        mediaFilter: MediaType?,
        searchText: String,
        enabledMediaTypes: [MediaType] = MediaType.allCases.map { $0 },
        isDark: Bool = false,
        allExpanded: Bool = true,
        expandTrigger: Int = 0,
        onSelectRecord: @escaping (Record) -> Void
    ) {
        self.recordType = recordType
        self.mediaFilter = mediaFilter
        self.searchText = searchText
        self.enabledMediaTypes = enabledMediaTypes
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

    /// Records after applying media type filter, enabled types, and search text.
    private var filteredRecords: [Record] {
        // Exclude disabled media types
        let enabledRaw = Set(enabledMediaTypes.map(\.rawValue))
        var results = allRecords.filter { enabledRaw.contains($0.mediaTypeRaw) }

        if let mediaFilter {
            let filterRaw = mediaFilter.rawValue
            results = results.filter { $0.mediaTypeRaw == filterRaw }
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
                        showBarChart: mediaFilter == nil,
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
                ? "Tap + to log something you've watched, read, or listened to."
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
