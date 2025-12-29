import Foundation

// MARK: - Default Duration Estimator

public class DefaultDurationEstimator: EstimateTaskDurationPort {
    
    // Base estimates in minutes for each category
    private let categoryBaselines: [String: Int] = [
        "reading": 45,
        "homework": 60,
        "review": 30,
        "practice": 90,
        "project": 180,
        "exam": 120,
        "midterm": 120,
        "final": 180,
        "lab": 120,
        "essay": 240,
        "quiz": 20
    ]
    
    // Course type multipliers
    private let courseTypeMultipliers: [String: Double] = [
        "seminar": 1.2,
        "lecture": 1.0,
        "lab": 1.5,
        "studio": 1.8,
        "independent": 2.0,
        "online": 0.9
    ]
    
    public init() {}
    
    public func estimateDuration(
        category: String,
        courseType: String?,
        credits: Int?,
        dueDate: Date?,
        historicalData: [CompletionHistory]
    ) async -> DurationEstimate {
        
        var reasonCodes: [String] = []
        
        // 1. Start with category baseline
        let baseline = categoryBaselines[category.lowercased()] ?? 60
        reasonCodes.append("category=\(category)")
        
        // 2. Apply course type multiplier
        var multiplier = 1.0
        if let courseType = courseType?.lowercased() {
            multiplier = courseTypeMultipliers[courseType] ?? 1.0
            reasonCodes.append("courseType=\(courseType)")
        }
        
        // 3. Apply credit multiplier
        if let credits = credits {
            let creditMultiplier = Double(credits) / 3.0 // 3 credits is baseline
            multiplier *= creditMultiplier
            reasonCodes.append("credits=\(credits)")
        }
        
        // 4. Check historical data for this category
        let relevantHistory = historicalData.filter { $0.category.lowercased() == category.lowercased() }
        
        var estimatedMinutes: Int
        var confidence: Double
        
        if relevantHistory.count >= 3 {
            // Use historical average
            let avg = relevantHistory.map { $0.actualMinutes }.reduce(0, +) / relevantHistory.count
            estimatedMinutes = avg
            confidence = min(0.9, 0.5 + Double(relevantHistory.count) * 0.05)
            reasonCodes.append("historySampleSize=\(relevantHistory.count)")
        } else if relevantHistory.count > 0 {
            // Blend historical with baseline
            let avg = relevantHistory.map { $0.actualMinutes }.reduce(0, +) / relevantHistory.count
            let baselineAdjusted = Int(Double(baseline) * multiplier)
            estimatedMinutes = (avg + baselineAdjusted) / 2
            confidence = 0.6
            reasonCodes.append("historySampleSize=\(relevantHistory.count)")
            reasonCodes.append("blendedEstimate")
        } else {
            // Pure heuristic
            estimatedMinutes = Int(Double(baseline) * multiplier)
            confidence = 0.5
            reasonCodes.append("heuristicOnly")
        }
        
        // 5. Calculate range (±20%)
        let minMinutes = Int(Double(estimatedMinutes) * 0.8)
        let maxMinutes = Int(Double(estimatedMinutes) * 1.2)
        
        return DurationEstimate(
            estimatedMinutes: estimatedMinutes,
            minMinutes: minMinutes,
            maxMinutes: maxMinutes,
            confidence: confidence,
            reasonCodes: reasonCodes
        )
    }
}

// MARK: - Default Effort Profile Estimator

public class DefaultEffortProfileEstimator: EstimateEffortProfilePort {
    
    private let defaultProfiles: [String: (multiplier: Double, baseMinutes: Int)] = [
        "seminar": (1.2, 180), // 3 hours per week per credit
        "lecture": (1.0, 150),
        "lab": (1.5, 210),
        "studio": (1.8, 240),
        "independent": (2.0, 270),
        "online": (0.9, 135)
    ]
    
    // Store learned profiles per course
    private var learnedProfiles: [String: EffortProfile] = [:]
    
    public init() {}
    
    public func getEffortProfile(courseType: String, credits: Int) -> EffortProfile {
        let type = courseType.lowercased()
        let profile = defaultProfiles[type] ?? (1.0, 150)
        
        let adjustedMinutes = profile.baseMinutes * credits
        
        return EffortProfile(
            courseType: courseType,
            multiplier: profile.multiplier,
            baseMinutesPerCredit: profile.baseMinutes
        )
    }
    
    public func updateEffortProfile(courseId: String, actualMinutes: Int, category: String) {
        // Update learned profile based on actual completion time
        // This would persist to UserDefaults or Core Data in production
        if var existing = learnedProfiles[courseId] {
            let newBase = (existing.baseMinutesPerCredit + actualMinutes) / 2
            learnedProfiles[courseId] = EffortProfile(
                courseType: existing.courseType,
                multiplier: existing.multiplier,
                baseMinutesPerCredit: newBase
            )
        }
    }
}

// MARK: - Default Workload Forecast

public class DefaultWorkloadForecaster: WorkloadForecastPort {
    
    public init() {}
    
    public func generateForecast(
        assignments: [AssignmentSummary],
        startDate: Date,
        endDate: Date
    ) async -> WorkloadForecast {
        
        var weeklyLoads: [Date: (hours: Double, breakdown: [String: Double])] = [:]
        let calendar = Calendar.current
        
        // Group assignments by week
        for assignment in assignments {
            guard assignment.dueDate >= startDate && assignment.dueDate <= endDate else {
                continue
            }
            
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: assignment.dueDate)) ?? assignment.dueDate
            
            let hours = Double(assignment.estimatedMinutes) / 60.0
            
            if var existing = weeklyLoads[weekStart] {
                existing.hours += hours
                existing.breakdown[assignment.category, default: 0] += hours
                weeklyLoads[weekStart] = existing
            } else {
                weeklyLoads[weekStart] = (hours: hours, breakdown: [assignment.category: hours])
            }
        }
        
        // Convert to sorted array
        let sortedWeeks = weeklyLoads.keys.sorted()
        let weekLoads = sortedWeeks.map { weekStart in
            let data = weeklyLoads[weekStart]!
            return WeekLoad(
                weekStart: weekStart,
                hours: data.hours,
                breakdown: data.breakdown
            )
        }
        
        // Find peak week
        let peakWeek = weekLoads.max(by: { $0.hours < $1.hours })?.weekStart
        
        // Calculate total hours
        let totalHours = weekLoads.reduce(0.0) { $0 + $1.hours }
        
        return WorkloadForecast(
            weeklyLoad: weekLoads,
            peakWeek: peakWeek,
            totalHours: totalHours
        )
    }
}
