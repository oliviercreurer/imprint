import SwiftUI

// ╔══════════════════════════════════════════════════════════════════╗
// ║  Theme.swift — Generated from Figma design tokens              ║
// ║  Source: Imprint/DesignSystem/{colors,typography,spacing}.json  ║
// ║  Last synced: 2026-03-21                                       ║
// ╚══════════════════════════════════════════════════════════════════╝

// MARK: - Adaptive Color Helper

private extension Color {
    /// Creates an adaptive `Color` that resolves automatically for light / dark mode.
    static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: CGFloat((dark >> 16) & 0xFF) / 255,
                          green: CGFloat((dark >> 8) & 0xFF) / 255,
                          blue: CGFloat(dark & 0xFF) / 255,
                          alpha: 1)
                : UIColor(red: CGFloat((light >> 16) & 0xFF) / 255,
                          green: CGFloat((light >> 8) & 0xFF) / 255,
                          blue: CGFloat(light & 0xFF) / 255,
                          alpha: 1)
        })
    }
}

// MARK: - Colors

/// Semantic color tokens matching the Figma design system.
///
/// Colors are adaptive — they automatically resolve for light and dark mode.
/// Organized into groups that mirror the Figma variable collections.
enum ImprintColors {

    // ── Neutral ─────────────────────────────────────────────────────

    /// Main background. Light: base-00 #FFFCF0, Dark: base-1000 #100F0F
    static let neutralSubtlest  = Color.adaptive(light: 0xFFFCF0, dark: 0x100F0F)
    /// Secondary surface. Light: base-50 #F2F0E5, Dark: base-900 #282726
    static let neutralSubtler   = Color.adaptive(light: 0xF2F0E5, dark: 0x282726)
    /// Borders, dividers. Light: base-200 #CECDC3, Dark: base-700 #575653
    static let neutralSubtle    = Color.adaptive(light: 0xCECDC3, dark: 0x575653)
    /// Muted text, icons. Light: base-400 #9F9D96, Dark: base-300 #B7B5AC
    static let neutralBold      = Color.adaptive(light: 0x9F9D96, dark: 0xB7B5AC)
    /// Secondary text. Light: base-700 #575653, Dark: base-150 #DAD8CE
    static let neutralBolder    = Color.adaptive(light: 0x575653, dark: 0xDAD8CE)
    /// Primary foreground. Light: base-1000 #100F0F, Dark: base-00 #FFFCF0
    static let neutralBoldest   = Color.adaptive(light: 0x100F0F, dark: 0xFFFCF0)

    // ── Text ────────────────────────────────────────────────────────

    /// Primary text. Light: base-1000 #100F0F, Dark: base-00 #FFFCF0
    static let textBoldest  = Color.adaptive(light: 0x100F0F, dark: 0xFFFCF0)
    /// Strong labels. Light: base-850 #343331, Dark: base-150 #DAD8CE
    static let textBolder   = Color.adaptive(light: 0x343331, dark: 0xDAD8CE)
    /// Body text. Light: base-700 #575653, Dark: base-300 #B7B5AC
    static let textBold     = Color.adaptive(light: 0x575653, dark: 0xB7B5AC)
    /// Subtle labels. Light: base-500 #878580, Dark: base-500 #878580
    static let textSubtle   = Color.adaptive(light: 0x878580, dark: 0x878580)
    /// Muted text. Light: base-300 #B7B5AC, Dark: base-700 #575653
    static let textSubtler  = Color.adaptive(light: 0xB7B5AC, dark: 0x575653)
    /// Faintest text. Light: base-200 #CECDC3, Dark: base-850 #343331
    static let textSubtlest = Color.adaptive(light: 0xCECDC3, dark: 0x343331)
    /// Inverse text (on filled buttons). Light: base-00 #FFFCF0, Dark: base-1000 #100F0F
    static let textInverse  = Color.adaptive(light: 0xFFFCF0, dark: 0x100F0F)

    // ── Icon ────────────────────────────────────────────────────────

    static let iconBoldest  = Color.adaptive(light: 0x100F0F, dark: 0xFFFCF0)
    static let iconBolder   = Color.adaptive(light: 0x343331, dark: 0xDAD8CE)
    static let iconBold     = Color.adaptive(light: 0x575653, dark: 0xB7B5AC)
    static let iconSubtle   = Color.adaptive(light: 0x878580, dark: 0x878580)
    static let iconSubtler  = Color.adaptive(light: 0xB7B5AC, dark: 0x575653)
    static let iconSubtlest = Color.adaptive(light: 0xCECDC3, dark: 0x343331)
    static let iconInverse  = Color.adaptive(light: 0xFFFCF0, dark: 0x100F0F)

    // ── Input ───────────────────────────────────────────────────────

    /// Input background. Light: base-50 #F2F0E5, Dark: base-900 #282726
    static let inputSubtlest = Color.adaptive(light: 0xF2F0E5, dark: 0x282726)
    /// Input border. Light: base-100 #E6E4D9, Dark: base-800 #403E3C
    static let inputSubtle   = Color.adaptive(light: 0xE6E4D9, dark: 0x403E3C)

    // ── Blue ────────────────────────────────────────────────────────

    static let blueSubtlest = Color.adaptive(light: 0xE1ECEB, dark: 0x12253B)
    static let blueSubtler  = Color.adaptive(light: 0x92BFDB, dark: 0x1A4F8C)
    static let blueSubtle   = Color.adaptive(light: 0x4385BE, dark: 0x3171B2)
    static let blueBold     = Color.adaptive(light: 0x205EA6, dark: 0x66A0C8)
    static let blueBolder   = Color.adaptive(light: 0x163B66, dark: 0xABCFE2)
    static let blueBoldest  = Color.adaptive(light: 0x12253B, dark: 0xE1ECEB)

    // ── Red ─────────────────────────────────────────────────────────

    static let redSubtlest = Color.adaptive(light: 0xFFE1D5, dark: 0x3E1715)
    static let redSubtler  = Color.adaptive(light: 0xF89A8A, dark: 0x942822)
    static let redSubtle   = Color.adaptive(light: 0xE8705F, dark: 0xC03E35)
    static let redBold     = Color.adaptive(light: 0xAF3029, dark: 0xE8705F)
    static let redBolder   = Color.adaptive(light: 0x6C201C, dark: 0xFDB2A2)
    static let redBoldest  = Color.adaptive(light: 0x3E1715, dark: 0xFFE1D5)

    // ── Cyan ────────────────────────────────────────────────────────

    static let cyanSubtlest = Color.adaptive(light: 0xDDF1E4, dark: 0x122F2C)
    static let cyanSubtler  = Color.adaptive(light: 0x87D3C3, dark: 0x1C6C66)
    static let cyanSubtle   = Color.adaptive(light: 0x5ABDAC, dark: 0x2F968D)
    static let cyanBold     = Color.adaptive(light: 0x24837B, dark: 0x5ABDAC)
    static let cyanBolder   = Color.adaptive(light: 0x164F4A, dark: 0xA2DECE)
    static let cyanBoldest  = Color.adaptive(light: 0x122F2C, dark: 0xDDF1E4)

    // ── Yellow ──────────────────────────────────────────────────────

    static let yellowSubtlest = Color.adaptive(light: 0xFAEEC6, dark: 0x3A2D04)
    static let yellowSubtler  = Color.adaptive(light: 0xECCB60, dark: 0x8E6B01)
    static let yellowSubtle   = Color.adaptive(light: 0xDFB431, dark: 0xBE9207)
    static let yellowBold     = Color.adaptive(light: 0xAD8301, dark: 0xDFB431)
    static let yellowBolder   = Color.adaptive(light: 0x664D01, dark: 0xF1D67E)
    static let yellowBoldest  = Color.adaptive(light: 0x3A2D04, dark: 0xFAEEC6)

    // ── Purple ──────────────────────────────────────────────────────

    static let purpleSubtlest = Color.adaptive(light: 0xF0EAEC, dark: 0x261C39)
    static let purpleSubtler  = Color.adaptive(light: 0xC4B9E0, dark: 0x4F3685)
    static let purpleSubtle   = Color.adaptive(light: 0xA699D0, dark: 0x735EB5)
    static let purpleBold     = Color.adaptive(light: 0x5E409D, dark: 0xA699D0)
    static let purpleBolder   = Color.adaptive(light: 0x3C2A62, dark: 0xD3CAE6)
    static let purpleBoldest  = Color.adaptive(light: 0x261C39, dark: 0xF0EAEC)

    // ── State Opacity ───────────────────────────────────────────────

    static let stateFull: Double     = 1.0
    static let stateMuted: Double    = 0.6
    static let stateDisabled: Double = 0.4
    static let stateHidden: Double   = 0.0

    // ── Primitives (non-adaptive, for programmatic use) ─────────────

    enum Primitive {
        // Base
        static let base00   = Color(hex: 0xFFFCF0)
        static let base50   = Color(hex: 0xF2F0E5)
        static let base100  = Color(hex: 0xE6E4D9)
        static let base150  = Color(hex: 0xDAD8CE)
        static let base200  = Color(hex: 0xCECDC3)
        static let base300  = Color(hex: 0xB7B5AC)
        static let base400  = Color(hex: 0x9F9D96)
        static let base500  = Color(hex: 0x878580)
        static let base600  = Color(hex: 0x6F6E69)
        static let base700  = Color(hex: 0x575653)
        static let base800  = Color(hex: 0x403E3C)
        static let base850  = Color(hex: 0x343331)
        static let base900  = Color(hex: 0x282726)
        static let base950  = Color(hex: 0x1C1B1A)
        static let base1000 = Color(hex: 0x100F0F)

        // Red
        static let red400  = Color(hex: 0xD14D41)
        static let red500  = Color(hex: 0xC03E35)
        static let red600  = Color(hex: 0xAF3029)

        // Blue
        static let blue400 = Color(hex: 0x4385BE)
        static let blue500 = Color(hex: 0x3171B2)
        static let blue600 = Color(hex: 0x205EA6)

        // Cyan
        static let cyan400 = Color(hex: 0x3AA99F)
        static let cyan500 = Color(hex: 0x2F968D)

        // Yellow
        static let yellow300 = Color(hex: 0xDFB431)
        static let yellow400 = Color(hex: 0xD0A215)

        // Purple
        static let purple400 = Color(hex: 0x8B7EC8)
        static let purple600 = Color(hex: 0x5E409D)
    }

    // ── Backward-Compatible Aliases ─────────────────────────────────
    // IMPORTANT: These are STATIC (non-adaptive) colors that always
    // return their light-mode value. Old views use `isDark ? X : Y`
    // ternaries to manually pick dark variants, so these must NOT be
    // adaptive — otherwise the ternary double-flips the result.
    // New views should use the adaptive semantic tokens above instead.

    static let paper            = Primitive.base00       // #FFFCF0
    static let primary          = Primitive.base1000     // #100F0F
    static let secondary        = Primitive.base400      // #9F9D96
    static let searchBg         = Primitive.base50       // #F2F0E5
    static let searchBorder     = Primitive.base200      // #CECDC3
    static let darkSecondary    = Primitive.base300      // #B7B5AC
    static let darkSurfaceBg    = Primitive.base900      // #282726
    static let darkSurfaceBorder = Primitive.base700     // #575653

    static let accentBlue        = Primitive.blue400     // #4385BE
    static let accentBlueLight   = Color(hex: 0x92BFDB)
    static let accentBlueBold    = Primitive.blue600     // #205EA6
    static let accentBlueBolder  = Color(hex: 0x163B66)
    static let accentBlueSubtlest = Color(hex: 0xE1ECEB)

    static let settingsRowBg   = Primitive.blue500       // #3171B2
    static let actionLogAgain  = Primitive.cyan500       // #2F968D
    static let actionEdit      = Primitive.yellow300     // #DFB431

    static let required        = Primitive.red600       // #AF3029
    static let formBorder      = Color(hex: 0x000000)
    static let chipInactive    = Color(hex: 0xE6E6E6)
    static let chipText        = Color(hex: 0x7E7E7E)
    static let darkChipInactive = Primitive.base850
    static let darkChipText     = Primitive.base400

    // ── Backward-Compatible Resolvers ───────────────────────────────
    // These will be removed once views are rebuilt from Figma specs.

    static func modalBg(_ isDark: Bool) -> Color { isDark ? Primitive.base1000 : Primitive.base00 }
    static func modalText(_ isDark: Bool) -> Color { isDark ? Primitive.base00 : Primitive.base1000 }
    static func headingText(_ isDark: Bool) -> Color { isDark ? Primitive.base00 : Primitive.base1000 }
    static func secondaryText(_ isDark: Bool) -> Color { isDark ? Primitive.base300 : Primitive.base400 }
    static func tertiaryText(_ isDark: Bool) -> Color { isDark ? Primitive.base700 : Primitive.base200 }
    static func inputBg(_ isDark: Bool) -> Color { isDark ? Primitive.base900 : Primitive.base50 }
    static func inputBorder(_ isDark: Bool) -> Color { isDark ? Primitive.base700 : Primitive.base200 }
    static func ctaFill(_ isDark: Bool) -> Color { isDark ? Primitive.base00 : Primitive.base1000 }
    static func ctaText(_ isDark: Bool) -> Color { isDark ? Primitive.base1000 : Primitive.base00 }
    static func chipInactiveFill(_ isDark: Bool) -> Color { isDark ? Primitive.base850 : chipInactive }
    static func chipInactiveText(_ isDark: Bool) -> Color { isDark ? Primitive.base400 : chipText }
    static func placeholderBg(_ isDark: Bool) -> Color { isDark ? Primitive.base900 : Primitive.base50 }
    static func failureBg(_ isDark: Bool) -> Color { isDark ? Primitive.base700 : Color(hex: 0xE0E0E0) }
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

// MARK: - Typography

/// Font helpers generated from Figma typography tokens.
///
/// Two families: Outfit (headings & body), JetBrains Mono (technical).
/// Sizes follow the design system scale: 200(12)…1000(48).
enum ImprintFonts {

    // ── Type Scale (points) ─────────────────────────────────────────

    static let size200: CGFloat = 12
    static let size300: CGFloat = 13
    static let size400: CGFloat = 14
    static let size500: CGFloat = 16
    static let size600: CGFloat = 18
    static let size700: CGFloat = 24
    static let size800: CGFloat = 32
    static let size900: CGFloat = 40
    static let size1000: CGFloat = 48

    // ── Line Heights ────────────────────────────────────────────────

    static let lineHeight200: CGFloat = 16
    static let lineHeight300: CGFloat = 18
    static let lineHeight400: CGFloat = 20
    static let lineHeight500: CGFloat = 22
    static let lineHeight600: CGFloat = 24
    static let lineHeight700: CGFloat = 32
    static let lineHeight800: CGFloat = 40
    static let lineHeight900: CGFloat = 48
    static let lineHeight1000: CGFloat = 60

    // ── Outfit (Headings & Body) ──────────────────────────────────

    static func outfitRegular(_ size: CGFloat) -> Font {
        .custom("Outfit-Regular", size: size, relativeTo: .body)
    }
    static func outfitMedium(_ size: CGFloat) -> Font {
        .custom("Outfit-Medium", size: size, relativeTo: .body)
    }
    static func outfitSemiBold(_ size: CGFloat) -> Font {
        .custom("Outfit-SemiBold", size: size, relativeTo: .title)
    }
    static func outfitBold(_ size: CGFloat) -> Font {
        .custom("Outfit-Bold", size: size, relativeTo: .title)
    }
    static func outfitExtraBold(_ size: CGFloat) -> Font {
        .custom("Outfit-ExtraBold", size: size, relativeTo: .largeTitle)
    }

    // ── Backward-compat aliases (Platypi → Outfit) ────────────────
    // Old call sites use platypi* names. These forward to Outfit.

    static func platypiRegular(_ size: CGFloat) -> Font { outfitRegular(size) }
    static func platypiMedium(_ size: CGFloat) -> Font { outfitMedium(size) }
    static func platypiSemiBold(_ size: CGFloat) -> Font { outfitSemiBold(size) }
    static func platypiBold(_ size: CGFloat) -> Font { outfitBold(size) }
    static func platypiExtraBold(_ size: CGFloat) -> Font { outfitExtraBold(size) }

    // ── JetBrains Mono (Technical / Monospaced) ─────────────────────

    static func jetBrainsRegular(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Regular", size: size, relativeTo: .body)
    }
    static func jetBrainsMedium(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Medium", size: size, relativeTo: .body)
    }
    static func jetBrainsSemiBold(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-SemiBold", size: size, relativeTo: .body)
    }
    static func jetBrainsBold(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Bold", size: size, relativeTo: .body)
    }
    static func jetBrainsExtraBold(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-ExtraBold", size: size, relativeTo: .body)
    }

    // ── Figma Type Styles ──────────────────────────────────────────
    //
    // Heading:
    //   Heading/H3          → Outfit SemiBold 32pt (tight)
    //
    // Technical (JetBrains Mono):
    //   Technical/14pt/Medium → JetBrains Mono Medium 14pt
    //   Technical/14pt/Bold   → JetBrains Mono Bold 14pt
    //   Technical/12pt/Medium → JetBrains Mono Medium 12pt
    //   Technical/12pt/Bold   → JetBrains Mono Bold 12pt
    //
    // Body (Outfit):
    //   Body/14pt/Medium     → Outfit Medium 14pt
    //   Body/14pt/Bold       → Outfit Bold 14pt
    //   Body/12pt/Medium     → Outfit Medium 12pt
    //   Body/12pt/Bold       → Outfit Bold 12pt

    // Heading
    static var headingH3: Font        { outfitSemiBold(size800) }

    // Technical — named to match Figma style tokens
    static var technical14Medium: Font { jetBrainsMedium(size400) }
    static var technical14Bold: Font   { jetBrainsBold(size400) }
    static var technical12Medium: Font { jetBrainsMedium(size200) }
    static var technical12Bold: Font   { jetBrainsBold(size200) }

    // Body — named to match Figma style tokens
    static var body16Regular: Font     { outfitRegular(size500) }
    static var body16Medium: Font      { outfitMedium(size500) }
    static var body16Bold: Font        { outfitBold(size500) }
    static var body14Regular: Font     { outfitRegular(size400) }
    static var body14Medium: Font      { outfitMedium(size400) }
    static var body14Bold: Font        { outfitBold(size400) }

    // ── Legacy Semantic Shortcuts ─────────────────────────────────
    // These bridge old call sites to the new style names.

    static var pageTitle: Font        { headingH3 }
    static var modalTitle: Font       { outfitSemiBold(20) }
    static var detailTitle: Font      { headingH3 }
    static var detailSubtitle: Font   { outfitSemiBold(size700) }
    static var filterChip: Font       { technical14Medium }
    static var recordName: Font       { technical14Medium }
    static var monthHeader: Font      { technical14Bold }
    static var dateText: Font         { technical14Medium }
    static var formLabel: Font        { technical14Medium }
    static var formValue: Font        { jetBrainsMedium(size500) }
    static var searchPlaceholder: Font { technical14Bold }
    static var noteBody: Font         { jetBrainsRegular(size400) }
}

// MARK: - Spacing

/// Spacing tokens generated from Figma spacing variables.
/// All values are in points (iOS logical pixels).
enum ImprintSpacing {

    // ── Space ───────────────────────────────────────────────────────

    static let space0: CGFloat    = 0
    static let space25: CGFloat   = 2
    static let space50: CGFloat   = 4
    static let space75: CGFloat   = 6
    static let space100: CGFloat  = 8
    static let space200: CGFloat  = 12
    static let space300: CGFloat  = 16
    static let space400: CGFloat  = 20
    static let space500: CGFloat  = 24
    static let space600: CGFloat  = 32
    static let space700: CGFloat  = 40
    static let space800: CGFloat  = 48
    static let space900: CGFloat  = 64
    static let space1000: CGFloat = 80

    // ── Radius ──────────────────────────────────────────────────────

    static let radiusSquare: CGFloat = 0
    static let radius25: CGFloat     = 2
    static let radius50: CGFloat     = 4
    static let radius75: CGFloat     = 6
    static let radius100: CGFloat    = 8
    static let radius200: CGFloat    = 12
    static let radius300: CGFloat    = 16
    static let radius400: CGFloat    = 20
    static let radius500: CGFloat    = 24
    static let radius600: CGFloat    = 32
    static let radius700: CGFloat    = 40
    static let radius800: CGFloat    = 48
    static let radius900: CGFloat    = 64
    static let radiusRound: CGFloat  = 1000

    // ── Size ────────────────────────────────────────────────────────

    static let size0: CGFloat    = 0
    static let size25: CGFloat   = 2
    static let size50: CGFloat   = 4
    static let size75: CGFloat   = 6
    static let size100: CGFloat  = 8
    static let size200: CGFloat  = 12
    static let size300: CGFloat  = 16
    static let size400: CGFloat  = 20
    static let size500: CGFloat  = 24
    static let size600: CGFloat  = 32
    static let size700: CGFloat  = 40
    static let size800: CGFloat  = 48
    static let size900: CGFloat  = 64
    static let size1000: CGFloat = 1000

    // ── Border ──────────────────────────────────────────────────────

    static let borderDefault: CGFloat = 2
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

        path.addEllipse(in: CGRect(
            x: center.x - outerR,
            y: center.y - outerR,
            width: outerR * 2,
            height: outerR * 2
        ))

        // Inner semicircle cutout (top half)
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
            .onDisappear {
                appeared = false
            }
    }
}

extension View {
    /// Applies a staggered fade-in + slide-up entrance animation.
    func staggeredAppearance(index: Int) -> some View {
        modifier(StaggeredAppearance(index: index))
    }
}
