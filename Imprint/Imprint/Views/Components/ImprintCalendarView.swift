import SwiftUI

/// A custom calendar grid styled with Imprint design tokens.
///
/// Shows a month/year header with prev/next navigation, weekday labels,
/// and a 6×7 day grid. Selecting a day updates the binding and dismisses.
struct ImprintCalendarView: View {

    @Binding var selection: Date
    @Environment(\.dismiss) private var dismiss

    @AppStorage("appearanceMode") private var appearanceMode = "light"
    private var isDark: Bool { appearanceMode == "dark" }

    @State private var displayedMonth: Date

    private let calendar = Calendar.current
    private let weekdaySymbols = ["M", "T", "W", "T", "F", "S", "S"]

    init(selection: Binding<Date>) {
        self._selection = selection
        self._displayedMonth = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(ImprintColors.inputBorder(isDark))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 24)

            // Month/year header with navigation
            monthHeader
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

            // Weekday labels
            weekdayLabels
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            // Day grid
            dayGrid
                .padding(.horizontal, 24)

            Spacer(minLength: 16)

            // Today button
            todayButton
                .padding(.bottom, 40)
        }
        .background(ImprintColors.modalBg(isDark))
        .presentationDetents([.height(520)])
        .presentationCornerRadius(48)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = addMonths(-1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ImprintColors.headingText(isDark))
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthYearString)
                .font(ImprintFonts.jetBrainsMedium(16))
                .foregroundStyle(ImprintColors.headingText(isDark))

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = addMonths(1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ImprintColors.headingText(isDark))
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        let adjusted = adjustedWeekdaySymbols()
        return LazyVGrid(columns: gridColumns, spacing: 0) {
            ForEach(adjusted, id: \.self) { symbol in
                Text(symbol)
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(ImprintColors.secondaryText(isDark))
                    .frame(height: 32)
            }
        }
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        let days = generateDays()
        return LazyVGrid(columns: gridColumns, spacing: 4) {
            ForEach(days) { day in
                dayCell(day)
            }
        }
    }

    private func dayCell(_ day: DayItem) -> some View {
        let isSelected = day.isCurrentMonth && isSameDay(day.date, selection)
        let isToday = day.isCurrentMonth && isSameDay(day.date, Date())

        return ZStack {
            // Selected background
            if isSelected {
                Circle()
                    .fill(ImprintColors.headingText(isDark))
            }
            // Today outline (when not selected)
            else if isToday {
                Circle()
                    .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 1.5)
            }

            Text("\(day.dayNumber)")
                .font(ImprintFonts.jetBrainsRegular(14))
                .foregroundStyle(dayTextColor(day, isSelected: isSelected))
        }
        .frame(height: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            if day.isCurrentMonth {
                selection = day.date
                dismiss()
            }
        }
    }

    private func dayTextColor(_ day: DayItem, isSelected: Bool) -> Color {
        if isSelected {
            return ImprintColors.modalBg(isDark)
        } else if !day.isCurrentMonth {
            return ImprintColors.secondaryText(isDark).opacity(0.4)
        } else {
            return ImprintColors.headingText(isDark)
        }
    }

    // MARK: - Today Button

    private var todayButton: some View {
        Button {
            selection = Date()
            dismiss()
        } label: {
            Text("Today")
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.accentBlue)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grid Layout

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    }

    // MARK: - Calendar Logic

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    /// Returns weekday symbols adjusted so the week starts on the user's locale first weekday.
    private func adjustedWeekdaySymbols() -> [String] {
        // Default symbols: M T W T F S S (Monday-first)
        let allSymbols = ["M", "T", "W", "T", "F", "S", "S"]
        let firstWeekday = calendar.firstWeekday // 1 = Sunday, 2 = Monday, etc.

        if firstWeekday == 2 {
            // Monday-first (most common outside US)
            return allSymbols
        } else if firstWeekday == 1 {
            // Sunday-first
            return ["S", "M", "T", "W", "T", "F", "S"]
        } else {
            // Fallback
            return allSymbols
        }
    }

    private func addMonths(_ count: Int) -> Date {
        calendar.date(byAdding: .month, value: count, to: displayedMonth) ?? displayedMonth
    }

    private func startOfMonth(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private func daysInMonth(_ date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    /// Generates the full 6×7 grid of day items for the displayed month,
    /// including padding days from the previous and next months.
    private func generateDays() -> [DayItem] {
        let monthStart = startOfMonth(displayedMonth)
        let daysCount = daysInMonth(displayedMonth)

        // Weekday of the first day (adjusted for locale first-weekday)
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let localeFirstWeekday = calendar.firstWeekday

        // Number of preceding padding days
        var offset = firstWeekday - localeFirstWeekday
        if offset < 0 { offset += 7 }

        var days: [DayItem] = []

        // Previous month padding
        if offset > 0 {
            let prevMonth = calendar.date(byAdding: .month, value: -1, to: monthStart)!
            let prevDaysCount = daysInMonth(prevMonth)
            for i in (prevDaysCount - offset + 1)...prevDaysCount {
                let date = calendar.date(bySetting: .day, value: i, of: prevMonth) ?? prevMonth
                days.append(DayItem(date: date, dayNumber: i, isCurrentMonth: false))
            }
        }

        // Current month days
        for i in 1...daysCount {
            let date = calendar.date(bySetting: .day, value: i, of: monthStart) ?? monthStart
            days.append(DayItem(date: date, dayNumber: i, isCurrentMonth: true))
        }

        // Next month padding (fill to 42 = 6 rows × 7)
        let remaining = 42 - days.count
        if remaining > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            for i in 1...remaining {
                let date = calendar.date(bySetting: .day, value: i, of: nextMonth) ?? nextMonth
                days.append(DayItem(date: date, dayNumber: i, isCurrentMonth: false))
            }
        }

        return days
    }
}

// MARK: - Day Item Model

private struct DayItem: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
}
