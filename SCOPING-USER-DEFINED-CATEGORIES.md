# Imprint: User-Defined Categories

## Overview

This document scopes the architectural shift from Imprint's current hardcoded media types (`film`, `tv`, `book`, `music`) to a fully generic, user-defined category system. The goal is to transform Imprint from a media tracker into a flexible personal logging tool that can track anything — media, restaurants, hikes, recipes, workouts, places visited, or whatever a user decides is worth remembering.

This change also removes all external API integrations (TMDB, Hardcover). All entries become manual.

---

## Motivation

1. **Flexibility.** Users should be able to define their own categories with their own fields, rather than being constrained to four media types.
2. **Sustainability.** Removing dependency on third-party APIs (TMDB, Hardcover) eliminates licensing costs and external points of failure — critical for commercialization.
3. **Simplicity.** A single, universal record form replaces four type-specific add views, reducing codebase surface area.

---

## Data Model

### New Entities

#### `Category`

Represents a user-defined type (e.g., "Film", "Restaurant", "Hike").

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary key |
| `name` | `String` | Display name (e.g., "Film") |
| `iconName` | `String` | SF Symbol name |
| `colorHex` | `String` | User-chosen accent color, stored as hex |
| `sortOrder` | `Int` | Controls display order in filter bar, menus |
| `isEnabled` | `Bool` | Replaces the current `disabledMediaTypes` AppStorage mechanism |
| `createdAt` | `Date` | Timestamp |

#### `FieldDefinition`

Defines a custom field within a category.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary key |
| `category` | `Category` | Relationship — belongs to one category |
| `label` | `String` | Display label (e.g., "Director", "Cuisine") |
| `fieldType` | `String` | One of: `text`, `date`, `number`, `image` |
| `sortOrder` | `Int` | Controls field display order in forms and detail views |
| `isRequired` | `Bool` | Whether the field must be filled on entry |

#### `FieldValue`

Stores the actual data for a single field on a single record.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary key |
| `record` | `Record` | Relationship — belongs to one record |
| `fieldDefinition` | `FieldDefinition` | Relationship — belongs to one field definition |
| `textValue` | `String?` | Populated when `fieldType == text` |
| `numberValue` | `Double?` | Populated when `fieldType == number` |
| `dateValue` | `Date?` | Populated when `fieldType == date` |
| `imagePath` | `String?` | Populated when `fieldType == image`; relative file path |

Only one value column is populated per row, determined by the parent `FieldDefinition.fieldType`.

### Modified Entity: `Record`

The `Record` model sheds all type-specific optional fields and retains only universal properties.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary key |
| `category` | `Category` | Relationship — replaces `mediaTypeRaw` |
| `recordType` | `String` | `"logged"` or `"queued"` (unchanged) |
| `name` | `String` | Title of the entry (universal, first-class) |
| `note` | `String?` | Freeform note (universal, first-class) |
| `createdAt` | `Date` | Timestamp |
| `startedOn` | `Date?` | When the user started (universal for logged records) |
| `finishedOn` | `Date?` | When the user finished (universal for logged records) |
| `fieldValues` | `[FieldValue]` | Relationship — has many field values |

**Removed fields:** `director`, `author`, `artist`, `creator`, `filmReleaseDate`, `tvReleaseYear`, `publicationDate`, `musicReleaseDate`, `tmdbId`, `posterPath`, `hardcoverId`, `runtime`, `pageCount`, `startPage`, `endPage`, `season`, `episode`, `episodeName`, `episodeDirector`, `episodeAirYear`, `episodeRuntime`, `numberOfSeasons`, `episodesJSON`, `overview`, `genres`, `cast`, `country`, `translator`.

### Image Storage

Images are stored as files on disk, not as `Data` blobs in SwiftData. The convention:

```
<App Documents>/images/<recordId>/<fieldDefinitionId>.jpg
```

`FieldValue.imagePath` stores the relative path from the app's documents directory. This keeps the SwiftData store lean and avoids memory pressure when loading record lists.

### Entity Relationship Diagram

```
Category (1) ──── (many) FieldDefinition
    │                          │
    │                          │
   (1)                        (1)
    │                          │
  (many)                    (many)
    │                          │
  Record (1) ──────── (many) FieldValue
```

---

## Default Category Templates

On first launch (or when no categories exist), Imprint seeds the database with pre-built templates:

| Category | Icon | Fields |
|---|---|---|
| **Film** | `film` | Director (text), Release Date (date), Runtime (number) |
| **TV** | `tv` | Creator (text), Season (number), Episode (number) |
| **Book** | `book` | Author (text), Publication Date (date), Page Count (number) |
| **Music** | `music.note` | Artist (text), Release Date (date) |

Users can modify, extend, or delete these. They serve as starting points, not permanent fixtures.

---

## UI Changes

### What Stays the Same

- **Two-tab structure** (Logged / Queued) — unchanged.
- **Filter bar** — still renders one chip per enabled category. Driven by `Category` entities instead of enum cases.
- **Monthly grouping with bar charts** — still groups logged records by month. Bar segments driven by category colors.
- **Footer add menu** — still shows a categorized "+" menu. Items pulled from enabled categories.
- **Settings toggles** — still lets users enable/disable categories. Now backed by `Category.isEnabled`.

### What Changes

- **Add/edit flow.** The four specialized views (`AddFilmView`, `AddTVView`, `AddBookView`, `RecordFormView`) collapse into a single `RecordFormView` that dynamically renders fields from the selected category's `FieldDefinition`s. The form includes a universal "Name" text field at the top, then renders each custom field in sort order, with a "Note" text area at the bottom.
- **Detail view.** `RecordDetailView` renders dynamically based on field values rather than switching on media type. A potential layout: name as title, then field values listed in definition order, note at the bottom.
- **Category management.** A new settings section where users can create, edit, reorder, and delete categories. Each category's edit screen lets users add/remove/reorder field definitions and pick an icon + color.
- **Color system.** Currently, `Theme.swift` hardcodes a 6-color palette per media type. This shifts to a single user-chosen color per category, with programmatic derivation of subtle/bold/dark variants (e.g., adjusting saturation and brightness).
- **Image field.** When a field of type `image` appears in the form, it renders as a tappable area that opens the camera or photo library via `PhotosPicker` or `UIImagePickerController`.

### Removed

- `AddFilmView`, `AddTVView`, `AddBookView` — replaced by the universal `RecordFormView`.
- TMDB search/poster picker flow.
- Hardcover search flow.
- All API service files (`TMDBService`, `HardcoverService`) and their associated models.

---

## Migration Strategy

For users upgrading from the current version, a SwiftData migration maps existing records to the new schema:

1. **Create default categories** (Film, TV, Book, Music) with their field definitions.
2. **For each existing `Record`:**
   - Set the `category` relationship based on the old `mediaTypeRaw` value.
   - Create `FieldValue` entities from the old type-specific fields:
     - Film: `director` → "Director" text value, `filmReleaseDate` → "Release Date" date value, etc.
     - TV: `creator` → "Creator", `season` → "Season", `episode` → "Episode", etc.
     - Book: `author` → "Author", `publicationDate` → "Publication Date", etc.
     - Music: `artist` → "Artist", `musicReleaseDate` → "Release Date", etc.
   - Poster images (from `posterPath` TMDB URLs): these are remote URLs that will no longer resolve without the API. Options: drop them, or run a one-time download during migration to save them locally as image field values. Dropping is simpler and more reliable.
3. **Remove old columns** from the `Record` entity via SwiftData's lightweight migration or a versioned schema migration.

This is a **heavyweight migration** — it creates new entities and moves data between columns. It will need thorough testing, particularly around edge cases (records with nil fields, records created via the generic `RecordFormView`, etc.).

---

## Files Affected

### Deleted

| File | Reason |
|---|---|
| `AddFilmView.swift` | Replaced by universal form |
| `AddTVView.swift` | Replaced by universal form |
| `AddBookView.swift` | Replaced by universal form |
| `TMDBService.swift` | No more API integrations |
| `HardcoverService.swift` | No more API integrations |
| `TMDBModels.swift` | No more API integrations |
| `HardcoverModels.swift` | No more API integrations |

### Heavily Modified

| File | Changes |
|---|---|
| `Enums.swift` | Remove `MediaType` enum entirely. `RecordType` stays. |
| `Record.swift` | Strip all type-specific fields; add `category` and `fieldValues` relationships. |
| `Theme.swift` | Replace hardcoded per-type color palettes with programmatic derivation from a single hex. |
| `MediaTypeAvailability.swift` | Replace with category-based enabled/disabled logic, or remove entirely if `Category.isEnabled` suffices. |
| `RecordFormView.swift` | Rewrite to dynamically render fields from `FieldDefinition`s. |
| `RecordDetailView.swift` | Rewrite to dynamically render field values. |
| `RecordRowView.swift` | Adapt to show category-driven creator/subtitle from field values. |
| `RecordListView.swift` | Filter by category instead of `MediaType`. |
| `RecordGrouping.swift` | Group by `Category` instead of `MediaType`. |
| `MediaFilterBar.swift` | Drive chips from `Category` entities. Rename to `CategoryFilterBar`. |
| `FooterToolbar.swift` | Drive menu items from `Category` entities. |
| `SettingsView.swift` | Add category management section; replace media type toggles. |
| `ContentView.swift` | Update environment injection; use `Category` queries instead of `MediaType` arrays. |
| `ImprintApp.swift` | Register new model types in the SwiftData container; trigger migration and seeding logic. |

### New Files

| File | Purpose |
|---|---|
| `Category.swift` | `@Model` entity for user-defined categories |
| `FieldDefinition.swift` | `@Model` entity for field schemas within a category |
| `FieldValue.swift` | `@Model` entity for actual field data on a record |
| `CategoryEditorView.swift` | UI for creating/editing a category and its fields |
| `ImageFieldView.swift` | Reusable component for image capture/display in forms |
| `CategorySeeder.swift` | First-launch seeding logic for default templates |
| `ColorDerivation.swift` | Utility for generating subtle/bold/dark color variants from a single hex |

---

## Implementation Phases

### Phase 1: Data Layer

Introduce `Category`, `FieldDefinition`, and `FieldValue` models. Rewrite `Record` to use relationships instead of hardcoded fields. Build the seeding logic for default categories. Write and test the migration from the old schema.

### Phase 2: Universal Form

Build the dynamic `RecordFormView` that renders fields from a category's definitions. Support text, date, number, and image field types. This replaces all four current add views.

### Phase 3: Display Layer

Update `RecordDetailView`, `RecordRowView`, `RecordListView`, and `RecordGrouping` to work with the new dynamic model. Update the filter bar, footer menu, and settings toggles to be driven by `Category` entities.

### Phase 4: Category Management

Build `CategoryEditorView` — the UI for creating and editing categories, adding/removing/reordering fields, and choosing icons and colors. Integrate into the settings flow.

### Phase 5: Cleanup

Delete all API-related files and the old type-specific add views. Remove the `MediaType` enum. Audit for any remaining hardcoded references.

---

## Open Questions

1. **Creator field as first-class?** Currently, `Record` has a computed `creatorLabel` that resolves to director/author/artist based on type. Should there be a first-class "creator" field on `Record` alongside `name`, or is it better to let this be a custom field that users can name whatever they want? The latter is more flexible; the former enables better default display in list rows.

2. **Row subtitle strategy.** `RecordRowView` currently shows the creator underneath the title. With dynamic fields, what should the subtitle be? Options: the first text field value, a user-designated "subtitle field" on the category, or nothing (just the title).

3. **Color picker scope.** Should users pick from a curated palette (easier to keep visually consistent) or have a full color picker? A curated palette is simpler to implement and prevents clashing aesthetics.

4. **Field type expansion.** The initial set is text, date, number, and image. Future candidates worth considering: rating (1–5 stars), URL, toggle/boolean, tags, and location. These don't need to be in v1 but are worth designing the `fieldType` system to accommodate.

5. **Category deletion behavior.** When a user deletes a category, what happens to its records? Options: delete them (destructive), move them to an "Uncategorized" bucket, or prevent deletion while records exist.

6. **Record display configuration.** Beyond field definitions, should a category also store display preferences — like which field to use as a subtitle in list view, or whether to show the image field prominently as a hero/cover?
