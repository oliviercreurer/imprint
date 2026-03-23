import SwiftUI

// MARK: - Entry Item Component
// Figma: entry-item (node 120:4524)
// Renders a single field value on an entry's detail/view sheet.
//
// Variants:
//   generic  — Label (Body/14pt/SemiBold, text/subtler) above Value (Body/16/Regular, text/bolder).
//              Used for short text, long text, number, country, slider, date.
//   checkbox — Row with neutral/subtler bg, rounded 8pt, padding 16pt.
//              Label (Body/16/Medium, text/boldest) left, toggle right.
//   url      — Label (Body/14pt/SemiBold, text/subtler) above link (Body/16/Regular, text/link, underlined).
//   image    — Label (Body/14pt/SemiBold, text/subtler) above a square container
//              with rounded corners (12pt), image centered preserving aspect ratio,
//              background color derived from the image's dominant color.

/// Displays a single field value in an entry's detail view.
enum ImprintEntryItemStyle {
    case generic
    case checkbox
    case url
    case image
}

struct ImprintEntryItem: View {

    let label: String
    let style: ImprintEntryItemStyle

    // Values (use whichever applies to the style)
    var textValue: String? = nil
    var boolValue: Bool? = nil
    var urlString: String? = nil
    var image: UIImage? = nil

    var body: some View {
        switch style {
        case .generic:
            genericItem
        case .checkbox:
            checkboxItem
        case .url:
            urlItem
        case .image:
            imageItem
        }
    }

    // MARK: - Generic (text/number/country/date/slider)

    private var genericItem: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
            fieldLabel

            Text(textValue ?? "")
                .font(ImprintFonts.body16Regular)
                .lineSpacing(ImprintFonts.body16LineSpacing)
                .foregroundStyle(ImprintColors.textBolder)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Checkbox

    private var checkboxItem: some View {
        HStack(spacing: ImprintSpacing.space200) {
            Text(label)
                .font(ImprintFonts.body16Medium)
                .lineSpacing(ImprintFonts.body16LineSpacing)
                .foregroundStyle(ImprintColors.textBoldest)
                .frame(maxWidth: .infinity, alignment: .leading)

            ImprintToggle(isOn: .constant(boolValue ?? false))
                .allowsHitTesting(false)
        }
        .padding(ImprintSpacing.space300)
        .background(ImprintColors.neutralSubtler)
        .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
    }

    // MARK: - URL

    private var urlItem: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
            fieldLabel

            if let urlString, let url = URL(string: urlString) {
                Link(destination: url) {
                    Text(urlString)
                        .font(ImprintFonts.body16Regular)
                        .lineSpacing(ImprintFonts.body16LineSpacing)
                        .foregroundStyle(ImprintColors.textLink)
                        .underline(color: ImprintColors.textLink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(urlString ?? "")
                    .font(ImprintFonts.body16Regular)
                    .lineSpacing(ImprintFonts.body16LineSpacing)
                    .foregroundStyle(ImprintColors.textLink)
                    .underline(color: ImprintColors.textLink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Image

    private var imageItem: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space100) {
            fieldLabel

            GeometryReader { geo in
                let side = geo.size.width
                ZStack {
                    // Background — derived from image's dominant color
                    RoundedRectangle(cornerRadius: ImprintSpacing.radius200)
                        .fill(imageBackgroundColor)

                    // Image centered, preserving aspect ratio
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: side, maxHeight: side)
                    }
                }
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius200))
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }

    private var imageBackgroundColor: Color {
        if let image {
            return image.dominantBackgroundColor()
        }
        return ImprintColors.neutralSubtler
    }

    // MARK: - Shared

    private var fieldLabel: some View {
        Text(label)
            .font(ImprintFonts.body14SemiBold)
            .foregroundStyle(ImprintColors.textSubtler)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Entry Items") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ImprintEntryItem(
                label: "Director",
                style: .generic,
                textValue: "Peter Bogdanovich"
            )

            ImprintEntryItem(
                label: "With Layal?",
                style: .checkbox,
                boolValue: true
            )

            ImprintEntryItem(
                label: "Link",
                style: .url,
                urlString: "https://www.google.com"
            )

            ImprintEntryItem(
                label: "Image",
                style: .image,
                image: UIImage(systemName: "photo")
            )
        }
        .padding(.horizontal, 32)
    }
    .background(ImprintColors.neutralSubtlest)
}
