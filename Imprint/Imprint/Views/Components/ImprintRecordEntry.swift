import SwiftUI

// MARK: - Record Entry Component
// Figma: RecordEntry (date: bool, note: bool)
// A single record row displaying category icon, record name, and optional date.
// Layout: HStack with space/500 (24pt) gap between name area and date
// Icon: size/300 (16pt), neutral/bold color
// Name font: Technical/Medium (JetBrains Mono Medium, size/400 14pt, height/300 18pt)
// Name color: neutral/boldest
// Date font: same as name
// Date color: neutral/bold
// Note variant: name is underlined (decoration: underline)

/// A record entry row matching the Figma RecordEntry component.
struct ImprintRecordEntry<Icon: View>: View {

    let name: String
    let icon: Icon
    var date: String? = nil
    var isNote: Bool = false

    var body: some View {
        HStack(spacing: ImprintSpacing.space500) {
            // Icon + Name
            HStack(spacing: ImprintSpacing.space100) {
                icon
                    .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                    .foregroundStyle(ImprintColors.neutralBold)

                Text(name)
                    .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size400))
                    .foregroundStyle(ImprintColors.neutralBoldest)
                    .underline(isNote)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Date
            if let date {
                Text(date)
                    .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size400))
                    .foregroundStyle(ImprintColors.neutralBold)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }
}

// MARK: - Preview

#Preview("Record Entries") {
    VStack(spacing: 12) {
        ImprintRecordEntry(
            name: "Paper Moon",
            icon: Image(systemName: "film"),
            date: "04.06.25"
        )
        ImprintRecordEntry(
            name: "Paper Moon",
            icon: Image(systemName: "film"),
            date: "04.06.25",
            isNote: true
        )
        ImprintRecordEntry(
            name: "Paper Moon",
            icon: Image(systemName: "film")
        )
    }
    .padding()
    .background(ImprintColors.neutralSubtlest)
}
