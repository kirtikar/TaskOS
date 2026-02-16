import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: Task
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var projects: [Project]
    @Query private var tags: [Tag]

    @State private var viewModel = TaskDetailViewModel()
    @State private var notificationService = NotificationService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Title + complete button
                titleSection

                Divider().padding(.horizontal, DS.Spacing.md)

                // Notes
                notesSection

                Divider().padding(.horizontal, DS.Spacing.md)

                // Metadata rows
                metaSection

                Divider().padding(.horizontal, DS.Spacing.md)

                // Subtasks
                subtasksSection
            }
        }
        .background(DS.Colors.groupedBG)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        withAnimation(DS.Animation.quick) {
                            task.isCompleted.toggle()
                            task.completedAt = task.isCompleted ? Date() : nil
                        }
                    } label: {
                        Label(
                            task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                            systemImage: task.isCompleted ? "xmark.circle" : "checkmark.circle"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        context.delete(task)
                        dismiss()
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(DS.Colors.accent)
                }
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            // Completion toggle
            Button {
                withAnimation(DS.Animation.bouncy) {
                    task.isCompleted.toggle()
                    task.completedAt = task.isCompleted ? Date() : nil
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? Color.clear : DS.Colors.accent,
                            lineWidth: 2
                        )
                        .background(
                            Circle().fill(task.isCompleted ? DS.Colors.accent : Color.clear)
                        )
                        .frame(width: 26, height: 26)

                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, DS.Spacing.lg + 2)

            TextField("Task title", text: $task.title, axis: .vertical)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(task.isCompleted ? DS.Colors.secondaryLabel : DS.Colors.label)
                .strikethrough(task.isCompleted, color: DS.Colors.tertiaryLabel)
                .padding(.vertical, DS.Spacing.lg)
        }
        .padding(.horizontal, DS.Spacing.md)
        .background(DS.Colors.secondaryBG)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        TextField(
            "Add notes...",
            text: $task.notes,
            axis: .vertical
        )
        .font(DS.Typography.body)
        .foregroundStyle(DS.Colors.label)
        .lineLimit(3...)
        .padding(DS.Spacing.md)
        .background(DS.Colors.secondaryBG)
    }

    // MARK: - Meta Section

    private var metaSection: some View {
        VStack(spacing: 0) {
            // Due Date
            DetailRow(
                icon: "calendar",
                iconColor: DS.Colors.accent,
                label: "Due Date"
            ) {
                HStack {
                    Text(viewModel.dueDateLabel(task.dueDate))
                        .font(DS.Typography.body)
                        .foregroundStyle(
                            task.dueDate == nil ? DS.Colors.tertiaryLabel :
                            task.isOverdue ? DS.Colors.overdue : DS.Colors.label
                        )
                    if task.dueDate != nil {
                        Button {
                            viewModel.clearDueDate(from: task)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(DS.Colors.tertiaryLabel)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } action: {
                viewModel.showDatePicker.toggle()
            }
            .sheet(isPresented: $viewModel.showDatePicker) {
                DatePickerSheet(selectedDate: Binding(
                    get: { task.dueDate ?? Date() },
                    set: { task.dueDate = $0 }
                ), title: "Due Date", showTime: false)
                .presentationDetents([.medium])
                .presentationCornerRadius(DS.Radius.lg)
            }

            Divider().padding(.leading, 52)

            // Reminder
            DetailRow(
                icon: "bell.fill",
                iconColor: .orange,
                label: "Reminder"
            ) {
                Text(viewModel.reminderLabel(task.reminderDate))
                    .font(DS.Typography.body)
                    .foregroundStyle(
                        task.reminderDate == nil ? DS.Colors.tertiaryLabel : DS.Colors.label
                    )
            } action: {
                viewModel.showReminderPicker.toggle()
            }
            .sheet(isPresented: $viewModel.showReminderPicker) {
                DatePickerSheet(selectedDate: Binding(
                    get: { task.reminderDate ?? Date() },
                    set: {
                        task.reminderDate = $0
                        viewModel.scheduleReminder(for: task, notificationService: notificationService)
                    }
                ), title: "Reminder", showTime: true)
                .presentationDetents([.medium])
                .presentationCornerRadius(DS.Radius.lg)
            }

            Divider().padding(.leading, 52)

            // Priority
            DetailRow(
                icon: "exclamationmark.3",
                iconColor: .red,
                label: "Priority"
            ) {
                PriorityBadge(priority: task.priority, showLabel: true)
            } action: {}
            .contextMenu {
                ForEach(Priority.allCases, id: \.rawValue) { p in
                    Button {
                        task.priority = p
                    } label: {
                        Label(p.label, systemImage: p.sfSymbol)
                    }
                }
            }

            Divider().padding(.leading, 52)

            // Project
            DetailRow(
                icon: "folder.fill",
                iconColor: task.project?.colorName.color ?? DS.Colors.tertiaryLabel,
                label: "Project"
            ) {
                Text(task.project?.name ?? "Inbox")
                    .font(DS.Typography.body)
                    .foregroundStyle(
                        task.project == nil ? DS.Colors.tertiaryLabel : DS.Colors.label
                    )
            } action: {
                viewModel.showProjectPicker = true
            }
            .sheet(isPresented: $viewModel.showProjectPicker) {
                ProjectPickerSheet(selectedProject: $task.project, projects: projects)
                    .presentationDetents([.medium])
                    .presentationCornerRadius(DS.Radius.lg)
            }

            Divider().padding(.leading, 52)

            // Tags
            DetailRow(
                icon: "tag.fill",
                iconColor: .purple,
                label: "Tags"
            ) {
                if task.tags.isEmpty {
                    Text("None")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.tertiaryLabel)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(task.tags) { tag in
                                TagChip(tag: tag, size: .small) {
                                    task.tags.removeAll { $0.id == tag.id }
                                }
                            }
                        }
                    }
                }
            } action: {
                viewModel.showTagPicker = true
            }

            Divider().padding(.leading, 52)

            // Repeat
            DetailRow(
                icon: "repeat",
                iconColor: .green,
                label: "Repeat"
            ) {
                Text(viewModel.repeatLabel(task.repeatFrequency, interval: task.repeatInterval))
                    .font(DS.Typography.body)
                    .foregroundStyle(
                        task.repeatFrequency == nil ? DS.Colors.tertiaryLabel : DS.Colors.label
                    )
            } action: {
                viewModel.showRepeatPicker.toggle()
            }
            .sheet(isPresented: $viewModel.showRepeatPicker) {
                RepeatPickerSheet(
                    frequency: $task.repeatFrequency,
                    interval: $task.repeatInterval
                )
                .presentationDetents([.medium])
                .presentationCornerRadius(DS.Radius.lg)
            }
        }
        .background(DS.Colors.secondaryBG)
    }

    // MARK: - Subtasks Section

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Subtasks", count: task.subtasks.count)

            VStack(spacing: 0) {
                ForEach(task.subtasks.sorted(by: { $0.order < $1.order })) { subtask in
                    SubtaskRow(subtask: subtask) {
                        viewModel.toggleSubtask(subtask)
                    } onDelete: {
                        viewModel.deleteSubtask(subtask, from: task, context: context)
                    }

                    Divider().padding(.leading, 40)
                }

                // Add subtask row
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(DS.Colors.accent)

                    TextField("Add subtask...", text: $viewModel.newSubtaskTitle)
                        .font(DS.Typography.body)
                        .onSubmit {
                            viewModel.addSubtask(to: task, context: context)
                        }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
            }
            .background(DS.Colors.secondaryBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .padding(.horizontal, DS.Spacing.md)
        }
        .padding(.top, DS.Spacing.sm)
    }
}

// MARK: - DetailRow

struct DetailRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let label: String
    @ViewBuilder let value: Content
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.xs - 2)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(iconColor)
                }

                Text(label)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.label)

                Spacer()

                value

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.Colors.tertiaryLabel)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SubtaskRow

struct SubtaskRow: View {
    @Bindable var subtask: Subtask
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Button(action: onToggle) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(subtask.isCompleted ? DS.Colors.success : DS.Colors.separator)
            }
            .buttonStyle(.plain)

            TextField("Subtask", text: $subtask.title)
                .font(DS.Typography.body)
                .foregroundStyle(subtask.isCompleted ? DS.Colors.tertiaryLabel : DS.Colors.label)
                .strikethrough(subtask.isCompleted, color: DS.Colors.tertiaryLabel)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(DS.Colors.tertiaryLabel)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.xs)
    }
}

// MARK: - DatePickerSheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let title: String
    let showTime: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: showTime ? [.date, .hourAndMinute] : [.date]
            )
            .datePickerStyle(.graphical)
            .tint(DS.Colors.accent)
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - ProjectPickerSheet

struct ProjectPickerSheet: View {
    @Binding var selectedProject: Project?
    let projects: [Project]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedProject = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "tray.fill")
                            .foregroundStyle(DS.Colors.secondaryLabel)
                        Text("Inbox")
                            .foregroundStyle(DS.Colors.label)
                        Spacer()
                        if selectedProject == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(DS.Colors.accent)
                        }
                    }
                }
                .buttonStyle(.plain)

                ForEach(projects.filter { !$0.isArchived }) { project in
                    Button {
                        selectedProject = project
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: project.iconName.sfSymbol)
                                .foregroundStyle(project.colorName.color)
                            Text(project.name)
                                .foregroundStyle(DS.Colors.label)
                            Spacer()
                            if selectedProject?.id == project.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DS.Colors.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Move to Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - RepeatPickerSheet

struct RepeatPickerSheet: View {
    @Binding var frequency: RepeatFrequency?
    @Binding var interval: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        frequency = nil
                        interval = 1
                        dismiss()
                    } label: {
                        HStack {
                            Text("Never")
                                .foregroundStyle(DS.Colors.label)
                            Spacer()
                            if frequency == nil {
                                Image(systemName: "checkmark").foregroundStyle(DS.Colors.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    ForEach(RepeatFrequency.allCases, id: \.rawValue) { freq in
                        Button {
                            frequency = freq
                            dismiss()
                        } label: {
                            HStack {
                                Text(freq.rawValue)
                                    .foregroundStyle(DS.Colors.label)
                                Spacer()
                                if frequency == freq {
                                    Image(systemName: "checkmark").foregroundStyle(DS.Colors.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if frequency != nil {
                    Section("Interval") {
                        Stepper("Every \(interval) \(frequency?.rawValue.lowercased() ?? "")s", value: $interval, in: 1...30)
                    }
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let task = Task(title: "Design the new homepage", notes: "Check with team first")
    task.priority = .high
    task.dueDate = Date()
    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(for: [Task.self, Project.self, Tag.self, Subtask.self], inMemory: true)
    .environment(ThemeManager.shared)
}
