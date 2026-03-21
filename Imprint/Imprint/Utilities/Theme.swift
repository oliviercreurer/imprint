import SwiftUI

// MARK: - Colors

/// Central color definitions matching Figma design tokens.
enum ImprintColors {

    // Base palette
    static let paper       = Color(hex: 0xFFFCF0)  // base/subtlest – main background
    static let searchBg    = Color(hex: 0xF2F0E5)  // base/subtler
    static let searchBorder = Color(hex: 0xCECDC3) // base/subtle
    static let secondary   = Color(hex: 0x9F9D96)  // base/bold – dates, month headers
    static let primary     = Color(hex: 0x100F0F)  // base/boldest – primary text

    // Dark mode base palette
    static let darkSecondary    = Color(hex: 0xB7B5AC)  // dark base/bold – dates, secondary text
    static let darkSurfaceBg    = Color(hex: 0x282726)  // dark base/subtler – search bg
    static let darkSurfaceBorder = Color(hex: 0x575653) // dark base/subtle – borders, dividers

    // Accent blue family
    static let accentBlue        = Color(hex: 0x4385BE)  // accent/blue/subtle
    static let accentBlueLight   = Color(hex: 0x92BFDB)  // accent/blue/subtler
    static let accentBlueBold    = Color(hex: 0x205EA6)  // accent/blue/bold
    static let accentBlueBolder  = Color(hex: 0x163B66)  // accent/blue/bolder
    static let accentBlueSubtlest = Color(hex: 0xE1ECEB) // accent/blue/subtlest

    // Settings row background
    static let settingsRowBg     = Color(hex: 0x3171B2)  // blue/blue-500

    // Action buttons (detail view floating bar)
    static let actionLogAgain = Color(hex: 0x2F968D)  // cyan/cyan-500 – "log again" button
    static let actionEdit     = Color(hex: 0xDFB431)  // yellow/yellow-300 – "edit" button

    // Modal / Form
    static let formBorder   = Color(hex: 0x000000)
    static let chipInactive = Color(hex: 0xE6E6E6)
    static let chipText     = Color(hex: 0x7E7E7E)
    static let required     = Color(hex: 0xE74E4E)

    // Dark mode form tokens
    static let darkChipInactive = Color(hex: 0x3A3938)
    static let darkChipText     = Color(hex: 0x9F9D96)

    // MARK: - Appearance-Aware Resolvers

    /// Background for modals and sheets.
    static func modalBg(_ isDark: Bool) -> Color { isDark ? primary : paper }

    /// Primary text color on modal backgrounds.
    static func modalText(_ isDark: Bool) -> Color { isDark ? paper : primary }

    /// Heading / label text (used where `.black` was hardcoded).
    static func headingText(_ isDark: Bool) -> Color { isDark ? paper : primary }

    /// Secondary / muted text.
    static func secondaryText(_ isDark: Bool) -> Color { isDark ? darkSecondary : secondary }

    /// Tertiary / faintest text.
    static func tertiaryText(_ isDark: Bool) -> Color { isDark ? darkSurfaceBorder : searchBorder }

    /// Input field background.
    static func inputBg(_ isDark: Bool) -> Color { isDark ? darkSurfaceBg : searchBg }

    /// Input field / card border.
    static func inputBorder(_ isDark: Bool) -> Color { isDark ? darkSurfaceBorder : searchBorder }

    /// CTA button fill.
    static func ctaFill(_ isDark: Bool) -> Color { isDark ? paper : primary }

    /// CTA button text.
    static func ctaText(_ isDark: Bool) -> Color { isDark ? primary : paper }

    /// Chip inactive fill (form media-type chips).
    static func chipInactiveFill(_ isDark: Bool) -> Color { isDark ? darkChipInactive : chipInactive }

    /// Chip inactive text (form media-type chips).
    static func chipInactiveText(_ isDark: Bool) -> Color { isDark ? darkChipText : chipText }

    /// Placeholder loading color for images.
    static func placeholderBg(_ isDark: Bool) -> Color { isDark ? darkSurfaceBg : searchBg }

    /// Failure placeholder color for images.
    static func failureBg(_ isDark: Bool) -> Color { isDark ? darkSurfaceBorder : Color(hex: 0xE0E0E0) }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Fonts

/// Font helpers matching the Figma typography spec.
///
/// Uses custom fonts when available, falling back to system monospaced.
/// Fonts must be added to the Xcode project and registered in Info.plist.
enum ImprintFonts {

    // MARK: Platypi

    static func platypiExtraBold(_ size: CGFloat) -> Font {
        .custom("Platypi-ExtraBold", size: size, relativeTo: .largeTitle)
    }

    static func platypiSemiBold(_ size: CGFloat) -> Font {
        .custom("Platypi-SemiBold", size: size, relativeTo: .title)
    }

    static func platypiLight(_ size: CGFloat) -> Font {
        .custom("Platypi-Light", size: size, relativeTo: .body)
    }

    // MARK: JetBrains Mono

    static func jetBrainsSemiBold(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-SemiBold", size: size, relativeTo: .body)
    }

    static func jetBrainsBold(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Bold", size: size, relativeTo: .body)
    }

    static func jetBrainsMedium(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Medium", size: size, relativeTo: .body)
    }

    static func jetBrainsRegular(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Regular", size: size, relativeTo: .body)
    }

    // MARK: Semantic shortcuts

    static var pageTitle: Font { platypiSemiBold(32) }
    static var modalTitle: Font { platypiSemiBold(20) }
    static var detailTitle: Font { platypiSemiBold(32) }
    static var detailSubtitle: Font { platypiSemiBold(24) }
    static var filterChip: Font { jetBrainsMedium(14) }
    static var recordName: Font { jetBrainsSemiBold(14) }
    static var monthHeader: Font { jetBrainsBold(14) }
    static var dateText: Font { jetBrainsSemiBold(14) }
    static var formLabel: Font { jetBrainsMedium(14) }
    static var formValue: Font { jetBrainsMedium(16) }
    static var searchPlaceholder: Font { jetBrainsBold(14) }
    static var noteBody: Font { jetBrainsRegular(14) }
}


// MARK: - Imprint Logo Shape

/// The Imprint logo as a SwiftUI Shape — a circle with a half-moon cutout (top half open).
/// Converted from the SVG: a 32×32 circle with an inner arc from (4,16) to (28,16).
struct ImprintLogo: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let scale = s / 32.0

        var path = Path()

        // Outer circle
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = 16.0 * scale

        // Start at top of circle, draw full outer circle clockwise
        path.addEllipse(in: CGRect(
            x: center.x - outerR,
            y: center.y - outerR,
            width: outerR * 2,
            height: outerR * 2
        ))

        // Inner semicircle cutout (top half)
        // The SVG draws: M16,4 arc to (4,16), line to (28,16), arc back to (16,4)
        // This is the top semicircle of an inner circle with radius 12
        let innerR = 12.0 * scale
        var cutout = Path()
        cutout.addArc(
            center: center,
            radius: innerR,
            startAngle: .degrees(0),
            endAngle: .degrees(-180),
            clockwise: true
        )
        cutout.closeSubpath()

        // Use even-odd fill to cut out the semicircle
        path.addPath(cutout)

        return path
    }
}

// MARK: - Staggered Appearance Animation

/// A modifier that fades in + slides up a view with a staggered delay based on index.
struct StaggeredAppearance: ViewModifier {
    let index: Int

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .onAppear {
                withAnimation(.easeOut(duration: 0.2).delay(Double(index) * 0.035)) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Applies a staggered fade-in + slide-up entrance animation.
    func staggeredAppearance(index: Int) -> some View {
        modifier(StaggeredAppearance(index: index))
    }
}
