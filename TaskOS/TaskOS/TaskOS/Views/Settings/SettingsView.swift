import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var context
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = true
    @AppStorage("default_priority") private var defaultPriority = Priority.none.rawValue
    @AppStorage("enable_badges") private var enableBadges = true

    @State private var showResetAlert = false
    @State private var notificationPermission: NotificationPermissionState = .unknown

    enum NotificationPermissionState {
        case unknown, granted, denied
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Appearance
                Section("Appearance") {
                    @Bindable var tm = themeManager
                    Picker("Theme", selection: $tm.theme) {
                        ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                            Label(theme.rawValue, systemImage: theme.sfSymbol)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Large Titles", isOn: $tm.preferLargeTitles)

                    NavigationLink {
                        AccentColorPicker()
                    } label: {
                        HStack {
                            Text("Accent Color")
                            Spacer()
                            Circle()
                                .fill(DS.Colors.accent)
                                .frame(width: 20, height: 20)
                        }
                    }
                }

                // MARK: Tasks
                Section("Tasks") {
                    Picker("Default Priority", selection: Binding(
                        get: { Priority(rawValue: defaultPriority) ?? .none },
                        set: { defaultPriority = $0.rawValue }
                    )) {
                        ForEach(Priority.allCases, id: \.rawValue) { p in
                            Label(p.label, systemImage: p.sfSymbol)
                                .tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: Notifications
                Section("Notifications") {
                    Toggle("App Badge Count", isOn: $enableBadges)

                    HStack {
                        Text("Notification Permission")
                        Spacer()
                        switch notificationPermission {
                        case .granted:
                            Label("Enabled", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(DS.Typography.caption1)
                        case .denied:
                            Button("Enable in Settings") {
                                openAppSettings()
                            }
                            .font(DS.Typography.caption1)
                            .foregroundStyle(DS.Colors.accent)
                        case .unknown:
                            Button("Request Permission") {
                                requestNotificationPermission()
                            }
                            .font(DS.Typography.caption1)
                            .foregroundStyle(DS.Colors.accent)
                        }
                    }
                }

                // MARK: Data
                Section("Data") {
                    NavigationLink("Manage Tags") {
                        TagManagerView()
                    }

                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset All Data", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(DS.Colors.destructive)
                    }
                }

                // MARK: About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(DS.Colors.secondaryLabel)
                    }

                    Button {
                        hasSeenOnboarding = false
                    } label: {
                        Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                    }
                    .foregroundStyle(DS.Colors.accent)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all tasks, projects, and tags. This cannot be undone.")
            }
            .task {
                await checkNotificationPermission()
            }
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                notificationPermission = (granted == true) ? .granted : .denied
            }
        }
    }

    @MainActor
    private func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional: notificationPermission = .granted
        case .denied:                   notificationPermission = .denied
        default:                        notificationPermission = .unknown
        }
    }

    private func resetAllData() {
        do {
            try context.delete(model: Task.self)
            try context.delete(model: Project.self)
            try context.delete(model: Tag.self)
            try context.delete(model: Subtask.self)
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}

// MARK: - AccentColorPicker

struct AccentColorPicker: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        List {
            ForEach(AccentOption.allCases, id: \.rawValue) { option in
                Button {
                    // In a real app: update Assets.xcassets programmatically or use UIAppearance
                } label: {
                    HStack {
                        Circle()
                            .fill(option.color)
                            .frame(width: 24, height: 24)
                        Text(option.rawValue)
                            .foregroundStyle(DS.Colors.label)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - TagManagerView

struct TagManagerView: View {
    @Query(sort: \Tag.createdAt) private var tags: [Tag]
    @Environment(\.modelContext) private var context
    @State private var newTagName = ""
    @State private var newTagColor = "#007AFF"

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New tag name", text: $newTagName)
                    Button("Add") {
                        guard !newTagName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let tag = Tag(name: newTagName.trimmingCharacters(in: .whitespaces), color: newTagColor)
                        context.insert(tag)
                        newTagName = ""
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(DS.Colors.accent)
                }
            }

            Section("Your Tags") {
                if tags.isEmpty {
                    Text("No tags yet")
                        .foregroundStyle(DS.Colors.secondaryLabel)
                } else {
                    ForEach(tags) { tag in
                        HStack {
                            TagChip(tag: tag)
                            Spacer()
                            Text("\(tag.tasks.count) tasks")
                                .font(DS.Typography.caption1)
                                .foregroundStyle(DS.Colors.secondaryLabel)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { context.delete(tags[$0]) }
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/#Preview {
    SettingsView()
        .modelContainer(for: [Task.self, Project.self, Tag.self, Subtask.self], inMemory: true)
        .environment(ThemeManager.shared)
}
