import XCTest
@testable import SharedCore

final class DragDropTests: XCTestCase {
    func testAssignmentDragPayloadEncodingRoundTrip() throws {
        let payload = AssignmentDragPayload(
            id: UUID(),
            title: "Review chapter 4",
            dueDate: Date(timeIntervalSince1970: 1_700_000_000),
            courseId: UUID()
        )

        let encoded = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(AssignmentDragPayload.self, from: encoded)

        XCTAssertEqual(decoded.id, payload.id)
        XCTAssertEqual(decoded.title, payload.title)
        XCTAssertEqual(decoded.courseId, payload.courseId)
        XCTAssertEqual(decoded.dueDate, payload.dueDate)
    }
}
