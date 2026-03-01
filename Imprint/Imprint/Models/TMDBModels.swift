import Foundation

// MARK: - Search

/// Response wrapper for TMDB `/search/movie` endpoint.
struct TMDBSearchResponse: Codable {
    let results: [TMDBMovie]
    let totalResults: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case results
        case totalResults = "total_results"
        case totalPages = "total_pages"
    }
}

/// A movie result from TMDB search.
struct TMDBMovie: Codable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String?
    let overview: String?
    let posterPath: String?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case releaseDate = "release_date"
    }

    /// Extracts the year from the release date string (e.g. "2024-03-15" → 2024).
    var releaseYear: Int? {
        guard let dateStr = releaseDate, dateStr.count >= 4 else { return nil }
        return Int(dateStr.prefix(4))
    }
}

// MARK: - Movie Details

/// Full movie detail from TMDB `/movie/{id}` endpoint with credits appended.
struct TMDBMovieDetail: Codable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let releaseDate: String?
    let credits: TMDBCredits?
    let productionCountries: [TMDBCountry]?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, credits
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case productionCountries = "production_countries"
    }

    /// The first director found in the crew list.
    var director: String? {
        credits?.crew.first(where: { $0.job == "Director" })?.name
    }

    /// Primary production country name.
    var country: String? {
        productionCountries?.first?.name
    }

    var releaseYear: Int? {
        guard let dateStr = releaseDate, dateStr.count >= 4 else { return nil }
        return Int(dateStr.prefix(4))
    }
}

struct TMDBCredits: Codable {
    let crew: [TMDBCrewMember]
}

struct TMDBCrewMember: Codable {
    let name: String
    let job: String
}

struct TMDBCountry: Codable {
    let name: String

    enum CodingKeys: String, CodingKey {
        case name
    }
}

// MARK: - Images / Posters

/// Response from TMDB `/movie/{id}/images` endpoint.
struct TMDBImagesResponse: Codable {
    let posters: [TMDBPoster]
}

/// A single poster image from TMDB.
struct TMDBPoster: Codable, Identifiable {
    let filePath: String
    let width: Int
    let height: Int
    let voteAverage: Double
    let iso639_1: String?

    var id: String { filePath }

    enum CodingKeys: String, CodingKey {
        case width, height
        case filePath = "file_path"
        case voteAverage = "vote_average"
        case iso639_1 = "iso_639_1"
    }
}
