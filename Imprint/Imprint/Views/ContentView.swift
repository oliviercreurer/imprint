import SwiftUI
import SwiftData

/// The root view of the app. Two-level horizontal pager:
///
///   Outer pager: [Records | Categories]
///   Inner pager (Records): [Log | Queue] — shares search bar & filters
///
/// Settings is presented as an overlay sheet (z-index layers):
///   z3 – settings content (title + X + body)
///   z2 – settings blue background sheet
///   z1 – underlying page (background, pager, footer)
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext

    /// All records, used to derive the flat ordered list for the detail pager.
    @Query(sort: \Record.createdAt, order: .reverse) private var allRecords: [Record]

    /// All enabled categories for filtering.
    @Query(filter: #Predicate<Category> { $0.isEnabled }, sort: \Category.sortOrder)
    private var enabledCategories: [Category]

    @AppStorage("appearanceMode") private var appearanceMode = "light"

    // ── Navigation state ───────────────────────────────────────────
    /// Outer pager: records vs categories
    @State private var selectedSection: AppSection = .records
    /// Inner pager: log vs queue (only meaningful when section == .records)
    @State private var selectedRecordTab: RecordType = .logged

    @State private var categoryFilter: Category?
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var debounceTask: Task<Void, Never>?
    @State private var showingNewRecord = false
    @State private var newRecordCategory: Category?
    @State private var selectedRecord: Record?
    @State private var selectedCategory: Category?

    @State private var showingSettings = false
    @State private var showingCreateCategory = false

    /// Toast message shown briefly after moving a queue item to the log.
    @State private var toastMessage: String?
    @State private var toastVisible = false
    @State private var pendingToastName: String?

    /// Whether all month sections are currently expanded.
    @State private var allSectionsExpanded = true
    @State private var expandCollapseTrigger = 0

    @FocusState private var isSearchFocused: Bool

    // ── Derived state ──────────────────────────────────────────────

    private var isDark: Bool { appearanceMode == "dark" }
    private var isRecordSection: Bool { selectedSection == .records }

    /// The composite page index across both pager levels (0 = Log, 1 = Queue, 2 = Categories).
    private var compositePageIndex: Int {
        isRecordSection ? selectedRecordTab.pageIndex : 2
    }

    /// The title to show in the shared title bar.
    private var currentTitle: String {
        isRecordSection ? selectedRecordTab.label : "Categories"
    }

    /// The title color for the current page.
    private var currentTitleColor: Color {
        isRecordSection ? selectedRecordTab.titleColor : ImprintColors.blueBold
    }

    /// Flat ordered list of records for the current record tab.
    private var currentTabRecords: [Record] {
        let enabledIds = Set(enabledCategories.map(\.persistentModelID))
        var results = allRecords.filter { record in
            guard record.recordType == selectedRecordTab else { return false }
            guard let cat = record.category else { return false }
            return enabledIds.contains(cat.persistentModelID)
        }

        if let categoryFilter {
            let filterId = categoryFilter.persistentModelID
            results = results.filter { $0.category?.persistentModelID == filterId }
        }

        if !debouncedSearchText.isEmpty {
            let query = debouncedSearchText.lowercased()
            results = results.filter { record in
                record.name.lowercased().contains(query)
                || (record.firstTextFieldValue?.lowercased().contains(query) ?? false)
                || (record.note?.lowercased().contains(query) ?? false)
            }
        }

        return results
    }

    // MARK: - Body

    var body: some View {
        ZStack {

            // ── z1: Underlying page ──────────────────────────────
            ImprintColors.neutralSubtlest
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title bar clearance — same height for all pages
                Color.clear.frame(height: ImprintSpacing.size800)
                    .padding(.top, ImprintSpacing.space600)

                // Outer pager: [Records container | Categories]
                TabView(selection: $selectedSection) {
                    recordsContainer
                        .tag(AppSection.records)

                    CategoriesView(
                        isDark: isDark,
                        onSelectCategory: { category in
                            selectedCategory = category
                        }
                    )
                    .tag(AppSection.categories)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            // Toast
            VStack {
                Spacer()

                (Text(toastMessage ?? "").font(ImprintFonts.technical12Bold)
                 + Text(" added to Log").font(ImprintFonts.technical12Medium))
                    .foregroundStyle(ImprintColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: ImprintSpacing.size800)
                    .background(
                        RoundedRectangle(cornerRadius: ImprintSpacing.size100)
                            .fill(ImprintColors.accentBlue)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
                    .scaleEffect(toastVisible ? 1.0 : 0.9)
                    .opacity(toastVisible ? 1.0 : 0.0)
            }
            .padding(.horizontal, ImprintSpacing.space700)
            .padding(.bottom, 148) // Positioned above footer — functional offset
            .allowsHitTesting(false)
            .zIndex(10)

            // Footer — both always rendered, crossfade based on section
            FooterToolbar(
                isDark: isDark,
                onAdd: { category in
                    newRecordCategory = category
                    showingNewRecord = true
                },
                onSettings: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showingSettings.toggle()
                    }
                }
            )
            .opacity(isRecordSection ? 1 : 0)
            .allowsHitTesting(isRecordSection && !showingSettings)

            categoriesFooter
                .opacity(isRecordSection ? 0 : 1)
                .allowsHitTesting(!isRecordSection && !showingSettings)

            // ── z2: Settings background sheet ────────────────────
            ImprintColors.accentBlueBold
                .ignoresSafeArea()
                .opacity(showingSettings ? 1 : 0)
                .allowsHitTesting(false)
                .zIndex(20)

            // ── z3: Shared title bar + settings body ─────────────
            VStack(spacing: 0) {
                sharedTitleBar
                    .zIndex(1)

                if showingSettings {
                    SettingsView()
                        .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
            .zIndex(25)
        }
        .animation(.easeInOut(duration: 0.35), value: selectedSection)
        .animation(.easeInOut(duration: 0.35), value: selectedRecordTab)
        .animation(.easeInOut(duration: 0.25), value: showingSettings)
        .onChange(of: searchText) { _, newValue in
            debounceTask?.cancel()
            if newValue.isEmpty {
                debouncedSearchText = ""
            } else {
                debounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    guard !Task.isCancelled else { return }
                    debouncedSearchText = newValue
                }
            }
        }
        .sheet(isPresented: $showingNewRecord) {
            RecordFormView(
                initialRecordType: selectedRecordTab,
                initialCategory: newRecordCategory
            )
        }
        .sheet(isPresented: $showingCreateCategory) {
            CategoryEditorView()
        }
        .sheet(item: $selectedCategory) { category in
            CategoryEditorView(existingCategory: category)
        }
        .sheet(item: $selectedRecord, onDismiss: {
            if let name = pendingToastName {
                pendingToastName = nil
                showToast(name)
            }
        }) { record in
            EntryDetailView(
                record: record,
                onMovedToLog: { name in
                    pendingToastName = name
                    selectedRecord = nil
                }
            )
        }
        .onAppear {
            CategorySeeder.seedIfNeeded(context: modelContext)
        }
        .preferredColorScheme(isDark ? .dark : .light)
    }

    // MARK: - Records Container (inner pager + shared search/filter)

    /// The records experience: persistent search bar + filter bar above
    /// an inner Log/Queue pager. Search state persists across both tabs.
    private var recordsContainer: some View {
        VStack(spacing: 0) {
            // Search bar + filter bar — shared across Log/Queue
            recordPageHeader

            // Inner pager: Log | Queue
            TabView(selection: $selectedRecordTab) {
                ForEach(RecordType.allPages) { recordType in
                    RecordListView(
                        recordType: recordType,
                        categoryFilter: categoryFilter,
                        searchText: debouncedSearchText,
                        isDark: isDark,
                        allExpanded: allSectionsExpanded,
                        expandTrigger: expandCollapseTrigger,
                        onSelectRecord: { record in
                            selectedRecord = record
                        }
                    )
                    .tag(recordType)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    // MARK: - Record Page Header

    private var recordPageHeader: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space200) {
            // Search bar
            HStack(spacing: ImprintSpacing.space100) {
                TextField("", text: $searchText, prompt:
                    Text("Search...")
                        .font(ImprintFonts.technical14Medium)
                        .foregroundStyle(ImprintColors.textSubtler)
                )
                .font(ImprintFonts.technical14Medium)
                .foregroundStyle(ImprintColors.textBoldest)
                .focused($isSearchFocused)
                .submitLabel(.done)
                .onSubmit { isSearchFocused = false }

                if isSearchFocused || !searchText.isEmpty {
                    Button {
                        if searchText.isEmpty {
                            isSearchFocused = false
                        } else {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: searchText.isEmpty ? "keyboard.chevron.compact.down" : "xmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ImprintColors.iconSubtle)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, ImprintSpacing.space300)
            .frame(height: ImprintSpacing.size800)
            .background(ImprintColors.inputSubtlest)
            .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
            .animation(.easeInOut(duration: 0.2), value: isSearchFocused)

            // Filter bar
            MediaFilterBar(selection: $categoryFilter, isDark: isDark)
        }
        .padding(.horizontal, ImprintSpacing.space600)
        .padding(.top, ImprintSpacing.space500)
        .padding(.bottom, ImprintSpacing.space300)
    }

    // MARK: - Toast

    private func showToast(_ name: String) {
        toastMessage = name
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            toastVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                toastVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                toastMessage = nil
            }
        }
    }

    // MARK: - Categories Footer

    private var categoriesFooter: some View {
        VStack(spacing: 0) {
            Spacer()

            LinearGradient(
                stops: [
                    .init(color: ImprintColors.neutralSubtlest.opacity(0), location: 0),
                    .init(color: ImprintColors.neutralSubtlest.opacity(0.4), location: 0.4),
                    .init(color: ImprintColors.neutralSubtlest.opacity(0.8), location: 0.7),
                    .init(color: ImprintColors.neutralSubtlest, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 69)
            .allowsHitTesting(false)

            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showingSettings.toggle()
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 24))
                        .foregroundStyle(ImprintColors.iconSubtle)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    showingCreateCategory = true
                } label: {
                    Text("Create")
                        .font(ImprintFonts.technical14Medium)
                        .foregroundStyle(ImprintColors.textInverse)
                        .padding(.horizontal, ImprintSpacing.space400)
                        .padding(.vertical, ImprintSpacing.space300)
                        .background(ImprintColors.blueBold)
                        .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius100))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.top, ImprintSpacing.space500)
            .padding(.bottom, ImprintSpacing.space700)
            .background(ImprintColors.neutralSubtlest)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Shared Title Bar

    private var sharedTitleBar: some View {
        HStack(alignment: .center) {
            Text(showingSettings ? "Settings" : currentTitle)
                .font(ImprintFonts.pageTitle)
                .foregroundStyle(
                    showingSettings ? ImprintColors.paper
                    : currentTitleColor
                )
                .contentTransition(.numericText())

            Spacer()

            if showingSettings {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showingSettings = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ImprintColors.accentBlueLight)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            } else {
                ImprintPageIndicator(
                    pageCount: 3,
                    currentPage: compositePageIndex
                )
            }
        }
        .padding(.horizontal, ImprintSpacing.space600)
        .padding(.top, ImprintSpacing.space600)
        .padding(.bottom, ImprintSpacing.space300)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Category.self, FieldDefinition.self, FieldValue.self, Record.self], inMemory: true)
}
