import SwiftUI
import SwiftData

struct SettingsView: View {

    @AppStorage("appearanceMode") private var appearanceMode = "light"

    @Query(sort: \Category.sortOrder)
    private var allCategories: [Category]

    private var enabledCount: Int { allCategories.filter(\.isEnabled).count }
    private var isDarkMode: Bool { appearanceMode == "dark" }

    @State private var showingCategoryEditor = false
    @State private var editingCategory: Category?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // ── Appearance ────────────────────────────────
                Text("Appearance")
                    .font(ImprintFonts.platypiSemiBold(16))
                    .foregroundStyle(ImprintColors.paper)
                    .staggeredAppearance(index: 0)

                appearanceSegmentedControl
                    .staggeredAppearance(index: 1)

                // ── Categories ────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(ImprintFonts.platypiSemiBold(16))
                        .foregroundStyle(ImprintColors.paper)

                    Text("Toggle categories on or off. Disabled categories are hidden but their records are preserved.")
                        .font(ImprintFonts.platypiLight(16))
                        .foregroundStyle(ImprintColors.accentBlueLight)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .staggeredAppearance(index: 2)

                // ── Toggle rows ────────────────────────────────
                VStack(spacing: 4) {
                    ForEach(Array(allCategories.enumerated()), id: \.element.persistentModelID) { offset, category in
                        categoryRow(category)
                            .staggeredAppearance(index: offset + 3)
                    }

                    // Add category button
                    Button {
                        editingCategory = nil
                        showingCategoryEditor = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(ImprintColors.accentBlueLight)
                                .frame(width: 10, height: 10)

                            Text("Add Category")
                                .font(ImprintFonts.jetBrainsMedium(14))
                                .foregroundStyle(ImprintColors.accentBlueLight)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(ImprintColors.accentBlueLight.opacity(0.3), lineWidth: 1, antialiased: true)
                        )
                    }
                    .buttonStyle(.plain)
                    .staggeredAppearance(index: allCategories.count + 3)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .padding(.bottom, 220)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingCategoryEditor) {
            CategoryEditorView(existingCategory: editingCategory)
        }
    }

    // MARK: - Appearance Segmented Control

    private var appearanceSegmentedControl: some View {
        GeometryReader { geo in
            let segmentWidth = geo.size.width / 2
            let pillOffset = isDarkMode ? segmentWidth : 0

            ZStack(alignment: .leading) {
                // Sliding pill
                RoundedRectangle(cornerRadius: 5)
                    .fill(ImprintColors.paper)
                    .frame(width: segmentWidth, height: 40)
                    .offset(x: pillOffset)

                // Labels
                HStack(spacing: 0) {
                    Button {
                        appearanceMode = "light"
                    } label: {
                        Text("Light")
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(!isDarkMode ? ImprintColors.accentBlueBolder : ImprintColors.paper)
                            .frame(width: segmentWidth, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        appearanceMode = "dark"
                    } label: {
                        Text("Dark")
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(isDarkMode ? ImprintColors.accentBlueBolder : ImprintColors.paper)
                            .frame(width: segmentWidth, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isDarkMode)
        }
        .frame(height: 40)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ImprintColors.accentBlueBolder)
        )
    }

    // MARK: - Category Row

    private func categoryRow(_ category: Category) -> some View {
        let isLastEnabled = category.isEnabled && enabledCount == 1

        return HStack(spacing: 12) {
            // Legend square
            RoundedRectangle(cornerRadius: 1)
                .fill(ColorDerivation.subtleColor(from: category.colorHex))
                .frame(width: 10, height: 10)

            // Category name — tap to edit
            Button {
                editingCategory = category
                showingCategoryEditor = true
            } label: {
                HStack(spacing: 6) {
                    Text(category.name)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(category.isEnabled ? ImprintColors.paper : ImprintColors.accentBlueLight)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ImprintColors.accentBlueLight.opacity(0.5))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            ImprintToggle(isOn: Binding(
                get: { category.isEnabled },
                set: { newValue in
                    guard !isLastEnabled else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        category.isEnabled = newValue
                    }
                }
            ))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ImprintColors.settingsRowBg)
        )
        .opacity(isLastEnabled ? 0.5 : 1.0)
    }
}
