import SwiftUI

// MARK: - Category Badge
// Figma: entry-type-label (node 120:5311)
// A pill showing a category icon + name, tinted by record type.
//
// Layout:
//   Height: size/600 (32pt)
//   Padding: space/100 (10pt)
//   Gap: space/75 (6pt)
//   Icon: size/300 (16pt), icon/bolder
//   Text: Technical/12pt/Bold, text/bolder
//   Corner radius: radius/50 (4pt)
//
// Background varies by record type:
//   Log:   cyan/subtlest
//   Queue: yellow/subtlest

/// A badge showing a category icon + name, tinted by record type.
struct ImprintCategoryBadge<Icon: View>: View {

    let categoryName: String
    let categoryIcon: Icon
    let recordType: RecordType

    var body: some View {
        HStack(spacing: ImprintSpacing.space75) {
            categoryIcon
                .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                .foregroundStyle(ImprintColors.iconBolder)

            Text(categoryName)
                .font(ImprintFonts.technical12Bold)
                .foregroundStyle(ImprintColors.textBolder)
        }
        .padding(ImprintSpacing.space100)
        .frame(height: ImprintSpacing.size600)
        .background(pillBackground)
        .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius50))
    }

    private var pillBackground: Color {
        switch recordType {
        case .logged: ImprintColors.cyanSubtlest
        case .queued: ImprintColors.yellowSubtlest
        }
    }
}

// MARK: - Preview

#Preview("Category Badge") {
    HStack(spacing: 16) {
        ImprintCategoryBadge(
            categoryName: "Film",
            categoryIcon: IconoirCatalog.icon(for: "cinema-old"),
            recordType: .logged
        )

        ImprintCategoryBadge(
            categoryName: "Film",
            categoryIcon: IconoirCatalog.icon(for: "cinema-old"),
            recordType: .queued
        )
    }
    .padding(32)
    .background(ImprintColors.neutralSubtlest)
}
