import SwiftUI
import SwiftData

// MARK: - Record Form View
// Figma: entry-edit (node 119:3382)
// A modal form for creating or editing a record.
//
// Layout (top → bottom):
//   1. Header: "New Log Entry" / "New Queue Entry" / "Edit Entry" (H5) + close button
//   2. Divider
//   3. Tabs + Category badge row:
//      - Left: ImprintSegmentedControl (.hug) for Log/Queue (hidden when editing)
//      - Right: ImprintCategoryBadge (cyan for log, yellow for queue)
//   4. Form fields: Name, Date (log only), dynamic fields, Note
//   5. Footer: gradient fade + Save button (right-aligned)
//
// Category is locked to whatever was selected before opening the form.

struct RecordFormView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

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
    @State private var textValues: [PersistentIdentifier: String] = [:]
    @State private var dateValues: [PersistentIdentifier: Date] = [:]
    @State private var imageDataValues: [PersistentIdentifier: Data] = [:]
    @State private var boolValues: [PersistentIdentifier: Bool] = [:]

    // MARK: - Keyboard Tracking

    @StateObject private var keyboard = KeyboardObserver()

    /// Identifies the currently active scroll anchor for programmatic scrolling.
    @State private var activeAnchor: String?

    private var isEditing: Bool { existingRecord != nil && !isRelogging }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedCategory != nil
    }

    /// Maps the RecordType to an integer index for the segmented control.
    private var recordTypeIndex: Binding<Int> {
        Binding(
            get: { recordType == .queued ? 1 : 0 },
            set: { recordType = $0 == 1 ? .queued : .logged }
        )
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

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: ImprintSpacing.space500) {
                        // ── Header ────────────────────────────────────
                        headerSection

                        // ── Tabs + Category badge ─────────────────────
                        tabsAndBadgeRow

                        // ── Form fields ───────────────────────────────
                        formFieldsSection
                    }
                    .padding(.horizontal, ImprintSpacing.space600)
                    .padding(.top, ImprintSpacing.space800)
                    .padding(.bottom, max(140, keyboard.height + 80))
                    .animation(.easeOut(duration: 0.25), value: keyboard.height)
                }
                .scrollIndicators(.hidden)
                .onChange(of: activeAnchor) { _, anchor in
                    guard let anchor else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(anchor, anchor: .center)
                        }
                    }
                }
            }

            // ── Footer ────────────────────────────────────
            footerBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(ImprintColors.neutralSubtlest.ignoresSafeArea())
        .onAppear(perform: populateInitialState)
        .presentationCornerRadius(ImprintSpacing.radius500)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space200) {
            HStack {
                Text(headerTitle)
                    .font(ImprintFonts.headingH5)
                    .foregroundStyle(ImprintColors.textBoldest)

                Spacer()

                ImprintCloseButton(action: { dismiss() })
            }

            // Divider
            Rectangle()
                .fill(ImprintColors.neutralSubtle)
                .frame(height: 1)
        }
    }

    private var headerTitle: String {
        if isEditing {
            return "Edit Entry"
        }
        return recordType == .logged ? "New Log Entry" : "New Queue Entry"
    }

    // MARK: - Tabs + Category Badge Row

    private var tabsAndBadgeRow: some View {
        HStack {
            if !isEditing {
                ImprintSegmentedControl(
                    selectedIndex: recordTypeIndex,
                    labels: ["Log", "Queue"],
                    sizing: .hug
                )
            }

            Spacer()

            if let category = selectedCategory {
                ImprintCategoryBadge(
                    categoryName: category.name,
                    categoryIcon: Group {
                        IconoirCatalog.icon(for: category.iconName)
                    },
                    recordType: recordType
                )
            }
        }
    }

    // MARK: - Form Fields

    private var formFieldsSection: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space200) {
            // Name (always first, always required)
            ImprintInput(
                label: "Name",
                text: $name,
                placeholder: "Entry name",
                onKeyboardDismiss: keyboard.height > 0 ? { dismissKeyboard() } : nil
            )
            .id("field-name")
            .simultaneousGesture(TapGesture().onEnded { activeAnchor = "field-name" })

            // Date (only for logged records)
            if recordType == .logged {
                VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
                    Text("Date")
                        .font(ImprintFonts.technical12Bold)
                        .foregroundStyle(ImprintColors.textSubtle)

                    ImprintDatePicker(selection: $finishedOn, hasSetDate: $hasSetDate)
                }
            }

            // Dynamic fields from category
            if let category = selectedCategory {
                ForEach(category.activeFieldDefinitions) { definition in
                    dynamicField(for: definition)
                        .id("field-\(definition.persistentModelID.hashValue)")
                        .simultaneousGesture(TapGesture().onEnded {
                            activeAnchor = "field-\(definition.persistentModelID.hashValue)"
                        })
                }
            }

            // Note (always last)
            ImprintTextArea(
                label: "Note",
                text: $note,
                placeholder: "Add a note...",
                onKeyboardDismiss: keyboard.height > 0 ? { dismissKeyboard() } : nil
            )
            .id("field-note")
            .simultaneousGesture(TapGesture().onEnded { activeAnchor = "field-note" })
        }
    }

    // MARK: - Dynamic Field Rendering

    @ViewBuilder
    private func dynamicField(for definition: FieldDefinition) -> some View {
        let id = definition.persistentModelID
        let dismiss: (() -> Void)? = keyboard.height > 0 ? { dismissKeyboard() } : nil

        switch definition.fieldType {
        case .shortText, .url, .country:
            ImprintInput(
                label: definition.label,
                text: textBinding(for: id),
                onKeyboardDismiss: dismiss
            )

        case .longText:
            ImprintTextArea(
                label: definition.label,
                text: textBinding(for: id),
                minHeight: 80,
                onKeyboardDismiss: dismiss
            )

        case .number, .slider:
            ImprintInput(
                label: definition.label,
                text: textBinding(for: id),
                onKeyboardDismiss: dismiss
            )

        case .checkbox:
            HStack {
                Text(definition.label)
                    .font(ImprintFonts.technical12Bold)
                    .foregroundStyle(ImprintColors.textSubtle)

                Spacer()

                ImprintToggle(isOn: boolBinding(for: id))
            }
            .padding(.vertical, ImprintSpacing.space50)

        case .date:
            VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
                Text(definition.label)
                    .font(ImprintFonts.technical12Bold)
                    .foregroundStyle(ImprintColors.textSubtle)

                ImprintDatePicker(
                    selection: dateBinding(for: id),
                    hasSetDate: .constant(dateValues[id] != nil)
                )
            }

        case .image, .attachment:
            VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
                Text(definition.label)
                    .font(ImprintFonts.technical12Bold)
                    .foregroundStyle(ImprintColors.textSubtle)

                ImageFieldView(
                    imageData: imageBinding(for: id),
                    isDark: false
                )
            }
        }
    }

    // MARK: - Footer

    private var footerBar: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [ImprintColors.neutralSubtlest.opacity(0), ImprintColors.neutralSubtlest],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)

            HStack {
                // Delete button — hidden for new entries, visible when editing
                if isEditing {
                    Button {
                        // Delete handled by parent (EntryDetailView)
                        dismiss()
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
                }

                Spacer()

                // Save button
                Button {
                    saveRecord()
                    dismiss()
                } label: {
                    Text("Save")
                        .font(ImprintFonts.technical14Medium)
                        .foregroundStyle(ImprintColors.textInverse)
                        .padding(.horizontal, ImprintSpacing.space400)
                        .frame(height: ImprintSpacing.size800)
                        .background(
                            canSave
                                ? ImprintColors.blueBold
                                : ImprintColors.blueBold.opacity(ImprintColors.stateDisabled)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.top, ImprintSpacing.space200)
            .padding(.bottom, ImprintSpacing.space700)
            .background(ImprintColors.neutralSubtlest)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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

    // MARK: - Keyboard

    private func dismissKeyboard() {
        activeAnchor = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
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
        for definition in category.activeFieldDefinitions {
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

// MARK: - Preview

#Preview {
    RecordFormView()
        .modelContainer(for: [Category.self, FieldDefinition.self, FieldValue.self, Record.self], inMemory: true)
}
