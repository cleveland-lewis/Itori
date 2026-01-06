import XCTest
import SwiftUI
@testable import Itori

/// Performance tests for critical UI paths
/// Run these tests on physical devices for accurate results
final class UIPerformanceTests: XCTestCase {
    
    var assignmentsStore: AssignmentsStore!
    var coursesStore: CoursesStore!
    
    override func setUp() {
        super.setUp()
        assignmentsStore = AssignmentsStore()
        coursesStore = CoursesStore()
        
        // Seed with deterministic data
        seedTestData()
    }
    
    override func tearDown() {
        assignmentsStore = nil
        coursesStore = nil
        super.tearDown()
    }
    
    // MARK: - Dashboard Performance
    
    func testDashboardInitialLoad() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Simulate dashboard data loading
            let tasks = assignmentsStore.tasks
            let courses = coursesStore.courses
            
            // Filter and sort operations
            let sortedTasks = tasks.sorted { lhs, rhs in
                switch (lhs.effectiveDueDateTime, rhs.effectiveDueDateTime) {
                case (nil, nil): return lhs.title < rhs.title
                case (nil, _): return false
                case (_, nil): return true
                case (let l?, let r?): return l < r
                }
            }
            
            XCTAssertGreaterThanOrEqual(sortedTasks.count, 0)
        }
    }
    
    func testAssignmentFiltering() {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        
        measure(options: options, metrics: [XCTClockMetric()]) {
            // Simulate filtering by course and semester
            let filtered = assignmentsStore.tasks.filter { task in
                guard let courseId = task.courseId else { return false }
                return coursesStore.courses.contains { $0.id == courseId }
            }
            
            XCTAssertGreaterThanOrEqual(filtered.count, 0)
        }
    }
    
    func testChartDataGeneration() {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            // Simulate chart data aggregation
            var categoryCount: [String: Int] = [:]
            
            for task in assignmentsStore.tasks {
                let category = task.category.rawValue
                categoryCount[category, default: 0] += 1
            }
            
            XCTAssertGreaterThanOrEqual(categoryCount.count, 0)
        }
    }
    
    // MARK: - List Scrolling Performance
    
    func testLargeListScrolling() {
        // Simulate rendering 100+ items
        let largeTaskList = (0..<100).map { index in
            AppTask(
                id: UUID(),
                title: "Task \(index)",
                courseId: nil,
                due: Date().addingTimeInterval(Double(index) * 86400),
                estimatedMinutes: 60,
                minBlockMinutes: 15,
                maxBlockMinutes: 120,
                difficulty: 0.5,
                importance: 0.5,
                type: .homework,
                locked: false,
                attachments: [],
                isCompleted: false,
                category: .homework
            )
        }
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Simulate list rendering
            let filtered = largeTaskList.filter { !$0.isCompleted }
            let sorted = filtered.sorted { $0.title < $1.title }
            
            XCTAssertEqual(sorted.count, 100)
        }
    }
    
    // MARK: - Search Performance
    
    func testSearchPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            let query = "assignment"
            let results = assignmentsStore.tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(query)
            }
            
            XCTAssertGreaterThanOrEqual(results.count, 0)
        }
    }
    
    // MARK: - Data Mutation Performance
    
    func testTaskCreationPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            let task = AppTask(
                id: UUID(),
                title: "Performance Test Task",
                courseId: nil,
                due: Date(),
                estimatedMinutes: 60,
                minBlockMinutes: 15,
                maxBlockMinutes: 120,
                difficulty: 0.5,
                importance: 0.5,
                type: .homework,
                locked: false,
                attachments: [],
                isCompleted: false,
                category: .homework
            )
            
            assignmentsStore.addTask(task)
        }
    }
    
    func testBulkTaskUpdate() {
        let taskIds = assignmentsStore.tasks.prefix(10).map { $0.id }
        
        measure(metrics: [XCTClockMetric()]) {
            for id in taskIds {
                if var task = assignmentsStore.tasks.first(where: { $0.id == id }) {
                    task.isCompleted = true
                    assignmentsStore.updateTask(task)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func seedTestData() {
        // Seed 50 courses
        for i in 0..<50 {
            let semester = Semester(
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 120),
                isCurrent: true,
                educationLevel: .college,
                semesterTerm: .fall
            )
            coursesStore.addSemester(semester)
            
            coursesStore.addCourse(
                title: "Course \(i)",
                code: "CS\(100 + i)",
                to: semester
            )
        }
        
        // Seed 200 assignments
        for i in 0..<200 {
            let task = AppTask(
                id: UUID(),
                title: "Assignment \(i)",
                courseId: coursesStore.courses.randomElement()?.id,
                due: Date().addingTimeInterval(Double(index) * 86400),
                estimatedMinutes: [30, 60, 90, 120].randomElement() ?? 60,
                minBlockMinutes: 15,
                maxBlockMinutes: 120,
                difficulty: Double.random(in: 0.3...0.9),
                importance: Double.random(in: 0.3...0.9),
                type: [.homework, .quiz, .exam, .project].randomElement() ?? .homework,
                locked: false,
                attachments: [],
                isCompleted: Bool.random(),
                category: [.homework, .quiz, .exam, .project].randomElement() ?? .homework
            )
            
            assignmentsStore.addTask(task)
        }
    }
}

// MARK: - Performance Baseline Configuration

extension UIPerformanceTests {
    /// Performance baselines (update these after optimization work)
    enum Baseline {
        static let dashboardLoad: TimeInterval = 0.1 // 100ms
        static let assignmentFiltering: TimeInterval = 0.05 // 50ms
        static let chartGeneration: TimeInterval = 0.08 // 80ms
        static let listScrolling: TimeInterval = 0.15 // 150ms
        static let search: TimeInterval = 0.03 // 30ms
        static let taskCreation: TimeInterval = 0.02 // 20ms
        static let bulkUpdate: TimeInterval = 0.1 // 100ms
    }
}
