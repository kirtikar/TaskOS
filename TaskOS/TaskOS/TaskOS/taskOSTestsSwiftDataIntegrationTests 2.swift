import XCTest
import SwiftData
@testable import taskOS

// MARK: - Shared helper

private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: Task.self, Project.self, Tag.self, Subtask.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

// MARK: - Task Persistence

final class TaskPersistenceTests: XCTestCase {

    func test_insertAndFetch() throws {
        let context = try makeContext()
        context.insert(Task(title: "Buy milk"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Buy milk")
    }

    func test_insertMultiple() throws {
        let context = try makeContext()
        ["Task A", "Task B", "Task C"].forEach { context.insert(Task(title: $0)) }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(fetched.count, 3)
        XCTAssertEqual(Set(fetched.map(\.title)), ["Task A", "Task B", "Task C"])
    }

    func test_delete() throws {
        let context = try makeContext()
        let task = Task(title: "Temp")
        context.insert(task)
        try context.save()

        context.delete(task)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<Task>()).isEmpty)
    }

    func test_propertiesRoundTrip() throws {
        let context = try makeContext()
        let due  = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        context.insert(Task(title: "Round-trip", notes: "Notes", dueDate: due, priority: .high))
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Task>()).first)
        XCTAssertEqual(fetched.title,    "Round-trip")
        XCTAssertEqual(fetched.notes,    "Notes")
        XCTAssertEqual(fetched.priority, .high)
        XCTAssertNotNil(fetched.dueDate)
    }

    func test_updateField() throws {
        let context = try makeContext()
        let task = Task(title: "Original")
        context.insert(task)
        try context.save()

        task.title = "Updated"
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Task>()).first)
        XCTAssertEqual(fetched.title, "Updated")
    }
}

// MARK: - Project Persistence

final class ProjectPersistenceTests: XCTestCase {

    func test_insertAndFetch() throws {
        let context = try makeContext()
        context.insert(Project(name: "Work", color: .indigo, icon: .briefcase))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Work")
    }

    func test_progressIsZeroWithNoTasks() throws {
        let context = try makeContext()
        let project = Project(name: "Empty")
        context.insert(project)
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Project>()).first)
        XCTAssertEqual(fetched.progress, 0)
    }

    func test_progressCalculatesCorrectly() throws {
        let context = try makeContext()
        let project = Project(name: "Mixed")
        context.insert(project)

        let t1 = Task(title: "Done 1", project: project); t1.isCompleted = true
        let t2 = Task(title: "Done 2", project: project); t2.isCompleted = true
        let t3 = Task(title: "Pending", project: project)
        [t1, t2, t3].forEach { context.insert($0) }
        project.tasks = [t1, t2, t3]
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Project>()).first)
        XCTAssertEqual(fetched.progress, 2.0 / 3.0, accuracy: 0.001)
    }

    func test_deleteProject_nullifiesTaskRelationship() throws {
        let context = try makeContext()
        let project = Project(name: "To delete")
        context.insert(project)
        let task = Task(title: "Orphaned", project: project)
        context.insert(task)
        project.tasks = [task]
        try context.save()

        context.delete(project)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertNil(tasks.first?.project)
    }
}

// MARK: - Tag Persistence

final class TagPersistenceTests: XCTestCase {

    func test_insertAndFetch() throws {
        let context = try makeContext()
        context.insert(Tag(name: "Work", color: "#FF0000"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Tag>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Work")
        XCTAssertEqual(fetched.first?.colorName, "#FF0000")
    }

    func test_tagAssociatedWithMultipleTasks() throws {
        let context = try makeContext()
        let tag = Tag(name: "Important")
        context.insert(tag)
        let t1 = Task(title: "Task 1"); context.insert(t1)
        let t2 = Task(title: "Task 2"); context.insert(t2)
        t1.tags = [tag]; t2.tags = [tag]
        tag.tasks = [t1, t2]
        try context.save()

        let fetchedTag = try XCTUnwrap(try context.fetch(FetchDescriptor<Tag>()).first)
        XCTAssertEqual(fetchedTag.tasks.count, 2)
    }

    func test_deleteTag_doesNotDeleteTasks() throws {
        let context = try makeContext()
        let tag  = Tag(name: "Temp")
        let task = Task(title: "Tagged task")
        context.insert(tag); context.insert(task)
        task.tags = [tag]; tag.tasks = [task]
        try context.save()

        context.delete(tag)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<Task>()).count, 1)
    }
}

// MARK: - Subtask Persistence

final class SubtaskPersistenceTests: XCTestCase {

    func test_subtaskLinkedToParent() throws {
        let context = try makeContext()
        let task    = Task(title: "Parent")
        let subtask = Subtask(title: "Child step", order: 0)
        context.insert(task); context.insert(subtask)
        task.subtasks.append(subtask)
        subtask.parentTask = task
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Task>()).first)
        XCTAssertEqual(fetched.subtasks.count, 1)
        XCTAssertEqual(fetched.subtasks.first?.title, "Child step")
    }

    func test_completedSubtasksCountUpdatesAfterToggle() throws {
        let context = try makeContext()
        let task = Task(title: "Parent")
        let s1   = Subtask(title: "Step 1")
        let s2   = Subtask(title: "Step 2")
        context.insert(task); context.insert(s1); context.insert(s2)
        task.subtasks = [s1, s2]
        try context.save()

        XCTAssertEqual(task.completedSubtasks, 0)
        s1.isCompleted = true
        try context.save()
        XCTAssertEqual(task.completedSubtasks, 1)
    }
}
