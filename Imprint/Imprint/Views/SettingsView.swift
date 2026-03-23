import SwiftUI

struct SettingsView: View {

    @AppStorage("appearanceMode") private var appearanceMode = "light"

    /// Maps the string-based AppStorage to an integer index for the segmented control.
    private var selectedIndex: Binding<Int> {
        Binding(
            get: { appearanceMode == "dark" ? 1 : 0 },
            set: { appearanceMode = $0 == 1 ? "dark" : "light" }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // ── Appearance ────────────────────────────────
                Text("Appearance")
                    .font(ImprintFonts.outfitSemiBold(16))
                    .foregroundStyle(ImprintColors.paper)
                    .staggeredAppearance(index: 0)

                ImprintSegmentedControl(
                    selectedIndex: selectedIndex,
                    labels: ["Light", "Dark"],
                    backgroundColor: ImprintColors.accentBlueBolder,
                    activePillColor: ImprintColors.paper,
                    activeTextColor: ImprintColors.accentBlueBolder,
                    inactiveTextColor: ImprintColors.paper
                )
                .staggeredAppearance(index: 1)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .padding(.bottom, 220)
        }
        .scrollIndicators(.hidden)
    }
}
