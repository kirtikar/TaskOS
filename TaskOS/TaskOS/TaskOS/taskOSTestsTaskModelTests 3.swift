import XCTest
@testable import taskOS

// MARK: - Task Model

final class TaskModelTests: XCTestCase {

    func test_defaults() {
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

    func test_customInit() {
        let due = Date()
        let t = Task(title: "R", notes: "N", isInInbox: false, dueDate: due, priority: .high)
        XCTAssertFalse(t.isInInbox)
        XCTAssertEqual(t.dueDate, due)
        XCTAssertEqual(t.priority, .high)
    }

    // isOverdue
    func test_isOverdue_noDate()        { XCTAssertFalse(Task(title:"T").isOverdue) }
    func test_isOverdue_completed()     { let t = Task(title:"T", dueDate: daysAgo(1)); t.isCompleted = true; XCTAssertFalse(t.isOverdue) }
    func test_isOverdue_pastIncomplete(){ XCTAssertTrue(Task(title:"T", dueDate: daysAgo(7)).isOverdue) }
    func test_isOverdue_dueToday()      { XCTAssertFalse(Task(title:"T", dueDate: todayNoon()).isOverdue) }

    // isDueToday
    func test_isDueToday_true()         { XCTAssertTrue(Task(title:"T", dueDate: Date()).isDueToday) }
    func test_isDueToday_nilDate()      { XCTAssertFalse(Task(title:"T").isDueToday) }
    func test_isDueToday_tomorrow()     { XCTAssertFalse(Task(title:"T", dueDate: daysFrom(1)).isDueToday) }

    // isDueTomorrow
    func test_isDueTomorrow_true()      { XCTAssertTrue(Task(title:"T", dueDate: daysFrom(1)).isDueTomorrow) }
    func test_isDueTomorrow_today()     { XCTAssertFalse(Task(title:"T", dueDate: Date()).isDueTomorrow) }

    // isDueThisWeek
    func test_isDueThisWeek_3days()     { XCTAssertTrue(Task(title:"T", dueDate: daysFrom(3)).isDueThisWeek) }
    func test_isDueThisWeek_10days()    { XCTAssertFalse(Task(title:"T", dueDate: daysFrom(10)).isDueThisWeek) }

    // completedSubtasks
    func test_completedSubtasks_count() {
        let t = Task(title: "P")
        let s1 = Subtask(title: "A"); s1.isCompleted = true
        let s2 = Subtask(title: "B")
        let s3 = Subtask(title: "C"); s3.isCompleted = true
        t.subtasks = [s1, s2, s3]
        XCTAssertEqual(t.completedSubtasks, 2)
    }
    func test_completedSubtasks_zero() { XCTAssertEqual(Task(title:"T").completedSubtasks, 0) }

    // MARK: Helpers
    private func daysAgo(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: -n, to: Date())! }
    private func daysFrom(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: n, to: Date())! }
    private func todayNoon() -> Date { Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())! }
}

// MARK: - Priority

final class PriorityTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(Priority.none.rawValue,   0)
        XCTAssertEqual(Priority.low.rawValue,    1)
        XCTAssertEqual(Priority.medium.rawValue, 2)
        XCTAssertEqual(Priority.high.rawValue,   3)
    }

    func test_labels() {
        XCTAssertEqual(Priority.none.label,   "None")
        XCTAssertEqual(Priority.low.label,    "Low")
        XCTAssertEqual(Priority.medium.label, "Medium")
        XCTAssertEqual(Priority.high.label,   "High")
    }

    func test_sfSymbols() {
        XCTAssertEqual(Priority.none.sfSymbol,   "minus")
        XCTAssertEqual(Priority.low.sfSymbol,    "exclamationmark")
        XCTAssertEqual(Priority.medium.sfSymbol, "exclamationmark.2")
        XCTAssertEqual(Priority.high.sfSymbol,   "exclamationmark.3")
    }

    func test_allCases_count()   { XCTAssertEqual(Priority.allCases.count, 4) }
    func test_ordering()         { XCTAssertGreaterThan(Priority.high.rawValue, Priority.medium.rawValue) }
}

// MARK: - RepeatFrequency

final class RepeatFrequencyTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(RepeatFrequency.daily.rawValue,   "Daily")
        XCTAssertEqual(RepeatFrequency.weekly.rawValue,  "Weekly")
        XCTAssertEqual(RepeatFrequency.monthly.rawValue, "Monthly")
        XCTAssertEqual(RepeatFrequency.yearly.rawValue,  "Yearly")
    }

    func test_allCases_count() { XCTAssertEqual(RepeatFrequency.allCases.count, 4) }

    func test_codableRoundTrip() throws {
        let decoded = try JSONDecoder().decode(
            RepeatFrequency.self,
            from: try JSONEncoder().encode(RepeatFrequency.weekly)
        )
        XCTAssertEqual(decoded, .weekly)
    }
}

// MARK: - Subtask

final class SubtaskTests: XCTestCase {

    func test_defaults() {
        let s = Subtask(title: "Write tests")
        XCTAssertFalse(s.isCompleted)
        XCTAssertEqual(s.title, "Write tests")
        XCTAssertEqual(s.order, 0)
    }

    func test_customOrder() {
        XCTAssertEqual(Subtask(title: "S", order: 5).order, 5)
    }
}
