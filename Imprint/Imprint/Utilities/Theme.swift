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

    // Film
    static let filmSubtle   = Color(hex: 0x5ABDAC)
    static let filmSubtler  = Color(hex: 0x87D3C3)
    static let filmSubtlest = Color(hex: 0xDDF1E4)
    static let filmBold     = Color(hex: 0x24837B)

    // Book
    static let bookSubtle   = Color(hex: 0xDFB431)
    static let bookSubtler  = Color(hex: 0xECCB60)
    static let bookBold     = Color(hex: 0xAD8301)

    // TV
    static let tvSubtle   = Color(hex: 0xA699D0)
    static let tvSubtler  = Color(hex: 0xC4B9E0)
    static let tvBold     = Color(hex: 0x5E409D)

    // Music
    static let musicSubtle   = Color(hex: 0xE8705F)
    static let musicSubtler  = Color(hex: 0xF89A8A)
    static let musicBold     = Color(hex: 0xAF3029)

    // Dark mode base palette (from Figma dark/queue mode)
    static let darkSecondary    = Color(hex: 0xB7B5AC)  // dark base/bold – dates, secondary text
    static let darkSurfaceBg    = Color(hex: 0x282726)  // dark base/subtler – search bg
    static let darkSurfaceBorder = Color(hex: 0x575653) // dark base/subtle – borders, dividers

    // Dark mode /subtlest – queue legend fills
    static let filmQueueFill  = Color(hex: 0x122F2C)
    static let bookQueueFill  = Color(hex: 0x3A2D04)   // was 0x2E2513, corrected from Figma
    static let tvQueueFill    = Color(hex: 0x1E1637)
    static let musicQueueFill = Color(hex: 0x3E1715)   // was 0x2E1210, corrected from Figma

    // Dark mode /subtle – selected chip fill, legend stroke
    static let filmDarkSubtle  = Color(hex: 0x2F968D)
    static let bookDarkSubtle  = Color(hex: 0xBE9207)
    static let tvDarkSubtle    = Color(hex: 0x735EB5)
    static let musicDarkSubtle = Color(hex: 0xC03E35)

    // Dark mode /subtler – chip borders (unselected)
    static let filmDarkSubtler  = Color(hex: 0x1C6C66)
    static let bookDarkSubtler  = Color(hex: 0x8E6B01)
    static let tvDarkSubtler    = Color(hex: 0x4F3685)
    static let musicDarkSubtler = Color(hex: 0x942822)

    // Dark mode /bold – chip text (vivid tokens from Figma dark mode)
    static let filmDarkBold  = Color(hex: 0x5ABDAC)
    static let bookDarkBold  = Color(hex: 0xDFB431)
    static let tvDarkBold    = Color(hex: 0xA699D0)
    static let musicDarkBold = Color(hex: 0xE8705F)

    // Accent blue (confirm button, links)
    static let accentBlue      = Color(hex: 0x4385BE)
    static let accentBlueLight = Color(hex: 0x92BFDB)

    // Action buttons (detail view floating bar)
    static let actionLogAgain = Color(hex: 0x2F968D)  // cyan/cyan-500 – "log again" button
    static let actionEdit     = Color(hex: 0xDFB431)  // yellow/yellow-300 – "edit" button

    // Modal / Form
    static let formBorder   = Color(hex: 0x000000)
    static let chipInactive = Color(hex: 0xE6E6E6)
    static let chipText     = Color(hex: 0x7E7E7E)
    static let required     = Color(hex: 0xE74E4E)
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

    static var pageTitle: Font { platypiExtraBold(32) }
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

// MARK: - MediaType Color Extensions

extension MediaType {

    /// The primary fill color for legend squares and bar chart segments.
    var subtleColor: Color {
        switch self {
        case .film:  ImprintColors.filmSubtle
        case .book:  ImprintColors.bookSubtle
        case .tv:    ImprintColors.tvSubtle
        case .music: ImprintColors.musicSubtle
        }
    }

    /// The border / chip outline color.
    var subtlerColor: Color {
        switch self {
        case .film:  ImprintColors.filmSubtler
        case .book:  ImprintColors.bookSubtler
        case .tv:    ImprintColors.tvSubtler
        case .music: ImprintColors.musicSubtler
        }
    }

    /// The lightest tint (legend background when unfilled).
    var subtlestColor: Color {
        switch self {
        case .film:  ImprintColors.filmSubtlest
        case .book:  ImprintColors.bookSubtle.opacity(0.25)
        case .tv:    ImprintColors.tvSubtle.opacity(0.25)
        case .music: ImprintColors.musicSubtle.opacity(0.25)
        }
    }

    /// Dark fill for queue legend squares.
    var queueLegendFill: Color {
        switch self {
        case .film:  ImprintColors.filmQueueFill
        case .book:  ImprintColors.bookQueueFill
        case .tv:    ImprintColors.tvQueueFill
        case .music: ImprintColors.musicQueueFill
        }
    }

    /// The strong text color used on chip labels.
    var boldColor: Color {
        switch self {
        case .film:  ImprintColors.filmBold
        case .book:  ImprintColors.bookBold
        case .tv:    ImprintColors.tvBold
        case .music: ImprintColors.musicBold
        }
    }

    /// Dark mode subtle color – selected chip fill, legend stroke.
    var darkSubtleColor: Color {
        switch self {
        case .film:  ImprintColors.filmDarkSubtle
        case .book:  ImprintColors.bookDarkSubtle
        case .tv:    ImprintColors.tvDarkSubtle
        case .music: ImprintColors.musicDarkSubtle
        }
    }

    /// Dark mode chip border color.
    var darkSubtlerColor: Color {
        switch self {
        case .film:  ImprintColors.filmDarkSubtler
        case .book:  ImprintColors.bookDarkSubtler
        case .tv:    ImprintColors.tvDarkSubtler
        case .music: ImprintColors.musicDarkSubtler
        }
    }

    /// Dark mode chip text color.
    var darkBoldColor: Color {
        switch self {
        case .film:  ImprintColors.filmDarkBold
        case .book:  ImprintColors.bookDarkBold
        case .tv:    ImprintColors.tvDarkBold
        case .music: ImprintColors.musicDarkBold
        }
    }
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
