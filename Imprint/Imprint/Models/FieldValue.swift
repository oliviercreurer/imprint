import Foundation
import SwiftData

/// Stores the actual data for a single field on a single record.
///
/// Only one value column is populated per row, determined by the parent
/// `FieldDefinition.fieldType`. For example, a "Director" text field
/// populates `textValue`; a "Runtime" number field populates `numberValue`.
@Model
final class FieldValue {

    // MARK: - Relationships

    /// The record this value belongs to.
    var record: Record?

    /// The field definition that describes this value's schema.
    var fieldDefinition: FieldDefinition?

    // MARK: - Value Columns (one populated per row)

    /// Populated when `fieldType == .text`.
    var textValue: String?

    /// Populated when `fieldType == .number`.
    var numberValue: Double?

    /// Populated when `fieldType == .date`.
    var dateValue: Date?

    /// Populated when `fieldType == .image`.
    /// Stores a relative file path from the app's documents directory.
    /// Convention: images/<recordId>/<fieldDefinitionId>.jpg
    var imagePath: String?

    // MARK: - Init

    init(fieldDefinition: FieldDefinition) {
        self.fieldDefinition = fieldDefinition
    }

    // MARK: - Convenience

    /// Returns true if this value has meaningful content set.
    var hasValue: Bool {
        guard let fieldDefinition else { return false }
        switch fieldDefinition.fieldType {
        case .text: return textValue != nil && !textValue!.isEmpty
        case .number: return numberValue != nil
        case .date: return dateValue != nil
        case .image: return imagePath != nil && !imagePath!.isEmpty
        }
    }

    /// A display-friendly string representation of the stored value.
    var displayValue: String? {
        guard let fieldDefinition else { return nil }
        switch fieldDefinition.fieldType {
        case .text:
            return textValue
        case .number:
            guard let num = numberValue else { return nil }
            // Show integers without decimal places
            return num.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(num))
                : String(num)
        case .date:
            guard let date = dateValue else { return nil }
            return date.formatted(date: .abbreviated, time: .omitted)
        case .image:
            return imagePath != nil ? "[Image]" : nil
        }
    }
}
