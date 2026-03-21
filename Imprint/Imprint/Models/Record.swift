import Foundation
import SwiftData

/// A single record — either logged (consumed/done) or queued (saved for later).
///
/// Each record belongs to a user-defined `Category` and stores its custom
/// field data via `FieldValue` entities linked to the category's `FieldDefinition`s.
@Model
final class Record {

    // MARK: - Core Fields

    /// Whether this record is logged or queued.
    /// Stored as raw string value for SwiftData predicate compatibility.
    var recordTypeRaw: String

    /// The title or name of the entry.
    var name: String

    /// An optional freeform note.
    var note: String?

    // MARK: - Date Fields

    /// The date consumption started (optional).
    var startedOn: Date?

    /// The date consumption finished. Required for logged records.
    var finishedOn: Date?

    /// When this record was created in Imprint.
    var createdAt: Date

    // MARK: - Relationships

    /// The user-defined category this record belongs to.
    var category: Category?

    /// Custom field values for this record.
    @Relationship(deleteRule: .cascade, inverse: \FieldValue.record)
    var fieldValues: [FieldValue]

    // MARK: - Computed Accessors

    /// Typed accessor for the record type.
    @Transient
    var recordType: RecordType {
        get { RecordType(rawValue: recordTypeRaw) ?? .logged }
        set { recordTypeRaw = newValue.rawValue }
    }

    // MARK: - Init

    init(
        recordType: RecordType,
        category: Category,
        name: String
    ) {
        self.recordTypeRaw = recordType.rawValue
        self.category = category
        self.name = name
        self.createdAt = Date()
        self.fieldValues = []
    }
}

// MARK: - Field Value Access

extension Record {

    /// Returns field values sorted by their definition's display order.
    var sortedFieldValues: [FieldValue] {
        fieldValues.sorted { lhs, rhs in
            (lhs.fieldDefinition?.sortOrder ?? 0) < (rhs.fieldDefinition?.sortOrder ?? 0)
        }
    }

    /// Finds the field value for a given field definition.
    func fieldValue(for definition: FieldDefinition) -> FieldValue? {
        fieldValues.first { $0.fieldDefinition?.persistentModelID == definition.persistentModelID }
    }

    /// Returns the display value of the first text field (useful for subtitles).
    var firstTextFieldValue: String? {
        sortedFieldValues.first { $0.fieldDefinition?.fieldType == .text }?.textValue
    }

    /// Returns the image path of the first image field (useful for covers).
    var firstImageFieldPath: String? {
        sortedFieldValues.first { $0.fieldDefinition?.fieldType == .image }?.imagePath
    }
}
