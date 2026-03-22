import SwiftUI
import SwiftData

/// A collapsible month section with header, bar chart, and record rows.
/// Updated to match the Figma Log screen design:
///   - Chevron + MONTH in neutral/bold
///   - Count in cyan/bold (right-aligned)
///   - Record rows use category icons via ImprintRecordEntry
struct MonthSectionView: View {

    let group: MonthGroup
    var searchText: String = ""
    var allExpanded: Bool = true
    var expandTrigger: Int = 0
    var isDark: Bool = false
    let onTapRecord: (Record) -> Void

    @State private var isExpanded = true
    /// Tracks whether the user manually collapsed this section,
    /// so we don't fight them by auto-expanding on every keystroke.
    @State private var wasManuallyCollapsed = false

    var body: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space200) {
            // Month header
            monthHeader

            if isExpanded {
                // Record rows
                ForEach(Array(group.records.enumerated()), id: \.element.persistentModelID) { index, record in
                    Button {
                        onTapRecord(record)
                    } label: {
                        RecordRowView(record: record, isDark: isDark, showDate: true)
                    }
                    .buttonStyle(.plain)
                    .staggeredAppearance(index: index)
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded = true
                }
            } else if wasManuallyCollapsed {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded = false
                }
            }
        }
        .onChange(of: expandTrigger) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded = allExpanded
                wasManuallyCollapsed = !allExpanded
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        ImprintMonthHeader(
            month: group.monthName.uppercased(),
            count: group.totalCount,
            isExpanded: isExpanded
        ) {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
                wasManuallyCollapsed = !isExpanded
            }
        }
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
        .background(ImprintColors.neutralSubtlest)
}
