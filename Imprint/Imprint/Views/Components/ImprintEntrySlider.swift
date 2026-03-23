import SwiftUI

// MARK: - Entry Slider Component
// Figma: entry-item / slider variant
// A read-only slider display for viewing a record's slider/rating value.
//
// Layout:
//   Label (Body/14pt/SemiBold, text/subtler)
//   Track: 4pt rounded bar (neutral/subtle) with tick dots (neutral/bold, 8pt)
//   Active indicator: filled circle (16pt) at the current value position (blue/bold)
//   Tick labels below each dot (Technical/12pt/Medium, text/subtle)

/// Displays a read-only slider/rating value in an entry's detail view.
struct ImprintEntrySlider: View {

    let label: String
    let value: Double
    let min: Double
    let max: Double
    let step: Double

    // MARK: - Computed

    private var ticks: [Int] {
        let stepClamped = Swift.max(step, 0.01)
        guard max > min else { return [] }
        var result: [Int] = []
        var val = min
        while val <= max + 0.001 {
            result.append(Int(val))
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
    private let indicatorSize: CGFloat = 16
    private let labelHeight: CGFloat = 16
    private let gap: CGFloat = ImprintSpacing.space100

    var body: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space100) {
            // Field label
            Text(label)
                .font(ImprintFonts.body14SemiBold)
                .foregroundStyle(ImprintColors.textSubtler)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Slider track + indicator + tick labels
            GeometryReader { geo in
                let count = ticks.count
                let inset: CGFloat = indicatorSize / 2
                let trackWidth = geo.size.width - indicatorSize

                // Track line
                RoundedRectangle(cornerRadius: 2)
                    .fill(ImprintColors.neutralSubtle)
                    .frame(height: 4)
                    .position(x: geo.size.width / 2, y: indicatorSize / 2)

                if count > 1 {
                    // Tick dots
                    ForEach(0..<count, id: \.self) { i in
                        let fraction = CGFloat(i) / CGFloat(count - 1)
                        let x = inset + fraction * trackWidth

                        Circle()
                            .fill(ImprintColors.neutralBold)
                            .frame(width: tickDotSize, height: tickDotSize)
                            .position(x: x, y: indicatorSize / 2)

                        // Tick label
                        Text("\(ticks[i])")
                            .font(ImprintFonts.technical12Medium)
                            .foregroundStyle(ImprintColors.textSubtle)
                            .fixedSize()
                            .position(x: x, y: indicatorSize + gap + labelHeight / 2)
                    }
                }

                // Active value indicator
                let indicatorX = inset + valueFraction * trackWidth

                Circle()
                    .fill(ImprintColors.blueBold)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .position(x: indicatorX, y: indicatorSize / 2)
            }
            .frame(height: indicatorSize + gap + labelHeight)
            .padding(.vertical, ImprintSpacing.space100)
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

#Preview("Entry Slider") {
    VStack(spacing: 32) {
        ImprintEntrySlider(
            label: "Rating",
            value: 3,
            min: 1,
            max: 5,
            step: 1
        )

        ImprintEntrySlider(
            label: "Difficulty",
            value: 7,
            min: 1,
            max: 10,
            step: 1
        )
    }
    .padding(.horizontal, 32)
    .background(ImprintColors.neutralSubtlest)
}
