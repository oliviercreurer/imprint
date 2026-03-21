import SwiftUI
import SwiftData

/// Shows full details for a single record as a panel overlay.
///
/// Dynamically renders field values from the record's category.
/// The top bar shows the category name as a colored chip.
struct RecordDetailView: View {

    @Bindable var record: Record
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Pager-driven animation params (neutral defaults for standalone use)
    var topBarAnimOffset: CGFloat = 0
    var topBarAnimOpacity: Double = 1
    var contentAnimOffset: CGFloat = 0
    var contentAnimOpacity: Double = 1

    // Navigation between entries (set by RecordDetailPager)
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var onGoBack: (() -> Void)? = nil
    var onGoForward: (() -> Void)? = nil

    /// Called when an edit moves a queued item to the log, passing the record name.
    var onMovedToLog: ((String) -> Void)? = nil

    /// Follows the global appearance preference.
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    private var isDark: Bool { appearanceMode == "dark" }

    @State private var showingEditSheet = false
    @State private var showingLogAgainSheet = false
    @State private var showingMoreMenu = false
    @State private var showingDeleteConfirmation = false
    /// Tracks the record type before the edit sheet opens.
    @State private var typeBeforeEdit: RecordType?
    @State private var selectedTab: DetailTab = .note

    enum DetailTab: String, CaseIterable {
        case note = "Note"
        case details = "Details"
    }

    // Theme-aware colors
    private var bgColor: Color { isDark ? ImprintColors.primary : ImprintColors.paper }
    private var textColor: Color { isDark ? ImprintColors.paper : .black }
    private var secondaryTextColor: Color { isDark ? ImprintColors.darkSecondary : ImprintColors.secondary }
    private var tertiaryTextColor: Color { isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder }
    private var buttonBorderColor: Color { isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder }

    /// Category color for the chip badge.
    private var categoryColorHex: String { record.category?.colorHex ?? "#9F9D96" }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Pinned top bar
                topBar
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
                    .padding(.bottom, 12)
                    .background(bgColor)
                    .zIndex(1)

                // Separator
                Rectangle()
                    .fill(tertiaryTextColor.opacity(0.5))
                    .frame(height: 1)
                    .zIndex(1)

                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        dynamicDetailContent
                    }
                    .padding(.top, 48)
                    .padding(.bottom, 200)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
                .offset(x: contentAnimOffset)
                .opacity(contentAnimOpacity)
            }

            // Bottom fade
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    colors: [bgColor.opacity(0), bgColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)

                bgColor
                    .frame(height: 80)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)

            // Floating bottom bar — nav buttons left, more button right
            HStack {
                // Navigation arrows — bottom-left
                if canGoBack || canGoForward {
                    navButtons
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)

            // More menu scrim
            if showingMoreMenu {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            showingMoreMenu = false
                        }
                    }
            }

            // More menu + button
            VStack(spacing: 0) {
                Spacer()

                HStack {
                    Spacer()

                    ZStack(alignment: .bottomTrailing) {
                        // Menu anchored above the button
                        if showingMoreMenu {
                            moreMenu
                                .offset(y: -58)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity
                                            .combined(with: .scale(scale: 0.85, anchor: .bottomTrailing))
                                            .combined(with: .offset(y: 6)),
                                        removal: .opacity
                                            .combined(with: .scale(scale: 0.9, anchor: .bottomTrailing))
                                    )
                                )
                        }

                        // The ··· / × button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                showingMoreMenu.toggle()
                            }
                        } label: {
                            Image(systemName: showingMoreMenu ? "xmark" : "ellipsis")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(isDark ? ImprintColors.primary : ImprintColors.paper)
                                .frame(width: 48, height: 48)
                                .background(isDark ? ImprintColors.paper : ImprintColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: showingMoreMenu ? 24 : 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(bgColor.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: record.recordTypeRaw)
        .onChange(of: record.recordTypeRaw) { oldValue, newValue in
            // Detect queue → log transition while editing
            if typeBeforeEdit == .queued,
               RecordType(rawValue: newValue) == .logged {
                typeBeforeEdit = nil
                onMovedToLog?(record.name)
            }
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            typeBeforeEdit = nil
        }) {
            RecordFormView(
                initialRecordType: record.recordType,
                initialCategory: record.category,
                existingRecord: record
            )
        }
        .sheet(isPresented: $showingLogAgainSheet) {
            RecordFormView(
                initialRecordType: .logged,
                initialCategory: record.category,
                existingRecord: record,
                isRelogging: true
            )
        }
        .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(record)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(record.name)\"? This can't be undone.")
        }
        .transition(.move(edge: .bottom))
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 8) {
            // Tag + date — animated during swipe transitions
            HStack(spacing: 8) {
                // Category chip
                Text(record.category?.name ?? "Uncategorized")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        isDark
                            ? ColorDerivation.darkSubtleColor(from: categoryColorHex)
                            : ColorDerivation.boldColor(from: categoryColorHex)
                    )
                    .foregroundStyle(
                        isDark
                            ? ColorDerivation.boldColor(from: categoryColorHex)
                            : ImprintColors.paper
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                // Date
                if let date = record.finishedOn {
                    Text(formattedDate(date))
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(secondaryTextColor)
                }
            }
            .offset(x: topBarAnimOffset)
            .opacity(topBarAnimOpacity)

            Spacer()

            // Close button — stays stationary as a stable anchor
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(buttonBorderColor, lineWidth: 2)
                    )
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navButtons: some View {
        HStack(spacing: 8) {
            Button {
                onGoBack?()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(canGoBack ? textColor : tertiaryTextColor)
                    .frame(width: 48, height: 48)
                    .background(bgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(buttonBorderColor, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)

            Button {
                onGoForward?()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(canGoForward ? textColor : tertiaryTextColor)
                    .frame(width: 48, height: 48)
                    .background(bgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(buttonBorderColor, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
    }

    // MARK: - More Menu

    private var moreMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Edit
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showingMoreMenu = false
                }
                typeBeforeEdit = record.recordType
                showingEditSheet = true
            } label: {
                Text("Edit")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 18)
            }
            .buttonStyle(.plain)

            // Log again — only for logged entries
            if record.recordType == .logged {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showingMoreMenu = false
                    }
                    showingLogAgainSheet = true
                } label: {
                    Text("Log again")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 18)
                }
                .buttonStyle(.plain)
            }

            // Delete
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showingMoreMenu = false
                }
                showingDeleteConfirmation = true
            } label: {
                Text("Delete")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(width: 162)
        .background(bgColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(buttonBorderColor, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Dynamic Detail Content

    private var dynamicDetailContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            Text(record.name)
                .font(ImprintFonts.detailSubtitle)
                .foregroundStyle(textColor)
                .multilineTextAlignment(.leading)
                .lineSpacing(0)

            // First text field value as subtitle (e.g. Director, Author)
            if let subtitle = record.firstTextFieldValue {
                Text(subtitle)
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(secondaryTextColor)
                    .offset(y: -12)
            }

            // Tab bar
            detailTabBar

            // Tab content
            Group {
                switch selectedTab {
                case .note:
                    noteTabContent
                case .details:
                    dynamicFieldsContent
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Dynamic Fields Content

    @ViewBuilder
    private var dynamicFieldsContent: some View {
        let values = record.sortedFieldValues.filter { $0.hasValue }

        if values.isEmpty {
            VStack(spacing: 8) {
                Text("No details available")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(tertiaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 32)
        } else {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(values) { fieldValue in
                    if let definition = fieldValue.fieldDefinition {
                        detailSection(definition.label) {
                            switch definition.fieldType {
                            case .text:
                                if let text = fieldValue.textValue {
                                    Text(text)
                                        .font(ImprintFonts.jetBrainsMedium(14))
                                        .foregroundStyle(textColor)
                                        .lineSpacing(4)
                                }

                            case .number:
                                if let display = fieldValue.displayValue {
                                    Text(display)
                                        .font(ImprintFonts.jetBrainsMedium(14))
                                        .foregroundStyle(textColor)
                                }

                            case .date:
                                if let display = fieldValue.displayValue {
                                    Text(display)
                                        .font(ImprintFonts.jetBrainsMedium(14))
                                        .foregroundStyle(textColor)
                                }

                            case .image:
                                if let path = fieldValue.imagePath,
                                   let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                    let fileURL = docsDir.appendingPathComponent(path)
                                    AsyncImage(url: fileURL) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(maxHeight: 260)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
        }
    }

    // MARK: - Shared Tab Bar & Note Content

    private var detailTabBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(tertiaryTextColor)
                .frame(height: 1)

            HStack(spacing: 24) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Text(tab.rawValue)
                                .font(ImprintFonts.jetBrainsMedium(14))
                                .foregroundStyle(selectedTab == tab ? textColor : secondaryTextColor)
                                .padding(.vertical, 12)

                            Rectangle()
                                .fill(selectedTab == tab ? textColor : Color.clear)
                                .frame(height: 2)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 32)

            Rectangle()
                .fill(tertiaryTextColor)
                .frame(height: 1)
        }
        .padding(.horizontal, -32) // Extend to full width from padded parent
    }

    @ViewBuilder
    private var noteTabContent: some View {
        if let note = record.note, !note.isEmpty {
            Text(note)
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(secondaryTextColor)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
        } else {
            VStack(spacing: 8) {
                Text("No note yet")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(tertiaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 32)
        }
    }

    /// A labeled section for the Details tab.
    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(tertiaryTextColor)
                .textCase(nil)

            content()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}
