import Foundation
import UserNotifications
@testable import Roots

class MockNotificationCenter: NotificationSchedulable {
    var isAuthorized = true
    var shouldFailAuthorization = false
    var shouldFailScheduling = false
    var scheduledNotifications: [UNNotificationRequest] = []
    var authorizationStatus: UNAuthorizationStatus = .authorized
    
    func requestAuthorization() async throws -> Bool {
        if shouldFailAuthorization {
            throw NSError(domain: "UNErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "User denied authorization"])
        }
        return isAuthorized
    }
    
    func schedule(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger?) async throws {
        if shouldFailScheduling {
            throw NSError(domain: "UNErrorDomain", code: 1407, userInfo: [NSLocalizedDescriptionKey: "Notifications not authorized"])
        }
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        scheduledNotifications.append(request)
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return scheduledNotifications
    }
    
    func removePendingNotifications(withIdentifiers identifiers: [String]) {
        scheduledNotifications.removeAll { identifiers.contains($0.identifier) }
    }
    
    func removeAllPendingNotifications() {
        scheduledNotifications.removeAll()
    }
    
    func getNotificationSettings() async -> UNNotificationSettings {
        return MockNotificationSettings(authorizationStatus: authorizationStatus)
    }
}

class MockNotificationSettings: UNNotificationSettings {
    private let _authorizationStatus: UNAuthorizationStatus
    
    init(authorizationStatus: UNAuthorizationStatus) {
        self._authorizationStatus = authorizationStatus
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override var authorizationStatus: UNAuthorizationStatus {
        return _authorizationStatus
    }
}
