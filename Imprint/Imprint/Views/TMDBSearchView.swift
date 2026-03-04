import SwiftUI

/// The data returned when a user selects a film from TMDB search.
struct TMDBSelection {
    let tmdbId: Int
    let title: String
    let director: String?
    let releaseYear: Int?
    let country: String?
    let posterPath: String?
}

/// A full-screen search view for finding films on TMDB.
///
/// Flow: search → pick a result → browse posters → confirm selection.
struct TMDBSearchView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    private var isDark: Bool { appearanceMode == "dark" }

    /// Called when the user confirms a film selection.
    var onSelect: (TMDBSelection) -> Void

    // MARK: - State

    @State private var query = ""
    @State private var searchResults: [TMDBMovie] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // Detail / poster selection
    @State private var selectedMovie: TMDBMovie?
    @State private var movieDetail: TMDBMovieDetail?
    @State private var posters: [TMDBPoster] = []
    @State private var selectedPosterPath: String?
    @State private var isLoadingDetail = false

    private let service = TMDBService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            if let movie = selectedMovie {
                // Poster picker phase
                posterPickerView(for: movie)
            } else {
                // Search phase
                searchPhase
            }
        }
        .background(ImprintColors.modalBg(isDark).ignoresSafeArea())
        .presentationCornerRadius(42)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(selectedMovie != nil ? "Choose a poster" : "Search TMDB")
                .font(ImprintFonts.modalTitle)
                .foregroundStyle(ImprintColors.headingText(isDark))

            Spacer()

            if selectedMovie != nil {
                // Back to results
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedMovie = nil
                        movieDetail = nil
                        posters = []
                        selectedPosterPath = nil
                    }
                } label: {
                    Text("Back")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.headingText(isDark))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
                        )
                }
            }

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
    }

    // MARK: - Search Phase

    private var searchPhase: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ImprintColors.secondaryText(isDark))

                TextField("Film title…", text: $query)
                    .font(ImprintFonts.formValue)
                    .foregroundStyle(ImprintColors.modalText(isDark))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { triggerSearch() }

                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                if !query.isEmpty {
                    Button {
                        query = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(ImprintColors.secondaryText(isDark))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(ImprintColors.inputBg(isDark))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 32)
            .padding(.bottom, 16)

            // Results
            if searchResults.isEmpty && !isSearching && !query.isEmpty {
                Spacer()
                Text("No results")
                    .font(ImprintFonts.jetBrainsRegular(14))
                    .foregroundStyle(ImprintColors.secondaryText(isDark))
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
        .onChange(of: query) { _, newValue in
            debounceSearch(newValue)
        }
    }

    // MARK: - Search Result Row

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
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            posterPlaceholder
                        default:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: 46, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    posterPlaceholder
                        .frame(width: 46, height: 68)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                // Title + year + overview
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.headingText(isDark))
                        .lineLimit(1)

                    if let year = movie.releaseYear {
                        Text(String(year))
                            .font(ImprintFonts.jetBrainsRegular(14))
                            .foregroundStyle(ImprintColors.secondaryText(isDark))
                    }

                    if let overview = movie.overview, !overview.isEmpty {
                        Text(overview)
                            .font(ImprintFonts.jetBrainsRegular(13))
                            .foregroundStyle(ImprintColors.secondaryText(isDark))
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ImprintColors.secondaryText(isDark))
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

    private func posterPickerView(for movie: TMDBMovie) -> some View {
        VStack(spacing: 0) {
            if isLoadingDetail {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading posters…")
                        .font(ImprintFonts.jetBrainsRegular(14))
                        .foregroundStyle(ImprintColors.secondaryText(isDark))
                }
                Spacer()
            } else if posters.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundStyle(ImprintColors.secondaryText(isDark))
                    Text("No posters available")
                        .font(ImprintFonts.jetBrainsRegular(14))
                        .foregroundStyle(ImprintColors.secondaryText(isDark))
                }
                Spacer()

                // Still allow confirming without a poster
                confirmButton(for: movie)
            } else {
                // Movie info summary
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(ImprintFonts.jetBrainsMedium(16))
                        .foregroundStyle(ImprintColors.headingText(isDark))

                    HStack(spacing: 8) {
                        if let year = movieDetail?.releaseYear ?? movie.releaseYear {
                            Text(String(year))
                                .font(ImprintFonts.jetBrainsRegular(14))
                                .foregroundStyle(ImprintColors.secondaryText(isDark))
                        }
                        if let director = movieDetail?.director {
                            Text("dir. \(director)")
                                .font(ImprintFonts.jetBrainsRegular(14))
                                .foregroundStyle(ImprintColors.secondaryText(isDark))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)

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

                confirmButton(for: movie)
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
                        image
                            .resizable()
                            .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    case .failure:
                        ImprintColors.failureBg(isDark)
                            .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    default:
                        ImprintColors.inputBg(isDark)
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

    private func confirmButton(for movie: TMDBMovie) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [ImprintColors.modalBg(isDark).opacity(0), ImprintColors.modalBg(isDark)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)

            VStack {
                Button {
                    confirmSelection(for: movie)
                } label: {
                    Text("Use this film")
                        .font(ImprintFonts.jetBrainsMedium(16))
                        .foregroundStyle(ImprintColors.ctaText(isDark))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(ImprintColors.ctaFill(isDark))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
            .background(ImprintColors.modalBg(isDark))
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Actions

    private func debounceSearch(_ query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
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
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedMovie = movie
            selectedPosterPath = movie.posterPath
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

    private func confirmSelection(for movie: TMDBMovie) {
        let selection = TMDBSelection(
            tmdbId: movie.id,
            title: movie.title,
            director: movieDetail?.director,
            releaseYear: movieDetail?.releaseYear ?? movie.releaseYear,
            country: movieDetail?.country,
            posterPath: selectedPosterPath ?? movie.posterPath
        )
        onSelect(selection)
        dismiss()
    }
}
