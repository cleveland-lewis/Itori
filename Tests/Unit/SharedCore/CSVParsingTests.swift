import XCTest
@testable import Itori

@MainActor
final class CSVParsingTests: XCTestCase {
    var parsingService: FileParsingService!
    var tempDir: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        parsingService = FileParsingService.shared
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        tempDir = nil
        try super.tearDownWithError()
    }

    func testCSVParsingBasicAssignments() async throws {
        // Given: A CSV file with basic assignment data
        let csvContent = """
        title,type,due,points
        Homework 1,homework,2026-01-15,10
        Midterm Exam,exam,2026-02-01,100
        Reading Assignment,reading,2026-01-20,5
        """

        let csvURL = tempDir.appendingPathComponent("assignments.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let courseFile = CourseFile(
            id: UUID(),
            courseId: UUID(),
            url: csvURL,
            displayName: "assignments.csv",
            addedAt: Date(),
            category: .syllabus
        )

        // When: Parsing the CSV file
        let results = try await parsingService.performParsing(for: courseFile)

        // Then: Should parse assignments and events correctly
        XCTAssertEqual(results.assignments.count, 2, "Should parse 2 assignments (homework and reading)")
        XCTAssertEqual(results.events.count, 1, "Should parse 1 event (exam)")

        // Verify homework
        let homework = results.assignments.first { $0.title == "Homework 1" }
        XCTAssertNotNil(homework)
        XCTAssertEqual(homework?.category, .homework)
        XCTAssertEqual(homework?.points, 10)
        XCTAssertNotNil(homework?.dueDate)

        // Verify exam
        let exam = results.events.first { $0.title == "Midterm Exam" }
        XCTAssertNotNil(exam)
        XCTAssertEqual(exam?.type, .exam)
        XCTAssertEqual(exam?.points, 100)
    }

    func testCSVParsingWithNotes() async throws {
        // Given: CSV with notes column
        let csvContent = """
        name,category,date,notes
        Project 1,project,2026-03-01,"Build a web app"
        Quiz 1,quiz,2026-01-25,"Covers chapters 1-3"
        """

        let csvURL = tempDir.appendingPathComponent("assignments_with_notes.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let courseFile = CourseFile(
            id: UUID(),
            courseId: UUID(),
            url: csvURL,
            displayName: "assignments_with_notes.csv",
            addedAt: Date(),
            category: .syllabus
        )

        // When
        let results = try await parsingService.performParsing(for: courseFile)

        // Then
        XCTAssertEqual(results.assignments.count, 1)
        XCTAssertEqual(results.events.count, 1)

        let project = results.assignments.first
        XCTAssertEqual(project?.title, "Project 1")
        XCTAssertEqual(project?.notes, "Build a web app")
        XCTAssertEqual(project?.category, .project)

        let quiz = results.events.first
        XCTAssertEqual(quiz?.title, "Quiz 1")
        XCTAssertEqual(quiz?.type, .quiz)
    }

    func testCSVParsingAlternativeHeaders() async throws {
        // Given: CSV with alternative column names
        let csvContent = """
        assignment,type,duedate,weight
        Essay 1,homework,01/30/2026,15
        Final Exam,exam,05/15/2026,200
        """

        let csvURL = tempDir.appendingPathComponent("alternative_headers.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let courseFile = CourseFile(
            id: UUID(),
            courseId: UUID(),
            url: csvURL,
            displayName: "alternative_headers.csv",
            addedAt: Date(),
            category: .syllabus
        )

        // When
        let results = try await parsingService.performParsing(for: courseFile)

        // Then
        XCTAssertEqual(results.assignments.count, 1)
        XCTAssertEqual(results.events.count, 1)

        let essay = results.assignments.first
        XCTAssertEqual(essay?.title, "Essay 1")
        XCTAssertEqual(essay?.points, 15)

        let finalExam = results.events.first
        XCTAssertEqual(finalExam?.title, "Final Exam")
        XCTAssertEqual(finalExam?.points, 200)
    }

    func testCSVParsingHandlesEmptyRows() async throws {
        // Given: CSV with empty rows
        let csvContent = """
        title,type,due
        Homework 1,homework,2026-01-15

        Homework 2,homework,2026-01-20

        """

        let csvURL = tempDir.appendingPathComponent("empty_rows.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let courseFile = CourseFile(
            id: UUID(),
            courseId: UUID(),
            url: csvURL,
            displayName: "empty_rows.csv",
            addedAt: Date(),
            category: .syllabus
        )

        // When
        let results = try await parsingService.performParsing(for: courseFile)

        // Then: Should only parse non-empty rows
        XCTAssertEqual(results.assignments.count, 2)
    }

    func testCSVParsingDateFormats() async throws {
        // Given: CSV with various date formats
        let csvContent = """
        title,type,due
        Assignment 1,homework,2026-01-15
        Assignment 2,homework,01/20/2026
        Assignment 3,homework,1-25-2026
        Assignment 4,homework,1/30/2026
        """

        let csvURL = tempDir.appendingPathComponent("date_formats.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let courseFile = CourseFile(
            id: UUID(),
            courseId: UUID(),
            url: csvURL,
            displayName: "date_formats.csv",
            addedAt: Date(),
            category: .syllabus
        )

        // When
        let results = try await parsingService.performParsing(for: courseFile)

        // Then: Should parse all date formats
        XCTAssertEqual(results.assignments.count, 4)
        for assignment in results.assignments {
            XCTAssertNotNil(assignment.dueDate, "Date should be parsed for \(assignment.title)")
        }
    }

    func testCSVParsingQuotedValues() async throws {
        // Given: CSV with quoted values containing commas
        let csvContent = """
        title,type,due,notes
        "Project: Final Design",project,2026-04-01,"Create mockups, implement design"
        "Homework 5: Ch 3, 4",homework,2026-02-15,"Read chapters 3, 4 and answer questions"
        """

        let csvURL = tempDir.appendingPathComponent("quoted_values.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let courseFile = CourseFile(
            id: UUID(),
            courseId: UUID(),
            url: csvURL,
            displayName: "quoted_values.csv",
            addedAt: Date(),
            category: .syllabus
        )

        // When
        let results = try await parsingService.performParsing(for: courseFile)

        // Then: Should handle quoted values correctly
        XCTAssertEqual(results.assignments.count, 2)

        let project = results.assignments.first { $0.title.contains("Final Design") }
        XCTAssertNotNil(project)
        XCTAssertTrue(project!.notes?.contains("mockups") ?? false)

        let homework = results.assignments.first { $0.title.contains("Ch 3") }
        XCTAssertNotNil(homework)
        XCTAssertTrue(homework!.notes?.contains("chapters 3, 4") ?? false)
    }
}
