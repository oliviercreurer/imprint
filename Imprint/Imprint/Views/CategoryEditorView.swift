import SwiftUI
import SwiftData

// MARK: - Category Editor View
// Figma: new-category/empty (node 115:7937)
// A full-screen overlay for creating or editing a user-defined category.
//
// Layout (top → bottom, inside a ScrollView):
//   1. Header: title (Heading/H4) + close button (size/600 circle, neutral/subtler, radius/round)
//   2. Description: Body/16/Regular, text/subtle
//   3. Name input (flex) + Icon selector (48pt square)
//   4. Divider: 1pt, neutral/subtle
//   5. "Form Fields" section heading (Heading/H5) + description
//   6. Locked default fields: Name (text-square), Log date (calendar), Note (align-left)
//   7. "Add field" button: cyan/subtlest bg, cyan/subtler border, Technical/14pt/Medium
//   8. User-added custom fields (ImprintField, optional/required states)
//
// All spacing uses design tokens from ImprintSpacing.

struct CategoryEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// If set, we're editing an existing category.
    var existingCategory: Category?

    // MARK: - Form State

    @State private var name: String = ""
    @State private var iconName: String = "cinema-old"
    @State private var colorHex: String = "#3B82F6"
    @State private var fields: [EditableField] = []
    @State private var showingIconPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddField = false
    @State private var editingFieldID: FieldEditID?

    /// Identifiable wrapper for triggering the edit-field sheet.
    private struct FieldEditID: Identifiable {
        let id: UUID
    }

    private var isEditing: Bool { existingCategory != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Lightweight model for editing fields before committing to SwiftData.
    struct EditableField: Identifiable {
        let id = UUID()
        var label: String
        var fieldType: FieldType
        var isRequired: Bool
        // Slider configuration
        var sliderMin: Double = 1
        var sliderMax: Double = 5
        var sliderStep: Double = 1
        /// Links back to the SwiftData FieldDefinition when editing an existing category.
        var definitionID: PersistentIdentifier?
        /// True if this field has stored values across any records. Used to
        /// prevent destructive changes like switching the field type.
        var hasExistingData: Bool = false
    }

    // MARK: - Icon Picker State

    @State private var iconSearchText: String = ""

    private var filteredIconNames: [String] {
        if iconSearchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return IconoirCatalog.allNames
        }
        let query = iconSearchText.lowercased()
        return IconoirCatalog.allNames.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ImprintSpacing.space400) {
                // ── 1. Header ──────────────────────────────────
                headerSection

                // ── 2. Name + Icon row ────────────────────────
                nameAndIconRow

                // ── 3. Divider ────────────────────────────────
                Rectangle()
                    .fill(ImprintColors.neutralSubtle)
                    .frame(height: 1)

                // ── 4. Form Fields section ────────────────────
                formFieldsSection
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.top, ImprintSpacing.space900)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .background(ImprintColors.neutralSubtlest.ignoresSafeArea())
        .onAppear(perform: populateFromExisting)
        .presentationCornerRadius(ImprintSpacing.radius500)
        .sheet(isPresented: $showingIconPicker) {
            iconPickerSheet
        }
        .sheet(isPresented: $showingAddField) {
            AddFieldView(categoryName: name) { newField in
                withAnimation(.easeInOut(duration: 0.15)) {
                    fields.append(newField)
                }
            }
        }
        .sheet(item: $editingFieldID) { editID in
            if let index = fields.firstIndex(where: { $0.id == editID.id }) {
                AddFieldView(
                    categoryName: name,
                    existingField: fields[index]
                ) { updatedField in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        fields[index] = updatedField
                    }
                }
            }
        }
        .alert("Delete Category", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let category = existingCategory {
                    for fd in category.fieldDefinitions {
                        modelContext.delete(fd)
                    }
                    modelContext.delete(category)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(name)\"? This can't be undone.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space300) {
            // Title + close
            HStack {
                Text(isEditing ? "Edit Category" : "New Category")
                    .font(ImprintFonts.headingH4)
                    .foregroundStyle(ImprintColors.textBoldest)
                    .tracking(-0.5)

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: ImprintSpacing.size300, weight: .medium))
                        .foregroundStyle(ImprintColors.iconSubtle)
                        .frame(
                            width: ImprintSpacing.size600,
                            height: ImprintSpacing.size600
                        )
                        .background(ImprintColors.neutralSubtler)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Description
            Text("Create a new category. Set a name, an icon, and compose its form below.")
                .font(ImprintFonts.body16Regular)
                .lineSpacing(ImprintFonts.body16LineSpacing)
                .foregroundStyle(ImprintColors.textSubtle)
        }
    }

    // MARK: - Name + Icon Row

    private var nameAndIconRow: some View {
        HStack(alignment: .top, spacing: ImprintSpacing.space200) {
            // Name input (flex)
            VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
                Text("Field label")
                    .font(ImprintFonts.technical12Bold)
                    .foregroundStyle(ImprintColors.textSubtle)

                TextField("e.g. Film", text: $name)
                    .font(ImprintFonts.technical14Medium)
                    .foregroundStyle(ImprintColors.textBoldest)
                    .frame(height: ImprintSpacing.size800)
                    .padding(.horizontal, ImprintSpacing.space300)
                    .background(ImprintColors.inputSubtlest)
                    .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
            }

            // Icon selector
            VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
                Text("Icon")
                    .font(ImprintFonts.technical12Bold)
                    .foregroundStyle(ImprintColors.textSubtle)

                Button { showingIconPicker = true } label: {
                    IconoirCatalog.icon(for: iconName)
                        .frame(
                            width: ImprintSpacing.size400,
                            height: ImprintSpacing.size400
                        )
                        .foregroundStyle(ImprintColors.iconSubtle)
                        .frame(
                            width: ImprintSpacing.size800,
                            height: ImprintSpacing.size800
                        )
                        .background(ImprintColors.neutralSubtler)
                        .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.space100))
                }
                .buttonStyle(.plain)
            }
            .frame(width: ImprintSpacing.size800)
        }
    }

    // MARK: - Form Fields Section

    private var formFieldsSection: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space300) {
            // Section heading + description
            VStack(alignment: .leading, spacing: ImprintSpacing.space100) {
                Text("Form Fields")
                    .font(ImprintFonts.headingH5)
                    .foregroundStyle(ImprintColors.textBoldest)

                Text("All category forms include name, date, and note fields by default. These can't be deleted. Drag and drop your added fields to re-order them.")
                    .font(ImprintFonts.body16Regular)
                    .lineSpacing(ImprintFonts.body16LineSpacing)
                    .foregroundStyle(ImprintColors.textSubtle)
            }

            // Default locked fields + user fields
            VStack(alignment: .leading, spacing: ImprintSpacing.space100) {
                // Name (locked)
                ImprintField(
                    fieldName: "Name",
                    icon: IconoirCatalog.icon(for: "text-square"),
                    state: .locked
                )

                // Log date (locked) + helper text
                VStack(alignment: .leading, spacing: ImprintSpacing.space100) {
                    ImprintField(
                        fieldName: "Log date",
                        icon: IconoirCatalog.icon(for: "calendar"),
                        state: .locked
                    )

                    Text("The log date field will only appear if adding an entry to your log.")
                        .font(ImprintFonts.body14Medium)
                        .foregroundStyle(ImprintColors.textSubtler)
                }
            }

            // Add field button
            addFieldButton

            // User-added custom fields
            ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                userFieldRow(index: index, field: field)
            }

            // Note (locked, always last)
            ImprintField(
                fieldName: "Note",
                icon: IconoirCatalog.icon(for: "align-left"),
                state: .locked
            )

            // Delete button (editing only)
            if isEditing, let category = existingCategory, category.canDelete {
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Text("Delete Category")
                        .font(ImprintFonts.technical14Medium)
                        .foregroundStyle(ImprintColors.redBold)
                        .frame(maxWidth: .infinity)
                        .frame(height: ImprintSpacing.size800)
                        .background(
                            RoundedRectangle(cornerRadius: ImprintSpacing.radius100)
                                .strokeBorder(ImprintColors.redSubtler.opacity(0.3), lineWidth: ImprintSpacing.borderDefault)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Add Field Button

    private var addFieldButton: some View {
        Button {
            showingAddField = true
        } label: {
            Text("Add field")
                .font(ImprintFonts.technical14Medium)
                .foregroundStyle(ImprintColors.textBoldest)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ImprintSpacing.space300)
                .background(ImprintColors.cyanSubtlest)
                .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
                .overlay(
                    RoundedRectangle(cornerRadius: ImprintSpacing.radius100)
                        .strokeBorder(ImprintColors.cyanSubtler, lineWidth: ImprintSpacing.borderDefault)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - User Field Row

    private func userFieldRow(index: Int, field: EditableField) -> some View {
        Button {
            editingFieldID = FieldEditID(id: field.id)
        } label: {
            ImprintField(
                fieldName: field.label.isEmpty ? field.fieldType.label : field.label,
                icon: IconoirCatalog.icon(for: field.fieldType.iconoirName),
                state: field.isRequired ? .required : .optional
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                editingFieldID = FieldEditID(id: field.id)
            } label: {
                Label("Edit Field", systemImage: "pencil")
            }

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    fields[index].isRequired.toggle()
                }
            } label: {
                Label(
                    field.isRequired ? "Make Optional" : "Make Required",
                    systemImage: field.isRequired ? "checkmark.circle" : "exclamationmark.circle"
                )
            }

            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    _ = fields.remove(at: index)
                }
            } label: {
                Label("Remove Field", systemImage: "trash")
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack {
            Button {
                saveCategory()
                dismiss()
            } label: {
                Text(isEditing ? "Save" : "Create Category")
                    .font(ImprintFonts.technical14Medium)
                    .foregroundStyle(ImprintColors.textInverse)
                    .frame(maxWidth: .infinity)
                    .frame(height: ImprintSpacing.size800)
                    .background(
                        canSave
                            ? ImprintColors.neutralBoldest
                            : ImprintColors.neutralBoldest.opacity(0.3)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, ImprintSpacing.space600)
        .padding(.top, ImprintSpacing.space500)
        .padding(.bottom, ImprintSpacing.space200)
        .background(ImprintColors.neutralSubtlest)
    }

    // MARK: - Icon Picker Sheet

    private var iconPickerSheet: some View {
        NavigationStack {
            VStack(spacing: ImprintSpacing.space300) {
                // Search field
                HStack(spacing: ImprintSpacing.space100) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: ImprintSpacing.size200))
                        .foregroundStyle(ImprintColors.iconSubtle)
                    TextField("Search icons", text: $iconSearchText)
                        .font(ImprintFonts.technical14Medium)
                        .foregroundStyle(ImprintColors.textBoldest)
                }
                .padding(.horizontal, ImprintSpacing.space300)
                .padding(.vertical, ImprintSpacing.space100)
                .background(ImprintColors.inputSubtlest)
                .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
                .overlay(
                    RoundedRectangle(cornerRadius: ImprintSpacing.radius100)
                        .strokeBorder(ImprintColors.inputSubtle, lineWidth: 1)
                )

                // Icon grid
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: ImprintSpacing.space100), count: 7),
                        spacing: ImprintSpacing.space100
                    ) {
                        ForEach(filteredIconNames, id: \.self) { icon in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    iconName = icon
                                }
                                showingIconPicker = false
                            } label: {
                                IconoirCatalog.icon(for: icon)
                                    .frame(width: ImprintSpacing.size300, height: ImprintSpacing.size300)
                                    .foregroundStyle(
                                        iconName == icon
                                            ? ImprintColors.textInverse
                                            : ImprintColors.iconSubtle
                                    )
                                    .frame(width: ImprintSpacing.size700, height: ImprintSpacing.size700)
                                    .background(
                                        iconName == icon
                                            ? ImprintColors.neutralBoldest
                                            : ImprintColors.neutralSubtler
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.top, ImprintSpacing.space300)
            .background(ImprintColors.neutralSubtlest.ignoresSafeArea())
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingIconPicker = false }
                        .font(ImprintFonts.technical14Medium)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Save

    private func saveCategory() {
        let category: Category
        if let existing = existingCategory {
            category = existing
        } else {
            let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
            let maxOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? -1
            category = Category(
                name: name.trimmingCharacters(in: .whitespaces),
                iconName: iconName,
                colorHex: colorHex,
                sortOrder: maxOrder + 1
            )
        }

        category.name = name.trimmingCharacters(in: .whitespaces)
        category.iconName = iconName
        category.colorHex = colorHex

        // Insert new category into the context first, so FDs can reference it
        if existingCategory == nil {
            modelContext.insert(category)
        }

        // Reconcile field definitions
        // 1. Collect IDs of fields still present in the editor
        let activeDefinitionIDs = Set(fields.compactMap(\.definitionID))

        // 2. Archive any existing definitions that were removed from the editor
        if isEditing {
            for fd in category.fieldDefinitions where !fd.isArchived {
                if !activeDefinitionIDs.contains(fd.persistentModelID) {
                    fd.isArchived = true
                }
            }
        }

        // 3. Update existing or create new field definitions
        for (index, editField) in fields.enumerated() {
            guard !editField.label.trimmingCharacters(in: .whitespaces).isEmpty else { continue }

            if let defID = editField.definitionID,
               let existing = category.fieldDefinitions.first(where: { $0.persistentModelID == defID }) {
                // Update in place — preserves all FieldValue relationships
                existing.label = editField.label.trimmingCharacters(in: .whitespaces)
                existing.fieldType = editField.fieldType
                existing.sortOrder = index
                existing.isRequired = editField.isRequired
                existing.sliderMin = editField.fieldType == .slider ? editField.sliderMin : nil
                existing.sliderMax = editField.fieldType == .slider ? editField.sliderMax : nil
                existing.sliderStep = editField.fieldType == .slider ? editField.sliderStep : nil
            } else {
                // Brand new field
                let fd = FieldDefinition(
                    label: editField.label.trimmingCharacters(in: .whitespaces),
                    fieldType: editField.fieldType,
                    sortOrder: index,
                    isRequired: editField.isRequired
                )
                if editField.fieldType == .slider {
                    fd.sliderMin = editField.sliderMin
                    fd.sliderMax = editField.sliderMax
                    fd.sliderStep = editField.sliderStep
                }
                fd.category = category
                modelContext.insert(fd)
                category.fieldDefinitions.append(fd)
            }
        }

        // Explicit save — ensures data is persisted before the sheet dismisses
        try? modelContext.save()
    }

    // MARK: - Populate for Editing

    private func populateFromExisting() {
        guard let category = existingCategory else { return }

        name = category.name
        iconName = category.iconName
        colorHex = category.colorHex

        fields = category.activeFieldDefinitions.map { fd in
            EditableField(
                label: fd.label,
                fieldType: fd.fieldType,
                isRequired: fd.isRequired,
                sliderMin: fd.sliderMin ?? 1,
                sliderMax: fd.sliderMax ?? 5,
                sliderStep: fd.sliderStep ?? 1,
                definitionID: fd.persistentModelID,
                hasExistingData: fd.hasData
            )
        }
    }
}
