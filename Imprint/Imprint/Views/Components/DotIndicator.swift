import SwiftUI

/// A dot indicator showing the current page.
///
/// Three dots (6×6 pt each, 5 pt spacing) inside a pill-shaped
/// background. Active page highlighted in bold color, inactive
/// pages in a subtle tone. No border.
struct DotIndicator: View {

    let currentPage: RecordType
    var isDark: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(RecordType.allPages) { page in
                Circle()
                    .fill(page == currentPage ? activeColor : inactiveColor)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(pillBackground)
        )
    }

    // MARK: - Colors

    private var activeColor: Color {
        isDark ? ImprintColors.paper : ImprintColors.primary
    }

    private var inactiveColor: Color {
        isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder
    }

    private var pillBackground: Color {
        isDark ? ImprintColors.darkSurfaceBg : ImprintColors.searchBg
    }
}
