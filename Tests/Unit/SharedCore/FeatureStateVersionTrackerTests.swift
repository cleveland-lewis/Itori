import XCTest
@testable import SharedCore

final class FeatureStateVersionTrackerTests: XCTestCase {
    func testTitleEditDoesNotIncrementVersion() {
        var tracker = FeatureStateVersionTracker(version: 3)
        let changed = tracker.recordAssignmentChange(
            dueDateChanged: false,
            categoryChanged: false,
            titleChanged: true
        )

        XCTAssertFalse(changed)
        XCTAssertEqual(tracker.version, 3, "Title-only changes should not increment version")
    }

    func testDueDateChangeIncrementsVersion() {
        var tracker = FeatureStateVersionTracker(version: 1)
        let changed = tracker.recordAssignmentChange(
            dueDateChanged: true,
            categoryChanged: false,
            titleChanged: false
        )

        XCTAssertTrue(changed)
        XCTAssertEqual(tracker.version, 2, "Due date changes should increment version")
    }
}
