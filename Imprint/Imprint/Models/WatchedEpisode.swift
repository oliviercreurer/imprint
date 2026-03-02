import Foundation

/// Represents a single watched episode within a TV log entry.
///
/// Multiple `WatchedEpisode` values are JSON-encoded and stored
/// in `Record.episodesJSON` to support multi-episode logging.
struct WatchedEpisode: Codable, Identifiable {

    var id: UUID
    var season: Int
    var episode: Int
    var episodeName: String?
    var episodeDirector: String?
    var episodeAirYear: Int?
    var episodeRuntime: Int?

    /// Formatted season/episode code, e.g. "S02.E05".
    var seasonEpisodeCode: String {
        String(format: "S%02d.E%02d", season, episode)
    }

    init(
        id: UUID = UUID(),
        season: Int,
        episode: Int,
        episodeName: String? = nil,
        episodeDirector: String? = nil,
        episodeAirYear: Int? = nil,
        episodeRuntime: Int? = nil
    ) {
        self.id = id
        self.season = season
        self.episode = episode
        self.episodeName = episodeName
        self.episodeDirector = episodeDirector
        self.episodeAirYear = episodeAirYear
        self.episodeRuntime = episodeRuntime
    }
}
