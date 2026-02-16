import Testing
import Foundation
@testable import taskOS

// MARK: - Task Model Tests

@Suite("Task Model")
struct TaskModelTests {

    // MARK: - Initialization

    @Test("Task initialises with correct defaults")
    func taskDefaultValues() {
        let task = Task(title: "Buy groceries")

        #expect(task.title == "Buy groceries")
        #expect(task.notes == "")
        #expect(task.isCompleted == false)
        #expect(task.isInInbox == true)
        #expect(task.dueDate == nil)
        #expect(task.reminderDate == nil)
        #expect(task.priority == .none)
        #expect(task.project == nil)
        #expect(task.tags.isEmpty)
        #expect(task.subtasks.isEmpty)
        #expect(task.repeatInterval == 1)
        #expect(task.repeatFrequency == nil)
    }

    @Test("Task initialises with custom values")
    func taskCustomValues() {
        let due = Date()
        let task = Task(
            title: "Design review",
            notes: "Check with stakeholders",
            isInInbox: false,
            dueDate: due,
            priority: .high
        )

        #expect(task.title == "Design review")
        #expect(task.notes == "Check with stakeholders")
        #expect(task.isInInbox == false)
        #expect(task.dueDate == due)
        #expect(task.priority == .high)
    }

    // MARK: - isOverdue

    @Test("Task is NOT overdue when no due date is set")
    func notOverdueWithNoDueDate() {
        let task = Task(title: "No date task")
        #expect(task.isOverdue == false)
    }

    @Test("Task is NOT overdue when already completed")
    func notOverdueWhenCompleted() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let task = Task(title: "Done task", dueDate: yesterday)
        task.isCompleted = true
        #expect(task.isOverdue == false)
    }

    @Test("Task IS overdue when due date is in the past and not completed")
    func overdueWhenPastDueDate() {
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let task = Task(title: "Old task", dueDate: lastWeek)
        #expect(task.isOverdue == true)
    }

    @Test("Task is NOT overdue when due today")
    func notOverdueWhenDueToday() {
        let todayNoon = Calendar.current.date(
            bySettingHour: 12, minute: 0, second: 0,
            of: Date()
        )!
        let task = Task(title: "Today task", dueDate: todayNoon)
        #expect(task.isOverdue == false)
    }

    // MARK: - isDueToday

    @Test("isDueToday is true when due date is today")
    func isDueTodayTrue() {
        let task = Task(title: "Today task", dueDate: Date())
        #expect(task.isDueToday == true)
    }

    @Test("isDueToday is false when due date is nil")
    func isDueTodayFalseWhenNil() {
        let task = Task(title: "No date")
        #expect(task.isDueToday == false)
    }

    @Test("isDueToday is false when due date is tomorrow")
    func isDueTodayFalseWhenTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let task = Task(title: "Tomorrow task", dueDate: tomorrow)
        #expect(task.isDueToday == false)
    }

    // MARK: - isDueTomorrow

    @Test("isDueTomorrow is true when due date is tomorrow")
    func isDueTomorrowTrue() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let task = Task(title: "Tomorrow task", dueDate: tomorrow)
        #expect(task.isDueTomorrow == true)
    }

    @Test("isDueTomorrow is false when due date is today")
    func isDueTomorrowFalseWhenToday() {
        let task = Task(title: "Today task", dueDate: Date())
        #expect(task.isDueTomorrow == false)
    }

    // MARK: - isDueThisWeek

    @Test("isDueThisWeek is true for a date 3 days from now")
    func isDueThisWeekTrue() {
        let inThreeDays = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let task = Task(title: "This week", dueDate: inThreeDays)
        #expect(task.isDueThisWeek == true)
    }

    @Test("isDueThisWeek is false for a date 10 days from now")
    func isDueThisWeekFalse() {
        let inTenDays = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        let task = Task(title: "Next week", dueDate: inTenDays)
        #expect(task.isDueThisWeek == false)
    }

    // MARK: - completedSubtasks

    @Test("completedSubtasks counts only completed subtasks")
    func completedSubtasksCount() {
        let task = Task(title: "Parent task")
        let s1 = Subtask(title: "Step 1")
        let s2 = Subtask(title: "Step 2")
        let s3 = Subtask(title: "Step 3")
        s1.isCompleted = true
        s3.isCompleted = true
        task.subtasks = [s1, s2, s3]

        #expect(task.completedSubtasks == 2)
    }

    @Test("completedSubtasks is zero with no subtasks")
    func completedSubtasksZero() {
        let task = Task(title: "Empty task")
        #expect(task.completedSubtasks == 0)
    }
}

// MARK: - Priority Tests

@Suite("Priority")
struct PriorityTests {

    @Test("Priority raw values are correct")
    func priorityRawValues() {
        #expect(Priority.none.rawValue   == 0)
        #expect(Priority.low.rawValue    == 1)
        #expect(Priority.medium.rawValue == 2)
        #expect(Priority.high.rawValue   == 3)
    }

    @Test("Priority labels are correct")
    func priorityLabels() {
        #expect(Priority.none.label   == "None")
        #expect(Priority.low.label    == "Low")
        #expect(Priority.medium.label == "Medium")
        #expect(Priority.high.label   == "High")
    }

    @Test("Priority sfSymbols are correct")
    func prioritySfSymbols() {
        #expect(Priority.none.sfSymbol   == "minus")
        #expect(Priority.low.sfSymbol    == "exclamationmark")
        #expect(Priority.medium.sfSymbol == "exclamationmark.2")
        #expect(Priority.high.sfSymbol   == "exclamationmark.3")
    }

    @Test("Priority allCases contains all four cases in order")
    func priorityAllCases() {
        let cases = Priority.allCases
        #expect(cases.count == 4)
        #expect(cases[0] == .none)
        #expect(cases[1] == .low)
        #expect(cases[2] == .medium)
        #expect(cases[3] == .high)
    }

    @Test("Priority is comparable by raw value")
    func priorityOrdering() {
        #expect(Priority.high.rawValue > Priority.medium.rawValue)
        #expect(Priority.medium.rawValue > Priority.low.rawValue)
        #expect(Priority.low.rawValue > Priority.none.rawValue)
    }
}

// MARK: - RepeatFrequency Tests

@Suite("RepeatFrequency")
struct RepeatFrequencyTests {

    @Test("RepeatFrequency raw values are human-readable strings")
    func repeatFrequencyRawValues() {
        #expect(RepeatFrequency.daily.rawValue   == "Daily")
        #expect(RepeatFrequency.weekly.rawValue  == "Weekly")
        #expect(RepeatFrequency.monthly.rawValue == "Monthly")
        #expect(RepeatFrequency.yearly.rawValue  == "Yearly")
    }

    @Test("RepeatFrequency allCases has four entries")
    func repeatFrequencyAllCases() {
        #expect(RepeatFrequency.allCases.count == 4)
    }

    @Test("RepeatFrequency is Codable")
    func repeatFrequencyCodable() throws {
        let encoded = try JSONEncoder().encode(RepeatFrequency.weekly)
        let decoded = try JSONDecoder().decode(RepeatFrequency.self, from: encoded)
        #expect(decoded == .weekly)
    }
}

// MARK: - Subtask Tests

@Suite("Subtask")
struct SubtaskTests {

    @Test("Subtask initialises as not completed")
    func subtaskDefaultNotCompleted() {
        let subtask = Subtask(title: "Write tests")
        #expect(subtask.isCompleted == false)
        #expect(subtask.title == "Write tests")
        #expect(subtask.order == 0)
    }

    @Test("Subtask order is preserved")
    func subtaskOrderPreserved() {
        let s = Subtask(title: "Step", order: 5)
        #expect(s.order == 5)
    }
}
