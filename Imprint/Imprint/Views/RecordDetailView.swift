import SwiftUI
import SwiftData

/// Shows full details for a single record as a panel overlay.
/// Matches the Figma "entry-panel" design with media chip, back button,
/// large title, metadata, and note.
struct RecordDetailView: View {

    @Bindable var record: Record
    @Environment(\.dismiss) private var dismiss

    var isDark: Bool = false

    @State private var showingEditSheet = false

    // Theme-aware colors
    private var bgColor: Color { isDark ? ImprintColors.primary : ImprintColors.paper }
    private var textColor: Color { isDark ? ImprintColors.paper : .black }
    private var secondaryTextColor: Color { isDark ? ImprintColors.darkSecondary : Color(hex: 0x7C7C7C) }
    private var buttonBorderColor: Color { isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Top bar: chip + date + back button
                    topBar

                    // Poster (for films with TMDB data)
                    if record.mediaType == .film,
                       let path = record.posterPath,
                       let url = TMDBService.posterURL(path: path, size: "w500") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                EmptyView()
                            default:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(ImprintColors.searchBg)
                                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                                    .overlay(ProgressView())
                            }
                        }
                        .frame(maxWidth: 220)
                    }

                    // Title and metadata
                    VStack(alignment: .leading, spacing: 16) {
                        Text(record.name)
                            .font(ImprintFonts.detailTitle)
                            .foregroundStyle(textColor)

                        metadataBlock

                        if let note = record.note, !note.isEmpty {
                            Text(note)
                                .font(ImprintFonts.noteBody)
                                .foregroundStyle(textColor)
                                .lineSpacing(5)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 80)
                .padding(.bottom, 200)
            }
            .scrollIndicators(.hidden)

            // Bottom fade
            VStack(spacing: 0) {
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
        }
        .background(bgColor)
        .sheet(isPresented: $showingEditSheet) {
            RecordFormView(existingRecord: record)
        }
        .presentationCornerRadius(0)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 8) {
            // Media type chip
            Text(record.mediaType.label)
                .font(ImprintFonts.jetBrainsMedium(12))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(isDark ? record.mediaType.queueLegendFill : record.mediaType.subtlestColor)
                .foregroundStyle(isDark ? record.mediaType.darkBoldColor : record.mediaType.boldColor)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            // Date
            if let date = record.finishedOn {
                Text(formattedDate(date))
                    .font(ImprintFonts.jetBrainsRegular(14))
                    .foregroundStyle(textColor)
            }

            Spacer()

            // Edit button
            Button {
                showingEditSheet = true
            } label: {
                Text("Edit")
                    .font(ImprintFonts.jetBrainsMedium(12))
                    .foregroundStyle(textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(buttonBorderColor, lineWidth: 2)
                    )
            }

            // Close button
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(ImprintFonts.jetBrainsMedium(12))
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

    // MARK: - Metadata

    @ViewBuilder
    private var metadataBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Media-specific metadata
            switch record.mediaType {
            case .film:
                if let director = record.director {
                    metaLine(director)
                }
                if let year = record.filmReleaseDate {
                    metaLine(String(year))
                }
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
            .font(ImprintFonts.jetBrainsRegular(14))
            .foregroundStyle(secondaryTextColor)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}
