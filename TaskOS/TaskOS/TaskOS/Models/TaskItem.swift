import Foundation
import SwiftData

// MARK: - Priority

enum Priority: Int, Codable, CaseIterable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    var label: String {
        switch self {
        case .none:   return "None"
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    var sfSymbol: String {
        switch self {
        case .none:   return "minus"
        case .low:    return "exclamationmark"
        case .medium: return "exclamationmark.2"
        case .high:   return "exclamationmark.3"
        }
    }
}

// MARK: - RepeatRule

enum RepeatFrequency: String, Codable, CaseIterable {
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
    case yearly  = "Yearly"
}

// MARK: - Subtask

@Model
final class Subtask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var order: Int
    var parentTask: TaskItem?

    init(title: String, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.order = order
    }
}

// MARK: - TaskItem

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var isInInbox: Bool
    var isSomeday: Bool       // defer indefinitely (Someday/Maybe)
    var dueDate: Date?
    var startDate: Date?      // defer until this date (not shown before then)
    var reminderDate: Date?
    var priority: Priority
    var createdAt: Date
    var completedAt: Date?
    var order: Int

    // Repeat
    var repeatFrequency: RepeatFrequency?
    var repeatInterval: Int

    // Relationships
    var project: Project?

    @Relationship(deleteRule: .nullify, inverse: \Tag.tasks)
    var tags: [Tag]

    @Relationship(deleteRule: .cascade, inverse: \Subtask.parentTask)
    var subtasks: [Subtask]

    var completedSubtasks: Int {
        subtasks.filter(\.isCompleted).count
    }

    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Calendar.current.startOfDay(for: Date())
    }

    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }

    var isDueTomorrow: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(due)
    }

    var isDueThisWeek: Bool {
        guard let due = dueDate else { return false }
        let today = Date()
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        return due >= today && due <= weekFromNow
    }

    init(
        title: String,
        notes: String = "",
        isInInbox: Bool = true,
        isSomeday: Bool = false,
        dueDate: Date? = nil,
        startDate: Date? = nil,
        reminderDate: Date? = nil,
        priority: Priority = .none,
        project: Project? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.isCompleted = false
        self.isInInbox = isInInbox
        self.isSomeday = isSomeday
        self.dueDate = dueDate
        self.startDate = startDate
        self.reminderDate = reminderDate
        self.priority = priority
        self.createdAt = Date()
        self.project = project
        self.tags = []
        self.subtasks = []
        self.order = 0
        self.repeatInterval = 1
    }
}
