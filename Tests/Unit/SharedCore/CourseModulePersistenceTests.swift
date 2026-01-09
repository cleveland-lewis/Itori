import XCTest
@testable import SharedCore

final class CourseModulePersistenceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var repository: CourseModuleRepository!
    var courseId: UUID!

    override func setUp() async throws {
        try await super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        repository = CourseModuleRepository(persistenceController: persistenceController)
        courseId = UUID()
    }

    override func tearDown() async throws {
        repository = nil
        persistenceController = nil
        try await super.tearDown()
    }

    // MARK: - Module Tests

    func testCreateModule() async throws {
        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: "Week 1"
        )

        XCTAssertEqual(module.title, "Week 1")
        XCTAssertEqual(module.courseId, courseId)
        XCTAssertEqual(module.type, .module)
        XCTAssertNil(module.parentId)
    }

    func testCreateNestedModule() async throws {
        let parent = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: "Parent Module"
        )

        let child = try await repository.createModule(
            courseId: courseId,
            parentId: parent.id,
            type: .section,
            title: "Child Section"
        )

        XCTAssertEqual(child.parentId, parent.id)
        XCTAssertEqual(child.type, .section)
    }

    func testFetchModules() async throws {
        _ = try await repository.createModule(courseId: courseId, type: .module, title: "Module 1")
        _ = try await repository.createModule(courseId: courseId, type: .module, title: "Module 2")
        _ = try await repository.createModule(courseId: courseId, type: .module, title: "Module 3")

        let modules = try await repository.fetchModules(for: courseId)

        XCTAssertEqual(modules.count, 3)
        XCTAssertTrue(modules.contains { $0.title == "Module 1" })
        XCTAssertTrue(modules.contains { $0.title == "Module 2" })
        XCTAssertTrue(modules.contains { $0.title == "Module 3" })
    }

    func testUpdateModule() async throws {
        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: "Original Title"
        )

        try await repository.updateModule(
            id: module.id,
            title: "Updated Title",
            sortIndex: 5
        )

        let modules = try await repository.fetchModules(for: courseId)
        let updated = modules.first { $0.id == module.id }

        XCTAssertEqual(updated?.title, "Updated Title")
        XCTAssertEqual(updated?.sortIndex, 5)
    }

    func testDeleteModule() async throws {
        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: "To Delete"
        )

        try await repository.deleteModule(id: module.id)

        let modules = try await repository.fetchModules(for: courseId)
        XCTAssertEqual(modules.count, 0)
    }

    func testModuleSortOrder() async throws {
        _ = try await repository.createModule(courseId: courseId, type: .module, title: "Third", sortIndex: 2)
        _ = try await repository.createModule(courseId: courseId, type: .module, title: "First", sortIndex: 0)
        _ = try await repository.createModule(courseId: courseId, type: .module, title: "Second", sortIndex: 1)

        let modules = try await repository.fetchModules(for: courseId)

        XCTAssertEqual(modules[0].title, "First")
        XCTAssertEqual(modules[1].title, "Second")
        XCTAssertEqual(modules[2].title, "Third")
    }

    // MARK: - File Tests

    func testAddFile() async throws {
        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: "test.pdf",
            fileType: "pdf",
            localURL: "/tmp/test.pdf",
            isSyllabus: true
        )

        XCTAssertEqual(file.filename, "test.pdf")
        XCTAssertEqual(file.fileType, "pdf")
        XCTAssertEqual(file.courseId, courseId)
        XCTAssertTrue(file.isSyllabus)
    }

    func testAddFileToModule() async throws {
        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: "Module with Files"
        )

        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: module.id,
            fileName: "lecture_notes.pdf",
            fileType: "pdf",
            localURL: "/tmp/lecture_notes.pdf"
        )

        XCTAssertEqual(file.nodeId, module.id)
    }

    func testFetchFilesForModule() async throws {
        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: "Test Module"
        )

        _ = try await repository.addFile(
            courseId: courseId,
            nodeId: module.id,
            fileName: "file1.pdf",
            fileType: "pdf",
            localURL: nil
        )
        _ = try await repository.addFile(
            courseId: courseId,
            nodeId: module.id,
            fileName: "file2.pdf",
            fileType: "pdf",
            localURL: nil
        )

        let files = try await repository.fetchFiles(courseId: courseId, nodeId: module.id)

        XCTAssertEqual(files.count, 2)
    }

    func testFetchCourseLevelFiles() async throws {
        _ = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: "syllabus.pdf",
            fileType: "pdf",
            localURL: nil,
            isSyllabus: true
        )
        _ = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: "schedule.pdf",
            fileType: "pdf",
            localURL: nil
        )

        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)

        XCTAssertEqual(files.count, 2)
        XCTAssertTrue(files.contains { $0.isSyllabus })
    }

    func testUpdateFileParse() async throws {
        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: "test.pdf",
            fileType: "pdf",
            localURL: nil
        )

        try await repository.updateFileParse(
            id: file.id,
            parseStatus: .parsed,
            parseError: nil
        )

        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        let updated = files.first { $0.id == file.id }

        XCTAssertEqual(updated?.parseStatus, .parsed)
        XCTAssertNotNil(updated?.parsedAt)
    }

    func testUpdateFileParseError() async throws {
        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: "test.pdf",
            fileType: "pdf",
            localURL: nil
        )

        try await repository.updateFileParse(
            id: file.id,
            parseStatus: .failed,
            parseError: "Invalid format"
        )

        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        let updated = files.first { $0.id == file.id }

        XCTAssertEqual(updated?.parseStatus, .failed)
        XCTAssertEqual(updated?.parseError, "Invalid format")
    }

    func testDeleteFile() async throws {
        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: "test.pdf",
            fileType: "pdf",
            localURL: nil
        )

        try await repository.deleteFile(id: file.id)

        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        XCTAssertEqual(files.count, 0)
    }

    func testCascadeDeleteModuleWithFiles() async throws {
        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: "Module with Files"
        )

        _ = try await repository.addFile(
            courseId: courseId,
            nodeId: module.id,
            fileName: "file1.pdf",
            fileType: "pdf",
            localURL: nil
        )
        _ = try await repository.addFile(
            courseId: courseId,
            nodeId: module.id,
            fileName: "file2.pdf",
            fileType: "pdf",
            localURL: nil
        )

        try await repository.deleteModule(id: module.id)

        // Files should be cascade deleted
        let files = try await repository.fetchFiles(courseId: courseId, nodeId: module.id)
        XCTAssertEqual(files.count, 0)
    }

    // MARK: - Parse Result Tests

    func testSaveParseResult() async throws {
        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: "test.pdf",
            fileType: "pdf",
            localURL: nil
        )

        try await repository.saveParseResult(
            fileId: file.id,
            parseType: "text_extraction",
            success: true,
            extractedText: "Sample extracted text",
            contentJSON: "{\"pages\": 5}",
            errorMessage: nil
        )

        // Parse result should be saved (tested via fetch if needed)
    }

    // MARK: - Multiple Course Isolation Tests

    func testModulesIsolatedByCourse() async throws {
        let course1 = UUID()
        let course2 = UUID()

        _ = try await repository.createModule(courseId: course1, type: .module, title: "Course 1 Module")
        _ = try await repository.createModule(courseId: course2, type: .module, title: "Course 2 Module")

        let modules1 = try await repository.fetchModules(for: course1)
        let modules2 = try await repository.fetchModules(for: course2)

        XCTAssertEqual(modules1.count, 1)
        XCTAssertEqual(modules2.count, 1)
        XCTAssertEqual(modules1[0].title, "Course 1 Module")
        XCTAssertEqual(modules2[0].title, "Course 2 Module")
    }
}
