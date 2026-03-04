import SwiftUI
import SwiftData

/// A streamlined flow for adding or editing a TV show via TMDB search.
///
/// Phases:
/// 1. **Search** — type to find a show, tap a result to select it.
/// 2. **Poster** — browse available posters and pick one.
/// 3. **Confirm** — review the selection, optionally set a date, season/episode, and note, then save.
///
/// When editing an existing record, the view starts directly in the confirm phase
/// with all fields pre-populated from the record.
struct AddTVView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("appearanceMode") private var appearanceMode = "light"
    private var isDark: Bool { appearanceMode == "dark" }

    /// The current record type context (logged vs queued).
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
    @State private var searchResults: [TMDBTVShow] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // MARK: - Selection State

    @State private var selectedShow: TMDBTVShow?
    @State private var showDetail: TMDBTVDetail?
    @State private var posters: [TMDBPoster] = []
    @State private var selectedPosterPath: String?
    @State private var isLoadingDetail = false

    // MARK: - Confirm State

    @State private var finishedOn: Date = Date()
    @State private var hasSetDate = false
    @State private var note = ""

    // MARK: - Episode Repeater State

    /// Each row in the repeater (season + episode as strings for input binding).
    struct EpisodeRow: Identifiable {
        let id = UUID()
        var season: String = ""
        var episode: String = ""
    }

    @State private var episodeRows: [EpisodeRow] = [EpisodeRow()]
    @State private var episodeDetails: [UUID: TMDBEpisodeDetail] = [:]
    @State private var episodeFetchTasks: [UUID: Task<Void, Never>] = [:]

    private let service = TMDBService.shared
    private var isEditing: Bool { existingRecord != nil && !isRelogging }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                header

                if phase == .search && !isEditing {
                    searchBar
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }

                switch phase {
                case .search:
                    searchResultsList
                case .posterPicker:
                    posterPickerContent
                case .confirm:
                    confirmContent
                }
            }
            .background(ImprintColors.modalBg(isDark))

            // Bottom fade + "Use this poster" button
            if phase == .posterPicker && !posters.isEmpty {
                VStack(spacing: 0) {
                    Spacer()

                    LinearGradient(
                        colors: [ImprintColors.modalBg(isDark).opacity(0), ImprintColors.modalBg(isDark)],
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
                                .foregroundStyle(ImprintColors.ctaText(isDark))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(ImprintColors.ctaFill(isDark))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .background(ImprintColors.modalBg(isDark))
                }
                .ignoresSafeArea(edges: .bottom)
            }

            if phase == .confirm {
                VStack(spacing: 0) {
                    Spacer()

                    LinearGradient(
                        colors: [ImprintColors.modalBg(isDark).opacity(0), ImprintColors.modalBg(isDark)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .allowsHitTesting(false)

                    confirmButton
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                        .background(ImprintColors.modalBg(isDark))
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
        .background(ImprintColors.modalBg(isDark).ignoresSafeArea())
        .presentationCornerRadius(42)
        .onAppear {
            populateFromExisting()
            if !isEditing {
                // Small delay lets the sheet finish presenting before pulling up the keyboard
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
                .foregroundStyle(ImprintColors.headingText(isDark))

            Spacer()

            if phase != .search && !(isEditing && phase == .confirm) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        goBack()
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

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ImprintColors.headingText(isDark))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 48)
        .padding(.bottom, 16)
    }

    private var headerTitle: String {
        switch phase {
        case .search: return "Add show"
        case .posterPicker: return "Choose a poster"
        case .confirm:
            if isEditing { return "Edit entry" }
            if isRelogging { return "Log again" }
            return "Add show"
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ImprintColors.secondaryText(isDark))

            TextField("Search...", text: $query)
                .font(ImprintFonts.searchPlaceholder)
                .foregroundStyle(ImprintColors.modalText(isDark))
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
                        .foregroundStyle(ImprintColors.secondaryText(isDark))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(ImprintColors.inputBg(isDark))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
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
                    .foregroundStyle(ImprintColors.secondaryText(isDark))
                Spacer()
            } else if searchResults.isEmpty && query.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(ImprintColors.secondaryText(isDark))
                    Text("Search for a show")
                        .font(ImprintFonts.jetBrainsRegular(14))
                        .foregroundStyle(ImprintColors.secondaryText(isDark))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchResults) { show in
                            searchResultRow(show)
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }
        }
    }

    private func searchResultRow(_ show: TMDBTVShow) -> some View {
        Button {
            selectShow(show)
        } label: {
            HStack(spacing: 16) {
                if let path = show.posterPath, let url = TMDBService.posterURL(path: path, size: "w92") {
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
                    Text(show.name)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.headingText(isDark))
                        .lineLimit(1)

                    if let year = show.firstAirYear {
                        Text(String(year))
                            .font(ImprintFonts.jetBrainsRegular(14))
                            .foregroundStyle(ImprintColors.secondaryText(isDark))
                    }

                    if let overview = show.overview, !overview.isEmpty {
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
            .fill(ImprintColors.tvSubtler.opacity(0.3))
            .overlay(
                Image(systemName: "tv")
                    .font(.system(size: 16))
                    .foregroundStyle(ImprintColors.tvSubtle)
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

                skipPosterButton
            } else {
                // Show info summary
                if let show = selectedShow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(show.name)
                            .font(ImprintFonts.jetBrainsMedium(16))
                            .foregroundStyle(ImprintColors.headingText(isDark))

                        HStack(spacing: 8) {
                            if let year = showDetail?.firstAirYear ?? show.firstAirYear {
                                Text(String(year))
                                    .font(ImprintFonts.jetBrainsRegular(14))
                                    .foregroundStyle(ImprintColors.secondaryText(isDark))
                            }
                            if let creator = showDetail?.creatorName {
                                Text(creator)
                                    .font(ImprintFonts.jetBrainsRegular(14))
                                    .foregroundStyle(ImprintColors.secondaryText(isDark))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                }

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
                        ImprintColors.inputBg(isDark)
                            .aspectRatio(2.0 / 3.0, contentMode: .fit)
                            .overlay(ProgressView().scaleEffect(0.7))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isSelected ? ImprintColors.tvBold : Color.clear,
                            lineWidth: 3
                        )
                )
                .overlay(alignment: .bottomTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white, ImprintColors.tvBold)
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
                colors: [ImprintColors.modalBg(isDark).opacity(0), ImprintColors.modalBg(isDark)],
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

    // MARK: - Confirm Phase

    private var confirmContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                showCard

                finishedOnField

                // Episode rows — only revealed after a date is selected
                if hasSetDate {
                    episodeRowsSection
                        .transition(.opacity.combined(with: .offset(y: -8)))
                }

                noteField
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .padding(.bottom, 120)
            .animation(.easeInOut(duration: 0.25), value: hasSetDate)
        }
        .scrollIndicators(.hidden)
    }

    private var showCard: some View {
        HStack(alignment: .top, spacing: 16) {
            if let path = selectedPosterPath, let url = TMDBService.posterURL(path: path, size: "w185") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        ImprintColors.inputBg(isDark)
                    }
                }
                .frame(width: 78, height: 119)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(ImprintColors.tvSubtler.opacity(0.3))
                    .frame(width: 78, height: 119)
                    .overlay(
                        Image(systemName: "tv")
                            .font(.system(size: 20))
                            .foregroundStyle(ImprintColors.tvSubtle)
                    )
            }

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedShow?.name ?? "")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.modalText(isDark))
                        .lineLimit(1)

                    VStack(alignment: .leading, spacing: 2) {
                        if let creator = showDetail?.creatorList {
                            Text(creator)
                                .font(ImprintFonts.jetBrainsMedium(14))
                                .foregroundStyle(ImprintColors.secondaryText(isDark))
                        }

                        HStack(spacing: 0) {
                            if let year = showDetail?.firstAirYear ?? selectedShow?.firstAirYear {
                                Text(String(year))
                            }
                            if let country = showDetail?.country {
                                Text(" • \(country)")
                            }
                        }
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.tertiaryText(isDark))
                    }
                }

                Spacer(minLength: 12)

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
                .foregroundStyle(ImprintColors.secondaryText(isDark))

            ImprintDatePicker(selection: $finishedOn, hasSetDate: $hasSetDate)

            Text("If left blank, this will be added to your queue")
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.secondaryText(isDark))
        }
    }

    /// Season picker — uses TMDB metadata when available.
    // MARK: - Episode Repeater

    private var episodeRowsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(episodeRows.enumerated()), id: \.element.id) { index, row in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom, spacing: 8) {
                        episodePickerRow(at: index)

                        // Always reserve space for delete button to maintain grid
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                let removed = episodeRows.remove(at: index)
                                episodeDetails.removeValue(forKey: removed.id)
                                episodeFetchTasks[removed.id]?.cancel()
                                episodeFetchTasks.removeValue(forKey: removed.id)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(ImprintColors.secondaryText(isDark))
                                .frame(height: 48)
                        }
                        .buttonStyle(.plain)
                        .opacity(index > 0 ? 1 : 0)
                        .allowsHitTesting(index > 0)
                    }

                    // Episode title preview
                    if let detail = episodeDetails[row.id] {
                        Text(detail.name)
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(ImprintColors.secondaryText(isDark))
                            .transition(.opacity)
                    }
                }
            }

            // Add episode button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    let newRow: EpisodeRow
                    if let last = episodeRows.last,
                       let lastSeason = Int(last.season),
                       let lastEp = Int(last.episode) {
                        // Auto-increment: same season, next episode
                        newRow = EpisodeRow(season: String(lastSeason), episode: String(lastEp + 1))
                    } else {
                        newRow = EpisodeRow()
                    }
                    episodeRows.append(newRow)
                    fetchEpisodeDetail(at: episodeRows.count - 1)
                }
            } label: {
                Text("Add episode")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(ImprintColors.accentBlue)
            }
            .buttonStyle(.plain)
        }
    }

    private func episodePickerRow(at index: Int) -> some View {
        let seasons = showDetail?.numberedSeasons ?? []
        let hasMetadata = !seasons.isEmpty
        let rowSeason = episodeRows[index].season
        let selectedSeasonMeta = seasons.first(where: { $0.seasonNumber == Int(rowSeason) })

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                if index == 0 {
                    Text("Season")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.secondaryText(isDark))
                }

                if hasMetadata {
                    Menu {
                        ForEach(seasons) { s in
                            Button {
                                episodeRows[index].season = String(s.seasonNumber)
                                episodeRows[index].episode = ""
                                episodeDetails.removeValue(forKey: episodeRows[index].id)
                            } label: {
                                Text("Season \(s.seasonNumber)")
                            }
                        }
                    } label: {
                        seasonEpisodeButton(
                            text: rowSeason.isEmpty ? "–" : "S\(String(format: "%02d", Int(rowSeason) ?? 0))"
                        )
                    }
                } else {
                    TextField("", text: $episodeRows[index].season)
                        .font(ImprintFonts.formValue)
                        .foregroundStyle(ImprintColors.modalText(isDark))
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(ImprintColors.inputBg(isDark))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onChange(of: episodeRows[index].season) { _, _ in
                            episodeRows[index].episode = ""
                            episodeDetails.removeValue(forKey: episodeRows[index].id)
                        }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                if index == 0 {
                    Text("Episode")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.secondaryText(isDark))
                }

                if hasMetadata, let meta = selectedSeasonMeta {
                    Menu {
                        ForEach(1...max(1, meta.episodeCount), id: \.self) { ep in
                            Button {
                                episodeRows[index].episode = String(ep)
                                fetchEpisodeDetail(at: index)
                            } label: {
                                Text("Episode \(ep)")
                            }
                        }
                    } label: {
                        seasonEpisodeButton(
                            text: episodeRows[index].episode.isEmpty ? "–" : "E\(String(format: "%02d", Int(episodeRows[index].episode) ?? 0))"
                        )
                    }
                } else {
                    TextField("", text: $episodeRows[index].episode)
                        .font(ImprintFonts.formValue)
                        .foregroundStyle(ImprintColors.modalText(isDark))
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(ImprintColors.inputBg(isDark))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onChange(of: episodeRows[index].episode) { _, _ in
                            fetchEpisodeDetail(at: index)
                        }
                }
            }
        }
    }

    private func episodePreview(_ ep: TMDBEpisodeDetail) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(ep.name) (S\(String(format: "%02d", ep.seasonNumber)).E\(String(format: "%02d", ep.episodeNumber)))")
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.secondaryText(isDark))
            if let dir = ep.director {
                Text("Dir. \(dir)")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(ImprintColors.secondaryText(isDark))
            }
            let metaParts: [String] = {
                var items: [String] = []
                if let y = ep.airYear { items.append(String(y)) }
                if let r = ep.runtime { items.append("\(r) mins") }
                return items
            }()
            if !metaParts.isEmpty {
                Text(metaParts.joined(separator: " • "))
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(ImprintColors.tertiaryText(isDark))
            }
        }
        .transition(.opacity)
    }

    private func seasonEpisodeButton(text: String) -> some View {
        HStack {
            Text(text)
                .font(ImprintFonts.formValue)
                .foregroundStyle(text == "–" ? ImprintColors.secondaryText(isDark) : ImprintColors.modalText(isDark))
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ImprintColors.secondaryText(isDark))
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(ImprintColors.inputBg(isDark))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Note")
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.secondaryText(isDark))

            TextEditor(text: $note)
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.modalText(isDark))
                .scrollContentBackground(.hidden)
                .padding(16)
                .frame(minHeight: 268)
                .background(ImprintColors.inputBg(isDark))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
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
                .foregroundStyle(ImprintColors.ctaText(isDark))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(ImprintColors.ctaFill(isDark))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: hasSetDate)
        }
    }

    private var confirmButtonLabel: String {
        if isEditing {
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
                dismiss()
            } else {
                phase = .posterPicker
            }
        case .posterPicker:
            if isEditing {
                phase = .confirm
            } else {
                phase = .search
                selectedShow = nil
                showDetail = nil
                posters = []
                selectedPosterPath = nil
            }
        case .search:
            break
        }
    }

    private func navigateToPosterPicker() {
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .posterPicker
        }

        if posters.isEmpty, let showId = selectedShow?.id, showId != 0 {
            isLoadingDetail = true
            Task {
                do {
                    let fetchedPosters = try await service.getTVPosters(id: showId)
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
            searchResults = try await service.searchTV(query: query)
        } catch {
            print("❌ TV search failed: \(error)")
            searchResults = []
        }
    }

    private func selectShow(_ show: TMDBTVShow) {
        isSearchFocused = false

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedShow = show
            selectedPosterPath = show.posterPath
            query = show.name
            phase = .posterPicker
            isLoadingDetail = true
        }

        Task {
            async let detailFetch = service.getTVDetails(id: show.id)
            async let postersFetch = service.getTVPosters(id: show.id)

            do {
                let (detail, fetchedPosters) = try await (detailFetch, postersFetch)
                await MainActor.run {
                    showDetail = detail
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

    // MARK: - Episode Fetch

    private func fetchEpisodeDetail(at index: Int) {
        guard index < episodeRows.count else { return }
        let row = episodeRows[index]

        episodeFetchTasks[row.id]?.cancel()

        guard let s = Int(row.season), let e = Int(row.episode),
              let showId = selectedShow?.id, showId != 0 else {
            episodeDetails.removeValue(forKey: row.id)
            return
        }

        let rowId = row.id
        episodeFetchTasks[rowId] = Task {
            do {
                let detail = try await service.getEpisodeDetails(showId: showId, season: s, episode: e)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        episodeDetails[rowId] = detail
                    }
                }
            } catch {
                print("❌ Episode detail fetch failed: \(error)")
                await MainActor.run { episodeDetails.removeValue(forKey: rowId) }
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
            let name = selectedShow?.name ?? existingRecord?.name ?? ""
            guard !name.isEmpty else { return }
            record = Record(
                recordType: recordType,
                mediaType: .tv,
                name: name
            )
        }

        record.recordType = recordType

        if let show = selectedShow {
            record.name = show.name
            record.tmdbId = show.id
        } else if let existing = existingRecord {
            record.tmdbId = existing.tmdbId
        }

        record.creator = showDetail?.creatorList ?? existingRecord?.creator ?? record.creator
        record.country = showDetail?.country ?? existingRecord?.country ?? record.country
        record.tvReleaseYear = showDetail?.firstAirYear ?? selectedShow?.firstAirYear ?? existingRecord?.tvReleaseYear ?? record.tvReleaseYear
        record.numberOfSeasons = showDetail?.numberOfSeasons ?? existingRecord?.numberOfSeasons ?? record.numberOfSeasons
        record.posterPath = selectedPosterPath ?? existingRecord?.posterPath

        // TMDB extended metadata
        record.overview = showDetail?.overview ?? existingRecord?.overview ?? record.overview
        record.genres = showDetail?.genreList ?? existingRecord?.genres ?? record.genres
        if let cast = showDetail?.topCast, !cast.isEmpty {
            record.cast = cast.joined(separator: ", ")
        } else if let cast = existingRecord?.cast {
            record.cast = cast
        }

        if hasSetDate {
            record.finishedOn = finishedOn

            // Build WatchedEpisode array from rows
            let watched: [WatchedEpisode] = episodeRows.compactMap { row in
                guard let s = Int(row.season), let e = Int(row.episode) else { return nil }
                let detail = episodeDetails[row.id]
                return WatchedEpisode(
                    season: s,
                    episode: e,
                    episodeName: detail?.name,
                    episodeDirector: detail?.director,
                    episodeAirYear: detail?.airYear,
                    episodeRuntime: detail?.runtime
                )
            }

            // Encode as JSON
            if !watched.isEmpty,
               let data = try? JSONEncoder().encode(watched),
               let jsonStr = String(data: data, encoding: .utf8) {
                record.episodesJSON = jsonStr
            }

            // Backward compat: mirror first episode into flat fields
            if let first = watched.first {
                record.season = first.season
                record.episode = first.episode
                record.episodeName = first.episodeName
                record.episodeDirector = first.episodeDirector
                record.episodeAirYear = first.episodeAirYear
                record.episodeRuntime = first.episodeRuntime
            }
        } else {
            record.finishedOn = nil
            record.episodesJSON = nil
            record.season = nil
            record.episode = nil
            record.episodeName = nil
            record.episodeDirector = nil
            record.episodeAirYear = nil
            record.episodeRuntime = nil
        }

        record.note = note.isEmpty ? nil : note

        if existingRecord == nil || isRelogging {
            modelContext.insert(record)
        }
    }

    // MARK: - Populate for Editing

    private func populateFromExisting() {
        guard let record = existingRecord else { return }

        selectedShow = syntheticShow(from: record)
        showDetail = syntheticDetail(from: record)

        selectedPosterPath = record.posterPath
        query = record.name

        // Re-fetch full TMDB detail so season/episode dropdowns work
        if let tmdbId = record.tmdbId, tmdbId != 0 {
            Task {
                do {
                    let detail = try await service.getTVDetails(id: tmdbId)
                    await MainActor.run {
                        showDetail = detail
                    }
                } catch {
                    // Keep synthetic detail as fallback — text inputs still work
                }
            }
        }

        // When relogging, keep date/note/episodes fresh for the new entry
        if !isRelogging {
            note = record.note ?? ""

            if let date = record.finishedOn {
                finishedOn = date
                hasSetDate = true
            }

            // Restore episode rows from watchedEpisodes
            let episodes = record.watchedEpisodes
            if !episodes.isEmpty {
                episodeRows = episodes.map { ep in
                    EpisodeRow(season: String(ep.season), episode: String(ep.episode))
                }

                // Synthesize TMDBEpisodeDetail for each row so the preview renders
                for (index, ep) in episodes.enumerated() {
                    let rowId = episodeRows[index].id
                    var json: [String: Any] = [
                        "id": 0,
                        "name": ep.episodeName ?? "",
                        "season_number": ep.season,
                        "episode_number": ep.episode
                    ]
                    if let runtime = ep.episodeRuntime { json["runtime"] = runtime }
                    if let year = ep.episodeAirYear { json["air_date"] = "\(year)-01-01" }
                    if let dir = ep.episodeDirector {
                        json["crew"] = [["name": dir, "job": "Director"]]
                    }
                    if ep.episodeName != nil,
                       let data = try? JSONSerialization.data(withJSONObject: json),
                       let detail = try? JSONDecoder().decode(TMDBEpisodeDetail.self, from: data) {
                        episodeDetails[rowId] = detail
                    } else {
                        // No cached metadata — try fetching from TMDB
                        fetchEpisodeDetail(at: index)
                    }
                }
            }
        }

        phase = .confirm
    }

    private func syntheticShow(from record: Record) -> TMDBTVShow {
        let json: [String: Any?] = [
            "id": record.tmdbId ?? 0,
            "name": record.name,
            "overview": nil,
            "poster_path": record.posterPath,
            "first_air_date": nil
        ]
        let data = try! JSONSerialization.data(withJSONObject: json.compactMapValues { $0 })
        return try! JSONDecoder().decode(TMDBTVShow.self, from: data)
    }

    private func syntheticDetail(from record: Record) -> TMDBTVDetail {
        var json: [String: Any] = [
            "id": record.tmdbId ?? 0,
            "name": record.name
        ]
        if let overview = record.overview {
            json["overview"] = overview
        }

        var createdBy: [[String: Any]] = []
        if let creator = record.creator {
            for (index, name) in creator.components(separatedBy: ", ").enumerated() {
                createdBy.append(["id": index, "name": name])
            }
        }
        json["created_by"] = createdBy

        var castArray: [[String: Any]] = []
        if let castStr = record.cast {
            for (index, name) in castStr.components(separatedBy: ", ").enumerated() {
                castArray.append(["id": index, "name": name, "order": index])
            }
        }
        json["credits"] = ["crew": [] as [[String: Any]], "cast": castArray]

        if let country = record.country {
            json["production_countries"] = [["name": country]]
        }
        if let genres = record.genres {
            json["genres"] = genres.components(separatedBy: ", ").enumerated().map { (i, name) in
                ["id": i, "name": name] as [String: Any]
            }
        }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(TMDBTVDetail.self, from: data)
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}
