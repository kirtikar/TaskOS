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
            // Schema changed (new fields added) — existing store is incompatible.
            // Wipe and recreate. Any existing dev data will be lost.
            print("⚠️ SwiftData migration failed (\(error)). Resetting store.")
            try? FileManager.default.removeItem(at: config.url)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
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
