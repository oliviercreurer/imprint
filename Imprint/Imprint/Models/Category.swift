import Foundation
import SwiftData

/// A user-defined category (e.g. "Film", "Restaurant", "Hike").
///
/// Categories replace the old hardcoded `MediaType` enum. Each category
/// owns a set of `FieldDefinition`s that describe the custom fields
/// available for records in that category.
@Model
final class Category {

    // MARK: - Fields

    /// Display name (e.g. "Film", "Restaurant").
    var name: String

    /// SF Symbol name for the category icon.
    var iconName: String

    /// User-chosen accent color, stored as a hex string (e.g. "#3B82F6").
    var colorHex: String

    /// Controls display order in the filter bar, menus, and settings.
    var sortOrder: Int

    /// Whether this category appears in the filter bar and add menu.
    /// Replaces the old `disabledMediaTypes` AppStorage mechanism.
    var isEnabled: Bool

    /// When this category was created.
    var createdAt: Date

    // MARK: - Relationships

    /// The custom field schemas defined for this category.
    @Relationship(deleteRule: .cascade, inverse: \FieldDefinition.category)
    var fieldDefinitions: [FieldDefinition]

    /// All records that belong to this category.
    /// Deletion is denied (handled in UI) — users must remove records first.
    @Relationship(deleteRule: .deny, inverse: \Record.category)
    var records: [Record]

    // MARK: - Init

    init(
        name: String,
        iconName: String,
        colorHex: String,
        sortOrder: Int,
        isEnabled: Bool = true
    ) {
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isEnabled = isEnabled
        self.createdAt = Date()
        self.fieldDefinitions = []
        self.records = []
    }
}

// MARK: - Convenience

extension Category {

    /// Field definitions sorted by their display order.
    var sortedFieldDefinitions: [FieldDefinition] {
        fieldDefinitions.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Whether this category can be deleted.
    /// Deletion is blocked while the category still has records.
    var canDelete: Bool {
        records.isEmpty
    }
}
