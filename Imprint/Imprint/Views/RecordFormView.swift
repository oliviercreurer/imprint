import SwiftUI
import SwiftData

/// A universal modal form for creating or editing a record in any category.
///
/// Dynamically renders fields from the selected category's `FieldDefinition`s.
///
/// Layout: pinned title bar → scrollable form → bottom fade + save button.
/// Fields: Name (required) → Date (for logged) → dynamic fields → Note.
struct RecordFormView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    private var isDark: Bool { appearanceMode == "dark" }

    /// All enabled categories, sorted by display order.
    @Query(filter: #Predicate<Category> { $0.isEnabled }, sort: \Category.sortOrder)
    private var enabledCategories: [Category]

    /// If set, we're editing an existing record.
    var existingRecord: Record?

    /// The category to pre-select (used when adding from the footer menu).
    var initialCategory: Category?

    /// The initial record type context (logged vs queued).
    var initialRecordType: RecordType

    /// When true, pre-populates from existingRecord but creates a new entry.
    var isRelogging: Bool = false

    // MARK: - Form State

    @State private var selectedCategory: Category?
    @State private var recordType: RecordType
    @State private var name: String = ""
    @State private var note: String = ""
    @State private var finishedOn: Date = Date()
    @State private var hasSetDate = false

    /// Dynamic field values keyed by FieldDefinition's persistentModelID.
    /// Text and number fields store strings; date fields store Date; image fields store Data.
    @State private var textValues: [PersistentIdentifier: String] = [:]
    @State private var dateValues: [PersistentIdentifier: Date] = [:]
    @State private var imageDataValues: [PersistentIdentifier: Data] = [:]
    @State private var boolValues: [PersistentIdentifier: Bool] = [:]

    private var isEditing: Bool { existingRecord != nil && !isRelogging }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedCategory != nil
    }

    // MARK: - Init

    init(
        initialRecordType: RecordType = .logged,
        initialCategory: Category? = nil,
        existingRecord: Record? = nil,
        isRelogging: Bool = false
    ) {
        self.initialRecordType = initialRecordType
        self.initialCategory = initialCategory
        self.existingRecord = existingRecord
        self.isRelogging = isRelogging
        _recordType = State(initialValue: existingRecord?.recordType ?? initialRecordType)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pinned title bar
            HStack {
                Text(isEditing ? "Edit Entry" : (recordType == .logged ? "New Log Entry" : "New Queue Entry"))
                    .font(ImprintFonts.modalTitle)
                    .foregroundStyle(ImprintColors.headingText(isDark))

                Spacer()

                Button {
                    dismiss()
                } label: {
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

            // Scrollable form content
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Category chips
                        categoryChips

                        // Log / Queue toggle (hidden when editing)
                        if !isEditing {
                            recordTypeToggle
                        }

                        // Date (for logged records)
                        if recordType == .logged {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Date")
                                        .font(ImprintFonts.formLabel)
                                        .foregroundStyle(ImprintColors.headingText(isDark))
                                    Spacer()
                                    Text("Required")
                                        .font(ImprintFonts.formLabel)
                                        .foregroundStyle(ImprintColors.required)
                                }
                                ImprintDatePicker(selection: $finishedOn, hasSetDate: $hasSetDate)
                            }
                        }

                        // Name
                        FormField(label: "Name", isRequired: true, isDark: isDark) {
                            TextField("", text: $name)
                                .font(ImprintFonts.formValue)
                                .foregroundStyle(ImprintColors.modalText(isDark))
                        }

                        // Dynamic fields from category
                        if let category = selectedCategory {
                            ForEach(category.sortedFieldDefinitions) { definition in
                                dynamicField(for: definition)
                            }
                        }

                        // Note
                        FormField(label: "Note", isDark: isDark) {
                            TextEditor(text: $note)
                                .font(ImprintFonts.noteBody)
                                .foregroundStyle(ImprintColors.modalText(isDark))
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
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
                            saveRecord()
                            dismiss()
                        } label: {
                            Text(isEditing ? "Save" : "Add Entry")
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
        .onAppear(perform: populateInitialState)
        .presentationCornerRadius(42)
        .keyboardDoneBar()
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(enabledCategories) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            IconoirCatalog.icon(for: category.iconName)
                                .frame(width: 12, height: 12)
                            Text(category.name)
                                .font(ImprintFonts.jetBrainsMedium(14))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            selectedCategory?.persistentModelID == category.persistentModelID
                                ? ColorDerivation.boldColor(from: category.colorHex)
                                : ImprintColors.chipInactiveFill(isDark)
                        )
                        .foregroundStyle(
                            selectedCategory?.persistentModelID == category.persistentModelID
                                ? .white
                                : ImprintColors.chipInactiveText(isDark)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Record Type Toggle

    private var recordTypeToggle: some View {
        HStack(spacing: 0) {
            ForEach([RecordType.logged, RecordType.queued], id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        recordType = type
                    }
                } label: {
                    Text(type == .logged ? "Log" : "Queue")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(recordType == type ? ImprintColors.ctaText(isDark) : ImprintColors.headingText(isDark))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(recordType == type ? ImprintColors.ctaFill(isDark) : ImprintColors.inputBg(isDark))
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
        )
    }

    // MARK: - Dynamic Field Rendering

    @ViewBuilder
    private func dynamicField(for definition: FieldDefinition) -> some View {
        let id = definition.persistentModelID

        switch definition.fieldType {
        case .shortText, .url, .country:
            FormField(label: definition.label, isRequired: definition.isRequired, isDark: isDark) {
                TextField("", text: textBinding(for: id))
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
                    .keyboardType(definition.fieldType == .url ? .URL : .default)
            }

        case .longText:
            FormField(label: definition.label, isRequired: definition.isRequired, isDark: isDark) {
                TextField("", text: textBinding(for: id), axis: .vertical)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
                    .lineLimit(3...6)
            }

        case .number:
            FormField(label: definition.label, isRequired: definition.isRequired, isDark: isDark) {
                TextField("", text: textBinding(for: id))
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
                    .keyboardType(.decimalPad)
            }

        case .slider:
            FormField(label: definition.label, isRequired: definition.isRequired, isDark: isDark) {
                TextField("", text: textBinding(for: id))
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
                    .keyboardType(.numberPad)
            }

        case .checkbox:
            FormField(label: definition.label, isRequired: definition.isRequired, isDark: isDark) {
                Toggle("", isOn: boolBinding(for: id))
                    .labelsHidden()
            }

        case .date:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(definition.label)
                        .font(ImprintFonts.formLabel)
                        .foregroundStyle(ImprintColors.headingText(isDark))
                    if definition.isRequired {
                        Spacer()
                        Text("Required")
                            .font(ImprintFonts.formLabel)
                            .foregroundStyle(ImprintColors.required)
                    }
                }
                ImprintDatePicker(
                    selection: dateBinding(for: id),
                    hasSetDate: .constant(dateValues[id] != nil)
                )
            }

        case .image, .attachment:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(definition.label)
                        .font(ImprintFonts.formLabel)
                        .foregroundStyle(ImprintColors.headingText(isDark))
                    if definition.isRequired {
                        Spacer()
                        Text("Required")
                            .font(ImprintFonts.formLabel)
                            .foregroundStyle(ImprintColors.required)
                    }
                }
                ImageFieldView(
                    imageData: imageBinding(for: id),
                    isDark: isDark
                )
            }
        }
    }

    // MARK: - Value Bindings

    private func textBinding(for id: PersistentIdentifier) -> Binding<String> {
        Binding(
            get: { textValues[id] ?? "" },
            set: { textValues[id] = $0 }
        )
    }

    private func boolBinding(for id: PersistentIdentifier) -> Binding<Bool> {
        Binding(
            get: { boolValues[id] ?? false },
            set: { boolValues[id] = $0 }
        )
    }

    private func dateBinding(for id: PersistentIdentifier) -> Binding<Date> {
        Binding(
            get: { dateValues[id] ?? Date() },
            set: { dateValues[id] = $0 }
        )
    }

    private func imageBinding(for id: PersistentIdentifier) -> Binding<Data?> {
        Binding(
            get: { imageDataValues[id] },
            set: { imageDataValues[id] = $0 }
        )
    }

    // MARK: - Save

    private func saveRecord() {
        guard let category = selectedCategory else { return }

        let record: Record
        if let existing = existingRecord, !isRelogging {
            record = existing
        } else {
            record = Record(
                recordType: recordType,
                category: category,
                name: name.trimmingCharacters(in: .whitespaces)
            )
        }

        record.recordType = recordType
        record.category = category
        record.name = name.trimmingCharacters(in: .whitespaces)
        record.note = note.isEmpty ? nil : note

        if recordType == .logged {
            record.finishedOn = hasSetDate ? finishedOn : Date()
        } else {
            record.finishedOn = nil
            record.startedOn = nil
        }

        // If editing, remove existing field values — we'll recreate them
        if isEditing {
            for oldValue in record.fieldValues {
                modelContext.delete(oldValue)
            }
            record.fieldValues = []
        }

        // Create field values from the form state
        for definition in category.sortedFieldDefinitions {
            let fieldValue = FieldValue(fieldDefinition: definition)
            fieldValue.record = record

            let id = definition.persistentModelID

            switch definition.fieldType {
            case .shortText, .longText, .url, .country:
                let text = textValues[id]?.trimmingCharacters(in: .whitespaces) ?? ""
                fieldValue.textValue = text.isEmpty ? nil : text

            case .number, .slider:
                let text = textValues[id]?.trimmingCharacters(in: .whitespaces) ?? ""
                fieldValue.numberValue = Double(text)

            case .checkbox:
                fieldValue.boolValue = boolValues[id]

            case .date:
                fieldValue.dateValue = dateValues[id]

            case .image, .attachment:
                if let data = imageDataValues[id] {
                    let path = saveImageToDisk(data: data, recordId: record.persistentModelID, fieldId: id)
                    fieldValue.imagePath = path
                }
            }

            // Only insert field values that have content
            if fieldValue.hasValue {
                modelContext.insert(fieldValue)
                record.fieldValues.append(fieldValue)
            }
        }

        if existingRecord == nil || isRelogging {
            modelContext.insert(record)
        }
    }

    // MARK: - Image Persistence

    /// Saves image data to disk and returns the relative path.
    private func saveImageToDisk(data: Data, recordId: PersistentIdentifier, fieldId: PersistentIdentifier) -> String? {
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileName = UUID().uuidString + ".jpg"
        let imagesDir = docsDir.appendingPathComponent("images", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            let fileURL = imagesDir.appendingPathComponent(fileName)

            // Compress to JPEG
            if let uiImage = UIImage(data: data),
               let jpegData = uiImage.jpegData(compressionQuality: 0.85) {
                try jpegData.write(to: fileURL)
                return "images/\(fileName)"
            }
        } catch {
            print("Failed to save image: \(error)")
        }

        return nil
    }

    // MARK: - Populate Initial State

    private func populateInitialState() {
        if let record = existingRecord {
            // Editing or re-logging — populate from existing record
            recordType = isRelogging ? initialRecordType : record.recordType
            selectedCategory = record.category
            name = record.name
            note = isRelogging ? "" : (record.note ?? "")

            if !isRelogging, let date = record.finishedOn {
                finishedOn = date
                hasSetDate = true
            }

            // Populate dynamic field values
            for fieldValue in record.sortedFieldValues {
                guard let definition = fieldValue.fieldDefinition else { continue }
                let id = definition.persistentModelID

                switch definition.fieldType {
                case .shortText, .longText, .url, .country:
                    textValues[id] = fieldValue.textValue ?? ""
                case .number, .slider:
                    if let num = fieldValue.numberValue {
                        textValues[id] = num.truncatingRemainder(dividingBy: 1) == 0
                            ? String(Int(num))
                            : String(num)
                    }
                case .checkbox:
                    boolValues[id] = fieldValue.boolValue ?? false
                case .date:
                    dateValues[id] = fieldValue.dateValue
                case .image, .attachment:
                    if let path = fieldValue.imagePath,
                       let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = docsDir.appendingPathComponent(path)
                        imageDataValues[id] = try? Data(contentsOf: fileURL)
                    }
                }
            }
        } else {
            // New record — set initial category
            selectedCategory = initialCategory ?? enabledCategories.first

            if initialRecordType == .logged {
                hasSetDate = true
            }
        }
    }
}

// MARK: - Form Field Component

/// A labeled form field matching the Figma design.
struct FormField<Content: View>: View {
    let label: String
    var isRequired: Bool = false
    var isDark: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(ImprintFonts.formLabel)
                    .foregroundStyle(ImprintColors.headingText(isDark))

                if isRequired {
                    Spacer()
                    Text("Required")
                        .font(ImprintFonts.formLabel)
                        .foregroundStyle(ImprintColors.required)
                }
            }

            content
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 48)
                .background(ImprintColors.inputBg(isDark))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    RecordFormView()
        .modelContainer(for: [Category.self, FieldDefinition.self, FieldValue.self, Record.self], inMemory: true)
}
