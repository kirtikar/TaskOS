import Foundation
import SwiftData
import SwiftUI

@Observable
final class ProjectsViewModel {
    var showNewProjectSheet = false
    var showArchivedProjects = false
    var editingProject: Project? = nil

    // New project form state
    var newProjectName = ""
    var newProjectColor: ProjectColor = .blue
    var newProjectIcon: ProjectIcon = .folder
    var newProjectNotes = ""

    func createProject(context: ModelContext) {
        guard !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let project = Project(
            name: newProjectName.trimmingCharacters(in: .whitespaces),
            color: newProjectColor,
            icon: newProjectIcon,
            notes: newProjectNotes
        )
        context.insert(project)
        resetForm()
    }

    func deleteProject(_ project: Project, context: ModelContext) {
        // Orphan tasks back to inbox
        project.tasks.forEach {
            $0.project = nil
            $0.isInInbox = true
        }
        context.delete(project)
    }

    func archiveProject(_ project: Project) {
        withAnimation(DS.Animation.quick) {
            project.isArchived.toggle()
        }
    }

    func resetForm() {
        newProjectName = ""
        newProjectColor = .blue
        newProjectIcon = .folder
        newProjectNotes = ""
    }
}

// MARK: - ProjectDetailViewModel

@Observable
final class ProjectDetailViewModel {
    var sortOrder: InboxViewModel.SortOrder = .createdDate
    var showCompleted = false
    var showEditSheet = false

    func sortedTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        let filtered = showCompleted ? tasks : tasks.filter { !$0.isCompleted }
        return filtered.sorted { a, b in
            switch sortOrder {
            case .createdDate: return a.createdAt > b.createdAt
            case .priority:    return a.priority.rawValue > b.priority.rawValue
            case .title:       return a.title.localizedCompare(b.title) == .orderedAscending
            case .dueDate:
                return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
            }
        }
    }

    func toggleTask(_ task: TaskItem) {
        withAnimation(DS.Animation.quick) {
            task.isCompleted.toggle()
            task.completedAt = task.isCompleted ? Date() : nil
        }
    }
}
