import Foundation

/// Provides smart duration estimates based on category, course type, and learning data
struct DurationEstimator {
    
    /// Get estimated duration for an assignment
    static func estimatedDuration(
        category: AssignmentCategory,
        course: Course,
        learningData: [String: CategoryLearningData]
    ) -> Int {
        // Check for learned data first
        let key = learningKey(courseId: course.id, category: category)
        if let learned = learningData[key], learned.hasEnoughData {
            return Int(learned.averageMinutes.rounded())
        }
        
        // Otherwise use base × multiplier
        let base = category.baseEstimateMinutes
        let multiplier = course.courseType.durationMultiplier(for: category)
        let estimated = Double(base) * multiplier
        
        // Round to step size
        let stepSize = category.stepSize
        return Int((estimated / Double(stepSize)).rounded()) * stepSize
    }
    
    /// Get decomposition hint text
    static func decompositionHint(
        category: AssignmentCategory,
        estimatedMinutes: Int,
        dueDate: Date
    ) -> String {
        let now = Date()
        let daysUntilDue = Calendar.current.dateComponents([.day], from: now, to: dueDate).day ?? 0
        
        switch category {
        case .reading:
            return "Typically: 1 × \(estimatedMinutes)m same day"
            
        case .homework:
            return "Typically: 2 × \(estimatedMinutes)m over 2 days"
            
        case .review:
            if daysUntilDue >= 7 {
                let sessionTime = estimatedMinutes / 3
                return "Typically: 3 × \(sessionTime)m spaced (today +2d +5d)"
            } else {
                return "Typically: 2 × \(estimatedMinutes / 2)m over \(min(daysUntilDue, 2)) days"
            }
            
        case .project:
            if daysUntilDue >= 14 {
                let sessionTime = estimatedMinutes / 4
                return "Typically: 4 × \(sessionTime)m across weeks"
            } else {
                let sessions = max(2, daysUntilDue / 3)
                let sessionTime = estimatedMinutes / sessions
                return "Typically: \(sessions) × \(sessionTime)m compressed"
            }
            
        case .exam:
            if daysUntilDue >= 10 {
                let sessionTime = estimatedMinutes / 5
                return "Typically: 5 × \(sessionTime)m spaced, last within 24h of due"
            } else {
                let sessions = max(3, daysUntilDue / 2)
                let sessionTime = estimatedMinutes / sessions
                return "Typically: \(sessions) × \(sessionTime)m compressed"
            }
            
        case .quiz:
            return "Typically: 1 × \(estimatedMinutes)m within 24h of due"
        case .practiceTest:
            return "Typically: 1 × \(estimatedMinutes)m scheduled in the week before"
        }
    }
    
    /// Generate learning data key
    static func learningKey(courseId: UUID, category: AssignmentCategory) -> String {
        "\(courseId.uuidString)_\(category.rawValue)"
    }
}

/// Stores learning data for a specific course+category combination
struct CategoryLearningData: Codable {
    let courseId: UUID
    let category: AssignmentCategory
    var completedCount: Int = 0
    var averageMinutes: Double = 0
    
    /// EWMA (Exponentially Weighted Moving Average)
    mutating func record(actualMinutes: Int) {
        let alpha = 0.3 // Weight for new data
        if completedCount == 0 {
            averageMinutes = Double(actualMinutes)
        } else {
            averageMinutes = alpha * Double(actualMinutes) + (1 - alpha) * averageMinutes
        }
        completedCount += 1
    }
    
    var hasEnoughData: Bool {
        completedCount >= 3
    }
}

// MARK: - AssignmentCategory Extensions
extension AssignmentCategory {
    /// Base estimate in minutes for first session
    var baseEstimateMinutes: Int {
        switch self {
        case .reading: return 45
        case .homework: return 75
        case .review: return 60
        case .project: return 120
        case .exam: return 180
        case .quiz: return 30
        case .practiceTest: return 50
        }
    }
    
    /// Step size for duration picker
    var stepSize: Int {
        switch self {
        case .reading, .review, .quiz: return 5
        case .homework: return 10
        case .project, .exam: return 15
        case .practiceTest: return 10
        }
    }
}

// MARK: - CourseType Extensions
extension CourseType {
    /// Get duration multiplier for a specific category
    func durationMultiplier(for category: AssignmentCategory) -> Double {
        let multipliers = durationMultipliers
        return multipliers[category] ?? 1.0
    }
    
    /// All multipliers for this course type
    var durationMultipliers: [AssignmentCategory: Double] {
        switch self {
        case .regular:
            return [:] // All 1.0
            
        case .honors, .ap, .ib:
            return [
                .reading: 1.2,
                .homework: 1.2,
                .review: 1.2,
                .project: 1.2,
                .exam: 1.2,
                .quiz: 1.2,
                .practiceTest: 1.2
            ]
            
        case .seminar:
            return [
                .reading: 1.4,
                .homework: 0.9,
                .review: 1.2,
                .project: 1.2,
                .exam: 1.0,
                .quiz: 1.0,
                .practiceTest: 1.0
            ]
            
        case .lab:
            return [
                .reading: 0.9,
                .homework: 1.1,
                .review: 1.0,
                .project: 1.2,
                .exam: 1.0,
                .quiz: 1.0,
                .practiceTest: 1.0
            ]
            
        default:
            return [:]
        }
    }
}
