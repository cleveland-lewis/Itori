import Foundation
import EventKit
import Combine

@MainActor
final class CalendarRefreshCoordinator: ObservableObject {
    static let shared = CalendarRefreshCoordinator()

    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var lastRefreshedAt: Date? = nil
    @Published var error: CalendarRefreshError? = nil

    private let calendarManager = CalendarManager.shared
    private let deviceCalendar = DeviceCalendarManager.shared
    private let settings = AppSettingsModel.shared
    private let assignmentsStore = AssignmentsStore.shared

    private let autoScheduleTagPrefix = "[RootsAutoSchedule:"

    func refresh() {
        Task { await runRefresh() }
    }

    func runRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        error = nil

        let granted = await deviceCalendar.requestFullAccessIfNeeded()
        guard granted else {
            error = .permissionDenied
            isRefreshing = false
            return
        }

        await calendarManager.refreshAuthStatus()

        let now = Date()
        let horizonDays = lookaheadDays(from: settings.plannerHorizon)
        let endDate = Calendar.current.date(byAdding: .day, value: horizonDays, to: now) ?? now

        await deviceCalendar.refreshEvents(from: now, to: endDate, reason: "manualRefresh")
        lastRefreshedAt = Date()

        do {
            try await scheduleAssignments(from: now, to: endDate)
        } catch {
            self.error = .schedulingFailed
        }

        isRefreshing = false
    }

    private func scheduleAssignments(from startDate: Date, to endDate: Date) async throws {
        let tasks = assignmentsStore.tasks.filter { task in
            guard !task.isCompleted, let due = task.due else { return false }
            return due >= startDate && due <= endDate
        }

        guard !tasks.isEmpty else { return }

        let autoTasks = tasks.map { task in
            AutoScheduleTask(
                id: task.id,
                title: task.title,
                estimatedDurationMinutes: max(30, task.estimatedMinutes),
                dueDate: task.due ?? endDate,
                priority: Int(task.importance * 10)
            )
        }

        let workStartHour = settings.workdayStartHourStorage
        let workEndHour = settings.workdayEndHourStorage
        let daysToPlan = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)

        let existingEvents = deviceCalendar.events.filter { event in
            event.endDate > startDate && event.startDate < endDate
        }

        let result = AutoScheduler.generateSchedule(
            tasks: autoTasks,
            existingEvents: existingEvents,
            startDate: startDate,
            daysToPlan: daysToPlan,
            workDayStart: workStartHour,
            workDayEnd: workEndHour
        )

        guard let targetCalendar = targetCalendar() else { return }
        try applySchedule(result.proposedEvents, targetCalendar: targetCalendar, within: startDate...endDate)
        await deviceCalendar.refreshEvents(from: startDate, to: endDate, reason: "autoScheduleUpdate")
    }

    private func targetCalendar() -> EKCalendar? {
        if !calendarManager.selectedCalendarID.isEmpty,
           let selected = deviceCalendar.store.calendars(for: .event).first(where: { $0.calendarIdentifier == calendarManager.selectedCalendarID }) {
            return selected
        }
        return deviceCalendar.store.defaultCalendarForNewEvents
    }

    private func applySchedule(_ proposed: [EKEvent], targetCalendar: EKCalendar, within range: ClosedRange<Date>) throws {
        let store = deviceCalendar.store
        let existing = deviceCalendar.events.filter { event in
            event.calendar.calendarIdentifier == targetCalendar.calendarIdentifier &&
            event.endDate > range.lowerBound && event.startDate < range.upperBound &&
            extractTag(from: event.notes) != nil
        }

        var existingByTag: [String: EKEvent] = [:]
        for event in existing {
            if let tag = extractTag(from: event.notes) {
                existingByTag[tag] = event
            }
        }

        var scheduledTags: Set<String> = []

        for proposedEvent in proposed {
            proposedEvent.calendar = targetCalendar
            guard let tag = extractTag(from: proposedEvent.notes) else { continue }
            scheduledTags.insert(tag)

            if let existingEvent = existingByTag[tag], existingEvent.calendar.allowsContentModifications {
                existingEvent.title = proposedEvent.title
                existingEvent.startDate = proposedEvent.startDate
                existingEvent.endDate = proposedEvent.endDate
                existingEvent.notes = mergeNotes(existingEvent.notes, tag: tag)
                try store.save(existingEvent, span: .thisEvent, commit: true)
            } else if targetCalendar.allowsContentModifications {
                proposedEvent.notes = mergeNotes(proposedEvent.notes, tag: tag)
                try store.save(proposedEvent, span: .thisEvent, commit: true)
            }
        }

        for (tag, event) in existingByTag where !scheduledTags.contains(tag) && event.calendar.allowsContentModifications {
            try store.remove(event, span: .thisEvent, commit: true)
        }
    }

    private func extractTag(from notes: String?) -> String? {
        guard let notes, let start = notes.range(of: autoScheduleTagPrefix) else { return nil }
        guard let end = notes[start.upperBound...].firstIndex(of: "]") else { return nil }
        return String(notes[start.lowerBound...end])
    }

    private func mergeNotes(_ notes: String?, tag: String) -> String {
        let current = notes ?? ""
        if current.contains(tag) {
            return current
        }
        if current.isEmpty {
            return tag
        }
        return "\(current)\n\(tag)"
    }

    private func lookaheadDays(from horizon: String) -> Int {
        switch horizon {
        case "1w": return 7
        case "2w": return 14
        case "1m": return 30
        case "2m": return 60
        default: return 14
        }
    }
}

enum CalendarRefreshError: LocalizedError, Identifiable {
    case permissionDenied
    case schedulingFailed

    var id: String {
        switch self {
        case .permissionDenied: return "permissionDenied"
        case .schedulingFailed: return "schedulingFailed"
        }
    }

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return NSLocalizedString("calendar.refresh.permission_denied", comment: "")
        case .schedulingFailed:
            return NSLocalizedString("calendar.refresh.scheduling_failed", comment: "")
        }
    }
}
