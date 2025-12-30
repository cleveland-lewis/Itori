import Foundation

struct PlannerTaskDTO: Hashable {
    let id: UUID
    let title: String
    let courseId: UUID?
    let dueDate: Date?
    let estimatedMinutes: Int
    let category: AssignmentCategory
    let importance: AssignmentUrgency
    let difficulty: AssignmentUrgency
    let isLockedToDueDate: Bool
    let isCompleted: Bool
}
