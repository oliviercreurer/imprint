import Foundation
import SwiftData

/// A single month section containing its records and media-type counts.
struct MonthGroup: Identifiable {
    let id: String          // e.g. "2025-04"
    let monthName: String   // e.g. "April"
    let year: Int
    let records: [Record]

    /// Number of records per media type, for the bar chart.
    var mediaCounts: [(type: MediaType, count: Int)] {
        MediaType.allCases.compactMap { type in
            let count = records.filter { $0.mediaType == type }.count
            return count > 0 ? (type, count) : nil
        }
    }

    var totalCount: Int { records.count }
}

/// Groups records by the month of their `finishedOn` date, sorted newest first.
///
/// Records without a `finishedOn` date are placed in an "Undated" group at the end.
func groupRecordsByMonth(_ records: [Record]) -> [MonthGroup] {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"

    var grouped: [String: (month: String, year: Int, records: [Record])] = [:]

    for record in records {
        guard let date = record.finishedOn else { continue }
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let year = comps.year, let month = comps.month else { continue }

        let key = String(format: "%04d-%02d", year, month)

        if grouped[key] == nil {
            let monthDate = calendar.date(from: comps) ?? date
            let monthName = formatter.string(from: monthDate)
            grouped[key] = (month: monthName, year: year, records: [])
        }
        grouped[key]?.records.append(record)
    }

    return grouped
        .sorted { $0.key > $1.key }
        .map { MonthGroup(id: $0.key, monthName: $0.value.month, year: $0.value.year, records: $0.value.records) }
}
