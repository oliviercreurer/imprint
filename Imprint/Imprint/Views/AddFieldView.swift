import SwiftUI

// MARK: - Add Field View
// Figma: add-field (node 115:8104)
// A sheet for configuring a new field to add to a category form.
//
// Layout (top → bottom):
//   1. Header: "Add Field" (Heading/H5, 18pt) + close X (20pt circle)
//   2. Description: Body/16/Regular, text/subtle — interpolates category name
//   3. Field label input: Technical/12pt/Bold label + input (size/800 height)
//   4. Field type grid: Technical/12pt/Bold label + 2-column grid of ImprintFieldTypeSelector
//   5. Additional Options (conditional, slider only):
//      - Heading: Body/16/SemiBold
//      - Three equal-width inputs: Min, Max, Step
//      - Slider preview with tick marks
//   6. Footer: Required toggle (left) + Save button (right)

struct AddFieldView: View {

    /// The name of the category being configured, for the description text.
    let categoryName: String

    /// If set, we're editing an existing field — pre-populates the form.
    var existingField: CategoryEditorView.EditableField?

    /// Called when the user saves a field configuration (new or edited).
    var onSave: (CategoryEditorView.EditableField) -> Void

    private var isEditing: Bool { existingField != nil }

    /// When true, the field type cannot be changed because records already
    /// have stored values for this field.
    private var isTypeLocked: Bool { existingField?.hasExistingData ?? false }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var keyboard = KeyboardObserver()

    // MARK: - Form State

    @State private var fieldLabel: String = ""
    @State private var selectedType: FieldType = .shortText
    @State private var isRequired: Bool = false

    // Slider configuration
    @State private var sliderMin: String = "1"
    @State private var sliderMax: String = "5"
    @State private var sliderStep: String = "1"

    // Focus tracking
    @FocusState private var focusedField: FocusableField?

    private enum FocusableField: Hashable {
        case label, sliderMin, sliderMax, sliderStep
    }

    private enum ScrollAnchor: Hashable {
        case label, sliderInputs
    }

    // MARK: - Computed

    private var canSave: Bool {
        !fieldLabel.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var parsedSliderMin: Double { Double(sliderMin) ?? 1 }
    private var parsedSliderMax: Double { Double(sliderMax) ?? 5 }
    private var parsedSliderStep: Double { Double(sliderStep) ?? 1 }

    /// Generate tick labels for the slider preview.
    private var sliderTicks: [Int] {
        let mn = parsedSliderMin
        let mx = parsedSliderMax
        let step = max(parsedSliderStep, 0.01)
        guard mx > mn else { return [] }
        var ticks: [Int] = []
        var val = mn
        while val <= mx + 0.001 {
            ticks.append(Int(val))
            val += step
        }
        // Cap at reasonable count for display
        if ticks.count > 20 { return Array(ticks.prefix(20)) }
        return ticks
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: ImprintSpacing.space400) {
                        // ── 1. Header ──────────────────────────────
                        headerSection

                        // ── 2. Field label input ──────────────────
                        fieldLabelInput
                            .id(ScrollAnchor.label)

                        // ── 3. Field type grid ────────────────────
                        fieldTypeGrid

                        // ── 4. Additional options (slider) ────────
                        if selectedType == .slider {
                            additionalOptionsSection
                        }
                    }
                    .padding(.horizontal, ImprintSpacing.space600)
                    .padding(.top, ImprintSpacing.space800)
                    .padding(.bottom, max(140, keyboard.height + 80))
                    .animation(.easeOut(duration: 0.25), value: keyboard.height)
                }
                .scrollIndicators(.hidden)
                .onChange(of: focusedField) { _, newField in
                    guard let newField else { return }
                    let anchor: ScrollAnchor = switch newField {
                    case .label: .label
                    case .sliderMin, .sliderMax, .sliderStep: .sliderInputs
                    }
                    // Small delay to let the keyboard height settle
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
        .presentationCornerRadius(ImprintSpacing.radius500)
        .onAppear(perform: populateFromExisting)
    }

    // MARK: - Populate from Existing

    private func populateFromExisting() {
        guard let existing = existingField else { return }
        fieldLabel = existing.label
        selectedType = existing.fieldType
        isRequired = existing.isRequired
        sliderMin = String(Int(existing.sliderMin))
        sliderMax = String(Int(existing.sliderMax))
        sliderStep = String(Int(existing.sliderStep))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space300) {
            // Title + close
            HStack {
                Text(isEditing ? "Edit Field" : "Add Field")
                    .font(ImprintFonts.headingH5)
                    .foregroundStyle(ImprintColors.textBoldest)

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
            Text("Create a field to add to your \(categoryName.isEmpty ? "category" : categoryName) category. Some field types have additional options to customize.")
                .font(ImprintFonts.body16Regular)
                .lineSpacing(ImprintFonts.body16LineSpacing)
                .foregroundStyle(ImprintColors.textSubtle)
        }
    }

    // MARK: - Field Label Input

    private var fieldLabelInput: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
            Text("Field label")
                .font(ImprintFonts.technical12Bold)
                .foregroundStyle(ImprintColors.textBold)

            HStack(spacing: ImprintSpacing.space100) {
                TextField("e.g. Director", text: $fieldLabel)
                    .font(ImprintFonts.technical14Medium)
                    .foregroundStyle(ImprintColors.textBoldest)
                    .focused($focusedField, equals: .label)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }

                if focusedField == .label {
                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ImprintColors.iconSubtle)
                    }
                }
            }
            .padding(.horizontal, ImprintSpacing.space300)
            .frame(height: ImprintSpacing.size800)
            .background(ImprintColors.inputSubtlest)
            .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    // MARK: - Field Type Grid

    private var fieldTypeGrid: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space200) {
            HStack(spacing: ImprintSpacing.space75) {
                Text("Field type")
                    .font(ImprintFonts.technical12Bold)
                    .foregroundStyle(ImprintColors.textBold)

                if isTypeLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ImprintColors.textSubtler)
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: ImprintSpacing.space100),
                    GridItem(.flexible(), spacing: ImprintSpacing.space100)
                ],
                spacing: ImprintSpacing.space100
            ) {
                ForEach(FieldType.allCases) { type in
                    ImprintFieldTypeSelector(
                        fieldType: type.label,
                        isSelected: selectedType == type,
                        icon: IconoirCatalog.icon(for: type.iconoirName),
                        action: {
                            guard !isTypeLocked else { return }
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedType = type
                            }
                        }
                    )
                }
            }
            .opacity(isTypeLocked ? 0.5 : 1.0)
        }
    }

    // MARK: - Additional Options (Slider)

    private var additionalOptionsSection: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space300) {
            // Section heading
            Text("Additional Options")
                .font(ImprintFonts.body16SemiBold)
                .foregroundStyle(ImprintColors.textBoldest)

            // Min / Max / Step inputs
            HStack(spacing: ImprintSpacing.space200) {
                sliderConfigInput(label: "Min", text: $sliderMin, field: .sliderMin)
                sliderConfigInput(label: "Max", text: $sliderMax, field: .sliderMax)
                sliderConfigInput(label: "Step", text: $sliderStep, field: .sliderStep)
            }
            .id(ScrollAnchor.sliderInputs)

            // Slider preview
            sliderPreview
        }
    }

    private func sliderConfigInput(label: String, text: Binding<String>, field: FocusableField) -> some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space50) {
            Text(label)
                .font(ImprintFonts.technical12Bold)
                .foregroundStyle(ImprintColors.textBold)

            HStack(spacing: 4) {
                TextField("0", text: text)
                    .font(ImprintFonts.technical14Medium)
                    .foregroundStyle(ImprintColors.textBoldest)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .focused($focusedField, equals: field)

                if focusedField == field {
                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ImprintColors.iconSubtle)
                    }
                }
            }
            .padding(.horizontal, ImprintSpacing.space200)
            .frame(height: ImprintSpacing.size800)
            .background(ImprintColors.inputSubtlest)
            .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    // MARK: - Slider Preview

    private var sliderPreview: some View {
        let ticks = sliderTicks
        let tickDotSize: CGFloat = 8
        let labelHeight: CGFloat = 16
        let gap: CGFloat = ImprintSpacing.space100

        return GeometryReader { geo in
            let count = ticks.count
            let inset: CGFloat = tickDotSize / 2
            let trackWidth = geo.size.width - tickDotSize

            // Track line
            RoundedRectangle(cornerRadius: 2)
                .fill(ImprintColors.neutralSubtle)
                .frame(height: 4)
                .position(x: geo.size.width / 2, y: tickDotSize / 2)

            if count > 1 {
                ForEach(0..<count, id: \.self) { i in
                    let fraction = CGFloat(i) / CGFloat(count - 1)
                    let x = inset + fraction * trackWidth

                    // Tick dot
                    Circle()
                        .fill(ImprintColors.neutralBold)
                        .frame(width: tickDotSize, height: tickDotSize)
                        .position(x: x, y: tickDotSize / 2)

                    // Number label directly below
                    Text("\(ticks[i])")
                        .font(ImprintFonts.technical12Medium)
                        .foregroundStyle(ImprintColors.textSubtle)
                        .fixedSize()
                        .position(x: x, y: tickDotSize + gap + labelHeight / 2)
                }
            }
        }
        .frame(height: tickDotSize + gap + labelHeight)
        .padding(.vertical, ImprintSpacing.space100)
    }

    // MARK: - Footer Bar

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
                // Required toggle
                HStack(spacing: ImprintSpacing.space100) {
                    ImprintToggle(isOn: $isRequired)

                    Text("Required")
                        .font(ImprintFonts.technical12Bold)
                        .foregroundStyle(ImprintColors.textBold)
                }

                Spacer()

                // Save button
                Button {
                    saveField()
                } label: {
                    Text("Save")
                        .font(ImprintFonts.technical14Medium)
                        .foregroundStyle(ImprintColors.textInverse)
                        .padding(.horizontal, ImprintSpacing.space500)
                        .frame(height: ImprintSpacing.size800)
                        .background(
                            canSave
                                ? ImprintColors.blueBold
                                : ImprintColors.blueBold.opacity(0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
                }
                .disabled(!canSave)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.bottom, ImprintSpacing.space700)
            .padding(.top, ImprintSpacing.space200)
            .background(ImprintColors.neutralSubtlest)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Save

    private func saveField() {
        let field = CategoryEditorView.EditableField(
            label: fieldLabel.trimmingCharacters(in: .whitespaces),
            fieldType: selectedType,
            isRequired: isRequired,
            sliderMin: parsedSliderMin,
            sliderMax: parsedSliderMax,
            sliderStep: parsedSliderStep
        )
        onSave(field)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Add Field") {
    AddFieldView(categoryName: "Film") { field in
        print("Saved: \(field.label) (\(field.fieldType.label))")
    }
}

#Preview("Edit Field") {
    AddFieldView(
        categoryName: "Film",
        existingField: .init(label: "Director", fieldType: .shortText, isRequired: true)
    ) { field in
        print("Updated: \(field.label) (\(field.fieldType.label))")
    }
}
