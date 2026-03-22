import SwiftUI

// MARK: - Category Block Component
// Figma: category-block
// A row showing a category icon, name, log/queue counts, and a disclosure chevron.
// Layout: HStack with space/600 (32pt) gap between name area and trailing content
// Background: neutral/subtler, rounded 8pt, height 48pt
// Icon: 16×16, icon/subtle
// Name: Technical/14pt/Bold, neutral/boldest
// Log count: Technical/12pt/Bold, cyan/bold
// Queue count: Technical/12pt/Bold, yellow/bold
// Divider: 1pt wide, 12pt tall, icon/subtle
// Chevron: SF Symbol chevron.right, icon/subtle

/// A category row matching the Figma category-block component.
struct ImprintCategoryBlock<Icon: View>: View {

    let icon: Icon
    let name: String
    var logCount: Int? = nil
    var queueCount: Int? = nil
    var action: () -> Void = {}

    /// Whether to show the log/queue stats.
    private var showStats: Bool {
        logCount != nil || queueCount != nil
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: ImprintSpacing.space600) {
                // Icon + Category name
                HStack(spacing: ImprintSpacing.space100) {
                    icon
                        .frame(width: 16, height: 16)
                        .foregroundStyle(ImprintColors.iconSubtle)

                    Text(name)
                        .font(ImprintFonts.technical14Medium)
                        .foregroundStyle(ImprintColors.neutralBoldest)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Trailing: stats + chevron
                HStack(spacing: ImprintSpacing.space200) {
                    if showStats {
                        // Log count | Queue count
                        HStack(spacing: ImprintSpacing.space75) {
                            Text("\(logCount ?? 0)")
                                .font(ImprintFonts.technical12Bold)
                                .foregroundStyle(ImprintColors.cyanBold)

                            // Vertical divider
                            Rectangle()
                                .fill(ImprintColors.iconSubtle)
                                .frame(width: 1, height: 12)

                            Text("\(queueCount ?? 0)")
                                .font(ImprintFonts.technical12Bold)
                                .foregroundStyle(ImprintColors.yellowBold)
                        }
                    }

                    // Disclosure chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ImprintColors.iconSubtle)
                }
            }
            .padding(.horizontal, ImprintSpacing.space300)
            .padding(.vertical, ImprintSpacing.space100)
            .frame(height: ImprintSpacing.size800)
            .background(ImprintColors.neutralSubtler)
            .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Category Block") {
    VStack(spacing: 12) {
        ImprintCategoryBlock(
            icon: IconoirCatalog.icon(for: "movie"),
            name: "Film",
            logCount: 234,
            queueCount: 145
        )

        ImprintCategoryBlock(
            icon: IconoirCatalog.icon(for: "book-stack"),
            name: "Book",
            logCount: 89,
            queueCount: 42
        )

        ImprintCategoryBlock(
            icon: IconoirCatalog.icon(for: "music-double-note"),
            name: "Record",
            logCount: 56
        )

        ImprintCategoryBlock(
            icon: IconoirCatalog.icon(for: "movie"),
            name: "New Category"
        )
    }
    .padding(.horizontal, 32)
    .background(ImprintColors.neutralSubtlest)
}
