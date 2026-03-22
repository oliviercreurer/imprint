import SwiftUI

// MARK: - Filter Button Component
// Figma: FilterButton (icon: alone/left/right/none, selected: bool)
// A compact filter chip used in the filter bar / toolbar.
// Height: size/600 (32pt)
// Corner radius: radius/50 (4pt)
// Padding: 10pt all sides
// Gap (icon ↔ text): space/75 (6pt)
// Icon: size/300 (16pt)
// Font: Technical/Small (JetBrains Mono Medium, size/200 12pt, height/200 16pt)
//
// Selected:
//   Background: neutral/bolder (#575653 light, #DAD8CE dark)
//   Text: text/inverse
//   Icon: icon/subtlest
// Unselected:
//   Background: neutral/subtler (#F2F0E5 light)
//   Text: text/boldest
//   Icon: icon/subtle

/// A filter chip matching the Figma FilterButton component.
struct ImprintFilterButton<Icon: View>: View {

    let isSelected: Bool
    var label: String? = nil
    var icon: Icon? = nil
    var iconPosition: IconPosition = .left
    var action: () -> Void = {}

    enum IconPosition {
        case alone  // icon only, no label
        case left   // icon before label
        case right  // icon after label
        case none   // label only
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: showsLabel ? ImprintSpacing.space75 : 0) {
                if iconPosition == .alone || iconPosition == .left, let icon {
                    icon
                        .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                        .foregroundStyle(iconColor)
                }

                if showsLabel, let label {
                    Text(label)
                        .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size200))
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                }

                if iconPosition == .right, let icon {
                    icon
                        .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                        .foregroundStyle(iconColor)
                }
            }
            .padding(10) // Figma: 10pt centering pad (between space/100 and space/200)
            .frame(minHeight: ImprintSpacing.size600)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius50))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed

    private var showsLabel: Bool {
        iconPosition != .alone
    }

    private var bgColor: Color {
        isSelected ? ImprintColors.neutralBolder : ImprintColors.neutralSubtler
    }

    private var textColor: Color {
        isSelected ? ImprintColors.textInverse : ImprintColors.textBoldest
    }

    private var iconColor: Color {
        isSelected ? ImprintColors.iconSubtlest : ImprintColors.iconSubtle
    }
}

// MARK: - Preview

#Preview("Filter Buttons") {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            ImprintFilterButton(isSelected: false, icon: Image(systemName: "line.3.horizontal.decrease"), iconPosition: .alone)
            ImprintFilterButton(isSelected: true, icon: Image(systemName: "line.3.horizontal.decrease"), iconPosition: .alone)
        }
        HStack(spacing: 8) {
            ImprintFilterButton(isSelected: false, label: "Text", icon: Image(systemName: "star"), iconPosition: .left)
            ImprintFilterButton(isSelected: true, label: "Text", icon: Image(systemName: "star"), iconPosition: .left)
        }
        HStack(spacing: 8) {
            ImprintFilterButton(isSelected: false, label: "Text", icon: Image(systemName: "chevron.down"), iconPosition: .right)
            ImprintFilterButton(isSelected: true, label: "Text", icon: Image(systemName: "chevron.down"), iconPosition: .right)
        }
        HStack(spacing: 8) {
            ImprintFilterButton<EmptyView>(isSelected: false, label: "Text", iconPosition: .none)
            ImprintFilterButton<EmptyView>(isSelected: true, label: "Text", iconPosition: .none)
        }
    }
    .padding()
    .background(ImprintColors.neutralSubtlest)
}
