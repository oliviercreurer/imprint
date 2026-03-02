import SwiftUI
import SwiftData

/// A streamlined flow for adding or editing a book via Hardcover search.
///
/// Phases:
/// 1. **Search** — type to find a book, tap a result to select it.
/// 2. **Cover** — browse available edition covers and pick one.
/// 3. **Confirm** — review the selection, optionally set a date and note, then save.
///
/// When editing an existing record, the view starts directly in the confirm phase
/// with all fields pre-populated from the record.
struct AddBookView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The current record type context (logged vs queued).
    var initialRecordType: RecordType = .logged

    /// If set, we're editing an existing record rather than creating a new one.
    var existingRecord: Record?

    /// When true, pre-populates from existingRecord but creates a new entry instead of updating.
    var isRelogging: Bool = false

    // MARK: - Flow State

    enum Phase {
        case search
        case coverPicker
        case confirm
    }

    @State private var phase: Phase = .search

    // MARK: - Search State

    @FocusState private var isSearchFocused: Bool
    @State private var query = ""
    @State private var searchResults: [HCSearchDocument] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // MARK: - Selection State

    @State private var selectedBook: HCSearchDocument?
    @State private var bookDetail: HCBook?
    @State private var editions: [HCEdition] = []
    @State private var selectedCoverURL: String?
    @State private var isLoadingDetail = false

    // MARK: - Confirm State

    @State private var finishedOn: Date = Date()
    @State private var hasSetDate = false
    @State private var note = ""
    @State private var startPage = ""
    @State private var endPage = ""

    private let service = HardcoverService.shared
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
                case .coverPicker:
                    coverPickerContent
                case .confirm:
                    confirmContent
                }
            }
            .background(ImprintColors.paper)

            // Bottom fade + "Use this cover" button
            if phase == .coverPicker && !editions.isEmpty {
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
                            Text("Use this cover")
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
        case .search: return "Add book"
        case .coverPicker: return "Choose a cover"
        case .confirm:
            if isEditing { return "Edit entry" }
            if isRelogging { return "Log again" }
            return "Add book"
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
                    Text("Search for a book")
                        .font(ImprintFonts.jetBrainsRegular(14))
                        .foregroundStyle(ImprintColors.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchResults) { book in
                            searchResultRow(book)
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }
        }
    }

    private func searchResultRow(_ book: HCSearchDocument) -> some View {
        Button {
            selectBook(book)
        } label: {
            HStack(spacing: 16) {
                // Cover thumbnail
                if let url = book.coverImageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            coverPlaceholder
                        default:
                            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: 46, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    coverPlaceholder
                        .frame(width: 46, height: 68)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(.black)
                        .lineLimit(1)

                    if let author = book.primaryAuthor {
                        Text(author)
                            .font(ImprintFonts.jetBrainsRegular(14))
                            .foregroundStyle(ImprintColors.secondary)
                            .lineLimit(1)
                    }

                    if let year = book.releaseYear {
                        Text(String(year))
                            .font(ImprintFonts.jetBrainsRegular(13))
                            .foregroundStyle(ImprintColors.secondary)
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

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(ImprintColors.bookSubtle.opacity(0.25))
            .overlay(
                Image(systemName: "book")
                    .font(.system(size: 16))
                    .foregroundStyle(ImprintColors.bookSubtle)
            )
    }

    // MARK: - Cover Picker

    private var coverPickerContent: some View {
        VStack(spacing: 0) {
            if isLoadingDetail {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading covers…")
                        .font(ImprintFonts.jetBrainsRegular(14))
                        .foregroundStyle(ImprintColors.secondary)
                }
                Spacer()
            } else if editions.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundStyle(ImprintColors.secondary)
                    Text("No covers available")
                        .font(ImprintFonts.jetBrainsRegular(14))
                        .foregroundStyle(ImprintColors.secondary)
                }
                Spacer()

                skipCoverButton
            } else {
                // Book info summary
                if let book = selectedBook {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(ImprintFonts.jetBrainsMedium(16))
                            .foregroundStyle(.black)

                        HStack(spacing: 8) {
                            if let year = book.releaseYear {
                                Text(String(year))
                                    .font(ImprintFonts.jetBrainsRegular(14))
                                    .foregroundStyle(ImprintColors.secondary)
                            }
                            if let author = book.primaryAuthor {
                                Text(author)
                                    .font(ImprintFonts.jetBrainsRegular(14))
                                    .foregroundStyle(ImprintColors.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                }

                // Cover grid
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(editions) { edition in
                            coverCell(edition)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 120)
                }
            }
        }
    }

    private func coverCell(_ edition: HCEdition) -> some View {
        let isSelected = selectedCoverURL == edition.bestImageURL

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCoverURL = edition.bestImageURL
            }
        } label: {
            if let url = edition.coverImageURL {
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
                            isSelected ? ImprintColors.bookBold : Color.clear,
                            lineWidth: 3
                        )
                )
                .overlay(alignment: .bottomTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white, ImprintColors.bookBold)
                            .padding(6)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var skipCoverButton: some View {
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
                    Text("Continue without cover")
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
                bookCard
                finishedOnField

                if hasSetDate {
                    pageRangeFields
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

    private var bookCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // Cover thumbnail
            if let urlStr = selectedCoverURL, let url = URL(string: urlStr) {
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
                    .fill(ImprintColors.bookSubtle.opacity(0.25))
                    .frame(width: 78, height: 119)
                    .overlay(
                        Image(systemName: "book")
                            .font(.system(size: 20))
                            .foregroundStyle(ImprintColors.bookSubtle)
                    )
            }

            // Book info
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedBook?.title ?? "")
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.primary)
                        .lineLimit(2)

                    VStack(alignment: .leading, spacing: 2) {
                        if let author = selectedBook?.primaryAuthor {
                            Text(author)
                                .font(ImprintFonts.jetBrainsMedium(14))
                                .foregroundStyle(ImprintColors.secondary)
                        }

                        if let year = selectedBook?.releaseYear {
                            Text(String(year))
                                .font(ImprintFonts.jetBrainsMedium(14))
                                .foregroundStyle(ImprintColors.searchBorder)
                        }
                    }
                }

                Spacer(minLength: 12)

                // Change cover link
                Button {
                    navigateToCoverPicker()
                } label: {
                    Text("Change cover")
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

    private var pageRangeFields: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pages")
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.secondary)

            HStack(spacing: 16) {
                TextField("Start page", text: $startPage)
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(ImprintColors.primary)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(ImprintColors.searchBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(ImprintColors.searchBorder, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                TextField("End page", text: $endPage)
                    .font(ImprintFonts.jetBrainsMedium(14))
                    .foregroundStyle(ImprintColors.primary)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(ImprintColors.searchBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(ImprintColors.searchBorder, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
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
                phase = .coverPicker
            }
        case .coverPicker:
            if isEditing {
                phase = .confirm
            } else {
                phase = .search
                selectedBook = nil
                bookDetail = nil
                editions = []
                selectedCoverURL = nil
            }
        case .search:
            break
        }
    }

    /// Opens the cover picker, fetching editions from Hardcover if needed.
    private func navigateToCoverPicker() {
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .coverPicker
        }

        if editions.isEmpty, let bookId = selectedBook?.id {
            isLoadingDetail = true
            Task {
                do {
                    if let detail = try await service.getBookDetails(id: bookId) {
                        await MainActor.run {
                            bookDetail = detail
                            editions = (detail.editions ?? []).filter { $0.bestImageURL != nil }
                            isLoadingDetail = false
                        }
                    } else {
                        await MainActor.run { isLoadingDetail = false }
                    }
                } catch {
                    await MainActor.run { isLoadingDetail = false }
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
            searchResults = try await service.searchBooks(query: query)
        } catch {
            print("❌ Book search failed: \(error)")
            searchResults = []
        }
    }

    private func selectBook(_ book: HCSearchDocument) {
        isSearchFocused = false

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedBook = book
            selectedCoverURL = book.imageURL
            query = book.title
            phase = .coverPicker
            isLoadingDetail = true
        }

        Task {
            do {
                if let detail = try await service.getBookDetails(id: book.id) {
                    await MainActor.run {
                        bookDetail = detail
                        editions = (detail.editions ?? []).filter { $0.bestImageURL != nil }
                        isLoadingDetail = false
                    }
                } else {
                    await MainActor.run { isLoadingDetail = false }
                }
            } catch {
                await MainActor.run { isLoadingDetail = false }
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
            let name = selectedBook?.title ?? existingRecord?.name ?? ""
            guard !name.isEmpty else { return }
            record = Record(
                recordType: recordType,
                mediaType: .book,
                name: name
            )
        }

        record.recordType = recordType

        // Update from selected book
        if let book = selectedBook {
            record.name = book.title
            record.hardcoverId = book.id
            record.author = book.primaryAuthor
            record.publicationDate = book.releaseYear ?? bookDetail?.releaseYear
            record.pageCount = book.pages ?? bookDetail?.pages
        } else if let existing = existingRecord {
            record.hardcoverId = existing.hardcoverId
            record.author = existing.author
            record.publicationDate = existing.publicationDate
            record.pageCount = existing.pageCount
        }

        // Cover — store as "hc:{fullURL}"
        if let coverURL = selectedCoverURL {
            record.posterPath = "hc:\(coverURL)"
        } else if let existing = existingRecord?.posterPath {
            record.posterPath = existing
        } else {
            record.posterPath = nil
        }

        // Extended metadata — prefer detail, fall back to search document
        record.overview = bookDetail?.description ?? selectedBook?.description ?? existingRecord?.overview ?? record.overview
        record.genres = bookDetail?.tagList ?? selectedBook?.tagList ?? existingRecord?.genres ?? record.genres

        if hasSetDate {
            record.finishedOn = finishedOn
        } else {
            record.finishedOn = nil
        }

        record.note = note.isEmpty ? nil : note
        record.startPage = Int(startPage)
        record.endPage = Int(endPage)

        if existingRecord == nil || isRelogging {
            modelContext.insert(record)
        }
    }

    // MARK: - Populate for Editing

    private func populateFromExisting() {
        guard let record = existingRecord else { return }

        // Build synthetic HCBook from stored record data
        selectedBook = syntheticBook(from: record)

        // Restore cover selection
        if let path = record.posterPath, path.hasPrefix("hc:") {
            selectedCoverURL = String(path.dropFirst(3))
        }

        query = record.name

        // When relogging, keep date/note/pages fresh for the new entry
        if !isRelogging {
            note = record.note ?? ""

            if let date = record.finishedOn {
                finishedOn = date
                hasSetDate = true
            }

            if let sp = record.startPage { startPage = String(sp) }
            if let ep = record.endPage { endPage = String(ep) }
        }

        // Jump straight to confirm
        phase = .confirm
    }

    /// Creates a synthetic HCSearchDocument from a Record's stored data so the UI can render.
    private func syntheticBook(from record: Record) -> HCSearchDocument {
        let contributions: [HCSearchContribution]?
        if let author = record.author {
            contributions = [
                HCSearchContribution(
                    author: HCSearchAuthor(id: nil, name: author, slug: nil),
                    contribution: "Author"
                )
            ]
        } else {
            contributions = nil
        }

        var coverURL: String? = nil
        if let path = record.posterPath, path.hasPrefix("hc:") {
            coverURL = String(path.dropFirst(3))
        }

        return HCSearchDocument(
            id: record.hardcoverId ?? 0,
            title: record.name,
            slug: nil,
            description: record.overview,
            pages: record.pageCount,
            releaseYear: record.publicationDate,
            releaseDate: record.publicationDate.map { "\($0)-01-01" },
            imageURL: coverURL,
            genres: record.genres?.components(separatedBy: ", "),
            contributions: contributions
        )
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}
