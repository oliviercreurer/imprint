import SwiftUI
import SwiftData

/// A streamlined flow for adding or editing a film via TMDB search.
///
/// Phases:
/// 1. **Search** — type to find a film, tap a result to select it.
/// 2. **Poster** — browse available posters and pick one.
/// 3. **Confirm** — review the selection, optionally set a date and note, then save.
///
/// When editing an existing record, the view starts directly in the confirm phase
/// with all fields pre-populated from the record.
struct AddFilmView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The current record type context (logged vs queued) — used as a starting point.
    var initialRecordType: RecordType = .logged

    /// If set, we're editing an existing record rather than creating a new one.
    var existingRecord: Record?

    /// When true, pre-populates from existingRecord but creates a new entry instead of updating.
    var isRelogging: Bool = false

    // MARK: - Flow State

    enum Phase {
        case search
        case posterPicker
        case confirm
    }

    @State private var phase: Phase = .search

    // MARK: - Search State

    @FocusState private var isSearchFocused: Bool
    @State private var query = ""
    @State private var searchResults: [TMDBMovie] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // MARK: - Selection State

    @State private var selectedMovie: TMDBMovie?
    @State private var movieDetail: TMDBMovieDetail?
    @State private var posters: [TMDBPoster] = []
    @State private var selectedPosterPath: String?
    @State private var isLoadingDetail = false

    // MARK: - Confirm State

    @State private var finishedOn: Date = Date()
    @State private var hasSetDate = false
    @State private var note = ""

    private let service = TMDBService.shared
    private var isEditing: Bool { existingRecord != nil && !isRelogging }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Header
                header

                // Search bar — only shown during search phase
                if phase == .search && !isEditing {
                    searchBar
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }

                // Phase content
                switch phase {
                case .search:
                    searchResultsList
                case .posterPicker:
                    posterPickerContent
                case .confirm:
                    confirmContent
                }
            }
            .background(ImprintColors.paper)

            // Bottom fade + "Use this poster" button
            if phase == .posterPicker && !posters.isEmpty {
                VStack(spacing: 0) {
                    Spacer()

                    LinearGradient(
                        colors: [ImprintColors.paper.opacity(0), ImprintColors.paper],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .allowsHitTesting(false)

                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                phase = .confirm
                            }
                        } label: {
                            Text("Use this poster")
                                .font(ImprintFonts.jetBrainsMedium(16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .background(ImprintColors.paper)
                }
                .ignoresSafeArea(edges: .bottom)
            }

            // Bottom fade + confirm button
            if phase == .confirm {
                VStack(spacing: 0) {
                    Spacer()

                    LinearGradient(
                        colors: [ImprintColors.paper.opacity(0), ImprintColors.paper],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .allowsHitTesting(false)

                    confirmButton
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                        .background(ImprintColors.paper)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 20)),
                        removal: .opacity
                    )
                )
            }
        }
        .keyboardDoneBar()
        .background(ImprintColors.paper.ignoresSafeArea())
        .presentationCornerRadius(42)
        .onAppear {
            populateFromExisting()
            if !isEditing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isSearchFocused = true
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(headerTitle)
                .font(ImprintFonts.modalTitle)
                .foregroundStyle(.black)

            Spacer()

            // Show Back button when navigating phases, but not on the
            // initial phase (search for add, confirm for edit)
            if phase != .search && !(isEditing && phase == .confirm) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        goBack()
                    }
                } label: {
                    Text("Back")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(ImprintColors.searchBorder, lineWidth: 2)
                        )
                }
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 48)
        .padding(.bottom, 16)
    }

    private var headerTitle: String {
        switch phase {
        case .search: return "Add film"
        case .posterPicker: return "Choose a poster"
        case .confirm:
            if isEditing { return "Edit entry" }
            if isRelogging { return "Log again" }
            return "Add film"
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ImprintColors.secondary)

            TextField("Search...", text: $query)
                .font(ImprintFonts.searchPlaceholder)
                .foregroundStyle(ImprintColors.primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .disabled(phase == .confirm)
                .onSubmit { triggerSearch() }

            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }

            if !query.isEmpty && phase == .search {
                Button {
                    query = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ImprintColors.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(ImprintColors.searchBg)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(ImprintColors.searchBorder, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onChange(of: query) { _, newValue in
            if phase == .search { debounceSearch(newValue) }
        }
    }

    // MARK: - Search Results

    private var searchResultsList: some View {
        Group {
            if searchResults.isEmpty && !isSearching && !query.isEmpty {
                Spacer()
                Text("No results")
                    .font(ImprintFonts.jetBrainsRegular(14))
                    .foregroundStyle(ImprintColors.secondary)
                Spacer()
            } else if searchResults.isEmpty && query.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(ImprintColors.secondary)
                    Text("Search for a film")
                        .font(ImprintFonts.jetBrainsRegular(14))
                        .foregroundStyle(ImprintColors.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchResults) { movie in
                            searchResultRow(movie)
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }
        }
    }

    private func searchResultRow(_ movie: TMDBMovie) -> some View {
        Button {
            selectMovie(movie)
        } label: {
            HStack(spacing: 16) {
                // Poster thumbnail
                if let path = movie.posterPath, let url = TMDBService.posterURL(path: path, size: "w92") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            posterPlaceholder
                        default:
                            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: 46, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    posterPlaceholder
                        .frame(width: 46, height: 68)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(.black)
                        .lineLimit(1)

                    if let year = movie.releaseYear {
                        Text(String(year))
                            .font(ImprintFonts.jetBrainsRegular(14))
                            .foregroundStyle(ImprintColors.secondary)
                    }

                    if let overview = movie.overview, !overview.isEmpty {
                        Text(overview)
                            .font(ImprintFonts.jetBrainsRegular(13))
                            .foregroundStyle(ImprintColors.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ImprintColors.secondary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(ImprintColors.filmSubtlest)
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 16))
                    .foregroundStyle(ImprintColors.filmSubtle)
            )
    }

    // MARK: - Poster Picker

    private var posterPickerContent: some View {
        VStack(spacing: 0) {
            if isLoadingDetail {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading posters…")
                        .font(ImprintFonts.jetBrainsRegular(14))
                        .foregroundStyle(ImprintColors.secondary)
                }
                Spacer()
            } else if posters.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundStyle(ImprintColors.secondary)
                    Text("No posters available")
                        .font(ImprintFonts.jetBrainsRegular(14))
                        .foregroundStyle(ImprintColors.secondary)
                }
                Spacer()

                skipPosterButton
            } else {
                // Poster grid
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(posters) { poster in
                            posterCell(poster)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 120)
                }
            }
        }
    }

    private func posterCell(_ poster: TMDBPoster) -> some View {
        let isSelected = selectedPosterPath == poster.filePath

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedPosterPath = poster.filePath
            }
        } label: {
            if let url = TMDBService.posterURL(path: poster.filePath, size: "w342") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(2.0 / 3.0, contentMode: .fit)
                    case .failure:
                        Color(hex: 0xE0E0E0).aspectRatio(2.0 / 3.0, contentMode: .fit)
                    default:
                        ImprintColors.searchBg
                            .aspectRatio(2.0 / 3.0, contentMode: .fit)
                            .overlay(ProgressView().scaleEffect(0.7))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isSelected ? ImprintColors.filmBold : Color.clear,
                            lineWidth: 3
                        )
                )
                .overlay(alignment: .bottomTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white, ImprintColors.filmBold)
                            .padding(6)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var skipPosterButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [ImprintColors.paper.opacity(0), ImprintColors.paper],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)

            VStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        phase = .confirm
                    }
                } label: {
                    Text("Continue without poster")
                        .font(ImprintFonts.jetBrainsMedium(16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
            .background(ImprintColors.paper)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Confirm Phase

    private var confirmContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Film card
                filmCard

                // Finished on
                finishedOnField

                // Note
                noteField
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var filmCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // Poster thumbnail
            if let path = selectedPosterPath, let url = TMDBService.posterURL(path: path, size: "w185") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        ImprintColors.searchBg
                    }
                }
                .frame(width: 78, height: 119)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(ImprintColors.filmSubtlest)
                    .frame(width: 78, height: 119)
                    .overlay(
                        Image(systemName: "film")
                            .font(.system(size: 20))
                            .foregroundStyle(ImprintColors.filmSubtle)
                    )
            }

            // Film info
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedMovie?.title ?? "")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.primary)
                        .lineLimit(1)

                    VStack(alignment: .leading, spacing: 2) {
                        if let director = movieDetail?.director {
                            Text(director)
                                .font(ImprintFonts.jetBrainsMedium(14))
                                .foregroundStyle(ImprintColors.secondary)
                        }

                        HStack(spacing: 0) {
                            if let year = movieDetail?.releaseYear ?? selectedMovie?.releaseYear {
                                Text(String(year))
                            }
                            if let runtime = movieDetail?.runtime, runtime > 0 {
                                Text(" • \(runtime) min")
                            }
                        }
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.searchBorder)
                    }
                }

                Spacer(minLength: 12)

                // Change poster link
                Button {
                    navigateToPosterPicker()
                } label: {
                    Text("Change poster")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.accentBlue)
                        .underline()
                }
            }
            .frame(height: 119)
        }
    }

    private var finishedOnField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Date")
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.secondary)

            ImprintDatePicker(selection: $finishedOn, hasSetDate: $hasSetDate)

            Text("If left blank, this will be added to your queue")
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.secondary)
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Note")
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.secondary)

            TextEditor(text: $note)
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.primary)
                .scrollContentBackground(.hidden)
                .padding(16)
                .frame(minHeight: 268)
                .background(ImprintColors.searchBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(ImprintColors.searchBorder, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            saveRecord()
            dismiss()
        } label: {
            Text(confirmButtonLabel)
                .font(ImprintFonts.jetBrainsMedium(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: hasSetDate)
        }
    }

    private var confirmButtonLabel: String {
        if isEditing {
            // Date state changed from the original → the action is meaningful
            let originalHadDate = existingRecord?.finishedOn != nil
            if hasSetDate && !originalHadDate {
                return "Add to log"
            } else if !hasSetDate && originalHadDate {
                return "Move to queue"
            }
            return "Save changes"
        }
        return hasSetDate ? "Add to log" : "Add to queue"
    }

    // MARK: - Navigation

    private func goBack() {
        switch phase {
        case .confirm:
            if isEditing {
                // In edit mode, there's no going back from confirm — dismiss instead
                dismiss()
            } else {
                phase = .posterPicker
            }
        case .posterPicker:
            if isEditing {
                // In edit mode, poster picker goes back to confirm (not search)
                phase = .confirm
            } else {
                phase = .search
                selectedMovie = nil
                movieDetail = nil
                posters = []
                selectedPosterPath = nil
            }
        case .search:
            break
        }
    }

    /// Opens the poster picker, fetching posters from TMDB if needed.
    private func navigateToPosterPicker() {
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .posterPicker
        }

        // If we don't have posters loaded yet, fetch them from TMDB
        if posters.isEmpty, let movieId = selectedMovie?.id, movieId != 0 {
            isLoadingDetail = true
            Task {
                do {
                    let fetchedPosters = try await service.getMoviePosters(id: movieId)
                    await MainActor.run {
                        posters = fetchedPosters
                        isLoadingDetail = false
                    }
                } catch {
                    await MainActor.run {
                        isLoadingDetail = false
                    }
                }
            }
        }
    }

    // MARK: - Search Logic

    private func debounceSearch(_ query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query)
        }
    }

    private func triggerSearch() {
        searchTask?.cancel()
        searchTask = Task {
            await performSearch(query)
        }
    }

    @MainActor
    private func performSearch(_ query: String) async {
        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await service.searchMovies(query: query)
        } catch {
            searchResults = []
        }
    }

    private func selectMovie(_ movie: TMDBMovie) {
        isSearchFocused = false

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedMovie = movie
            selectedPosterPath = movie.posterPath
            query = movie.title
            phase = .posterPicker
            isLoadingDetail = true
        }

        Task {
            async let detailFetch = service.getMovieDetails(id: movie.id)
            async let postersFetch = service.getMoviePosters(id: movie.id)

            do {
                let (detail, fetchedPosters) = try await (detailFetch, postersFetch)
                await MainActor.run {
                    movieDetail = detail
                    posters = fetchedPosters
                    isLoadingDetail = false
                }
            } catch {
                await MainActor.run {
                    isLoadingDetail = false
                }
            }
        }
    }

    // MARK: - Save

    private func saveRecord() {
        let recordType: RecordType = hasSetDate ? .logged : .queued

        let record: Record
        if let existing = existingRecord, !isRelogging {
            // Editing an existing record — update in place
            record = existing
        } else {
            // New record or re-logging — always create a fresh entry
            let name = selectedMovie?.title ?? existingRecord?.name ?? ""
            guard !name.isEmpty else { return }
            record = Record(
                recordType: recordType,
                mediaType: .film,
                name: name
            )
        }

        record.recordType = recordType

        // Update name from movie if we have one, otherwise keep existing
        if let movie = selectedMovie {
            record.name = movie.title
            record.tmdbId = movie.id
        } else if let existing = existingRecord {
            record.tmdbId = existing.tmdbId
        }

        record.director = movieDetail?.director ?? existingRecord?.director ?? record.director
        record.filmReleaseDate = movieDetail?.releaseYear ?? selectedMovie?.releaseYear ?? existingRecord?.filmReleaseDate ?? record.filmReleaseDate
        record.country = movieDetail?.country ?? existingRecord?.country ?? record.country
        record.posterPath = selectedPosterPath ?? existingRecord?.posterPath

        // TMDB extended metadata
        record.runtime = movieDetail?.runtime ?? existingRecord?.runtime ?? record.runtime
        record.overview = movieDetail?.overview ?? existingRecord?.overview ?? record.overview
        record.genres = movieDetail?.genreList ?? existingRecord?.genres ?? record.genres
        if let cast = movieDetail?.topCast, !cast.isEmpty {
            record.cast = cast.joined(separator: ", ")
        } else if let cast = existingRecord?.cast {
            record.cast = cast
        }

        if hasSetDate {
            record.finishedOn = finishedOn
        } else {
            record.finishedOn = nil
        }

        record.note = note.isEmpty ? nil : note

        if existingRecord == nil || isRelogging {
            modelContext.insert(record)
        }
    }

    // MARK: - Populate for Editing

    private func populateFromExisting() {
        guard let record = existingRecord else { return }

        // Build synthetic TMDB objects from the stored record so the film card renders.
        // We encode/decode via JSON to work with Codable structs that have CodingKeys.
        selectedMovie = syntheticMovie(from: record)
        movieDetail = syntheticDetail(from: record)

        selectedPosterPath = record.posterPath
        query = record.name

        // When relogging, keep date/note fresh for the new entry
        if !isRelogging {
            note = record.note ?? ""

            if let date = record.finishedOn {
                finishedOn = date
                hasSetDate = true
            }
        }

        // Jump straight to the confirm phase
        phase = .confirm
    }

    /// Creates a synthetic TMDBMovie from a Record's stored data.
    private func syntheticMovie(from record: Record) -> TMDBMovie {
        let json: [String: Any?] = [
            "id": record.tmdbId ?? 0,
            "title": record.name,
            "overview": nil,
            "poster_path": record.posterPath,
            "release_date": record.filmReleaseDate.map { "\($0)-01-01" }
        ]
        let data = try! JSONSerialization.data(withJSONObject: json.compactMapValues { $0 })
        return try! JSONDecoder().decode(TMDBMovie.self, from: data)
    }

    /// Creates a synthetic TMDBMovieDetail from a Record's stored data.
    private func syntheticDetail(from record: Record) -> TMDBMovieDetail {
        var json: [String: Any] = [
            "id": record.tmdbId ?? 0,
            "title": record.name
        ]
        if let year = record.filmReleaseDate {
            json["release_date"] = "\(year)-01-01"
        }
        if let runtime = record.runtime {
            json["runtime"] = runtime
        }
        if let overview = record.overview {
            json["overview"] = overview
        }

        // Build credits with director + cast
        var crew: [[String: Any]] = []
        if let director = record.director {
            crew.append(["name": director, "job": "Director"])
        }
        var castArray: [[String: Any]] = []
        if let castStr = record.cast {
            for (index, name) in castStr.components(separatedBy: ", ").enumerated() {
                castArray.append(["id": index, "name": name, "order": index])
            }
        }
        json["credits"] = ["crew": crew, "cast": castArray]

        if let country = record.country {
            json["production_countries"] = [["name": country]]
        }
        if let genres = record.genres {
            json["genres"] = genres.components(separatedBy: ", ").enumerated().map { (i, name) in
                ["id": i, "name": name] as [String: Any]
            }
        }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(TMDBMovieDetail.self, from: data)
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}
