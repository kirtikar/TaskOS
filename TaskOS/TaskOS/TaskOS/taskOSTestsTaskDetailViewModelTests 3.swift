import XCTest
import SwiftData
@testable import taskOS

final class TaskDetailViewModelTests: XCTestCase {

    // MARK: - dueDateLabel

    func test_dueDateLabel_nil()           { XCTAssertEqual(vm().dueDateLabel(nil), "No Date") }
    func test_dueDateLabel_nonEmpty()      { XCTAssertFalse(vm().dueDateLabel(Date()).isEmpty) }
    func test_dueDateLabel_diffForDates()  {
        let today    = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        XCTAssertNotEqual(vm().dueDateLabel(today), vm().dueDateLabel(tomorrow))
    }

    // MARK: - reminderLabel

    func test_reminderLabel_nil()       { XCTAssertEqual(vm().reminderLabel(nil), "No Reminder") }
    func test_reminderLabel_nonEmpty()  {
        let label = vm().reminderLabel(Date())
        XCTAssertFalse(label.isEmpty)
        XCTAssertNotEqual(label, "No Reminder")
    }

    // MARK: - repeatLabel

    func test_repeatLabel_nilIsNever()      { XCTAssertEqual(vm().repeatLabel(nil, interval: 1), "Never") }
    func test_repeatLabel_interval1()       {
        XCTAssertEqual(vm().repeatLabel(.daily,   interval: 1), "Daily")
        XCTAssertEqual(vm().repeatLabel(.weekly,  interval: 1), "Weekly")
        XCTAssertEqual(vm().repeatLabel(.monthly, interval: 1), "Monthly")
        XCTAssertEqual(vm().repeatLabel(.yearly,  interval: 1), "Yearly")
    }
    func test_repeatLabel_multipleIntervals() {
        XCTAssertEqual(vm().repeatLabel(.daily,  interval: 3), "Every 3 dailys")
        XCTAssertEqual(vm().repeatLabel(.weekly, interval: 2), "Every 2 weeklys")
    }

    // MARK: - clearDueDate

    func test_clearDueDate_setsBothNil() {
        let t = Task(title: "T", dueDate: Date(), reminderDate: Date())
        vm().clearDueDate(from: t)
        XCTAssertNil(t.dueDate)
        XCTAssertNil(t.reminderDate)
    }

    func test_clearDueDate_idempotentWhenAlreadyNil() {
        let t = Task(title: "T")
        vm().clearDueDate(from: t)
        XCTAssertNil(t.dueDate)
        XCTAssertNil(t.reminderDate)
    }

    // MARK: - clearReminder

    func test_clearReminder_onlyClearsReminder() {
        let due = Date()
        let t = Task(title: "T", dueDate: due, reminderDate: Date())
        vm().clearReminder(from: t)
        XCTAssertNil(t.reminderDate)
        XCTAssertEqual(t.dueDate, due)
    }

    // MARK: - toggleSubtask

    func test_toggle_falseToTrue()  { let s = Subtask(title:"S"); vm().toggleSubtask(s); XCTAssertTrue(s.isCompleted) }
    func test_toggle_trueToFalse()  { let s = Subtask(title:"S"); s.isCompleted = true; vm().toggleSubtask(s); XCTAssertFalse(s.isCompleted) }
    func test_toggle_doubleRestores() {
        let s = Subtask(title: "S")
        let v = vm()
        v.toggleSubtask(s); v.toggleSubtask(s)
        XCTAssertFalse(s.isCompleted)
    }

    // MARK: - addSubtask / deleteSubtask

    func test_addSubtask_appendsCorrectly() throws {
        let ctx = try makeContext()
        let t   = Task(title: "Parent"); ctx.insert(t)
        let v   = vm(); v.newSubtaskTitle = "Write tests"
        v.addSubtask(to: t, context: ctx)
        XCTAssertEqual(t.subtasks.count, 1)
        XCTAssertEqual(t.subtasks.first?.title, "Write tests")
        XCTAssertTrue(v.newSubtaskTitle.isEmpty)
    }

    func test_addSubtask_ignoresWhitespace() throws {
        let ctx = try makeContext()
        let t   = Task(title: "Parent"); ctx.insert(t)
        let v   = vm(); v.newSubtaskTitle = "   "
        v.addSubtask(to: t, context: ctx)
        XCTAssertTrue(t.subtasks.isEmpty)
    }

    func test_addSubtask_incrementingOrder() throws {
        let ctx = try makeContext()
        let t   = Task(title: "Parent"); ctx.insert(t)
        let v   = vm()
        v.newSubtaskTitle = "First";  v.addSubtask(to: t, context: ctx)
        v.newSubtaskTitle = "Second"; v.addSubtask(to: t, context: ctx)
        let sorted = t.subtasks.sorted { $0.order < $1.order }
        XCTAssertEqual(sorted[0].order, 0)
        XCTAssertEqual(sorted[1].order, 1)
    }

    func test_deleteSubtask_removesFromTask() throws {
        let ctx     = try makeContext()
        let t       = Task(title: "Parent"); ctx.insert(t)
        let subtask = Subtask(title: "Del"); ctx.insert(subtask)
        t.subtasks.append(subtask)
        vm().deleteSubtask(subtask, from: t, context: ctx)
        XCTAssertTrue(t.subtasks.isEmpty)
    }

    // MARK: - Default booleans

    func test_defaultTogglesAllFalse() {
        let v = vm()
        XCTAssertFalse(v.showDatePicker)
        XCTAssertFalse(v.showReminderPicker)
        XCTAssertFalse(v.showProjectPicker)
        XCTAssertFalse(v.showTagPicker)
        XCTAssertFalse(v.showRepeatPicker)
    }

    // MARK: - Helpers

    private func vm() -> TaskDetailViewModel { TaskDetailViewModel() }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Task.self, Subtask.self, Project.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }
}
