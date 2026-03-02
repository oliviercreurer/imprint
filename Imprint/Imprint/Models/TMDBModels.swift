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
    let runtime: Int?
    let genres: [TMDBGenre]?
    let credits: TMDBCredits?
    let productionCountries: [TMDBCountry]?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres, credits
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

    /// Top cast members by billing order (up to 10).
    var topCast: [String] {
        let sorted = credits?.cast?.sorted(by: { $0.order < $1.order }) ?? []
        return Array(sorted.prefix(10).map(\.name))
    }

    /// Comma-separated genre names.
    var genreList: String? {
        guard let genres, !genres.isEmpty else { return nil }
        return genres.map(\.name).joined(separator: ", ")
    }
}

struct TMDBGenre: Codable {
    let id: Int
    let name: String
}

struct TMDBCredits: Codable {
    let cast: [TMDBCastMember]?
    let crew: [TMDBCrewMember]
}

struct TMDBCastMember: Codable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int

    enum CodingKeys: String, CodingKey {
        case id, name, character, order
        case profilePath = "profile_path"
    }
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

// MARK: - TV Search

/// Response wrapper for TMDB `/search/tv` endpoint.
struct TMDBTVSearchResponse: Codable {
    let results: [TMDBTVShow]
    let totalResults: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case results
        case totalResults = "total_results"
        case totalPages = "total_pages"
    }
}

/// A TV show result from TMDB search.
struct TMDBTVShow: Codable, Identifiable {
    let id: Int
    let name: String
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let firstAirDate: String?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case originalName = "original_name"
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
    }

    var firstAirYear: Int? {
        guard let dateStr = firstAirDate, dateStr.count >= 4 else { return nil }
        return Int(dateStr.prefix(4))
    }
}

// MARK: - TV Details

/// Full TV show detail from TMDB `/tv/{id}` endpoint with credits appended.
struct TMDBTVDetail: Codable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let firstAirDate: String?
    let genres: [TMDBGenre]?
    let credits: TMDBCredits?
    let productionCountries: [TMDBCountry]?
    let createdBy: [TMDBCreator]?
    let numberOfSeasons: Int?
    let seasons: [TMDBTVSeason]?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, genres, credits, seasons
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
        case productionCountries = "production_countries"
        case createdBy = "created_by"
        case numberOfSeasons = "number_of_seasons"
    }

    /// Returns only numbered seasons (excludes specials / season 0).
    var numberedSeasons: [TMDBTVSeason] {
        (seasons ?? []).filter { $0.seasonNumber > 0 }.sorted { $0.seasonNumber < $1.seasonNumber }
    }

    /// The first creator listed.
    var creatorName: String? {
        createdBy?.first?.name
    }

    /// All creator names joined.
    var creatorList: String? {
        guard let creators = createdBy, !creators.isEmpty else { return nil }
        return creators.map(\.name).joined(separator: ", ")
    }

    /// Primary production country name.
    var country: String? {
        productionCountries?.first?.name
    }

    var firstAirYear: Int? {
        guard let dateStr = firstAirDate, dateStr.count >= 4 else { return nil }
        return Int(dateStr.prefix(4))
    }

    /// Top cast members by billing order (up to 10).
    var topCast: [String] {
        let sorted = credits?.cast?.sorted(by: { $0.order < $1.order }) ?? []
        return Array(sorted.prefix(10).map(\.name))
    }

    /// Comma-separated genre names.
    var genreList: String? {
        guard let genres, !genres.isEmpty else { return nil }
        return genres.map(\.name).joined(separator: ", ")
    }
}

struct TMDBCreator: Codable {
    let id: Int
    let name: String
}

/// A season summary returned in the TV detail response.
struct TMDBTVSeason: Codable, Identifiable {
    let id: Int
    let name: String?
    let seasonNumber: Int
    let episodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
    }
}

// MARK: - TV Episode Details

/// Full episode detail from TMDB `/tv/{id}/season/{s}/episode/{e}` endpoint.
struct TMDBEpisodeDetail: Codable {
    let id: Int
    let name: String
    let overview: String?
    let airDate: String?
    let runtime: Int?
    let seasonNumber: Int
    let episodeNumber: Int
    let crew: [TMDBCrewMember]?
    let guestStars: [TMDBCastMember]?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, runtime, crew
        case airDate = "air_date"
        case seasonNumber = "season_number"
        case episodeNumber = "episode_number"
        case guestStars = "guest_stars"
    }

    /// The first director found in the episode crew.
    var director: String? {
        crew?.first(where: { $0.job == "Director" })?.name
    }

    /// Year extracted from the air date string.
    var airYear: Int? {
        guard let dateStr = airDate, dateStr.count >= 4 else { return nil }
        return Int(dateStr.prefix(4))
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
