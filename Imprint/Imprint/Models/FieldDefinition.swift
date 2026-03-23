import Foundation
import SwiftData

/// Defines a custom field within a category (e.g. "Director" text field on "Film").
///
/// Each `FieldDefinition` describes the schema for one field. The actual data
/// for each record lives in `FieldValue`, linked to both the record and
/// this definition.
@Model
final class FieldDefinition {

    // MARK: - Fields

    /// Display label shown in forms and detail views (e.g. "Director", "Cuisine").
    var label: String

    /// The data type of this field. Stored as a raw string for SwiftData compatibility.
    /// One of the FieldType raw values (e.g. "shortText", "longText", "image", etc.).
    var fieldTypeRaw: String

    /// Controls field display order in forms and detail views.
    var sortOrder: Int

    /// Whether this field must be filled when creating a record.
    var isRequired: Bool

    /// Soft-deleted fields are hidden from new record forms but their
    /// historical `FieldValue`s are preserved and still displayed on
    /// existing records.
    var isArchived: Bool = false

    // MARK: - Slider Configuration

    /// Minimum value for slider fields. Defaults to 1.
    var sliderMin: Double?

    /// Maximum value for slider fields. Defaults to 5.
    var sliderMax: Double?

    /// Step increment for slider fields. Defaults to 1.
    var sliderStep: Double?

    // MARK: - Relationships

    /// The category this field belongs to.
    var category: Category?

    /// All values stored for this field across records.
    @Relationship(deleteRule: .cascade, inverse: \FieldValue.fieldDefinition)
    var fieldValues: [FieldValue]

    // MARK: - Computed Accessors

    /// Typed accessor for the field type.
    @Transient
    var fieldType: FieldType {
        get { FieldType(rawValue: fieldTypeRaw) ?? .shortText }
        set { fieldTypeRaw = newValue.rawValue }
    }

    // MARK: - Init

    /// Whether any records have stored a value for this field.
    @Transient
    var hasData: Bool {
        fieldValues.contains { $0.hasValue }
    }

    init(
        label: String,
        fieldType: FieldType,
        sortOrder: Int,
        isRequired: Bool = false
    ) {
        self.label = label
        self.fieldTypeRaw = fieldType.rawValue
        self.sortOrder = sortOrder
        self.isRequired = isRequired
        self.isArchived = false
        self.fieldValues = []
    }
}

// MARK: - Field Type

/// The supported data types for custom fields.
nonisolated enum FieldType: String, Codable, CaseIterable, Identifiable, Sendable {
    case shortText
    case longText
    case image
    case checkbox
    case number
    case slider
    case date
    case url
    case country
    case attachment

    var id: String { rawValue }

    var label: String {
        switch self {
        case .shortText:  "Short text"
        case .longText:   "Long text"
        case .image:      "Image"
        case .checkbox:   "Checkbox"
        case .number:     "Number"
        case .slider:     "Slider"
        case .date:       "Date"
        case .url:        "URL"
        case .country:    "Country"
        case .attachment: "Attachment"
        }
    }

    /// Iconoir icon name (kebab-case) for this field type.
    var iconoirName: String {
        switch self {
        case .shortText:  "text-square"
        case .longText:   "align-left"
        case .image:      "media-image"
        case .checkbox:   "check-circle"
        case .number:     "number-0-square"
        case .slider:     "git-commit"
        case .date:       "calendar"
        case .url:        "link"
        case .country:    "white-flag"
        case .attachment: "attachment"
        }
    }
}
