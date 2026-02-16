import Foundation
import UserNotifications
import SwiftUI

// MARK: - NotificationService

@Observable
final class NotificationService {
    var isAuthorized = false

    init() {
        Task { await checkPermission() }
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
        }
    }

    // MARK: - Schedule

    func scheduleReminder(id: String, title: String, body: String, date: Date) async {
        guard isAuthorized else {
            let granted = await requestPermission()
            guard granted else { return }
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body.isEmpty ? "Tap to open task" : body
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["task_id": id]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    // MARK: - Repeating

    func scheduleRepeatingReminder(
        id: String,
        title: String,
        body: String,
        date: Date,
        frequency: RepeatFrequency
    ) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["task_id": id]

        let cal = Calendar.current
        var components: DateComponents

        switch frequency {
        case .daily:
            components = cal.dateComponents([.hour, .minute], from: date)
        case .weekly:
            components = cal.dateComponents([.weekday, .hour, .minute], from: date)
        case .monthly:
            components = cal.dateComponents([.day, .hour, .minute], from: date)
        case .yearly:
            components = cal.dateComponents([.month, .day, .hour, .minute], from: date)
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "\(id)_repeat",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule repeating notification: \(error)")
        }
    }

    // MARK: - Cancel

    func cancelReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id, "\(id)_repeat"]
        )
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Badge

    func updateBadgeCount(_ count: Int) async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
        } catch {
            print("Failed to update badge: \(error)")
        }
    }
}
