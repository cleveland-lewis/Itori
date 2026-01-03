import Foundation

/// Converts between Assignment (UI model) and AppTask (persistent model)
struct AssignmentConverter {
    
    /// Convert Assignment to AppTask for persistence
    static func toAppTask(_ assignment: Assignment) -> AppTask {
        let taskType = taskTypeFromCategory(assignment.category)
        let importance = importanceFromUrgency(assignment.urgency)
        
        return AppTask(
            id: assignment.id,
            title: assignment.title,
            courseId: assignment.courseId,
            due: assignment.dueDate,
            estimatedMinutes: assignment.estimatedMinutes,
            minBlockMinutes: 20,
            maxBlockMinutes: min(assignment.estimatedMinutes, 180),
            difficulty: assignment.plannerDifficulty,
            importance: importance,
            type: taskType,
            locked: assignment.isLockedToDueDate,
            attachments: [],
            isCompleted: assignment.status == .completed,
            gradeWeightPercent: assignment.weightPercent,
            gradePossiblePoints: nil,
            gradeEarnedPoints: nil,
            category: taskType,
            dueTimeMinutes: assignment.dueTimeMinutes
        )
    }
    
    /// Convert AppTask to Assignment for UI
    static func toAssignment(_ task: AppTask, coursesStore: CoursesStore) -> Assignment {
        let category = categoryFromTaskType(task.category)
        let urgency = urgencyFromImportance(task.importance)
        let status = task.isCompleted ? AssignmentStatus.completed : AssignmentStatus.notStarted
        
        // Get course info if available
        let course = task.courseId.flatMap { courseId in 
            coursesStore.courses.first(where: { $0.id == courseId })
        }
        
        return Assignment(
            id: task.id,
            courseId: task.courseId,
            title: task.title,
            dueDate: task.due ?? Date(),
            dueTimeMinutes: task.dueTimeMinutes,
            estimatedMinutes: task.estimatedMinutes,
            weightPercent: task.gradeWeightPercent,
            category: category,
            urgency: urgency,
            isLockedToDueDate: task.locked,
            plan: [],
            status: status,
            courseCode: course?.code,
            courseName: course?.title,
            notes: nil
        )
    }
    
    // MARK: - Helpers
    
    private static func taskTypeFromCategory(_ category: AssignmentCategory) -> TaskType {
        switch category {
        case .reading: return .reading
        case .exam: return .exam
        case .homework: return .homework
        case .quiz: return .quiz
        case .review: return .review
        case .project: return .project
        }
    }
    
    private static func categoryFromTaskType(_ type: TaskType) -> AssignmentCategory {
        switch type {
        case .reading: return .reading
        case .exam: return .exam
        case .homework: return .homework
        case .quiz: return .quiz
        case .review: return .review
        case .project: return .project
        case .study: return .review
        }
    }
    
    private static func importanceFromUrgency(_ urgency: AssignmentUrgency) -> Double {
        switch urgency {
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .critical: return 1.0
        }
    }
    
    private static func urgencyFromImportance(_ importance: Double) -> AssignmentUrgency {
        switch importance {
        case ..<0.3: return .low
        case ..<0.6: return .medium
        case ..<0.85: return .high
        default: return .critical
        }
    }
}
