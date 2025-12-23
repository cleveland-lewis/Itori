import Foundation
import EventKit
import Combine

/// Manages optimistic updates for EventKit events, ensuring immediate UI feedback
/// while EventKit commits happen in the background.
@MainActor
final class OptimisticEventStore: ObservableObject {
    static let shared = OptimisticEventStore()
    
    /// Events with pending optimistic updates (local edits not yet committed to EventKit)
    @Published private(set) var pendingUpdates: [String: OptimisticEvent] = [:]
    
    /// Events with failed updates that need user attention
    @Published private(set) var failedUpdates: [String: EventUpdateError] = [:]
    
    /// Events with detected conflicts (external changes during save)
    @Published private(set) var conflicts: [String: EventConflict] = [:]

    private var retryBlocks: [String: () async throws -> Void] = [:]
    
    private init() {}
    
    /// Applies an optimistic update immediately and queues EventKit save with reconciliation
    func applyOptimisticUpdate(
        eventIdentifier: String,
        updateBlock: @escaping (inout OptimisticEvent) -> Void,
        eventKitCommit: @escaping () async throws -> Void
    ) async {
        // Capture pre-save snapshot for conflict detection
        let preSaveSnapshot = await captureEventSnapshot(identifier: eventIdentifier)
        
        // Create optimistic event if it doesn't exist
        if pendingUpdates[eventIdentifier] == nil {
            pendingUpdates[eventIdentifier] = OptimisticEvent(
                identifier: eventIdentifier,
                pendingSince: Date(),
                preSaveSnapshot: preSaveSnapshot
            )
        }
        
        // Apply the optimistic update
        updateBlock(&pendingUpdates[eventIdentifier]!)
        retryBlocks[eventIdentifier] = eventKitCommit
        
        // Commit to EventKit in background
        do {
            try await eventKitCommit()
            
            // RECONCILIATION PASS: Fetch updated event and check for conflicts
            await reconcileAfterSave(
                eventIdentifier: eventIdentifier,
                preSaveSnapshot: preSaveSnapshot
            )
            
        } catch {
            if isEventDeletedError(error) {
                await MainActor.run {
                    self.conflicts[eventIdentifier] = EventConflict(
                        identifier: eventIdentifier,
                        type: .deletedExternally,
                        detectedAt: Date(),
                        resolution: .acceptEventKitTruth
                    )
                    self.pendingUpdates.removeValue(forKey: eventIdentifier)
                    self.failedUpdates.removeValue(forKey: eventIdentifier)
                    self.retryBlocks.removeValue(forKey: eventIdentifier)
                }
                if let range = refreshRange(preSave: preSaveSnapshot, postSave: nil) {
                    await DeviceCalendarManager.shared.refreshEvents(in: range, reason: "conflictDetected:deleted")
                }
                return
            }

            // Failure: mark as failed and keep optimistic state visible
            await MainActor.run {
                self.failedUpdates[eventIdentifier] = EventUpdateError(
                    identifier: eventIdentifier,
                    error: error,
                    timestamp: Date()
                )
            }

            if let range = refreshRange(preSave: preSaveSnapshot, postSave: nil) {
                await DeviceCalendarManager.shared.refreshEvents(in: range, reason: "optimisticSaveFailed")
            }

            print("📅 [OptimisticEventStore] EventKit commit failed for \(eventIdentifier): \(error)")
        }
    }
    
    /// MARK: - Reconciliation
    
    /// Captures a snapshot of event state before save for conflict detection
    private func captureEventSnapshot(identifier: String) async -> EventSnapshot? {
        guard let event = DeviceCalendarManager.shared.store.event(withIdentifier: identifier) else {
            return nil
        }
        
        return EventSnapshot(
            identifier: identifier,
            title: event.title,
            startDate: event.startDate,
            endDate: event.endDate,
            location: event.location,
            notes: event.notes,
            lastModifiedDate: event.lastModifiedDate,
            capturedAt: Date()
        )
    }
    
    /// Reconciles local state with EventKit after successful save
    private func reconcileAfterSave(
        eventIdentifier: String,
        preSaveSnapshot: EventSnapshot?
    ) async {
        // Fetch current EventKit state
        guard let postSaveEvent = DeviceCalendarManager.shared.store.event(withIdentifier: eventIdentifier) else {
            // Event was deleted externally during save
            await MainActor.run {
                self.conflicts[eventIdentifier] = EventConflict(
                    identifier: eventIdentifier,
                    type: .deletedExternally,
                    detectedAt: Date(),
                    resolution: .acceptEventKitTruth
                )
                self.pendingUpdates.removeValue(forKey: eventIdentifier)
            }
            if let range = refreshRange(preSave: preSaveSnapshot, postSave: nil) {
                await DeviceCalendarManager.shared.refreshEvents(in: range, reason: "conflictDetected:deleted")
            } else {
                await DeviceCalendarManager.shared.refreshEventsForVisibleRange(reason: "conflictDetected:deleted")
            }
            print("⚠️ [OptimisticEventStore] Conflict: Event \(eventIdentifier) was deleted externally")
            return
        }
        
        // Check for external modifications during save
        if let snapshot = preSaveSnapshot,
           let lastMod = postSaveEvent.lastModifiedDate,
           lastMod > snapshot.capturedAt {
            
            // Conflict detected: event was modified externally during our save
            let hasFieldChanges = (
                postSaveEvent.title != snapshot.title ||
                postSaveEvent.startDate != snapshot.startDate ||
                postSaveEvent.endDate != snapshot.endDate ||
                postSaveEvent.location != snapshot.location ||
                postSaveEvent.notes != snapshot.notes
            )
            
            if hasFieldChanges {
                await MainActor.run {
                    self.conflicts[eventIdentifier] = EventConflict(
                        identifier: eventIdentifier,
                        type: .modifiedExternally(
                            preSave: snapshot,
                            postSave: EventSnapshot(from: postSaveEvent)
                        ),
                        detectedAt: Date(),
                        resolution: .acceptEventKitTruth
                    )
                }
                print("⚠️ [OptimisticEventStore] Conflict: Event \(eventIdentifier) was modified externally")
            }
        }
        
        // Success: remove from pending, apply EventKit truth
        await MainActor.run {
            self.pendingUpdates.removeValue(forKey: eventIdentifier)
            self.failedUpdates.removeValue(forKey: eventIdentifier)
            self.retryBlocks.removeValue(forKey: eventIdentifier)
        }
        
        // Trigger refresh to get canonical EventKit state
        if let range = refreshRange(preSave: preSaveSnapshot, postSave: EventSnapshot(from: postSaveEvent)) {
            await DeviceCalendarManager.shared.refreshEvents(in: range, reason: "reconciliationComplete")
        } else {
            await DeviceCalendarManager.shared.refreshEventsForVisibleRange(reason: "reconciliationComplete")
        }
    }
    
    /// Returns the optimistic version of an event if one exists, otherwise nil
    func optimisticEvent(for identifier: String) -> OptimisticEvent? {
        pendingUpdates[identifier]
    }
    
    /// Checks if an event has a pending update
    func hasPendingUpdate(for identifier: String) -> Bool {
        pendingUpdates[identifier] != nil
    }
    
    /// Checks if an event has a failed update
    func hasFailedUpdate(for identifier: String) -> Bool {
        failedUpdates[identifier] != nil
    }
    
    /// Checks if an event has a detected conflict
    func hasConflict(for identifier: String) -> Bool {
        conflicts[identifier] != nil
    }
    
    /// Returns conflict details if one exists
    func conflict(for identifier: String) -> EventConflict? {
        conflicts[identifier]
    }
    
    /// Clears failed update for an event (user acknowledged the error)
    func clearFailedUpdate(for identifier: String) {
        failedUpdates.removeValue(forKey: identifier)
        pendingUpdates.removeValue(forKey: identifier)
        retryBlocks.removeValue(forKey: identifier)
    }
    
    /// Clears conflict for an event (user acknowledged)
    func clearConflict(for identifier: String) {
        conflicts.removeValue(forKey: identifier)
    }
    
    /// Retries a failed update
    func retryFailedUpdate(
        for identifier: String,
        eventKitCommit: @escaping () async throws -> Void
    ) async {
        guard failedUpdates[identifier] != nil else { return }

        let preSaveSnapshot = pendingUpdates[identifier]?.preSaveSnapshot

        // Clear failed state
        failedUpdates.removeValue(forKey: identifier)

        // Retry commit
        do {
            try await eventKitCommit()
            await reconcileAfterSave(
                eventIdentifier: identifier,
                preSaveSnapshot: preSaveSnapshot
            )
        } catch {
            if isEventDeletedError(error) {
                await MainActor.run {
                    self.conflicts[identifier] = EventConflict(
                        identifier: identifier,
                        type: .deletedExternally,
                        detectedAt: Date(),
                        resolution: .acceptEventKitTruth
                    )
                    self.pendingUpdates.removeValue(forKey: identifier)
                    self.failedUpdates.removeValue(forKey: identifier)
                    self.retryBlocks.removeValue(forKey: identifier)
                }
                if let range = refreshRange(preSave: preSaveSnapshot, postSave: nil) {
                    await DeviceCalendarManager.shared.refreshEvents(in: range, reason: "conflictDetected:deleted")
                }
                return
            }

            await MainActor.run {
                self.failedUpdates[identifier] = EventUpdateError(
                    identifier: identifier,
                    error: error,
                    timestamp: Date()
                )
            }

            if let range = refreshRange(preSave: preSaveSnapshot, postSave: nil) {
                await DeviceCalendarManager.shared.refreshEvents(in: range, reason: "optimisticRetryFailed")
            }
        }
    }
    
    /// Clears all pending and failed updates (e.g., on app background/foreground)
    func clearAll() {
        pendingUpdates.removeAll()
        failedUpdates.removeAll()
        retryBlocks.removeAll()
    }

    func retryFailedUpdate(for identifier: String) async {
        guard let commit = retryBlocks[identifier] else { return }
        await retryFailedUpdate(for: identifier, eventKitCommit: commit)
    }

    private func refreshRange(preSave: EventSnapshot?, postSave: EventSnapshot?) -> DateInterval? {
        let startCandidates = [preSave?.startDate, postSave?.startDate].compactMap { $0 }
        let endCandidates = [preSave?.endDate, postSave?.endDate].compactMap { $0 }
        guard let start = startCandidates.min(), let end = endCandidates.max() else { return nil }
        return DateInterval(start: start.addingTimeInterval(-3600), end: end.addingTimeInterval(3600))
    }

    private func isEventDeletedError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == EKErrorDomain, nsError.code == EKError.eventNotFound.rawValue {
            return true
        }
        if nsError.domain == "EKCADErrorDomain", nsError.code == 1010 {
            return true
        }
        return false
    }
}

/// Represents an optimistically updated event
struct OptimisticEvent {
    let identifier: String
    let pendingSince: Date
    let preSaveSnapshot: EventSnapshot?
    
    var title: String?
    var startDate: Date?
    var endDate: Date?
    var isAllDay: Bool?
    var location: String?
    var notes: String?
    var url: String?
    var category: EventCategory?
}

/// Snapshot of event state for conflict detection
struct EventSnapshot {
    let identifier: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let notes: String?
    let lastModifiedDate: Date?
    let capturedAt: Date
    
    init(identifier: String, title: String, startDate: Date, endDate: Date, location: String?, notes: String?, lastModifiedDate: Date?, capturedAt: Date) {
        self.identifier = identifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.lastModifiedDate = lastModifiedDate
        self.capturedAt = capturedAt
    }
    
    init(from event: EKEvent) {
        self.identifier = event.eventIdentifier
        self.title = event.title
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.location = event.location
        self.notes = event.notes
        self.lastModifiedDate = event.lastModifiedDate
        self.capturedAt = Date()
    }
}

/// Represents a failed event update
struct EventUpdateError: Identifiable {
    let id = UUID()
    let identifier: String
    let error: Error
    let timestamp: Date
    
    var localizedDescription: String {
        error.localizedDescription
    }
}

/// Represents a detected conflict between local changes and external modifications
struct EventConflict: Identifiable {
    let id = UUID()
    let identifier: String
    let type: ConflictType
    let detectedAt: Date
    let resolution: ConflictResolution
    
    enum ConflictType {
        case modifiedExternally(preSave: EventSnapshot, postSave: EventSnapshot)
        case deletedExternally
    }
    
    enum ConflictResolution {
        case acceptEventKitTruth  // Default policy: EventKit is source of truth
        case retryLocalChanges    // Retry local changes (not yet implemented)
        case userChoice           // Defer to user (future enhancement)
    }
    
    var userFacingMessage: String {
        switch type {
        case .modifiedExternally:
            return "This event was modified by another app or device during your edit."
        case .deletedExternally:
            return "This event was deleted by another app or device."
        }
    }
}
