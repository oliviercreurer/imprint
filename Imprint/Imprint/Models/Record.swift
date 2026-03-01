import Foundation
import SwiftData

/// A single media record — either logged (consumed) or queued (saved for later).
///
/// All media types share a common set of fields. Type-specific fields
/// (e.g. `director` for films, `author` for books) are optional and only
/// relevant when the record's `mediaType` matches.
@Model
final class Record {

    // MARK: - Shared Fields

    /// Whether this record is logged or queued.
    /// Stored as raw string value for SwiftData predicate compatibility.
    var recordTypeRaw: String

    /// The media category (film, tv, book, music).
    /// Stored as raw string value for SwiftData predicate compatibility.
    var mediaTypeRaw: String

    /// The title or name of the media item.
    var name: String

    /// An optional freeform note.
    var note: String?

    /// Country of origin.
    var country: String?

    // MARK: - Logged-Specific Fields

    /// The date consumption started (optional, useful for books etc.).
    var startedOn: Date?

    /// The date consumption finished. Required for logged records.
    var finishedOn: Date?

    // MARK: - Film Fields

    var director: String?
    var filmReleaseDate: Int?

    // MARK: - TMDB Fields

    /// The TMDB movie ID, if this film was linked via search.
    var tmdbId: Int?

    /// The TMDB poster file path (e.g. "/abc123.jpg") chosen by the user.
    var posterPath: String?

    // MARK: - TV Fields

    var creator: String?
    var season: Int?
    var episode: Int?

    // MARK: - Book Fields

    var author: String?
    var publicationDate: Int?
    var translator: String?

    // MARK: - Music Fields

    var artist: String?
    var musicReleaseDate: Int?

    // MARK: - Metadata

    /// When this record was created in Imprint.
    var createdAt: Date

    // MARK: - Computed Accessors

    /// Typed accessor for the record type.
    @Transient
    var recordType: RecordType {
        get { RecordType(rawValue: recordTypeRaw) ?? .logged }
        set { recordTypeRaw = newValue.rawValue }
    }

    /// Typed accessor for the media type.
    @Transient
    var mediaType: MediaType {
        get { MediaType(rawValue: mediaTypeRaw) ?? .film }
        set { mediaTypeRaw = newValue.rawValue }
    }

    // MARK: - Init

    init(
        recordType: RecordType,
        mediaType: MediaType,
        name: String
    ) {
        self.recordTypeRaw = recordType.rawValue
        self.mediaTypeRaw = mediaType.rawValue
        self.name = name
        self.createdAt = Date()
    }
}

// MARK: - Convenience

extension Record {

    /// Returns the primary "creator" label for display purposes,
    /// based on media type (director, creator, author, or artist).
    var creatorLabel: String? {
        switch mediaType {
        case .film: director
        case .tv: creator
        case .book: author
        case .music: artist
        }
    }

    /// Returns the release/publication year if set.
    var releaseYear: Int? {
        switch mediaType {
        case .film: filmReleaseDate
        case .tv: nil
        case .book: publicationDate
        case .music: musicReleaseDate
        }
    }
}
