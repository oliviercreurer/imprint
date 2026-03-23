import SwiftUI

// MARK: - TextArea Component
// Derived from ImprintInput — same label/explainer pattern, but with a
// multi-line TextEditor for long-form text entry.
//
// Background: input/subtlest
// Min height: 120pt (roughly 5 lines)
// Corner radius: radius/100 (8pt)
// Padding: space/300 horizontal (16pt), space/200 vertical (12pt)
// Font: Technical/Medium (JetBrains Mono Medium, 14pt)
// Label: Technical/12pt/Bold, text/subtle
// Explainer: Body/14pt/Medium, text/subtler

/// A multi-line text input matching the Imprint design system.
struct ImprintTextArea: View {

    let label: String?
    @Binding var text: String
    var placeholder: String = ""
    var explainer: String? = nil
    var minHeight: CGFloat = 120

    /// When provided, a keyboard dismiss icon is shown inside the field.
    var onKeyboardDismiss: (() -> Void)? = nil

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
            // Label row — label + optional keyboard dismiss
            if label != nil || onKeyboardDismiss != nil {
                HStack {
                    if let label {
                        Text(label)
                            .font(ImprintFonts.technical12Bold)
                            .foregroundStyle(ImprintColors.textSubtle)
                    }

                    Spacer()

                    if let onKeyboardDismiss {
                        Button(action: onKeyboardDismiss) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ImprintColors.iconSubtle)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Text area
            ZStack(alignment: .topLeading) {
                // Placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .font(ImprintFonts.technical14Medium)
                        .foregroundStyle(ImprintColors.textSubtler)
                        .padding(.horizontal, ImprintSpacing.space300)
                        .padding(.vertical, ImprintSpacing.space200)
                }

                // Editor
                TextEditor(text: $text)
                    .font(ImprintFonts.technical14Medium)
                    .foregroundStyle(ImprintColors.textBoldest)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, ImprintSpacing.space200)
                    .padding(.vertical, ImprintSpacing.space100)
            }
            .frame(minHeight: minHeight, alignment: .topLeading)
            .background(ImprintColors.inputSubtlest)
            .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))

            // Explainer
            if let explainer {
                Text(explainer)
                    .font(ImprintFonts.body14Medium)
                    .foregroundStyle(ImprintColors.textSubtler)
            }
        }
    }
}

// MARK: - Preview

#Preview("TextArea") {
    VStack(spacing: 24) {
        ImprintTextArea(
            label: "Note",
            text: .constant(""),
            placeholder: "Add a note..."
        )

        ImprintTextArea(
            label: "Description",
            text: .constant("A really wonderful film about a father and daughter on the run during the Great Depression. Tatum O'Neal is extraordinary."),
            explainer: "Optional — add any additional context."
        )

        ImprintTextArea(
            label: nil,
            text: .constant(""),
            placeholder: "Write something...",
            minHeight: 200
        )
    }
    .padding(32)
    .background(ImprintColors.neutralSubtlest)
}
