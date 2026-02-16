import SwiftUI
import SwiftData

@main
struct TaskOSApp: App {
    @State private var themeManager = ThemeManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            Project.self,
            Tag.self,
            Subtask.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.theme.colorScheme)
                .environment(themeManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
