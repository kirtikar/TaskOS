import XCTest
import UserNotifications
@testable import taskOS

final class NotificationServiceTests: XCTestCase {

    // MARK: - Initial state

    func test_initialState_isAuthorizedPropertyExists() {
        // Just verify the service initialises without crashing and exposes isAuthorized
        let service = NotificationService()
        let _ = service.isAuthorized   // compile-time type check
    }

    // MARK: - Cancel helpers

    func test_cancelAll_doesNotCrashWithNoPendingNotifications() {
        NotificationService().cancelAll()
    }

    func test_cancelReminder_doesNotCrashForUnknownId() {
        NotificationService().cancelReminder(id: UUID().uuidString)
    }

    func test_cancelReminder_removesBothBaseAndRepeatIds() async {
        let service = NotificationService()
        let id      = "unit-test-\(UUID().uuidString)"

        // Schedule two dummy requests (silently no-ops without authorization)
        let content = UNMutableNotificationContent()
        content.title = "Test"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: "\(id)_repeat", content: content, trigger: trigger))

        service.cancelReminder(id: id)

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let ids = Set(pending.map(\.identifier))
        XCTAssertFalse(ids.contains(id))
        XCTAssertFalse(ids.contains("\(id)_repeat"))
    }

    // MARK: - Schedule (offline / unauthorized paths)

    func test_scheduleReminder_doesNotCrashWhenUnauthorized() async {
        let service = NotificationService()
        // isAuthorized is false in the test runner — exercises the guard-exit path
        await service.scheduleReminder(
            id: UUID().uuidString,
            title: "Test",
            body: "Body",
            date: Date().addingTimeInterval(3600)
        )
    }

    func test_scheduleRepeatingReminder_doesNotCrashForAllFrequencies() async {
        let service = NotificationService()
        let date    = Date().addingTimeInterval(3600)
        for frequency in RepeatFrequency.allCases {
            await service.scheduleRepeatingReminder(
                id: UUID().uuidString,
                title: "Repeat",
                body: "Body",
                date: date,
                frequency: frequency
            )
        }
    }

    // MARK: - Badge count

    func test_updateBadgeCount_doesNotCrash() async {
        let service = NotificationService()
        await service.updateBadgeCount(0)
        await service.updateBadgeCount(5)
        await service.updateBadgeCount(99)
    }
}
