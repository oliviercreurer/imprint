import SwiftUI

// MARK: - Page Indicator Component
// Figma: page-indicator (position: 1/2/3)
// A horizontal dot indicator showing which page is active.
// Container: neutral/subtler bg, 999px radius (pill), size/600 (32pt) height, 12pt padding
// Dots: 6pt circles, 5pt gap
// Active dot: neutral/boldest
// Inactive dot: neutral/subtle

/// A page indicator pill matching the Figma page-indicator component.
struct ImprintPageIndicator: View {

    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? ImprintColors.neutralBoldest : ImprintColors.neutralSubtle)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(12)
        .frame(height: ImprintSpacing.size600)
        .background(ImprintColors.neutralSubtler)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Page Indicator") {
    VStack(spacing: 16) {
        ImprintPageIndicator(pageCount: 3, currentPage: 0)
        ImprintPageIndicator(pageCount: 3, currentPage: 1)
        ImprintPageIndicator(pageCount: 3, currentPage: 2)
    }
    .padding()
    .background(ImprintColors.neutralSubtlest)
}
