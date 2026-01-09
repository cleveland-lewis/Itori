import EventKit
import Foundation

/// Manages event deletion with confirmation and recurring event handling
@MainActor
final class EventDeletionService {
    static let shared = EventDeletionService()

    private let deviceCalendar = DeviceCalendarManager.shared
    private let authManager = CalendarAuthorizationManager.shared

    private init() {}

    /// Deletion scope for recurring events
    enum RecurringDeletionScope {
        case thisEvent
        case futureEvents
        case allEvents

        var ekSpan: EKSpan {
            switch self {
            case .thisEvent:
                .thisEvent
            case .futureEvents:
                .futureEvents
            case .allEvents:
                .thisEvent // We handle "all" by removing the entire series
            }
        }

        var localizedTitle: String {
            switch self {
            case .thisEvent:
                NSLocalizedString("event.delete.scope.this_event", comment: "This Event")
            case .futureEvents:
                NSLocalizedString("event.delete.scope.future_events", comment: "Future Events")
            case .allEvents:
                NSLocalizedString("event.delete.scope.all_events", comment: "All Events")
            }
        }
    }

    /// Result of deletion request
    enum DeletionResult {
        case cancelled
        case deleted
        case failed(Error)
    }

    /// Delete an event with proper confirmation and recurring handling
    /// - Parameters:
    ///   - eventId: EventKit identifier
    ///   - isReminder: Whether this is a reminder instead of event
    ///   - presentConfirmation: Closure to present confirmation alert (returns true if confirmed)
    ///   - presentScopeSelection: Closure to present scope selection for recurring events (returns selected scope or
    /// nil if cancelled)
    /// - Returns: DeletionResult indicating success, cancellation, or failure
    func deleteEvent(
        eventId: String,
        isReminder: Bool,
        presentConfirmation: @escaping (String, String) async -> Bool,
        presentScopeSelection: @escaping () async -> RecurringDeletionScope?
    ) async -> DeletionResult {
        guard authManager.isAuthorized else {
            LOG_EVENTKIT(.warn, "DeleteEvent", "Deletion attempted without authorization")
            return .failed(EventDeletionError.notAuthorized)
        }

        // Load the event/reminder
        guard let calendarItem = deviceCalendar.store.calendarItem(withIdentifier: eventId) else {
            LOG_EVENTKIT(.warn, "DeleteEvent", "Event not found: \(eventId)")
            // Object not found - treat as already deleted, clean up cache
            await deviceCalendar.refreshEventsForVisibleRange(reason: "eventNotFound")
            return .failed(EventDeletionError.eventNotFound)
        }

        // Handle reminders separately
        if isReminder {
            guard let reminder = calendarItem as? EKReminder else {
                return .failed(EventDeletionError.typeMismatch)
            }
            return await deleteReminder(reminder, presentConfirmation: presentConfirmation)
        }

        // Handle events
        guard let event = calendarItem as? EKEvent else {
            return .failed(EventDeletionError.typeMismatch)
        }

        return await deleteEventWithConfirmation(
            event,
            presentConfirmation: presentConfirmation,
            presentScopeSelection: presentScopeSelection
        )
    }

    // MARK: - Private Deletion Handlers

    private func deleteReminder(
        _ reminder: EKReminder,
        presentConfirmation: @escaping (String, String) async -> Bool
    ) async -> DeletionResult {
        // Confirmation
        let title = NSLocalizedString("event.delete.confirm_title", comment: "Delete Reminder?")
        let message = NSLocalizedString(
            "event.delete.confirm_message_reminder",
            comment: "Are you sure you want to delete this reminder?"
        )

        let confirmed = await presentConfirmation(title, message)
        guard confirmed else {
            return .cancelled
        }

        // Delete
        do {
            try deviceCalendar.store.remove(reminder, commit: true)
            await deviceCalendar.refreshEventsForVisibleRange(reason: "reminderDeleted")
            LOG_EVENTKIT(.info, "DeleteEvent", "Deleted reminder: \(reminder.title ?? "Untitled")")
            return .deleted
        } catch {
            LOG_EVENTKIT(.error, "DeleteEvent", "Failed to delete reminder: \(error)")
            return .failed(error)
        }
    }

    private func deleteEventWithConfirmation(
        _ event: EKEvent,
        presentConfirmation: @escaping (String, String) async -> Bool,
        presentScopeSelection: @escaping () async -> RecurringDeletionScope?
    ) async -> DeletionResult {
        let isRecurring = event.hasRecurrenceRules

        // Step 1: If recurring, ask for scope FIRST
        let scope: RecurringDeletionScope
        if isRecurring {
            guard let selectedScope = await presentScopeSelection() else {
                return .cancelled
            }
            scope = selectedScope
        } else {
            scope = .thisEvent
        }

        // Step 2: Final confirmation (prevents accidental destructive selection)
        let title = NSLocalizedString("event.delete.confirm_title", comment: "Delete Event?")
        let message: String = if isRecurring {
            switch scope {
            case .thisEvent:
                NSLocalizedString(
                    "event.delete.confirm_message_this",
                    comment: "Delete this occurrence of the recurring event?"
                )
            case .futureEvents:
                NSLocalizedString(
                    "event.delete.confirm_message_future",
                    comment: "Delete this and all future occurrences?"
                )
            case .allEvents:
                NSLocalizedString("event.delete.confirm_message_all", comment: "Delete all occurrences of this event?")
            }
        } else {
            NSLocalizedString(
                "event.delete.confirm_message_single",
                comment: "Are you sure you want to delete this event?"
            )
        }

        let confirmed = await presentConfirmation(title, message)
        guard confirmed else {
            return .cancelled
        }

        // Step 3: Perform deletion
        return await performDeletion(event: event, scope: scope)
    }

    private func performDeletion(event: EKEvent, scope: RecurringDeletionScope) async -> DeletionResult {
        do {
            let span = scope.ekSpan

            if scope == .allEvents && event.hasRecurrenceRules {
                // For "all events", we need to delete the master event
                // EventKit will handle removing all instances
                try deviceCalendar.store.remove(event, span: .futureEvents, commit: true)
            } else {
                try deviceCalendar.store.remove(event, span: span, commit: true)
            }

            // Refresh UI
            await deviceCalendar.refreshEventsForVisibleRange(reason: "eventDeleted")

            LOG_EVENTKIT(.info, "DeleteEvent", "Deleted event: \(event.title ?? "Untitled") (scope: \(scope))")
            return .deleted

        } catch let error as NSError {
            // Handle "object not found" gracefully
            if error.domain == "EKCADErrorDomain" && error.code == 1010 {
                LOG_EVENTKIT(.warn, "DeleteEvent", "Event already deleted externally: \(event.title ?? "Untitled")")
                await deviceCalendar.refreshEventsForVisibleRange(reason: "eventAlreadyDeleted")
                return .deleted // Treat as success - goal achieved
            }

            LOG_EVENTKIT(.error, "DeleteEvent", "Failed to delete event: \(error)")
            return .failed(error)
        }
    }
}

// MARK: - Errors

enum EventDeletionError: LocalizedError {
    case notAuthorized
    case eventNotFound
    case typeMismatch

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            NSLocalizedString(
                "event.delete.error.not_authorized",
                comment: "Calendar access is required to delete events."
            )
        case .eventNotFound:
            NSLocalizedString(
                "event.delete.error.not_found",
                comment: "This event could not be found. It may have been deleted already."
            )
        case .typeMismatch:
            NSLocalizedString("event.delete.error.type_mismatch", comment: "Invalid event type.")
        }
    }
}
