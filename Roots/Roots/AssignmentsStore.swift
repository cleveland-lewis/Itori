import Foundation
import Combine

final class AssignmentsStore: ObservableObject {
    static let shared = AssignmentsStore()
    private init() {}

    @Published var tasks: [Task] = []

    // No sample data - provided methods to add/remove tasks programmatically
    func addTask(_ task: Task) {
        tasks.append(task)
    }

    func removeTask(id: UUID) {
        tasks.removeAll { $0.id == id }
    }

    func updateTask(_ task: Task) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        }
    }

    func incompleteTasks() -> [Task] {
        // For now all tasks are considered active; in future, filter by completion state
        return tasks
    }
}