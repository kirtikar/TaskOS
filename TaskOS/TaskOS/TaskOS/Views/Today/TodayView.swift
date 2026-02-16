import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Task> { !$0.isCompleted }, sort: \Task.createdAt) private var activeTasks: [Task]
    @Query(sort: \Task.completedAt, order: .reverse) private var allTasks: [Task]

    @State private var viewModel = TodayViewModel()
    @State private var selectedTask: Task? = nil
    @State private var showCompleted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    filterChips
                    taskSections
                }
            }
            .background(DS.Colors.groupedBG)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCompleted.toggle()
                    } label: {
                        Image(systemName: showCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundStyle(DS.Colors.accent)
                    }
                }
            }
            .navigationDestination(item: $selectedTask) { task in
                TaskDetailView(task: task)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(viewModel.greetingText)
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colors.secondaryLabel)

            Text(viewModel.dateHeaderText)
                .font(DS.Typography.largeTitle)
                .foregroundStyle(DS.Colors.label)

            // Progress bar
            let todayCount   = viewModel.todayTasks(from: allTasks).count
            let completedCount = viewModel.completedTodayTasks(from: allTasks).count
            let total = todayCount + completedCount
            if total > 0 {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    HStack {
                        Text("\(completedCount) of \(total) done")
                            .font(DS.Typography.caption1)
                            .foregroundStyle(DS.Colors.secondaryLabel)
                        Spacer()
                        Text("\(Int(Double(completedCount) / Double(total) * 100))%")
                            .font(DS.Typography.caption1.bold())
                            .foregroundStyle(DS.Colors.accent)
                    }
                    ProgressView(value: Double(completedCount), total: Double(total))
                        .tint(DS.Colors.accent)
                        .scaleEffect(x: 1, y: 0.7, anchor: .center)
                }
                .padding(.top, DS.Spacing.xs)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.sm)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(TodayViewModel.TodayFilter.allCases, id: \.rawValue) { filter in
                    FilterChip(
                        label: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation(DS.Animation.quick) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.md)
        }
        .padding(.bottom, DS.Spacing.sm)
    }

    // MARK: - Task Sections

    @ViewBuilder
    private var taskSections: some View {
        let overdue  = viewModel.overdueTasks(from: allTasks)
        let today    = viewModel.todayTasks(from: allTasks)
        let upcoming = viewModel.upcomingTasks(from: allTasks)
        let done     = viewModel.completedTodayTasks(from: allTasks)

        VStack(spacing: DS.Spacing.sm) {
            // Overdue
            if !overdue.isEmpty && (viewModel.selectedFilter == .all || viewModel.selectedFilter == .overdue) {
                TaskSection(
                    title: "Overdue",
                    count: overdue.count,
                    tasks: overdue,
                    titleColor: DS.Colors.overdue
                ) { task in
                    selectedTask = task
                } onToggle: { task in
                    viewModel.toggleTask(task)
                }
            }

            // Today
            if viewModel.selectedFilter == .all || viewModel.selectedFilter == .today {
                if today.isEmpty && overdue.isEmpty {
                    EmptyStateView(
                        sfSymbol: "sun.max",
                        title: "All Clear",
                        message: "Nothing due today. Enjoy your day or add a task.",
                        actionLabel: nil
                    )
                } else if !today.isEmpty {
                    TaskSection(
                        title: "Today",
                        count: today.count,
                        tasks: today
                    ) { task in
                        selectedTask = task
                    } onToggle: { task in
                        viewModel.toggleTask(task)
                    }
                }
            }

            // Upcoming
            if !upcoming.isEmpty && (viewModel.selectedFilter == .all || viewModel.selectedFilter == .upcoming) {
                TaskSection(
                    title: "Upcoming",
                    count: upcoming.count,
                    tasks: upcoming
                ) { task in
                    selectedTask = task
                } onToggle: { task in
                    viewModel.toggleTask(task)
                }
            }

            // Completed Today
            if showCompleted && !done.isEmpty {
                TaskSection(
                    title: "Completed",
                    count: done.count,
                    tasks: done,
                    titleColor: DS.Colors.success
                ) { task in
                    selectedTask = task
                } onToggle: { task in
                    viewModel.toggleTask(task)
                }
            }
        }
        .padding(.bottom, 100) // tab bar clearance
    }
}

// MARK: - TaskSection

struct TaskSection: View {
    let title: String
    let count: Int
    let tasks: [Task]
    var titleColor: Color = DS.Colors.secondaryLabel
    var onTap: (Task) -> Void
    var onToggle: (Task) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: title, count: count)
                .foregroundStyle(titleColor)

            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TaskRow(task: task) {
                        onToggle(task)
                    } onTap: {
                        onTap(task)
                    }

                    if task.id != tasks.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(DS.Colors.secondaryBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .padding(.horizontal, DS.Spacing.md)
        }
    }
}

// FilterChip → defined in DesignSystem/Components/Sheets.swift

#Preview {
    TodayView()
        .modelContainer(for: [Task.self, Project.self, Tag.self, Subtask.self], inMemory: true)
        .environment(ThemeManager.shared)
}
