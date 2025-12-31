//
//  PlannerModelsTests.swift
//  RootsTests
//
//  Tests for PlannerModels - Plan status and step types
//

import XCTest
@testable import Roots

@MainActor
final class PlannerModelsTests: BaseTestCase {
    
    // MARK: - PlanStatus Tests
    
    func testPlanStatusAllCases() {
        let statuses: [PlanStatus] = [.draft, .active, .completed, .archived]
        XCTAssertEqual(statuses.count, 4)
    }
    
    func testPlanStatusRawValues() {
        XCTAssertEqual(PlanStatus.draft.rawValue, "draft")
        XCTAssertEqual(PlanStatus.active.rawValue, "active")
        XCTAssertEqual(PlanStatus.completed.rawValue, "completed")
        XCTAssertEqual(PlanStatus.archived.rawValue, "archived")
    }
    
    func testPlanStatusCodable() throws {
        let status = PlanStatus.active
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(status)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PlanStatus.self, from: data)
        
        XCTAssertEqual(decoded, status)
    }
    
    func testPlanStatusFromRawValue() {
        XCTAssertEqual(PlanStatus(rawValue: "draft"), .draft)
        XCTAssertEqual(PlanStatus(rawValue: "active"), .active)
        XCTAssertEqual(PlanStatus(rawValue: "completed"), .completed)
        XCTAssertEqual(PlanStatus(rawValue: "archived"), .archived)
        XCTAssertNil(PlanStatus(rawValue: "invalid"))
    }
    
    // MARK: - StepType Tests
    
    func testStepTypeAllCases() {
        let types: [StepType] = [.work, .review, .practice, .research]
        XCTAssertEqual(types.count, 4)
    }
    
    func testStepTypeRawValues() {
        XCTAssertEqual(StepType.work.rawValue, "work")
        XCTAssertEqual(StepType.review.rawValue, "review")
        XCTAssertEqual(StepType.practice.rawValue, "practice")
        XCTAssertEqual(StepType.research.rawValue, "research")
    }
    
    func testStepTypeCodable() throws {
        let stepType = StepType.review
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(stepType)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StepType.self, from: data)
        
        XCTAssertEqual(decoded, stepType)
    }
    
    func testStepTypeFromRawValue() {
        XCTAssertEqual(StepType(rawValue: "work"), .work)
        XCTAssertEqual(StepType(rawValue: "review"), .review)
        XCTAssertEqual(StepType(rawValue: "practice"), .practice)
        XCTAssertEqual(StepType(rawValue: "research"), .research)
        XCTAssertNil(StepType(rawValue: "invalid"))
    }
    
    // MARK: - Enum Equality Tests
    
    func testPlanStatusEquality() {
        XCTAssertEqual(PlanStatus.draft, .draft)
        XCTAssertNotEqual(PlanStatus.draft, .active)
    }
    
    func testStepTypeEquality() {
        XCTAssertEqual(StepType.work, .work)
        XCTAssertNotEqual(StepType.work, .review)
    }
    
    // MARK: - Array/Set Usage Tests
    
    func testPlanStatusInArray() {
        let statuses: [PlanStatus] = [.draft, .active, .completed]
        
        XCTAssertTrue(statuses.contains(.draft))
        XCTAssertFalse(statuses.contains(.archived))
    }
    
    func testStepTypeInArray() {
        let types: [StepType] = [.work, .review]
        
        XCTAssertTrue(types.contains(.work))
        XCTAssertFalse(types.contains(.practice))
    }
}
