import SwiftUI
import SwiftData

// MARK: - QuickAddView
// Fast task capture with natural-language parsing.
// Type "Buy milk tomorrow #shopping !!" to auto-fill date, tag, priority.

struct QuickAddView: View {
    var defaultProject: Project? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Project> { !$0.isArchived }) private var projects: [Project]
    @Query private var tags: [Tag]

    @State private var title         = ""
    @State private var notes         = ""
    @State private var dueDate: Date?     = nil
    @State private var priority: Priority = .none
    @State private var selectedProject: Project? = nil
    @State private var selectedTags: [Tag]  = []
    @State private var repeatFreq: RepeatFrequency? = nil
    @State private var isSomeday = false

    @State private var showDatePicker    = false
    @State private var showProjectPicker = false
    @State private var showExpanded      = false

    // Parser hint chips
    @State private var parsedHints: [ParseHint] = []

    @FocusState private var titleFocused: Bool

    private let parser = NLParserService()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputArea
                if !parsedHints.isEmpty { hintStrip }
                Divider()
                attributeBar
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
                    Button("Add") { saveTask() }
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

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            TextField("What needs to be done?", text: $title, axis: .vertical)
                .font(.system(size: 18, weight: .medium))
                .focused($titleFocused)
                .lineLimit(1...5)
                .onSubmit { saveTask() }
                .onChange(of: title) { _, newValue in
                    parseHints(from: newValue)
                }

            if showExpanded {
                TextField("Notes...", text: $notes, axis: .vertical)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.secondaryLabel)
                    .lineLimit(2...4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DS.Spacing.md)
    }

    // MARK: - Hint Strip
    // Shows chips for what the parser detected — tap to apply or dismiss.

    private var hintStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(parsedHints) { hint in
                    Button {
                        applyHint(hint)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: hint.icon)
                                .font(.caption.weight(.medium))
                            Text(hint.label)
                                .font(DS.Typography.caption1)
                        }
                        .foregroundStyle(DS.Colors.accent)
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, DS.Spacing.xxs + 2)
                        .background(DS.Colors.accent.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.xs)
        }
        .background(DS.Colors.groupedBG)
    }

    // MARK: - Attribute Bar

    private var attributeBar: some View {
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
                        .frame(width: 300)
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
                        Button { priority = p } label: {
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

                // Repeat
                AttributePill(
                    icon: "repeat",
                    label: repeatFreq?.rawValue ?? "Repeat",
                    isActive: repeatFreq != nil,
                    activeColor: repeatFreq != nil ? .green : nil
                ) {}
                .contextMenu {
                    Button("None") { repeatFreq = nil }
                    Divider()
                    ForEach(RepeatFrequency.allCases, id: \.rawValue) { f in
                        Button(f.rawValue) { repeatFreq = f }
                    }
                }

                // Someday toggle
                AttributePill(
                    icon: isSomeday ? "moon.fill" : "moon",
                    label: "Someday",
                    isActive: isSomeday,
                    activeColor: isSomeday ? .indigo : nil
                ) {
                    withAnimation(DS.Animation.quick) { isSomeday.toggle() }
                }

                // Notes toggle
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
    }

    // MARK: - Quick Date Picker

    private var quickDatePicker: some View {
        VStack(spacing: 0) {
            ForEach(quickDateOptions, id: \.label) { option in
                Button {
                    dueDate = option.date
                    showDatePicker = false
                } label: {
                    HStack {
                        Image(systemName: option.icon).frame(width: 20).foregroundStyle(DS.Colors.accent)
                        Text(option.label).foregroundStyle(DS.Colors.label)
                        Spacer()
                        if let d = option.date {
                            Text(d.taskRowDateLabel)
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
            ("Today",     "sun.max",               cal.startOfDay(for: Date())),
            ("Tomorrow",  "sunrise",                cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))),
            ("This Weekend", "moon.stars",          nextWeekend()),
            ("Next Week", "forward.end",            cal.date(byAdding: .weekOfYear, value: 1, to: Date()))
        ]
    }

    private func nextWeekend() -> Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysToSat = (7 - weekday + 7) % 7
        return cal.date(byAdding: .day, value: daysToSat == 0 ? 7 : daysToSat, to: today)
    }

    // MARK: - NL Parsing

    private func parseHints(from text: String) {
        guard text.count > 2 else { parsedHints = []; return }
        let result = parser.parse(text)
        var hints: [ParseHint] = []

        if let date = result.dueDate {
            hints.append(ParseHint(id: "date", icon: "calendar",
                                   label: "Set due: \(date.taskRowDateLabel)") {
                dueDate = date
            })
        }
        if result.priority != .none {
            hints.append(ParseHint(id: "priority", icon: result.priority.sfSymbol,
                                   label: result.priority.label + " priority") {
                priority = result.priority
            })
        }
        for tagName in result.tagNames {
            let existing = tags.first { $0.name.lowercased() == tagName.lowercased() }
            if let tag = existing, !selectedTags.contains(where: { $0.id == tag.id }) {
                hints.append(ParseHint(id: "tag_\(tagName)", icon: "tag",
                                       label: "#\(tag.name)") {
                    selectedTags.append(tag)
                })
            }
        }
        if result.isSomeday {
            hints.append(ParseHint(id: "someday", icon: "moon", label: "Mark Someday") {
                isSomeday = true
            })
        }
        withAnimation(DS.Animation.quick) { parsedHints = hints }
    }

    private func applyHint(_ hint: ParseHint) {
        hint.action()
        withAnimation(DS.Animation.quick) {
            parsedHints.removeAll { $0.id == hint.id }
        }
        // Clean the matched token from the title
        let cleaned = parser.parse(title)
        if !cleaned.title.isEmpty { title = cleaned.title }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Save

    private func saveTask() {
        var finalTitle = title.trimmingCharacters(in: .whitespaces)
        guard !finalTitle.isEmpty else { return }

        // Auto-apply any remaining unacknowledged hints
        let result = parser.parse(finalTitle)
        finalTitle = result.title.isEmpty ? finalTitle : result.title
        if dueDate == nil { dueDate = result.dueDate }
        if priority == .none { priority = result.priority }
        if repeatFreq == nil { repeatFreq = result.repeatFrequency }

        let task = TaskItem(
            title: finalTitle,
            notes: notes,
            isInInbox: selectedProject == nil,
            isSomeday: isSomeday,
            dueDate: dueDate,
            priority: priority,
            project: selectedProject
        )
        task.tags = selectedTags
        task.repeatFrequency = repeatFreq
        context.insert(task)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - ParseHint

private struct ParseHint: Identifiable {
    let id: String
    let icon: String
    let label: String
    let action: () -> Void
}

// MARK: - AttributePill

struct AttributePill: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    var activeColor: Color? = nil
    let action: () -> Void

    var displayColor: Color {
        isActive ? (activeColor ?? DS.Colors.accent) : DS.Colors.secondaryLabel
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
            .background(isActive ? displayColor.opacity(0.12) : DS.Colors.secondaryBG)
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
