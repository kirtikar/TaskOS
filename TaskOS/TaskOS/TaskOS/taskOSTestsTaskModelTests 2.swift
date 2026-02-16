import XCTest
@testable import taskOS

// MARK: - Task Model Tests

final class TaskModelTests: XCTestCase {

    // MARK: - Defaults

    func test_init_defaultValues() {
        let task = Task(title: "Buy groceries")
        XCTAssertEqual(task.title, "Buy groceries")
        XCTAssertEqual(task.notes, "")
        XCTAssertFalse(task.isCompleted)
        XCTAssertTrue(task.isInInbox)
        XCTAssertNil(task.dueDate)
        XCTAssertNil(task.reminderDate)
        XCTAssertEqual(task.priority, .none)
        XCTAssertNil(task.project)
        XCTAssertTrue(task.tags.isEmpty)
        XCTAssertTrue(task.subtasks.isEmpty)
        XCTAssertEqual(task.repeatInterval, 1)
        XCTAssertNil(task.repeatFrequency)
    }

    func test_init_customValues() {
        let due = Date()
        let task = Task(title: "Review", notes: "Check with team",
                        isInInbox: false, dueDate: due, priority: .high)
        XCTAssertEqual(task.title, "Review")
        XCTAssertEqual(task.notes, "Check with team")
        XCTAssertFalse(task.isInInbox)
        XCTAssertEqual(task.dueDate, due)
        XCTAssertEqual(task.priority, .high)
    }

    // MARK: - isOverdue

    func test_isOverdue_falseWhenNoDueDate() {
        XCTAssertFalse(Task(title: "T").isOverdue)
    }

    func test_isOverdue_falseWhenCompleted() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let task = Task(title: "T", dueDate: yesterday)
        task.isCompleted = true
        XCTAssertFalse(task.isOverdue)
    }

    func test_isOverdue_trueWhenPastDueAndIncomplete() {
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let task = Task(title: "T", dueDate: lastWeek)
        XCTAssertTrue(task.isOverdue)
    }

    func test_isOverdue_falseWhenDueToday() {
        let todayNoon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        XCTAssertFalse(Task(title: "T", dueDate: todayNoon).isOverdue)
    }

    // MARK: - isDueToday

    func test_isDueToday_trueForToday() {
        XCTAssertTrue(Task(title: "T", dueDate: Date()).isDueToday)
    }

    func test_isDueToday_falseWhenNil() {
        XCTAssertFalse(Task(title: "T").isDueToday)
    }

    func test_isDueToday_falseForTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertFalse(Task(title: "T", dueDate: tomorrow).isDueToday)
    }

    // MARK: - isDueTomorrow

    func test_isDueTomorrow_trueForTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertTrue(Task(title: "T", dueDate: tomorrow).isDueTomorrow)
    }

    func test_isDueTomorrow_falseForToday() {
        XCTAssertFalse(Task(title: "T", dueDate: Date()).isDueTomorrow)
    }

    // MARK: - isDueThisWeek

    func test_isDueThisWeek_trueForThreeDaysAhead() {
        let inThree = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        XCTAssertTrue(Task(title: "T", dueDate: inThree).isDueThisWeek)
    }

    func test_isDueThisWeek_falseForTenDaysAhead() {
        let inTen = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        XCTAssertFalse(Task(title: "T", dueDate: inTen).isDueThisWeek)
    }

    // MARK: - completedSubtasks

    func test_completedSubtasks_countsOnlyCompleted() {
        let task = Task(title: "P")
        let s1 = Subtask(title: "A"); s1.isCompleted = true
        let s2 = Subtask(title: "B")
        let s3 = Subtask(title: "C"); s3.isCompleted = true
        task.subtasks = [s1, s2, s3]
        XCTAssertEqual(task.completedSubtasks, 2)
    }

    func test_completedSubtasks_zeroWithNoSubtasks() {
        XCTAssertEqual(Task(title: "T").completedSubtasks, 0)
    }
}

// MARK: - Priority Tests

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

    func test_allCases_count() {
        XCTAssertEqual(Priority.allCases.count, 4)
    }

    func test_ordering_byRawValue() {
        XCTAssertGreaterThan(Priority.high.rawValue,   Priority.medium.rawValue)
        XCTAssertGreaterThan(Priority.medium.rawValue, Priority.low.rawValue)
        XCTAssertGreaterThan(Priority.low.rawValue,    Priority.none.rawValue)
    }
}

// MARK: - RepeatFrequency Tests

final class RepeatFrequencyTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(RepeatFrequency.daily.rawValue,   "Daily")
        XCTAssertEqual(RepeatFrequency.weekly.rawValue,  "Weekly")
        XCTAssertEqual(RepeatFrequency.monthly.rawValue, "Monthly")
        XCTAssertEqual(RepeatFrequency.yearly.rawValue,  "Yearly")
    }

    func test_allCases_hasFourEntries() {
        XCTAssertEqual(RepeatFrequency.allCases.count, 4)
    }

    func test_codableRoundTrip() throws {
        let encoded = try JSONEncoder().encode(RepeatFrequency.weekly)
        let decoded = try JSONDecoder().decode(RepeatFrequency.self, from: encoded)
        XCTAssertEqual(decoded, .weekly)
    }
}

// MARK: - Subtask Tests

final class SubtaskTests: XCTestCase {

    func test_init_defaultsToNotCompleted() {
        let s = Subtask(title: "Write tests")
        XCTAssertFalse(s.isCompleted)
        XCTAssertEqual(s.title, "Write tests")
        XCTAssertEqual(s.order, 0)
    }

    func test_init_customOrder() {
        let s = Subtask(title: "Step", order: 5)
        XCTAssertEqual(s.order, 5)
    }
}
