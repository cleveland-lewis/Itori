//
//  TimerAlarmScheduler.swift
//  Roots (iOS)
//
//  Phase 2.1: AlarmKit Integration
//  Note: AlarmKit requires iOS 26.0+. Falls back to notifications on older iOS.

#if os(iOS)
import Foundation
import SwiftUI
import UserNotifications

@available(iOS 17.0, *)
final class IOSTimerAlarmScheduler: TimerAlarmScheduling {
    private let settings = AppSettingsModel.shared
    private var scheduledAlarmIDs: [String: UUID] = [:]
    private var authorizationStatus: AuthorizationStatus = .notDetermined
    
    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
    }
    
    var isEnabled: Bool {
        guard settings.alarmKitTimersEnabled else { return false }
        return alarmKitAvailable && isAuthorized
    }
    
    var alarmKitAvailable: Bool {
        // Check if AlarmKit can be imported and iOS version is sufficient
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            return true
        }
        #endif
        return false
    }
    
    var isAuthorized: Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            // Will implement when AlarmKit is available
            return authorizationStatus == .authorized
        }
        #endif
        return false
    }
    
    init() {
        // Check initial authorization status if AlarmKit is available
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            Task {
                await checkAuthorizationStatus()
            }
        }
        #endif
    }
    
    // MARK: - Authorization
    
    func requestAuthorizationIfNeeded() async -> Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            // TODO: Implement when AlarmKit API is available
            // Example implementation:
            /*
            do {
                let status = try await AlarmManager.shared.requestAuthorization()
                authorizationStatus = status == .authorized ? .authorized : .denied
                return authorizationStatus == .authorized
            } catch {
                LOG_UI(.error, "AlarmKit", "Authorization request failed: \(error.localizedDescription)")
                authorizationStatus = .denied
                return false
            }
            */
            
            // Placeholder: Assume authorized for development
            authorizationStatus = .authorized
            return true
        }
        #endif
        return false
    }
    
    private func checkAuthorizationStatus() async {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            // TODO: Check actual status when AlarmKit is available
            // authorizationStatus = AlarmManager.shared.authorizationStatus == .authorized ? .authorized : .denied
            authorizationStatus = .notDetermined
        }
        #endif
    }
    
    // MARK: - Scheduling
    
    func scheduleTimerEnd(id: String, fireIn seconds: TimeInterval, title: String, body: String) {
        guard isEnabled else {
            LOG_UI(.debug, "AlarmKit", "AlarmKit not enabled or available, skipping alarm schedule")
            return
        }
        
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            scheduleAlarmKitTimer(id: id, fireIn: seconds, title: title, body: body)
        } else {
            LOG_UI(.info, "AlarmKit", "iOS < 26.0, AlarmKit not available")
        }
        #else
        LOG_UI(.info, "AlarmKit", "AlarmKit framework not available")
        #endif
    }
    
    #if canImport(AlarmKit)
    @available(iOS 26.0, *)
    private func scheduleAlarmKitTimer(id: String, fireIn seconds: TimeInterval, title: String, body: String) {
        let alarmID = UUID()
        scheduledAlarmIDs[id] = alarmID
        
        Task {
            do {
                // TODO: Implement actual AlarmKit scheduling when API is available
                /*
                let attributes = AlarmAttributes(
                    presentation: alarmPresentation(title: title, body: body),
                    metadata: TimerAlarmMetadata(sessionID: id, mode: body),
                    tintColor: Color.accentColor
                )
                
                let config = AlarmManager.AlarmConfiguration.timer(
                    duration: seconds,
                    attributes: attributes,
                    stopIntent: nil,
                    secondaryIntent: nil,
                    sound: .default
                )
                
                try await AlarmManager.shared.schedule(id: alarmID, configuration: config)
                */
                
                LOG_UI(.info, "AlarmKit", "Alarm scheduled: \(id) for \(seconds)s - \(title)")
            } catch {
                LOG_UI(.error, "AlarmKit", "Failed to schedule alarm: \(error.localizedDescription)")
                scheduledAlarmIDs.removeValue(forKey: id)
            }
        }
    }
    
    @available(iOS 26.0, *)
    private func alarmPresentation(title: String, body: String) -> AlarmPresentation {
        // TODO: Implement when AlarmKit API is available
        /*
        return AlarmPresentation(
            title: title,
            body: body,
            sound: .default,
            interruptionLevel: .timeSensitive
        )
        */
        fatalError("AlarmKit API not yet available")
    }
    #endif
    
    // MARK: - Cancellation
    
    func cancelTimer(id: String) {
        guard let alarmID = scheduledAlarmIDs[id] else {
            LOG_UI(.debug, "AlarmKit", "No alarm to cancel for id: \(id)")
            return
        }
        
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            cancelAlarmKitTimer(alarmID: alarmID, sessionID: id)
        }
        #endif
        
        scheduledAlarmIDs.removeValue(forKey: id)
    }
    
    #if canImport(AlarmKit)
    @available(iOS 26.0, *)
    private func cancelAlarmKitTimer(alarmID: UUID, sessionID: String) {
        Task {
            do {
                // TODO: Implement when AlarmKit API is available
                // try await AlarmManager.shared.cancel(id: alarmID)
                LOG_UI(.info, "AlarmKit", "Alarm cancelled: \(sessionID)")
            } catch {
                LOG_UI(.error, "AlarmKit", "Failed to cancel alarm: \(error.localizedDescription)")
            }
        }
    }
    #endif
}

// MARK: - Notification Fallback Scheduler

@available(iOS 17.0, *)
final class NotificationFallbackScheduler: TimerAlarmScheduling {
    private var scheduledNotifications: [String: String] = [:] // sessionID -> notificationID
    
    var isEnabled: Bool { true }
    var isAuthorized: Bool {
        // Check notification authorization
        var authorized = false
        let semaphore = DispatchSemaphore(value: 0)
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            authorized = settings.authorizationStatus == .authorized
            semaphore.signal()
        }
        
        semaphore.wait()
        return authorized
    }
    var alarmKitAvailable: Bool { false }
    
    func requestAuthorizationIfNeeded() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            LOG_UI(.error, "Notifications", "Authorization failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func scheduleTimerEnd(id: String, fireIn seconds: TimeInterval, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "TIMER_COMPLETE"
        content.userInfo = ["sessionID": id]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, seconds), // Minimum 1 second
            repeats: false
        )
        
        let notificationID = "timer-\(id)"
        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                LOG_UI(.error, "Notifications", "Failed to schedule: \(error.localizedDescription)")
            } else {
                self.scheduledNotifications[id] = notificationID
                LOG_UI(.info, "Notifications", "Notification scheduled: \(id) for \(seconds)s")
            }
        }
    }
    
    func cancelTimer(id: String) {
        guard let notificationID = scheduledNotifications[id] else {
            return
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationID]
        )
        scheduledNotifications.removeValue(forKey: id)
        LOG_UI(.info, "Notifications", "Notification cancelled: \(id)")
    }
}

// TODO: Restore AlarmKit integration
// #if canImport(AlarmKit)
//     private func alarmID(for id: String) -> UUID {
//         if let existing = scheduledIDs[id] { return existing }
//         let newID = UUID()
//         scheduledIDs[id] = newID
//         return newID
//     }
// 
//     private func alarmPresentation(title: String) -> AlarmPresentation {
//         let stop = AlarmButton(text: LocalizedStringResource(stringLiteral: NSLocalizedString("alarm.stop", comment: "Stop")), textColor: .white, systemImageName: "stop.fill")
//         let pause = AlarmButton(text: LocalizedStringResource(stringLiteral: NSLocalizedString("alarm.pause", comment: "Pause")), textColor: .white, systemImageName: "pause.fill")
//         let resume = AlarmButton(text: LocalizedStringResource(stringLiteral: NSLocalizedString("alarm.resume", comment: "Resume")), textColor: .white, systemImageName: "play.fill")
// 
//         let alert = AlarmPresentation.Alert(
//             title: LocalizedStringResource(stringLiteral: title),
//             stopButton: stop,
//             secondaryButton: nil,
//             secondaryButtonBehavior: nil
//         )
//         let countdown = AlarmPresentation.Countdown(
//             title: LocalizedStringResource(stringLiteral: title),
//             pauseButton: pause
//         )
//         let paused = AlarmPresentation.Paused(
//             title: LocalizedStringResource(stringLiteral: NSLocalizedString("alarm.paused", comment: "Paused")),
//             resumeButton: resume
//         )
//         return AlarmPresentation(alert: alert, countdown: countdown, paused: paused)
//     }
// #endif
// }
// 
// TODO: Restore AlarmKit metadata
// #if canImport(AlarmKit)
// private struct TimerAlarmMetadata: AlarmMetadata, Codable, Hashable, Sendable {
//     var mode: String
// }
// #endif

#endif // os(iOS)