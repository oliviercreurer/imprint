import SwiftUI
import SwiftData

/// A modal for creating or editing a user-defined category.
///
/// Lets users set the category name, icon, color, and manage field definitions
/// (add, remove, reorder). Integrated into Settings via SettingsView.
struct CategoryEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    private var isDark: Bool { appearanceMode == "dark" }

    /// If set, we're editing an existing category.
    var existingCategory: Category?

    // MARK: - Form State

    @State private var name: String = ""
    @State private var iconName: String = "cinema-old"
    @State private var colorHex: String = "#3B82F6"
    @State private var selectedColor: Color = .blue
    @State private var fields: [EditableField] = []
    @State private var showingDeleteConfirmation = false
    @State private var showingIconPicker = false

    private var isEditing: Bool { existingCategory != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Lightweight model for editing fields before committing to SwiftData.
    struct EditableField: Identifiable {
        let id = UUID()
        var label: String
        var fieldType: FieldType
        var isRequired: Bool
    }

    @State private var iconSearchText: String = ""

    /// Filtered icon names based on the search query.
    private var filteredIconNames: [String] {
        if iconSearchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return IconoirCatalog.allNames
        }
        let query = iconSearchText.lowercased()
        return IconoirCatalog.allNames.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(isEditing ? "Edit Category" : "New Category")
                    .font(ImprintFonts.modalTitle)
                    .foregroundStyle(ImprintColors.headingText(isDark))

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ImprintColors.headingText(isDark))
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 48)
            .padding(.bottom, 16)
            .background(ImprintColors.modalBg(isDark))

            // Scrollable form
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Name
                        FormField(label: "Name", isRequired: true, isDark: isDark) {
                            TextField("e.g. Film, Restaurant, Hike", text: $name)
                                .font(ImprintFonts.formValue)
                                .foregroundStyle(ImprintColors.modalText(isDark))
                        }

                        // Icon picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(ImprintFonts.formLabel)
                                .foregroundStyle(ImprintColors.headingText(isDark))

                            iconGrid
                        }

                        // Color picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(ImprintFonts.formLabel)
                                .foregroundStyle(ImprintColors.headingText(isDark))

                            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: selectedColor) { _, newColor in
                                    colorHex = ColorDerivation.hex(from: newColor)
                                }
                        }

                        // Preview
                        categoryPreview

                        // Fields
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fields")
                                .font(ImprintFonts.formLabel)
                                .foregroundStyle(ImprintColors.headingText(isDark))

                            ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                                fieldRow(index: index, field: field)
                            }

                            addFieldButton
                        }

                        // Delete button (editing only)
                        if isEditing, let category = existingCategory, category.canDelete {
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                Text("Delete Category")
                                    .font(ImprintFonts.jetBrainsMedium(14))
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(.red.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        } else if isEditing, let category = existingCategory, !category.canDelete {
                            Text("This category can't be deleted because it still has records.")
                                .font(ImprintFonts.jetBrainsRegular(13))
                                .foregroundStyle(ImprintColors.secondaryText(isDark))
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 200)
                }

                // Bottom fade + save button
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [ImprintColors.modalBg(isDark).opacity(0), ImprintColors.modalBg(isDark)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)

                    VStack {
                        Button {
                            saveCategory()
                            dismiss()
                        } label: {
                            Text(isEditing ? "Save" : "Create Category")
                                .font(ImprintFonts.jetBrainsMedium(16))
                                .foregroundStyle(ImprintColors.ctaText(isDark))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(canSave ? ImprintColors.ctaFill(isDark) : ImprintColors.ctaFill(isDark).opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(!canSave)
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity)
                    .background(ImprintColors.modalBg(isDark))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(ImprintColors.modalBg(isDark).ignoresSafeArea())
        .onAppear(perform: populateFromExisting)
        .presentationCornerRadius(42)
        .alert("Delete Category", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let category = existingCategory {
                    // Delete field definitions (cascade should handle this, but be explicit)
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

    // MARK: - Icon Grid

    private var iconGrid: some View {
        VStack(spacing: 8) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(ImprintColors.secondaryText(isDark))
                TextField("Search icons", text: $iconSearchText)
                    .font(ImprintFonts.jetBrainsRegular(13))
                    .foregroundStyle(ImprintColors.modalText(isDark))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ImprintColors.inputBg(isDark))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 1)
            )

            // Grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 8
            ) {
                ForEach(filteredIconNames, id: \.self) { icon in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            iconName = icon
                        }
                    } label: {
                        IconoirCatalog.icon(for: icon)
                            .frame(width: 18, height: 18)
                            .foregroundStyle(
                                iconName == icon
                                    ? ImprintColors.ctaText(isDark)
                                    : ImprintColors.secondaryText(isDark)
                            )
                            .frame(width: 40, height: 40)
                            .background(
                                iconName == icon
                                    ? ImprintColors.ctaFill(isDark)
                                    : ImprintColors.inputBg(isDark)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        iconName == icon ? Color.clear : ImprintColors.inputBorder(isDark),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Preview

    private var categoryPreview: some View {
        HStack(spacing: 8) {
            Text("Preview:")
                .font(ImprintFonts.formLabel)
                .foregroundStyle(ImprintColors.secondaryText(isDark))

            HStack(spacing: 6) {
                IconoirCatalog.icon(for: iconName)
                    .frame(width: 12, height: 12)
                Text(name.isEmpty ? "Category" : name)
                    .font(ImprintFonts.jetBrainsMedium(14))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(ColorDerivation.boldColor(from: colorHex))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Legend square preview
            RoundedRectangle(cornerRadius: 2)
                .fill(ColorDerivation.subtleColor(from: colorHex))
                .frame(width: 10, height: 10)
        }
    }

    // MARK: - Field Row

    private func fieldRow(index: Int, field: EditableField) -> some View {
        HStack(spacing: 12) {
            // Field type icon
            Image(systemName: field.fieldType.iconName)
                .font(.system(size: 14))
                .foregroundStyle(ImprintColors.secondaryText(isDark))
                .frame(width: 20)

            // Label
            TextField("Field name", text: Binding(
                get: { fields[index].label },
                set: { fields[index].label = $0 }
            ))
            .font(ImprintFonts.jetBrainsMedium(14))
            .foregroundStyle(ImprintColors.modalText(isDark))

            // Type picker
            Menu {
                ForEach(FieldType.allCases) { type in
                    Button {
                        fields[index].fieldType = type
                    } label: {
                        Label(type.label, systemImage: type.iconName)
                    }
                }
            } label: {
                Text(field.fieldType.label)
                    .font(ImprintFonts.jetBrainsRegular(12))
                    .foregroundStyle(ImprintColors.secondaryText(isDark))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ImprintColors.inputBg(isDark))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Remove
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    _ = fields.remove(at: index)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ImprintColors.inputBg(isDark))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Add Field Button

    private var addFieldButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                fields.append(EditableField(label: "", fieldType: .text, isRequired: false))
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text("Add Field")
                    .font(ImprintFonts.jetBrainsMedium(14))
            }
            .foregroundStyle(ImprintColors.accentBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(ImprintColors.accentBlue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private func saveCategory() {
        let category: Category
        if let existing = existingCategory {
            category = existing
        } else {
            // Determine sort order (append at end)
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

        // Reconcile field definitions
        if isEditing {
            // Simple approach: remove all and recreate
            for fd in category.fieldDefinitions {
                modelContext.delete(fd)
            }
            category.fieldDefinitions = []
        }

        // Create field definitions from the editable list
        for (index, editField) in fields.enumerated() {
            guard !editField.label.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let fd = FieldDefinition(
                label: editField.label.trimmingCharacters(in: .whitespaces),
                fieldType: editField.fieldType,
                sortOrder: index,
                isRequired: editField.isRequired
            )
            fd.category = category
            modelContext.insert(fd)
            category.fieldDefinitions.append(fd)
        }

        if existingCategory == nil {
            modelContext.insert(category)
        }
    }

    // MARK: - Populate for Editing

    private func populateFromExisting() {
        guard let category = existingCategory else { return }

        name = category.name
        iconName = category.iconName
        colorHex = category.colorHex
        selectedColor = ColorDerivation.color(from: category.colorHex)

        fields = category.sortedFieldDefinitions.map { fd in
            EditableField(
                label: fd.label,
                fieldType: fd.fieldType,
                isRequired: fd.isRequired
            )
        }
    }
}
