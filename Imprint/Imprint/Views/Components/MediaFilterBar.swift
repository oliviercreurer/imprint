import SwiftUI
import SwiftData

/// A horizontal row of filter chips driven by user-defined categories.
/// Renamed conceptually from MediaFilterBar but keeps the file name
/// for minimal project-file churn. Matches the Figma design.
struct MediaFilterBar: View {

    @Binding var selection: Category?

    /// Whether to use dark-mode styling (for Queue view).
    var isDark: Bool = false

    @Query(filter: #Predicate<Category> { $0.isEnabled }, sort: \Category.sortOrder)
    private var enabledCategories: [Category]

    var body: some View {
        HStack(spacing: 8) {
            // "All" chip — hidden when only one category is enabled
            if enabledCategories.count > 1 {
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

            ForEach(enabledCategories) { category in
                let isSelected = selection?.persistentModelID == category.persistentModelID
                let boldColor = ColorDerivation.boldColor(from: category.colorHex)
                let subtleColor = ColorDerivation.subtleColor(from: category.colorHex)
                let darkSubtleColor = ColorDerivation.darkSubtleColor(from: category.colorHex)
                let darkBoldColor = ColorDerivation.darkBoldColor(from: category.colorHex)

                FilterChip(
                    label: category.name,
                    isSelected: isSelected,
                    selectedBg: isDark ? darkSubtleColor : subtleColor,
                    selectedText: isDark ? ImprintColors.paper : .white,
                    unselectedBg: isDark ? ImprintColors.primary : ImprintColors.paper,
                    unselectedBorder: isDark ? darkBoldColor : boldColor,
                    unselectedText: isDark ? darkBoldColor : boldColor
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = isSelected ? nil : category
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
