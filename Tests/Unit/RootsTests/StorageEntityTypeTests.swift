//
//  StorageEntityTypeTests.swift
//  RootsTests
//
//  Tests for StorageEntityType - Storage entity classifications
//

import XCTest
@testable import Roots

@MainActor
final class StorageEntityTypeTests: BaseTestCase {
    
    // MARK: - All Cases Tests
    
    func testStorageEntityTypeAllCases() {
        XCTAssertEqual(StorageEntityType.allCases.count, 15)
    }
    
    func testStorageEntityTypeContainsAllExpected() {
        let types = StorageEntityType.allCases
        
        XCTAssertTrue(types.contains(.course))
        XCTAssertTrue(types.contains(.semester))
        XCTAssertTrue(types.contains(.assignment))
        XCTAssertTrue(types.contains(.grade))
        XCTAssertTrue(types.contains(.plannerBlock))
        XCTAssertTrue(types.contains(.assignmentPlan))
        XCTAssertTrue(types.contains(.focusSession))
        XCTAssertTrue(types.contains(.practiceTest))
        XCTAssertTrue(types.contains(.testBlueprint))
        XCTAssertTrue(types.contains(.courseOutline))
        XCTAssertTrue(types.contains(.courseFile))
        XCTAssertTrue(types.contains(.attachment))
        XCTAssertTrue(types.contains(.syllabus))
        XCTAssertTrue(types.contains(.parsedAssignment))
        XCTAssertTrue(types.contains(.calendarEvent))
        XCTAssertTrue(types.contains(.timerSession))
    }
    
    // MARK: - Raw Value Tests
    
    func testStorageEntityTypeRawValues() {
        XCTAssertEqual(StorageEntityType.course.rawValue, "Course")
        XCTAssertEqual(StorageEntityType.semester.rawValue, "Semester")
        XCTAssertEqual(StorageEntityType.assignment.rawValue, "Assignment")
        XCTAssertEqual(StorageEntityType.plannerBlock.rawValue, "Planner Block")
    }
    
    // MARK: - Has Native Title Tests
    
    func testHasNativeTitleTrue() {
        XCTAssertTrue(StorageEntityType.course.hasNativeTitle)
        XCTAssertTrue(StorageEntityType.assignment.hasNativeTitle)
        XCTAssertTrue(StorageEntityType.practiceTest.hasNativeTitle)
        XCTAssertTrue(StorageEntityType.attachment.hasNativeTitle)
    }
    
    func testHasNativeTitleFalse() {
        XCTAssertFalse(StorageEntityType.semester.hasNativeTitle)
        XCTAssertFalse(StorageEntityType.grade.hasNativeTitle)
        XCTAssertFalse(StorageEntityType.plannerBlock.hasNativeTitle)
        XCTAssertFalse(StorageEntityType.timerSession.hasNativeTitle)
    }
    
    // MARK: - Category Tests
    
    func testCategoryAcademic() {
        XCTAssertEqual(StorageEntityType.course.category, .academic)
        XCTAssertEqual(StorageEntityType.semester.category, .academic)
        XCTAssertEqual(StorageEntityType.assignment.category, .academic)
        XCTAssertEqual(StorageEntityType.grade.category, .academic)
    }
    
    func testCategoryPlanning() {
        XCTAssertEqual(StorageEntityType.plannerBlock.category, .planning)
        XCTAssertEqual(StorageEntityType.assignmentPlan.category, .planning)
        XCTAssertEqual(StorageEntityType.focusSession.category, .planning)
    }
    
    func testCategoryTesting() {
        XCTAssertEqual(StorageEntityType.practiceTest.category, .testing)
        XCTAssertEqual(StorageEntityType.testBlueprint.category, .testing)
    }
    
    func testCategoryContent() {
        XCTAssertEqual(StorageEntityType.courseOutline.category, .content)
        XCTAssertEqual(StorageEntityType.courseFile.category, .content)
        XCTAssertEqual(StorageEntityType.attachment.category, .content)
    }
    
    // MARK: - Display Type Name Tests
    
    func testDisplayTypeName() {
        XCTAssertEqual(StorageEntityType.course.displayTypeName, "Course")
        XCTAssertEqual(StorageEntityType.assignment.displayTypeName, "Assignment")
        XCTAssertEqual(StorageEntityType.plannerBlock.displayTypeName, "Planner Block")
    }
    
    // MARK: - Icon Tests
    
    func testIconsNotEmpty() {
        for type in StorageEntityType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }
    
    func testSpecificIcons() {
        XCTAssertEqual(StorageEntityType.course.icon, "book.closed")
        XCTAssertEqual(StorageEntityType.assignment.icon, "doc.text")
        XCTAssertEqual(StorageEntityType.timerSession.icon, "timer.square")
    }
    
    // MARK: - Identifiable Tests
    
    func testIdentifiable() {
        XCTAssertEqual(StorageEntityType.course.id, "Course")
        XCTAssertEqual(StorageEntityType.assignment.id, "Assignment")
    }
    
    // MARK: - Codable Tests
    
    func testStorageEntityTypeCodable() throws {
        let type = StorageEntityType.assignment
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(type)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StorageEntityType.self, from: data)
        
        XCTAssertEqual(decoded, type)
    }
}

// MARK: - EntityCategory Tests

@MainActor
final class EntityCategoryTests: BaseTestCase {
    
    func testEntityCategoryAllCases() {
        XCTAssertEqual(EntityCategory.allCases.count, 7)
    }
    
    func testEntityCategoryRawValues() {
        XCTAssertEqual(EntityCategory.academic.rawValue, "Academic")
        XCTAssertEqual(EntityCategory.planning.rawValue, "Planning")
        XCTAssertEqual(EntityCategory.testing.rawValue, "Testing")
    }
    
    func testEntityCategoryIcons() {
        XCTAssertEqual(EntityCategory.academic.icon, "graduationcap")
        XCTAssertEqual(EntityCategory.planning.icon, "calendar.badge.clock")
        XCTAssertEqual(EntityCategory.timer.icon, "timer")
    }
    
    func testEntityCategoryIdentifiable() {
        XCTAssertEqual(EntityCategory.academic.id, "Academic")
        XCTAssertEqual(EntityCategory.content.id, "Content")
    }
}

// MARK: - StorageListItem Tests

@MainActor
final class StorageListItemTests: BaseTestCase {
    
    func testStorageListItemInitialization() {
        let item = StorageListItem(
            displayTitle: "Test Assignment",
            entityType: .assignment,
            contextDescription: "Math 101",
            primaryDate: Date(),
            statusDescription: "Active",
            entityId: "123",
            entityStore: "assignments"
        )
        
        XCTAssertEqual(item.displayTitle, "Test Assignment")
        XCTAssertEqual(item.entityType, .assignment)
        XCTAssertEqual(item.contextDescription, "Math 101")
        XCTAssertEqual(item.statusDescription, "Active")
        XCTAssertEqual(item.entityId, "123")
        XCTAssertEqual(item.entityStore, "assignments")
    }
    
    func testStorageListItemSearchText() {
        let item = StorageListItem(
            displayTitle: "Test Assignment",
            entityType: .assignment,
            contextDescription: "Math 101",
            primaryDate: Date(),
            statusDescription: "Active",
            entityId: "123",
            entityStore: "assignments"
        )
        
        let searchText = item.searchText
        XCTAssertTrue(searchText.contains("test assignment"))
        XCTAssertTrue(searchText.contains("assignment"))
        XCTAssertTrue(searchText.contains("math 101"))
        XCTAssertTrue(searchText.contains("active"))
    }
    
    func testStorageListItemSearchTextLowercase() {
        let item = StorageListItem(
            displayTitle: "CAPS TITLE",
            entityType: .course,
            primaryDate: Date(),
            entityId: "123",
            entityStore: "courses"
        )
        
        XCTAssertEqual(item.searchText, item.searchText.lowercased())
    }
    
    func testStorageListItemHashable() {
        let id = UUID()
        let item1 = StorageListItem(
            id: id,
            displayTitle: "Test",
            entityType: .assignment,
            primaryDate: Date(),
            entityId: "123",
            entityStore: "store"
        )
        let item2 = StorageListItem(
            id: id,
            displayTitle: "Test",
            entityType: .assignment,
            primaryDate: Date(),
            entityId: "123",
            entityStore: "store"
        )
        
        XCTAssertEqual(item1, item2)
        
        var set = Set<StorageListItem>()
        set.insert(item1)
        set.insert(item2)
        
        XCTAssertEqual(set.count, 1)
    }
    
    func testStorageListItemWithoutOptionals() {
        let item = StorageListItem(
            displayTitle: "Simple Item",
            entityType: .course,
            primaryDate: Date(),
            entityId: "456",
            entityStore: "courses"
        )
        
        XCTAssertNil(item.contextDescription)
        XCTAssertNil(item.statusDescription)
    }
}
