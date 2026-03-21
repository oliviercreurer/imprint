import Foundation
import SwiftData

/// Seeds the database with default category templates on first launch.
///
/// When no categories exist, creates Film, TV, Book, and Music categories
/// with sensible default field definitions. Users can modify, extend, or
/// delete these — they're starting points, not permanent fixtures.
enum CategorySeeder {

    /// Creates default categories if none exist in the given context.
    /// Call this once during app launch after the model container is ready.
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        // Check if categories already exist
        let descriptor = FetchDescriptor<Category>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // Seed defaults
        let templates = Self.defaultTemplates()
        for (category, fields) in templates {
            context.insert(category)
            for field in fields {
                field.category = category
                context.insert(field)
            }
        }

        try? context.save()
    }

    /// Defines the default category templates with their field definitions.
    private static func defaultTemplates() -> [(Category, [FieldDefinition])] {
        [
            // Film
            (
                Category(
                    name: "Film",
                    iconName: "film",
                    colorHex: "#E45E5C",
                    sortOrder: 0
                ),
                [
                    FieldDefinition(label: "Director", fieldType: .text, sortOrder: 0),
                    FieldDefinition(label: "Release Year", fieldType: .number, sortOrder: 1),
                    FieldDefinition(label: "Runtime", fieldType: .number, sortOrder: 2),
                ]
            ),
            // TV
            (
                Category(
                    name: "TV",
                    iconName: "tv",
                    colorHex: "#5BA7E4",
                    sortOrder: 1
                ),
                [
                    FieldDefinition(label: "Creator", fieldType: .text, sortOrder: 0),
                    FieldDefinition(label: "Season", fieldType: .number, sortOrder: 1),
                    FieldDefinition(label: "Episode", fieldType: .number, sortOrder: 2),
                ]
            ),
            // Book
            (
                Category(
                    name: "Book",
                    iconName: "book",
                    colorHex: "#6BBD6E",
                    sortOrder: 2
                ),
                [
                    FieldDefinition(label: "Author", fieldType: .text, sortOrder: 0),
                    FieldDefinition(label: "Publication Year", fieldType: .number, sortOrder: 1),
                    FieldDefinition(label: "Page Count", fieldType: .number, sortOrder: 2),
                ]
            ),
            // Music
            (
                Category(
                    name: "Music",
                    iconName: "music.note",
                    colorHex: "#C78CDB",
                    sortOrder: 3
                ),
                [
                    FieldDefinition(label: "Artist", fieldType: .text, sortOrder: 0),
                    FieldDefinition(label: "Release Year", fieldType: .number, sortOrder: 1),
                ]
            ),
        ]
    }
}
