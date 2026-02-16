import Foundation
import SwiftData
import SwiftUI

@Observable
final class InboxViewModel {
    var sortOrder: SortOrder = .createdDate
    var showCompleted = false
    var editMode: EditMode = .inactive

    enum SortOrder: String, CaseIterable {
        case createdDate = "Date Added"
        case priority    = "Priority"
        case title       = "Title"
        case dueDate     = "Due Date"

        var sfSymbol: String {
            switch self {
            case .createdDate: return "calendar.badge.plus"
            case .priority:    return "exclamationmark.3"
            case .title:       return "textformat"
            case .dueDate:     return "calendar"
            }
        }
    }

    func sortedTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        let filtered = showCompleted ? tasks : tasks.filter { !$0.isCompleted }
        return filtered.sorted { a, b in
            switch sortOrder {
            case .createdDate:
                return a.createdAt > b.createdAt
            case .priority:
                if a.priority.rawValue != b.priority.rawValue {
                    return a.priority.rawValue > b.priority.rawValue
                }
                return a.createdAt > b.createdAt
            case .title:
                return a.title.localizedCompare(b.title) == .orderedAscending
            case .dueDate:
                let aDate = a.dueDate ?? .distantFuture
                let bDate = b.dueDate ?? .distantFuture
                return aDate < bDate
            }
        }
    }

    func toggleTask(_ task: TaskItem) {
        withAnimation(DS.Animation.quick) {
            task.isCompleted.toggle()
            task.completedAt = task.isCompleted ? Date() : nil
        }
    }

    func deleteTask(_ task: TaskItem, context: ModelContext) {
        context.delete(task)
    }

    func moveTasks(_ tasks: [TaskItem], to project: Project) {
        tasks.forEach {
            $0.project = project
            $0.isInInbox = false
        }
    }
}
