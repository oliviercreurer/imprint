import SwiftUI

/// Generates color variants from a single hex string.
///
/// Replaces the old hardcoded per-media-type color palettes in Theme.swift.
/// Given one user-chosen hex color, derives subtle, bold, and dark-mode
/// variants programmatically by adjusting saturation and brightness.
enum ColorDerivation {

    // MARK: - Hex Conversion

    /// Creates a SwiftUI `Color` from a hex string (e.g. "#3B82F6" or "3B82F6").
    static func color(from hex: String) -> Color {
        let (r, g, b) = rgb(from: hex)
        return Color(red: r, green: g, blue: b)
    }

    /// Parses a hex string into RGB components (0–1 range).
    static func rgb(from hex: String) -> (Double, Double, Double) {
        let cleaned = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard cleaned.count == 6,
              let int = UInt64(cleaned, radix: 16) else {
            return (0.5, 0.5, 0.5) // Fallback gray
        }
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        return (r, g, b)
    }

    /// Converts RGB (0–1) to a hex string with leading "#".
    static func hex(from color: Color) -> String {
        // Resolve in sRGB
        let resolved = color.resolve(in: .init())
        let r = Int(max(0, min(255, resolved.red * 255)))
        let g = Int(max(0, min(255, resolved.green * 255)))
        let b = Int(max(0, min(255, resolved.blue * 255)))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    // MARK: - Variant Derivation

    /// The main/bold color — the hex value as-is.
    static func boldColor(from hex: String) -> Color {
        color(from: hex)
    }

    /// A subtle, low-saturation tint for light-mode backgrounds and chips.
    /// Desaturates and lightens the base color.
    static func subtleColor(from hex: String) -> Color {
        adjustedColor(from: hex, saturationMultiplier: 0.3, brightnessOffset: 0.55)
    }

    /// An even lighter variant for secondary backgrounds.
    static func subtlerColor(from hex: String) -> Color {
        adjustedColor(from: hex, saturationMultiplier: 0.15, brightnessOffset: 0.65)
    }

    /// The lightest tint — barely visible, for card/section backgrounds.
    static func subtlestColor(from hex: String) -> Color {
        adjustedColor(from: hex, saturationMultiplier: 0.08, brightnessOffset: 0.72)
    }

    /// A dark-mode–friendly version of the subtle color.
    /// Higher saturation, lower brightness to look good on dark backgrounds.
    static func darkSubtleColor(from hex: String) -> Color {
        adjustedColor(from: hex, saturationMultiplier: 0.5, brightnessOffset: -0.35)
    }

    /// A dark-mode bold variant — slightly desaturated to reduce glare.
    static func darkBoldColor(from hex: String) -> Color {
        adjustedColor(from: hex, saturationMultiplier: 0.85, brightnessOffset: -0.1)
    }

    // MARK: - Internal

    /// Adjusts a hex color's HSB values.
    private static func adjustedColor(
        from hex: String,
        saturationMultiplier: Double,
        brightnessOffset: Double
    ) -> Color {
        let (r, g, b) = rgb(from: hex)
        var (h, s, br) = rgbToHSB(r: r, g: g, b: b)

        s *= saturationMultiplier
        br = max(0, min(1, br + brightnessOffset))

        return Color(hue: h, saturation: s, brightness: br)
    }

    /// Converts RGB (0–1) to HSB (0–1).
    private static func rgbToHSB(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        // Brightness
        let brightness = maxC

        // Saturation
        let saturation = maxC == 0 ? 0 : delta / maxC

        // Hue
        var hue: Double = 0
        if delta > 0 {
            if maxC == r {
                hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxC == g {
                hue = ((b - r) / delta) + 2
            } else {
                hue = ((r - g) / delta) + 4
            }
            hue /= 6
            if hue < 0 { hue += 1 }
        }

        return (hue, saturation, brightness)
    }
}
