import SwiftUI

// MARK: - Button Component
// Figma: Button (Size × Style × State × Color)
// 3 sizes: small, medium, large
// 3 styles: light, border, bold
// 6 colors: neutral, cyan, blue, purple, red, yellow
// 2 states: enabled, disabled

/// A design-system button matching the Figma component variants.
struct ImprintButton: View {

    let label: String
    var color: ButtonColor = .neutral
    var size: ButtonSize = .large
    var style: ButtonStyle = .light
    var isEnabled: Bool = true
    var action: () -> Void = {}

    // MARK: - Enums

    enum ButtonColor {
        case neutral, cyan, blue, purple, red, yellow
    }

    enum ButtonSize {
        case small, medium, large
    }

    enum ButtonStyle {
        case light, border, bold
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(textFont)
                .foregroundStyle(textColor)
                .lineSpacing(0)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(minHeight: minHeight)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius50))
        .overlay(
            RoundedRectangle(cornerRadius: ImprintSpacing.radius50)
                .strokeBorder(borderColor, lineWidth: style == .border ? ImprintSpacing.borderDefault : 0)
        )
        .opacity(isEnabled ? ImprintColors.stateFull : ImprintColors.stateDisabled)
        .allowsHitTesting(isEnabled)
    }

    // MARK: - Layout by Size

    /// Font: Technical/Small (size/200, weight/medium) for all sizes
    private var textFont: Font {
        ImprintFonts.jetBrainsMedium(ImprintFonts.size200)
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small:  ImprintSpacing.space200   // 12
        case .medium: ImprintSpacing.space300   // 16
        case .large:  ImprintSpacing.space300   // 16
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small:  ImprintSpacing.space100   // 8
        case .medium: ImprintSpacing.space200   // 12
        case .large:  ImprintSpacing.space300   // 16
        }
    }

    private var minHeight: CGFloat {
        switch size {
        case .small:  ImprintSpacing.size600    // 32
        case .medium: ImprintSpacing.size700    // 40
        case .large:  ImprintSpacing.size800    // 48
        }
    }

    // MARK: - Colors by Style × Color

    private var background: Color {
        switch style {
        case .light:  lightBg
        case .border: .clear
        case .bold:   boldBg
        }
    }

    private var textColor: Color {
        switch style {
        case .light:  ImprintColors.textBoldest
        case .border: borderTextColor
        case .bold:   boldTextColor
        }
    }

    private var borderColor: Color {
        switch style {
        case .border: colorSubtle
        case _:       .clear
        }
    }

    // Light style backgrounds
    private var lightBg: Color {
        switch color {
        case .neutral: ImprintColors.neutralSubtler
        case .cyan:    ImprintColors.cyanSubtlest
        case .blue:    ImprintColors.blueSubtlest
        case .purple:  ImprintColors.purpleSubtlest
        case .red:     ImprintColors.redSubtlest
        case .yellow:  ImprintColors.yellowSubtlest
        }
    }

    // Bold style backgrounds
    private var boldBg: Color {
        switch color {
        case .neutral: ImprintColors.neutralBolder
        case .cyan:    ImprintColors.cyanSubtle
        case .blue:    ImprintColors.blueSubtle
        case .purple:  ImprintColors.purpleSubtle
        case .red:     ImprintColors.redSubtle
        case .yellow:  ImprintColors.yellowSubtle
        }
    }

    // Bold style text
    private var boldTextColor: Color {
        switch color {
        case .neutral: ImprintColors.textInverse
        case _:        ImprintColors.textInverse
        }
    }

    // Border style text
    private var borderTextColor: Color {
        switch color {
        case .neutral: ImprintColors.textBoldest
        case .cyan:    ImprintColors.cyanBold
        case .blue:    ImprintColors.blueBold
        case .purple:  ImprintColors.purpleBold
        case .red:     ImprintColors.redBold
        case .yellow:  ImprintColors.yellowBold
        }
    }

    // Subtle color for border strokes
    private var colorSubtle: Color {
        switch color {
        case .neutral: ImprintColors.neutralSubtle
        case .cyan:    ImprintColors.cyanSubtle
        case .blue:    ImprintColors.blueSubtle
        case .purple:  ImprintColors.purpleSubtle
        case .red:     ImprintColors.redSubtle
        case .yellow:  ImprintColors.yellowSubtle
        }
    }
}

// MARK: - Preview

#Preview("Button Variants") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach(["light", "border", "bold"], id: \.self) { styleName in
                let style: ImprintButton.ButtonStyle =
                    styleName == "light" ? .light :
                    styleName == "border" ? .border : .bold

                VStack(alignment: .leading, spacing: 8) {
                    Text(styleName.capitalized)
                        .font(ImprintFonts.jetBrainsBold(14))
                    HStack(spacing: 8) {
                        ImprintButton(label: "Button", color: .neutral, size: .medium, style: style)
                        ImprintButton(label: "Button", color: .cyan, size: .medium, style: style)
                        ImprintButton(label: "Button", color: .blue, size: .medium, style: style)
                        ImprintButton(label: "Button", color: .purple, size: .medium, style: style)
                        ImprintButton(label: "Button", color: .red, size: .medium, style: style)
                        ImprintButton(label: "Button", color: .yellow, size: .medium, style: style)
                    }
                }
            }
        }
        .padding()
    }
}
