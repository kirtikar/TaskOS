import XCTest
import UserNotifications
@testable import taskOS

final class NotificationServiceTests: XCTestCase {

    func test_initialState_doesNotCrash() {
        let _ = NotificationService()
    }

    func test_cancelAll_noCrash() {
        NotificationService().cancelAll()
    }

    func test_cancelReminder_unknownId_noCrash() {
        NotificationService().cancelReminder(id: UUID().uuidString)
    }

    func test_cancelReminder_removesBothIds() async {
        let id      = "unit-test-\(UUID().uuidString)"
        let content = UNMutableNotificationContent()
        content.title = "Test"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)

        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: "\(id)_repeat", content: content, trigger: trigger))

        NotificationService().cancelReminder(id: id)

        let ids = Set(
            await UNUserNotificationCenter.current()
                .pendingNotificationRequests()
                .map(\.identifier)
        )
        XCTAssertFalse(ids.contains(id))
        XCTAssertFalse(ids.contains("\(id)_repeat"))
    }

    func test_scheduleReminder_noCrashWhenUnauthorized() async {
        await NotificationService().scheduleReminder(
            id: UUID().uuidString,
            title: "Test",
            body: "Body",
            date: Date().addingTimeInterval(3600)
        )
    }

    func test_scheduleRepeating_allFrequencies_noCrash() async {
        let service = NotificationService()
        let date    = Date().addingTimeInterval(3600)
        for frequency in RepeatFrequency.allCases {
            await service.scheduleRepeatingReminder(
                id: UUID().uuidString,
                title: "T", body: "B",
                date: date, frequency: frequency
            )
        }
    }

    func test_updateBadgeCount_noCrash() async {
        let service = NotificationService()
        await service.updateBadgeCount(0)
        await service.updateBadgeCount(5)
    }
}
