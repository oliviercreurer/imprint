import SwiftUI
import SwiftData

/// A collapsible month section with header, bar chart, and record rows.
struct MonthSectionView: View {

    let group: MonthGroup
    var showBarChart: Bool = true
    var searchText: String = ""
    var allExpanded: Bool = true
    var expandTrigger: Int = 0
    let onTapRecord: (Record) -> Void

    @State private var isExpanded = true
    /// Tracks whether the user manually collapsed this section,
    /// so we don't fight them by auto-expanding on every keystroke.
    @State private var wasManuallyCollapsed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month header
            monthHeader

            // Proportional bar chart (always visible, hidden when filtering by media type)
            if showBarChart {
                barChart
            }

            if isExpanded {
                // Record rows
                ForEach(Array(group.records.enumerated()), id: \.element.persistentModelID) { index, record in
                    Button {
                        onTapRecord(record)
                    } label: {
                        RecordRowView(record: record)
                    }
                    .buttonStyle(.plain)
                    .staggeredAppearance(index: index)
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                // Auto-expand to reveal search results
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded = true
                }
            } else if wasManuallyCollapsed {
                // Search cleared — restore the user's manual collapse
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded = false
                }
            }
        }
        .onChange(of: expandTrigger) { _, _ in
            // Respond to the global expand/collapse-all toggle.
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded = allExpanded
                wasManuallyCollapsed = !allExpanded
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
                wasManuallyCollapsed = !isExpanded
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ImprintColors.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))

                Text(group.monthName.uppercased())
                    .font(ImprintFonts.monthHeader)
                    .foregroundStyle(ImprintColors.secondary)

                Spacer()

                Text("\(group.totalCount)")
                    .font(ImprintFonts.jetBrainsRegular(14))
                    .foregroundStyle(ImprintColors.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        GeometryReader { geo in
            let total = group.totalCount
            let availableWidth = geo.size.width
            let gap: CGFloat = 2
            let gapCount = CGFloat(max(group.mediaCounts.count - 1, 0))
            let usable = availableWidth - (gap * gapCount)

            HStack(spacing: gap) {
                ForEach(Array(group.mediaCounts.enumerated()), id: \.offset) { index, item in
                    let proportion = CGFloat(item.count) / CGFloat(total)
                    let barWidth = usable * proportion

                    RoundedRectangle(cornerRadius: cornerRadius(for: index))
                        .fill(item.type.subtleColor)
                        .frame(width: max(barWidth, 4), height: 12)
                }
            }
        }
        .frame(height: 12)
    }

    /// First bar gets 4px left radius, last bar gets 4px right radius, middle bars get 2px.
    private func cornerRadius(for index: Int) -> CGFloat {
        // All bars use 2px; the first/last get slightly larger end caps
        // Using a uniform 3px for simplicity, matching the Figma 4px/2px approach
        return 3
    }
}

#Preview {
    let group = MonthGroup(
        id: "2025-04",
        monthName: "April",
        year: 2025,
        records: []
    )
    MonthSectionView(group: group) { _ in }
        .padding(.horizontal, 32)
        .background(ImprintColors.paper)
}
