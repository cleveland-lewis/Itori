import Foundation
import Combine

/// Central service for estimation - provides duration, effort, and workload forecasting
@MainActor
public class EstimationService: ObservableObject {
    
    public static let shared = EstimationService()
    
    private let durationEstimator: EstimateTaskDurationPort
    private let effortProfileEstimator: EstimateEffortProfilePort
    private let workloadForecaster: WorkloadForecastPort
    private var nextDefaultEstimates: [DefaultEstimateKey: Int] = [:]
    
    public init(
        durationEstimator: EstimateTaskDurationPort? = nil,
        effortProfileEstimator: EstimateEffortProfilePort? = nil,
        workloadForecaster: WorkloadForecastPort? = nil
    ) {
        self.durationEstimator = durationEstimator ?? DefaultDurationEstimator()
        self.effortProfileEstimator = effortProfileEstimator ?? DefaultEffortProfileEstimator()
        self.workloadForecaster = workloadForecaster ?? DefaultWorkloadForecaster()
    }
    
    // MARK: - Duration Estimation
    
    /// Estimates task duration based on category, course info, and historical data
    public func estimateTaskDuration(
        category: String,
        courseType: String? = nil,
        credits: Int? = nil,
        dueDate: Date? = nil,
        historicalData: [CompletionHistory] = []
    ) async -> DurationEstimate {
        return await durationEstimator.estimateDuration(
            category: category,
            courseType: courseType,
            credits: credits,
            dueDate: dueDate,
            historicalData: historicalData
        )
    }
    
    // MARK: - Effort Profile
    
    /// Gets the effort profile for a course type
    public func getEffortProfile(courseType: String, credits: Int) -> EffortProfile {
        return effortProfileEstimator.getEffortProfile(courseType: courseType, credits: credits)
    }
    
    /// Updates effort profile based on actual completion
    public func recordCompletion(courseId: String, actualMinutes: Int, category: String) {
        effortProfileEstimator.updateEffortProfile(courseId: courseId, actualMinutes: actualMinutes, category: category)
    }
    
    // MARK: - Workload Forecast
    
    /// Generates weekly workload forecast for given assignments
    public func generateWorkloadForecast(
        assignments: [AssignmentSummary],
        startDate: Date,
        endDate: Date
    ) async -> WorkloadForecast {
        return await workloadForecaster.generateForecast(
            assignments: assignments,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    // MARK: - Convenience Methods
    
    /// Auto-fills estimated minutes for an assignment based on category and course
    public func autoFillEstimate(
        category: String,
        courseType: String?,
        credits: Int?,
        dueDate: Date?,
        courseId: String? = nil
    ) async -> Int {
        if let cached = nextDefaultEstimate(category: category, courseType: courseType, credits: credits) {
            return cached
        }
        
        // Fetch historical data for this course if available
        var history: [CompletionHistory] = []
        if let courseId = courseId {
            history = await fetchCompletionHistory(courseId: courseId, category: category)
        }
        
        let estimate = await estimateTaskDuration(
            category: category,
            courseType: courseType,
            credits: credits,
            dueDate: dueDate,
            historicalData: history
        )
        
        return estimate.estimatedMinutes
    }
    
    public func storeNextDefaultEstimate(
        category: String,
        courseType: String?,
        credits: Int?,
        estimatedMinutes: Int
    ) {
        let key = DefaultEstimateKey(category: category, courseType: courseType, credits: credits)
        nextDefaultEstimates[key] = estimatedMinutes
    }
    
    public func nextDefaultEstimate(
        category: String,
        courseType: String?,
        credits: Int?
    ) -> Int? {
        let key = DefaultEstimateKey(category: category, courseType: courseType, credits: credits)
        return nextDefaultEstimates[key]
    }
    
    /// Fetches completion history from Core Data
    private func fetchCompletionHistory(courseId: String, category: String) async -> [CompletionHistory] {
        // TODO: Integrate with Core Data to fetch actual completion history
        // For now, return empty array (fallback to heuristics)
        return []
    }
}

private struct DefaultEstimateKey: Hashable {
    let category: String
    let courseType: String?
    let credits: Int?
}
