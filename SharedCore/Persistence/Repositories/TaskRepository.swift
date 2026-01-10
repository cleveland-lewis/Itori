internal import CoreData

final class TaskRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() -> [AppTask] {
        // Stub implementation - returns empty array
        []
    }

    func save(_: AppTask) throws {
        // Stub implementation
    }

    func delete(_: AppTask) throws {
        // Stub implementation
    }
}
