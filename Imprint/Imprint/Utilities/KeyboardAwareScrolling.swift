import SwiftUI
import Combine

/// Tracks the current keyboard height via NotificationCenter.
///
/// Use this in any view that opts out of automatic keyboard avoidance
/// (via `.ignoresSafeArea(.keyboard)`) but still needs to keep the
/// focused field visible. Pair with `ScrollViewReader.scrollTo(_:)`.
///
/// Usage:
/// ```swift
/// @StateObject private var keyboard = KeyboardObserver()
///
/// ScrollViewReader { proxy in
///     ScrollView {
///         content
///             .padding(.bottom, keyboard.height)
///     }
///     .onChange(of: keyboard.height) { _, newHeight in
///         if newHeight > 0 {
///             withAnimation(.easeOut(duration: 0.25)) {
///                 proxy.scrollTo(focusedFieldID, anchor: .bottom)
///             }
///         }
///     }
/// }
/// ```
final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                self?.height = height
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                self?.height = height
            }
            .store(in: &cancellables)
    }
}
