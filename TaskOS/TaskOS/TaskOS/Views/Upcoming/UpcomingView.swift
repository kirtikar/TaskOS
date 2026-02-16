import SwiftUI
import SwiftData

// MARK: - UpcomingView
// Shows tasks grouped by due date for the next 14 days + a "Later" bucket.

struct UpcomingView: View {
    @Query(
        filter: #Predicate<TaskItem> { !$0.isCompleted && $0.dueDate != nil },
        sort: \TaskItem.dueDate
    ) private var scheduledTasks: [TaskItem]

    @Query(
        filter: #Predicate<TaskItem> { $0.isCompleted && $0.dueDate != nil },
        sort: \TaskItem.completedAt
    ) private var completedTasks: [TaskItem]

    @Environment(\.modelContext) private var context
    @State private var selectedTask: TaskItem?
    @State private var showCompleted = false

    // MARK: - Computed groups

    private var groups: [DayGroup] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let horizon = cal.date(byAdding: .day, value: 14, to: today)!

        var buckets: [Date: [TaskItem]] = [:]
        var later: [TaskItem] = []
        var overdue: [TaskItem] = []

        for task in scheduledTasks {
            guard let due = task.dueDate else { continue }
            let day = cal.startOfDay(for: due)
            if day < today {
                overdue.append(task)
            } else if day <= horizon {
                buckets[day, default: []].append(task)
            } else {
                later.append(task)
            }
        }

        var result: [DayGroup] = []

        if !overdue.isEmpty {
            result.append(DayGroup(date: nil, label: "Overdue", tasks: overdue, isOverdue: true))
        }

        // Sort days
        for day in buckets.keys.sorted() {
            result.append(DayGroup(date: day, label: dayLabel(day), tasks: buckets[day]!))
        }

        if !later.isEmpty {
            result.append(DayGroup(date: nil, label: "Later", tasks: later.sorted {
                ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }))
        }

        return result
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    upcomingEmpty
                } else {
                    upcomingList
                }
            }
            .background(DS.Colors.groupedBG)
            .navigationTitle("Upcoming")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(DS.Animation.quick) { showCompleted.toggle() }
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

    // MARK: - List

    private var upcomingList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DS.Spacing.sm, pinnedViews: [.sectionHeaders]) {
                ForEach(groups) { group in
                    Section {
                        VStack(spacing: 0) {
                            ForEach(group.tasks) { task in
                                TaskRow(task: task) {
                                    toggleTask(task)
                                } onTap: {
                                    selectedTask = task
                                }

                                if task.id != group.tasks.last?.id {
                                    Divider().padding(.leading, 52)
                                }
                            }
                        }
                        .background(DS.Colors.secondaryBG)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                        .padding(.horizontal, DS.Spacing.md)
                    } header: {
                        upcomingHeader(group)
                    }
                }

                if showCompleted {
                    completedSection
                }

                Spacer().frame(height: 100)
            }
            .padding(.top, DS.Spacing.xs)
        }
    }

    // MARK: - Section Header

    private func upcomingHeader(_ group: DayGroup) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            // Day number badge (for real dates)
            if let date = group.date {
                let cal = Calendar.current
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.xs)
                        .fill(cal.isDateInToday(date) ? DS.Colors.accent : DS.Colors.secondaryBG)
                        .frame(width: 36, height: 36)
                    VStack(spacing: 0) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(cal.isDateInToday(date) ? .white : DS.Colors.tertiaryLabel)
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(cal.isDateInToday(date) ? .white : DS.Colors.label)
                    }
                }
            } else {
                // Overdue / Later badge
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.xs)
                        .fill(group.isOverdue ? DS.Colors.overdue.opacity(0.12) : DS.Colors.tertiaryBG)
                        .frame(width: 36, height: 36)
                    Image(systemName: group.isOverdue ? "exclamationmark.triangle.fill" : "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(group.isOverdue ? DS.Colors.overdue : DS.Colors.tertiaryLabel)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(group.label)
                    .font(DS.Typography.headline)
                    .foregroundStyle(group.isOverdue ? DS.Colors.overdue : DS.Colors.label)
                if let date = group.date {
                    Text(date.formatted(.dateTime.month(.wide).day().year()))
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colors.secondaryLabel)
                }
            }

            Spacer()

            Text("\(group.tasks.count)")
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colors.tertiaryLabel)
                .padding(.horizontal, DS.Spacing.xs)
                .padding(.vertical, 3)
                .background(DS.Colors.tertiaryBG)
                .clipShape(Capsule())
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.xs)
        .background(DS.Colors.groupedBG)
    }

    // MARK: - Completed Section

    private var completedSection: some View {
        let recent = completedTasks
            .filter { task in
                guard let due = task.dueDate else { return false }
                return Calendar.current.isDate(due, equalTo: Date(), toGranularity: .weekOfYear)
            }
            .prefix(10)

        return Group {
            if !recent.isEmpty {
                Section {
                    VStack(spacing: 0) {
                        ForEach(Array(recent)) { task in
                            TaskRow(task: task) { toggleTask(task) } onTap: { selectedTask = task }
                            if task.id != recent.last?.id {
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                    .background(DS.Colors.secondaryBG)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .padding(.horizontal, DS.Spacing.md)
                } header: {
                    SectionHeader(title: "Completed this week", count: recent.count)
                        .padding(.horizontal, DS.Spacing.md)
                        .background(DS.Colors.groupedBG)
                }
            }
        }
    }

    // MARK: - Empty State

    private var upcomingEmpty: some View {
        EmptyStateView(
            sfSymbol: "calendar.badge.checkmark",
            title: "No Upcoming Tasks",
            message: "Tasks with due dates will appear here, organized by day.",
            actionLabel: nil
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func toggleTask(_ task: TaskItem) {
        withAnimation(DS.Animation.quick) {
            task.isCompleted.toggle()
            task.completedAt = task.isCompleted ? Date() : nil
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)    { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.wide))
    }
}

// MARK: - DayGroup

private struct DayGroup: Identifiable {
    let id = UUID()
    let date: Date?
    let label: String
    let tasks: [TaskItem]
    var isOverdue: Bool = false
}

// MARK: - Preview

#Preview {
    UpcomingView()
        .modelContainer(for: [TaskItem.self, Project.self, Tag.self, Subtask.self], inMemory: true)
        .environment(ThemeManager.shared)
}
