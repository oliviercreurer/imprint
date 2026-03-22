import SwiftUI
import SwiftData

/// The Categories screen — third page in the horizontal pager.
/// Shows all user categories with log/queue counts, plus a subtitle
/// explaining the feature. Tapping a category navigates to its editor.
///
/// Figma: categories (node 115:6101)
/// Layout:
///   - Subtitle: Body/16/Regular, text/subtle — space/500 below title area
///   - Category list: VStack with space/100 gap, each item is ImprintCategoryBlock
struct CategoriesView: View {

    let isDark: Bool
    let onSelectCategory: (Category) -> Void

    @Query(sort: \Category.sortOrder)
    private var allCategories: [Category]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ImprintSpacing.space600) {
                // Subtitle
                Text("Create your own custom categories and then compose a unique form for each one.")
                    .font(ImprintFonts.body16Regular)
                    .foregroundStyle(ImprintColors.textSubtle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .staggeredAppearance(index: 0)

                // Category list
                VStack(spacing: ImprintSpacing.space100) {
                    ForEach(Array(allCategories.enumerated()), id: \.element.persistentModelID) { index, category in
                        ImprintCategoryBlock(
                            icon: IconoirCatalog.icon(for: category.iconName),
                            name: category.name,
                            logCount: logCount(for: category),
                            queueCount: queueCount(for: category)
                        ) {
                            onSelectCategory(category)
                        }
                        .staggeredAppearance(index: index + 1)
                    }
                }
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.top, ImprintSpacing.space500)
            .padding(.bottom, footerClearance)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Helpers

    private func logCount(for category: Category) -> Int {
        category.records.filter { $0.recordType == .logged }.count
    }

    private func queueCount(for category: Category) -> Int {
        category.records.filter { $0.recordType == .queued }.count
    }

    /// Bottom padding to clear the floating footer toolbar.
    private var footerClearance: CGFloat { 220 }
}
