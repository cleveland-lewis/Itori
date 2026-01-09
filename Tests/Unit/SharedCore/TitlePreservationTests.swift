import XCTest
@testable import SharedCore

/// Tests to prevent regression: titles must never change on save, and migration must not lose data
final class TitlePreservationTests: XCTestCase {
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
    

    // MARK: - Module Title Preservation Tests

    func testCreateModulePreservesTitleExactly() async throws {
        let originalTitle = "Week 1: Introduction to Swift"
        

    // MARK: - Module Title Preservation Tests

    func testCreateModulePreservesTitleExactly() async throws {
        let originalTitle = "Week 1: Introduction to Swift"


        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: originalTitle
        )
        
        XCTAssertEqual(module.title, originalTitle, "Creating module should preserve title exactly")
    }
    

        XCTAssertEqual(module.title, originalTitle, "Creating module should preserve title exactly")
    }


        XCTAssertEqual(module.title, originalTitle, "Creating module should preserve title exactly")
    }

    func testEditModulePreservesTitleExactly() async throws {
        let originalTitle = "Chapter 3: Data Structures"
        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: originalTitle
        )
        


        let newTitle = "Chapter 3: Advanced Data Structures"
        try await repository.updateModule(
            id: module.id,
            title: newTitle,
            sortIndex: nil
        )
        

        let modules = try await repository.fetchModules(for: courseId)
        let updated = modules.first { $0.id == module.id }

        XCTAssertEqual(updated?.title, newTitle, "Editing module should preserve new title exactly")
    }
    

        let modules = try await repository.fetchModules(for: courseId)
        let updated = modules.first { $0.id == module.id }

        XCTAssertEqual(updated?.title, newTitle, "Editing module should preserve new title exactly")
    }


    func testSaveModuleMultipleTimesPreservesTitle() async throws {
        let title = "Module 5: Algorithms"
        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: title
        )
        
        // Save multiple times with different sort indices
        for i in 0..<5 {

        // Save multiple times with different sort indices
        for i in 0 ..< 5 {

        // Save multiple times with different sort indices
        for i in 0 ..< 5 {
            try await repository.updateModule(
                id: module.id,
                title: nil,
                sortIndex: i
            )
        }
        

        let modules = try await repository.fetchModules(for: courseId)
        let updated = modules.first { $0.id == module.id }

        XCTAssertEqual(updated?.title, title, "Saving module multiple times should preserve title exactly")
    }

    // MARK: - File Title Preservation Tests

    func testCreateFilePreservesTitleExactly() async throws {
        let filename = "Syllabus - Fall 2024.pdf"
        

        let modules = try await repository.fetchModules(for: courseId)
        let updated = modules.first { $0.id == module.id }

        XCTAssertEqual(updated?.title, title, "Saving module multiple times should preserve title exactly")
    }

    // MARK: - File Title Preservation Tests

    func testCreateFilePreservesTitleExactly() async throws {
        let filename = "Syllabus - Fall 2024.pdf"


        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: filename,
            fileType: "pdf",
            localURL: nil,
            isSyllabus: true
        )
        
        XCTAssertEqual(file.filename, filename, "Creating file should preserve filename exactly")
    }
    

        XCTAssertEqual(file.filename, filename, "Creating file should preserve filename exactly")
    }


        XCTAssertEqual(file.filename, filename, "Creating file should preserve filename exactly")
    }

    func testFilenameSavePreservesTitle() async throws {
        let filename = "Practice Exam [Final].pdf"
        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: filename,
            fileType: "pdf",
            localURL: nil,
            isPracticeExam: true
        )
        


        // Update parse status multiple times
        try await repository.updateFileParse(
            id: file.id,
            parseStatus: .queued,
            parseError: nil
        )
        try await repository.updateFileParse(
            id: file.id,
            parseStatus: .parsing,
            parseError: nil
        )
        try await repository.updateFileParse(
            id: file.id,
            parseStatus: .parsed,
            parseError: nil
        )
        

        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        let updated = files.first { $0.id == file.id }

        XCTAssertEqual(updated?.filename, filename, "Saving file multiple times should preserve filename exactly")
    }

    // MARK: - Edge Case Titles

    func testTitleWithBrackets() async throws {
        let title = "[IMPORTANT] Module 1: Introduction"
        

        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        let updated = files.first { $0.id == file.id }

        XCTAssertEqual(updated?.filename, filename, "Saving file multiple times should preserve filename exactly")
    }

    // MARK: - Edge Case Titles

    func testTitleWithBrackets() async throws {
        let title = "[IMPORTANT] Module 1: Introduction"


        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: title
        )
        
        XCTAssertEqual(module.title, title, "Title with brackets should be preserved exactly")
        

        XCTAssertEqual(module.title, title, "Title with brackets should be preserved exactly")


        XCTAssertEqual(module.title, title, "Title with brackets should be preserved exactly")

        // Verify after fetch
        let modules = try await repository.fetchModules(for: courseId)
        let fetched = modules.first { $0.id == module.id }
        XCTAssertEqual(fetched?.title, title, "Title with brackets should persist after fetch")
    }
    
    func testTitleWithColons() async throws {
        let title = "Week 3: Review: Midterm Prep"
        

    func testTitleWithColons() async throws {
        let title = "Week 3: Review: Midterm Prep"


    func testTitleWithColons() async throws {
        let title = "Week 3: Review: Midterm Prep"

        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: title
        )
        
        XCTAssertEqual(module.title, title, "Title with colons should be preserved exactly")
    }
    

        XCTAssertEqual(module.title, title, "Title with colons should be preserved exactly")
    }


        XCTAssertEqual(module.title, title, "Title with colons should be preserved exactly")
    }

    func testTitleWithLegacyLikePrefixes() async throws {
        let titles = [
            "Module: Core Concepts",
            "Section: Advanced Topics",
            "Chapter: Final Review",
            "Part 1: Getting Started",
            "Lesson 5: Summary"
        ]
        


        for title in titles {
            let module = try await repository.createModule(
                courseId: courseId,
                type: .module,
                title: title
            )
            

            XCTAssertEqual(module.title, title, "Title with prefix '\(title)' should be preserved exactly")
        }

        let modules = try await repository.fetchModules(for: courseId)
        XCTAssertEqual(modules.count, titles.count)
        

            XCTAssertEqual(module.title, title, "Title with prefix '\(title)' should be preserved exactly")
        }

        let modules = try await repository.fetchModules(for: courseId)
        XCTAssertEqual(modules.count, titles.count)


        for (index, module) in modules.enumerated() {
            XCTAssertEqual(module.title, titles[index], "Title '\(titles[index])' should persist exactly")
        }
    }
    


    func testFilenameWithSpecialCharacters() async throws {
        let filenames = [
            "[Syllabus] CS 101.pdf",
            "Practice Test: Midterm (v2).pdf",
            "Homework #3 - Arrays & Strings.pdf",
            "Lab Report [Group A]: Results.pdf"
        ]
        


        for filename in filenames {
            let file = try await repository.addFile(
                courseId: courseId,
                nodeId: nil,
                fileName: filename,
                fileType: "pdf",
                localURL: nil
            )
            

            XCTAssertEqual(file.filename, filename, "Filename '\(filename)' should be preserved exactly")
        }

        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        XCTAssertEqual(files.count, filenames.count)
        

            XCTAssertEqual(file.filename, filename, "Filename '\(filename)' should be preserved exactly")
        }

        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        XCTAssertEqual(files.count, filenames.count)


        for file in files {
            XCTAssertTrue(filenames.contains(file.filename), "Filename '\(file.filename)' should persist exactly")
        }
    }
    
    // MARK: - Migration Tests
    

    // MARK: - Migration Tests


    // MARK: - Migration Tests

    func testLegacyRecordMigratesCategoryCorrectly() async throws {
        // Create file with legacy isSyllabus flag
        let syllabusFile = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: "Course Syllabus.pdf",
            fileType: "pdf",
            localURL: nil,
            isSyllabus: true,
            isPracticeExam: false
        )
        

        // Verify legacy flag is preserved
        XCTAssertTrue(syllabusFile.isSyllabus, "Legacy isSyllabus flag should be preserved")
        XCTAssertFalse(syllabusFile.isPracticeExam, "Legacy isPracticeExam flag should be false")

        // Verify category is set (even if uncategorized initially)
        XCTAssertNotNil(syllabusFile.category, "Category should not be nil")
        

        // Verify legacy flag is preserved
        XCTAssertTrue(syllabusFile.isSyllabus, "Legacy isSyllabus flag should be preserved")
        XCTAssertFalse(syllabusFile.isPracticeExam, "Legacy isPracticeExam flag should be false")

        // Verify category is set (even if uncategorized initially)
        XCTAssertNotNil(syllabusFile.category, "Category should not be nil")


        // Create file with legacy isPracticeExam flag
        let practiceFile = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: "Practice Exam.pdf",
            fileType: "pdf",
            localURL: nil,
            isSyllabus: false,
            isPracticeExam: true
        )
        


        // Verify legacy flag is preserved
        XCTAssertFalse(practiceFile.isSyllabus, "Legacy isSyllabus flag should be false")
        XCTAssertTrue(practiceFile.isPracticeExam, "Legacy isPracticeExam flag should be preserved")
        XCTAssertNotNil(practiceFile.category, "Category should not be nil")
    }
    
    func testTitleRemainsIdenticalPrePostMigration() async throws {
        let originalFilename = "Final Exam Review.pdf"
        

    func testTitleRemainsIdenticalPrePostMigration() async throws {
        let originalFilename = "Final Exam Review.pdf"


    func testTitleRemainsIdenticalPrePostMigration() async throws {
        let originalFilename = "Final Exam Review.pdf"

        // Create file with legacy flags (simulating old data)
        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: originalFilename,
            fileType: "pdf",
            localURL: nil,
            isSyllabus: false,
            isPracticeExam: true
        )
        
        XCTAssertEqual(file.filename, originalFilename, "Filename should remain unchanged after creation with legacy flags")
        

        XCTAssertEqual(
            file.filename,
            originalFilename,
            "Filename should remain unchanged after creation with legacy flags"
        )

        // Simulate migration by updating parse status (which might trigger category inference)
        try await repository.updateFileParse(
            id: file.id,
            parseStatus: .parsed,
            parseError: nil
        )
        

        // Verify title is still identical
        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        let migrated = files.first { $0.id == file.id }

        XCTAssertEqual(
            migrated?.filename,
            originalFilename,
            "Filename must remain identical after migration-like operations"
        )
    }
    

        // Verify title is still identical
        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        let migrated = files.first { $0.id == file.id }

        XCTAssertEqual(
            migrated?.filename,
            originalFilename,
            "Filename must remain identical after migration-like operations"
        )
    }


    func testMigrationPreservesAllFileData() async throws {
        let testData = (
            filename: "Syllabus [Spring 2024].pdf",
            fileType: "pdf",
            localURL: "/path/to/file.pdf",
            isSyllabus: true,
            isPracticeExam: false
        )
        


        let file = try await repository.addFile(
            courseId: courseId,
            nodeId: nil,
            fileName: testData.filename,
            fileType: testData.fileType,
            localURL: testData.localURL,
            isSyllabus: testData.isSyllabus,
            isPracticeExam: testData.isPracticeExam
        )
        


        // Verify all data is preserved
        XCTAssertEqual(file.filename, testData.filename, "Filename must be preserved")
        XCTAssertEqual(file.fileType, testData.fileType, "File type must be preserved")
        XCTAssertEqual(file.localURL, testData.localURL, "Local URL must be preserved")
        XCTAssertEqual(file.isSyllabus, testData.isSyllabus, "isSyllabus flag must be preserved")
        XCTAssertEqual(file.isPracticeExam, testData.isPracticeExam, "isPracticeExam flag must be preserved")
        XCTAssertEqual(file.courseId, courseId, "Course ID must be preserved")
        
        // Fetch and verify persistence
        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        let persisted = files.first { $0.id == file.id }
        

        // Fetch and verify persistence
        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        let persisted = files.first { $0.id == file.id }


        // Fetch and verify persistence
        let files = try await repository.fetchFiles(courseId: courseId, nodeId: nil)
        let persisted = files.first { $0.id == file.id }

        XCTAssertNotNil(persisted, "File should be persisted")
        XCTAssertEqual(persisted?.filename, testData.filename, "Persisted filename must match")
        XCTAssertEqual(persisted?.fileType, testData.fileType, "Persisted file type must match")
        XCTAssertEqual(persisted?.localURL, testData.localURL, "Persisted local URL must match")
        XCTAssertEqual(persisted?.isSyllabus, testData.isSyllabus, "Persisted isSyllabus must match")
        XCTAssertEqual(persisted?.isPracticeExam, testData.isPracticeExam, "Persisted isPracticeExam must match")
    }
    
    // MARK: - Module Migration Tests
    

    // MARK: - Module Migration Tests


    // MARK: - Module Migration Tests

    func testModuleMigrationPreservesAllData() async throws {
        let testData = (
            type: CourseOutlineNodeType.module,
            title: "Module 1: [Introduction] Core Concepts",
            sortIndex: 0
        )
        


        let module = try await repository.createModule(
            courseId: courseId,
            parentId: nil,
            type: testData.type,
            title: testData.title,
            sortIndex: testData.sortIndex
        )
        


        XCTAssertEqual(module.title, testData.title, "Title must be preserved")
        XCTAssertEqual(module.type, testData.type, "Type must be preserved")
        XCTAssertEqual(module.sortIndex, testData.sortIndex, "Sort index must be preserved")
        XCTAssertEqual(module.courseId, courseId, "Course ID must be preserved")
        XCTAssertNil(module.parentId, "Parent ID should be nil for root module")
        
        // Verify persistence
        let modules = try await repository.fetchModules(for: courseId)
        let persisted = modules.first { $0.id == module.id }
        

        // Verify persistence
        let modules = try await repository.fetchModules(for: courseId)
        let persisted = modules.first { $0.id == module.id }


        // Verify persistence
        let modules = try await repository.fetchModules(for: courseId)
        let persisted = modules.first { $0.id == module.id }

        XCTAssertNotNil(persisted, "Module should be persisted")
        XCTAssertEqual(persisted?.title, testData.title, "Persisted title must match exactly")
        XCTAssertEqual(persisted?.type, testData.type, "Persisted type must match")
        XCTAssertEqual(persisted?.sortIndex, testData.sortIndex, "Persisted sort index must match")
    }
    
    func testNestedModuleTitlePreservation() async throws {
        let parentTitle = "Section A: [Parent]"
        let childTitle = "Subsection 1: [Child]"
        

    func testNestedModuleTitlePreservation() async throws {
        let parentTitle = "Section A: [Parent]"
        let childTitle = "Subsection 1: [Child]"


    func testNestedModuleTitlePreservation() async throws {
        let parentTitle = "Section A: [Parent]"
        let childTitle = "Subsection 1: [Child]"

        let parent = try await repository.createModule(
            courseId: courseId,
            parentId: nil,
            type: .section,
            title: parentTitle,
            sortIndex: 0
        )
        


        let child = try await repository.createModule(
            courseId: courseId,
            parentId: parent.id,
            type: .lesson,
            title: childTitle,
            sortIndex: 0
        )
        
        XCTAssertEqual(parent.title, parentTitle, "Parent title must be preserved")
        XCTAssertEqual(child.title, childTitle, "Child title must be preserved")
        

        XCTAssertEqual(parent.title, parentTitle, "Parent title must be preserved")
        XCTAssertEqual(child.title, childTitle, "Child title must be preserved")


        XCTAssertEqual(parent.title, parentTitle, "Parent title must be preserved")
        XCTAssertEqual(child.title, childTitle, "Child title must be preserved")

        // Verify both persist correctly
        let modules = try await repository.fetchModules(for: courseId)
        let persistedParent = modules.first { $0.id == parent.id }
        let persistedChild = modules.first { $0.id == child.id }
        

        XCTAssertEqual(persistedParent?.title, parentTitle, "Parent title must persist")
        XCTAssertEqual(persistedChild?.title, childTitle, "Child title must persist")
    }

    // MARK: - Stress Tests
    

        XCTAssertEqual(persistedParent?.title, parentTitle, "Parent title must persist")
        XCTAssertEqual(persistedChild?.title, childTitle, "Child title must persist")
    }

    // MARK: - Stress Tests


    func testMassiveTitleVariations() async throws {
        let variations = [
            "Simple Title",
            "[Prefix] Title",
            "Title: Suffix",
            "[Prefix]: Title: Suffix",
            "Title (Notes)",
            "Title [v2]",
            "Chapter 1: Section A: Part I",
            "Module: [DRAFT] Introduction",
            "Week 1 - Day 1: Getting Started",
            "[IMPORTANT][URGENT] Critical Review"
        ]
        


        for (index, title) in variations.enumerated() {
            let module = try await repository.createModule(
                courseId: courseId,
                type: .module,
                title: title,
                sortIndex: index
            )
            

            XCTAssertEqual(module.title, title, "Variation '\(title)' should be preserved exactly")
        }

        let modules = try await repository.fetchModules(for: courseId)
        XCTAssertEqual(modules.count, variations.count, "All modules should be created")
        

            XCTAssertEqual(module.title, title, "Variation '\(title)' should be preserved exactly")
        }

        let modules = try await repository.fetchModules(for: courseId)
        XCTAssertEqual(modules.count, variations.count, "All modules should be created")


        for module in modules {
            XCTAssertTrue(variations.contains(module.title), "Title '\(module.title)' should be in original variations")
        }
    }
    

    func testUnicodeTitles() async throws {
        let unicodeTitles = [
            "模块 1: 介绍", // Chinese
            "モジュール 1: イントロ", // Japanese
            "모듈 1: 소개", // Korean
            "Модуль 1: Введение", // Russian
            "وحدة 1: مقدمة", // Arabic
            "Module 1: Εισαγωγή" // Greek
        ]
        

    func testUnicodeTitles() async throws {
        let unicodeTitles = [
            "模块 1: 介绍", // Chinese
            "モジュール 1: イントロ", // Japanese
            "모듈 1: 소개", // Korean
            "Модуль 1: Введение", // Russian
            "وحدة 1: مقدمة", // Arabic
            "Module 1: Εισαγωγή" // Greek
        ]


        for (index, title) in unicodeTitles.enumerated() {
            let module = try await repository.createModule(
                courseId: courseId,
                type: .module,
                title: title,
                sortIndex: index
            )
            
            XCTAssertEqual(module.title, title, "Unicode title '\(title)' should be preserved exactly")
        }
        

            XCTAssertEqual(module.title, title, "Unicode title '\(title)' should be preserved exactly")
        }


            XCTAssertEqual(module.title, title, "Unicode title '\(title)' should be preserved exactly")
        }

        let modules = try await repository.fetchModules(for: courseId)
        for module in modules {
            XCTAssertTrue(unicodeTitles.contains(module.title), "Unicode title should persist exactly")
        }
    }
}
