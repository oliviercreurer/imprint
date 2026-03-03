import SwiftUI

/// A horizontal row of filter chips for selecting a media type.
/// Matches the Figma design: small rounded-rect chips with media-type colors.
struct MediaFilterBar: View {

    @Binding var selection: MediaType?

    /// Whether to use dark-mode styling (for Queue view).
    var isDark: Bool = false

    @Environment(\.enabledMediaTypes) private var enabledTypes

    var body: some View {
        HStack(spacing: 8) {
            // "All" chip — hidden when only one type is enabled
            if enabledTypes.count > 1 {
                FilterChip(
                    label: "All",
                    isSelected: selection == nil,
                    selectedBg: isDark ? ImprintColors.paper : ImprintColors.primary,
                    selectedText: isDark ? ImprintColors.primary : ImprintColors.paper,
                    unselectedBg: isDark ? ImprintColors.primary : ImprintColors.paper,
                    unselectedBorder: isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.secondary,
                    unselectedText: isDark ? ImprintColors.paper : ImprintColors.primary
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = nil
                    }
                }
            }

            ForEach(enabledTypes) { type in
                FilterChip(
                    label: type.label,
                    isSelected: selection == type,
                    selectedBg: isDark ? type.darkSubtleColor : type.subtleColor,
                    selectedText: isDark ? ImprintColors.paper : .white,
                    unselectedBg: isDark ? ImprintColors.primary : ImprintColors.paper,
                    unselectedBorder: isDark ? type.darkSubtlerColor : type.subtlerColor,
                    unselectedText: isDark ? type.darkBoldColor : type.boldColor
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = (selection == type) ? nil : type
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let selectedBg: Color
    let selectedText: Color
    let unselectedBg: Color
    let unselectedBorder: Color
    let unselectedText: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(ImprintFonts.filterChip)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(isSelected ? selectedBg : unselectedBg)
                .foregroundStyle(isSelected ? selectedText : unselectedText)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isSelected ? Color.clear : unselectedBorder,
                            lineWidth: 2
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection: MediaType? = nil
    VStack {
        MediaFilterBar(selection: $selection)
        MediaFilterBar(selection: $selection, isDark: true)
            .padding()
            .background(ImprintColors.primary)
    }
}
