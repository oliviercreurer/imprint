import SwiftUI
import SwiftData

/// A custom modal form for creating a new record or editing an existing one.
///
/// Styled to match the Figma design: white background with rounded top corners,
/// custom form fields with labeled inputs, and media-type chip selector.
struct RecordFormView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    private var isDark: Bool { appearanceMode == "dark" }

    var existingRecord: Record?

    // MARK: - Form State

    @State private var recordType: RecordType
    @State private var mediaType: MediaType = .film
    @State private var name: String = ""
    @State private var note: String = ""
    @State private var country: String = ""

    // Logged fields
    @State private var finishedOn: Date = Date()

    // Film
    @State private var director: String = ""
    @State private var filmReleaseDate: String = ""
    @State private var tmdbId: String = ""
    @State private var posterPath: String = ""
    @State private var showingTMDBSearch = false

    // TV
    @State private var creator: String = ""
    @State private var season: String = ""
    @State private var episode: String = ""

    // Book
    @State private var author: String = ""
    @State private var publicationDate: String = ""
    @State private var translator: String = ""

    // Music
    @State private var artist: String = ""
    @State private var musicReleaseDate: String = ""

    private var isEditing: Bool { existingRecord != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Init

    init(initialRecordType: RecordType = .logged, initialMediaType: MediaType = .film, existingRecord: Record? = nil) {
        self.existingRecord = existingRecord
        _recordType = State(initialValue: existingRecord?.recordType ?? initialRecordType)
        _mediaType = State(initialValue: existingRecord?.mediaType ?? initialMediaType)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pinned title bar
            HStack {
                Text(isEditing ? "Edit Entry" : (recordType == .logged ? "New Log Entry" : "New Queue Entry"))
                    .font(ImprintFonts.modalTitle)
                    .foregroundStyle(ImprintColors.headingText(isDark))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ImprintColors.headingText(isDark))
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 48)
            .padding(.bottom, 16)
            .background(ImprintColors.modalBg(isDark))

            // Scrollable form content
            ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Media type chips
                    mediaTypeChips

                        // Log / Queue toggle (hidden when editing)
                        if !isEditing {
                            recordTypeToggle
                        }

                        // Date (for logged records)
                        if recordType == .logged {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Date")
                                        .font(ImprintFonts.formLabel)
                                        .foregroundStyle(ImprintColors.headingText(isDark))
                                    Spacer()
                                    Text("Required")
                                        .font(ImprintFonts.formLabel)
                                        .foregroundStyle(ImprintColors.required)
                                }
                                ImprintDatePicker(selection: $finishedOn, hasSetDate: .constant(true))
                            }
                        }

                        // Name
                        FormField(label: "Name", isRequired: true, isDark: isDark) {
                            TextField("", text: $name)
                                .font(ImprintFonts.formValue)
                                .foregroundStyle(ImprintColors.modalText(isDark))
                        }

                        // Media-specific fields
                        mediaSpecificFields

                        // Country
                        FormField(label: "Country", isDark: isDark) {
                            TextField("", text: $country)
                                .font(ImprintFonts.formValue)
                                .foregroundStyle(ImprintColors.modalText(isDark))
                        }

                        // Note
                        FormField(label: "Note", isDark: isDark) {
                            TextEditor(text: $note)
                                .font(ImprintFonts.noteBody)
                                .foregroundStyle(ImprintColors.modalText(isDark))
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                        }
                    }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .padding(.bottom, 200)
            }

            // Bottom fade + save button
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [ImprintColors.modalBg(isDark).opacity(0), ImprintColors.modalBg(isDark)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)

                VStack {
                    Button {
                        saveRecord()
                        dismiss()
                    } label: {
                        Text(isEditing ? "Save" : "Add Entry")
                            .font(ImprintFonts.jetBrainsMedium(16))
                            .foregroundStyle(ImprintColors.ctaText(isDark))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(canSave ? ImprintColors.ctaFill(isDark) : ImprintColors.ctaFill(isDark).opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(!canSave)
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
                .background(ImprintColors.modalBg(isDark))
            }
            .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(ImprintColors.modalBg(isDark).ignoresSafeArea())
        .onAppear(perform: populateFromExisting)
        .presentationCornerRadius(42)
        .sheet(isPresented: $showingTMDBSearch) {
            TMDBSearchView { selection in
                name = selection.title
                director = selection.director ?? ""
                filmReleaseDate = selection.releaseYear.map(String.init) ?? ""
                country = selection.country ?? country
                tmdbId = String(selection.tmdbId)
                posterPath = selection.posterPath ?? ""
            }
        }
    }

    // MARK: - Media Type Chips

    private var mediaTypeChips: some View {
        HStack(spacing: 8) {
            ForEach(MediaType.allCases) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        mediaType = type
                    }
                } label: {
                    Text(type.label)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(mediaType == type ? ImprintColors.ctaFill(isDark) : ImprintColors.chipInactiveFill(isDark))
                        .foregroundStyle(mediaType == type ? ImprintColors.ctaText(isDark) : ImprintColors.chipInactiveText(isDark))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Record Type Toggle

    private var recordTypeToggle: some View {
        HStack(spacing: 0) {
            ForEach([RecordType.logged, RecordType.queued], id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        recordType = type
                    }
                } label: {
                    Text(type == .logged ? "Log" : "Queue")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(recordType == type ? ImprintColors.ctaText(isDark) : ImprintColors.headingText(isDark))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(recordType == type ? ImprintColors.ctaFill(isDark) : ImprintColors.inputBg(isDark))
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
        )
    }

    // MARK: - Media-Specific Fields

    @ViewBuilder
    private var mediaSpecificFields: some View {
        switch mediaType {
        case .film:
            // TMDB search button
            if TMDBService.shared.isConfigured {
                Button {
                    showingTMDBSearch = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .medium))
                        Text(tmdbId.isEmpty ? "Search TMDB" : "Search again")
                            .font(ImprintFonts.jetBrainsMedium(14))
                    }
                    .foregroundStyle(ImprintColors.filmBold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ImprintColors.filmSubtlest)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(ImprintColors.filmSubtler, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Show selected poster thumbnail
                if !posterPath.isEmpty, let url = TMDBService.posterURL(path: posterPath, size: "w185") {
                    HStack(spacing: 12) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                ImprintColors.inputBg(isDark)
                            }
                        }
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Poster selected")
                                .font(ImprintFonts.formLabel)
                                .foregroundStyle(ImprintColors.secondaryText(isDark))
                            Button {
                                posterPath = ""
                            } label: {
                                Text("Remove")
                                    .font(ImprintFonts.jetBrainsRegular(13))
                                    .foregroundStyle(ImprintColors.required)
                            }
                        }
                    }
                }
            }

            FormField(label: "Director", isDark: isDark) {
                TextField("", text: $director)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
            }
            FormField(label: "Release year", isDark: isDark) {
                TextField("", text: $filmReleaseDate)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
                    .keyboardType(.numberPad)
            }
        case .tv:
            FormField(label: "Creator", isDark: isDark) {
                TextField("", text: $creator)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
            }
            HStack(spacing: 16) {
                FormField(label: "Season", isDark: isDark) {
                    TextField("", text: $season)
                        .font(ImprintFonts.formValue)
                        .foregroundStyle(ImprintColors.modalText(isDark))
                        .keyboardType(.numberPad)
                }
                FormField(label: "Episode", isDark: isDark) {
                    TextField("", text: $episode)
                        .font(ImprintFonts.formValue)
                        .foregroundStyle(ImprintColors.modalText(isDark))
                        .keyboardType(.numberPad)
                }
            }
        case .book:
            FormField(label: "Author", isDark: isDark) {
                TextField("", text: $author)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
            }
            FormField(label: "Publication year", isDark: isDark) {
                TextField("", text: $publicationDate)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
                    .keyboardType(.numberPad)
            }
            FormField(label: "Translator", isDark: isDark) {
                TextField("", text: $translator)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
            }
        case .music:
            FormField(label: "Artist", isDark: isDark) {
                TextField("", text: $artist)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
            }
            FormField(label: "Release year", isDark: isDark) {
                TextField("", text: $musicReleaseDate)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
                    .keyboardType(.numberPad)
            }
        }
    }

    // MARK: - Save

    private func saveRecord() {
        let record = existingRecord ?? Record(
            recordType: recordType,
            mediaType: mediaType,
            name: name.trimmingCharacters(in: .whitespaces)
        )

        record.recordType = recordType
        record.mediaType = mediaType
        record.name = name.trimmingCharacters(in: .whitespaces)
        record.note = note.isEmpty ? nil : note
        record.country = country.isEmpty ? nil : country

        if recordType == .logged {
            record.finishedOn = finishedOn
        } else {
            record.finishedOn = nil
            record.startedOn = nil
        }

        record.director = mediaType == .film ? nilIfEmpty(director) : nil
        record.filmReleaseDate = mediaType == .film ? Int(filmReleaseDate) : nil
        record.tmdbId = mediaType == .film ? Int(tmdbId) : nil
        record.posterPath = mediaType == .film ? nilIfEmpty(posterPath) : nil
        record.creator = mediaType == .tv ? nilIfEmpty(creator) : nil
        record.season = mediaType == .tv ? Int(season) : nil
        record.episode = mediaType == .tv ? Int(episode) : nil
        record.author = mediaType == .book ? nilIfEmpty(author) : nil
        record.publicationDate = mediaType == .book ? Int(publicationDate) : nil
        record.translator = mediaType == .book ? nilIfEmpty(translator) : nil
        record.artist = mediaType == .music ? nilIfEmpty(artist) : nil
        record.musicReleaseDate = mediaType == .music ? Int(musicReleaseDate) : nil

        if existingRecord == nil {
            modelContext.insert(record)
        }
    }

    // MARK: - Populate for Editing

    private func populateFromExisting() {
        guard let record = existingRecord else { return }

        recordType = record.recordType
        mediaType = record.mediaType
        name = record.name
        note = record.note ?? ""
        country = record.country ?? ""

        if let date = record.finishedOn { finishedOn = date }

        director = record.director ?? ""
        filmReleaseDate = record.filmReleaseDate.map(String.init) ?? ""
        tmdbId = record.tmdbId.map(String.init) ?? ""
        posterPath = record.posterPath ?? ""
        creator = record.creator ?? ""
        season = record.season.map(String.init) ?? ""
        episode = record.episode.map(String.init) ?? ""
        author = record.author ?? ""
        publicationDate = record.publicationDate.map(String.init) ?? ""
        translator = record.translator ?? ""
        artist = record.artist ?? ""
        musicReleaseDate = record.musicReleaseDate.map(String.init) ?? ""
    }

    private func formattedDateForField(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    private func nilIfEmpty(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Form Field Component

/// A labeled form field matching the Figma design.
private struct FormField<Content: View>: View {
    let label: String
    var isRequired: Bool = false
    var isDark: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(ImprintFonts.formLabel)
                    .foregroundStyle(ImprintColors.headingText(isDark))

                if isRequired {
                    Spacer()
                    Text("Required")
                        .font(ImprintFonts.formLabel)
                        .foregroundStyle(ImprintColors.required)
                }
            }

            content
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 48)
                .background(ImprintColors.inputBg(isDark))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    RecordFormView()
        .modelContainer(for: Record.self, inMemory: true)
}
