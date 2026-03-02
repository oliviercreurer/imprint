import SwiftUI
import SwiftData

/// Shows full details for a single record as a panel overlay.
///
/// Films and books get a centered layout with cover hero, metadata, and Note/Details tabs.
/// Other media types keep the original left-aligned layout.
struct RecordDetailView: View {

    @Bindable var record: Record
    @Environment(\.dismiss) private var dismiss

    // Pager-driven animation params (neutral defaults for standalone use)
    var topBarAnimOffset: CGFloat = 0
    var topBarAnimOpacity: Double = 1
    var contentAnimOffset: CGFloat = 0
    var contentAnimOpacity: Double = 1

    // Navigation between entries (set by RecordDetailPager)
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var onGoBack: (() -> Void)? = nil
    var onGoForward: (() -> Void)? = nil

    /// Called when an edit moves a queued item to the log, passing the record name.
    var onMovedToLog: ((String) -> Void)? = nil

    /// Derives dark mode from the record's current type so the view
    /// reacts live when an entry moves between queue and log.
    private var isDark: Bool { record.recordType == .queued }

    @State private var showingEditSheet = false
    @State private var showingLogAgainSheet = false
    /// Tracks the record type before the edit sheet opens.
    @State private var typeBeforeEdit: RecordType?
    @State private var selectedTab: DetailTab = .note

    enum DetailTab: String, CaseIterable {
        case note = "Note"
        case details = "Details"
    }

    // Theme-aware colors
    private var bgColor: Color { isDark ? ImprintColors.primary : ImprintColors.paper }
    private var textColor: Color { isDark ? ImprintColors.paper : .black }
    private var secondaryTextColor: Color { isDark ? ImprintColors.darkSecondary : ImprintColors.secondary }
    private var tertiaryTextColor: Color { isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder }
    private var buttonBorderColor: Color { isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Pinned top bar
                topBar
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
                    .padding(.bottom, 12)
                    .background(bgColor)
                    .zIndex(1)

                // Separator
                Rectangle()
                    .fill(tertiaryTextColor.opacity(0.5))
                    .frame(height: 1)
                    .zIndex(1)

                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        if record.mediaType == .film {
                            filmDetailContent
                        } else if record.mediaType == .tv {
                            tvDetailContent
                        } else if record.mediaType == .book {
                            bookDetailContent
                        } else {
                            genericDetailContent
                        }
                    }
                    .padding(.top, 48)
                    .padding(.bottom, 200)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
                .offset(x: contentAnimOffset)
                .opacity(contentAnimOpacity)
            }

            // Bottom fade
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    colors: [bgColor.opacity(0), bgColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)

                bgColor
                    .frame(height: 80)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)

            // Floating bottom bar — nav buttons left, action buttons right
            HStack {
                // Navigation arrows — bottom-left
                if canGoBack || canGoForward {
                    navButtons
                }

                Spacer()

                // Edit / Log again — bottom-right
                actionButtons
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)
        }
        .background(bgColor.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: record.recordTypeRaw)
        .onChange(of: record.recordTypeRaw) { oldValue, newValue in
            // Detect queue → log transition while editing — dismiss immediately
            // so the edit sheet and detail cover drop together.
            if typeBeforeEdit == .queued,
               RecordType(rawValue: newValue) == .logged {
                typeBeforeEdit = nil
                onMovedToLog?(record.name)
            }
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            typeBeforeEdit = nil
        }) {
            if record.mediaType == .film {
                AddFilmView(
                    initialRecordType: record.recordType,
                    existingRecord: record
                )
            } else if record.mediaType == .tv {
                AddTVView(
                    initialRecordType: record.recordType,
                    existingRecord: record
                )
            } else if record.mediaType == .book {
                AddBookView(
                    initialRecordType: record.recordType,
                    existingRecord: record
                )
            } else {
                RecordFormView(existingRecord: record)
            }
        }
        .sheet(isPresented: $showingLogAgainSheet) {
            if record.mediaType == .film {
                AddFilmView(
                    initialRecordType: .logged,
                    existingRecord: record,
                    isRelogging: true
                )
            } else if record.mediaType == .tv {
                AddTVView(
                    initialRecordType: .logged,
                    existingRecord: record,
                    isRelogging: true
                )
            } else if record.mediaType == .book {
                AddBookView(
                    initialRecordType: .logged,
                    existingRecord: record,
                    isRelogging: true
                )
            } else {
                RecordFormView(existingRecord: record)
            }
        }
        .transition(.move(edge: .bottom))
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 8) {
            // Tag + date — animated during swipe transitions
            HStack(spacing: 8) {
                // Media type chip — bold active state
                Text(record.mediaType.label)
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isDark ? record.mediaType.queueLegendFill : record.mediaType.boldColor)
                    .foregroundStyle(isDark ? record.mediaType.darkBoldColor : ImprintColors.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                // Date
                if let date = record.finishedOn {
                    Text(formattedDate(date))
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(secondaryTextColor)
                }
            }
            .offset(x: topBarAnimOffset)
            .opacity(topBarAnimOpacity)

            Spacer()

            // Close button — stays stationary as a stable anchor
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(buttonBorderColor, lineWidth: 2)
                    )
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navButtons: some View {
        HStack(spacing: 8) {
            Button {
                onGoBack?()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(canGoBack ? textColor : tertiaryTextColor)
                    .frame(width: 48, height: 48)
                    .background(bgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(buttonBorderColor, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)

            Button {
                onGoForward?()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(canGoForward ? textColor : tertiaryTextColor)
                    .frame(width: 48, height: 48)
                    .background(bgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(buttonBorderColor, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
    }

    // MARK: - Floating Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Log again — only for logged entries, not queue items
            if record.recordType == .logged {
                Button {
                    showingLogAgainSheet = true
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(ImprintColors.actionLogAgain)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            // Edit
            Button {
                typeBeforeEdit = record.recordType
                showingEditSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(ImprintColors.actionEdit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Film Detail (Centered Layout + Tabs)

    private var filmDetailContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            filmHero
                .padding(.horizontal, 32)
            detailTabBar
            Group {
                switch selectedTab {
                case .note:
                    noteTabContent
                case .details:
                    filmDetailsContent
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var filmHero: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Poster — shrinks and fades as you scroll up via .visualEffect
            if let path = record.posterPath,
               let url = TMDBService.posterURL(path: path, size: "w500") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    case .failure:
                        EmptyView()
                    default:
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ImprintColors.searchBg)
                            .aspectRatio(2.0 / 3.0, contentMode: .fit)
                            .overlay(ProgressView())
                    }
                }
                .frame(height: 260)
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                .visualEffect { content, proxy in
                    let minY = proxy.frame(in: .named("scroll")).minY
                    let scrolled = max(0, 48 - minY)
                    let progress = min(1, scrolled / 220)
                    return content
                        .scaleEffect(1 - progress * 0.4)
                        .opacity(1 - progress)
                }
            }

            // Title + metadata
            VStack(alignment: .leading, spacing: 16) {
                Text(record.name)
                    .font(ImprintFonts.detailSubtitle)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(0)

                VStack(alignment: .leading, spacing: 2) {
                    // Director
                    if let director = record.director {
                        Text(director)
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(secondaryTextColor)
                    }

                    // Year • Runtime
                    filmMetaLine
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Builds the "1990 • 88 mins" line from available data.
    private var filmMetaLine: some View {
        let parts: [String] = {
            var items: [String] = []
            if let year = record.filmReleaseDate {
                items.append(String(year))
            }
            if let mins = record.runtime {
                items.append("\(mins) mins")
            }
            return items
        }()

        return Group {
            if !parts.isEmpty {
                Text(parts.joined(separator: " • "))
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(tertiaryTextColor)
            }
        }
    }

    // MARK: - Film Tab Content

    @ViewBuilder
    private var filmDetailsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Synopsis
            if let overview = record.overview, !overview.isEmpty {
                detailSection("Synopsis") {
                    Text(overview)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                        .lineSpacing(6)
                }
            }

            // Genres
            if let genres = record.genres, !genres.isEmpty {
                detailSection("Genres") {
                    Text(genres)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                }
            }

            // Cast
            if let cast = record.cast, !cast.isEmpty {
                detailSection("Cast") {
                    Text(cast)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                        .lineSpacing(4)
                }
            }

            // Country
            if let country = record.country, !country.isEmpty {
                detailSection("Country") {
                    Text(country)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                }
            }

            // Empty state
            if record.overview == nil && record.genres == nil && record.cast == nil && record.country == nil {
                VStack(spacing: 8) {
                    Text("No details available")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(tertiaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    /// A labeled section for the Details tab. Extensible — just add more calls.
    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(tertiaryTextColor)
                .textCase(nil)

            content()
        }
    }

    // MARK: - TV Detail (Centered Layout + Tabs)

    private var tvDetailContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            tvHero
                .padding(.horizontal, 32)
            detailTabBar
            Group {
                switch selectedTab {
                case .note:
                    if record.recordType == .logged {
                        tvLogInfoTabContent
                    } else {
                        noteTabContent
                    }
                case .details:
                    tvDetailsContent
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var tvHero: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Poster — same scroll effect as film/book
            if let path = record.posterPath,
               let url = TMDBService.posterURL(path: path, size: "w500") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    case .failure:
                        EmptyView()
                    default:
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ImprintColors.searchBg)
                            .aspectRatio(2.0 / 3.0, contentMode: .fit)
                            .overlay(ProgressView())
                    }
                }
                .frame(height: 260)
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                .visualEffect { content, proxy in
                    let minY = proxy.frame(in: .named("scroll")).minY
                    let scrolled = max(0, 48 - minY)
                    let progress = min(1, scrolled / 220)
                    return content
                        .scaleEffect(1 - progress * 0.4)
                        .opacity(1 - progress)
                }
            }

            // Title + metadata
            VStack(alignment: .leading, spacing: 16) {
                Text(record.name)
                    .font(ImprintFonts.detailSubtitle)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(0)

                if record.recordType == .queued {
                    // Queue: show creator and year/seasons
                    tvQueueMeta
                } else {
                    let episodes = record.watchedEpisodes
                    if episodes.count <= 1 {
                        // Single episode: show details in hero
                        VStack(alignment: .leading, spacing: 2) {
                            if let epName = record.episodeName,
                               let s = record.season, let e = record.episode {
                                Text("\(epName) (S\(String(format: "%02d", s)).E\(String(format: "%02d", e)))")
                                    .font(ImprintFonts.jetBrainsMedium(14))
                                    .foregroundStyle(secondaryTextColor)
                            } else if let s = record.season, let e = record.episode {
                                Text(String(format: "S%02d.E%02d", s, e))
                                    .font(ImprintFonts.jetBrainsMedium(14))
                                    .foregroundStyle(secondaryTextColor)
                            } else if let s = record.season {
                                Text(String(format: "S%02d", s))
                                    .font(ImprintFonts.jetBrainsMedium(14))
                                    .foregroundStyle(secondaryTextColor)
                            }

                            if let dir = record.episodeDirector {
                                Text("Dir. \(dir)")
                                    .font(ImprintFonts.jetBrainsMedium(14))
                                    .foregroundStyle(secondaryTextColor)
                            }

                            tvMetaLine
                        }
                    }
                    // Multiple episodes: no episode info in hero (shown in Log Info tab)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tvMetaLine: some View {
        let parts: [String] = {
            var items: [String] = []
            if let year = record.episodeAirYear {
                items.append(String(year))
            }
            if let mins = record.episodeRuntime {
                items.append("\(mins) mins")
            }
            return items
        }()

        return Group {
            if !parts.isEmpty {
                Text(parts.joined(separator: " • "))
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(tertiaryTextColor)
            }
        }
    }

    /// Metadata shown beneath the title for queued TV shows:
    /// "Created by [name]" and "20XX • X seasons".
    @ViewBuilder
    private var tvQueueMeta: some View {
        VStack(spacing: 2) {
            if let creator = record.creator, !creator.isEmpty {
                Text("Created by \(creator)")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(secondaryTextColor)
            }

            let parts: [String] = {
                var p: [String] = []
                if let year = record.tvReleaseYear {
                    p.append(String(year))
                }
                if let count = record.numberOfSeasons, count > 0 {
                    p.append("\(count) season\(count == 1 ? "" : "s")")
                }
                return p
            }()

            if !parts.isEmpty {
                Text(parts.joined(separator: " \u{2022} "))
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(tertiaryTextColor)
            }
        }
    }

    @ViewBuilder
    private var tvDetailsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let overview = record.overview, !overview.isEmpty {
                detailSection("Synopsis") {
                    Text(overview)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                        .lineSpacing(6)
                }
            }

            if let genres = record.genres, !genres.isEmpty {
                detailSection("Genres") {
                    Text(genres)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                }
            }

            if let cast = record.cast, !cast.isEmpty {
                detailSection("Cast") {
                    Text(cast)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                        .lineSpacing(4)
                }
            }

            // Country
            if let country = record.country, !country.isEmpty {
                detailSection("Country") {
                    Text(country)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                }
            }

            if record.overview == nil && record.genres == nil && record.cast == nil && record.country == nil {
                VStack(spacing: 8) {
                    Text("No details available")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(tertiaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    // MARK: - Book Detail (Centered Layout + Tabs)

    private var bookDetailContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            bookHero
                .padding(.horizontal, 32)
            detailTabBar
            Group {
                switch selectedTab {
                case .note:
                    noteTabContent
                case .details:
                    bookDetailsContent
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var bookHero: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Cover — shrinks and fades as you scroll up via .visualEffect
            if let url = record.coverImageURL(size: "L") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    case .failure:
                        EmptyView()
                    default:
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ImprintColors.searchBg)
                            .aspectRatio(2.0 / 3.0, contentMode: .fit)
                            .overlay(ProgressView())
                    }
                }
                .frame(height: 260)
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                .visualEffect { content, proxy in
                    let minY = proxy.frame(in: .named("scroll")).minY
                    let scrolled = max(0, 48 - minY)
                    let progress = min(1, scrolled / 220)
                    return content
                        .scaleEffect(1 - progress * 0.4)
                        .opacity(1 - progress)
                }
            }

            // Title + metadata
            VStack(alignment: .leading, spacing: 16) {
                Text(record.name)
                    .font(ImprintFonts.detailSubtitle)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(0)

                VStack(alignment: .leading, spacing: 2) {
                    if let author = record.author {
                        Text(author)
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(secondaryTextColor)
                    }

                    bookMetaLine

                    // Page range (reading progress)
                    if let sp = record.startPage, let ep = record.endPage {
                        Text("pp. \(sp)–\(ep)")
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(tertiaryTextColor)
                    } else if let sp = record.startPage {
                        Text("from p. \(sp)")
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(tertiaryTextColor)
                    } else if let ep = record.endPage {
                        Text("to p. \(ep)")
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(tertiaryTextColor)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Builds the "1866 • 545 pages" line from available data.
    private var bookMetaLine: some View {
        let parts: [String] = {
            var items: [String] = []
            if let year = record.publicationDate {
                items.append(String(year))
            }
            if let pages = record.pageCount {
                items.append("\(pages) pages")
            }
            return items
        }()

        return Group {
            if !parts.isEmpty {
                Text(parts.joined(separator: " • "))
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(tertiaryTextColor)
            }
        }
    }

    @ViewBuilder
    private var bookDetailsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            if let overview = record.overview, !overview.isEmpty {
                detailSection("Description") {
                    Text(overview)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                        .lineSpacing(6)
                }
            }

            // Subjects
            if let genres = record.genres, !genres.isEmpty {
                detailSection("Subjects") {
                    Text(genres)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                }
            }

            // Translator
            if let translator = record.translator, !translator.isEmpty {
                detailSection("Translator") {
                    Text(translator)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                }
            }

            // Country
            if let country = record.country, !country.isEmpty {
                detailSection("Country") {
                    Text(country)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(textColor)
                }
            }

            // Empty state
            if record.overview == nil && record.genres == nil && (record.translator == nil || record.translator?.isEmpty == true) && record.country == nil {
                VStack(spacing: 8) {
                    Text("No details available")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(tertiaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    // MARK: - Shared Tab Bar & Note Content

    /// Reusable tab bar used by film, TV, and book detail layouts.
    private var detailTabBar: some View {
        VStack(spacing: 0) {
            // Top divider
            Rectangle()
                .fill(tertiaryTextColor)
                .frame(height: 1)

            HStack(spacing: 24) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Text(tabLabel(for: tab))
                                .font(ImprintFonts.jetBrainsMedium(14))
                                .foregroundStyle(selectedTab == tab ? textColor : secondaryTextColor)
                                .padding(.vertical, 12)

                            Rectangle()
                                .fill(selectedTab == tab ? textColor : Color.clear)
                                .frame(height: 2)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 32)

            // Bottom divider
            Rectangle()
                .fill(tertiaryTextColor)
                .frame(height: 1)
        }
    }

    /// Reusable note tab content used by both film and book detail layouts.
    @ViewBuilder
    private var noteTabContent: some View {
        if let note = record.note, !note.isEmpty {
            Text(note)
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(secondaryTextColor)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
        } else {
            VStack(spacing: 8) {
                Text("No note yet")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(tertiaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 32)
        }
    }

    /// Returns the display label for a tab, using "Log Info" for logged TV entries.
    private func tabLabel(for tab: DetailTab) -> String {
        if tab == .note && record.mediaType == .tv && record.recordType == .logged {
            return "Log Info"
        }
        return tab.rawValue
    }

    /// Log Info tab content for logged TV entries: Watched section + Note section.
    @ViewBuilder
    private var tvLogInfoTabContent: some View {
        let episodes = record.watchedEpisodes

        VStack(alignment: .leading, spacing: 24) {
            if !episodes.isEmpty {
                // Watched section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Watched")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(secondaryTextColor)
                        .lineSpacing(6)

                    ForEach(episodes) { ep in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ep.seasonEpisodeCode)
                                .font(ImprintFonts.jetBrainsMedium(14))
                                .foregroundStyle(secondaryTextColor)
                                .lineSpacing(6)

                            Text(ep.episodeName ?? "Episode \(ep.episode)")
                                .font(ImprintFonts.jetBrainsBold(14))
                                .foregroundStyle(textColor)
                                .lineSpacing(6)

                            if let dir = ep.episodeDirector {
                                Text("Dir. \(dir)")
                                    .font(ImprintFonts.jetBrainsMedium(14))
                                    .foregroundStyle(secondaryTextColor)
                                    .lineSpacing(6)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(tertiaryTextColor)
                                .frame(width: 2)
                        }
                    }
                }
            }

            // Note section
            VStack(alignment: .leading, spacing: 12) {
                Text("Note")
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(secondaryTextColor)
                    .lineSpacing(6)

                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(secondaryTextColor)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No note yet")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(tertiaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Generic Detail (Non-Film)

    private var genericDetailContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(record.name)
                .font(ImprintFonts.detailTitle)
                .foregroundStyle(textColor)

            genericMetadataBlock

            if let note = record.note, !note.isEmpty {
                Text(note)
                    .font(ImprintFonts.noteBody)
                    .foregroundStyle(textColor)
                    .lineSpacing(5)
            }
        }
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var genericMetadataBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch record.mediaType {
            case .film:
                EmptyView() // Handled by filmDetailContent
            case .tv:
                if let season = record.season, let episode = record.episode {
                    metaLine(String(format: "S%02d.E%02d", season, episode))
                } else if let season = record.season {
                    metaLine("S\(String(format: "%02d", season))")
                }
                if let creator = record.creator {
                    metaLine(creator)
                }
            case .book:
                if let author = record.author {
                    metaLine(author)
                }
                if let year = record.publicationDate {
                    metaLine(String(year))
                }
                if let translator = record.translator {
                    metaLine("Translated by \(translator)")
                }
            case .music:
                if let artist = record.artist {
                    metaLine(artist)
                }
                if let year = record.musicReleaseDate {
                    metaLine(String(year))
                }
            }

            if let country = record.country {
                metaLine(country)
            }
        }
    }

    private func metaLine(_ text: String) -> some View {
        Text(text)
            .font(ImprintFonts.jetBrainsMedium(14))
            .foregroundStyle(secondaryTextColor)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}
