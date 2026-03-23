import SwiftUI
import UIKit

// MARK: - Image Color Extraction
// Used by ImprintEntryItem's image variant to derive a background
// color from the displayed photo.

extension UIImage {

    /// Returns a muted, lightened version of the image's dominant color,
    /// suitable as a background behind the image.
    ///
    /// The algorithm downsamples to 1×1 to get the average color, then
    /// desaturates and lightens it so it works as a subtle backdrop.
    func dominantBackgroundColor(saturation: CGFloat = 0.3, brightness: CGFloat = 0.85) -> Color {
        guard let cgImage = self.cgImage else { return Color.gray.opacity(0.15) }

        // Downsample to 1×1 pixel to get the average color
        let size = CGSize(width: 1, height: 1)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var pixel: [UInt8] = [0, 0, 0, 0]
        guard let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return Color.gray.opacity(0.15)
        }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        let r = CGFloat(pixel[0]) / 255.0
        let g = CGFloat(pixel[1]) / 255.0
        let b = CGFloat(pixel[2]) / 255.0

        // Convert to HSB, then adjust for a soft background
        let uiColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        var hue: CGFloat = 0
        var sat: CGFloat = 0
        var brt: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &sat, brightness: &brt, alpha: &alpha)

        let adjustedColor = UIColor(
            hue: hue,
            saturation: min(sat, saturation),
            brightness: max(brt, brightness),
            alpha: 1.0
        )

        return Color(adjustedColor)
    }
}
