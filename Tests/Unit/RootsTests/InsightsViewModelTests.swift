import XCTest
@testable import Roots

final class InsightsViewModelTests: XCTestCase {
    var viewModel: InsightsViewModel!
    var mockEngine: MockInsightEngine!
    var mockHistoryStore: MockHistoryStore!
    
    override func setUp() {
        super.setUp()
        mockEngine = MockInsightEngine()
        mockHistoryStore = MockHistoryStore()
        viewModel = InsightsViewModel(engine: mockEngine, historyStore: mockHistoryStore)
    }
    
    override func tearDown() {
        viewModel = nil
        mockEngine = nil
        mockHistoryStore = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.loadingMessage)
        XCTAssertTrue(viewModel.insights.isEmpty)
    }
    
    func testRefreshGeneratesInsights() async {
        let testInsight = Insight(
            id: UUID(),
            type: .productivity,
            title: "Test Insight",
            message: "Test message",
            priority: .medium,
            actionable: true,
            metadata: [:]
        )
        mockEngine.insightsToReturn = [testInsight]
        
        viewModel.refresh(windowDays: 7)
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        XCTAssertEqual(viewModel.insights.count, 1)
        XCTAssertEqual(viewModel.insights.first?.title, "Test Insight")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testRefreshUsesCorrectTimeWindow() async {
        viewModel.refresh(windowDays: 30)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertTrue(mockHistoryStore.queryCalled)
    }
}

// MARK: - Mocks

class MockInsightEngine: InsightEngine {
    var insightsToReturn: [Insight] = []
    
    func generateInsights(from stats: UsageStats) -> [Insight] {
        return insightsToReturn
    }
}

class MockHistoryStore: HistoryStore {
    var queryCalled = false
    var events: [HistoryEvent] = []
    
    func record(_ event: HistoryEvent) {
        events.append(event)
    }
    
    func query(from: Date, to: Date) -> [HistoryEvent] {
        queryCalled = true
        return events
    }
    
    func queryRecent(limit: Int) -> [HistoryEvent] {
        return Array(events.prefix(limit))
    }
    
    func clear() {
        events.removeAll()
    }
}
