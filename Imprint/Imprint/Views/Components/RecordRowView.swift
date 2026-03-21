import SwiftUI

/// A single row in the record list, showing a colored legend square,
/// the record name (underlined if it has a note), and the date.
struct RecordRowView: View {

    let record: Record

    /// Whether to use dark-mode styling (for Queue view).
    var isDark: Bool = false

    private var hasNote: Bool {
        if let note = record.note, !note.isEmpty { return true }
        return false
    }

    /// The category color for this record, with a fallback gray.
    private var categoryColor: Color {
        guard let hex = record.category?.colorHex else {
            return ImprintColors.secondary
        }
        return ColorDerivation.boldColor(from: hex)
    }

    var body: some View {
        HStack(spacing: 24) {
            HStack(spacing: 12) {
                // Colored legend square
                if isDark {
                    // Queue: bordered square with dark subtle fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            record.category != nil
                                ? ColorDerivation.darkSubtleColor(from: record.category!.colorHex)
                                : ImprintColors.darkSurfaceBg
                        )
                        .frame(width: 10, height: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(
                                    record.category != nil
                                        ? ColorDerivation.darkBoldColor(from: record.category!.colorHex)
                                        : ImprintColors.darkSurfaceBorder,
                                    lineWidth: 2
                                )
                        )
                } else {
                    // Log: solid filled square
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            record.category != nil
                                ? ColorDerivation.subtleColor(from: record.category!.colorHex)
                                : ImprintColors.secondary
                        )
                        .frame(width: 10, height: 10)
                }

                // Record name
                Text(record.name)
                    .font(ImprintFonts.recordName)
                    .foregroundStyle(isDark ? ImprintColors.paper : ImprintColors.primary)
                    .underline(hasNote)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)

            // Date
            if let date = record.finishedOn {
                Text(formattedDate(date))
                    .font(ImprintFonts.dateText)
                    .foregroundStyle(isDark ? ImprintColors.darkSecondary : ImprintColors.secondary)
            }
        }
    }

    /// Formats a date as DD.MM.YY matching the Figma design.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}
