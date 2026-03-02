import SwiftUI

/// A non-interactive dot indicator showing the current page in a horizontal paging layout.
///
/// Renders one dot per page inside a pill-shaped container with a subtle background.
/// The active dot slides smoothly between positions as the user swipes.
/// Colors adapt to the current theme (light or dark).
struct DotIndicator: View {

    let currentPage: RecordType
    var isDark: Bool = false

    private let dotSize: CGFloat = 6
    private let spacing: CGFloat = 6
    private let pillPaddingH: CGFloat = 10
    private let pillPaddingV: CGFloat = 10
    private let pillCornerRadius: CGFloat = 999

    var body: some View {
        ZStack {
            // Background pill
            Capsule()
                .fill(pillBackground)
                .overlay(
                    Capsule()
                        .strokeBorder(pillBorder, lineWidth: 1.5)
                )

            // Dots
            HStack(spacing: spacing) {
                ForEach(RecordType.allPages) { page in
                    Circle()
                        .fill(page == currentPage ? fillColor : fillColor.opacity(0.3))
                        .frame(width: dotSize, height: dotSize)
                        .scaleEffect(page == currentPage ? 1.0 : 0.85)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.horizontal, pillPaddingH)
            .padding(.vertical, pillPaddingV)
        }
        .fixedSize()
        .allowsHitTesting(false)
    }

    // MARK: - Colors

    private var fillColor: Color {
        isDark ? ImprintColors.paper : ImprintColors.primary
    }

    private var pillBackground: Color {
        isDark ? ImprintColors.darkSurfaceBg : ImprintColors.searchBg
    }

    private var pillBorder: Color {
        isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder
    }
}
