import Foundation
import SwiftData
import SwiftUI

@Observable
final class TodayViewModel {
    var showCompleted = false
    var selectedFilter: TodayFilter = .all

    enum TodayFilter: String, CaseIterable {
        case all      = "All"
        case overdue  = "Overdue"
        case today    = "Today"
        case upcoming = "Upcoming"
    }

    func toggleTask(_ task: TaskItem) {
        withAnimation(DS.Animation.quick) {
            task.isCompleted.toggle()
            task.completedAt = task.isCompleted ? Date() : nil
        }
    }

    func todayTasks(from all: [TaskItem]) -> [TaskItem] {
        all.filter { $0.isDueToday && !$0.isCompleted }
           .sorted { a, b in
               let ap = a.priority.rawValue
               let bp = b.priority.rawValue
               if ap != bp { return ap > bp }
               return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
           }
    }

    func overdueTasks(from all: [TaskItem]) -> [TaskItem] {
        all.filter { $0.isOverdue && !$0.isCompleted }
           .sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
    }

    func upcomingTasks(from all: [TaskItem]) -> [TaskItem] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return all.filter {
            guard let due = $0.dueDate, !$0.isCompleted else { return false }
            return due >= tomorrow && due <= nextWeek
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    func completedTodayTasks(from all: [TaskItem]) -> [TaskItem] {
        all.filter {
            guard $0.isCompleted, let completedAt = $0.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }

    var dateHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}
