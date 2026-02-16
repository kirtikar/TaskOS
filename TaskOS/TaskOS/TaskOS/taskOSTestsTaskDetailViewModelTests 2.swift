import XCTest
import SwiftData
@testable import taskOS

final class TaskDetailViewModelTests: XCTestCase {

    // MARK: - dueDateLabel

    func test_dueDateLabel_nilReturnsNoDate() {
        XCTAssertEqual(TaskDetailViewModel().dueDateLabel(nil), "No Date")
    }

    func test_dueDateLabel_nonEmptyForValidDate() {
        let label = TaskDetailViewModel().dueDateLabel(Date())
        XCTAssertFalse(label.isEmpty)
    }

    func test_dueDateLabel_differentForDifferentDates() {
        let vm       = TaskDetailViewModel()
        let today    = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        XCTAssertNotEqual(vm.dueDateLabel(today), vm.dueDateLabel(tomorrow))
    }

    // MARK: - reminderLabel

    func test_reminderLabel_nilReturnsNoReminder() {
        XCTAssertEqual(TaskDetailViewModel().reminderLabel(nil), "No Reminder")
    }

    func test_reminderLabel_nonEmptyForValidDate() {
        let label = TaskDetailViewModel().reminderLabel(Date())
        XCTAssertFalse(label.isEmpty)
        XCTAssertNotEqual(label, "No Reminder")
    }

    // MARK: - repeatLabel

    func test_repeatLabel_nilFrequencyReturnsNever() {
        XCTAssertEqual(TaskDetailViewModel().repeatLabel(nil, interval: 1), "Never")
    }

    func test_repeatLabel_interval1ReturnsRawValue() {
        let vm = TaskDetailViewModel()
        XCTAssertEqual(vm.repeatLabel(.daily,   interval: 1), "Daily")
        XCTAssertEqual(vm.repeatLabel(.weekly,  interval: 1), "Weekly")
        XCTAssertEqual(vm.repeatLabel(.monthly, interval: 1), "Monthly")
        XCTAssertEqual(vm.repeatLabel(.yearly,  interval: 1), "Yearly")
    }

    func test_repeatLabel_multipleIntervals() {
        let vm = TaskDetailViewModel()
        XCTAssertEqual(vm.repeatLabel(.daily,  interval: 3), "Every 3 dailys")
        XCTAssertEqual(vm.repeatLabel(.weekly, interval: 2), "Every 2 weeklys")
    }

    // MARK: - clearDueDate

    func test_clearDueDate_setsBothDatesToNil() {
        let vm   = TaskDetailViewModel()
        let task = Task(title: "T", dueDate: Date(), reminderDate: Date())
        vm.clearDueDate(from: task)
        XCTAssertNil(task.dueDate)
        XCTAssertNil(task.reminderDate)
    }

    func test_clearDueDate_idempotentWhenAlreadyNil() {
        let vm   = TaskDetailViewModel()
        let task = Task(title: "T")
        vm.clearDueDate(from: task)
        XCTAssertNil(task.dueDate)
        XCTAssertNil(task.reminderDate)
    }

    // MARK: - clearReminder

    func test_clearReminder_onlyClearsReminderDate() {
        let vm   = TaskDetailViewModel()
        let due  = Date()
        let task = Task(title: "T", dueDate: due, reminderDate: Date())
        vm.clearReminder(from: task)
        XCTAssertNil(task.reminderDate)
        XCTAssertEqual(task.dueDate, due)
    }

    // MARK: - toggleSubtask

    func test_toggleSubtask_falseToTrue() {
        let subtask = Subtask(title: "S")
        TaskDetailViewModel().toggleSubtask(subtask)
        XCTAssertTrue(subtask.isCompleted)
    }

    func test_toggleSubtask_trueToFalse() {
        let subtask = Subtask(title: "S")
        subtask.isCompleted = true
        TaskDetailViewModel().toggleSubtask(subtask)
        XCTAssertFalse(subtask.isCompleted)
    }

    func test_toggleSubtask_doubleToggleRestoresOriginal() {
        let subtask = Subtask(title: "S")
        let vm = TaskDetailViewModel()
        vm.toggleSubtask(subtask)
        vm.toggleSubtask(subtask)
        XCTAssertFalse(subtask.isCompleted)
    }

    // MARK: - addSubtask / deleteSubtask

    func test_addSubtask_appendsWithCorrectTitle() throws {
        let context = try makeContext()
        let task    = Task(title: "Parent")
        context.insert(task)

        let vm = TaskDetailViewModel()
        vm.newSubtaskTitle = "Write unit tests"
        vm.addSubtask(to: task, context: context)

        XCTAssertEqual(task.subtasks.count, 1)
        XCTAssertEqual(task.subtasks.first?.title, "Write unit tests")
        XCTAssertEqual(vm.newSubtaskTitle, "")
    }

    func test_addSubtask_ignoresWhitespaceOnly() throws {
        let context = try makeContext()
        let task    = Task(title: "Parent")
        context.insert(task)

        let vm = TaskDetailViewModel()
        vm.newSubtaskTitle = "   "
        vm.addSubtask(to: task, context: context)

        XCTAssertTrue(task.subtasks.isEmpty)
    }

    func test_addSubtask_assignsIncrementingOrder() throws {
        let context = try makeContext()
        let task    = Task(title: "Parent")
        context.insert(task)

        let vm = TaskDetailViewModel()
        vm.newSubtaskTitle = "First"
        vm.addSubtask(to: task, context: context)
        vm.newSubtaskTitle = "Second"
        vm.addSubtask(to: task, context: context)

        let sorted = task.subtasks.sorted { $0.order < $1.order }
        XCTAssertEqual(sorted[0].title, "First")
        XCTAssertEqual(sorted[0].order, 0)
        XCTAssertEqual(sorted[1].title, "Second")
        XCTAssertEqual(sorted[1].order, 1)
    }

    func test_deleteSubtask_removesFromTask() throws {
        let context = try makeContext()
        let task    = Task(title: "Parent")
        let subtask = Subtask(title: "To delete")
        context.insert(task)
        context.insert(subtask)
        task.subtasks.append(subtask)

        TaskDetailViewModel().deleteSubtask(subtask, from: task, context: context)
        XCTAssertTrue(task.subtasks.isEmpty)
    }

    // MARK: - Default toggle states

    func test_defaultToggleStates_allFalse() {
        let vm = TaskDetailViewModel()
        XCTAssertFalse(vm.showDatePicker)
        XCTAssertFalse(vm.showReminderPicker)
        XCTAssertFalse(vm.showProjectPicker)
        XCTAssertFalse(vm.showTagPicker)
        XCTAssertFalse(vm.showRepeatPicker)
    }

    // MARK: - Helper

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Task.self, Subtask.self, Project.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }
}
