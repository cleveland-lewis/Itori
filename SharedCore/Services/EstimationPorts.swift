import Foundation

// MARK: - Estimation Result Models

public struct DurationEstimate: Codable, Equatable {
    public let estimatedMinutes: Int
    public let minMinutes: Int
    public let maxMinutes: Int
    public let confidence: Double // 0.0 to 1.0
    public let reasonCodes: [String]

    public init(
        estimatedMinutes: Int,
        minMinutes: Int,
        maxMinutes: Int,
        confidence: Double,
        reasonCodes: [String]
    ) {
        self.estimatedMinutes = estimatedMinutes
        self.minMinutes = minMinutes
        self.maxMinutes = maxMinutes
        self.confidence = confidence
        self.reasonCodes = reasonCodes
    }
}

public struct EffortProfile: Codable, Equatable {
    public let courseType: String
    public let multiplier: Double
    public let baseMinutesPerCredit: Int

    public init(courseType: String, multiplier: Double, baseMinutesPerCredit: Int) {
        self.courseType = courseType
        self.multiplier = multiplier
        self.baseMinutesPerCredit = baseMinutesPerCredit
    }
}

public struct WorkloadForecast: Codable, Equatable {
    public let weeklyLoad: [WeekLoad]
    public let peakWeek: Date?
    public let totalHours: Double

    public init(weeklyLoad: [WeekLoad], peakWeek: Date?, totalHours: Double) {
        self.weeklyLoad = weeklyLoad
        self.peakWeek = peakWeek
        self.totalHours = totalHours
    }
}

public struct WeekLoad: Codable, Equatable {
    public let weekStart: Date
    public let hours: Double
    public let breakdown: [String: Double] // category -> hours

    public init(weekStart: Date, hours: Double, breakdown: [String: Double]) {
        self.weekStart = weekStart
        self.hours = hours
        self.breakdown = breakdown
    }
}

// MARK: - Port Protocols

public protocol EstimateTaskDurationPort {
    func estimateDuration(
        category: String,
        courseType: String?,
        credits: Int?,
        dueDate: Date?,
        historicalData: [CompletionHistory]
    ) async -> DurationEstimate
}

public protocol EstimateEffortProfilePort {
    func getEffortProfile(courseType: String, credits: Int) -> EffortProfile
    func updateEffortProfile(courseId: String, actualMinutes: Int, category: String)
}

public protocol WorkloadForecastPort {
    func generateForecast(
        assignments: [AssignmentSummary],
        startDate: Date,
        endDate: Date
    ) async -> WorkloadForecast
}

// MARK: - Supporting Models

public struct CompletionHistory: Codable, Equatable {
    public let category: String
    public let actualMinutes: Int
    public let completedDate: Date
    public let courseId: String

    public init(category: String, actualMinutes: Int, completedDate: Date, courseId: String) {
        self.category = category
        self.actualMinutes = actualMinutes
        self.completedDate = completedDate
        self.courseId = courseId
    }
}

public struct AssignmentSummary: Codable, Equatable {
    public let id: String
    public let category: String
    public let courseId: String
    public let dueDate: Date
    public let estimatedMinutes: Int

    public init(id: String, category: String, courseId: String, dueDate: Date, estimatedMinutes: Int) {
        self.id = id
        self.category = category
        self.courseId = courseId
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
    }
}
