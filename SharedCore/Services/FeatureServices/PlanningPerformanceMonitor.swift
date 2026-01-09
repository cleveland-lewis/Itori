import Foundation

/// Performance monitoring for the deterministic planning engine
enum PlanningPerformanceMonitor {
    struct Metrics {
        var planGenerationTime: TimeInterval = 0
        var sessionGenerationTime: TimeInterval = 0
        var schedulingTime: TimeInterval = 0
        var totalTime: TimeInterval = 0
        var stepsGenerated: Int = 0
        var sessionsGenerated: Int = 0
        var sessionsScheduled: Int = 0
        var sessionsOverflow: Int = 0

        var efficiency: Double {
            guard totalTime > 0 else { return 0 }
            let successRate = Double(sessionsScheduled) / Double(max(1, sessionsGenerated))
            return successRate
        }

        var throughput: Double {
            guard totalTime > 0 else { return 0 }
            return Double(sessionsScheduled) / totalTime
        }
    }

    static func measurePlanGeneration<T>(
        operation: () -> T
    ) -> (result: T, duration: TimeInterval) {
        let start = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let duration = CFAbsoluteTimeGetCurrent() - start
        return (result, duration)
    }

    static func measureScheduling(
        sessions: [PlannerSession],
        settings: StudyPlanSettings,
        energyProfile: [Int: Double]
    ) -> (result: (scheduled: [ScheduledSession], overflow: [PlannerSession]), metrics: Metrics) {
        var metrics = Metrics()

        let start = CFAbsoluteTimeGetCurrent()

        let sessionResult = measurePlanGeneration {
            sessions
        }
        metrics.sessionGenerationTime = sessionResult.duration
        metrics.sessionsGenerated = sessions.count

        let scheduleResult = measurePlanGeneration {
            PlannerEngine.scheduleSessions(sessions, settings: settings, energyProfile: energyProfile)
        }
        metrics.schedulingTime = scheduleResult.duration
        metrics.sessionsScheduled = scheduleResult.result.scheduled.count
        metrics.sessionsOverflow = scheduleResult.result.overflow.count

        metrics.totalTime = CFAbsoluteTimeGetCurrent() - start

        return (scheduleResult.result, metrics)
    }

    static func generateFullPlanMetrics(
        for assignment: Assignment,
        settings: PlanGenerationSettings = .default,
        studySettings: StudyPlanSettings = StudyPlanSettings(),
        energyProfile: [Int: Double]
    ) -> (plan: AssignmentPlan, metrics: Metrics) {
        var metrics = Metrics()
        let overallStart = CFAbsoluteTimeGetCurrent()

        // Measure plan generation
        let planResult = measurePlanGeneration {
            AssignmentPlanEngine.generatePlan(for: assignment, settings: settings)
        }
        metrics.planGenerationTime = planResult.duration
        metrics.stepsGenerated = planResult.result.steps.count

        // Measure session generation
        let sessionResult = measurePlanGeneration {
            PlannerEngine.generateSessions(for: assignment, settings: studySettings)
        }
        metrics.sessionGenerationTime = sessionResult.duration
        metrics.sessionsGenerated = sessionResult.result.count

        // Measure scheduling
        let scheduleResult = measurePlanGeneration {
            PlannerEngine.scheduleSessions(sessionResult.result, settings: studySettings, energyProfile: energyProfile)
        }
        metrics.schedulingTime = scheduleResult.duration
        metrics.sessionsScheduled = scheduleResult.result.scheduled.count
        metrics.sessionsOverflow = scheduleResult.result.overflow.count

        metrics.totalTime = CFAbsoluteTimeGetCurrent() - overallStart

        return (planResult.result, metrics)
    }
}

// MARK: - Optimization Helpers

extension AssignmentPlanEngine {
    /// Validate that a plan meets quality standards
    static func validatePlan(_ plan: AssignmentPlan) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        // Check if plan has steps
        if plan.steps.isEmpty {
            issues.append(.emptyPlan)
        }

        // Check sequence indices
        let sortedSteps = plan.steps.sorted { $0.sequenceIndex < $1.sequenceIndex }
        for (index, step) in sortedSteps.enumerated() {
            if step.sequenceIndex != index {
                issues.append(.invalidSequenceIndex(stepId: step.id, expected: index, actual: step.sequenceIndex))
            }
        }

        // Check for overlapping time windows
        for i in 0 ..< sortedSteps.count {
            for j in (i + 1) ..< sortedSteps.count {
                let step1 = sortedSteps[i]
                let step2 = sortedSteps[j]

                if let start1 = step1.recommendedStartDate,
                   let due1 = step1.dueBy,
                   let start2 = step2.recommendedStartDate,
                   let due2 = step2.dueBy
                {
                    // Check if windows overlap inappropriately
                    if start2 < start1 && due2 > start1 {
                        issues.append(.timeWindowOverlap(step1: step1.id, step2: step2.id))
                    }
                }
            }
        }

        // Check for unrealistic durations
        for step in plan.steps {
            if step.estimatedDuration < 60 { // Less than 1 minute
                issues.append(.unrealisticDuration(stepId: step.id, duration: step.estimatedDuration))
            }
            if step.estimatedDuration > 8 * 60 * 60 { // More than 8 hours
                issues.append(.excessiveDuration(stepId: step.id, duration: step.estimatedDuration))
            }
        }

        // Check for dependency cycles
        if plan.sequenceEnforcementEnabled {
            if let cycle = plan.detectCycle() {
                issues.append(.dependencyCycle(cycleIds: cycle))
            }
        }

        return issues
    }

    enum ValidationIssue: Equatable {
        case emptyPlan
        case invalidSequenceIndex(stepId: UUID, expected: Int, actual: Int)
        case timeWindowOverlap(step1: UUID, step2: UUID)
        case unrealisticDuration(stepId: UUID, duration: TimeInterval)
        case excessiveDuration(stepId: UUID, duration: TimeInterval)
        case dependencyCycle(cycleIds: [UUID])

        var description: String {
            switch self {
            case .emptyPlan:
                "Plan contains no steps"
            case let .invalidSequenceIndex(stepId, expected, actual):
                "Step \(stepId) has invalid sequence index. Expected: \(expected), Actual: \(actual)"
            case let .timeWindowOverlap(step1, step2):
                "Time windows overlap between steps \(step1) and \(step2)"
            case let .unrealisticDuration(stepId, duration):
                "Step \(stepId) has unrealistic duration: \(duration) seconds"
            case let .excessiveDuration(stepId, duration):
                "Step \(stepId) has excessive duration: \(duration / 3600) hours"
            case let .dependencyCycle(cycleIds):
                "Dependency cycle detected: \(cycleIds)"
            }
        }
    }
}

// MARK: - Plan Quality Metrics

extension AssignmentPlan {
    /// Calculate quality score for this plan (0-100)
    var qualityScore: Double {
        var score = 100.0

        // Deduct for empty plan
        if steps.isEmpty {
            return 0
        }

        // Check time distribution
        let durations = steps.map(\.estimatedDuration)
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.map { pow($0 - avgDuration, 2) }.reduce(0, +) / Double(durations.count)
        let stdDev = sqrt(variance)

        // Penalize high variance (inconsistent session lengths)
        if stdDev > avgDuration * 0.5 {
            score -= 10
        }

        // Check timing consistency
        let sortedSteps = self.sortedSteps
        var hasTimingGaps = false
        for i in 0 ..< (sortedSteps.count - 1) {
            if let end1 = sortedSteps[i].dueBy,
               let start2 = sortedSteps[i + 1].recommendedStartDate
            {
                let gap = start2.timeIntervalSince(end1)
                if gap > 48 * 60 * 60 { // More than 2 days
                    hasTimingGaps = true
                    break
                }
            }
        }
        if hasTimingGaps {
            score -= 5
        }

        // Bonus for reasonable step count
        let idealStepCount = 4
        let stepCountDiff = abs(steps.count - idealStepCount)
        if stepCountDiff <= 2 {
            score += 5
        }

        // Check completion feasibility
        if let firstStart = sortedSteps.first?.recommendedStartDate,
           let lastDue = sortedSteps.last?.dueBy
        {
            let totalAvailableTime = lastDue.timeIntervalSince(firstStart)
            let totalRequiredTime = totalEstimatedDuration

            // Should have at least 20% buffer
            if totalAvailableTime < totalRequiredTime * 1.2 {
                score -= 15
            }
        }

        return max(0, min(100, score))
    }

    /// Complexity score (higher = more complex plan)
    var complexityScore: Double {
        var complexity: Double = 0

        // Base complexity from step count
        complexity += Double(steps.count) * 10

        // Add complexity for dependencies
        if sequenceEnforcementEnabled {
            let totalDependencies = steps.reduce(0) { $0 + $1.prerequisiteIds.count }
            complexity += Double(totalDependencies) * 5
        }

        // Add complexity for varied step types
        let uniqueTypes = Set(steps.map(\.stepType)).count
        complexity += Double(uniqueTypes) * 8

        // Add complexity for long duration spread
        if let firstStart = sortedSteps.first?.recommendedStartDate,
           let lastDue = sortedSteps.last?.dueBy
        {
            let daysSpread = lastDue.timeIntervalSince(firstStart) / (24 * 60 * 60)
            complexity += daysSpread * 2
        }

        return complexity
    }
}

// MARK: - Benchmarking

#if DEBUG
    enum PlanningBenchmark {
        static func runBenchmark(iterations: Int = 100) -> BenchmarkResult {
            var totalPlanTime: TimeInterval = 0
            var totalSessionTime: TimeInterval = 0
            var totalScheduleTime: TimeInterval = 0

            let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
            let energyProfile = [
                9: 0.7,
                10: 0.8,
                11: 0.9,
                12: 0.7,
                13: 0.6,
                14: 0.7,
                15: 0.8,
                16: 0.9,
                17: 0.7,
                18: 0.6,
                19: 0.5,
                20: 0.4
            ]

            for _ in 0 ..< iterations {
                let assignment = Assignment(
                    id: UUID(),
                    courseId: nil,
                    title: "Benchmark Test",
                    dueDate: dueDate,
                    estimatedMinutes: 240,
                    weightPercent: nil,
                    category: .exam,
                    urgency: .high,
                    isLockedToDueDate: false,
                    plan: []
                )

                let (_, metrics) = PlanningPerformanceMonitor.generateFullPlanMetrics(
                    for: assignment,
                    energyProfile: energyProfile
                )

                totalPlanTime += metrics.planGenerationTime
                totalSessionTime += metrics.sessionGenerationTime
                totalScheduleTime += metrics.schedulingTime
            }

            return BenchmarkResult(
                iterations: iterations,
                avgPlanGeneration: totalPlanTime / Double(iterations),
                avgSessionGeneration: totalSessionTime / Double(iterations),
                avgScheduling: totalScheduleTime / Double(iterations)
            )
        }

        struct BenchmarkResult {
            let iterations: Int
            let avgPlanGeneration: TimeInterval
            let avgSessionGeneration: TimeInterval
            let avgScheduling: TimeInterval

            var totalAverage: TimeInterval {
                avgPlanGeneration + avgSessionGeneration + avgScheduling
            }

            var formattedReport: String {
                """
                Planning Engine Benchmark (\(iterations) iterations)
                ====================================================
                Average Plan Generation:    \(String(format: "%.2f", avgPlanGeneration * 1000)) ms
                Average Session Generation: \(String(format: "%.2f", avgSessionGeneration * 1000)) ms
                Average Scheduling:         \(String(format: "%.2f", avgScheduling * 1000)) ms
                Total Average:              \(String(format: "%.2f", totalAverage * 1000)) ms
                """
            }
        }
    }
#endif
