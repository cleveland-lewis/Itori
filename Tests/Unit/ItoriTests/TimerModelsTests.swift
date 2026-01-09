//
//  TimerModelsTests.swift
//  ItoriTests
//
//  Tests for TimerModels - Timer mode, activities, and categories
//

import XCTest
@testable import Itori

@MainActor
final class TimerModelsTests: BaseTestCase {
    // MARK: - TimerMode Tests

    func testTimerModeAllCases() {
        XCTAssertEqual(TimerMode.allCases.count, 4)
        XCTAssertTrue(TimerMode.allCases.contains(.pomodoro))
        XCTAssertTrue(TimerMode.allCases.contains(.timer))
        XCTAssertTrue(TimerMode.allCases.contains(.stopwatch))
        XCTAssertTrue(TimerMode.allCases.contains(.focus))
    }

    func testTimerModeDisplayNames() {
        XCTAssertEqual(TimerMode.pomodoro.displayName, "Pomodoro")
        XCTAssertEqual(TimerMode.timer.displayName, "Timer")
        XCTAssertEqual(TimerMode.stopwatch.displayName, "Stopwatch")
        XCTAssertEqual(TimerMode.focus.displayName, "Focus")
    }

    func testTimerModeSystemImages() {
        XCTAssertEqual(TimerMode.pomodoro.systemImage, "hourglass")
        XCTAssertEqual(TimerMode.timer.systemImage, "timer")
        XCTAssertEqual(TimerMode.stopwatch.systemImage, "stopwatch")
        XCTAssertEqual(TimerMode.focus.systemImage, "brain.head.profile")
    }

    func testTimerModeDefaultDurations() {
        XCTAssertEqual(TimerMode.pomodoro.defaultDuration, 25 * 60)
        XCTAssertEqual(TimerMode.timer.defaultDuration, 10 * 60)
        XCTAssertNil(TimerMode.stopwatch.defaultDuration)
        XCTAssertNil(TimerMode.focus.defaultDuration)
    }

    func testTimerModeCodable() throws {
        let mode = TimerMode.pomodoro
        let encoder = JSONEncoder()
        let data = try encoder.encode(mode)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerMode.self, from: data)
        XCTAssertEqual(decoded, mode)
    }

    // MARK: - TimerDisplayStyle Tests

    func testTimerDisplayStyleAllCases() {
        XCTAssertEqual(TimerDisplayStyle.allCases.count, 2)
        XCTAssertTrue(TimerDisplayStyle.allCases.contains(.digital))
        XCTAssertTrue(TimerDisplayStyle.allCases.contains(.analog))
    }

    // MARK: - TimerActivity Tests

    func testTimerActivityInitialization() {
        let activity = TimerActivity(
            id: UUID(),
            name: "Study Math",
            note: "Chapter 5",
            courseID: UUID(),
            assignmentID: UUID(),
            studyCategory: .problemSolving,
            colorHex: "#FF0000",
            emoji: "📚",
            isPinned: true
        )

        XCTAssertEqual(activity.name, "Study Math")
        XCTAssertEqual(activity.note, "Chapter 5")
        XCTAssertNotNil(activity.courseID)
        XCTAssertNotNil(activity.assignmentID)
        XCTAssertEqual(activity.studyCategory, .problemSolving)
        XCTAssertEqual(activity.colorHex, "#FF0000")
        XCTAssertEqual(activity.emoji, "📚")
        XCTAssertTrue(activity.isPinned)
    }

    func testTimerActivityMinimalInit() {
        let activity = TimerActivity(name: "Quick Task")

        XCTAssertEqual(activity.name, "Quick Task")
        XCTAssertNil(activity.note)
        XCTAssertNil(activity.courseID)
        XCTAssertNil(activity.assignmentID)
        XCTAssertNil(activity.studyCategory)
        XCTAssertFalse(activity.isPinned)
    }

    func testTimerActivityCodable() throws {
        let activity = TimerActivity(
            name: "Test Activity",
            studyCategory: .reading,
            isPinned: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(activity)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerActivity.self, from: data)

        XCTAssertEqual(decoded.id, activity.id)
        XCTAssertEqual(decoded.name, activity.name)
        XCTAssertEqual(decoded.studyCategory, activity.studyCategory)
        XCTAssertEqual(decoded.isPinned, activity.isPinned)
    }

    func testTimerActivityHashable() {
        let id = UUID()
        let activity1 = TimerActivity(id: id, name: "Test")
        let activity2 = TimerActivity(id: id, name: "Test")

        XCTAssertEqual(activity1, activity2)
        XCTAssertEqual(activity1.hashValue, activity2.hashValue)
    }

    // MARK: - StudyCategory Tests

    func testStudyCategoryAllCases() {
        XCTAssertEqual(StudyCategory.allCases.count, 5)
        XCTAssertTrue(StudyCategory.allCases.contains(.reading))
        XCTAssertTrue(StudyCategory.allCases.contains(.problemSolving))
        XCTAssertTrue(StudyCategory.allCases.contains(.reviewing))
        XCTAssertTrue(StudyCategory.allCases.contains(.writing))
        XCTAssertTrue(StudyCategory.allCases.contains(.admin))
    }

    func testStudyCategoryDisplayNames() {
        XCTAssertEqual(StudyCategory.reading.displayName, "Reading")
        XCTAssertEqual(StudyCategory.problemSolving.displayName, "Problemsolving")
        XCTAssertEqual(StudyCategory.reviewing.displayName, "Reviewing")
        XCTAssertEqual(StudyCategory.writing.displayName, "Writing")
        XCTAssertEqual(StudyCategory.admin.displayName, "Admin")
    }

    // MARK: - Edge Cases

    func testTimerActivityEmptyName() {
        let activity = TimerActivity(name: "")
        XCTAssertEqual(activity.name, "")
    }

    func testTimerActivityLongName() {
        let longName = String(repeating: "a", count: 500)
        let activity = TimerActivity(name: longName)
        XCTAssertEqual(activity.name.count, 500)
    }

    func testTimerActivityWithAllOptionalFields() {
        let activity = TimerActivity(
            name: "Complete Task",
            note: "Notes",
            courseID: UUID(),
            assignmentID: UUID(),
            studyCategory: .admin,
            collectionID: UUID(),
            colorHex: "#00FF00",
            emoji: "🎯",
            isPinned: false
        )

        XCTAssertNotNil(activity.note)
        XCTAssertNotNil(activity.courseID)
        XCTAssertNotNil(activity.assignmentID)
        XCTAssertNotNil(activity.studyCategory)
        XCTAssertNotNil(activity.collectionID)
        XCTAssertNotNil(activity.colorHex)
        XCTAssertNotNil(activity.emoji)
    }
}
