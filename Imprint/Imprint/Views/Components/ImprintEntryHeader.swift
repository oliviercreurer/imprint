import SwiftUI

// MARK: - Entry Header Component
// Figma: entry-header (node 120:4489)
// Displayed at the top of an entry's VIEW sheet.
//
// Two variants based on record type:
//   Queue: category pill (yellow/subtlest bg) + close button
//   Log:   category pill (cyan/subtlest bg)  + date (Technical/12pt/Medium, text/subtle) + close button
//
// Below the top row:
//   Entry title: Heading/H5 (Outfit SemiBold 18pt), text/boldest
//   Divider: 1pt, neutral/subtle

/// A header for entry detail/view sheets, matching the Figma entry-header component.
struct ImprintEntryHeader<Icon: View>: View {

    let title: String
    let categoryName: String
    let categoryIcon: Icon
    let recordType: RecordType
    var dateString: String? = nil
    var onClose: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space500) {
            // ── Top row: pill + trailing ──────────────────────
            HStack {
                // Category pill
                categoryPill

                Spacer()

                // Trailing: optional date + close button
                HStack(spacing: ImprintSpacing.space300) {
                    if recordType == .logged, let dateString {
                        Text(dateString)
                            .font(ImprintFonts.technical12Medium)
                            .foregroundStyle(ImprintColors.textSubtle)
                    }

                    closeButton
                }
            }

            // ── Entry title ──────────────────────────────────
            Text(title)
                .font(ImprintFonts.headingH5)
                .foregroundStyle(ImprintColors.textBoldest)

            // ── Divider ──────────────────────────────────────
            Rectangle()
                .fill(ImprintColors.neutralSubtle)
                .frame(height: 1)
        }
    }

    // MARK: - Category Pill

    private var categoryPill: some View {
        ImprintCategoryBadge(
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            recordType: recordType
        )
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ImprintColors.iconSubtle)
                .frame(
                    width: ImprintSpacing.size600,
                    height: ImprintSpacing.size600
                )
                .background(ImprintColors.neutralSubtler)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Entry Header") {
    VStack(spacing: 32) {
        ImprintEntryHeader(
            title: "Paper Moon",
            categoryName: "Film",
            categoryIcon: IconoirCatalog.icon(for: "cinema-old"),
            recordType: .queued,
            onClose: {}
        )

        ImprintEntryHeader(
            title: "Paper Moon",
            categoryName: "Film",
            categoryIcon: IconoirCatalog.icon(for: "cinema-old"),
            recordType: .logged,
            dateString: "03.22.26",
            onClose: {}
        )
    }
    .padding(.horizontal, 32)
    .background(ImprintColors.neutralSubtlest)
}
