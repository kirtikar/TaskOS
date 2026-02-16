import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskDetailViewModel {
    var showDatePicker    = false
    var showReminderPicker = false
    var showProjectPicker = false
    var showTagPicker     = false
    var showRepeatPicker  = false
    var newSubtaskTitle   = ""
    var isSaving          = false

    func addSubtask(to task: Task, context: ModelContext) {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let subtask = Subtask(title: trimmed, order: task.subtasks.count)
        context.insert(subtask)
        task.subtasks.append(subtask)
        newSubtaskTitle = ""
    }

    func deleteSubtask(_ subtask: Subtask, from task: Task, context: ModelContext) {
        task.subtasks.removeAll { $0.id == subtask.id }
        context.delete(subtask)
    }

    func toggleSubtask(_ subtask: Subtask) {
        withAnimation(DS.Animation.quick) {
            subtask.isCompleted.toggle()
        }
    }

    func clearDueDate(from task: Task) {
        task.dueDate = nil
        task.reminderDate = nil
    }

    func clearReminder(from task: Task) {
        task.reminderDate = nil
    }

    func scheduleReminder(for task: Task, notificationService: NotificationService) {
        guard let reminder = task.reminderDate else { return }
        Task {
            await notificationService.scheduleReminder(
                id: task.id.uuidString,
                title: task.title,
                body: task.notes.isEmpty ? "Tap to open" : task.notes,
                date: reminder
            )
        }
    }

    func dueDateLabel(_ date: Date?) -> String {
        guard let date else { return "No Date" }
        return date.taskRowDateLabel
    }

    func reminderLabel(_ date: Date?) -> String {
        guard let date else { return "No Reminder" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func repeatLabel(_ freq: RepeatFrequency?, interval: Int) -> String {
        guard let freq else { return "Never" }
        if interval == 1 { return freq.rawValue }
        return "Every \(interval) \(freq.rawValue.lowercased())s"
    }
}
