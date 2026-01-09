//
//  DragDropHandlerTests.swift
//  ItoriTests
//

import XCTest
@testable import Itori

@MainActor
final class DragDropHandlerTests: XCTestCase {
    func testReassignAssignmentUpdatesCourse() {
        let store = MockAssignmentStore()
        let assignment = AppTask(
            id: UUID(),
            title: "Research essay",
            courseId: nil,
            due: nil,
            estimatedMinutes: 45,
            minBlockMinutes: 15,
            maxBlockMinutes: 45,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .homework
        )
        store.tasks = [assignment]
        let payload = TransferableAssignment(from: assignment)
        let targetCourse = UUID()

        let result = DragDropHandler.reassignAssignment(payload, to: targetCourse, assignmentsStore: store)

        XCTAssertTrue(result)
        XCTAssertEqual(store.tasks.first?.courseId, targetCourse)
    }

    func testScheduleAssignmentOpensPlannerForDueDate() {
        let coordinator = PlannerCoordinator.shared
        let dueDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let assignment = AppTask(
            id: UUID(),
            title: "Group presentation",
            courseId: nil,
            due: dueDate,
            estimatedMinutes: 90,
            minBlockMinutes: 30,
            maxBlockMinutes: 60,
            difficulty: 0.6,
            importance: 0.7,
            type: .project,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .project
        )
        let payload = TransferableAssignment(from: assignment)

        let scheduledDate = DragDropHandler.scheduleAssignment(payload, plannerCoordinator: coordinator)

        XCTAssertEqual(scheduledDate, dueDate)
        XCTAssertNotNil(coordinator.requestedDate)
        XCTAssertEqual(coordinator.requestedDate, dueDate)
    }
}

private final class MockAssignmentStore: AssignmentTaskUpdating {
    var tasks: [AppTask] = []

    func updateTask(_ task: AppTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
}
