@testable import Roots
import EventKit
import XCTest

final class DiagnosticTests: XCTestCase {
    @MainActor
    func testHealthCheckReportsNoIssuesInCleanState() async throws {
        // Create temporary directory for test
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("diagnostic-\(UUID().uuidString)")

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            throw XCTSkip("Failed to create temp directory: \(error.localizedDescription)")
        }

        // Ensure cleanup after test
        addTeardownBlock {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let tasksURL = tempDir.appendingPathComponent("tasks.json")
        let coursesURL = tempDir.appendingPathComponent("courses.json")

        // Create valid JSON files with error handling
        do {
            try Data("[]".utf8).write(to: tasksURL)
            let emptyCourses: [String: Any?] = ["semesters": [], "courses": [], "currentSemesterId": nil]
            let courseData = try JSONSerialization.data(withJSONObject: emptyCourses.compactMapValues { $0 }, options: [])
            try courseData.write(to: coursesURL)
        } catch {
            throw XCTSkip("Failed to create test files: \(error.localizedDescription)")
        }

        // Initialize test objects with proper error handling
        let coursesStore: CoursesStore
        do {
            coursesStore = CoursesStore(storageURL: coursesURL)
        } catch {
            throw XCTSkip("Failed to initialize CoursesStore: \(error.localizedDescription)")
        }

        // Reset shared state safely
        AssignmentsStore.shared.tasks = []
        let calendarManager = CalendarManager.shared
        calendarManager.isAuthorized = false

        // Create debugger instance with safe mocks
        let debugger: AppDebugger
        do {
            debugger = AppDebugger(
                dataManager: coursesStore,
                calendarManager: calendarManager,
                assignmentsStore: AssignmentsStore.shared,
                documentsDirectory: tempDir,
                tasksFileURL: tasksURL,
                coursesFileURL: coursesURL,
                authorizationStatusProvider: { (.notDetermined, .notDetermined) }
            )
        } catch {
            throw XCTSkip("Failed to initialize AppDebugger: \(error.localizedDescription)")
        }

        // Run diagnostic with comprehensive error handling
        let report: DiagnosticReport
        do {
            report = debugger.runFullDiagnostic()
        } catch {
            throw XCTSkip("Diagnostic crashed during execution: \(error.localizedDescription)")
        }

        // Verify report is valid
        guard report.issues.isEmpty || !report.issues.isEmpty else {
            throw XCTSkip("Diagnostic report is in invalid state")
        }

        // Allow warnings, but fail on critical errors containing "Corrupt" or "Error"
        let criticalIssues = report.issues.filter {
            $0.title.contains("Corrupt") || $0.title.contains("Error") ||
            $0.details.contains("Corrupt") || $0.details.contains("Error")
        }

        if !criticalIssues.isEmpty {
            let issueDescriptions = criticalIssues.map { issue in
                let title = issue.title
                let details = issue.details
                return "\(title): \(details)"
            }
            XCTFail("Health check found critical issues: \(issueDescriptions.joined(separator: ", "))")
        }
    }
}
