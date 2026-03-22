import SwiftUI
import Iconoir

// MARK: - Field Component
// Figma: Field (state: locked/optional/required)
// A row displaying a field name with an icon, used in category editor views.
// Background: neutral/subtler (#F2F0E5 light)
// Height: size/800 (48pt)
// Corner radius: radius/100 (8pt)
// Padding: space/300 horizontal (16pt), space/100 vertical (8pt)
// Icon: 16pt, icon/subtle color
// Name: Technical/14pt/Medium, neutral/boldest
// States:
//   locked   → lock icon on right, full row at stateDisabled opacity (0.4)
//   optional → chevron.right on right
//   required → "Required" label (Technical/12pt/Bold, red/subtle) + chevron.right

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
                    .frame(width: 16, height: 16)
                    .foregroundStyle(ImprintColors.iconSubtle)

                Text(fieldName)
                    .font(ImprintFonts.technical14Medium)
                    .foregroundStyle(ImprintColors.neutralBoldest)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Right: state indicators
            switch state {
            case .locked:
                Image(systemName: "lock")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ImprintColors.iconSubtle)

            case .optional:
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ImprintColors.iconSubtle)

            case .required:
                HStack(spacing: ImprintSpacing.space200) {
                    Text("Required")
                        .font(ImprintFonts.technical12Bold)
                        .foregroundStyle(ImprintColors.redSubtle)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ImprintColors.iconSubtle)
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
