import Foundation
import EventKit
import Combine
import SwiftUI

struct PendingScheduleSuggestion: Identifiable, Equatable {
    let id: UUID
    let diff: ScheduleDiff
    let createdAt: Date
    let inputHash: String
    let featureStateVersion: Int
    let summaryText: String
    let targetCalendarID: String
    let range: ClosedRange<Date>
}

@MainActor
final class CalendarRefreshCoordinator: ObservableObject {
    static let shared = CalendarRefreshCoordinator()

    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var lastRefreshedAt: Date? = nil
    @Published var error: CalendarRefreshError? = nil
    @Published private(set) var pendingScheduleSuggestion: PendingScheduleSuggestion? = nil

    private let calendarManager = CalendarManager.shared
    private let deviceCalendar = DeviceCalendarManager.shared
    private let authManager = CalendarAuthorizationManager.shared
    private var settings: AppSettingsModel { AppSettingsModel.shared }
    private let assignmentsStore = AssignmentsStore.shared

    private let autoScheduleTagPrefix = "[RootsAutoSchedule:"


    func refresh() {
        Task { _ = await runRefresh() }
    }

    @discardableResult
    func runRefresh() async -> CalendarRefreshError? {
        guard !isRefreshing else { return nil }
        isRefreshing = true
        error = nil

        authManager.refreshStatus()
        if authManager.isNotDetermined {
            _ = await deviceCalendar.requestFullAccessIfNeeded()
            authManager.refreshStatus()
        }
        guard authManager.isAuthorized else {
            authManager.logDeniedOnce(context: "manualRefresh")
            error = .permissionDenied
            isRefreshing = false
            return .permissionDenied
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
        return error
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
                dueDate: task.effectiveDueDateTime ?? task.due ?? endDate,
                priority: Int(task.importance * 10)
            )
        }

        let workStartHour = settings.workdayStartHourStorage
        let workEndHour = settings.workdayEndHourStorage
        let daysToPlan = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)

        let existingEvents = deviceCalendar.events.filter { event in
            event.endDate > startDate && event.startDate < endDate
        }

        let proposed = AutoScheduler.generateSchedule(
            tasks: autoTasks,
            existingEvents: existingEvents,
            startDate: startDate,
            daysToPlan: daysToPlan,
            workDayStart: workStartHour,
            workDayEnd: workEndHour
        )

        guard let targetCalendar = targetCalendar() else { return }
        let inputHash = scheduleInputHash(
            tasks: autoTasks,
            startDate: startDate,
            endDate: endDate,
            workDayStart: workStartHour,
            workDayEnd: workEndHour,
            maxStudyMinutesPerDay: 360
        )
        let diff = buildScheduleDiff(
            proposed: proposed,
            existingEvents: existingEvents,
            within: startDate...endDate
        )

        if diff.addedBlocks.isEmpty &&
            diff.movedBlocks.isEmpty &&
            diff.resizedBlocks.isEmpty &&
            diff.removedBlocks.isEmpty &&
            diff.conflicts.isEmpty {
            return
        }

        stageSuggestion(
            PendingScheduleSuggestion(
                id: UUID(),
                diff: diff,
                createdAt: Date(),
                inputHash: inputHash,
                featureStateVersion: 0,
                summaryText: summaryText(for: diff),
                targetCalendarID: targetCalendar.calendarIdentifier,
                range: startDate...endDate
            )
        )
    }

    func applyPendingScheduleSuggestion() {
        Task { @MainActor in
            do {
                try await applyPendingScheduleSuggestionInternal()
            } catch {
                self.error = .schedulingFailed
            }
        }
    }

    func applyPendingScheduleSuggestionNonConflicting() {
        Task { @MainActor in
            do {
                try await applyPendingScheduleSuggestionNonConflictingInternal()
            } catch {
                self.error = .schedulingFailed
            }
        }
    }

    func discardPendingScheduleSuggestion() {
        pendingScheduleSuggestion = nil
    }

    private func applyPendingScheduleSuggestionInternal() async throws {
        guard let suggestion = pendingScheduleSuggestion else { return }
        guard authManager.isAuthorized else {
            authManager.logDeniedOnce(context: "applyScheduleDiff")
            return
        }
        guard let target = calendar(with: suggestion.targetCalendarID) else { return }
        try applyScheduleDiff(suggestion.diff, targetCalendar: target, within: suggestion.range)
        await calendarManager.syncPlannerSessionsToCalendar(in: suggestion.range)
        pendingScheduleSuggestion = nil
        await deviceCalendar.refreshEvents(from: suggestion.range.lowerBound, to: suggestion.range.upperBound, reason: "autoScheduleApply")
    }

    private func applyPendingScheduleSuggestionNonConflictingInternal() async throws {
        guard let suggestion = pendingScheduleSuggestion else { return }
        guard authManager.isAuthorized else {
            authManager.logDeniedOnce(context: "applyScheduleDiffNonConflicting")
            return
        }
        guard let target = calendar(with: suggestion.targetCalendarID) else { return }
        let nonConflicting = suggestion.diff.nonConflictingChanges
        guard nonConflicting.changeCount > 0 else { return }
        try applyScheduleDiff(nonConflicting, targetCalendar: target, within: suggestion.range)
        await calendarManager.syncPlannerSessionsToCalendar(in: suggestion.range)
        await deviceCalendar.refreshEvents(from: suggestion.range.lowerBound, to: suggestion.range.upperBound, reason: "autoScheduleApply")

        if suggestion.diff.conflicts.isEmpty {
            pendingScheduleSuggestion = nil
        } else {
            let remaining = ScheduleDiff(
                addedBlocks: [],
                movedBlocks: [],
                resizedBlocks: [],
                removedBlocks: [],
                conflicts: suggestion.diff.conflicts,
                reason: suggestion.diff.reason,
                confidence: suggestion.diff.confidence
            )
            pendingScheduleSuggestion = PendingScheduleSuggestion(
                id: suggestion.id,
                diff: remaining,
                createdAt: suggestion.createdAt,
                inputHash: suggestion.inputHash,
                featureStateVersion: suggestion.featureStateVersion,
                summaryText: summaryText(for: remaining),
                targetCalendarID: suggestion.targetCalendarID,
                range: suggestion.range
            )
        }
    }

    private func targetCalendar() -> EKCalendar? {
        guard authManager.isAuthorized else {
            authManager.logDeniedOnce(context: "targetCalendar")
            return nil
        }
        if !calendarManager.selectedCalendarID.isEmpty,
           let selected = deviceCalendar.store.calendars(for: .event).first(where: { $0.calendarIdentifier == calendarManager.selectedCalendarID }) {
            return selected
        }
        return deviceCalendar.store.defaultCalendarForNewEvents
    }

    private func calendar(with id: String) -> EKCalendar? {
        guard authManager.isAuthorized else {
            authManager.logDeniedOnce(context: "calendarLookup")
            return nil
        }
        return deviceCalendar.store.calendars(for: .event).first(where: { $0.calendarIdentifier == id })
    }

    func buildScheduleDiff(
        proposed: ScheduleDiff,
        existingEvents: [EKEvent],
        within range: ClosedRange<Date>
    ) -> ScheduleDiff {
        let existingTagged = existingEvents.filter { event in
            event.endDate > range.lowerBound &&
            event.startDate < range.upperBound &&
            extractTag(from: event.notes) != nil
        }

        var existingByTag: [String: EKEvent] = [:]
        for event in existingTagged {
            if let tag = extractTag(from: event.notes) {
                existingByTag[tag] = event
            }
        }

        var additions: [ProposedBlock] = []
        var moved: [MovedBlock] = []
        var resized: [ResizedBlock] = []
        let conflicts: [ScheduleConflict] = proposed.conflicts
        var scheduledTags: Set<String> = []

        for block in proposed.addedBlocks {
            let tag = block.tempID
            scheduledTags.insert(tag)

            if let existing = existingByTag[tag] {
                let existingDuration = existing.endDate.timeIntervalSince(existing.startDate)
                if existing.startDate != block.startDate {
                    moved.append(MovedBlock(blockID: tag, newStartDate: block.startDate, reason: block.reason))
                }
                if existingDuration != block.duration {
                    resized.append(ResizedBlock(blockID: tag, newDuration: block.duration, reason: block.reason))
                }
            } else {
                additions.append(block)
            }
        }

        var removals: [RemovedBlock] = []
        for (tag, _) in existingByTag where !scheduledTags.contains(tag) {
            removals.append(RemovedBlock(blockID: tag, reason: "Auto-schedule removal"))
        }

        return ScheduleDiff(
            addedBlocks: additions,
            movedBlocks: moved,
            resizedBlocks: resized,
            removedBlocks: removals,
            conflicts: conflicts,
            reason: proposed.reason,
            confidence: proposed.confidence
        )
    }

    func applyScheduleDiff(_ diff: ScheduleDiff, targetCalendar: EKCalendar, within range: ClosedRange<Date>) throws {
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

        var movedByID: [String: MovedBlock] = [:]
        var resizedByID: [String: ResizedBlock] = [:]
        for move in diff.movedBlocks { movedByID[move.blockID] = move }
        for resize in diff.resizedBlocks { resizedByID[resize.blockID] = resize }

        for block in diff.addedBlocks where targetCalendar.allowsContentModifications {
            if existingByTag[block.tempID] != nil {
                continue
            }
            let event = EKEvent(eventStore: store)
            event.title = block.title
            event.startDate = block.startDate
            event.endDate = block.startDate.addingTimeInterval(block.duration)
            event.calendar = targetCalendar
            event.notes = mergeNotes(event.notes, tag: block.tempID)
            try store.save(event, span: .thisEvent, commit: true)
        }

        for (tag, event) in existingByTag {
            guard event.calendar.allowsContentModifications else { continue }
            if diff.removedBlocks.contains(where: { $0.blockID == tag }) {
                try store.remove(event, span: .thisEvent, commit: true)
                continue
            }
            let moved = movedByID[tag]
            let resized = resizedByID[tag]
            if moved == nil && resized == nil { continue }
            let existingDuration = event.endDate.timeIntervalSince(event.startDate)
            if let moved { event.startDate = moved.newStartDate }
            let newDuration = resized?.newDuration ?? existingDuration
            event.endDate = event.startDate.addingTimeInterval(newDuration)
            event.notes = mergeNotes(event.notes, tag: tag)
            try store.save(event, span: .thisEvent, commit: true)
        }
    }

    @discardableResult
    func stageSuggestion(_ suggestion: PendingScheduleSuggestion) -> Bool {
        guard pendingScheduleSuggestion == nil else { return false }
        pendingScheduleSuggestion = suggestion
        return true
    }
    
    private func summaryText(for diff: ScheduleDiff) -> String {
        var parts: [String] = []
        if !diff.addedBlocks.isEmpty {
            parts.append("Add \(diff.addedBlocks.count)")
        }
        if !diff.movedBlocks.isEmpty {
            parts.append("Move \(diff.movedBlocks.count)")
        }
        if !diff.resizedBlocks.isEmpty {
            parts.append("Resize \(diff.resizedBlocks.count)")
        }
        if !diff.removedBlocks.isEmpty {
            parts.append("Remove \(diff.removedBlocks.count)")
        }
        if !diff.conflicts.isEmpty {
            parts.append("Conflicts \(diff.conflicts.count)")
        }
        return parts.joined(separator: " - ")
    }

    private func scheduleInputHash(
        tasks: [AutoScheduleTask],
        startDate: Date,
        endDate: Date,
        workDayStart: Int,
        workDayEnd: Int,
        maxStudyMinutesPerDay: Int
    ) -> String {
        struct HashInput: Codable {
            let tasks: [HashTask]
            let startDate: Date
            let endDate: Date
            let workDayStart: Int
            let workDayEnd: Int
            let maxStudyMinutesPerDay: Int
        }
        struct HashTask: Codable {
            let id: UUID
            let estimatedDurationMinutes: Int
            let dueDate: Date
            let priority: Int
        }

        let payload = HashInput(
            tasks: tasks.map {
                HashTask(
                    id: $0.id,
                    estimatedDurationMinutes: $0.estimatedDurationMinutes,
                    dueDate: $0.dueDate,
                    priority: $0.priority
                )
            },
            startDate: startDate,
            endDate: endDate,
            workDayStart: workDayStart,
            workDayEnd: workDayEnd,
            maxStudyMinutesPerDay: maxStudyMinutesPerDay
        )

        guard let data = try? JSONEncoder().encode(payload) else {
            return ""
        }
        return AIInputHasher.hash(inputJSON: data, unorderedArrayKeys: ["tasks"])
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
