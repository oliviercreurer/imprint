# Film API Migration: TMDB → OMDB

> Investigation into replacing TMDB with OMDB for film lookups. TV shows remain on TMDB for now (OMDB's TV coverage is limited).

## Why Migrate

TMDB's commercial licensing is too expensive for Imprint's scale. OMDB offers a simpler, more affordable alternative for movie data.

## OMDB API Overview

- **Auth**: API key (query parameter), obtained via registration at omdbapi.com
- **Free tier**: 1,000 requests/day (generous for a personal logging app)
- **Rate limit**: 100 calls per 60 seconds
- **Response format**: JSON, CamelCase fields
- **Poster images**: Standard tier returns Amazon CDN URLs (`m.media-amazon.com`). Patron tier unlocks OMDB's own poster API (280K+ posters, up to 2000×3000)

---

## Current TMDB Usage for Films

### Service methods consumed by AddFilmView

| TMDB Method | Purpose | Data Used |
|-------------|---------|-----------|
| `searchMovies(query:)` | Search by title | id, title, posterPath, releaseDate, overview |
| `getMovieDetails(id:)` | Full metadata + credits | director, runtime, overview, genres, cast, country, releaseYear |
| `getMoviePosters(id:)` | Multiple poster options | filePath, voteAverage (sorted) |
| `posterURL(path:size:)` | Image URL construction | Sizes: w92, w185, w342, w500 |

### Record fields populated from TMDB (films)

```
tmdbId          → movie ID (Int)
name            → title
director        → from credits crew (job == "Director")
filmReleaseDate → year extracted from release_date
country         → first production country
posterPath      → TMDB file path like "/abc123.jpg"
runtime         → minutes
overview        → plot synopsis
genres          → comma-separated genre names
cast            → comma-separated top 10 actor names
```

### Image sizes used

- Search results thumbnails: `w92`
- Poster picker grid: `w342`
- Confirm phase card: `w185`
- Detail view hero: `w500`

---

## OMDB Equivalent Endpoints

### Search

```
GET https://www.omdbapi.com/?apikey=KEY&s=QUERY&type=movie
```

Returns: `{ Search: [{ Title, Year, imdbID, Type, Poster }], totalResults }`.

Pagination via `&page=N` (10 results per page).

**Limitation**: Search results are minimal — no overview/plot, no multiple posters. Just title, year, poster URL, and IMDb ID.

### Detail Lookup

```
GET https://www.omdbapi.com/?apikey=KEY&i=IMDB_ID&plot=full
```

Returns: `{ Title, Year, Rated, Released, Runtime, Genre, Director, Writer, Actors, Plot, Language, Country, Awards, Poster, Ratings[], imdbRating, imdbVotes, imdbID, Type, BoxOffice }`.

**This single call replaces both `getMovieDetails` and the basic metadata from search.**

---

## Field Mapping: TMDB → OMDB

| Record Field | TMDB Source | OMDB Source | Notes |
|-------------|-------------|-------------|-------|
| `name` | `movie.title` | `Title` | Direct map |
| `director` | `credits.crew` (job == Director) | `Director` | OMDB returns as string, may contain multiple comma-separated |
| `filmReleaseDate` | `release_date` → year | `Year` | OMDB returns year as string (e.g. "1999") |
| `country` | `production_countries[0].name` | `Country` | OMDB returns comma-separated string |
| `posterPath` | `/abc123.jpg` (TMDB path) | Full Amazon CDN URL | **Breaking change** — see migration notes |
| `runtime` | `runtime` (Int, minutes) | `Runtime` (String, e.g. "136 min") | Needs parsing |
| `overview` | `overview` | `Plot` (use `&plot=full`) | Direct map |
| `genres` | `genres[].name` joined | `Genre` | OMDB already comma-separated |
| `cast` | `credits.cast[0..9].name` | `Actors` | OMDB returns top-billed, comma-separated |
| `tmdbId` | TMDB movie ID | **No equivalent** | Store `imdbID` instead (e.g. "tt0133093") |

---

## What OMDB Cannot Do (vs TMDB)

### No multiple poster options

TMDB's `getMoviePosters` returns a ranked list of available posters. OMDB returns exactly **one** poster URL per movie. This means:

- **The poster picker phase in AddFilmView has no OMDB equivalent**
- Options: (a) skip the poster picker for films, (b) use a fallback poster service, (c) accept the single poster

### No credits breakdown

TMDB returns full cast/crew arrays with roles, character names, and profile images. OMDB returns `Director`, `Writer`, and `Actors` as comma-separated strings. No character names, no crew beyond director/writer, no profile photos.

### No backdrop images

TMDB provides landscape backdrop images. OMDB has posters only.

### Lower image quality (free tier)

Standard OMDB poster URLs point to Amazon's CDN at a single resolution. TMDB offers multiple sizes (w92 through original). The OMDB Patron tier provides higher-res posters via their own API.

---

## Migration Strategy

### Phase 1: New service (OMDBService.swift)

Create alongside TMDBService (don't delete TMDB yet):

```
OMDBService
  ├─ static let shared
  ├─ private let apiKey: String  // from OMDB.plist
  ├─ searchMovies(query:) async throws -> [OMDBSearchResult]
  ├─ getMovieDetails(imdbId:) async throws -> OMDBMovieDetail
  └─ var isConfigured: Bool
```

### Phase 2: New models (OMDBModels.swift)

```
OMDBSearchResponse
  ├─ search: [OMDBSearchResult]  // CodingKey: "Search"
  └─ totalResults: String

OMDBSearchResult
  ├─ title: String        // "Title"
  ├─ year: String          // "Year"
  ├─ imdbID: String        // "imdbID"
  ├─ type: String          // "Type"
  └─ poster: String        // "Poster" (full URL or "N/A")

OMDBMovieDetail
  ├─ title: String
  ├─ year: String
  ├─ rated: String
  ├─ released: String
  ├─ runtime: String       // "136 min" — needs parsing
  ├─ genre: String         // comma-separated
  ├─ director: String
  ├─ writer: String
  ├─ actors: String        // comma-separated
  ├─ plot: String
  ├─ country: String
  ├─ poster: String        // full URL
  ├─ imdbRating: String
  ├─ imdbID: String
  └─ computed: runtimeMinutes, releaseYear, firstCountry
```

### Phase 3: Update AddFilmView

- Replace `TMDBService` calls with `OMDBService`
- Search phase: show results from OMDB search (poster + title + year)
- **Remove poster picker phase** (or simplify to single poster preview)
- Confirm phase: fetch full details via `getMovieDetails(imdbId:)`
- Save `imdbID` to a new field (or repurpose `tmdbId` → rename to `externalId`)

### Phase 4: Update Record model

- `posterPath` handling: OMDB returns full URLs, not relative paths
  - Add `"omdb:"` prefix pattern (like `"hc:"` for Hardcover)
  - Or store full URL directly and detect by prefix (`https://m.media-amazon.com/`)
- `coverImageURL(size:)` needs a new branch for OMDB URLs (no size variants — return as-is)
- Consider renaming `tmdbId` → `externalId: String?` to hold IMDb IDs for films, TMDB IDs for TV

### Phase 5: Existing data migration

Records already saved with TMDB poster paths will break if we remove TMDBService. Options:

- **Keep TMDBService read-only** for rendering existing poster paths (safest)
- **Migrate on first launch**: fetch OMDB poster URL for each existing film record by title+year, update `posterPath`
- **Lazy migration**: update `posterPath` when user opens a record's detail view

**Recommendation**: Keep TMDBService's `posterURL()` static method and image base URL for backwards compatibility. New films use OMDB, old films continue resolving via TMDB image CDN.

---

## TV Shows: No Change

OMDB's TV coverage is limited — no episode-level details, no season breakdowns, no multiple posters. **TV shows should stay on TMDB** for now. The TV endpoints (`searchTV`, `getTVDetails`, `getTVPosters`, `getEpisodeDetails`) remain unchanged.

---

## Impact on API Key Management

- TMDB key stays in `TMDB.plist` (still needed for TV + legacy film posters)
- Add `OMDB.plist` with new API key
- Add `**/OMDB.plist` to `.gitignore`

---

## Implementation Order

1. Create `OMDBModels.swift`
2. Create `OMDBService.swift` with search + detail methods
3. Create `OMDB.plist` (add to `.gitignore`)
4. Update `Record.swift` — add OMDB URL handling in `coverImageURL`
5. Update `AddFilmView.swift` — swap to OMDB, simplify poster phase
6. Keep TMDBService for TV + legacy poster resolution
7. Test with existing records (ensure old posters still load)

---

## Open Questions

1. **Poster picker**: Drop it for films, or find an alternative poster source?
2. **External ID field**: Rename `tmdbId` to `externalId: String?` to be API-agnostic?
3. **Patron tier**: Worth the small cost for higher-res posters via OMDB's own API?
4. **IMDb ratings**: OMDB includes `imdbRating` — display in the detail view?
