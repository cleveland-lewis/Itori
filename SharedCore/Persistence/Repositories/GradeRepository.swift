internal import CoreData
import Foundation

final class GradeRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() -> [GradeEntry] {
        // Stub implementation - returns empty array
        []
    }

    func save(_: GradeEntry) throws {
        // Stub implementation
    }

    func delete(_: GradeEntry) throws {
        // Stub implementation
    }
}
