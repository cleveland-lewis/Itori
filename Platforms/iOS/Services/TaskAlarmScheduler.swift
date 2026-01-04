//
//  TaskAlarmScheduler.swift
//  Itori (iOS)
//
//  Phase 4.2: Task alarm scheduler implementations
//

#if os(iOS)
import Foundation
import UserNotifications
import Combine

#if canImport(AlarmKit)
import AlarmKit

/// AlarmKit-based task alarm scheduler (iOS 26.0+)
@available(iOS 26.0, *)
final class IOSTaskAlarmScheduler: ObservableObject, TaskAlarmScheduling {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "taskAlarms.enabled")
        }
    }
    
    var alarmKitAvailable: Bool {
        true  // This class is only instantiated when AlarmKit is available
    }
    
    var isAuthorized: Bool {
        get async {
            // TODO: Check AlarmKit authorization status
            // For now, assume authorized if AlarmKit is available
            return true
        }
    }
    
    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "taskAlarms.enabled")
    }
    
    func requestAuthorizationIfNeeded() async -> Bool {
        // TODO: Request AlarmKit authorization
        // This will be implemented when AlarmKit API is publicly available
        // For now, return true to allow development
        print("⏰ [TaskAlarmScheduler] AlarmKit authorization requested")
        return true
    }
    
    func scheduleAlarm(for task: AppTask, at date: Date, sound: String?) async throws {
        guard isEnabled else {
            print("⏰ [TaskAlarmScheduler] AlarmKit disabled, skipping schedule")
            return
        }
        
        guard isAuthorized else {
            print("⚠️ [TaskAlarmScheduler] AlarmKit not authorized")
            throw TaskAlarmError.notAuthorized
        }
        
        print("⏰ [TaskAlarmScheduler] Scheduling AlarmKit alarm for task: \(task.title) at \(date)")
        
        // TODO: Implement AlarmKit scheduling when API is available
        // Example (when AlarmKit is released):
        // let alarm = Alarm(
        //     identifier: task.id.uuidString,
        //     trigger: date,
        //     title: task.title,
        //     body: "Task reminder: \(task.title)",
        //     sound: sound
        // )
        // try await AlarmManager.shared.schedule(alarm)
        
        print("✅ [TaskAlarmScheduler] AlarmKit alarm scheduled (placeholder)")
    }
    
    func cancelAlarm(for taskID: UUID) async throws {
        print("⏰ [TaskAlarmScheduler] Cancelling AlarmKit alarm for task: \(taskID)")
        
        // TODO: Implement AlarmKit cancellation when API is available
        // Example:
        // try await AlarmManager.shared.cancel(identifier: taskID.uuidString)
        
        print("✅ [TaskAlarmScheduler] AlarmKit alarm cancelled (placeholder)")
    }
    
    func cancelAllAlarms() async throws {
        print("⏰ [TaskAlarmScheduler] Cancelling all AlarmKit task alarms")
        
        // TODO: Implement bulk cancellation when API is available
        // Example:
        // let identifiers = await AlarmManager.shared.pendingAlarms()
        //     .filter { $0.identifier.starts(with: "task-") }
        //     .map { $0.identifier }
        // try await AlarmManager.shared.cancel(identifiers: identifiers)
        
        print("✅ [TaskAlarmScheduler] All AlarmKit alarms cancelled (placeholder)")
    }
}
#endif

// MARK: - Notification Fallback Scheduler

/// Standard notification-based task alarm scheduler (iOS 17.0+)
final class NotificationTaskAlarmScheduler: ObservableObject, TaskAlarmScheduling {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "taskAlarms.enabled")
        }
    }
    
    var alarmKitAvailable: Bool {
        false
    }
    
    var isAuthorized: Bool {
        get async {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }
    
    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "taskAlarms.enabled")
    }
    
    func requestAuthorizationIfNeeded() async -> Bool {
        let current = UNUserNotificationCenter.current()
        let settings = await current.notificationSettings()
        
        if settings.authorizationStatus == .notDetermined {
            do {
                let granted = try await current.requestAuthorization(options: [.alert, .sound, .badge])
                print("📱 [NotificationTaskScheduler] Authorization \(granted ? "granted" : "denied")")
                return granted
            } catch {
                print("❌ [NotificationTaskScheduler] Authorization error: \(error)")
                return false
            }
        }
        
        return settings.authorizationStatus == .authorized
    }
    
    func scheduleAlarm(for task: AppTask, at date: Date, sound: String?) async throws {
        guard isEnabled else {
            print("📱 [NotificationTaskScheduler] Notifications disabled, skipping schedule")
            return
        }
        
        let authorized = await isAuthorized
        guard authorized else {
            print("⚠️ [NotificationTaskScheduler] Notifications not authorized")
            throw TaskAlarmError.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("task.alarm.title", comment: "Task Reminder")
        content.body = task.title
        content.sound = sound.flatMap { UNNotificationSound(named: UNNotificationSoundName($0)) } ?? .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = [
            "taskID": task.id.uuidString,
            "taskTitle": task.title,
            "type": "taskAlarm"
        ]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
        print("✅ [NotificationTaskScheduler] Notification scheduled for task: \(task.title) at \(date)")
    }
    
    func cancelAlarm(for taskID: UUID) async throws {
        let identifier = "task-\(taskID.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("✅ [NotificationTaskScheduler] Notification cancelled for task: \(taskID)")
    }
    
    func cancelAllAlarms() async throws {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let taskIdentifiers = pending.filter { $0.identifier.starts(with: "task-") }.map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: taskIdentifiers)
        print("✅ [NotificationTaskScheduler] All task notifications cancelled (\(taskIdentifiers.count))")
    }
}

// MARK: - Task Alarm Error

enum TaskAlarmError: Error, LocalizedError {
    case notAuthorized
    case invalidDate
    case schedulingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return NSLocalizedString("task.alarm.error.notAuthorized", comment: "Alarm authorization required")
        case .invalidDate:
            return NSLocalizedString("task.alarm.error.invalidDate", comment: "Invalid alarm date")
        case .schedulingFailed:
            return NSLocalizedString("task.alarm.error.schedulingFailed", comment: "Failed to schedule alarm")
        }
    }
}

#endif
