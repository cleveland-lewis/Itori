import Foundation
import UserNotifications

protocol NotificationSchedulable {
    func requestNotificationAuthorization() async throws -> Bool
    func scheduleNotification(
        identifier: String,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger?
    ) async throws
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func notificationSettings() async -> UNNotificationSettings
    func removePendingNotificationRequests(withIdentifiers: [String])
    func removeAllPendingNotificationRequests()
}

// Default implementation for production
extension UNUserNotificationCenter: NotificationSchedulable {
    func requestNotificationAuthorization() async throws -> Bool {
        try await requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleNotification(
        identifier: String,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger?
    ) async throws {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await add(request)
    }
}
