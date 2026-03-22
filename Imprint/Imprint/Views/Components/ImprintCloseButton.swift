import SwiftUI
import Iconoir

// MARK: - Close Button Component
// Figma: close-button
// Size: size/600 (32pt) circle
// Background: neutral/subtler
// Icon: size/300 (16pt), icon/subtle color
// Corner radius: radius/round (fully circular)
// Padding: 10pt (centers 16pt icon in 32pt circle)

/// A circular close button matching the Figma close-button component.
struct ImprintCloseButton: View {

    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Iconoir.xmark.asImage
                .resizable()
                .scaledToFit()
                .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                .foregroundStyle(ImprintColors.iconSubtle)
        }
        .frame(width: ImprintSpacing.size600, height: ImprintSpacing.size600)
        .background(ImprintColors.neutralSubtler)
        .clipShape(Circle())
    }
}

// MARK: - Preview

#Preview("Close Button") {
    ImprintCloseButton()
        .padding()
        .background(ImprintColors.neutralSubtlest)
}
