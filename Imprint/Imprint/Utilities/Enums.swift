import SwiftUI

// MARK: - Record Type

/// Whether a record has been consumed (logged) or saved for later (queued).
///
/// Marked `nonisolated` so it can be used freely across isolation boundaries
/// (e.g. inside SwiftData predicates and background contexts).
nonisolated enum RecordType: String, Codable, CaseIterable, Identifiable, Sendable {
    case logged
    case queued

    var id: String { rawValue }

    var label: String {
        switch self {
        case .logged: "Log"
        case .queued: "Queue"
        }
    }

    /// The pages shown in the horizontal paging TabView.
    static let allPages: [RecordType] = [.logged, .queued]

    /// Index of this page in the paging order.
    var pageIndex: Int {
        switch self {
        case .logged: return 0
        case .queued: return 1
        }
    }

    /// Per-page title color from the design system.
    @MainActor var titleColor: Color {
        switch self {
        case .logged: ImprintColors.cyanBold
        case .queued: ImprintColors.yellowBold
        }
    }
}

// MARK: - App Section

/// The two top-level sections in the outer horizontal pager.
/// Records (Log + Queue) share a search/filter context;
/// Categories is a separate experience.
nonisolated enum AppSection: String, CaseIterable, Identifiable, Sendable {
    case records
    case categories

    var id: String { rawValue }
}

