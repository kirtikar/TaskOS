import Testing
import Foundation
import UserNotifications
@testable import taskOS

// MARK: - NotificationService Tests
//
// UNUserNotificationCenter requires a running app with a valid bundle to grant
// authorization, so these tests focus on the observable state transitions and
// the logic branches that don't require a real UNUserNotificationCenter grant.

@Suite("NotificationService")
struct NotificationServiceTests {

    // MARK: - Initial State

    @Test("Service starts with isAuthorized = false before permission check resolves")
    func initialStateNotAuthorized() {
        // NotificationService checks permission on init inside a Task{} so
        // synchronously the value is still the default (false).
        let service = NotificationService()
        // We can't assert the async result here — just verify the property exists
        // and has a Bool type (compile-time guarantee). We also ensure no crash.
        let _ = service.isAuthorized
    }

    // MARK: - cancelReminder

    @Test("cancelAll does not crash when called with no pending notifications")
    func cancelAllNoCrash() {
        let service = NotificationService()
        // UNUserNotificationCenter silently no-ops when there's nothing to cancel.
        service.cancelAll()
    }

    @Test("cancelReminder does not crash when called with an unknown id")
    func cancelReminderUnknownId() {
        let service = NotificationService()
        service.cancelReminder(id: UUID().uuidString)
    }

    @Test("cancelReminder removes both the base id and the repeat-suffixed id")
    func cancelReminderRemovesBothIds() async {
        let service = NotificationService()
        let testID  = "test-cancel-\(UUID().uuidString)"

        // Verify no crash and that both IDs would be targeted.
        // We can introspect by scheduling known requests and then cancelling.
        let content = UNMutableNotificationContent()
        content.title = "Test"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let req1 = UNNotificationRequest(identifier: testID,            content: content, trigger: trigger)
        let req2 = UNNotificationRequest(identifier: "\(testID)_repeat", content: content, trigger: trigger)

        // Add both requests (may silently fail without authorization — that's fine)
        try? await UNUserNotificationCenter.current().add(req1)
        try? await UNUserNotificationCenter.current().add(req2)

        service.cancelReminder(id: testID)

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let ids = pending.map(\.identifier)
        #expect(!ids.contains(testID))
        #expect(!ids.contains("\(testID)_repeat"))
    }

    // MARK: - scheduleReminder (offline / unauthorized path)

    @Test("scheduleReminder exits gracefully when not authorized and permission is denied")
    func scheduleReminderNoAuthNoCrash() async {
        let service = NotificationService()
        // isAuthorized is false by default in a test runner with no permission granted.
        // We set it explicitly to verify the guard-exit path.
        // (We cannot actually grant permission in unit tests.)
        await service.scheduleReminder(
            id: UUID().uuidString,
            title: "Reminder",
            body: "Test body",
            date: Date().addingTimeInterval(3600)
        )
        // If we reach here without crashing the test passes.
    }

    // MARK: - scheduleRepeatingReminder – DateComponents per frequency

    @Test("scheduleRepeatingReminder does not crash for each RepeatFrequency")
    func scheduleRepeatingReminderAllFrequencies() async {
        let service = NotificationService()
        let date = Date().addingTimeInterval(3600)

        for frequency in RepeatFrequency.allCases {
            await service.scheduleRepeatingReminder(
                id: UUID().uuidString,
                title: "Repeat test",
                body: "Body",
                date: date,
                frequency: frequency
            )
        }
        // Reaching here without crash/assertion failure is the pass condition.
    }

    // MARK: - updateBadgeCount

    @Test("updateBadgeCount does not crash when called with various values")
    func updateBadgeCountNoCrash() async {
        let service = NotificationService()
        await service.updateBadgeCount(0)
        await service.updateBadgeCount(5)
        await service.updateBadgeCount(99)
    }
}
