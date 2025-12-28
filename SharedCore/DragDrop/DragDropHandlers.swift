import Foundation

protocol AssignmentTaskUpdating: AnyObject {
    var tasks: [AppTask] { get }
    func updateTask(_ task: AppTask)
}

extension AssignmentsStore: AssignmentTaskUpdating {}

struct DragDropHandler {
    /// Reassigns the task described by the payload to a new course, returning `true` when the update succeeds.
    static func reassignAssignment(_ payload: TransferableAssignment, to courseId: UUID, assignmentsStore: AssignmentTaskUpdating) -> Bool {
        guard let taskId = UUID(uuidString: payload.id),
              let task = assignmentsStore.tasks.first(where: { $0.id == taskId }) else {
            return false
        }
        let updated = task.withCourseId(courseId)
        assignmentsStore.updateTask(updated)
        return true
    }

    /// Opens the planner for the payload's due date (or today when missing) and returns the targeted date.
    static func scheduleAssignment(_ payload: TransferableAssignment, plannerCoordinator: PlannerCoordinator) -> Date {
        let date = payload.dueDate ?? Date()
        let courseUUID = payload.courseId.flatMap(UUID.init(uuidString:))
        plannerCoordinator.openPlanner(for: date, courseId: courseUUID)
        return date
    }
}
