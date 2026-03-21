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
    /// One of: "text", "date", "number", "image".
    var fieldTypeRaw: String

    /// Controls field display order in forms and detail views.
    var sortOrder: Int

    /// Whether this field must be filled when creating a record.
    var isRequired: Bool

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
        get { FieldType(rawValue: fieldTypeRaw) ?? .text }
        set { fieldTypeRaw = newValue.rawValue }
    }

    // MARK: - Init

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
        self.fieldValues = []
    }
}

// MARK: - Field Type

/// The supported data types for custom fields.
nonisolated enum FieldType: String, Codable, CaseIterable, Identifiable, Sendable {
    case text
    case date
    case number
    case image

    var id: String { rawValue }

    var label: String {
        switch self {
        case .text: "Text"
        case .date: "Date"
        case .number: "Number"
        case .image: "Image"
        }
    }

    /// SF Symbol for field type selection UI.
    var iconName: String {
        switch self {
        case .text: "textformat"
        case .date: "calendar"
        case .number: "number"
        case .image: "photo"
        }
    }
}
