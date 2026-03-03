import SwiftUI

struct SettingsView: View {

    @AppStorage("disabledMediaTypes") private var disabledMediaTypesRaw = ""

    private var enabledTypes: [MediaType] {
        enabledMediaTypes(disabledRaw: disabledMediaTypesRaw)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // ── Enabled Media Types ────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enabled Media Types")
                        .font(ImprintFonts.platypiSemiBold(16))
                        .foregroundStyle(ImprintColors.paper)

                    Text("All media types are enabled by default, but you can turn some off. If you've already added items for a type you wish to disable, we'll simply hide those entries instead of deleting them.")
                        .font(ImprintFonts.platypiLight(16))
                        .foregroundStyle(ImprintColors.accentBlueLight)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .staggeredAppearance(index: 0)

                // ── Toggle rows ────────────────────────────────
                VStack(spacing: 4) {
                    ForEach(Array(MediaType.allCases.enumerated()), id: \.element.id) { offset, type in
                        mediaTypeRow(type)
                            .staggeredAppearance(index: offset + 1)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .padding(.bottom, 220)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Media Type Row

    private func mediaTypeRow(_ type: MediaType) -> some View {
        let isEnabled = enabledTypes.contains(type)
        let isLastEnabled = isEnabled && enabledTypes.count == 1

        return HStack(spacing: 12) {
            // Legend square
            RoundedRectangle(cornerRadius: 1)
                .fill(type.subtleColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .strokeBorder(type.subtleColor, lineWidth: 2)
                )
                .frame(width: 10, height: 10)

            Text(type.settingsLabel)
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(isEnabled ? ImprintColors.paper : ImprintColors.accentBlueLight)

            Spacer()

            ImprintToggle(isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    guard !isLastEnabled else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        disabledMediaTypesRaw = toggleMediaType(type, disabledRaw: disabledMediaTypesRaw)
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
