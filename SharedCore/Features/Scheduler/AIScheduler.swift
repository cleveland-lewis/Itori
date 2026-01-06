import Foundation

// Simple scheduling types and algorithm for Itori

enum EventSource {
    case calendar, `class`, exam, external
}

enum TaskType: String, Hashable, CaseIterable, Codable {
    case project
    case exam
    case quiz
    case homework
    case reading
    case review
    case study
    case practiceTest

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "homework", "problemSet", "practiceHomework": self = .homework
        case "examPrep": self = .exam
        case "meeting": self = .project
        default:
            if let val = TaskType(rawValue: raw) {
                self = val
            } else {
                self = .homework
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    var displayName: String {
        switch self {
        case .project: return "Project"
        case .exam: return "Exam"
        case .quiz: return "Quiz"
        case .homework: return "Homework"
        case .reading: return "Reading"
        case .review: return "Review"
        case .study: return "Study"
        case .practiceTest: return "Practice Test"
        }
    }
}

struct FixedEvent: Equatable {
    let id: UUID
    let title: String
    let start: Date
    let end: Date
    let isLocked: Bool
    let source: EventSource
}

struct AppTask: Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let courseId: UUID?
    let moduleIds: [UUID]
    let due: Date?
    let dueTimeMinutes: Int?
    let estimatedMinutes: Int
    let minBlockMinutes: Int
    let maxBlockMinutes: Int
    let difficulty: Double     // 0…1
    let importance: Double     // 0…1
    let type: TaskType
    let category: TaskType     // First-class category field (aliased to type for now)
    let locked: Bool
    let recurrence: RecurrenceRule?
    let recurrenceSeriesID: UUID?
    let recurrenceIndex: Int?
    let attachments: [Attachment]
    var isCompleted: Bool
    var gradeWeightPercent: Double?
    var gradePossiblePoints: Double?
    var gradeEarnedPoints: Double?
    var calendarEventIdentifier: String?
    var sourceUniqueKey: String?
    var sourceFingerprint: String?
    var notes: String?
    var needsReview: Bool = false  // Marks items that may be orphaned from source
    
    // Phase 4.1: Alarm reminder properties (iOS/iPadOS only)
    var alarmDate: Date?               // When to fire the alarm reminder
    var alarmEnabled: Bool = false     // Whether alarm is active
    var alarmSound: String?            // Optional custom alarm sound identifier
    
    // Soft delete support for data integrity
    var deletedAt: Date?               // When task was soft-deleted (nil = active)
    
    var isDeleted: Bool { deletedAt != nil }

    init(id: UUID, title: String, courseId: UUID?, moduleIds: [UUID] = [], due: Date?, estimatedMinutes: Int, minBlockMinutes: Int, maxBlockMinutes: Int, difficulty: Double, importance: Double, type: TaskType, locked: Bool, attachments: [Attachment] = [], isCompleted: Bool = false, gradeWeightPercent: Double? = nil, gradePossiblePoints: Double? = nil, gradeEarnedPoints: Double? = nil, category: TaskType? = nil, dueTimeMinutes: Int? = nil, recurrence: RecurrenceRule? = nil, recurrenceSeriesID: UUID? = nil, recurrenceIndex: Int? = nil, calendarEventIdentifier: String? = nil, sourceUniqueKey: String? = nil, sourceFingerprint: String? = nil, notes: String? = nil, needsReview: Bool = false, alarmDate: Date? = nil, alarmEnabled: Bool = false, alarmSound: String? = nil, deletedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.courseId = courseId
        self.moduleIds = moduleIds
        self.due = due.map { Calendar.current.startOfDay(for: $0) }
        self.dueTimeMinutes = dueTimeMinutes
        self.estimatedMinutes = estimatedMinutes
        self.minBlockMinutes = minBlockMinutes
        self.maxBlockMinutes = maxBlockMinutes
        self.difficulty = difficulty
        self.importance = importance
        self.type = type
        self.category = category ?? type  // Use provided category or default to type
        self.locked = locked
        self.recurrence = recurrence
        self.recurrenceSeriesID = recurrenceSeriesID
        self.recurrenceIndex = recurrenceIndex
        self.attachments = attachments
        self.isCompleted = isCompleted
        self.gradeWeightPercent = gradeWeightPercent
        self.gradePossiblePoints = gradePossiblePoints
        self.gradeEarnedPoints = gradeEarnedPoints
        self.calendarEventIdentifier = calendarEventIdentifier
        self.sourceUniqueKey = sourceUniqueKey
        self.sourceFingerprint = sourceFingerprint
        self.notes = notes
        self.needsReview = needsReview
        self.alarmDate = alarmDate
        self.alarmEnabled = alarmEnabled
        self.alarmSound = alarmSound
        self.deletedAt = deletedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case courseId
        case moduleIds
        case due
        case dueTimeMinutes
        case estimatedMinutes
        case minBlockMinutes
        case maxBlockMinutes
        case difficulty
        case importance
        case type
        case category
        case locked
        case recurrence
        case recurrenceSeriesID
        case recurrenceIndex
        case attachments
        case isCompleted
        case gradeWeightPercent
        case gradePossiblePoints
        case gradeEarnedPoints
        case calendarEventIdentifier
        case sourceUniqueKey
        case sourceFingerprint
        case notes
        case needsReview
        case alarmDate           // Phase 4.1
        case alarmEnabled        // Phase 4.1
        case alarmSound          // Phase 4.1
        case deletedAt           // Soft delete support
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        courseId = try container.decodeIfPresent(UUID.self, forKey: .courseId)
        moduleIds = try container.decodeIfPresent([UUID].self, forKey: .moduleIds) ?? []
        let decodedDue = try container.decodeIfPresent(Date.self, forKey: .due)
        let decodedDueTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .dueTimeMinutes)
        if let decodedDue {
            let day = Calendar.current.startOfDay(for: decodedDue)
            due = day
            if let decodedDueTimeMinutes {
                dueTimeMinutes = decodedDueTimeMinutes
            } else {
                let components = Calendar.current.dateComponents([.hour, .minute], from: decodedDue)
                let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                dueTimeMinutes = minutes == 0 ? nil : minutes
            }
        } else {
            due = nil
            dueTimeMinutes = nil
        }
        estimatedMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedMinutes) ?? 60
        minBlockMinutes = try container.decodeIfPresent(Int.self, forKey: .minBlockMinutes) ?? 20
        maxBlockMinutes = try container.decodeIfPresent(Int.self, forKey: .maxBlockMinutes) ?? 180
        difficulty = try container.decodeIfPresent(Double.self, forKey: .difficulty) ?? 0.5
        importance = try container.decodeIfPresent(Double.self, forKey: .importance) ?? 0.5
        type = try container.decodeIfPresent(TaskType.self, forKey: .type) ?? .homework
        category = try container.decodeIfPresent(TaskType.self, forKey: .category) ?? type
        locked = try container.decodeIfPresent(Bool.self, forKey: .locked) ?? false
        recurrence = decodeRecurrenceRule(from: container)
        recurrenceSeriesID = try container.decodeIfPresent(UUID.self, forKey: .recurrenceSeriesID)
        recurrenceIndex = try container.decodeIfPresent(Int.self, forKey: .recurrenceIndex)
        attachments = try container.decodeIfPresent([Attachment].self, forKey: .attachments) ?? []
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        gradeWeightPercent = try container.decodeIfPresent(Double.self, forKey: .gradeWeightPercent)
        gradePossiblePoints = try container.decodeIfPresent(Double.self, forKey: .gradePossiblePoints)
        gradeEarnedPoints = try container.decodeIfPresent(Double.self, forKey: .gradeEarnedPoints)
        calendarEventIdentifier = try container.decodeIfPresent(String.self, forKey: .calendarEventIdentifier)
        sourceUniqueKey = try container.decodeIfPresent(String.self, forKey: .sourceUniqueKey)
        sourceFingerprint = try container.decodeIfPresent(String.self, forKey: .sourceFingerprint)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        needsReview = try container.decodeIfPresent(Bool.self, forKey: .needsReview) ?? false
        
        // Phase 4.1: Decode alarm properties
        alarmDate = try container.decodeIfPresent(Date.self, forKey: .alarmDate)
        alarmEnabled = try container.decodeIfPresent(Bool.self, forKey: .alarmEnabled) ?? false
        alarmSound = try container.decodeIfPresent(String.self, forKey: .alarmSound)
        
        // Soft delete support
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(courseId, forKey: .courseId)
        try container.encode(moduleIds, forKey: .moduleIds)
        try container.encodeIfPresent(due, forKey: .due)
        try container.encodeIfPresent(dueTimeMinutes, forKey: .dueTimeMinutes)
        try container.encode(estimatedMinutes, forKey: .estimatedMinutes)
        try container.encode(minBlockMinutes, forKey: .minBlockMinutes)
        try container.encode(maxBlockMinutes, forKey: .maxBlockMinutes)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(importance, forKey: .importance)
        try container.encode(type, forKey: .type)
        try container.encode(category, forKey: .category)
        try container.encode(locked, forKey: .locked)
        try container.encodeIfPresent(recurrence, forKey: .recurrence)
        try container.encodeIfPresent(recurrenceSeriesID, forKey: .recurrenceSeriesID)
        try container.encodeIfPresent(recurrenceIndex, forKey: .recurrenceIndex)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(gradeWeightPercent, forKey: .gradeWeightPercent)
        try container.encodeIfPresent(gradePossiblePoints, forKey: .gradePossiblePoints)
        try container.encodeIfPresent(gradeEarnedPoints, forKey: .gradeEarnedPoints)
        try container.encodeIfPresent(calendarEventIdentifier, forKey: .calendarEventIdentifier)
        try container.encodeIfPresent(sourceUniqueKey, forKey: .sourceUniqueKey)
        try container.encodeIfPresent(sourceFingerprint, forKey: .sourceFingerprint)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(needsReview, forKey: .needsReview)
        
        // Phase 4.1: Encode alarm properties
        try container.encodeIfPresent(alarmDate, forKey: .alarmDate)
        try container.encode(alarmEnabled, forKey: .alarmEnabled)
        try container.encodeIfPresent(alarmSound, forKey: .alarmSound)
        
        // Soft delete support
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
    }

    func withCourseId(_ newCourseId: UUID?) -> AppTask {
        AppTask(
            id: id,
            title: title,
            courseId: newCourseId,
            moduleIds: moduleIds,
            due: due,
            estimatedMinutes: estimatedMinutes,
            minBlockMinutes: minBlockMinutes,
            maxBlockMinutes: maxBlockMinutes,
            difficulty: difficulty,
            importance: importance,
            type: type,
            locked: locked,
            attachments: attachments,
            isCompleted: isCompleted,
            gradeWeightPercent: gradeWeightPercent,
            gradePossiblePoints: gradePossiblePoints,
            gradeEarnedPoints: gradeEarnedPoints,
            category: category,
            dueTimeMinutes: dueTimeMinutes,
            recurrence: recurrence,
            recurrenceSeriesID: recurrenceSeriesID,
            recurrenceIndex: recurrenceIndex,
            calendarEventIdentifier: calendarEventIdentifier,
            sourceUniqueKey: sourceUniqueKey,
            sourceFingerprint: sourceFingerprint,
            notes: notes,
            needsReview: needsReview,
            alarmDate: alarmDate,
            alarmEnabled: alarmEnabled,
            alarmSound: alarmSound
        )
    }
}

private func decodeRecurrenceRule(from container: KeyedDecodingContainer<AppTask.CodingKeys>) -> RecurrenceRule? {
    if let rule = try? container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrence) {
        return rule
    }
    if let legacy = try? container.decodeIfPresent(String.self, forKey: .recurrence) {
        switch legacy {
        case "daily":
            return RecurrenceRule.preset(.daily)
        case "weekly":
            return RecurrenceRule.preset(.weekly)
        case "biweekly":
            return RecurrenceRule(frequency: .weekly, interval: 2, end: .never, skipPolicy: .init())
        case "monthly":
            return RecurrenceRule.preset(.monthly)
        case "yearly":
            return RecurrenceRule.preset(.yearly)
        default:
            return nil
        }
    }
    return nil
}

extension AppTask {
    /// True if this task is not associated with any course (personal task)
    var isPersonal: Bool {
        courseId == nil
    }
    
    var effectiveDueDateTime: Date? {
        guard let due else { return nil }
        if let dueTimeMinutes {
            return Calendar.current.date(byAdding: .minute, value: dueTimeMinutes, to: due)
        }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: due)
        components.hour = 23
        components.minute = 59
        return Calendar.current.date(from: components)
    }
    
    var hasExplicitDueTime: Bool {
        dueTimeMinutes != nil
    }
    
    /// Convenience initializer with safe defaults for common cases
    /// Reduces initializer drift when model evolves
    static func create(
        id: UUID = UUID(),
        title: String,
        courseId: UUID? = nil,
        moduleIds: [UUID] = [],
        due: Date? = nil,
        estimatedMinutes: Int = 60,
        type: TaskType = .homework,
        difficulty: Double = 0.5,
        importance: Double = 0.5,
        locked: Bool = false
    ) -> AppTask {
        AppTask(
            id: id,
            title: title,
            courseId: courseId,
            moduleIds: moduleIds,
            due: due,
            estimatedMinutes: estimatedMinutes,
            minBlockMinutes: 20,
            maxBlockMinutes: 120,
            difficulty: difficulty,
            importance: importance,
            type: type,
            locked: locked,
            attachments: [],
            isCompleted: false,
            category: type
        )
    }
}

struct Constraints {
    let horizonStart: Date
    let horizonEnd: Date
    let dayStartHour: Int
    let dayEndHour: Int
    let maxStudyMinutesPerDay: Int
    let maxStudyMinutesPerBlock: Int
    let minGapBetweenBlocksMinutes: Int
    let doNotScheduleWindows: [ClosedRange<Date>]
    let energyProfile: [Int: Double] // hourOfDay → 0…1
}

struct ScheduledBlock: Equatable {
    let id: UUID
    let taskId: UUID
    let start: Date
    let end: Date
}

struct ScheduleResult {
    var blocks: [ScheduledBlock]
    var unscheduledTasks: [AppTask]
    var log: [String]
}

// Helpers
private struct FreeInterval: Equatable {
    var start: Date
    var end: Date
    var durationMinutes: Int { Int(end.timeIntervalSince(start) / 60.0) }
}

private struct CandidateBlock: Equatable {
    var start: Date
    var end: Date
    var energyScore: Double
    var dayStart: Date
    var durationMinutes: Int { Int(end.timeIntervalSince(start) / 60.0) }
}


struct AIScheduler {
    private static let calendar = Calendar.current
    // Expose Task alias for tests that reference AIScheduler.Task
    typealias Task = AppTask

    // Public entry
    static func generateSchedule(
        tasks inputTasks: [Task],
        fixedEvents: [FixedEvent],
        constraints: Constraints,
        preferences: SchedulerPreferences = SchedulerPreferences.default(),
        energyLevel: EnergyLevel = .medium
    ) -> ScheduleResult {
        LOG_SCHEDULER(.info, "ScheduleGeneration", "Starting schedule generation", metadata: ["tasks": "\(inputTasks.count)", "fixedEvents": "\(fixedEvents.count)", "energyLevel": "\(energyLevel.rawValue)"])
        var log: [String] = []

        // 1. Filter tasks based on energy level
        let filteredTasks = filterTasksByEnergyLevel(tasks: inputTasks, energyLevel: energyLevel)
        LOG_SCHEDULER(.debug, "ScheduleGeneration", "Filtered tasks by energy", metadata: ["original": "\(inputTasks.count)", "filtered": "\(filteredTasks.count)", "energyLevel": "\(energyLevel.rawValue)"])

        // 2. Build free intervals per day
        let dayIntervals = buildFreeIntervalsPerDay(fixedEvents: fixedEvents, constraints: constraints)
        LOG_SCHEDULER(.debug, "ScheduleGeneration", "Built free intervals", metadata: ["days": "\(dayIntervals.count)"])

        // 3. Compute task priorities
        var tasks = filteredTasks // include locked tasks; they can be forced to due date
        let horizonDays = daysBetween(start: constraints.horizonStart, end: constraints.horizonEnd)
        var priorityMap: [UUID: Double] = [:]
        for task in tasks {
            priorityMap[task.id] = computePriority(for: task, horizonDays: max(1, horizonDays), preferences: preferences)
        }

        // 3. Generate candidate blocks
        var candidates = generateCandidates(from: dayIntervals, constraints: constraints)

        // 4. Assign tasks greedily
        // Sort tasks by priority desc, due asc
        tasks.sort { (a, b) -> Bool in
            let pa = priorityMap[a.id] ?? 0
            let pb = priorityMap[b.id] ?? 0
            if pa == pb {
                return (a.due ?? Date.distantFuture) < (b.due ?? Date.distantFuture)
            }
            return pa > pb
        }

        var scheduledBlocks: [ScheduledBlock] = []
        var unscheduled: [Task] = []

        // Track per-day scheduled minutes
        var minutesScheduledForDay: [Date: Int] = [:] // key = startOfDay

        // candidate availability is represented by the candidates array; when partially used, we update it

        for task in tasks {
            var remaining = task.estimatedMinutes
            let taskPriority = priorityMap[task.id] ?? 0
            let dueDate = task.due

            // Filter candidates for this task each iteration (dynamic)
            var attempts = 0
            while remaining > 0 {
                attempts += 1
                // Avoid infinite loop
                if attempts > 5000 { break }

                // Build feasible candidate list
                let feasibleIndices = candidates.indices.filter { idx in
                    let c = candidates[idx]
                    // candidate must be at least minBlock
                    if c.durationMinutes < task.minBlockMinutes { return false }
                    // candidate must not exceed per-block max for scheduler and task
                    if c.durationMinutes <= 0 { return false }
                    if c.durationMinutes < task.minBlockMinutes { return false }
                    if c.durationMinutes > constraints.maxStudyMinutesPerBlock && constraints.maxStudyMinutesPerBlock > 0 { return false }
                    // due date constraint
                    if let due = dueDate, c.end > due { return false }
                    // per-day cap
                    let dayKey = startOfDay(c.start)
                    let already = minutesScheduledForDay[dayKey] ?? 0
                    if already >= constraints.maxStudyMinutesPerDay { return false }
                    return true
                }

                if feasibleIndices.isEmpty { break }

                // Score candidates
                var bestIdx: Int? = nil
                var bestScore: Double = -Double.infinity
                for idx in feasibleIndices {
                    let c = candidates[idx]
                    let energy = c.energyScore
                    // lateness penalty: if due exists, penalize distance to due (closer to due -> higher penalty), prefer earlier -> negative penalty
                    var latenessPenalty = 0.0
                    if let due = dueDate {
                        let secondsUntilDue = due.timeIntervalSince(c.start)
                        // if candidate is after due, already filtered
                        let daysUntilDue = max(0.0, secondsUntilDue / 86400.0)
                        // closer to due -> higher penalty. Normalize by horizon days
                        latenessPenalty = (1.0 / (1.0 + daysUntilDue)) // in (0,1]
                    }

                    // Composite score
                    // deterministic weights
                    let alpha = 1.0 // task priority weight
                    let beta = 0.5  // energy weight
                    let gamma = 0.5 // lateness penalty weight (lower is better)

                    let score = alpha * taskPriority + beta * energy - gamma * latenessPenalty

                    if score > bestScore {
                        bestScore = score
                        bestIdx = idx
                    }
                }

                guard let chosenIdx = bestIdx else { break }
                let chosen = candidates[chosenIdx]

                // Determine duration to schedule in this candidate
                let chosenDuration = min(task.maxBlockMinutes, chosen.durationMinutes, remaining)
                // Respect scheduler global per-block cap
                let finalDuration = min(chosenDuration, constraints.maxStudyMinutesPerBlock > 0 ? constraints.maxStudyMinutesPerBlock : chosenDuration)

                // Create scheduled block
                let blockStart = chosen.start
                let blockEnd = calendar.date(byAdding: .minute, value: finalDuration, to: blockStart)!
                let sb = ScheduledBlock(id: UUID(), taskId: task.id, start: blockStart, end: blockEnd)
                scheduledBlocks.append(sb)

                // Update remaining and candidate
                remaining -= finalDuration

                // Update per-day counters
                let dayKey = startOfDay(blockStart)
                minutesScheduledForDay[dayKey] = (minutesScheduledForDay[dayKey] ?? 0) + finalDuration

                // Update chosen candidate: remove the used portion from its start
                if blockEnd >= chosen.end {
                    // used entire candidate
                    candidates.remove(at: chosenIdx)
                } else {
                    // shrink candidate start forward
                    candidates[chosenIdx].start = blockEnd
                }

                // If candidate leftover is shorter than minBlock, discard it
                if chosenIdx < candidates.count {
                    if candidates[chosenIdx].durationMinutes < task.minBlockMinutes {
                        candidates.remove(at: chosenIdx)
                    }
                }

                // also enforce min gap between blocks by trimming nearby candidates (optional)
                if constraints.minGapBetweenBlocksMinutes > 0 {
                    let gap = constraints.minGapBetweenBlocksMinutes
                    // remove or trim candidates that start within gap of blockEnd
                    candidates = candidates.flatMap { c -> [CandidateBlock] in
                        if c.start < blockEnd.addingTimeInterval(TimeInterval(gap * 60)) && c.end > blockEnd {
                            // trim start
                            var trimmed = c
                            trimmed.start = blockEnd.addingTimeInterval(TimeInterval(gap * 60))
                            if trimmed.durationMinutes >= task.minBlockMinutes {
                                return [trimmed]
                            } else {
                                return []
                            }
                        }
                        return [c]
                    }
                }
            }

            if remaining > 0 {
                unscheduled.append(task)
                log.append("Task \(task.title): scheduled \(task.estimatedMinutes - remaining)/\(task.estimatedMinutes) minutes; could not fully schedule within horizon.")
            } else {
                log.append("Task \(task.title): fully scheduled.")
            }
        }

        // 5. Local improvement pass: merge adjacent blocks for same task on the same day
        scheduledBlocks.sort { $0.start < $1.start }
        scheduledBlocks = mergeAdjacentBlocks(blocks: scheduledBlocks, maxBlockMinutes: constraints.maxStudyMinutesPerBlock, minGap: constraints.minGapBetweenBlocksMinutes)

        LOG_SCHEDULER(.info, "ScheduleGeneration", "Schedule generation complete", metadata: ["scheduled": "\(scheduledBlocks.count)", "unscheduled": "\(unscheduled.count)"])
        if !unscheduled.isEmpty {
            LOG_SCHEDULER(.warn, "ScheduleGeneration", "Some tasks could not be scheduled", metadata: ["count": "\(unscheduled.count)"])
        }
        return ScheduleResult(blocks: scheduledBlocks, unscheduledTasks: unscheduled, log: log)
    }

    // MARK: - Free interval generation
    private static func buildFreeIntervalsPerDay(fixedEvents: [FixedEvent], constraints: Constraints) -> [Date: [FreeInterval]] {
        var result: [Date: [FreeInterval]] = [:]
        let start = startOfDay(constraints.horizonStart)
        let end = startOfDay(constraints.horizonEnd)

        var current = start
        while current <= end {
            let dayStart = calendar.date(bySettingHour: constraints.dayStartHour, minute: 0, second: 0, of: current)!
            let dayEnd = calendar.date(bySettingHour: constraints.dayEndHour, minute: 0, second: 0, of: current)!

            var free: [FreeInterval] = [FreeInterval(start: dayStart, end: dayEnd)]

            // gather blockers for this day: fixed events and doNotScheduleWindows that intersect
            let blockers: [ClosedRange<Date>] = {
                var b: [ClosedRange<Date>] = []
                for fe in fixedEvents {
                    // consider events that overlap this day window
                    if fe.end <= dayStart || fe.start >= dayEnd { continue }
                    // treat any locked events as blockers; unlocked fixed events could be considered flexible but here we block
                    if fe.isLocked {
                        let rStart = max(fe.start, dayStart)
                        let rEnd = min(fe.end, dayEnd)
                        b.append(rStart...rEnd)
                    }
                }
                for w in constraints.doNotScheduleWindows {
                    if w.upperBound <= dayStart || w.lowerBound >= dayEnd { continue }
                    let rStart = max(w.lowerBound, dayStart)
                    let rEnd = min(w.upperBound, dayEnd)
                    b.append(rStart...rEnd)
                }
                // sort blockers by start
                b.sort { $0.lowerBound < $1.lowerBound }
                return b
            }()

            // subtract blockers from free intervals
            for blocker in blockers {
                free = subtractIntervalList(free, blockerLower: blocker.lowerBound, blockerUpper: blocker.upperBound)
            }

            // discard fragments smaller than smallest feasible block (use 20 minutes as safe minimum or min from constraints if present)
            let minFeasible = 20
            free = free.filter { $0.durationMinutes >= minFeasible }

            result[startOfDay(current)] = free

            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return result
    }

    private static func subtractIntervalList(_ free: [FreeInterval], blockerLower: Date, blockerUpper: Date) -> [FreeInterval] {
        var out: [FreeInterval] = []
        for interval in free {
            // no overlap
            if blockerUpper <= interval.start || blockerLower >= interval.end {
                out.append(interval)
                continue
            }

            // overlap exists
            if blockerLower <= interval.start && blockerUpper >= interval.end {
                // blocker covers whole interval -> remove
                continue
            }

            if blockerLower <= interval.start {
                // trim left side
                let newStart = blockerUpper
                if newStart < interval.end {
                    out.append(FreeInterval(start: newStart, end: interval.end))
                }
            } else if blockerUpper >= interval.end {
                // trim right side
                let newEnd = blockerLower
                if newEnd > interval.start {
                    out.append(FreeInterval(start: interval.start, end: newEnd))
                }
            } else {
                // blocker in middle -> split
                out.append(FreeInterval(start: interval.start, end: blockerLower))
                out.append(FreeInterval(start: blockerUpper, end: interval.end))
            }
        }
        // sort by start
        out.sort { $0.start < $1.start }
        return out
    }

    // MARK: - Priority
    private static func computePriority(for task: Task, horizonDays: Int, preferences: SchedulerPreferences) -> Double {
        // urgency
        let now = Date()
        var urgency: Double = 0
        if let due = task.due {
            let timeToDue = max(0.0, due.timeIntervalSince(now))
            let days = timeToDue / 86400.0
            urgency = 1.0 - clamp(days / Double(horizonDays), 0, 1)
        }

        let importance = clamp(task.importance, 0, 1)
        let difficulty = clamp(task.difficulty, 0, 1)
        // size factor relative to 180 minutes reference
        let sizeFactor = clamp(Double(task.estimatedMinutes) / 180.0, 0, 1)

        let wUrgency = preferences.wUrgency
        let wImportance = preferences.wImportance
        let wDifficulty = preferences.wDifficulty
        let wSize = preferences.wSize

        // course bias
        var bias = 0.0
        if let cid = task.courseId {
            bias = preferences.courseBias[cid] ?? 0.0
        }

        let score = wUrgency * urgency + wImportance * importance + wDifficulty * difficulty + wSize * sizeFactor + bias
        return score
    }

    // MARK: - Candidate generation
    private static func generateCandidates(from dayIntervals: [Date: [FreeInterval]], constraints: Constraints) -> [CandidateBlock] {
        var candidates: [CandidateBlock] = []
        let sortedDays = dayIntervals.keys.sorted()

        for day in sortedDays {
            guard let intervals = dayIntervals[day] else { continue }
            for interval in intervals {
                var remaining = interval.durationMinutes
                var cursor = interval.start

                // If the interval is short but >= minBlock, create one candidate
                if remaining <= constraints.maxStudyMinutesPerBlock || constraints.maxStudyMinutesPerBlock <= 0 {
                    if remaining >= 20 {
                        let energy = energyForDate(cursor, profile: constraints.energyProfile)
                        candidates.append(CandidateBlock(start: cursor, end: interval.end, energyScore: energy, dayStart: day))
                    }
                    continue
                }

                // Otherwise, break into chunks of up to maxStudyMinutesPerBlock deterministically
                let chunk = max(20, min(constraints.maxStudyMinutesPerBlock > 0 ? constraints.maxStudyMinutesPerBlock : remaining, remaining))
                while remaining >= 20 {
                    let dur = min(chunk, remaining)
                    let end = calendar.date(byAdding: .minute, value: dur, to: cursor)!
                    let energy = energyForDate(cursor, profile: constraints.energyProfile)
                    candidates.append(CandidateBlock(start: cursor, end: end, energyScore: energy, dayStart: day))
                    remaining -= dur
                    cursor = end
                }
            }
        }

        return candidates
    }

    // MARK: - Merge adjacent
    private static func mergeAdjacentBlocks(blocks: [ScheduledBlock], maxBlockMinutes: Int, minGap: Int) -> [ScheduledBlock] {
        guard !blocks.isEmpty else { return [] }
        var out: [ScheduledBlock] = []
        var current = blocks[0]
        for i in 1..<blocks.count {
            let next = blocks[i]
            if next.taskId == current.taskId {
                let gap = Int(next.start.timeIntervalSince(current.end) / 60.0)
                let combinedMinutes = Int(next.end.timeIntervalSince(current.start) / 60.0)
                if gap <= minGap && (maxBlockMinutes <= 0 || combinedMinutes <= maxBlockMinutes) {
                    // merge
                    current = ScheduledBlock(id: current.id, taskId: current.taskId, start: current.start, end: next.end)
                    continue
                }
            }
            out.append(current)
            current = next
        }
        out.append(current)
        return out
    }

    // MARK: - Energy-Aware Task Filtering
    /// Filters tasks based on current energy level
    /// - High: All tasks
    /// - Medium: Tasks due within 7 days + high importance tasks
    /// - Low: Only critically due tasks (today/tomorrow) and urgent items
    private static func filterTasksByEnergyLevel(tasks: [Task], energyLevel: EnergyLevel) -> [Task] {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let sevenDays = calendar.date(byAdding: .day, value: 7, to: today)!
        
        switch energyLevel {
        case .high:
            // High energy: schedule all tasks
            return tasks
            
        case .medium:
            // Medium energy: tasks due within a week OR high importance
            return tasks.filter { task in
                // Always include locked tasks
                if task.locked { return true }
                
                // Include high importance tasks regardless of due date
                if task.importance >= 0.7 { return true }
                
                // Include tasks due within 7 days
                if let due = task.due, due <= sevenDays {
                    return true
                }
                
                // Include tasks with no due date if they're important enough
                if task.due == nil && task.importance >= 0.5 {
                    return true
                }
                
                return false
            }
            
        case .low:
            // Low energy: only critically due (today/tomorrow) or very urgent
            return tasks.filter { task in
                // Always include locked tasks
                if task.locked { return true }
                
                // Include tasks due today or tomorrow
                if let due = task.due {
                    if due <= tomorrow {
                        return true
                    }
                    
                    // Include very urgent tasks (within 2 days) if they're also important
                    let twoDays = calendar.date(byAdding: .day, value: 2, to: today)!
                    if due <= twoDays && task.importance >= 0.7 {
                        return true
                    }
                }
                
                // Include critical items (high importance + difficulty)
                if task.importance >= 0.8 && task.difficulty >= 0.6 {
                    return true
                }
                
                return false
            }
        }
    }

    // MARK: - Utilities
    private static func energyForDate(_ date: Date, profile: [Int: Double]) -> Double {
        let hour = calendar.component(.hour, from: date)
        return profile[hour] ?? 0.5
    }

    private static func startOfDay(_ d: Date) -> Date {
        return calendar.startOfDay(for: d)
    }

    private static func daysBetween(start: Date, end: Date) -> Int {
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        let comps = calendar.dateComponents([.day], from: s, to: e)
        return max(1, comps.day ?? 1)
    }

    private static func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T {
        return min(max(v, lo), hi)
    }
}

// MARK: - TaskType Extensions for Duration Estimation
extension TaskType {
    /// Base estimate in minutes for first session
    var baseEstimateMinutes: Int {
        switch self {
        case .reading: return 45
        case .homework: return 75
        case .review: return 60
        case .project: return 120
        case .exam: return 180
        case .quiz: return 30
        case .study: return 60
        case .practiceTest: return 60
        }
    }
    
    /// Step size for duration picker
    var stepSize: Int {
        switch self {
        case .reading, .review, .quiz: return 5
        case .homework, .study: return 10
        case .project, .exam: return 15
        case .practiceTest: return 10
        }
    }
    
    /// Convert to AssignmentCategory for compatibility
    var asAssignmentCategory: AssignmentCategory {
        switch self {
        case .project: return .project
        case .exam: return .exam
        case .quiz: return .quiz
        case .homework: return .homework
        case .reading: return .reading
        case .review: return .review
        case .study: return .review
        case .practiceTest: return .practiceTest
        }
    }
}
