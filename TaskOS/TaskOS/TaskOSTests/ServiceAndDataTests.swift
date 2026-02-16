import XCTest
import SwiftData
import UserNotifications
@testable import taskOS

// MARK: - Notification Tests

final class NotificationTests: XCTestCase {

    func testInitDoesNotCrash() { let _ = NotificationService() }
    func testCancelAllNoCrash() { NotificationService().cancelAll() }
    func testCancelUnknownIdNoCrash() { NotificationService().cancelReminder(id: UUID().uuidString) }

    func testCancelReminderRemovesBothIds() async {
        let id = "unit-\(UUID().uuidString)"
        let content = UNMutableNotificationContent(); content.title = "T"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "\(id)_repeat", content: content, trigger: trigger))
        NotificationService().cancelReminder(id: id)
        let ids = Set(await UNUserNotificationCenter.current().pendingNotificationRequests().map(\.identifier))
        XCTAssertFalse(ids.contains(id))
        XCTAssertFalse(ids.contains("\(id)_repeat"))
    }

    func testScheduleReminderNoCrashWhenUnauthorized() async {
        await NotificationService().scheduleReminder(id: UUID().uuidString, title: "T", body: "B", date: Date().addingTimeInterval(3600))
    }

    func testScheduleRepeatingAllFrequenciesNoCrash() async {
        let s = NotificationService()
        for f in RepeatFrequency.allCases {
            await s.scheduleRepeatingReminder(id: UUID().uuidString, title: "T", body: "B", date: Date().addingTimeInterval(3600), frequency: f)
        }
    }

    func testUpdateBadgeNoCrash() async {
        await NotificationService().updateBadgeCount(0)
        await NotificationService().updateBadgeCount(5)
    }
}

// MARK: - SwiftData Tests

private func makeContext() throws -> ModelContext {
    let c = try ModelContainer(for: Task.self, Project.self, Tag.self, Subtask.self,
                               configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return ModelContext(c)
}

final class TaskPersistenceTests: XCTestCase {

    func testInsertAndFetch() throws {
        let ctx = try makeContext()
        ctx.insert(Task(title: "Buy milk")); try ctx.save()
        let fetched = try ctx.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Buy milk")
    }

    func testInsertMultiple() throws {
        let ctx = try makeContext()
        ["A","B","C"].forEach { ctx.insert(Task(title: $0)) }; try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Task>()).count, 3)
    }

    func testDelete() throws {
        let ctx = try makeContext()
        let t = Task(title: "Temp"); ctx.insert(t); try ctx.save()
        ctx.delete(t); try ctx.save()
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<Task>()).isEmpty)
    }

    func testUpdate() throws {
        let ctx = try makeContext()
        let t = Task(title: "Old"); ctx.insert(t); try ctx.save()
        t.title = "New"; try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Task>()).first?.title, "New")
    }

    func testRoundTrip() throws {
        let ctx = try makeContext()
        let due = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        ctx.insert(Task(title: "RT", notes: "N", dueDate: due, priority: .high)); try ctx.save()
        let f = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Task>()).first)
        XCTAssertEqual(f.priority, .high)
        XCTAssertNotNil(f.dueDate)
    }
}

final class ProjectPersistenceTests: XCTestCase {

    func testInsertAndFetch() throws {
        let ctx = try makeContext()
        ctx.insert(Project(name: "Work", color: .indigo, icon: .briefcase)); try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Project>()).first?.name, "Work")
    }

    func testProgressZero() throws {
        let ctx = try makeContext()
        let p = Project(name: "E"); ctx.insert(p); try ctx.save()
        XCTAssertEqual(p.progress, 0)
    }

    func testProgressCalculation() throws {
        let ctx = try makeContext()
        let p = Project(name: "M"); ctx.insert(p)
        let t1 = Task(title: "D1", project: p); t1.isCompleted = true; ctx.insert(t1)
        let t2 = Task(title: "D2", project: p); t2.isCompleted = true; ctx.insert(t2)
        let t3 = Task(title: "P",  project: p);                        ctx.insert(t3)
        p.tasks = [t1, t2, t3]; try ctx.save()
        XCTAssertEqual(p.progress, 2.0/3.0, accuracy: 0.001)
    }

    func testDeleteProjectNullifiesTasks() throws {
        let ctx = try makeContext()
        let p = Project(name: "Del"); ctx.insert(p)
        let t = Task(title: "T", project: p); ctx.insert(t)
        p.tasks = [t]; try ctx.save()
        ctx.delete(p); try ctx.save()
        let tasks = try ctx.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertNil(tasks.first?.project)
    }
}

final class TagPersistenceTests: XCTestCase {

    func testInsertAndFetch() throws {
        let ctx = try makeContext()
        ctx.insert(Tag(name: "Work", color: "#FF0000")); try ctx.save()
        let f = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Tag>()).first)
        XCTAssertEqual(f.name, "Work")
        XCTAssertEqual(f.colorName, "#FF0000")
    }

    func testDeleteTagDoesNotDeleteTasks() throws {
        let ctx = try makeContext()
        let tag = Tag(name: "T"); let task = Task(title: "TT")
        ctx.insert(tag); ctx.insert(task)
        task.tags = [tag]; tag.tasks = [task]; try ctx.save()
        ctx.delete(tag); try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Task>()).count, 1)
    }
}

final class SubtaskPersistenceTests: XCTestCase {

    func testLinkedToParent() throws {
        let ctx = try makeContext()
        let t = Task(title: "P"); let s = Subtask(title: "S")
        ctx.insert(t); ctx.insert(s)
        t.subtasks.append(s); s.parentTask = t; try ctx.save()
        XCTAssertEqual(try XCTUnwrap(try ctx.fetch(FetchDescriptor<Task>()).first).subtasks.first?.title, "S")
    }

    func testCompletedCountUpdates() throws {
        let ctx = try makeContext()
        let t = Task(title: "P"); let s1 = Subtask(title: "1"); let s2 = Subtask(title: "2")
        ctx.insert(t); ctx.insert(s1); ctx.insert(s2)
        t.subtasks = [s1, s2]; try ctx.save()
        XCTAssertEqual(t.completedSubtasks, 0)
        s1.isCompleted = true; try ctx.save()
        XCTAssertEqual(t.completedSubtasks, 1)
    }
}
