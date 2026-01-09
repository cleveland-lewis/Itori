import Combine
import EventKit
import Foundation

/// Manages bidirectional sync between app assignments and system calendar
@MainActor
final class AssignmentCalendarSyncManager: ObservableObject {
    static let shared = AssignmentCalendarSyncManager()

    private let deviceCalendar = DeviceCalendarManager.shared
    private let authManager = CalendarAuthorizationManager.shared
    private var cancellables = Set<AnyCancellable>()

    @Published var isSyncEnabled: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncErrors: [SyncError] = []

    struct SyncError: Identifiable {
        let id = UUID()
        let message: String
        let date: Date
        let assignment: AppTask?
    }

    private init() {
        loadSyncPreferences()
    }

    // MARK: - Preferences

    private func loadSyncPreferences() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: "assignmentCalendarSyncEnabled")
    }

    func setSyncEnabled(_ enabled: Bool) {
        isSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "assignmentCalendarSyncEnabled")

        if enabled {
            // Trigger initial sync
            Task {
                await performFullSync()
            }
        }
    }

    // MARK: - Permission Handling

    func requestPermissionsIfNeeded() async -> Bool {
        guard !authManager.isAuthorized else { return true }
        return await DeviceCalendarManager.shared.requestFullAccessIfNeeded()
    }

    // MARK: - Sync Operations

    /// Perform full bidirectional sync
    func performFullSync() async {
        guard isSyncEnabled, authManager.isAuthorized else { return }

        LOG_SYNC(.info, "AssignmentSync", "Starting full sync")

        // Get assignments and events
        let assignments = AssignmentsStore.shared.tasks
        let calendar = getTargetCalendar()

        guard let calendar else {
            addError("No writable calendar available for sync")
            return
        }

        // Sync assignments to calendar
        for assignment in assignments {
            await syncAssignmentToCalendar(assignment, calendar: calendar)
        }

        lastSyncDate = Date()
        LOG_SYNC(.info, "AssignmentSync", "Full sync completed")
    }

    /// Sync a single assignment to calendar
    /// Returns the calendar event identifier if successful
    @discardableResult
    func syncAssignmentToCalendar(_ assignment: AppTask, calendar: EKCalendar? = nil) async -> String? {
        guard isSyncEnabled, authManager.isAuthorized else { return nil }

        let targetCalendar = calendar ?? getTargetCalendar()
        guard let targetCalendar else {
            addError("No calendar available", assignment: assignment)
            return nil
        }

        do {
            let eventId: String?
            // Check if event already exists
            if let existingEventId = assignment.calendarEventIdentifier,
               let existingEvent = deviceCalendar.store.event(withIdentifier: existingEventId)
            {
                // Update existing event
                try updateEvent(existingEvent, with: assignment)
                LOG_SYNC(.info, "AssignmentSync", "Updated assignment: \(assignment.title)")
                eventId = existingEventId
            } else {
                // Create new event
                let event = try createEvent(for: assignment, in: targetCalendar)
                LOG_SYNC(.info, "AssignmentSync", "Created event for assignment: \(assignment.title)")
                eventId = event.eventIdentifier
            }

            // Save event ID back to assignment if it's new
            if eventId != assignment.calendarEventIdentifier, let eventId {
                var updatedAssignment = assignment
                updatedAssignment.calendarEventIdentifier = eventId
                AssignmentsStore.shared.updateTask(updatedAssignment)
            }

            return eventId
        } catch {
            addError("Failed to sync assignment: \(error.localizedDescription)", assignment: assignment)
            return nil
        }
    }

    /// Delete assignment's calendar event
    func deleteCalendarEvent(for assignment: AppTask) async {
        guard isSyncEnabled, authManager.isAuthorized else { return }
        guard let eventId = assignment.calendarEventIdentifier else { return }

        do {
            if let event = deviceCalendar.store.event(withIdentifier: eventId) {
                try deviceCalendar.store.remove(event, span: .thisEvent)
                LOG_SYNC(.info, "AssignmentSync", "Deleted calendar event for: \(assignment.title)")
            }
        } catch {
            addError("Failed to delete event: \(error.localizedDescription)", assignment: assignment)
        }
    }

    // MARK: - Event Creation/Update

    private func createEvent(for assignment: AppTask, in calendar: EKCalendar) throws -> EKEvent {
        let event = EKEvent(eventStore: deviceCalendar.store)
        event.calendar = calendar
        event.title = assignment.title

        // Set dates
        if let dueDate = assignment.due {
            if assignment.hasExplicitDueTime {
                // Assignment has specific time
                event.startDate = dueDate.addingTimeInterval(-Double(assignment.estimatedMinutes) * 60)
                event.endDate = dueDate
            } else {
                // All-day event
                event.isAllDay = true
                event.startDate = Calendar.current.startOfDay(for: dueDate)
                event.endDate = Calendar.current.startOfDay(for: dueDate)
            }
        } else {
            // No due date - skip
            throw SyncErrorType.noDueDate
        }

        // Add notes with course info
        var notes = ""
        if let courseId = assignment.courseId,
           let coursesStore = CoursesStore.shared,
           let course = coursesStore.courses.first(where: { $0.id == courseId })
        {
            notes += "Course: \(course.code) - \(course.title)\n"
        }
        notes += "Type: \(assignment.category.rawValue)\n"
        notes += "Estimated time: \(assignment.estimatedMinutes) minutes"
        event.notes = notes

        try deviceCalendar.store.save(event, span: .thisEvent)
        return event
    }

    private func updateEvent(_ event: EKEvent, with assignment: AppTask) throws {
        event.title = assignment.title

        // Update dates
        if let dueDate = assignment.due {
            if assignment.hasExplicitDueTime {
                event.isAllDay = false
                event.startDate = dueDate.addingTimeInterval(-Double(assignment.estimatedMinutes) * 60)
                event.endDate = dueDate
            } else {
                event.isAllDay = true
                event.startDate = Calendar.current.startOfDay(for: dueDate)
                event.endDate = Calendar.current.startOfDay(for: dueDate)
            }
        }

        // Update notes
        var notes = ""
        if let courseId = assignment.courseId,
           let coursesStore = CoursesStore.shared,
           let course = coursesStore.courses.first(where: { $0.id == courseId })
        {
            notes += "Course: \(course.code) - \(course.title)\n"
        }
        notes += "Type: \(assignment.category.rawValue)\n"
        notes += "Estimated time: \(assignment.estimatedMinutes) minutes"
        event.notes = notes

        try deviceCalendar.store.save(event, span: .thisEvent)
    }

    // MARK: - Helpers

    private func getTargetCalendar() -> EKCalendar? {
        let calendars = deviceCalendar.store.calendars(for: .event).filter(\.allowsContentModifications)

        // Try to use default calendar
        if let defaultCal = deviceCalendar.store.defaultCalendarForNewEvents,
           defaultCal.allowsContentModifications
        {
            return defaultCal
        }

        // Return first writable calendar
        return calendars.first
    }

    private func addError(_ message: String, assignment: AppTask? = nil) {
        let error = SyncError(message: message, date: Date(), assignment: assignment)
        syncErrors.append(error)
        LOG_SYNC(.error, "AssignmentSync", message)
    }

    private enum SyncErrorType: Error {
        case noDueDate
    }
}
