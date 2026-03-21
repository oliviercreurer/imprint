import SwiftUI
import SwiftData

@main
struct ImprintApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Category.self,
            FieldDefinition.self,
            FieldValue.self,
            Record.self,
        ])
    }
}
