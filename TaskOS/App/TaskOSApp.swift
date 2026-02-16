import SwiftUI
import SwiftData

@main
struct TaskOSApp: App {
    @State private var themeManager = ThemeManager.shared
    @State private var authService  = AuthenticationService()
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
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
            RootView()
                .preferredColorScheme(themeManager.theme.colorScheme)
                .environment(themeManager)
                .environment(authService)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - RootView
// Controls the auth → onboarding → main app navigation flow.

struct RootView: View {
    @Environment(AuthenticationService.self) private var auth
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !auth.isAuthenticated {
                // Not signed in → show auth wall
                AuthView()
                    .transition(.opacity)
            } else if !hasSeenOnboarding {
                // Signed in, first launch → onboarding
                OnboardingView()
                    .transition(.opacity)
            } else {
                // Fully set up → main app
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(DS.Animation.smooth, value: auth.isAuthenticated)
        .onAppear {
            auth.restoreSession()
        }
    }
}
