import SwiftUI
import SwiftData

struct SearchView: View {
    @Query private var allTasks: [TaskItem]
    @Query private var allProjects: [Project]
    @Query private var allTags: [Tag]

    @State private var searchText = ""
    @State private var selectedTask: TaskItem?
    @State private var selectedFilter: SearchFilter = .all

    enum SearchFilter: String, CaseIterable {
        case all      = "All"
        case tasks    = "Tasks"
        case projects = "Projects"
        case tags     = "Tags"
    }

    private var matchedTasks: [TaskItem] {
        guard !searchText.isEmpty else { return [] }
        return allTasks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) })
        }
    }

    private var matchedProjects: [Project] {
        guard !searchText.isEmpty else { return [] }
        return allProjects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if searchText.isEmpty {
                    recentSuggestions
                } else {
                    filterChipsRow

                    ScrollView {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            if (selectedFilter == .all || selectedFilter == .tasks) && !matchedTasks.isEmpty {
                                VStack(spacing: 0) {
                                    SectionHeader(title: "Tasks", count: matchedTasks.count)
                                    ForEach(matchedTasks) { task in
                                        TaskRow(task: task) {} onTap: {
                                            selectedTask = task
                                        }
                                        if task.id != matchedTasks.last?.id {
                                            Divider().padding(.leading, 52)
                                        }
                                    }
                                }
                                .background(DS.Colors.secondaryBG)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                                .padding(.horizontal, DS.Spacing.md)
                            }

                            if (selectedFilter == .all || selectedFilter == .projects) && !matchedProjects.isEmpty {
                                SectionHeader(title: "Projects", count: matchedProjects.count)
                                ForEach(matchedProjects) { project in
                                    HStack {
                                        Image(systemName: project.iconName.sfSymbol)
                                            .foregroundStyle(project.colorName.color)
                                            .frame(width: 28)
                                        Text(project.name)
                                            .font(DS.Typography.body)
                                        Spacer()
                                        Text("\(project.activeTasks.count)")
                                            .font(DS.Typography.caption1)
                                            .foregroundStyle(DS.Colors.secondaryLabel)
                                    }
                                    .padding(.horizontal, DS.Spacing.md)
                                    .padding(.vertical, DS.Spacing.sm)
                                    .background(DS.Colors.secondaryBG)
                                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                                    .padding(.horizontal, DS.Spacing.md)
                                }
                            }

                            if matchedTasks.isEmpty && matchedProjects.isEmpty {
                                EmptyStateView(
                                    sfSymbol: "magnifyingglass",
                                    title: "No Results",
                                    message: "No tasks or projects match \"\(searchText)\""
                                )
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .background(DS.Colors.groupedBG)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Tasks, projects, tags..."
            )
            .navigationDestination(item: $selectedTask) { task in
                TaskDetailView(task: task)
            }
        }
    }

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(SearchFilter.allCases, id: \.rawValue) { filter in
                    FilterChip(label: filter.rawValue, isSelected: selectedFilter == filter) {
                        withAnimation(DS.Animation.quick) { selectedFilter = filter }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.xs)
        }
    }

    private var recentSuggestions: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            if !allTasks.filter(\.isInInbox).isEmpty {
                SectionHeader(title: "Inbox", count: allTasks.filter { $0.isInInbox && !$0.isCompleted }.count)
                VStack(spacing: 0) {
                    ForEach(allTasks.filter { $0.isInInbox && !$0.isCompleted }.prefix(5)) { task in
                        TaskRow(task: task) {} onTap: { selectedTask = task }
                        Divider().padding(.leading, 52)
                    }
                }
                .background(DS.Colors.secondaryBG)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                .padding(.horizontal, DS.Spacing.md)
            }

            Spacer()
        }
        .padding(.top, DS.Spacing.sm)
        .background(DS.Colors.groupedBG)
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [TaskItem.self, Project.self, Tag.self, Subtask.self], inMemory: true)
        .environment(ThemeManager.shared)
}
