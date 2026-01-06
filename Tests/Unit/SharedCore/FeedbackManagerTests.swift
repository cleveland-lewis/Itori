import XCTest
@testable import Itori

final class FeedbackManagerTests: XCTestCase {
    
    var feedbackManager: FeedbackManager!
    
    override func setUp() {
        super.setUp()
        feedbackManager = FeedbackManager.shared
    }
    
    // MARK: - Debouncing Tests
    
    func testFeedbackDebouncing() async {
        let event = FeedbackManager.FeedbackEvent.taskCompleted
        
        // Trigger multiple times rapidly
        await MainActor.run {
            feedbackManager.trigger(event: event)
            feedbackManager.trigger(event: event)
            feedbackManager.trigger(event: event)
        }
        
        // Should only trigger once due to debouncing
        // Manual verification needed - check device
    }
    
    func testDifferentEventsNotDebounced() async {
        await MainActor.run {
            feedbackManager.trigger(event: .taskCompleted)
            feedbackManager.trigger(event: .taskCreated)
            feedbackManager.trigger(event: .taskDeleted)
        }
        
        // All three should trigger (different events)
        // Manual verification needed - check device
    }
    
    // MARK: - Prepare Tests
    
    func testPrepareReducesLatency() async {
        await MainActor.run {
            feedbackManager.prepare(for: .taskCompleted)
            
            // Trigger immediately after prepare
            feedbackManager.trigger(event: .taskCompleted)
        }
        
        // Should feel more responsive
        // Manual verification needed - check device
    }
    
    // MARK: - Event Mapping Tests
    
    func testAllEventsHaveMapping() {
        let allEvents: [FeedbackManager.FeedbackEvent] = [
            .taskCompleted, .taskCreated, .taskDeleted,
            .timerStarted, .timerStopped, .timerCompleted,
            .navigationChanged, .errorOccurred, .successAction,
            .warningAction, .selectionChanged, .dataRefreshed,
            .itemDragged, .itemDropped
        ]
        
        // Ensure no crashes
        for event in allEvents {
            feedbackManager.trigger(event: event)
        }
    }
    
    // MARK: - Performance Tests
    
    func testFeedbackPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<100 {
                feedbackManager.trigger(event: .selectionChanged)
            }
        }
        
        // Should complete quickly even with debouncing
    }
}
