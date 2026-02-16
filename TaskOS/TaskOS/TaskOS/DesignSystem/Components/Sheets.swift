import SwiftUI
import SwiftData

// MARK: - Shared sheet components used across multiple views.
// Centralised here so QuickAddView, TaskDetailView, etc. all use
// the same implementations without duplication.

// MARK: - ProjectPickerSheet

struct ProjectPickerSheet: View {
    @Binding var selectedProject: Project?
    let projects: [Project]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Inbox (no project)
                Button {
                    selectedProject = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "tray.fill")
                            .foregroundStyle(DS.Colors.secondaryLabel)
                            .frame(width: 24)
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
                                .frame(width: 24)
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
                        Stepper(
                            "Every \(interval) \(frequency?.rawValue.lowercased() ?? "")s",
                            value: $interval,
                            in: 1...30
                        )
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

// MARK: - FilterChip
// Single source of truth — used in TodayView, SearchView, and anywhere else.

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DS.Typography.footnote)
                .foregroundStyle(isSelected ? .white : DS.Colors.secondaryLabel)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xxs + 2)
                .background(isSelected ? DS.Colors.accent : DS.Colors.secondaryBG)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
