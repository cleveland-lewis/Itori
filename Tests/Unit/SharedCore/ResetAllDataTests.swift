import XCTest
@testable import Roots

final class ResetAllDataTests: XCTestCase {
    @MainActor
    func testAssignmentsResetIsIdempotent() {
        let store = AssignmentsStore.shared
        let task = AppTask(
            id: UUID(),
            title: "Reset Test Task",
            courseId: nil,
            due: Date(),
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.5,
            importance: 0.5,
            type: .homework,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .homework
        )

        store.addTask(task)
        XCTAssertFalse(store.tasks.isEmpty)

        store.resetAll()
        XCTAssertTrue(store.tasks.isEmpty)

        store.resetAll()
        XCTAssertTrue(store.tasks.isEmpty)
    }
}
