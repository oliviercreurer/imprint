import SwiftUI

// MARK: - Segmented Control
// Figma: tabs (node 120:5342)
// A multi-segment toggle with an animated sliding pill.
//
// Two sizing variants:
//   - .fill (default): pills stretch equally to fill the parent width
//   - .hug: pills shrink to fit their text content + space/300 horizontal padding
//
// Layout:
//   Outer: height 48pt, padding 4pt, radius/100 (8pt)
//   Inner pill: radius 5pt, spring animation
//   Labels: Technical/14pt/Medium (JetBrains Mono)
//
// Color props allow reuse across contexts:
//   - Settings (blue): accentBlueBolder bg, paper pill, accentBlueBolder active text, paper inactive text
//   - Neutral (default): neutral/subtle bg, neutral/subtlest pill, text/boldest active, neutral/bolder inactive

/// Sizing mode for the segmented control.
enum ImprintSegmentedSizing {
    /// Pills stretch equally to fill the parent width.
    case fill
    /// Pills hug their text content with horizontal padding.
    case hug
}

/// A reusable segmented control with an animated sliding pill.
struct ImprintSegmentedControl: View {

    @Binding var selectedIndex: Int

    let labels: [String]

    // MARK: - Layout Props

    /// How pills are sized relative to the container.
    var sizing: ImprintSegmentedSizing = .fill

    // MARK: - Color Props

    /// Background color of the entire control.
    var backgroundColor: Color = ImprintColors.neutralSubtle
    /// Fill color of the active sliding pill.
    var activePillColor: Color = ImprintColors.neutralSubtlest
    /// Text color of the selected segment.
    var activeTextColor: Color = ImprintColors.textBoldest
    /// Text color of the unselected segment.
    var inactiveTextColor: Color = ImprintColors.neutralBolder

    // MARK: - Internal State

    /// Stores measured widths of each label for the hug variant.
    @State private var labelWidths: [Int: CGFloat] = [:]

    /// Horizontal padding inside each pill for the hug variant.
    private let hugPadding: CGFloat = ImprintSpacing.space300

    var body: some View {
        switch sizing {
        case .fill:
            fillLayout
        case .hug:
            hugLayout
        }
    }

    // MARK: - Fill Layout

    private var fillLayout: some View {
        GeometryReader { geo in
            let count = max(labels.count, 1)
            let segmentWidth = geo.size.width / CGFloat(count)
            let pillOffset = CGFloat(selectedIndex) * segmentWidth

            ZStack(alignment: .leading) {
                // Sliding pill
                RoundedRectangle(cornerRadius: 5)
                    .fill(activePillColor)
                    .frame(width: segmentWidth, height: geo.size.height)
                    .offset(x: pillOffset)

                // Labels
                HStack(spacing: 0) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        Button {
                            selectedIndex = index
                        } label: {
                            Text(label)
                                .font(ImprintFonts.technical14Medium)
                                .foregroundStyle(selectedIndex == index ? activeTextColor : inactiveTextColor)
                                .frame(width: segmentWidth, height: geo.size.height)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: selectedIndex)
        }
        .frame(height: ImprintSpacing.size700)
        .padding(ImprintSpacing.space50)
        .background(
            RoundedRectangle(cornerRadius: ImprintSpacing.radius100)
                .fill(backgroundColor)
        )
    }

    // MARK: - Hug Layout

    private var hugLayout: some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                Button {
                    selectedIndex = index
                } label: {
                    Text(label)
                        .font(ImprintFonts.technical14Medium)
                        .foregroundStyle(selectedIndex == index ? activeTextColor : inactiveTextColor)
                        .padding(.horizontal, hugPadding)
                        .frame(height: ImprintSpacing.size700)
                        .background(
                            Group {
                                if selectedIndex == index {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(activePillColor)
                                }
                            }
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: selectedIndex)
        .padding(ImprintSpacing.space50)
        .background(
            RoundedRectangle(cornerRadius: ImprintSpacing.radius100)
                .fill(backgroundColor)
        )
    }
}

// MARK: - Preview

#Preview("Segmented Control") {
    VStack(alignment: .leading, spacing: 32) {
        // Fill variant (default)
        Text("Fill").font(ImprintFonts.technical12Bold).foregroundStyle(ImprintColors.textSubtle)
        ImprintSegmentedControl(
            selectedIndex: .constant(0),
            labels: ["Light", "Dark"]
        )

        // Fill variant — blue (Settings)
        Text("Fill — Blue").font(ImprintFonts.technical12Bold).foregroundStyle(ImprintColors.textSubtle)
        ImprintSegmentedControl(
            selectedIndex: .constant(0),
            labels: ["Light", "Dark"],
            backgroundColor: ImprintColors.accentBlueBolder,
            activePillColor: ImprintColors.paper,
            activeTextColor: ImprintColors.accentBlueBolder,
            inactiveTextColor: ImprintColors.paper
        )

        // Hug variant
        Text("Hug").font(ImprintFonts.technical12Bold).foregroundStyle(ImprintColors.textSubtle)
        ImprintSegmentedControl(
            selectedIndex: .constant(0),
            labels: ["Log", "Queue"],
            sizing: .hug
        )

        // Hug variant — three segments
        Text("Hug — 3 segments").font(ImprintFonts.technical12Bold).foregroundStyle(ImprintColors.textSubtle)
        ImprintSegmentedControl(
            selectedIndex: .constant(1),
            labels: ["Day", "Week", "Month"],
            sizing: .hug
        )
    }
    .padding(32)
    .background(ImprintColors.neutralSubtlest)
}
