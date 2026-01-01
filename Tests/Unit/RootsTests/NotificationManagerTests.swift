import XCTest
import UserNotifications
@testable import Roots

final class NotificationManagerTests: XCTestCase {
    var mockCenter: MockNotificationCenter!
    
    override func setUp() {
        super.setUp()
        mockCenter = MockNotificationCenter()
    }
    
    override func tearDown() {
        mockCenter = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorizationSuccess() async throws {
        mockCenter.isAuthorized = true
        mockCenter.shouldFailAuthorization = false
        
        let granted = try await mockCenter.requestAuthorization()
        
        XCTAssertTrue(granted)
    }
    
    func testRequestAuthorizationDenied() async throws {
        mockCenter.isAuthorized = false
        mockCenter.shouldFailAuthorization = false
        
        let granted = try await mockCenter.requestAuthorization()
        
        XCTAssertFalse(granted)
    }
    
    func testRequestAuthorizationFailure() async {
        mockCenter.shouldFailAuthorization = true
        
        do {
            _ = try await mockCenter.requestAuthorization()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "UNErrorDomain")
        }
    }
    
    // MARK: - Scheduling Tests
    
    func testScheduleNotificationSuccess() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Test Body"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        
        try await mockCenter.schedule(identifier: "test-1", content: content, trigger: trigger)
        
        let pending = await mockCenter.getPendingNotifications()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.identifier, "test-1")
        XCTAssertEqual(pending.first?.content.title, "Test Notification")
    }
    
    func testScheduleMultipleNotifications() async throws {
        for i in 1...3 {
            let content = UNMutableNotificationContent()
            content.title = "Notification \(i)"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(i * 60), repeats: false)
            try await mockCenter.schedule(identifier: "test-\(i)", content: content, trigger: trigger)
        }
        
        let pending = await mockCenter.getPendingNotifications()
        XCTAssertEqual(pending.count, 3)
    }
    
    func testScheduleNotificationWithoutAuthorization() async {
        mockCenter.shouldFailScheduling = true
        
        let content = UNMutableNotificationContent()
        content.title = "Test"
        
        do {
            try await mockCenter.schedule(identifier: "test", content: content, trigger: nil)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual((error as NSError).code, 1407)
        }
    }
    
    // MARK: - Removal Tests
    
    func testRemoveSpecificNotifications() async throws {
        // Schedule 3 notifications
        for i in 1...3 {
            let content = UNMutableNotificationContent()
            content.title = "Test \(i)"
            try await mockCenter.schedule(identifier: "test-\(i)", content: content, trigger: nil)
        }
        
        // Remove one
        mockCenter.removePendingNotifications(withIdentifiers: ["test-2"])
        
        let pending = await mockCenter.getPendingNotifications()
        XCTAssertEqual(pending.count, 2)
        XCTAssertFalse(pending.contains { $0.identifier == "test-2" })
    }
    
    func testRemoveAllNotifications() async throws {
        for i in 1...3 {
            let content = UNMutableNotificationContent()
            content.title = "Test \(i)"
            try await mockCenter.schedule(identifier: "test-\(i)", content: content, trigger: nil)
        }
        
        mockCenter.removeAllPendingNotifications()
        
        let pending = await mockCenter.getPendingNotifications()
        XCTAssertEqual(pending.count, 0)
    }
    
    // MARK: - Settings Tests
    
    func testGetNotificationSettingsAuthorized() async {
        mockCenter.authorizationStatus = .authorized
        
        let settings = await mockCenter.getNotificationSettings()
        
        XCTAssertEqual(settings.authorizationStatus, .authorized)
    }
    
    func testGetNotificationSettingsDenied() async {
        mockCenter.authorizationStatus = .denied
        
        let settings = await mockCenter.getNotificationSettings()
        
        XCTAssertEqual(settings.authorizationStatus, .denied)
    }
    
    func testGetNotificationSettingsNotDetermined() async {
        mockCenter.authorizationStatus = .notDetermined
        
        let settings = await mockCenter.getNotificationSettings()
        
        XCTAssertEqual(settings.authorizationStatus, .notDetermined)
    }
    
    // MARK: - Edge Cases
    
    func testScheduleNotificationWithCustomSound() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Test"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("custom.wav"))
        
        try await mockCenter.schedule(identifier: "test", content: content, trigger: nil)
        
        let pending = await mockCenter.getPendingNotifications()
        XCTAssertNotNil(pending.first?.content.sound)
    }
    
    func testScheduleNotificationWithBadge() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Test"
        content.badge = 5
        
        try await mockCenter.schedule(identifier: "test", content: content, trigger: nil)
        
        let pending = await mockCenter.getPendingNotifications()
        XCTAssertEqual(pending.first?.content.badge, 5)
    }
    
    func testScheduleNotificationWithUserInfo() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Test"
        content.userInfo = ["key": "value", "id": 123]
        
        try await mockCenter.schedule(identifier: "test", content: content, trigger: nil)
        
        let pending = await mockCenter.getPendingNotifications()
        let userInfo = pending.first?.content.userInfo
        XCTAssertEqual(userInfo?["key"] as? String, "value")
        XCTAssertEqual(userInfo?["id"] as? Int, 123)
    }
}
