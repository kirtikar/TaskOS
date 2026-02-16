import XCTest
@testable import taskOS

final class TaskModelTests: XCTestCase {

    func testDefaults() {
        let t = Task(title: "Buy milk")
        XCTAssertEqual(t.title, "Buy milk")
        XCTAssertEqual(t.notes, "")
        XCTAssertFalse(t.isCompleted)
        XCTAssertTrue(t.isInInbox)
        XCTAssertNil(t.dueDate)
        XCTAssertNil(t.reminderDate)
        XCTAssertEqual(t.priority, .none)
        XCTAssertNil(t.project)
        XCTAssertTrue(t.tags.isEmpty)
        XCTAssertTrue(t.subtasks.isEmpty)
        XCTAssertEqual(t.repeatInterval, 1)
        XCTAssertNil(t.repeatFrequency)
    }

    func testIsOverdue_noDate()         { XCTAssertFalse(Task(title: "T").isOverdue) }
    func testIsOverdue_completed()      { let t = Task(title: "T", dueDate: ago(1)); t.isCompleted = true; XCTAssertFalse(t.isOverdue) }
    func testIsOverdue_pastIncomplete() { XCTAssertTrue(Task(title: "T", dueDate: ago(7)).isOverdue) }
    func testIsOverdue_today()          { XCTAssertFalse(Task(title: "T", dueDate: todayNoon()).isOverdue) }

    func testIsDueToday_true()     { XCTAssertTrue(Task(title: "T", dueDate: Date()).isDueToday) }
    func testIsDueToday_nil()      { XCTAssertFalse(Task(title: "T").isDueToday) }
    func testIsDueToday_tomorrow() { XCTAssertFalse(Task(title: "T", dueDate: from(1)).isDueToday) }

    func testIsDueTomorrow_true()  { XCTAssertTrue(Task(title: "T", dueDate: from(1)).isDueTomorrow) }
    func testIsDueTomorrow_today() { XCTAssertFalse(Task(title: "T", dueDate: Date()).isDueTomorrow) }

    func testIsDueThisWeek_3days()  { XCTAssertTrue(Task(title: "T", dueDate: from(3)).isDueThisWeek) }
    func testIsDueThisWeek_10days() { XCTAssertFalse(Task(title: "T", dueDate: from(10)).isDueThisWeek) }

    func testCompletedSubtasksCount() {
        let t = Task(title: "P")
        let s1 = Subtask(title: "A"); s1.isCompleted = true
        let s2 = Subtask(title: "B")
        let s3 = Subtask(title: "C"); s3.isCompleted = true
        t.subtasks = [s1, s2, s3]
        XCTAssertEqual(t.completedSubtasks, 2)
    }

    func testCompletedSubtasksZero() { XCTAssertEqual(Task(title: "T").completedSubtasks, 0) }

    private func ago(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: -n, to: Date())! }
    private func from(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: n, to: Date())! }
    private func todayNoon() -> Date { Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())! }
}

final class PriorityTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(Priority.none.rawValue,   0)
        XCTAssertEqual(Priority.low.rawValue,    1)
        XCTAssertEqual(Priority.medium.rawValue, 2)
        XCTAssertEqual(Priority.high.rawValue,   3)
    }

    func testLabels() {
        XCTAssertEqual(Priority.none.label,   "None")
        XCTAssertEqual(Priority.low.label,    "Low")
        XCTAssertEqual(Priority.medium.label, "Medium")
        XCTAssertEqual(Priority.high.label,   "High")
    }

    func testSfSymbols() {
        XCTAssertEqual(Priority.none.sfSymbol,   "minus")
        XCTAssertEqual(Priority.low.sfSymbol,    "exclamationmark")
        XCTAssertEqual(Priority.medium.sfSymbol, "exclamationmark.2")
        XCTAssertEqual(Priority.high.sfSymbol,   "exclamationmark.3")
    }

    func testAllCasesCount()   { XCTAssertEqual(Priority.allCases.count, 4) }
    func testOrdering()        { XCTAssertGreaterThan(Priority.high.rawValue, Priority.medium.rawValue) }
}

final class RepeatFrequencyTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(RepeatFrequency.daily.rawValue,   "Daily")
        XCTAssertEqual(RepeatFrequency.weekly.rawValue,  "Weekly")
        XCTAssertEqual(RepeatFrequency.monthly.rawValue, "Monthly")
        XCTAssertEqual(RepeatFrequency.yearly.rawValue,  "Yearly")
    }

    func testAllCasesCount() { XCTAssertEqual(RepeatFrequency.allCases.count, 4) }

    func testCodableRoundTrip() throws {
        let decoded = try JSONDecoder().decode(RepeatFrequency.self, from: try JSONEncoder().encode(RepeatFrequency.weekly))
        XCTAssertEqual(decoded, .weekly)
    }
}

final class SubtaskTests: XCTestCase {

    func testDefaults()    { let s = Subtask(title: "T"); XCTAssertFalse(s.isCompleted); XCTAssertEqual(s.order, 0) }
    func testCustomOrder() { XCTAssertEqual(Subtask(title: "T", order: 5).order, 5) }
}
