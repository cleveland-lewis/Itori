import XCTest
@testable import SharedCore

final class PlannerAnalysisPersistenceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var repository: PlannerAnalysisRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        repository = PlannerAnalysisRepository(persistenceController: persistenceController)
    }
    
    override func tearDown() async throws {
        repository = nil
        persistenceController = nil
        try await super.tearDown()
    }
    
    // MARK: - Create Tests
    
    func testSaveAnalysis() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7 * 24 * 60 * 60) // 1 week
        
        let analysisData: [String: Any] = [
            "assignments": ["id1", "id2", "id3"],
            "total_hours": 40,
            "difficulty_average": 0.7
        ]
        
        let resultData: [String: Any] = [
            "recommendations": ["Start early", "Break into chunks"],
            "workload_distribution": ["Monday": 8, "Tuesday": 6]
        ]
        
        let id = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: analysisData,
            resultData: resultData
        )
        
        XCTAssertNotNil(id)
    }
    
    func testSaveAnalysisWithoutResults() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7 * 24 * 60 * 60)
        
        let analysisData: [String: Any] = [
            "assignments": ["id1", "id2"]
        ]
        
        let id = try await repository.saveAnalysis(
            type: "workload_analysis",
            startDate: startDate,
            endDate: endDate,
            analysisData: analysisData,
            resultData: nil
        )
        
        XCTAssertNotNil(id)
    }
    
    // MARK: - Fetch Tests
    
    func testFetchAnalysesByDateRange() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7 * 24 * 60 * 60)
        
        _ = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["test": "data1"],
            resultData: nil
        )
        
        _ = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["test": "data2"],
            resultData: nil
        )
        
        let analyses = try await repository.fetchAnalyses(
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(analyses.count, 2)
    }
    
    func testFetchAnalysesByType() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7 * 24 * 60 * 60)
        
        _ = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["test": "data"],
            resultData: nil
        )
        
        _ = try await repository.saveAnalysis(
            type: "workload_analysis",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["test": "data"],
            resultData: nil
        )
        
        let weeklyPlans = try await repository.fetchAnalyses(
            startDate: startDate,
            endDate: endDate,
            type: "weekly_plan"
        )
        
        XCTAssertEqual(weeklyPlans.count, 1)
        XCTAssertEqual(weeklyPlans[0].analysisType, "weekly_plan")
    }
    
    func testFetchLatestAnalysis() async throws {
        let now = Date()
        let startDate = now
        let endDate = now.addingTimeInterval(7 * 24 * 60 * 60)
        
        // Create three analyses
        _ = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["order": 1],
            resultData: nil
        )
        
        // Small delay to ensure different timestamps
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        _ = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["order": 2],
            resultData: nil
        )
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let lastId = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["order": 3],
            resultData: nil
        )
        
        let latest = try await repository.fetchLatestAnalysis(type: "weekly_plan")
        
        XCTAssertNotNil(latest)
        XCTAssertEqual(latest?.id, lastId)
    }
    
    func testFetchLatestAnalysisReturnsNilWhenEmpty() async throws {
        let latest = try await repository.fetchLatestAnalysis(type: "nonexistent_type")
        XCTAssertNil(latest)
    }
    
    // MARK: - Update Tests
    
    func testUpdateAnalysis() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7 * 24 * 60 * 60)
        
        let id = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["initial": "data"],
            resultData: nil
        )
        
        let newResultData: [String: Any] = [
            "recommendations": ["New recommendation"],
            "score": 85
        ]
        
        try await repository.updateAnalysis(
            id: id,
            resultData: newResultData
        )
        
        let latest = try await repository.fetchLatestAnalysis(type: "weekly_plan")
        XCTAssertNotNil(latest?.resultData)
        XCTAssertNotNil(latest?.resultData?["recommendations"])
    }
    
    func testUpdateNonexistentAnalysisThrowsError() async throws {
        let fakeId = UUID()
        
        do {
            try await repository.updateAnalysis(
                id: fakeId,
                resultData: ["test": "data"]
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("not found"))
        }
    }
    
    // MARK: - Delete Tests
    
    func testDeleteAnalysis() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7 * 24 * 60 * 60)
        
        let id = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["test": "data"],
            resultData: nil
        )
        
        try await repository.deleteAnalysis(id: id)
        
        let analyses = try await repository.fetchAnalyses(
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(analyses.count, 0)
    }
    
    func testDeleteOldAnalyses() async throws {
        let now = Date()
        let oldDate = now.addingTimeInterval(-90 * 24 * 60 * 60) // 90 days ago
        let recentDate = now.addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        
        // Create old analysis
        _ = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: oldDate,
            endDate: oldDate.addingTimeInterval(7 * 24 * 60 * 60),
            analysisData: ["old": "data"],
            resultData: nil
        )
        
        // Create recent analysis
        _ = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: recentDate,
            endDate: recentDate.addingTimeInterval(7 * 24 * 60 * 60),
            analysisData: ["recent": "data"],
            resultData: nil
        )
        
        // Delete analyses older than 30 days
        let cutoffDate = now.addingTimeInterval(-30 * 24 * 60 * 60)
        let deletedCount = try await repository.deleteOldAnalyses(olderThan: cutoffDate)
        
        XCTAssertEqual(deletedCount, 1)
        
        // Verify recent analysis still exists
        let latest = try await repository.fetchLatestAnalysis(type: "weekly_plan")
        XCTAssertNotNil(latest)
    }
    
    // MARK: - Data Integrity Tests
    
    func testAnalysisDataSerialization() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7 * 24 * 60 * 60)
        
        let complexData: [String: Any] = [
            "assignments": ["id1", "id2", "id3"],
            "metadata": [
                "total_hours": 40,
                "difficulty": 0.7,
                "categories": ["reading", "homework", "project"]
            ],
            "stats": [
                "average": 6.5,
                "max": 10,
                "min": 3
            ]
        ]
        
        let resultData: [String: Any] = [
            "recommendations": [
                "Start early on difficult tasks",
                "Break work into 2-hour blocks"
            ],
            "daily_plan": [
                "Monday": ["task1", "task2"],
                "Tuesday": ["task3"]
            ]
        ]
        
        let id = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: complexData,
            resultData: resultData
        )
        
        let retrieved = try await repository.fetchLatestAnalysis(type: "weekly_plan")
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, id)
        XCTAssertNotNil(retrieved?.analysisData["assignments"])
        XCTAssertNotNil(retrieved?.analysisData["metadata"])
        XCTAssertNotNil(retrieved?.resultData?["recommendations"])
        XCTAssertNotNil(retrieved?.resultData?["daily_plan"])
    }
    
    func testMultipleAnalysisTypes() async throws {
        let now = Date()
        let startDate = now
        let endDate = now.addingTimeInterval(7 * 24 * 60 * 60)
        
        _ = try await repository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["type": "weekly"],
            resultData: nil
        )
        
        _ = try await repository.saveAnalysis(
            type: "workload_analysis",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["type": "workload"],
            resultData: nil
        )
        
        _ = try await repository.saveAnalysis(
            type: "difficulty_assessment",
            startDate: startDate,
            endDate: endDate,
            analysisData: ["type": "difficulty"],
            resultData: nil
        )
        
        let weeklyPlans = try await repository.fetchAnalyses(
            startDate: startDate,
            endDate: endDate,
            type: "weekly_plan"
        )
        
        let workloadAnalyses = try await repository.fetchAnalyses(
            startDate: startDate,
            endDate: endDate,
            type: "workload_analysis"
        )
        
        XCTAssertEqual(weeklyPlans.count, 1)
        XCTAssertEqual(workloadAnalyses.count, 1)
    }
}
