import Foundation
import SwiftData
import SwiftUI

// MARK: - ProjectColor

enum ProjectColor: String, Codable, CaseIterable {
    case blue     = "blue"
    case red      = "red"
    case orange   = "orange"
    case yellow   = "yellow"
    case green    = "green"
    case teal     = "teal"
    case purple   = "purple"
    case pink     = "pink"
    case indigo   = "indigo"
    case gray     = "gray"

    var color: Color {
        switch self {
        case .blue:   return .blue
        case .red:    return .red
        case .orange: return .orange
        case .yellow: return Color(red: 0.9, green: 0.75, blue: 0.0)
        case .green:  return .green
        case .teal:   return .teal
        case .purple: return .purple
        case .pink:   return .pink
        case .indigo: return .indigo
        case .gray:   return .gray
        }
    }
}

// MARK: - ProjectIcon

enum ProjectIcon: String, Codable, CaseIterable {
    case folder       = "folder.fill"
    case star         = "star.fill"
    case briefcase    = "briefcase.fill"
    case heart        = "heart.fill"
    case house        = "house.fill"
    case cart         = "cart.fill"
    case book         = "book.fill"
    case gamecontroller = "gamecontroller.fill"
    case music        = "music.note"
    case airplane     = "airplane"
    case dumbbell     = "dumbbell.fill"
    case fork         = "fork.knife"
    case graduationcap = "graduationcap.fill"
    case person       = "person.fill"
    case lightbulb    = "lightbulb.fill"

    var sfSymbol: String { rawValue }
}

// MARK: - Project

@Model
final class Project {
    var id: UUID
    var name: String
    var colorName: ProjectColor
    var iconName: ProjectIcon
    var notes: String
    var isArchived: Bool
    var createdAt: Date
    var order: Int

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.project)
    var tasks: [TaskItem]

    var activeTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [TaskItem] {
        tasks.filter(\.isCompleted)
    }

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(tasks.count)
    }

    init(
        name: String,
        color: ProjectColor = .blue,
        icon: ProjectIcon = .folder,
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.colorName = color
        self.iconName = icon
        self.notes = notes
        self.isArchived = false
        self.createdAt = Date()
        self.order = 0
        self.tasks = []
    }
}
