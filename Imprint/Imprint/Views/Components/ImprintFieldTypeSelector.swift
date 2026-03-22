import SwiftUI
import Iconoir

// MARK: - Field Type Selector Component
// Figma: FieldTypeSelector (state: on/off)
// A toggle pill for selecting a field type in the category editor.
// Background: neutral/boldest when selected, neutral/subtler when not
// Corner radius: radius/100 (8pt)
// Padding: space/300 (16pt)
// Icon: size/300 (16pt), icon/subtlest when selected, icon/bold when not
// Text: Technical/Medium (size/400 14pt), text/inverse when selected, text/boldest when not

/// A field type toggle pill matching the Figma FieldTypeSelector component.
struct ImprintFieldTypeSelector<Icon: View>: View {

    let fieldType: String
    let isSelected: Bool
    var icon: Icon
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: ImprintSpacing.space100) {
                icon
                    .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                    .foregroundStyle(isSelected ? ImprintColors.iconSubtlest : ImprintColors.iconBold)

                Text(fieldType)
                    .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size400))
                    .foregroundStyle(isSelected ? ImprintColors.textInverse : ImprintColors.textBoldest)
                    .lineLimit(1)
            }
            .padding(ImprintSpacing.space300)
            .background(isSelected ? ImprintColors.neutralBoldest : ImprintColors.neutralSubtler)
            .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Field Type Selector") {
    HStack(spacing: 8) {
        ImprintFieldTypeSelector(fieldType: "Field type", isSelected: false, icon: IconoirCatalog.icon(for: "align-left"))
        ImprintFieldTypeSelector(fieldType: "Field type", isSelected: true, icon: IconoirCatalog.icon(for: "align-left"))
    }
    .padding()
    .background(ImprintColors.neutralSubtlest)
}
