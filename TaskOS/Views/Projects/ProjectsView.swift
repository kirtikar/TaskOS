import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Query(
        filter: #Predicate<Project> { !$0.isArchived },
        sort: \Project.createdAt
    ) private var projects: [Project]

    @Query(
        filter: #Predicate<Project> { $0.isArchived },
        sort: \Project.createdAt
    ) private var archivedProjects: [Project]

    @Environment(\.modelContext) private var context
    @State private var viewModel = ProjectsViewModel()
    @State private var selectedProject: Project?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    if projects.isEmpty && archivedProjects.isEmpty {
                        EmptyStateView(
                            sfSymbol: "square.grid.2x2",
                            title: "No Projects Yet",
                            message: "Organize your tasks into projects for better focus.",
                            actionLabel: "Create Project"
                        ) {
                            viewModel.showNewProjectSheet = true
                        }
                        .padding(.top, DS.Spacing.xxxl)
                    } else {
                        projectGrid(projects)

                        if !archivedProjects.isEmpty && viewModel.showArchivedProjects {
                            SectionHeader(title: "Archived", count: archivedProjects.count)
                            projectGrid(archivedProjects)
                        }

                        if !archivedProjects.isEmpty {
                            Button {
                                withAnimation(DS.Animation.quick) {
                                    viewModel.showArchivedProjects.toggle()
                                }
                            } label: {
                                Label(
                                    viewModel.showArchivedProjects ? "Hide Archived" : "Show Archived (\(archivedProjects.count))",
                                    systemImage: viewModel.showArchivedProjects ? "archivebox.fill" : "archivebox"
                                )
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colors.secondaryLabel)
                            }
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.bottom, DS.Spacing.md)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .background(DS.Colors.groupedBG)
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showNewProjectSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DS.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showNewProjectSheet) {
                NewProjectSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(DS.Radius.lg)
            }
            .navigationDestination(item: $selectedProject) { project in
                ProjectDetailView(project: project)
            }
        }
    }

    // MARK: - Project Grid

    private func projectGrid(_ list: [Project]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: DS.Spacing.sm
        ) {
            ForEach(list) { project in
                ProjectCard(project: project) {
                    selectedProject = project
                }
                .contextMenu {
                    projectContextMenu(for: project)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func projectContextMenu(for project: Project) -> some View {
        Button {
            viewModel.editingProject = project
        } label: {
            Label("Edit Project", systemImage: "pencil")
        }

        Button {
            viewModel.archiveProject(project)
        } label: {
            Label(
                project.isArchived ? "Unarchive" : "Archive",
                systemImage: project.isArchived ? "arrow.uturn.up" : "archivebox"
            )
        }

        Divider()

        Button(role: .destructive) {
            viewModel.deleteProject(project, context: context)
        } label: {
            Label("Delete Project", systemImage: "trash")
        }
    }
}

// MARK: - ProjectCard

struct ProjectCard: View {
    let project: Project
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: DS.Radius.xs)
                            .fill(project.colorName.color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: project.iconName.sfSymbol)
                            .font(.system(size: 16))
                            .foregroundStyle(project.colorName.color)
                    }

                    Spacer()

                    Text("\(project.activeTasks.count)")
                        .font(DS.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(DS.Colors.label)
                }

                Text(project.name)
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.label)
                    .lineLimit(1)

                if !project.tasks.isEmpty {
                    // Progress bar
                    VStack(spacing: 4) {
                        ProgressView(value: project.progress)
                            .tint(project.colorName.color)
                            .scaleEffect(x: 1, y: 0.6, anchor: .center)

                        Text("\(project.completedTasks.count) of \(project.tasks.count) done")
                            .font(DS.Typography.caption2)
                            .foregroundStyle(DS.Colors.tertiaryLabel)
                    }
                } else {
                    Text("No tasks yet")
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colors.tertiaryLabel)
                }
            }
            .padding(DS.Spacing.md)
            .background(DS.Colors.secondaryBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NewProjectSheet

struct NewProjectSheet: View {
    @Bindable var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $viewModel.newProjectName)
                        .font(DS.Typography.body)

                    TextField("Notes (optional)", text: $viewModel.newProjectNotes, axis: .vertical)
                        .font(DS.Typography.body)
                        .lineLimit(2...4)
                }

                Section("Color") {
                    colorPicker
                }

                Section("Icon") {
                    iconPicker
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createProject(context: context)
                        dismiss()
                    }
                    .disabled(viewModel.newProjectName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(ProjectColor.allCases, id: \.rawValue) { color in
                    Button {
                        viewModel.newProjectColor = color
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 28, height: 28)
                            if viewModel.newProjectColor == color {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, DS.Spacing.xxs)
        }
    }

    private var iconPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: DS.Spacing.xs) {
            ForEach(ProjectIcon.allCases, id: \.rawValue) { icon in
                Button {
                    viewModel.newProjectIcon = icon
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: DS.Radius.xs)
                            .fill(
                                viewModel.newProjectIcon == icon
                                    ? viewModel.newProjectColor.color.opacity(0.15)
                                    : DS.Colors.tertiaryBG
                            )
                            .frame(width: 40, height: 40)
                        Image(systemName: icon.sfSymbol)
                            .font(.system(size: 18))
                            .foregroundStyle(
                                viewModel.newProjectIcon == icon
                                    ? viewModel.newProjectColor.color
                                    : DS.Colors.secondaryLabel
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DS.Spacing.xxs)
    }
}

#Preview {
    ProjectsView()
        .modelContainer(for: [Task.self, Project.self, Tag.self, Subtask.self], inMemory: true)
        .environment(ThemeManager.shared)
}
