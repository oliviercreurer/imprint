import Foundation

// MARK: - GraphQL Response Wrappers

/// Generic wrapper for Hardcover GraphQL responses: `{ "data": T }`.
struct HCGraphQLResponse<T: Decodable>: Decodable {
    let data: T
}

// MARK: - Search Response

/// Wraps the search query result: `{ "search": { "results": <JSON blob> } }`.
///
/// The `results` field is a raw Typesense JSON blob, not a typed GraphQL object.
/// It contains `{ "hits": [ { "document": { ... } } ] }`.
struct HCSearchData: Decodable {
    let search: HCSearchRaw
}

struct HCSearchRaw: Decodable {
    let results: HCTypesenseResults

    /// Custom decoder to handle `results` arriving as either a nested JSON
    /// object (Hasura jsonb) or a raw JSON string that needs re-parsing.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try decoding as a nested object first (most common with Hasura jsonb)
        if let direct = try? container.decode(HCTypesenseResults.self, forKey: .results) {
            results = direct
        } else {
            // Fall back to decoding as a JSON string, then re-parsing
            let jsonString = try container.decode(String.self, forKey: .results)
            guard let data = jsonString.data(using: .utf8) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .results, in: container,
                    debugDescription: "results string is not valid UTF-8"
                )
            }
            results = try JSONDecoder().decode(HCTypesenseResults.self, from: data)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case results
    }
}

/// Typesense search response: `{ "found": N, "hits": [...] }`.
struct HCTypesenseResults: Decodable {
    let found: Int?
    let hits: [HCTypesenseHit]?
}

/// A single Typesense hit: `{ "document": { ... } }`.
struct HCTypesenseHit: Decodable {
    let document: HCSearchDocument
}

/// A book document from the Typesense search index.
///
/// The Typesense document shape differs significantly from the GraphQL shape:
///   - `image` is an object with `{url, color, height, width, id}`
///   - `contributions` is `[{author: {id, name, slug, image}, contribution}]`
///   - `genres` is `[String]`
///   - `id` is a String
///   - `release_year` is an Int
///
/// Uses a lenient custom decoder so unknown/extra fields don't break parsing.
struct HCSearchDocument: Codable, Identifiable, Sendable {
    let id: Int
    let title: String
    let slug: String?
    let description: String?
    let pages: Int?
    let releaseYear: Int?
    let releaseDate: String?
    let imageURL: String?          // extracted from image.url
    let genres: [String]?
    let contributions: [HCSearchContribution]?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, description, pages, image, genres, contributions
        case releaseYear = "release_year"
        case releaseDate = "release_date"
    }

    /// Memberwise init for building synthetic documents (e.g. from a Record).
    init(
        id: Int, title: String, slug: String?, description: String?,
        pages: Int?, releaseYear: Int?, releaseDate: String?,
        imageURL: String?, genres: [String]?,
        contributions: [HCSearchContribution]?
    ) {
        self.id = id; self.title = title; self.slug = slug
        self.description = description; self.pages = pages
        self.releaseYear = releaseYear; self.releaseDate = releaseDate
        self.imageURL = imageURL; self.genres = genres
        self.contributions = contributions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // id — Typesense returns a string like "858567"
        if let intId = try? c.decode(Int.self, forKey: .id) {
            id = intId
        } else if let strId = try? c.decode(String.self, forKey: .id),
                  let parsed = Int(strId) {
            id = parsed
        } else {
            id = 0
        }

        title = (try? c.decode(String.self, forKey: .title)) ?? "Unknown"
        slug = try? c.decode(String.self, forKey: .slug)
        description = try? c.decode(String.self, forKey: .description)
        pages = try? c.decode(Int.self, forKey: .pages)
        releaseYear = try? c.decode(Int.self, forKey: .releaseYear)
        releaseDate = try? c.decode(String.self, forKey: .releaseDate)
        genres = try? c.decode([String].self, forKey: .genres)
        contributions = try? c.decode([HCSearchContribution].self, forKey: .contributions)

        // image is an object like {"url":"...", "color":"...", "height":500, ...}
        if let imgObj = try? c.decode(HCSearchImage.self, forKey: .image) {
            imageURL = imgObj.url
        } else {
            imageURL = nil
        }
    }

    // MARK: - Encoding (for Codable conformance)

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(String(id), forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(slug, forKey: .slug)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(pages, forKey: .pages)
        try c.encodeIfPresent(releaseYear, forKey: .releaseYear)
        try c.encodeIfPresent(releaseDate, forKey: .releaseDate)
        try c.encodeIfPresent(genres, forKey: .genres)
        try c.encodeIfPresent(contributions, forKey: .contributions)
        if let url = imageURL {
            try c.encode(HCSearchImage(url: url), forKey: .image)
        }
    }

    // MARK: - Convenience

    /// The primary author name from contributions, preferring entries with
    /// a nil or "Author" role over translators, editors, etc.
    var primaryAuthor: String? {
        guard let contribs = contributions, !contribs.isEmpty else { return nil }
        // Prefer contribution == nil (default for author in Typesense) or "Author"
        let author = contribs.first(where: {
            $0.contribution == nil || $0.contribution?.lowercased() == "author"
        })
        return (author ?? contribs.first)?.author?.name
    }

    /// Cover image URL.
    var coverImageURL: URL? {
        guard let urlStr = imageURL, let url = URL(string: urlStr) else { return nil }
        return url
    }

    /// Stores the cover URL in the format used by Record.posterPath.
    var cachedImage: String? { imageURL }

    /// Comma-separated genre list (capped at 5).
    var tagList: String? {
        guard let g = genres, !g.isEmpty else { return nil }
        return g.prefix(5).joined(separator: ", ")
    }
}

/// A contribution entry from the Typesense search document.
/// Shape: `{"author": {"id": 240314, "name": "...", "slug": "...", "image": {}}, "contribution": null}`
struct HCSearchContribution: Codable, Sendable {
    let author: HCSearchAuthor?
    let contribution: String?
}

/// An author nested inside a Typesense contribution.
struct HCSearchAuthor: Codable, Sendable {
    let id: Int?
    let name: String?
    let slug: String?
}

/// The image object in a Typesense search document.
/// Shape: `{"color":"#412003","color_name":"Black","height":500,"id":5160419,"url":"https://...","width":330}`
struct HCSearchImage: Codable, Sendable {
    let url: String?
}

// MARK: - Book Detail Response

/// Wraps the book detail query: `{ "books_by_pk": { ... } }`.
struct HCBookDetailData: Decodable {
    let booksByPk: HCBook?

    enum CodingKeys: String, CodingKey {
        case booksByPk = "books_by_pk"
    }
}

/// Full book detail from the `books_by_pk` GraphQL query.
///
/// This is the rich, nested shape — includes editions, image, etc.
struct HCBook: Codable, Identifiable, Sendable {
    let id: Int
    let title: String
    let slug: String?
    let description: String?
    let pages: Int?
    let releaseDate: String?
    let cachedImage: String?
    let cachedContributors: [HCContributor]?
    let cachedTags: [HCTag]?
    let image: HCImage?
    let editions: [HCEdition]?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, description, pages, image, editions
        case releaseDate = "release_date"
        case cachedImage = "cached_image"
        case cachedContributors = "cached_contributors"
        case cachedTags = "cached_tags"
    }

    init(
        id: Int, title: String, slug: String?, description: String?,
        pages: Int?, releaseDate: String?, cachedImage: String?,
        cachedContributors: [HCContributor]?, cachedTags: [HCTag]?,
        image: HCImage?, editions: [HCEdition]?
    ) {
        self.id = id; self.title = title; self.slug = slug
        self.description = description; self.pages = pages
        self.releaseDate = releaseDate; self.cachedImage = cachedImage
        self.cachedContributors = cachedContributors
        self.cachedTags = cachedTags; self.image = image
        self.editions = editions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(Int.self, forKey: .id)) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Unknown"
        slug = try? c.decode(String.self, forKey: .slug)
        description = try? c.decode(String.self, forKey: .description)
        pages = try? c.decode(Int.self, forKey: .pages)
        releaseDate = try? c.decode(String.self, forKey: .releaseDate)
        image = try? c.decode(HCImage.self, forKey: .image)
        editions = try? c.decode([HCEdition].self, forKey: .editions)
        cachedContributors = try? c.decode([HCContributor].self, forKey: .cachedContributors)
        cachedTags = try? c.decode([HCTag].self, forKey: .cachedTags)

        // cached_image — may be a plain URL string OR {"url": "..."}
        if let str = try? c.decode(String.self, forKey: .cachedImage), !str.isEmpty {
            cachedImage = str
        } else if let obj = try? c.decode(HCImage.self, forKey: .cachedImage), let url = obj.url {
            cachedImage = url
        } else {
            cachedImage = nil
        }
    }

    /// The primary author, preferring entries with a nil or "Author" role
    /// over translators, editors, etc.
    var primaryAuthor: String? {
        guard let contribs = cachedContributors, !contribs.isEmpty else { return nil }
        let author = contribs.first(where: {
            $0.contribution == nil || $0.contribution?.lowercased() == "author"
        })
        return (author ?? contribs.first)?.name
    }

    /// Extracts a four-digit year from `release_date`.
    var releaseYear: Int? {
        guard let dateStr = releaseDate, dateStr.count >= 4 else { return nil }
        return Int(dateStr.prefix(4))
    }

    /// Best available cover image URL — prefers `image.url`, falls back to `cached_image`.
    var coverImageURL: URL? {
        if let urlStr = image?.url, let url = URL(string: urlStr) {
            return url
        }
        if let urlStr = cachedImage, let url = URL(string: urlStr) {
            return url
        }
        return nil
    }

    /// Comma-separated tag list (capped at 5).
    var tagList: String? {
        guard let tags = cachedTags, !tags.isEmpty else { return nil }
        return tags.prefix(5).map(\.tag).joined(separator: ", ")
    }
}

// MARK: - Supporting Types

/// A contributor (author, translator, etc.) from `cached_contributors`.
struct HCContributor: Codable, Sendable {
    let id: Int?
    let name: String
    let image: String?
    let contribution: String?
}

/// A tag from `cached_tags`.
struct HCTag: Codable, Sendable {
    let tag: String
}

/// The `image { url }` field on a book.
struct HCImage: Codable, Sendable {
    let url: String?
}

/// An edition of a book, each potentially with its own cover.
struct HCEdition: Codable, Identifiable, Sendable {
    let id: Int
    let cachedImage: String?
    let image: HCImage?
    let title: String?

    enum CodingKeys: String, CodingKey {
        case id, title, image
        case cachedImage = "cached_image"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(Int.self, forKey: .id)) ?? 0
        title = try? c.decode(String.self, forKey: .title)
        image = try? c.decode(HCImage.self, forKey: .image)

        // cached_image — may be a plain URL string OR {"url": "..."}
        if let str = try? c.decode(String.self, forKey: .cachedImage), !str.isEmpty {
            cachedImage = str
        } else if let obj = try? c.decode(HCImage.self, forKey: .cachedImage), let url = obj.url {
            cachedImage = url
        } else {
            cachedImage = nil
        }
    }

    /// Best available cover URL — prefers `image.url` over `cached_image`.
    var bestImageURL: String? {
        image?.url ?? cachedImage
    }

    /// The cover image URL for this edition.
    var coverImageURL: URL? {
        guard let urlStr = bestImageURL else { return nil }
        return URL(string: urlStr)
    }
}
