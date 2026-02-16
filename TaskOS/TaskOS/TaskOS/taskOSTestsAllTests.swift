import XCTest
import SwiftUI
import SwiftData
@testable import taskOS

// MARK: - ThemeManager

final class ThemeManagerTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "app_theme")
        UserDefaults.standard.removeObject(forKey: "accent_color")
        UserDefaults.standard.removeObject(forKey: "large_titles")
    }

    func test_appTheme_rawValues() {
        XCTAssertEqual(AppTheme.system.rawValue, "System")
        XCTAssertEqual(AppTheme.light.rawValue,  "Light")
        XCTAssertEqual(AppTheme.dark.rawValue,   "Dark")
    }

    func test_appTheme_colorSchemes() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme,  .dark)
    }

    func test_appTheme_threeCases_distinctSymbols() {
        XCTAssertEqual(AppTheme.allCases.count, 3)
        let symbols = AppTheme.allCases.map(\.sfSymbol)
        XCTAssertEqual(Set(symbols).count, 3)
    }

    func test_themeManager_persistsTheme() {
        ThemeManager.shared.theme = .dark
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app_theme"), "Dark")
    }

    func test_themeManager_persistsLargeTitles() {
        ThemeManager.shared.preferLargeTitles = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "large_titles"))
        ThemeManager.shared.preferLargeTitles = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "large_titles"))
    }

    func test_themeManager_persistsAccentColor() {
        ThemeManager.shared.accentColorName = "Purple"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "accent_color"), "Purple")
    }

    func test_accentOption_eightCases() {
        XCTAssertEqual(AccentOption.allCases.count, 8)
    }

    func test_accentOption_rawValues() {
        let expected = ["Blue", "Indigo", "Purple", "Pink", "Red", "Orange", "Teal", "Green"]
        XCTAssertEqual(AccentOption.allCases.map(\.rawValue), expected)
    }

    func test_userDefaults_contains() {
        let key = "test_\(UUID().uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        XCTAssertFalse(UserDefaults.standard.contains(key))
        UserDefaults.standard.set("v", forKey: key)
        XCTAssertTrue(UserDefaults.standard.contains(key))
    }
}

// MARK: - DesignSystem

final class DesignSystemTests: XCTestCase {

    func test_spacing_ascending() {
        XCTAssertLessThan(DS.Spacing.xxs, DS.Spacing.xs)
        XCTAssertLessThan(DS.Spacing.xs,  DS.Spacing.sm)
        XCTAssertLessThan(DS.Spacing.sm,  DS.Spacing.md)
        XCTAssertLessThan(DS.Spacing.md,  DS.Spacing.lg)
        XCTAssertLessThan(DS.Spacing.lg,  DS.Spacing.xl)
        XCTAssertLessThan(DS.Spacing.xl,  DS.Spacing.xxl)
        XCTAssertLessThan(DS.Spacing.xxl, DS.Spacing.xxxl)
    }

    func test_radius_ascending() {
        XCTAssertLessThan(DS.Radius.xs, DS.Radius.sm)
        XCTAssertLessThan(DS.Radius.sm, DS.Radius.md)
        XCTAssertLessThan(DS.Radius.md, DS.Radius.lg)
        XCTAssertLessThan(DS.Radius.lg, DS.Radius.pill)
    }

    func test_priorityColor_allCasesNoCrash() {
        Priority.allCases.forEach { _ = $0.color }
    }
}

// MARK: - Project Enums

final class ProjectEnumTests: XCTestCase {

    func test_projectColor_tenCases() {
        XCTAssertEqual(ProjectColor.allCases.count, 10)
    }

    func test_projectColor_rawValuesLowercase() {
        for c in ProjectColor.allCases {
            XCTAssertEqual(c.rawValue, c.rawValue.lowercased())
        }
    }

    func test_projectIcon_sfSymbolEqualsRawValue() {
        for icon in ProjectIcon.allCases { XCTAssertEqual(icon.sfSymbol, icon.rawValue) }
    }
}

// MARK: - Color Hex Extension

final class ColorHexExtensionTests: XCTestCase {

    func test_validHexWithHash()    { XCTAssertNotNil(Color(hex: "#007AFF")) }
    func test_validHexWithoutHash() { XCTAssertNotNil(Color(hex: "007AFF")) }
    func test_invalidHex()          { XCTAssertNil(Color(hex: "ZZZZZZ")) }
    func test_emptyString()         { XCTAssertNil(Color(hex: "")) }
    func test_redHex()              { XCTAssertNotNil(Color(hex: "#FF0000")) }
}

// MARK: - SwiftData Integration

private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: Task.self, Project.self, Tag.self, Subtask.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

final class TaskPersistenceTests: XCTestCase {

    func test_insertAndFetch() throws {
        let ctx = try makeContext()
        ctx.insert(Task(title: "Buy milk"))
        try ctx.save()
        let fetched = try ctx.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Buy milk")
    }

    func test_insertMultiple() throws {
        let ctx = try makeContext()
        ["A", "B", "C"].forEach { ctx.insert(Task(title: $0)) }
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Task>()).count, 3)
    }

    func test_delete() throws {
        let ctx = try makeContext()
        let t = Task(title: "Temp"); ctx.insert(t); try ctx.save()
        ctx.delete(t); try ctx.save()
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<Task>()).isEmpty)
    }

    func test_update() throws {
        let ctx = try makeContext()
        let t = Task(title: "Old"); ctx.insert(t); try ctx.save()
        t.title = "New"; try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Task>()).first?.title, "New")
    }

    func test_propertiesRoundTrip() throws {
        let ctx = try makeContext()
        let due = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        ctx.insert(Task(title: "RT", notes: "N", dueDate: due, priority: .high))
        try ctx.save()
        let f = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Task>()).first)
        XCTAssertEqual(f.priority, .high)
        XCTAssertNotNil(f.dueDate)
    }
}

final class ProjectPersistenceTests: XCTestCase {

    func test_insertAndFetch() throws {
        let ctx = try makeContext()
        ctx.insert(Project(name: "Work", color: .indigo, icon: .briefcase))
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Project>()).first?.name, "Work")
    }

    func test_progressZeroNoTasks() throws {
        let ctx = try makeContext()
        let p = Project(name: "E"); ctx.insert(p); try ctx.save()
        XCTAssertEqual(p.progress, 0)
    }

    func test_progressCalculation() throws {
        let ctx = try makeContext()
        let p = Project(name: "M"); ctx.insert(p)
        let t1 = Task(title: "D1", project: p); t1.isCompleted = true; ctx.insert(t1)
        let t2 = Task(title: "D2", project: p); t2.isCompleted = true; ctx.insert(t2)
        let t3 = Task(title: "P",  project: p);                        ctx.insert(t3)
        p.tasks = [t1, t2, t3]; try ctx.save()
        XCTAssertEqual(p.progress, 2.0 / 3.0, accuracy: 0.001)
    }

    func test_deleteProject_nullifiesTasks() throws {
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

    func test_insertAndFetch() throws {
        let ctx = try makeContext()
        ctx.insert(Tag(name: "Work", color: "#FF0000")); try ctx.save()
        let f = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Tag>()).first)
        XCTAssertEqual(f.name, "Work")
        XCTAssertEqual(f.colorName, "#FF0000")
    }

    func test_deleteTag_doesNotDeleteTasks() throws {
        let ctx = try makeContext()
        let tag = Tag(name: "T"); let task = Task(title: "TT")
        ctx.insert(tag); ctx.insert(task)
        task.tags = [tag]; tag.tasks = [task]; try ctx.save()
        ctx.delete(tag); try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Task>()).count, 1)
    }
}

final class SubtaskPersistenceTests: XCTestCase {

    func test_subtaskLinkedToParent() throws {
        let ctx = try makeContext()
        let task = Task(title: "P"); let sub = Subtask(title: "S")
        ctx.insert(task); ctx.insert(sub)
        task.subtasks.append(sub); sub.parentTask = task; try ctx.save()
        let f = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Task>()).first)
        XCTAssertEqual(f.subtasks.first?.title, "S")
    }

    func test_completedCount_updatesAfterToggle() throws {
        let ctx = try makeContext()
        let task = Task(title: "P")
        let s1 = Subtask(title: "1"); let s2 = Subtask(title: "2")
        ctx.insert(task); ctx.insert(s1); ctx.insert(s2)
        task.subtasks = [s1, s2]; try ctx.save()
        XCTAssertEqual(task.completedSubtasks, 0)
        s1.isCompleted = true; try ctx.save()
        XCTAssertEqual(task.completedSubtasks, 1)
    }
}
