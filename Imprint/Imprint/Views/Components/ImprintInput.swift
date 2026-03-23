import SwiftUI

// MARK: - Input Component
// Figma: Input (state: empty/filled, label, icon, explainer)
// Background: input/subtlest (#F2F0E5 light, #282726 dark)
// Height: size/800 (48pt)
// Corner radius: radius/100 (8pt)
// Padding: space/300 horizontal (16pt), space/100 vertical (8pt)
// Font: Technical/Medium (JetBrains Mono Medium, size/400 14pt, height/300 18pt)
// Label: Technical/Small (size/200 12pt, height/200 16pt), text/subtle

/// A text input field matching the Figma Input component.
struct ImprintInput: View {

    let label: String?
    @Binding var text: String
    var placeholder: String = ""
    var showIcon: Bool = false

    /// When provided, a keyboard dismiss icon is shown inside the field.
    /// The parent is responsible for clearing focus in this closure.
    var onKeyboardDismiss: (() -> Void)? = nil

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
            // Label
            if let label {
                Text(label)
                    .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size200))
                    .foregroundStyle(ImprintColors.textSubtle)
                    .lineSpacing(0)
            }

            // Input field
            HStack(spacing: ImprintSpacing.space100) {
                TextField(placeholder, text: $text)
                    .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size400))
                    .foregroundStyle(ImprintColors.textBoldest)
                    .accentColor(Color(ImprintColors.Primitive.base500))

                if showIcon {
                    Image(systemName: "chevron.up.chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                        .foregroundStyle(ImprintColors.iconSubtle)
                }

                if let onKeyboardDismiss {
                    Button(action: onKeyboardDismiss) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ImprintColors.iconSubtle)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ImprintSpacing.space300)
            .padding(.vertical, ImprintSpacing.space100)
            .frame(height: ImprintSpacing.size800)
            .background(ImprintColors.inputSubtlest)
            .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
        }
    }
}

// MARK: - Preview

#Preview("Input") {
    VStack(spacing: 24) {
        ImprintInput(
            label: "Field label",
            text: .constant(""),
            placeholder: "e.g. Director"
        )
        ImprintInput(
            label: "Field label",
            text: .constant("Director")
        )
        ImprintInput(
            label: nil,
            text: .constant(""),
            placeholder: "Search…",
            showIcon: true
        )
    }
    .padding()
    .background(ImprintColors.neutralSubtlest)
}
