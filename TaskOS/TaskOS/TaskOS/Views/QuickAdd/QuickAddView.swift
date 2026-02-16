import SwiftUI
import SwiftData

// MARK: - QuickAddView
// Fast task capture sheet — optimized for speed, minimal friction

struct QuickAddView: View {
    var defaultProject: Project? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Project> { !$0.isArchived }) private var projects: [Project]
    @Query private var tags: [Tag]

    @State private var title        = ""
    @State private var notes        = ""
    @State private var dueDate: Date? = nil
    @State private var priority: Priority = .none
    @State private var selectedProject: Project? = nil
    @State private var selectedTags: [Tag] = []
    @State private var showDatePicker   = false
    @State private var showProjectPicker = false
    @State private var showTagPicker    = false
    @State private var showExpanded     = false

    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main input
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    TextField("What needs to be done?", text: $title, axis: .vertical)
                        .font(.system(size: 18, weight: .medium))
                        .focused($titleFocused)
                        .lineLimit(1...5)
                        .onSubmit { saveTask() }

                    if showExpanded {
                        TextField("Notes...", text: $notes, axis: .vertical)
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.secondaryLabel)
                            .lineLimit(2...4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(DS.Spacing.md)

                Divider()

                // Attribute pills row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.xs) {
                        // Due date
                        AttributePill(
                            icon: "calendar",
                            label: dueDate.map { $0.taskRowDateLabel } ?? "Date",
                            isActive: dueDate != nil,
                            activeColor: dueDate != nil ? DS.Colors.accent : nil
                        ) {
                            showDatePicker = true
                        }
                        .popover(isPresented: $showDatePicker) {
                            quickDatePicker
                                .frame(width: 320)
                                .presentationCompactAdaptation(.popover)
                        }

                        // Priority
                        AttributePill(
                            icon: priority == .none ? "flag" : priority.sfSymbol,
                            label: priority == .none ? "Priority" : priority.label,
                            isActive: priority != .none,
                            activeColor: priority.color
                        ) {}
                        .contextMenu {
                            ForEach(Priority.allCases, id: \.rawValue) { p in
                                Button {
                                    priority = p
                                } label: {
                                    Label(p.label, systemImage: p.sfSymbol)
                                }
                            }
                        }

                        // Project
                        AttributePill(
                            icon: selectedProject?.iconName.sfSymbol ?? "folder",
                            label: selectedProject?.name ?? "Inbox",
                            isActive: selectedProject != nil,
                            activeColor: selectedProject?.colorName.color
                        ) {
                            showProjectPicker = true
                        }
                        .sheet(isPresented: $showProjectPicker) {
                            ProjectPickerSheet(selectedProject: $selectedProject, projects: projects)
                                .presentationDetents([.medium])
                                .presentationCornerRadius(DS.Radius.lg)
                        }

                        // Tags
                        AttributePill(
                            icon: "tag",
                            label: selectedTags.isEmpty ? "Tag" : selectedTags.map(\.name).joined(separator: ", "),
                            isActive: !selectedTags.isEmpty,
                            activeColor: selectedTags.first.map { Color(hex: $0.colorName) ?? .purple }
                        ) {
                            showTagPicker = true
                        }

                        // Expand/Notes toggle
                        AttributePill(
                            icon: showExpanded ? "chevron.up" : "note.text",
                            label: showExpanded ? "Less" : "Notes",
                            isActive: showExpanded || !notes.isEmpty
                        ) {
                            withAnimation(DS.Animation.quick) {
                                showExpanded.toggle()
                                if showExpanded { titleFocused = false }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                }

                Divider()

                Spacer()
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DS.Colors.secondaryLabel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTask() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                selectedProject = defaultProject
                titleFocused = true
            }
        }
    }

    // MARK: - Quick Date Picker

    private var quickDatePicker: some View {
        VStack(spacing: 0) {
            // Quick presets
            ForEach(quickDateOptions, id: \.label) { option in
                Button {
                    dueDate = option.date
                    showDatePicker = false
                } label: {
                    HStack {
                        Image(systemName: option.icon)
                            .frame(width: 20)
                            .foregroundStyle(DS.Colors.accent)
                        Text(option.label)
                            .foregroundStyle(DS.Colors.label)
                        Spacer()
                        if let date = option.date {
                            Text(date.taskRowDateLabel)
                                .font(DS.Typography.caption1)
                                .foregroundStyle(DS.Colors.secondaryLabel)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                }
                .buttonStyle(.plain)
                Divider()
            }

            if dueDate != nil {
                Button {
                    dueDate = nil
                    showDatePicker = false
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle").foregroundStyle(DS.Colors.destructive)
                        Text("Clear Date").foregroundStyle(DS.Colors.destructive)
                        Spacer()
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .background(DS.Colors.secondaryBG)
    }

    private var quickDateOptions: [(label: String, icon: String, date: Date?)] {
        let cal = Calendar.current
        return [
            ("Today",     "sun.max",        cal.startOfDay(for: Date())),
            ("Tomorrow",  "sunrise",        cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))),
            ("This Week", "calendar.badge.clock", cal.date(byAdding: .day, value: 7, to: Date())),
            ("Next Week", "forward.end",    cal.date(byAdding: .weekOfYear, value: 1, to: Date()))
        ]
    }

    // MARK: - Save

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let task = TaskItem(
            title: trimmed,
            notes: notes,
            isInInbox: selectedProject == nil,
            dueDate: dueDate,
            priority: priority,
            project: selectedProject
        )
        task.tags = selectedTags
        context.insert(task)
        dismiss()
    }
}

// MARK: - AttributePill

struct AttributePill: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    var activeColor: Color? = nil
    let action: () -> Void

    var displayColor: Color {
        if isActive { return activeColor ?? DS.Colors.accent }
        return DS.Colors.secondaryLabel
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption.weight(.medium))
                Text(label)
                    .font(DS.Typography.footnote)
                    .lineLimit(1)
            }
            .foregroundStyle(isActive ? displayColor : DS.Colors.secondaryLabel)
            .padding(.horizontal, DS.Spacing.xs)
            .padding(.vertical, DS.Spacing.xxs + 2)
            .background(
                isActive
                    ? displayColor.opacity(0.12)
                    : DS.Colors.secondaryBG
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    isActive ? displayColor.opacity(0.3) : DS.Colors.separator,
                    lineWidth: 0.5
                )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickAddView()
        .modelContainer(for: [TaskItem.self, Project.self, Tag.self, Subtask.self], inMemory: true)
        .environment(ThemeManager.shared)
}
