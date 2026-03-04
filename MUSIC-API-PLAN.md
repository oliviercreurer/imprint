# Music API Integration Plan

> Implementation plan for adding music search to Imprint's "Add Music" flow.

## Current State

The app is already primed for music. `MediaType.music` exists in the enum, `Record` has `artist` and `musicReleaseDate` fields, and theme colors are fully defined. What's missing: an API service, response models, an `AddMusicView`, and the wiring in `ContentView`.

---

## 1. API Choice: MusicBrainz + Cover Art Archive

**Why MusicBrainz:**

- Completely free and open — no API key required for read-only access
- No authentication needed (just a custom User-Agent header)
- Comprehensive database: albums, singles, EPs, compilations, artists
- Rate limit: 1 request/second average (generous for a search-and-select flow)
- JSON responses via `?fmt=json`
- Stable, long-running project backed by MetaBrainz Foundation

**Why not Discogs:**

- Requires OAuth for search endpoints (more setup, token management)
- 60 req/min authenticated — fine, but MusicBrainz is simpler to integrate
- Better suited for collectors/marketplace use cases

**Why not Spotify/Apple Music:**

- Spotify requires OAuth + developer app + token refresh
- Apple Music requires a paid developer account + MusicKit entitlement
- Both are overkill for a search-and-select flow

**Cover Art Archive** (companion to MusicBrainz):

- Free, no auth, no rate limit documented
- Provides album artwork in 250px, 500px, and 1200px sizes
- Lookup by MusicBrainz Release Group ID (MBID)
- URL pattern: `https://coverartarchive.org/release-group/{mbid}/front-{size}`

---

## 2. API Endpoints

### Search releases (albums)

```
GET https://musicbrainz.org/ws/2/release-group?query={query}&type=album&fmt=json&limit=20
```

Returns release groups (albums, EPs, singles) with artist credits, first release date, and MBID.

### Release group details

```
GET https://musicbrainz.org/ws/2/release-group/{mbid}?inc=artists+releases&fmt=json
```

Returns full details including all releases under the group, artist info, and type (album, single, EP).

### Cover art lookup

```
GET https://coverartarchive.org/release-group/{mbid}
```

Returns JSON listing of available cover art images with URLs. For the front cover specifically:

```
https://coverartarchive.org/release-group/{mbid}/front-500
```

This redirects to the actual image URL. Can be used directly as an image source.

---

## 3. Data Models (MusicBrainzModels.swift)

```
MBSearchResponse
  └─ releaseGroups: [MBReleaseGroup]

MBReleaseGroup
  ├─ id: String (MBID)
  ├─ title: String
  ├─ primaryType: String? ("Album", "Single", "EP")
  ├─ firstReleaseDate: String?
  ├─ artistCredit: [MBArtistCredit]
  └─ computed: artistName, releaseYear

MBArtistCredit
  ├─ name: String
  └─ artist: MBArtist

MBArtist
  ├─ id: String (MBID)
  ├─ name: String
  └─ disambiguation: String?

MBCoverArtResponse
  └─ images: [MBCoverImage]

MBCoverImage
  ├─ image: String (full-size URL)
  ├─ thumbnails: MBThumbnails
  ├─ front: Bool
  └─ back: Bool

MBThumbnails
  ├─ small: String? (250px)
  ├─ large: String? (500px)
  └─ _1200: String? (1200px, key is "1200")
```

All models conform to `Codable` with `CodingKeys` for JSON mapping (MusicBrainz uses kebab-case: `release-groups`, `artist-credit`, `first-release-date`).

---

## 4. Service Layer (MusicBrainzService.swift)

Follows the singleton pattern established by `TMDBService` and `HardcoverService`.

```
MusicBrainzService
  ├─ static let shared
  ├─ private let baseURL = "https://musicbrainz.org/ws/2"
  ├─ private let coverArtBaseURL = "https://coverartarchive.org"
  │
  ├─ searchReleaseGroups(query:) async throws -> [MBReleaseGroup]
  ├─ getReleaseGroupDetail(id:) async throws -> MBReleaseGroup
  ├─ getCoverArt(releaseGroupId:) async throws -> [MBCoverImage]
  └─ static func coverURL(mbid:, size:) -> URL?
```

**Key implementation details:**

- Custom `User-Agent` header required: `"Imprint/1.0 (olvr@hey.com)"` — MusicBrainz requires this for rate limit compliance
- All requests include `?fmt=json`
- No API key or plist needed
- 1 req/sec rate limit handled by adding a simple throttle (sleep between rapid calls)
- `isConfigured` always returns `true` (no key to validate)

---

## 5. AddMusicView.swift

Follows the same 3-phase pattern as `AddFilmView` and `AddBookView`:

### Phase 1: Search

- Text field with debounced search (reuse the 150ms pattern)
- Results show: album art thumbnail (250px) + title + artist + year
- Tap a result → fetch cover art options → advance to Phase 2

### Phase 2: Cover Picker

- Grid of available cover art from Cover Art Archive
- If no art available, show a placeholder and skip to Phase 3
- Select artwork → advance to Phase 3

### Phase 3: Confirm

- Show selected cover art, album title, artist
- Date picker (listened on)
- Optional note field
- Save → create Record with:
  - `name`: album title
  - `artist`: artist name
  - `mediaType`: `.music`
  - `musicReleaseDate`: year from firstReleaseDate
  - `posterPath`: `"mb:{coverArtURL}"` (prefixed like Hardcover's `"hc:"` pattern)
  - `externalId`: MusicBrainz MBID (for potential future lookups)

---

## 6. Record Model Updates

The `Record` model already has `artist` and `musicReleaseDate` fields. Additional changes needed:

- `coverImageURL(size:)` computed property needs a new branch to handle `"mb:"` prefixed paths (similar to `"hc:"` for Hardcover)
- `creatorLabel` already returns `artist` for `.music` type
- `releaseYear` already returns `musicReleaseDate` for `.music` type

---

## 7. ContentView Wiring

Add the sheet trigger (matches existing pattern):

```swift
@State private var showingAddMusic = false

// In the onAdd closure:
} else if mediaType == .music {
    showingAddMusic = true
}

// Sheet:
.sheet(isPresented: $showingAddMusic) {
    AddMusicView(initialRecordType: selectedTab)
}
```

---

## 8. Rate Limit Strategy

MusicBrainz allows 1 req/sec average. Our flow makes at most 3 requests per user action:

1. Search (on debounced input) — 1 request
2. Detail fetch (on selection) — 1 request
3. Cover art fetch (on selection) — 1 request to Cover Art Archive (separate service, separate limit)

With 150ms search debounce, we're well within limits for normal use. For safety, add a simple timestamp-based throttle in the service that ensures at least 1 second between MusicBrainz API calls.

---

## 9. Implementation Order

1. **MusicBrainzModels.swift** — Define all response types
2. **MusicBrainzService.swift** — Singleton service with search, detail, and cover art methods
3. **AddMusicView.swift** — 3-phase view following AddFilmView pattern
4. **Record model update** — Add `"mb:"` prefix handling in `coverImageURL`
5. **ContentView wiring** — Add sheet state + trigger
6. **Test** — Search, select, pick art, confirm, verify Record saves correctly

---

## 10. Files to Create

- `Imprint/Imprint/Models/MusicBrainzModels.swift`
- `Imprint/Imprint/Services/MusicBrainzService.swift`
- `Imprint/Imprint/Views/AddMusicView.swift`

## Files to Modify

- `Imprint/Imprint/Models/Record.swift` — `coverImageURL` for `"mb:"` prefix
- `Imprint/Imprint/Views/ContentView.swift` — sheet state + wiring
