import SwiftUI

// MARK: - Icon Selector Component
// Figma: IconSelector (state: on/off)
// A tile for choosing an icon, used in the category editor icon picker.
// Container: vertical stack with label + icon tile
// Label: "Icon", Technical/Small (size/200 12pt), text/subtle
// Tile background: neutral/subtler
// Tile size: size/800 (48pt) square
// Tile corner radius: space/100 (8pt) — Figma uses space token for this radius
// Icon: size/400 (20pt)
//   off → icon/subtle
//   on  → icon/boldest (Figma calls it "icon/normal" which maps to boldest)

/// An icon selector tile matching the Figma IconSelector component.
struct ImprintIconSelector<Icon: View>: View {

    let label: String
    let icon: Icon
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
            Text(label)
                .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size200))
                .foregroundStyle(ImprintColors.textSubtle)

            icon
                .frame(width: ImprintSpacing.size400, height: ImprintSpacing.size400)
                .foregroundStyle(isSelected ? ImprintColors.iconBoldest : ImprintColors.iconSubtle)
                .frame(width: ImprintSpacing.size800, height: ImprintSpacing.size800)
                .background(ImprintColors.neutralSubtler)
                .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
        }
    }
}

// MARK: - Preview

#Preview("Icon Selector") {
    HStack(spacing: 16) {
        ImprintIconSelector(
            label: "Icon",
            icon: Image(systemName: "film"),
            isSelected: false
        )
        ImprintIconSelector(
            label: "Icon",
            icon: Image(systemName: "film"),
            isSelected: true
        )
    }
    .padding()
    .background(ImprintColors.neutralSubtlest)
}
