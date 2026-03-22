import SwiftUI
import SwiftData

/// A horizontal row of icon-based filter buttons driven by user-defined categories.
/// Matches the Figma filter bar: "ALL" text chip + per-category icon chips,
/// with a trailing gradient fade when the row overflows.
struct MediaFilterBar: View {

    @Binding var selection: Category?
    var isDark: Bool = false

    @Query(filter: #Predicate<Category> { $0.isEnabled }, sort: \Category.sortOrder)
    private var enabledCategories: [Category]

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ImprintSpacing.space100) {
                    // "All" chip
                    if enabledCategories.count > 1 {
                        ImprintFilterButton<EmptyView>(
                            isSelected: selection == nil,
                            label: "All",
                            iconPosition: .none
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection = nil
                            }
                        }
                    }

                    // Per-category icon buttons
                    ForEach(enabledCategories) { category in
                        let isSelected = selection?.persistentModelID == category.persistentModelID

                        ImprintFilterButton(
                            isSelected: isSelected,
                            icon: IconoirCatalog.icon(for: category.iconName),
                            iconPosition: .alone
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection = isSelected ? nil : category
                            }
                        }
                    }
                }
                // Extra trailing space so the fade doesn't cover the last chip
                .padding(.trailing, 48)
            }

            // Trailing gradient fade
            LinearGradient(
                colors: [
                    ImprintColors.neutralSubtlest.opacity(0),
                    ImprintColors.neutralSubtlest
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 79, height: ImprintSpacing.size600)
            .allowsHitTesting(false)
        }
        .frame(height: ImprintSpacing.size600)
    }
}
