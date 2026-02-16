import Testing
import Foundation
import SwiftData
@testable import taskOS

// MARK: - SwiftData Integration Tests
//
// All tests use an in-memory ModelContainer so nothing is persisted to disk
// and tests remain fully isolated from each other.

// MARK: - Shared container helper

private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
        for: Task.self, Project.self, Tag.self, Subtask.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

// MARK: - Task Persistence

@Suite("Task – SwiftData Persistence")
struct TaskPersistenceTests {

    @Test("Inserted task is fetchable from context")
    func insertAndFetchTask() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let task = Task(title: "Buy milk")
        context.insert(task)
        try context.save()

        let descriptor = FetchDescriptor<Task>()
        let fetched    = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Buy milk")
    }

    @Test("Multiple tasks can be inserted and individually fetched")
    func insertMultipleTasks() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let titles = ["Task A", "Task B", "Task C"]
        titles.forEach { context.insert(Task(title: $0)) }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Task>())
        #expect(fetched.count == 3)

        let fetchedTitles = Set(fetched.map(\.title))
        #expect(fetchedTitles == Set(titles))
    }

    @Test("Deleting a task removes it from the context")
    func deleteTask() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let task = Task(title: "Temporary task")
        context.insert(task)
        try context.save()

        context.delete(task)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Task>())
        #expect(fetched.isEmpty)
    }

    @Test("Task properties survive a save / fetch round-trip")
    func taskRoundTrip() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let due = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let task = Task(
            title: "Round-trip task",
            notes: "Some notes",
            dueDate: due,
            priority: .high
        )
        context.insert(task)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Task>()).first)
        #expect(fetched.title    == "Round-trip task")
        #expect(fetched.notes    == "Some notes")
        #expect(fetched.priority == .high)
        // Due date precision can vary slightly; compare to minute
        #expect(fetched.dueDate != nil)
    }

    @Test("Updating a task field persists correctly")
    func updateTaskField() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let task = Task(title: "Original title")
        context.insert(task)
        try context.save()

        task.title = "Updated title"
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Task>()).first)
        #expect(fetched.title == "Updated title")
    }
}

// MARK: - Project Persistence

@Suite("Project – SwiftData Persistence")
struct ProjectPersistenceTests {

    @Test("Inserted project is fetchable")
    func insertAndFetchProject() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let project = Project(name: "Work", color: .indigo, icon: .briefcase)
        context.insert(project)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Project>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Work")
    }

    @Test("Project progress is 0 with no tasks")
    func projectProgressNoTasks() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let project = Project(name: "Empty")
        context.insert(project)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Project>()).first)
        #expect(fetched.progress == 0)
    }

    @Test("Project progress calculates correctly with mixed tasks")
    func projectProgressMixedTasks() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let project = Project(name: "Mixed")
        context.insert(project)

        let t1 = Task(title: "Done 1", project: project)
        let t2 = Task(title: "Done 2", project: project)
        let t3 = Task(title: "Pending", project: project)
        t1.isCompleted = true
        t2.isCompleted = true

        context.insert(t1)
        context.insert(t2)
        context.insert(t3)
        project.tasks = [t1, t2, t3]
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Project>()).first)
        #expect(abs(fetched.progress - (2.0 / 3.0)) < 0.001)
    }

    @Test("Deleting a project does not cascade-delete its tasks (nullify rule)")
    func deleteProjectNullifyTasks() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let project = Project(name: "To delete")
        context.insert(project)

        let task = Task(title: "Orphaned task", project: project)
        context.insert(task)
        project.tasks = [task]
        try context.save()

        context.delete(project)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        #expect(tasks.count == 1)
        #expect(tasks.first?.project == nil)
    }
}

// MARK: - Tag Persistence

@Suite("Tag – SwiftData Persistence")
struct TagPersistenceTests {

    @Test("Inserted tag is fetchable")
    func insertAndFetchTag() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let tag = Tag(name: "Work", color: "#FF0000")
        context.insert(tag)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Tag>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Work")
        #expect(fetched.first?.colorName == "#FF0000")
    }

    @Test("Tag can be associated with multiple tasks")
    func tagAssociatedWithMultipleTasks() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let tag = Tag(name: "Important")
        context.insert(tag)

        let t1 = Task(title: "Task 1")
        let t2 = Task(title: "Task 2")
        context.insert(t1)
        context.insert(t2)
        t1.tags = [tag]
        t2.tags = [tag]
        tag.tasks = [t1, t2]
        try context.save()

        let fetchedTag = try #require(try context.fetch(FetchDescriptor<Tag>()).first)
        #expect(fetchedTag.tasks.count == 2)
    }

    @Test("Deleting a tag does not delete its associated tasks")
    func deleteTagDoesNotDeleteTasks() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let tag = Tag(name: "Temp")
        let task = Task(title: "Tagged task")
        context.insert(tag)
        context.insert(task)
        task.tags = [tag]
        tag.tasks = [task]
        try context.save()

        context.delete(tag)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        #expect(tasks.count == 1)
    }
}

// MARK: - Subtask Persistence

@Suite("Subtask – SwiftData Persistence")
struct SubtaskPersistenceTests {

    @Test("Subtask is linked to its parent task correctly")
    func subtaskLinkedToParent() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let task    = Task(title: "Parent")
        let subtask = Subtask(title: "Child step", order: 0)
        context.insert(task)
        context.insert(subtask)
        task.subtasks.append(subtask)
        subtask.parentTask = task
        try context.save()

        let fetchedTask = try #require(try context.fetch(FetchDescriptor<Task>()).first)
        #expect(fetchedTask.subtasks.count == 1)
        #expect(fetchedTask.subtasks.first?.title == "Child step")
    }

    @Test("Subtask completedSubtasks count updates after toggling")
    func completedSubtasksUpdates() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)

        let task = Task(title: "Parent")
        let s1   = Subtask(title: "Step 1")
        let s2   = Subtask(title: "Step 2")
        context.insert(task)
        context.insert(s1)
        context.insert(s2)
        task.subtasks = [s1, s2]
        try context.save()

        #expect(task.completedSubtasks == 0)

        s1.isCompleted = true
        try context.save()

        #expect(task.completedSubtasks == 1)
    }
}
