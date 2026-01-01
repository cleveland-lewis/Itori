import Foundation
import UserNotifications
@testable import Roots

class MockNotificationCenter: NotificationSchedulable {
    var isAuthorized = true
    var shouldFailAuthorization = false
    var shouldFailScheduling = false
    var scheduledNotifications: [UNNotificationRequest] = []
    var authorizationStatus: UNAuthorizationStatus = .authorized
    
    func requestNotificationAuthorization() async throws -> Bool {
        if shouldFailAuthorization {
            throw NSError(domain: "UNErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "User denied authorization"])
        }
        return isAuthorized
    }
    
    func scheduleNotification(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger?) async throws {
        if shouldFailScheduling {
            throw NSError(domain: "UNErrorDomain", code: 1407, userInfo: [NSLocalizedDescriptionKey: "Notifications not authorized"])
        }
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        scheduledNotifications.append(request)
    }
    
    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        return scheduledNotifications
    }
    
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        scheduledNotifications.removeAll { identifiers.contains($0.identifier) }
    }
    
    func removeAllPendingNotificationRequests() {
        scheduledNotifications.removeAll()
    }
    
    func notificationSettings() async -> UNNotificationSettings {
        return MockNotificationSettings(authorizationStatus: authorizationStatus)
    }
}

// UNNotificationSettings cannot be subclassed, so we need to work with actual settings
// For testing, we'll use the requestAuthorization callback to control authorization status
