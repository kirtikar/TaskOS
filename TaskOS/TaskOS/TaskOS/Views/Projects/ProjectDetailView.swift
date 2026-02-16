import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ProjectDetailViewModel()
    @State private var selectedTask: TaskItem?
    @State private var showAddTask = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                projectHeader
                taskList
            }
            .padding(.bottom, 100)
        }
        .background(DS.Colors.groupedBG)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: DS.Spacing.sm) {
                    Menu {
                        ForEach(InboxViewModel.SortOrder.allCases, id: \.rawValue) { order in
                            Button {
                                viewModel.sortOrder = order
                            } label: {
                                Label(order.rawValue, systemImage: order.sfSymbol)
                            }
                        }
                        Divider()
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

                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DS.Colors.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            QuickAddView(defaultProject: project)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(DS.Radius.lg)
        }
        .navigationDestination(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
    }

    // MARK: - Project Header

    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(project.colorName.color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: project.iconName.sfSymbol)
                        .font(.system(size: 24))
                        .foregroundStyle(project.colorName.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(project.activeTasks.count)")
                            .font(DS.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundStyle(DS.Colors.label)
                        Text("tasks remaining")
                            .font(DS.Typography.subheadline)
                            .foregroundStyle(DS.Colors.secondaryLabel)
                    }

                    if !project.tasks.isEmpty {
                        Text("\(project.completedTasks.count) completed")
                            .font(DS.Typography.caption1)
                            .foregroundStyle(DS.Colors.tertiaryLabel)
                    }
                }
            }

            if !project.tasks.isEmpty {
                ProgressView(value: project.progress)
                    .tint(project.colorName.color)
                    .scaleEffect(x: 1, y: 0.7, anchor: .center)
            }

            if !project.notes.isEmpty {
                Text(project.notes)
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.secondaryLabel)
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Colors.secondaryBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - Task List

    @ViewBuilder
    private var taskList: some View {
        let tasks = viewModel.sortedTasks(project.tasks)

        if tasks.isEmpty {
            EmptyStateView(
                sfSymbol: project.iconName.sfSymbol,
                title: "No Tasks",
                message: "Add tasks to \(project.name) to get started.",
                actionLabel: "Add Task"
            ) {
                showAddTask = true
            }
        } else {
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TaskRow(task: task) {
                        viewModel.toggleTask(task)
                    } onTap: {
                        selectedTask = task
                    }
                    .listRowInsets(EdgeInsets())

                    if task.id != tasks.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(DS.Colors.secondaryBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .padding(.horizontal, DS.Spacing.md)
        }
    }
}

#Preview {
    let project = Project(name: "Work", color: .blue, icon: .briefcase)
    return NavigationStack {
        ProjectDetailView(project: project)
    }
    .modelContainer(for: [TaskItem.self, Project.self, Tag.self, Subtask.self], inMemory: true)
    .environment(ThemeManager.shared)
}
