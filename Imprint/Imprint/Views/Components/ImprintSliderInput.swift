import SwiftUI

// MARK: - Slider Input Component
// An interactive slider for forms that snaps to discrete tick values.
// Matches the visual style of ImprintEntrySlider (track, tick dots, labels)
// but adds tap and drag interaction with a Binding<Double>.
//
// Gesture strategy:
//   - Each tick has an invisible tap target for reliable tap-to-select
//   - A high-priority horizontal drag gesture handles slide-to-select
//     and takes precedence over the parent ScrollView's pan gesture
//
// Layout:
//   Label (Technical/12pt/Bold, text/subtle) — optional
//   Track: 4pt rounded bar (neutral/subtle) with tick dots (8pt)
//   Active indicator: filled circle (20pt) at current value (blue/bold)
//   Tick labels below each dot (Technical/12pt/Medium, text/subtle)
//   Active tick label uses text/boldest for emphasis

/// An interactive slider input that snaps to discrete tick values.
struct ImprintSliderInput: View {

    let label: String?
    @Binding var value: Double
    let min: Double
    let max: Double
    let step: Double

    // MARK: - Computed

    private var ticks: [Double] {
        let stepClamped = Swift.max(step, 0.01)
        guard max > min else { return [] }
        var result: [Double] = []
        var val = min
        while val <= max + 0.001 {
            result.append(val)
            val += stepClamped
        }
        if result.count > 20 { return Array(result.prefix(20)) }
        return result
    }

    /// Fraction 0…1 of the current value along the range.
    private var valueFraction: CGFloat {
        guard max > min else { return 0 }
        return CGFloat((value - min) / (max - min)).clamped(to: 0...1)
    }

    // MARK: - Dimensions

    private let tickDotSize: CGFloat = 8
    private let indicatorSize: CGFloat = 20
    private let labelHeight: CGFloat = 16
    private let gap: CGFloat = ImprintSpacing.space100

    // MARK: - State

    @State private var isDragging = false
    @State private var sliderWidth: CGFloat = 0

    /// Inset from each edge so the indicator center aligns with the first/last tick.
    private var inset: CGFloat { indicatorSize / 2 }

    /// The usable track width between first and last tick centers.
    private var trackWidth: CGFloat { Swift.max(sliderWidth - indicatorSize, 1) }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space100) {
            // Field label
            if let label {
                Text(label)
                    .font(ImprintFonts.technical12Bold)
                    .foregroundStyle(ImprintColors.textSubtle)
            }

            // Interactive slider area
            ZStack(alignment: .topLeading) {
                // Visual layer (track, dots, labels, indicator)
                sliderVisuals
                    .allowsHitTesting(false)

                // Interaction layer (tap targets for each tick)
                tickTapTargets
            }
            .frame(height: indicatorSize + gap + labelHeight)
            .padding(.vertical, ImprintSpacing.space100)
            // Read the rendered width so the drag handler can compute fractions
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { sliderWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, w in sliderWidth = w }
                }
            )
            // High-priority drag beats the ScrollView's pan gesture
            .highPriorityGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { gesture in
                        isDragging = true
                        let fraction = (gesture.location.x - inset) / trackWidth
                        let clamped = Double(Swift.min(Swift.max(fraction, 0), 1))
                        snapToNearest(fraction: clamped)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }

    // MARK: - Slider Visuals

    /// Pure rendering — no hit testing, drawn with GeometryReader for layout.
    private var sliderVisuals: some View {
        GeometryReader { geo in
            let count = ticks.count
            let localInset = indicatorSize / 2
            let localTrackWidth = geo.size.width - indicatorSize

            // Track line
            RoundedRectangle(cornerRadius: 2)
                .fill(ImprintColors.neutralSubtle)
                .frame(height: 4)
                .position(x: geo.size.width / 2, y: indicatorSize / 2)

            if count > 1 {
                ForEach(0..<count, id: \.self) { i in
                    let fraction = CGFloat(i) / CGFloat(count - 1)
                    let x = localInset + fraction * localTrackWidth
                    let tickValue = ticks[i]
                    let isActive = abs(tickValue - value) < 0.001

                    // Tick dot
                    Circle()
                        .fill(isActive ? ImprintColors.blueBold : ImprintColors.neutralBold)
                        .frame(width: tickDotSize, height: tickDotSize)
                        .position(x: x, y: indicatorSize / 2)

                    // Tick label
                    Text(tickValue.truncatingRemainder(dividingBy: 1) == 0
                         ? "\(Int(tickValue))"
                         : String(format: "%.1f", tickValue))
                        .font(ImprintFonts.technical12Medium)
                        .foregroundStyle(isActive ? ImprintColors.textBoldest : ImprintColors.textSubtle)
                        .fixedSize()
                        .position(x: x, y: indicatorSize + gap + labelHeight / 2)
                }
            }

            // Active value indicator
            let indicatorX = localInset + valueFraction * localTrackWidth

            Circle()
                .fill(ImprintColors.blueBold)
                .frame(width: indicatorSize, height: indicatorSize)
                .shadow(color: ImprintColors.blueBold.opacity(isDragging ? 0.3 : 0), radius: 6)
                .position(x: indicatorX, y: indicatorSize / 2)
                .animation(.easeOut(duration: 0.15), value: value)
        }
    }

    // MARK: - Tick Tap Targets

    /// Invisible buttons over each tick position for reliable tap-to-select.
    private var tickTapTargets: some View {
        GeometryReader { geo in
            let count = ticks.count
            let localInset = indicatorSize / 2
            let localTrackWidth = geo.size.width - indicatorSize

            if count > 1 {
                ForEach(0..<count, id: \.self) { i in
                    let fraction = CGFloat(i) / CGFloat(count - 1)
                    let x = localInset + fraction * localTrackWidth
                    let tickValue = ticks[i]

                    // Generous tap target centered on the tick
                    Color.clear
                        .frame(width: Swift.max(localTrackWidth / CGFloat(count - 1), 32),
                               height: indicatorSize + gap + labelHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.15)) {
                                value = tickValue
                            }
                        }
                        .position(x: x, y: (indicatorSize + gap + labelHeight) / 2)
                }
            }
        }
    }

    // MARK: - Snap Logic

    /// Snaps the value to the nearest tick given a 0…1 fraction along the track.
    private func snapToNearest(fraction: Double) {
        let raw = min + fraction * (max - min)
        guard let closest = ticks.min(by: { abs($0 - raw) < abs($1 - raw) }) else { return }
        if abs(closest - value) > 0.001 {
            value = closest
        }
    }
}

// MARK: - CGFloat Clamped

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Preview

#Preview("Slider Input") {
    struct SliderDemo: View {
        @State private var rating: Double = 3
        @State private var difficulty: Double = 1

        var body: some View {
            VStack(spacing: 32) {
                ImprintSliderInput(
                    label: "Rating",
                    value: $rating,
                    min: 1,
                    max: 5,
                    step: 1
                )

                ImprintSliderInput(
                    label: "Difficulty",
                    value: $difficulty,
                    min: 1,
                    max: 10,
                    step: 1
                )

                ImprintSliderInput(
                    label: nil,
                    value: $rating,
                    min: 0,
                    max: 4,
                    step: 0.5
                )

                Text("Rating: \(Int(rating))  |  Difficulty: \(Int(difficulty))")
                    .font(.caption)
            }
            .padding(.horizontal, 32)
            .background(ImprintColors.neutralSubtlest)
        }
    }

    return SliderDemo()
}
