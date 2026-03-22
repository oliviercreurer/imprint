import SwiftUI
import Iconoir

// MARK: - Field Component
// Figma: Field (state: locked/optional/required)
// A row displaying a field name with an icon, used in record detail views.
// Background: neutral/subtler (#F2F0E5 light)
// Height: size/800 (48pt)
// Corner radius: radius/100 (8pt)
// Padding: space/300 horizontal (16pt), space/100 vertical (8pt)
// Icon: size/300 (16pt), icon/subtle color
// Font: Technical/Medium (JetBrains Mono Medium, size/400 14pt, height/300 18pt)
// States:
//   locked  → full row at stateDisabled opacity (0.4)
//   optional → lock icon on right, red/subtle warning icon
//   required → "Required" label + warning icon on right

/// A field row component matching the Figma Field variants.
struct ImprintField<Icon: View>: View {

    let fieldName: String
    var icon: Icon
    var state: FieldState = .optional

    enum FieldState {
        case locked
        case optional
        case required
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: ImprintSpacing.space600) {
            // Left: icon + field name
            HStack(spacing: ImprintSpacing.space100) {
                icon
                    .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                    .foregroundStyle(ImprintColors.iconSubtle)

                Text(fieldName)
                    .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size400))
                    .foregroundStyle(ImprintColors.neutralBoldest)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Right: state indicators
            switch state {
            case .locked:
                Image(systemName: "lock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                    .foregroundStyle(ImprintColors.iconSubtle)

            case .optional:
                Image(systemName: "exclamationmark.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                    .foregroundStyle(ImprintColors.redSubtle)

            case .required:
                HStack(spacing: ImprintSpacing.space200) {
                    Text("Required")
                        .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size200))
                        .foregroundStyle(ImprintColors.textSubtle)

                    Image(systemName: "exclamationmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                        .foregroundStyle(ImprintColors.redSubtle)
                }
            }
        }
        .padding(.horizontal, ImprintSpacing.space300)
        .padding(.vertical, ImprintSpacing.space100)
        .frame(height: ImprintSpacing.size800)
        .background(ImprintColors.neutralSubtler)
        .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
        .opacity(state == .locked ? ImprintColors.stateDisabled : ImprintColors.stateFull)
    }
}

// MARK: - Preview

#Preview("Field States") {
    VStack(spacing: 12) {
        ImprintField(fieldName: "Note", icon: IconoirCatalog.icon(for: "align-left"), state: .locked)
        ImprintField(fieldName: "Note", icon: IconoirCatalog.icon(for: "align-left"), state: .optional)
        ImprintField(fieldName: "Note", icon: IconoirCatalog.icon(for: "align-left"), state: .required)
    }
    .padding()
    .background(ImprintColors.neutralSubtlest)
}
