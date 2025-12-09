@testable import Roots
import EventKit
import XCTest

final class DiagnosticTests: XCTestCase {
    func testHealthCheckReportsNoIssuesInCleanState() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("diagnostic-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let tasksURL = tempDir.appendingPathComponent("tasks.json")
        let coursesURL = tempDir.appendingPathComponent("courses.json")

        try Data("[]".utf8).write(to: tasksURL)
        let emptyCourses: [String: Any?] = ["semesters": [], "courses": [], "currentSemesterId": nil]
        let courseData = try JSONSerialization.data(withJSONObject: emptyCourses.compactMapValues { $0 }, options: [])
        try courseData.write(to: coursesURL)

        let coursesStore = CoursesStore(storageURL: coursesURL)

        AssignmentsStore.shared.tasks = []
        let calendarManager = CalendarManager.shared
        calendarManager.isAuthorized = false

        let debugger = AppDebugger(
            dataManager: coursesStore,
            calendarManager: calendarManager,
            assignmentsStore: AssignmentsStore.shared,
            documentsDirectory: tempDir,
            tasksFileURL: tasksURL,
            coursesFileURL: coursesURL,
            authorizationStatusProvider: { (.notDetermined, .notDetermined) }
        )

        let report = debugger.runFullDiagnostic()
        if !report.issues.isEmpty {
            XCTFail(report.formattedSummary)
        }
    }
}
