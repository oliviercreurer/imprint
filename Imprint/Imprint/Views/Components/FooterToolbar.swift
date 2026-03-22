import SwiftUI
import SwiftData

/// The custom footer overlay with gradient fade, settings gear, and + button.
/// Matches the Figma footer design:
///   - Settings gear icon (24pt) left-aligned
///   - Blue + button (48pt, blue/bold bg, radius/100) right-aligned
///   - Gradient fade from transparent → neutralSubtlest
struct FooterToolbar: View {

    let isDark: Bool
    let onAdd: (Category) -> Void
    var onSettings: (() -> Void)? = nil

    @State private var showingMenu = false

    @Query(filter: #Predicate<Category> { $0.isEnabled }, sort: \Category.sortOrder)
    private var enabledCategories: [Category]

    private var bgColor: Color { ImprintColors.neutralSubtlest }

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
                            categoryMenu
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

                        // The × / + button — blue/bold bg
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                showingMenu.toggle()
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(ImprintColors.textInverse)
                                .frame(
                                    width: ImprintSpacing.size800,
                                    height: ImprintSpacing.size800
                                )
                                .background(ImprintColors.blueBold)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: showingMenu
                                            ? ImprintSpacing.radiusRound
                                            : ImprintSpacing.radius100
                                    )
                                )
                                .rotationEffect(.degrees(showingMenu ? 45 : 0))
                        }
                    }
                }
                .padding(.horizontal, ImprintSpacing.space600)
                .padding(.bottom, ImprintSpacing.space700)
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
            .frame(height: 69)
            .allowsHitTesting(false)

            // Solid background region with settings gear + spacer for + button
            HStack {
                // Settings gear icon
                Button {
                    onSettings?()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 24))
                        .foregroundStyle(ImprintColors.iconSubtle)
                }
                .buttonStyle(.plain)

                Spacer()

                // Placeholder matching the + button size
                Color.clear
                    .frame(
                        width: ImprintSpacing.size800,
                        height: ImprintSpacing.size800
                    )
            }
            .padding(.horizontal, ImprintSpacing.space600)
            .padding(.top, ImprintSpacing.space500)
            .padding(.bottom, ImprintSpacing.space700)
            .background(bgColor)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Category Menu

    private var categoryMenu: some View {
        VStack(alignment: .leading, spacing: ImprintSpacing.space200) {
            Text("Add...")
                .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size400))
                .foregroundStyle(ImprintColors.neutralSubtle)

            ForEach(enabledCategories) { category in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showingMenu = false
                    }
                    onAdd(category)
                } label: {
                    HStack(spacing: ImprintSpacing.space100) {
                        IconoirCatalog.icon(for: category.iconName)
                            .frame(
                                width: ImprintSpacing.size300,
                                height: ImprintSpacing.size300
                            )
                            .foregroundStyle(ImprintColors.neutralBold)

                        Text(category.name)
                            .font(ImprintFonts.jetBrainsMedium(ImprintFonts.size400))
                            .foregroundStyle(ImprintColors.textBoldest)

                        Spacer()
                    }
                    .frame(height: 18)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(ImprintSpacing.space400)
        .frame(width: 180)
        .background(ImprintColors.neutralSubtlest)
        .overlay(
            RoundedRectangle(cornerRadius: ImprintSpacing.radius200)
                .strokeBorder(
                    ImprintColors.neutralSubtle,
                    lineWidth: ImprintSpacing.borderDefault
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: ImprintSpacing.radius200))
    }
}
