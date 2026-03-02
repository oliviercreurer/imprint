import SwiftUI

/// A custom date picker trigger styled with Imprint design tokens.
///
/// Displays either a "Select date" prompt or a formatted date with a clear button.
/// Tapping opens a sheet with the custom `ImprintCalendarView` calendar grid.
struct ImprintDatePicker: View {

    @Binding var selection: Date
    @Binding var hasSetDate: Bool

    @State private var showingCalendar = false

    var body: some View {
        HStack {
            if hasSetDate {
                Button {
                    showingCalendar = true
                } label: {
                    Text(formattedDate(selection))
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    hasSetDate = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ImprintColors.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showingCalendar = true
                } label: {
                    Text("Select date")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.secondary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(ImprintColors.searchBg)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(ImprintColors.searchBorder, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $showingCalendar) {
            ImprintCalendarView(selection: $selection)
                .onDisappear {
                    // If the user picked a date (or already had one), mark as set
                    hasSetDate = true
                }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}
