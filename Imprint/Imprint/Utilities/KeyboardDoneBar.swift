import SwiftUI
import Combine

/// A custom keyboard accessory bar that replaces the system ToolbarItemGroup(placement: .keyboard).
/// Unlike the system toolbar, this gives full control over the gap between the bar and the keyboard.
struct KeyboardDoneBarModifier: ViewModifier {
    @State private var isKeyboardVisible = false

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isKeyboardVisible {
                    HStack {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        }
                        .font(ImprintFonts.jetBrainsMedium(14))
                        .foregroundStyle(ImprintColors.accentBlue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 18) // 10pt base + 8pt gap from keyboard
                    .background(ImprintColors.paper)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: isKeyboardVisible)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
    }
}

extension View {
    func keyboardDoneBar() -> some View {
        modifier(KeyboardDoneBarModifier())
    }
}
