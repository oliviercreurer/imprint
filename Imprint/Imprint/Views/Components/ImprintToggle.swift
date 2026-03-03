import SwiftUI

/// A brand-styled toggle matching the Imprint design system.
///
/// 40×24 pt capsule track with a 18 pt circular thumb.
/// - ON:  dark track (`accentBlueBolder`), thumb right
/// - OFF: light track (`accentBlueLight`), thumb left
/// - Thumb color is always `paper`
struct ImprintToggle: View {

    @Binding var isOn: Bool

    private let trackWidth: CGFloat = 40
    private let trackHeight: CGFloat = 24
    private let thumbSize: CGFloat = 18
    private let thumbPadding: CGFloat = 3

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            // Track
            Capsule()
                .fill(isOn ? ImprintColors.accentBlueBolder : ImprintColors.accentBlueLight)
                .frame(width: trackWidth, height: trackHeight)

            // Thumb
            Circle()
                .fill(isOn ? ImprintColors.paper : ImprintColors.accentBlueBold)
                .frame(width: thumbSize, height: thumbSize)
                .padding(.horizontal, thumbPadding)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        .onTapGesture {
            isOn.toggle()
        }
    }
}
