import Foundation

/// Handles all communication with The Movie Database (TMDB) API.
///
/// Loads the API key from `TMDB.plist` in the app bundle and provides
/// async methods for searching movies, fetching details, and retrieving posters.
final class TMDBService: Sendable {

    static let shared = TMDBService()

    private let apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p"

    private init() {
        guard
            let path = Bundle.main.path(forResource: "TMDB", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let key = dict["APIKey"] as? String,
            key != "YOUR_TMDB_API_KEY_HERE"
        else {
            self.apiKey = ""
            return
        }
        self.apiKey = key
    }

    /// Whether the service has a valid API key configured.
    var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Search

    /// Search for movies matching the given query string.
    func searchMovies(query: String) async throws -> [TMDBMovie] {
        guard isConfigured else { return [] }

        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "\(baseURL)/search/movie?api_key=\(apiKey)&query=\(encoded)&include_adult=false")!

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
        return response.results
    }

    // MARK: - Movie Details

    /// Fetch full details for a movie, including credits (for director).
    func getMovieDetails(id: Int) async throws -> TMDBMovieDetail {
        let url = URL(string: "\(baseURL)/movie/\(id)?api_key=\(apiKey)&append_to_response=credits")!

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TMDBMovieDetail.self, from: data)
    }

    // MARK: - Posters

    /// Fetch all available poster images for a movie.
    func getMoviePosters(id: Int) async throws -> [TMDBPoster] {
        let url = URL(string: "\(baseURL)/movie/\(id)/images?api_key=\(apiKey)")!

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TMDBImagesResponse.self, from: data)

        // Sort by vote average descending so the best-rated posters come first.
        return response.posters.sorted { $0.voteAverage > $1.voteAverage }
    }

    // MARK: - Image URLs

    /// Constructs a full image URL for a TMDB poster path.
    ///
    /// - Parameters:
    ///   - path: The poster file path from TMDB (e.g. "/abc123.jpg").
    ///   - size: The image size. Common values: "w92", "w154", "w185", "w342", "w500", "w780", "original".
    static func posterURL(path: String, size: String = "w500") -> URL? {
        URL(string: "\(imageBaseURL)/\(size)\(path)")
    }
}
