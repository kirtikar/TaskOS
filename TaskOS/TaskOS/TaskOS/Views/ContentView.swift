import SwiftUI
import SwiftData

// MARK: - Tab

enum AppTab: Int, CaseIterable {
    case today    = 0
    case inbox    = 1
    case projects = 2
    case search   = 3
    case settings = 4

    var title: String {
        switch self {
        case .today:    return "Today"
        case .inbox:    return "Inbox"
        case .projects: return "Projects"
        case .search:   return "Search"
        case .settings: return "Settings"
        }
    }

    var sfSymbol: String {
        switch self {
        case .today:    return "sun.max.fill"
        case .inbox:    return "tray.fill"
        case .projects: return "square.grid.2x2.fill"
        case .search:   return "magnifyingglass"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var selectedTab: AppTab = .today
    @State private var showQuickAdd = false
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Views
            TabView(selection: $selectedTab) {
                TodayView()
                    .tag(AppTab.today)

                InboxView()
                    .tag(AppTab.inbox)

                ProjectsView()
                    .tag(AppTab.projects)

                SearchView()
                    .tag(AppTab.search)

                SettingsView()
                    .tag(AppTab.settings)
            }
            .tabViewStyle(.automatic)
            .overlay(alignment: .bottom) {
                customTabBar
            }

            // Quick Add floating button
            quickAddButton
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(DS.Radius.lg)
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                if tab == .search {
                    // Center: Quick Add FAB placeholder (spacer)
                    Spacer()
                        .frame(width: 72)
                } else {
                    tabBarItem(tab)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.xs)
        .padding(.bottom, DS.Spacing.md)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            DS.Colors.separator
                .frame(height: 0.5)
        }
    }

    private func tabBarItem(_ tab: AppTab) -> some View {
        Button {
            withAnimation(DS.Animation.quick) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.sfSymbol)
                    .font(.system(size: 20))
                    .symbolEffect(.bounce, value: selectedTab == tab)
                Text(tab.title)
                    .font(DS.Typography.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selectedTab == tab ? DS.Colors.accent : DS.Colors.tertiaryLabel)
            .scaleEffect(selectedTab == tab ? 1.05 : 1.0)
            .animation(DS.Animation.quick, value: selectedTab == tab)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Add Button

    private var quickAddButton: some View {
        Button {
            withAnimation(DS.Animation.bouncy) {
                showQuickAdd = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(DS.Colors.accent)
                    .frame(width: 56, height: 56)
                    .shadow(color: DS.Colors.accent.opacity(0.4), radius: 12, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .padding(.bottom, 28)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Task.self, Project.self, Tag.self, Subtask.self], inMemory: true)
        .environment(ThemeManager.shared)
}
