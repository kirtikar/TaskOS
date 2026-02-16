import SwiftUI
import SwiftData

struct InboxView: View {
    @Query(
        filter: #Predicate<TaskItem> { $0.isInInbox },
        sort: \TaskItem.createdAt,
        order: .reverse
    ) private var inboxTasks: [TaskItem]

    @Query private var projects: [Project]
    @Environment(\.modelContext) private var context

    @State private var viewModel = InboxViewModel()
    @State private var selectedTask: TaskItem?
    @State private var showSortMenu = false
    @State private var searchText = ""

    private var filteredTasks: [TaskItem] {
        let base = viewModel.sortedTasks(inboxTasks)
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if inboxTasks.isEmpty {
                    EmptyStateView(
                        sfSymbol: "tray",
                        title: "Inbox is Empty",
                        message: "Tasks you capture without a project land here."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DS.Colors.groupedBG)
                } else {
                    taskList
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search inbox")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // Sort options
                        Section("Sort by") {
                            ForEach(InboxViewModel.SortOrder.allCases, id: \.rawValue) { order in
                                Button {
                                    withAnimation(DS.Animation.quick) {
                                        viewModel.sortOrder = order
                                    }
                                } label: {
                                    Label(
                                        order.rawValue,
                                        systemImage: viewModel.sortOrder == order ? "checkmark" : order.sfSymbol
                                    )
                                }
                            }
                        }

                        Divider()

                        // Show completed toggle
                        Button {
                            viewModel.showCompleted.toggle()
                        } label: {
                            Label(
                                viewModel.showCompleted ? "Hide Completed" : "Show Completed",
                                systemImage: viewModel.showCompleted ? "eye.slash" : "eye"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(DS.Colors.accent)
                    }
                }
            }
            .navigationDestination(item: $selectedTask) { task in
                TaskDetailView(task: task)
            }
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            if filteredTasks.isEmpty {
                Text("No tasks match your search")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.secondaryLabel)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, DS.Spacing.xxxl)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(filteredTasks) { task in
                    TaskRow(task: task) {
                        viewModel.toggleTask(task)
                    } onTap: {
                        selectedTask = task
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteTask(task, context: context)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            viewModel.toggleTask(task)
                        } label: {
                            Label(
                                task.isCompleted ? "Uncomplete" : "Complete",
                                systemImage: task.isCompleted ? "xmark.circle" : "checkmark.circle"
                            )
                        }
                        .tint(DS.Colors.success)
                    }
                    .contextMenu {
                        inboxContextMenu(for: task)
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(DS.Colors.groupedBG)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func inboxContextMenu(for task: TaskItem) -> some View {
        Button {
            selectedTask = task
        } label: {
            Label("Edit", systemImage: "pencil")
        }

        Menu("Move to Project") {
            ForEach(projects.filter { !$0.isArchived }) { project in
                Button {
                    viewModel.moveTasks([task], to: project)
                } label: {
                    Label(project.name, systemImage: project.iconName.sfSymbol)
                }
            }
        }

        Divider()

        Button {
            viewModel.toggleTask(task)
        } label: {
            Label(
                task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                systemImage: task.isCompleted ? "xmark.circle" : "checkmark.circle"
            )
        }

        Button(role: .destructive) {
            viewModel.deleteTask(task, context: context)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

#Preview {
    InboxView()
        .modelContainer(for: [TaskItem.self, Project.self, Tag.self, Subtask.self], inMemory: true)
        .environment(ThemeManager.shared)
}
