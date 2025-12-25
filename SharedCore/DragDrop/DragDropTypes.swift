import Foundation
import UniformTypeIdentifiers

/// Represents the data we share when dragging an assignment.
struct AssignmentDragPayload: Codable {
    let id: UUID
    let title: String
    let dueDate: Date?
    let courseId: UUID?

    var fallbackDescription: String {
        if let due = dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(title) • due \(formatter.string(from: due))"
        }
        return title
    }

    static func load(from providers: [NSItemProvider], completion: @escaping (AssignmentDragPayload) -> Void) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(DragDropType.assignment.identifier) }) else {
            return false
        }

        provider.loadDataRepresentation(forTypeIdentifier: DragDropType.assignment.identifier) { data, error in
            guard let data else { return }
            if let payload = try? JSONDecoder().decode(AssignmentDragPayload.self, from: data) {
                DispatchQueue.main.async {
                    completion(payload)
                }
            }
        }
        return true
    }
}

enum DragDropType {
    static let assignment = UTType(exportedAs: "com.roots.assignment")
}

extension AppTask {
    func itemProvider() -> NSItemProvider {
        let payload = AssignmentDragPayload(id: id, title: title, dueDate: due, courseId: courseId)
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: DragDropType.assignment.identifier, visibility: .all) { completion in
            completion(try? JSONEncoder().encode(payload), nil)
            return nil
        }
        provider.registerObject(payload.fallbackDescription as NSString, visibility: .all) { _ in }
        return provider
    }
}
