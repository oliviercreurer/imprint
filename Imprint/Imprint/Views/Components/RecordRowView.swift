import SwiftUI

/// A single row in the record list, showing the category icon,
/// the record name (underlined if it has a note), and the date.
/// Matches the Figma RecordEntry component pattern.
struct RecordRowView: View {

    let record: Record

    /// Whether to use dark-mode styling.
    var isDark: Bool = false

    /// Whether to show the date (Log shows dates, Queue does not).
    var showDate: Bool = true

    private var hasNote: Bool {
        if let note = record.note, !note.isEmpty { return true }
        return false
    }

    var body: some View {
        ImprintRecordEntry(
            name: record.name,
            icon: IconoirCatalog.icon(for: record.category?.iconName ?? "folder"),
            date: showDate ? formattedDate : nil,
            isNote: hasNote
        )
    }

    /// Formats the finished date as MM.DD.YY matching the Figma design.
    private var formattedDate: String? {
        guard let date = record.finishedOn else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yy"
        return formatter.string(from: date)
    }
}
