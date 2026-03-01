import SwiftUI
import SwiftData

@main
struct ImprintApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Record.self)
    }
}
