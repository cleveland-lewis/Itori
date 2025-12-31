//
//  AppModalRouterTests.swift
//  RootsTests
//
//  Tests for AppModalRouter - Modal navigation management
//

import XCTest
import Combine
@testable import Roots

@MainActor
final class AppModalRouterTests: BaseTestCase {
    
    var router: AppModalRouter!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        router = AppModalRouter()
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        router = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultState() {
        XCTAssertNil(router.route)
    }
    
    // MARK: - Present Tests
    
    func testPresentAddAssignment() {
        router.present(.addAssignment)
        XCTAssertEqual(router.route, .addAssignment)
    }
    
    func testPresentAddGrade() {
        router.present(.addGrade)
        XCTAssertEqual(router.route, .addGrade)
    }
    
    func testPresentPlanner() {
        router.present(.planner)
        XCTAssertEqual(router.route, .planner)
    }
    
    func testPresentOverwritesPreviousRoute() {
        router.present(.addAssignment)
        router.present(.addGrade)
        
        XCTAssertEqual(router.route, .addGrade)
    }
    
    // MARK: - Clear Tests
    
    func testClear() {
        router.present(.addAssignment)
        router.clear()
        
        XCTAssertNil(router.route)
    }
    
    func testClearWhenAlreadyNil() {
        router.clear()
        XCTAssertNil(router.route)
    }
    
    // MARK: - Published Tests
    
    func testRoutePublishes() {
        let expectation = XCTestExpectation(description: "Route published")
        
        router.$route
            .dropFirst()
            .sink { route in
                XCTAssertEqual(route, .addAssignment)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        router.present(.addAssignment)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMultipleRouteChanges() {
        var routeChanges: [AppModalRoute?] = []
        
        router.$route
            .sink { route in
                routeChanges.append(route)
            }
            .store(in: &cancellables)
        
        router.present(.addAssignment)
        router.present(.addGrade)
        router.clear()
        
        XCTAssertEqual(routeChanges.count, 4) // Initial + 3 changes
        XCTAssertNil(routeChanges[0])
        XCTAssertEqual(routeChanges[1], .addAssignment)
        XCTAssertEqual(routeChanges[2], .addGrade)
        XCTAssertNil(routeChanges[3])
    }
}

// MARK: - AppModalRoute Tests

@MainActor
final class AppModalRouteTests: BaseTestCase {
    
    func testAllRoutes() {
        let routes: [AppModalRoute] = [.addAssignment, .addGrade, .planner]
        XCTAssertEqual(routes.count, 3)
    }
    
    func testRouteIds() {
        XCTAssertEqual(AppModalRoute.addAssignment.id, "addAssignment")
        XCTAssertEqual(AppModalRoute.addGrade.id, "addGrade")
        XCTAssertEqual(AppModalRoute.planner.id, "planner")
    }
    
    func testRouteIdsUnique() {
        let routes: [AppModalRoute] = [.addAssignment, .addGrade, .planner]
        let ids = Set(routes.map { $0.id })
        XCTAssertEqual(ids.count, routes.count)
    }
    
    func testRouteHashable() {
        var set = Set<AppModalRoute>()
        set.insert(.addAssignment)
        set.insert(.addGrade)
        set.insert(.addAssignment)
        
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(.addAssignment))
        XCTAssertTrue(set.contains(.addGrade))
    }
    
    func testRouteEquality() {
        XCTAssertEqual(AppModalRoute.addAssignment, .addAssignment)
        XCTAssertNotEqual(AppModalRoute.addAssignment, .addGrade)
    }
}
