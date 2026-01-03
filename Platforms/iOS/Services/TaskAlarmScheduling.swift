//
//  TaskAlarmScheduling.swift
//  Roots (iOS)
//
//  Phase 4.2: Task alarm scheduling protocol
//

#if os(iOS)
import Foundation

/// Protocol for scheduling task alarm reminders
/// Abstracts AlarmKit vs standard notification implementations
protocol TaskAlarmScheduling {
    /// Whether AlarmKit is available on this device
    var alarmKitAvailable: Bool { get }
    
    /// Whether the user has authorized alarms
    var isAuthorized: Bool { get async }
    
    /// Whether task alarms are enabled in settings
    var isEnabled: Bool { get set }
    
    /// Request authorization if needed
    func requestAuthorizationIfNeeded() async -> Bool
    
    /// Schedule an alarm for a task
    /// - Parameters:
    ///   - task: The task to set the alarm for
    ///   - date: When the alarm should fire
    ///   - sound: Optional custom sound identifier
    func scheduleAlarm(for task: AppTask, at date: Date, sound: String?) async throws
    
    /// Cancel the alarm for a task
    /// - Parameter taskID: The ID of the task whose alarm should be cancelled
    func cancelAlarm(for taskID: UUID) async throws
    
    /// Update an existing alarm (cancel + reschedule)
    /// - Parameters:
    ///   - task: The task with updated alarm settings
    ///   - date: New alarm date
    ///   - sound: Optional custom sound identifier
    func updateAlarm(for task: AppTask, at date: Date, sound: String?) async throws
    
    /// Cancel all task alarms
    func cancelAllAlarms() async throws
}

// MARK: - Default Implementation

extension TaskAlarmScheduling {
    func updateAlarm(for task: AppTask, at date: Date, sound: String?) async throws {
        try await cancelAlarm(for: task.id)
        try await scheduleAlarm(for: task, at: date, sound: sound)
    }
}

#endif
