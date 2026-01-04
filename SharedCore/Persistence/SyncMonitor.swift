//
//  SyncMonitor.swift
//  Itori
//
//  Core Data + CloudKit sync monitoring for debugging
//

import Foundation
import CoreData
import Combine

#if DEBUG
/// Debug-only monitoring of Core Data + CloudKit sync status
/// Use this to diagnose sync issues during development
@MainActor
final class SyncMonitor: ObservableObject {
    static let shared = SyncMonitor()
    
    @Published private(set) var lastRemoteChange: Date?
    @Published private(set) var isCloudKitActive: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var syncEvents: [SyncEvent] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let maxEvents = 100
    
    struct SyncEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let type: EventType
        let details: String
        
        enum EventType {
            case importStarted
            case importFinished
            case exportStarted
            case exportFinished
            case conflict
            case error
            case statusChange
        }
        
        var icon: String {
            switch type {
            case .importStarted, .importFinished: return "arrow.down.circle"
            case .exportStarted, .exportFinished: return "arrow.up.circle"
            case .conflict: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .statusChange: return "info.circle"
            }
        }
        
        var color: String {
            switch type {
            case .importStarted, .exportStarted: return "blue"
            case .importFinished, .exportFinished: return "green"
            case .conflict: return "orange"
            case .error: return "red"
            case .statusChange: return "gray"
            }
        }
    }
    
    private init() {
        setupObservers()
        checkCloudKitStatus()
    }
    
    private func setupObservers() {
        // Observe remote change notifications
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] notification in
                self?.handleRemoteChange(notification)
            }
            .store(in: &cancellables)
        
        // Observe iCloud sync status changes
        NotificationCenter.default.publisher(for: .iCloudSyncStatusChanged)
            .sink { [weak self] notification in
                self?.handleSyncStatusChange(notification)
            }
            .store(in: &cancellables)
        
        // Observe CloudKit import events
        NotificationCenter.default.publisher(for: NSNotification.Name(rawValue: "NSPersistentCloudKitContainerEventChangedNotification"))
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleRemoteChange(_ notification: Notification) {
        Task { @MainActor in
            lastRemoteChange = Date()
            addEvent(type: .importFinished, details: "Remote changes detected")
            LOG_DATA(.info, "SyncMonitor", "Remote change notification received")
        }
    }
    
    private func handleSyncStatusChange(_ notification: Notification) {
        Task { @MainActor in
            if let enabled = notification.object as? Bool {
                isCloudKitActive = enabled
                let reason = notification.userInfo?["reason"] as? String ?? "Unknown"
                addEvent(type: .statusChange, details: "CloudKit sync \(enabled ? "enabled" : "disabled"): \(reason)")
            }
        }
    }
    
    private func handleCloudKitEvent(_ notification: Notification) {
        Task { @MainActor in
            // Parse CloudKit container event if available
            if let userInfo = notification.userInfo {
                let eventType = userInfo["eventType"] as? String ?? "unknown"
                addEvent(type: .statusChange, details: "CloudKit event: \(eventType)")
            }
        }
    }
    
    private func checkCloudKitStatus() {
        Task { @MainActor in
            let settings = AppSettingsModel.shared
            isCloudKitActive = settings.enableICloudSync
            addEvent(type: .statusChange, details: "Initial status: CloudKit \(isCloudKitActive ? "active" : "inactive")")
        }
    }
    
    private func addEvent(type: SyncEvent.EventType, details: String) {
        let event = SyncEvent(timestamp: Date(), type: type, details: details)
        syncEvents.insert(event, at: 0)
        
        // Keep only recent events
        if syncEvents.count > maxEvents {
            syncEvents = Array(syncEvents.prefix(maxEvents))
        }
        
        // Track errors
        if case .error = type {
            lastError = details
        }
    }
    
    /// Manually log a sync event (useful for debugging)
    func logEvent(type: SyncEvent.EventType, details: String) {
        addEvent(type: type, details: details)
    }
    
    /// Clear all events
    func clearEvents() {
        syncEvents.removeAll()
        lastError = nil
    }
    
    /// Get summary statistics
    var statistics: SyncStatistics {
        let imports = syncEvents.filter { $0.type == .importFinished }.count
        let exports = syncEvents.filter { $0.type == .exportFinished }.count
        let conflicts = syncEvents.filter { $0.type == .conflict }.count
        let errors = syncEvents.filter { $0.type == .error }.count
        
        return SyncStatistics(
            totalEvents: syncEvents.count,
            imports: imports,
            exports: exports,
            conflicts: conflicts,
            errors: errors,
            lastSync: lastRemoteChange
        )
    }
    
    struct SyncStatistics {
        let totalEvents: Int
        let imports: Int
        let exports: Int
        let conflicts: Int
        let errors: Int
        let lastSync: Date?
    }
}
#endif
