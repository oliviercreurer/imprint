import SwiftUI

/// The custom footer overlay with gradient fade, search bar, and toolbar icons.
struct FooterToolbar: View {

    @Binding var searchText: String
    let isDark: Bool
    let placeholder: String
    let allExpanded: Bool
    let onAdd: () -> Void
    let onToggleExpand: () -> Void

    private var bgColor: Color { isDark ? ImprintColors.primary : ImprintColors.paper }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .bottom) {
                // Gradient fade
                LinearGradient(
                    colors: [bgColor.opacity(0), bgColor],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.35)
                )
                .allowsHitTesting(false)

                VStack(spacing: 16) {
                    // Search bar
                    HStack(spacing: 0) {
                        TextField("", text: $searchText, prompt:
                            Text(placeholder)
                                .font(ImprintFonts.searchPlaceholder)
                                .foregroundStyle(isDark ? ImprintColors.darkSecondary : ImprintColors.secondary)
                        )
                        .font(ImprintFonts.searchPlaceholder)
                        .foregroundStyle(isDark ? ImprintColors.paper : ImprintColors.primary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(isDark ? ImprintColors.darkSurfaceBg : ImprintColors.searchBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder,
                                lineWidth: 2
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Toolbar row — ZStack so + button is always dead center
                    ZStack {
                        // Add button (absolutely centered)
                        Button(action: onAdd) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(isDark ? ImprintColors.primary : ImprintColors.paper)
                                .frame(width: 48, height: 48)
                                .background(isDark ? ImprintColors.paper : ImprintColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        // Side icons
                        HStack {
                            // Settings
                            Button {
                                // TODO: Settings action
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 20))
                                    .foregroundStyle(isDark ? ImprintColors.paper : ImprintColors.primary)
                                    .frame(width: 24, height: 24)
                            }

                            Spacer()

                            // Expand / Collapse all
                            Button {
                                onToggleExpand()
                            } label: {
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 20))
                                    .foregroundStyle(isDark ? ImprintColors.paper : ImprintColors.primary)
                                    .frame(width: 24, height: 24)
                                    .rotationEffect(.degrees(allExpanded ? 0 : 180))
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .frame(height: 200)
        }
    }
}
