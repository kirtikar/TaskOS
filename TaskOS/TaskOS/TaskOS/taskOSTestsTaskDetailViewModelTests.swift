import Testing
import Foundation
import SwiftData
@testable import taskOS

// MARK: - TaskDetailViewModel Tests

@Suite("TaskDetailViewModel")
struct TaskDetailViewModelTests {

    // MARK: - dueDateLabel

    @Test("dueDateLabel returns 'No Date' when date is nil")
    func dueDateLabelNil() {
        let vm = TaskDetailViewModel()
        #expect(vm.dueDateLabel(nil) == "No Date")
    }

    @Test("dueDateLabel returns a non-empty string for a valid date")
    func dueDateLabelNonEmpty() {
        let vm = TaskDetailViewModel()
        let label = vm.dueDateLabel(Date())
        #expect(!label.isEmpty)
    }

    @Test("dueDateLabel returns different strings for different dates")
    func dueDateLabelDifferentDates() {
        let vm = TaskDetailViewModel()
        let today    = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        #expect(vm.dueDateLabel(today) != vm.dueDateLabel(tomorrow))
    }

    // MARK: - reminderLabel

    @Test("reminderLabel returns 'No Reminder' when date is nil")
    func reminderLabelNil() {
        let vm = TaskDetailViewModel()
        #expect(vm.reminderLabel(nil) == "No Reminder")
    }

    @Test("reminderLabel returns a formatted string for a valid date")
    func reminderLabelFormatted() {
        let vm = TaskDetailViewModel()
        let date = Date()
        let label = vm.reminderLabel(date)
        #expect(!label.isEmpty)
        #expect(label != "No Reminder")
    }

    // MARK: - repeatLabel

    @Test("repeatLabel returns 'Never' when frequency is nil")
    func repeatLabelNever() {
        let vm = TaskDetailViewModel()
        #expect(vm.repeatLabel(nil, interval: 1) == "Never")
    }

    @Test("repeatLabel returns frequency rawValue when interval is 1")
    func repeatLabelInterval1() {
        let vm = TaskDetailViewModel()
        #expect(vm.repeatLabel(.daily,   interval: 1) == "Daily")
        #expect(vm.repeatLabel(.weekly,  interval: 1) == "Weekly")
        #expect(vm.repeatLabel(.monthly, interval: 1) == "Monthly")
        #expect(vm.repeatLabel(.yearly,  interval: 1) == "Yearly")
    }

    @Test("repeatLabel returns 'Every N <freq>s' when interval > 1")
    func repeatLabelMultipleIntervals() {
        let vm = TaskDetailViewModel()
        #expect(vm.repeatLabel(.daily,  interval: 3) == "Every 3 dailys")
        #expect(vm.repeatLabel(.weekly, interval: 2) == "Every 2 weeklys")
    }

    // MARK: - clearDueDate

    @Test("clearDueDate sets both dueDate and reminderDate to nil")
    func clearDueDateClearsBoth() {
        let vm = TaskDetailViewModel()
        let task = Task(
            title: "Test",
            dueDate: Date(),
            reminderDate: Date()
        )
        vm.clearDueDate(from: task)
        #expect(task.dueDate == nil)
        #expect(task.reminderDate == nil)
    }

    @Test("clearDueDate is idempotent when dates are already nil")
    func clearDueDateIdempotent() {
        let vm = TaskDetailViewModel()
        let task = Task(title: "Test")
        vm.clearDueDate(from: task)
        #expect(task.dueDate == nil)
        #expect(task.reminderDate == nil)
    }

    // MARK: - clearReminder

    @Test("clearReminder sets only reminderDate to nil")
    func clearReminderOnlyReminder() {
        let vm = TaskDetailViewModel()
        let due = Date()
        let task = Task(title: "Test", dueDate: due, reminderDate: Date())
        vm.clearReminder(from: task)
        #expect(task.reminderDate == nil)
        #expect(task.dueDate == due)
    }

    // MARK: - toggleSubtask

    @Test("toggleSubtask flips isCompleted from false to true")
    func toggleSubtaskFalseToTrue() {
        let vm = TaskDetailViewModel()
        let subtask = Subtask(title: "Step")
        #expect(subtask.isCompleted == false)
        vm.toggleSubtask(subtask)
        #expect(subtask.isCompleted == true)
    }

    @Test("toggleSubtask flips isCompleted from true to false")
    func toggleSubtaskTrueToFalse() {
        let vm = TaskDetailViewModel()
        let subtask = Subtask(title: "Step")
        subtask.isCompleted = true
        vm.toggleSubtask(subtask)
        #expect(subtask.isCompleted == false)
    }

    @Test("toggleSubtask is idempotent over two calls")
    func toggleSubtaskDoubleToggle() {
        let vm = TaskDetailViewModel()
        let subtask = Subtask(title: "Step")
        let initial = subtask.isCompleted
        vm.toggleSubtask(subtask)
        vm.toggleSubtask(subtask)
        #expect(subtask.isCompleted == initial)
    }

    // MARK: - addSubtask / deleteSubtask (in-memory SwiftData)

    @Test("addSubtask appends a new subtask with the current title")
    func addSubtaskAppendsCorrectly() throws {
        let container = try ModelContainer(
            for: Task.self, Subtask.self, Project.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let task = Task(title: "Parent")
        context.insert(task)

        let vm = TaskDetailViewModel()
        vm.newSubtaskTitle = "Write unit tests"
        vm.addSubtask(to: task, context: context)

        #expect(task.subtasks.count == 1)
        #expect(task.subtasks.first?.title == "Write unit tests")
        #expect(vm.newSubtaskTitle == "")
    }

    @Test("addSubtask does nothing for a whitespace-only title")
    func addSubtaskIgnoresWhitespace() throws {
        let container = try ModelContainer(
            for: Task.self, Subtask.self, Project.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let task = Task(title: "Parent")
        context.insert(task)

        let vm = TaskDetailViewModel()
        vm.newSubtaskTitle = "   "
        vm.addSubtask(to: task, context: context)

        #expect(task.subtasks.isEmpty)
    }

    @Test("addSubtask assigns incrementing order values")
    func addSubtaskIncrementingOrder() throws {
        let container = try ModelContainer(
            for: Task.self, Subtask.self, Project.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let task = Task(title: "Parent")
        context.insert(task)

        let vm = TaskDetailViewModel()
        vm.newSubtaskTitle = "First"
        vm.addSubtask(to: task, context: context)

        vm.newSubtaskTitle = "Second"
        vm.addSubtask(to: task, context: context)

        let sorted = task.subtasks.sorted(by: { $0.order < $1.order })
        #expect(sorted[0].title == "First")
        #expect(sorted[0].order == 0)
        #expect(sorted[1].title == "Second")
        #expect(sorted[1].order == 1)
    }

    @Test("deleteSubtask removes the subtask from the parent task")
    func deleteSubtaskRemovesFromTask() throws {
        let container = try ModelContainer(
            for: Task.self, Subtask.self, Project.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let task = Task(title: "Parent")
        context.insert(task)
        let subtask = Subtask(title: "To delete")
        context.insert(subtask)
        task.subtasks.append(subtask)

        let vm = TaskDetailViewModel()
        vm.deleteSubtask(subtask, from: task, context: context)

        #expect(task.subtasks.isEmpty)
    }

    // MARK: - Initial toggle state

    @Test("showDatePicker defaults to false")
    func showDatePickerDefaultsFalse() {
        let vm = TaskDetailViewModel()
        #expect(vm.showDatePicker == false)
    }

    @Test("showReminderPicker defaults to false")
    func showReminderPickerDefaultsFalse() {
        let vm = TaskDetailViewModel()
        #expect(vm.showReminderPicker == false)
    }
}
