import SwiftUI
import SwiftData

/// Wraps `RecordDetailView` and enables navigating between sibling
/// entries via left/right arrow buttons, with staggered entry/exit
/// animations on the top bar (type tag + date) and the scrollable content.
struct RecordDetailPager: View {

    let records: [Record]
    let initialIndex: Int
    var onMovedToLog: ((String) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0

    /// Prevents rapid taps during transition.
    @State private var isAnimating = false

    // MARK: - Staggered animation state

    @State private var topBarOffset: CGFloat = 0
    @State private var topBarOpacity: Double = 1
    @State private var contentOffset: CGFloat = 0
    @State private var contentOpacity: Double = 1

    /// Opaque curtain that physically hides content during the record
    /// swap, preventing any poster/image flash between entries.
    @State private var curtainOpacity: Double = 0

    /// Background color for the curtain, follows global appearance.
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    private var curtainColor: Color {
        appearanceMode == "dark" ? ImprintColors.primary : ImprintColors.paper
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            RecordDetailView(
                record: records[currentIndex],
                topBarAnimOffset: topBarOffset,
                topBarAnimOpacity: topBarOpacity,
                contentAnimOffset: contentOffset,
                contentAnimOpacity: contentOpacity,
                canGoBack: currentIndex > 0,
                canGoForward: currentIndex < records.count - 1,
                onGoBack: { navigate(direction: .backward) },
                onGoForward: { navigate(direction: .forward) },
                onMovedToLog: { name in
                    onMovedToLog?(name)
                    dismiss()
                }
            )

            // Solid curtain — sits above all content during the swap
            curtainColor
                .ignoresSafeArea()
                .opacity(curtainOpacity)
                .allowsHitTesting(false)
        }
        .onAppear { currentIndex = initialIndex }
        .transition(.move(edge: .bottom))
    }

    // MARK: - Navigation

    private enum Direction { case forward, backward }

    private func navigate(direction: Direction) {
        guard !isAnimating else { return }

        let nextIndex = direction == .forward
            ? currentIndex + 1
            : currentIndex - 1
        guard nextIndex >= 0, nextIndex < records.count else { return }

        isAnimating = true
        let exitSign: CGFloat = direction == .forward ? -1 : 1
        let enterSign: CGFloat = -exitSign

        // Phase 1: Exit — top bar leads, curtain fades in
        withAnimation(.easeIn(duration: 0.18)) {
            topBarOffset = exitSign * 32
            topBarOpacity = 0
            curtainOpacity = 1
        }

        // Phase 1b: Exit — content follows (staggered 40ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            withAnimation(.easeIn(duration: 0.16)) {
                contentOffset = exitSign * 44
                contentOpacity = 0
            }
        }

        // Phase 2: Swap record behind the opaque curtain.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                topBarOffset = enterSign * 32
                topBarOpacity = 0
                contentOffset = enterSign * 44
                contentOpacity = 0
                currentIndex = nextIndex
            }

            // Phase 3: Fade curtain out while content enters
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                // Top bar leads
                withAnimation(.easeOut(duration: 0.22)) {
                    topBarOffset = 0
                    topBarOpacity = 1
                    curtainOpacity = 0
                }

                // Content follows (staggered 50ms)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.20)) {
                        contentOffset = 0
                        contentOpacity = 1
                    }
                }

                // Unlock after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isAnimating = false
                }
            }
        }
    }
}
