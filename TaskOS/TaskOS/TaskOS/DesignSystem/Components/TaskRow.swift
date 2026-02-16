import SwiftUI

// MARK: - TaskRow
// The core reusable cell used in every task list in the app.

struct TaskRow: View {
    let task: Task
    var onToggle: () -> Void
    var onTap: () -> Void

    @State private var checkScale: CGFloat = 1.0

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                // Completion circle
                completionButton

                // Content
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    titleRow
                    metaRow
                }

                Spacer(minLength: 0)

                // Priority flag (if set)
                if task.priority != .none {
                    Image(systemName: task.priority.sfSymbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(task.priority.color)
                }
            }
            .padding(.vertical, DS.Spacing.xs)
            .padding(.horizontal, DS.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(TaskRowButtonStyle())
    }

    // MARK: - Subviews

    private var completionButton: some View {
        Button(action: {
            withAnimation(DS.Animation.bouncy) {
                checkScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(DS.Animation.quick) {
                    checkScale = 1.0
                }
            }
            onToggle()
        }) {
            ZStack {
                Circle()
                    .strokeBorder(
                        task.isCompleted ? Color.clear : priorityCircleColor,
                        lineWidth: 1.5
                    )
                    .background(
                        Circle().fill(task.isCompleted ? DS.Colors.accent : Color.clear)
                    )
                    .frame(width: 22, height: 22)

                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(checkScale)
        }
        .buttonStyle(.plain)
        .padding(.top, 1)
    }

    private var titleRow: some View {
        Text(task.title)
            .font(DS.Typography.body)
            .foregroundStyle(task.isCompleted ? DS.Colors.tertiaryLabel : DS.Colors.label)
            .strikethrough(task.isCompleted, color: DS.Colors.tertiaryLabel)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }

    private var metaRow: some View {
        HStack(spacing: DS.Spacing.xs) {
            // Due date
            if let due = task.dueDate {
                HStack(spacing: 3) {
                    Image(systemName: task.isOverdue ? "exclamationmark.circle.fill" : "calendar")
                        .font(.caption2)
                    Text(due.taskRowDateLabel)
                        .font(DS.Typography.caption1)
                }
                .foregroundStyle(task.isOverdue ? DS.Colors.overdue : DS.Colors.secondaryLabel)
            }

            // Project chip
            if let project = task.project {
                HStack(spacing: 3) {
                    Circle()
                        .fill(project.colorName.color)
                        .frame(width: 6, height: 6)
                    Text(project.name)
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colors.secondaryLabel)
                }
            }

            // Subtasks indicator
            if !task.subtasks.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "checklist")
                        .font(.caption2)
                    Text("\(task.completedSubtasks)/\(task.subtasks.count)")
                        .font(DS.Typography.caption1)
                }
                .foregroundStyle(DS.Colors.secondaryLabel)
            }

            // Tags
            ForEach(task.tags.prefix(2)) { tag in
                TagChip(tag: tag, size: .small)
            }
        }
    }

    private var priorityCircleColor: Color {
        switch task.priority {
        case .high:   return DS.Colors.priorityHigh
        case .medium: return DS.Colors.priorityMedium
        case .low:    return DS.Colors.priorityLow
        case .none:   return DS.Colors.separator
        }
    }
}

// MARK: - TaskRowButtonStyle

struct TaskRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? DS.Colors.secondaryBG : Color.clear)
            .animation(DS.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Date Label Helper

extension Date {
    var taskRowDateLabel: String {
        if Calendar.current.isDateInToday(self)     { return "Today" }
        if Calendar.current.isDateInTomorrow(self)  { return "Tomorrow" }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
            ? "MMM d"
            : "MMM d, yyyy"
        return formatter.string(from: self)
    }
}

// MARK: - Preview

#Preview {
    let task = Task(title: "Review design mockups", notes: "Check Figma", dueDate: Date())
    task.priority = .high
    return List {
        TaskRow(task: task, onToggle: {}, onTap: {})
        TaskRow(task: task, onToggle: {}, onTap: {})
    }
    .listStyle(.plain)
}
