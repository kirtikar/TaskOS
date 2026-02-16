import XCTest
import SwiftData
@testable import taskOS

final class ViewModelTests: XCTestCase {

    private var context: ModelContext!

    override func setUpWithError() throws {
        let container = try ModelContainer(
            for: Task.self, Subtask.self, Project.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    // MARK: dueDateLabel

    func testDueDateLabel_nil()    { XCTAssertEqual(vm().dueDateLabel(nil), "No Date") }
    func testDueDateLabel_nonEmpty() { XCTAssertFalse(vm().dueDateLabel(Date()).isEmpty) }
    func testDueDateLabel_diffDates() {
        let today    = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        XCTAssertNotEqual(vm().dueDateLabel(today), vm().dueDateLabel(tomorrow))
    }

    // MARK: reminderLabel

    func testReminderLabel_nil()     { XCTAssertEqual(vm().reminderLabel(nil), "No Reminder") }
    func testReminderLabel_nonEmpty() {
        let label = vm().reminderLabel(Date())
        XCTAssertFalse(label.isEmpty)
        XCTAssertNotEqual(label, "No Reminder")
    }

    // MARK: repeatLabel

    func testRepeatLabel_never()      { XCTAssertEqual(vm().repeatLabel(nil, interval: 1), "Never") }
    func testRepeatLabel_interval1()  {
        XCTAssertEqual(vm().repeatLabel(.daily,   interval: 1), "Daily")
        XCTAssertEqual(vm().repeatLabel(.weekly,  interval: 1), "Weekly")
        XCTAssertEqual(vm().repeatLabel(.monthly, interval: 1), "Monthly")
        XCTAssertEqual(vm().repeatLabel(.yearly,  interval: 1), "Yearly")
    }
    func testRepeatLabel_multi() {
        XCTAssertEqual(vm().repeatLabel(.daily,  interval: 3), "Every 3 dailys")
        XCTAssertEqual(vm().repeatLabel(.weekly, interval: 2), "Every 2 weeklys")
    }

    // MARK: clearDueDate

    func testClearDueDate_setsBothNil() {
        let t = Task(title: "T", dueDate: Date(), reminderDate: Date())
        vm().clearDueDate(from: t)
        XCTAssertNil(t.dueDate)
        XCTAssertNil(t.reminderDate)
    }

    // MARK: clearReminder

    func testClearReminder_onlyClearsReminder() {
        let due = Date()
        let t = Task(title: "T", dueDate: due, reminderDate: Date())
        vm().clearReminder(from: t)
        XCTAssertNil(t.reminderDate)
        XCTAssertEqual(t.dueDate, due)
    }

    // MARK: toggleSubtask

    func testToggle_falseToTrue()     { let s = Subtask(title: "S"); vm().toggleSubtask(s); XCTAssertTrue(s.isCompleted) }
    func testToggle_trueToFalse()     { let s = Subtask(title: "S"); s.isCompleted = true; vm().toggleSubtask(s); XCTAssertFalse(s.isCompleted) }
    func testToggle_doubleRestores()  {
        let s = Subtask(title: "S"); let v = vm()
        v.toggleSubtask(s); v.toggleSubtask(s)
        XCTAssertFalse(s.isCompleted)
    }

    // MARK: addSubtask

    func testAddSubtask_appendsCorrectly() {
        let t = Task(title: "Parent"); context.insert(t)
        let v = vm(); v.newSubtaskTitle = "Write tests"
        v.addSubtask(to: t, context: context)
        XCTAssertEqual(t.subtasks.count, 1)
        XCTAssertEqual(t.subtasks.first?.title, "Write tests")
        XCTAssertTrue(v.newSubtaskTitle.isEmpty)
    }

    func testAddSubtask_ignoresWhitespace() {
        let t = Task(title: "Parent"); context.insert(t)
        let v = vm(); v.newSubtaskTitle = "   "
        v.addSubtask(to: t, context: context)
        XCTAssertTrue(t.subtasks.isEmpty)
    }

    func testAddSubtask_incrementingOrder() {
        let t = Task(title: "Parent"); context.insert(t)
        let v = vm()
        v.newSubtaskTitle = "First";  v.addSubtask(to: t, context: context)
        v.newSubtaskTitle = "Second"; v.addSubtask(to: t, context: context)
        let sorted = t.subtasks.sorted { $0.order < $1.order }
        XCTAssertEqual(sorted[0].order, 0)
        XCTAssertEqual(sorted[1].order, 1)
    }

    // MARK: deleteSubtask

    func testDeleteSubtask_removes() {
        let t = Task(title: "Parent"); context.insert(t)
        let s = Subtask(title: "Del"); context.insert(s)
        t.subtasks.append(s)
        vm().deleteSubtask(s, from: t, context: context)
        XCTAssertTrue(t.subtasks.isEmpty)
    }

    // MARK: defaults

    func testDefaultBooleans() {
        let v = vm()
        XCTAssertFalse(v.showDatePicker)
        XCTAssertFalse(v.showReminderPicker)
        XCTAssertFalse(v.showProjectPicker)
        XCTAssertFalse(v.showTagPicker)
        XCTAssertFalse(v.showRepeatPicker)
    }

    private func vm() -> TaskDetailViewModel { TaskDetailViewModel() }
}
