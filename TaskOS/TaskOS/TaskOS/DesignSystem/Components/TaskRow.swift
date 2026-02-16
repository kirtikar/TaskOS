import SwiftUI

// MARK: - TaskRow
// Core reusable cell. Features a satisfying Things 3-style completion animation.

struct TaskRow: View {
    let task: TaskItem
    var onToggle: () -> Void
    var onTap: () -> Void

    // Animation state
    @State private var checkScale: CGFloat = 1.0
    @State private var checkOpacity: Double = 1.0
    @State private var rowOpacity: Double = 1.0
    @State private var particlesVisible = false

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                completionButton
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    titleRow
                    metaRow
                }
                Spacer(minLength: 0)
                if task.priority != .none {
                    Image(systemName: task.priority.sfSymbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(task.priority.color)
                }
            }
            .padding(.vertical, DS.Spacing.xs)
            .padding(.horizontal, DS.Spacing.md)
            .contentShape(Rectangle())
            .opacity(rowOpacity)
        }
        .buttonStyle(TaskRowButtonStyle())
        .onChange(of: task.isCompleted) { _, completed in
            if completed { playCompletionAnimation() }
            else { resetAnimation() }
        }
    }

    // MARK: - Completion Button

    private var completionButton: some View {
        ZStack {
            // Completion circle
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
                    .transition(.scale.combined(with: .opacity))
            }

            // Burst particles (shows briefly on completion)
            if particlesVisible {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(DS.Colors.accent.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .offset(burstOffset(index: i, radius: 14))
                        .opacity(particlesVisible ? 0 : 1)
                }
            }
        }
        .scaleEffect(checkScale)
        .opacity(checkOpacity)
        .frame(width: 22, height: 22)
        .onTapGesture {
            onToggle()
        }
        .padding(.top, 1)
    }

    // MARK: - Title Row

    private var titleRow: some View {
        Text(task.title)
            .font(DS.Typography.body)
            .foregroundStyle(task.isCompleted ? DS.Colors.tertiaryLabel : DS.Colors.label)
            .strikethrough(task.isCompleted, color: DS.Colors.tertiaryLabel)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .animation(DS.Animation.quick, value: task.isCompleted)
    }

    // MARK: - Meta Row

    private var metaRow: some View {
        HStack(spacing: DS.Spacing.xs) {
            if let due = task.dueDate {
                HStack(spacing: 3) {
                    Image(systemName: task.isOverdue ? "exclamationmark.circle.fill" : "calendar")
                        .font(.caption2)
                    Text(due.taskRowDateLabel)
                        .font(DS.Typography.caption1)
                }
                .foregroundStyle(task.isOverdue ? DS.Colors.overdue : DS.Colors.secondaryLabel)
            }

            if let project = task.project {
                HStack(spacing: 3) {
                    Circle().fill(project.colorName.color).frame(width: 6, height: 6)
                    Text(project.name)
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colors.secondaryLabel)
                }
            }

            if !task.subtasks.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "checklist").font(.caption2)
                    Text("\(task.completedSubtasks)/\(task.subtasks.count)")
                        .font(DS.Typography.caption1)
                }
                .foregroundStyle(DS.Colors.secondaryLabel)
            }

            if task.isSomeday {
                HStack(spacing: 3) {
                    Image(systemName: "moon.fill").font(.caption2)
                    Text("Someday")
                        .font(DS.Typography.caption1)
                }
                .foregroundStyle(.indigo.opacity(0.7))
            }

            ForEach(task.tags.prefix(2)) { tag in
                TagChip(tag: tag, size: .small)
            }
        }
    }

    // MARK: - Priority circle color

    private var priorityCircleColor: Color {
        switch task.priority {
        case .high:   return DS.Colors.priorityHigh
        case .medium: return DS.Colors.priorityMedium
        case .low:    return DS.Colors.priorityLow
        case .none:   return DS.Colors.separator
        }
    }

    // MARK: - Completion Animation

    private func playCompletionAnimation() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // 1. Scale up the check
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            checkScale = 1.35
            particlesVisible = true
        }

        // 2. Scale back and show particles fading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                checkScale = 1.0
            }
        }

        // 3. Fade out particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                particlesVisible = false
            }
        }

        // 4. Gently dim the row
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                rowOpacity = 0.5
            }
        }
    }

    private func resetAnimation() {
        withAnimation(DS.Animation.quick) {
            rowOpacity = 1.0
            checkScale = 1.0
            checkOpacity = 1.0
            particlesVisible = false
        }
    }

    // MARK: - Burst offset helper

    private func burstOffset(index: Int, radius: CGFloat) -> CGSize {
        let angle = Double(index) * (360.0 / 6.0) * .pi / 180
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
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
            ? "MMM d" : "MMM d, yyyy"
        return formatter.string(from: self)
    }
}

// MARK: - Preview

#Preview {
    let task = TaskItem(title: "Review design mockups", notes: "Check Figma", dueDate: Date())
    task.priority = .high
    return List {
        TaskRow(task: task, onToggle: {}, onTap: {})
        TaskRow(task: task, onToggle: {}, onTap: {})
    }
    .listStyle(.plain)
}
