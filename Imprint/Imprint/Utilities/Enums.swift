import Foundation

// MARK: - Record Type

/// Whether a record has been consumed (logged) or saved for later (queued).
///
/// Marked `nonisolated` so it can be used freely across isolation boundaries
/// (e.g. inside SwiftData predicates and background contexts).
nonisolated enum RecordType: String, Codable, CaseIterable, Identifiable, Sendable {
    case logged
    case queued

    var id: String { rawValue }

    var label: String {
        switch self {
        case .logged: "Log"
        case .queued: "Queue"
        }
    }
}

// MARK: - Media Type

/// The four supported media categories.
nonisolated enum MediaType: String, Codable, CaseIterable, Identifiable, Sendable {
    case film
    case tv
    case book
    case music

    var id: String { rawValue }

    var label: String {
        switch self {
        case .film: "Film"
        case .tv: "TV"
        case .book: "Book"
        case .music: "Music"
        }
    }

    /// SF Symbol name for each media type.
    var iconName: String {
        switch self {
        case .film: "film"
        case .tv: "tv"
        case .book: "book"
        case .music: "music.note"
        }
    }
}
