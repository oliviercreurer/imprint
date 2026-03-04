import SwiftUI

/// The custom footer overlay with gradient fade and + button.
/// Tapping the + button reveals an animated media-type picker menu.
struct FooterToolbar: View {

    let isDark: Bool
    let onAdd: (MediaType) -> Void

    @State private var showingMenu = false
    @Environment(\.enabledMediaTypes) private var enabledTypes

    private var bgColor: Color { isDark ? ImprintColors.primary : ImprintColors.paper }

    var body: some View {
        ZStack {
            // LAYER 1: Footer chrome (gradient + toolbar row)
            footerChrome

            // LAYER 2: Full-screen scrim — covers everything including the footer
            if showingMenu {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            showingMenu = false
                        }
                    }
            }

            // LAYER 3: Menu + close button float above the scrim
            VStack(spacing: 0) {
                Spacer()

                HStack {
                    Spacer()

                    ZStack(alignment: .bottomTrailing) {
                        // Menu anchored above the button
                        if showingMenu {
                            mediaTypeMenu
                                .offset(y: -58)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity
                                            .combined(with: .scale(scale: 0.85, anchor: .bottomTrailing))
                                            .combined(with: .offset(y: 6)),
                                        removal: .opacity
                                            .combined(with: .scale(scale: 0.9, anchor: .bottomTrailing))
                                    )
                                )
                        }

                        // The × / + button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                showingMenu.toggle()
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(isDark ? ImprintColors.primary : ImprintColors.paper)
                                .frame(width: 48, height: 48)
                                .background(isDark ? ImprintColors.paper : ImprintColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: showingMenu ? 24 : 8))
                                .rotationEffect(.degrees(showingMenu ? 45 : 0))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Footer Chrome

    /// The base footer layer: gradient and toolbar row.
    private var footerChrome: some View {
        VStack(spacing: 0) {
            Spacer()

            // Gradient fade — transparent at top, solid at bottom
            LinearGradient(
                stops: [
                    .init(color: bgColor.opacity(0), location: 0),
                    .init(color: bgColor.opacity(0.4), location: 0.4),
                    .init(color: bgColor.opacity(0.8), location: 0.7),
                    .init(color: bgColor, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)

            // Solid background region with content
            VStack(spacing: 16) {
                // Toolbar row — spacers keep layout balanced around the centered add button
                HStack {
                    // Left spacer — handle chip sits in ContentView's global overlay
                    Color.clear
                        .frame(width: 48, height: 48)

                    Spacer()

                    // Right spacer matching the add button size
                    Color.clear
                        .frame(width: 48, height: 48)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 4)
            .padding(.bottom, 40)
            .background(bgColor)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Media Type Menu

    private var mediaTypeMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add...")
                .font(ImprintFonts.jetBrainsMedium(14))
                .foregroundStyle(ImprintColors.searchBorder)

            ForEach(enabledTypes) { type in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showingMenu = false
                    }
                    onAdd(type)
                } label: {
                    HStack {
                        Text(type.menuLabel)
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(isDark ? ImprintColors.paper : ImprintColors.primary)

                        Spacer()

                        // Colored legend square (filled)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(type.subtleColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 1)
                                    .strokeBorder(type.subtleColor, lineWidth: 2)
                            )
                            .frame(width: 10, height: 10)
                    }
                    .frame(height: 18)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 162)
        .background(isDark ? ImprintColors.darkSurfaceBg : ImprintColors.paper)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDark ? ImprintColors.darkSurfaceBorder : ImprintColors.searchBorder,
                    lineWidth: 2
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
