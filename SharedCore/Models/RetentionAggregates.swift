import Foundation

struct AggregateKey: Hashable, Codable {
    var semesterId: UUID?
    var courseId: UUID?
    var activityId: UUID?
    var bucket: AggregateBucket
    var bucketStart: Date
}

enum AggregateBucket: String, Codable, CaseIterable {
    case day
    case week
    case month
}

struct AssignmentAggregateMetrics: Codable {
    var completedCount: Int = 0
    var onTimeCount: Int = 0
}

struct GradeAggregateMetrics: Codable {
    var percentages: [Double] = []
}

struct CalendarAggregateMetrics: Codable {
    var eventCount: Int = 0
    var totalDurationSeconds: TimeInterval = 0
}

struct RetentionAggregates: Codable {
    var studyTime: [AggregateKey: TimeInterval] = [:]
    var assignmentMetrics: [AggregateKey: AssignmentAggregateMetrics] = [:]
    var gradeMetrics: [AggregateKey: GradeAggregateMetrics] = [:]
    var calendarMetrics: [AggregateKey: CalendarAggregateMetrics] = [:]
}
