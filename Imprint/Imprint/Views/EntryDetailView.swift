import SwiftUI
import SwiftData

// MARK: - Entry Detail View (VIEW Sheet)
// Figma: entry-view (node 119:3153)
// Presents a read-only view of a single record's data.
//
// Layout (top → bottom):
//   1. ImprintEntryHeader — category pill, optional date, close button, title, divider
//   2. ScrollView of field values rendered via ImprintEntryItem / ImprintEntrySlider
//   3. Footer — gradient fade + Edit button (right-aligned)
//
// Presented as a sheet with presentationCornerRadius.
// Background: neutralSubtlest.

struct EntryDetailView: View {

    @Bindable var record: Record
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    /// Tracks pre-edit record type to detect queue→log transitions.
    @State private var typeBeforeEdit: RecordType?

    /// Called when an edit moves a queued item to the log, passing the record name.
    var onMovedToLog: ((String) -> Void)? = nil

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ImprintSpacing.space300) {
                // ── Header ─────────────────────────────────────
                headerSection

                // ── Field values ──────────────────────────────
                fieldValuesSection
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.top, ImprintSpacing.space800)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            footerBar
        }
        .background(ImprintColors.neutralSubtlest.ignoresSafeArea())
        .presentationCornerRadius(ImprintSpacing.radius500)
        .onChange(of: record.recordTypeRaw) { oldValue, newValue in
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
        .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(record)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(record.name)\"? This can't be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ImprintEntryHeader(
            title: record.name,
            categoryName: record.category?.name ?? "Uncategorized",
            categoryIcon: categoryIcon,
            recordType: record.recordType,
            dateString: formattedDate,
            onClose: { dismiss() }
        )
    }

    private var categoryIcon: some View {
        Group {
            if let iconName = record.category?.iconName {
                IconoirCatalog.icon(for: iconName)
            } else {
                Image(systemName: "square.grid.2x2")
            }
        }
    }

    /// Formatted date string for logged entries (MM.dd.yy).
    private var formattedDate: String? {
        guard record.recordType == .logged, let date = record.finishedOn else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yy"
        return formatter.string(from: date)
    }

    // MARK: - Field Values

    @ViewBuilder
    private var fieldValuesSection: some View {
        let values = record.sortedFieldValues.filter { $0.hasValue }

        if values.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: ImprintSpacing.space300) {
                ForEach(values) { fieldValue in
                    if let definition = fieldValue.fieldDefinition {
                        fieldValueView(for: fieldValue, definition: definition)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fieldValueView(for fieldValue: FieldValue, definition: FieldDefinition) -> some View {
        switch definition.fieldType {
        case .checkbox:
            ImprintEntryItem(
                label: definition.label,
                style: .checkbox,
                boolValue: fieldValue.boolValue ?? false
            )

        case .url:
            ImprintEntryItem(
                label: definition.label,
                style: .url,
                urlString: fieldValue.textValue
            )

        case .image, .attachment:
            if let path = fieldValue.imagePath,
               let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = docsDir.appendingPathComponent(path)
                if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                    ImprintEntryItem(
                        label: definition.label,
                        style: .image,
                        image: uiImage
                    )
                }
            }

        case .slider:
            ImprintEntrySlider(
                label: definition.label,
                value: fieldValue.numberValue ?? definition.sliderMin ?? 1,
                min: definition.sliderMin ?? 1,
                max: definition.sliderMax ?? 5,
                step: definition.sliderStep ?? 1
            )

        case .date:
            ImprintEntryItem(
                label: definition.label,
                style: .generic,
                textValue: fieldValue.displayValue
            )

        case .shortText, .longText, .number, .country:
            ImprintEntryItem(
                label: definition.label,
                style: .generic,
                textValue: fieldValue.displayValue
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: ImprintSpacing.space100) {
            Text("No details recorded")
                .font(ImprintFonts.body16Regular)
                .foregroundStyle(ImprintColors.textSubtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, ImprintSpacing.space700)
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack {
            // Delete button (subtle)
            Button {
                showingDeleteConfirmation = true
            } label: {
                Text("Delete...")
                    .font(ImprintFonts.technical14Medium)
                    .foregroundStyle(ImprintColors.redBold)
                    .padding(.horizontal, ImprintSpacing.space400)
                    .frame(height: ImprintSpacing.size800)
                    .background(ImprintColors.redSubtlest)
                    .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
            }
            .buttonStyle(.plain)

            Spacer()

            // Edit button
            Button {
                typeBeforeEdit = record.recordType
                showingEditSheet = true
            } label: {
                Text("Edit")
                    .font(ImprintFonts.technical14Medium)
                    .foregroundStyle(ImprintColors.textInverse)
                    .padding(.horizontal, ImprintSpacing.space500)
                    .frame(height: ImprintSpacing.size800)
                    .background(ImprintColors.blueBold)
                    .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ImprintSpacing.space600)
        .padding(.top, ImprintSpacing.space500)
        .padding(.bottom, ImprintSpacing.space200)
        .background(ImprintColors.neutralSubtlest)
    }
}

// MARK: - Preview

#Preview("Entry Detail — Logged") {
    Text("Entry Detail")
        .sheet(isPresented: .constant(true)) {
            // Preview placeholder — real usage requires a Record
            VStack {
                Text("EntryDetailView preview requires a model context with sample data.")
                    .font(ImprintFonts.body16Regular)
                    .foregroundStyle(ImprintColors.textSubtle)
                    .padding()
            }
            .background(ImprintColors.neutralSubtlest)
            .presentationCornerRadius(ImprintSpacing.radius500)
        }
}
