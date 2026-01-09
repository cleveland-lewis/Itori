import EventKit
import Foundation

/// Lightweight task model for auto-scheduling.
struct AutoScheduleTask: Identifiable {
    let id: UUID
    let title: String
    let estimatedDurationMinutes: Int
    let dueDate: Date
    let priority: Int // higher = more important

    init(id: UUID = UUID(), title: String, estimatedDurationMinutes: Int, dueDate: Date, priority: Int) {
        self.id = id
        self.title = title
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.dueDate = dueDate
        self.priority = priority
    }
}

enum AutoScheduler {
    private static let autoScheduleTagPrefix = "[ItoriAutoSchedule:"

    private struct TimeSlot {
        var startDate: Date
        var duration: TimeInterval // seconds
        var endDate: Date { startDate.addingTimeInterval(duration) }
    }

    /// Main scheduling entry.
    static func generateSchedule(
        tasks: [AutoScheduleTask],
        existingEvents: [EKEvent],
        startDate: Date,
        daysToPlan: Int = 7,
        workDayStart: Int = 9,
        workDayEnd: Int = 17,
        maxStudyMinutesPerDay: Int = 360
    ) -> ScheduleDiff {
        var proposedBlocks: [ProposedBlock] = []
        let remainingTasks = tasks.sorted {
            if $0.priority != $1.priority { return $0.priority > $1.priority }
            return $0.dueDate < $1.dueDate
        }

        var freeSlots = findFreeSlots(
            existingEvents: existingEvents,
            startDate: startDate,
            days: daysToPlan,
            startHour: workDayStart,
            endHour: workDayEnd
        )

        var minutesScheduledPerDay: [Date: Int] = [:] // key = start of day
        let calendar = Calendar.current
        let minBlockMinutes = 60

        for task in remainingTasks {
            var minutesNeeded = task.estimatedDurationMinutes
            var scheduledChunks = 0

            // Try to place task greedily across available slots
            for slotIndex in freeSlots.indices {
                guard minutesNeeded > 0 else { break }
                let slot = freeSlots[slotIndex]
                let dayStart = calendar.startOfDay(for: slot.startDate)
                let already = minutesScheduledPerDay[dayStart] ?? 0
                if already >= maxStudyMinutesPerDay { continue }

                let slotMinutes = Int(slot.duration / 60)
                let allocatableMinutes = min(slotMinutes, maxStudyMinutesPerDay - already)
                let chunk = min(minutesNeeded, allocatableMinutes)

                // Enforce contiguity preference: require a minimum block
                if chunk < minBlockMinutes { continue }

                // Create proposed block for this chunk
                let block = createBlock(
                    for: task,
                    start: slot.startDate,
                    durationMinutes: chunk,
                    chunkIndex: scheduledChunks
                )
                proposedBlocks.append(block)
                scheduledChunks += 1

                // Consume slot
                let consumedSeconds = TimeInterval(chunk * 60)
                freeSlots[slotIndex].startDate = slot.startDate.addingTimeInterval(consumedSeconds)
                freeSlots[slotIndex].duration = max(0, slot.duration - consumedSeconds)

                // Update counters
                minutesScheduledPerDay[dayStart] = already + chunk
                minutesNeeded -= chunk
            }
        }

        return ScheduleDiff(
            addedBlocks: proposedBlocks,
            movedBlocks: [],
            resizedBlocks: [],
            conflicts: [],
            reason: "autoSchedule",
            confidence: AIConfidence(0.6)
        )
    }

    // MARK: - Helpers

    private static func createBlock(
        for task: AutoScheduleTask,
        start: Date,
        durationMinutes: Int,
        chunkIndex: Int
    ) -> ProposedBlock {
        let tag = "\(autoScheduleTagPrefix)\(task.id.uuidString)-\(chunkIndex)]"
        return ProposedBlock(
            tempID: tag,
            title: task.title,
            startDate: start,
            duration: TimeInterval(durationMinutes * 60),
            reason: "Auto-scheduled study block"
        )
    }

    /// Compute free slots within the work window minus existing events.
    private static func findFreeSlots(
        existingEvents: [EKEvent],
        startDate: Date,
        days: Int,
        startHour: Int,
        endHour: Int
    ) -> [TimeSlot] {
        let calendar = Calendar.current
        var slots: [TimeSlot] = []

        for offset in 0 ..< days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
            guard let windowStart = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: day),
                  let windowEnd = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: day) else { continue }

            var daySlots = [TimeSlot(startDate: windowStart, duration: windowEnd.timeIntervalSince(windowStart))]

            // Busy events that overlap the work window
            let busy = existingEvents.compactMap { event -> (Date, Date)? in
                guard let start = event.startDate, let end = event.endDate else { return nil }
                // If no end date, skip
                if end <= windowStart || start >= windowEnd { return nil }
                let clampedStart = max(start, windowStart)
                let clampedEnd = min(end, windowEnd)
                return (clampedStart, clampedEnd)
            }.sorted { $0.0 < $1.0 }

            // Subtract busy intervals from daySlots
            for interval in busy {
                daySlots = subtract(interval: interval, from: daySlots)
            }

            slots.append(contentsOf: daySlots.filter { $0.duration > 0 })
        }

        return slots.sorted { $0.startDate < $1.startDate }
    }

    /// Subtract a busy interval from a collection of slots, returning the remaining free slots.
    private static func subtract(interval: (Date, Date), from slots: [TimeSlot]) -> [TimeSlot] {
        var result: [TimeSlot] = []

        for slot in slots {
            // No overlap
            if interval.1 <= slot.startDate || interval.0 >= slot.endDate {
                result.append(slot)
                continue
            }

            // Overlap: left remainder
            if interval.0 > slot.startDate {
                let duration = interval.0.timeIntervalSince(slot.startDate)
                result.append(TimeSlot(startDate: slot.startDate, duration: duration))
            }

            // Overlap: right remainder
            if interval.1 < slot.endDate {
                let duration = slot.endDate.timeIntervalSince(interval.1)
                result.append(TimeSlot(startDate: interval.1, duration: duration))
            }
        }

        return result
    }
}
