import SwiftUI

// MARK: - Month Header Component
// Figma: month-header
// A row showing a chevron, month name, and log count.
// Layout: HStack with space/500 (24pt) gap between month area and count
// Chevron: 16pt, nav icon
// Month text: Technical/14pt/Bold, cyan/bold
// Count text: Technical/14pt/Bold, cyan/bold

/// A month section header matching the Figma month-header component.
struct ImprintMonthHeader: View {

    let month: String
    let count: Int
    var isExpanded: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: ImprintSpacing.space500) {
                // Chevron + Month name
                HStack(spacing: ImprintSpacing.space100) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ImprintColors.cyanBold)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))

                    Text(month)
                        .font(ImprintFonts.technical14Bold)
                        .foregroundStyle(ImprintColors.cyanBold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Log count
                Text("\(count)")
                    .font(ImprintFonts.technical14Bold)
                    .foregroundStyle(ImprintColors.cyanBold)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Month Header") {
    VStack(spacing: 16) {
        ImprintMonthHeader(month: "APRIL", count: 12, isExpanded: true)
        ImprintMonthHeader(month: "MARCH", count: 8, isExpanded: false)
    }
    .padding(.horizontal, 32)
    .background(ImprintColors.neutralSubtlest)
}
