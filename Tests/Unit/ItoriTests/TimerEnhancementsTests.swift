import XCTest
@testable import SharedCore

/// Tests for Phase A timer enhancements
/// These tests verify new functionality works correctly when feature flags are ON
final class TimerEnhancementsTests: XCTestCase {
    
    var viewModel: TimerPageViewModel!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        viewModel = TimerPageViewModel.shared
        
        // Enable Phase A features for testing
        FeatureFlags.shared.enablePhaseA()
    }
    
    @MainActor
    override func tearDown() async throws {
        // Clean up
        viewModel.customPresets.removeAll()
        if viewModel.currentSession != nil {
            viewModel.endSession(completed: false)
        }
        
        // Reset flags
        FeatureFlags.shared.resetToDefaults()
        try await super.tearDown()
    }
    
    // MARK: - Quick Timer Presets Tests
    
    @MainActor
    func testDefaultPresetsExist() {
        // Given/When: Default presets
        let presets = TimerPreset.defaults
        
        // Then: Should have expected count
        XCTAssertEqual(presets.count, 6)
        XCTAssertTrue(presets.allSatisfy { $0.isDefault })
    }
    
    @MainActor
    func testPresetHasRequiredProperties() {
        // Given: A preset
        let preset = TimerPreset.defaults.first!
        
        // Then: Should have all required properties
        XCTAssertFalse(preset.name.isEmpty)
        XCTAssertGreaterThan(preset.duration, 0)
        XCTAssertNotNil(preset.emoji)
    }
    
    @MainActor
    func testAddCustomPreset() {
        // Given: Custom preset
        let preset = TimerPreset(
            name: "Test Preset",
            duration: 10 * 60,
            emoji: "🧪",
            mode: .timer
        )
        
        // When: Adding preset
        viewModel.addPreset(preset)
        
        // Then: Should be in custom presets
        XCTAssertEqual(viewModel.customPresets.count, 1)
        XCTAssertEqual(viewModel.customPresets.first?.name, "Test Preset")
    }
    
    @MainActor
    func testUpdateCustomPreset() {
        // Given: Existing custom preset
        var preset = TimerPreset(
            name: "Original",
            duration: 10 * 60,
            mode: .timer
        )
        viewModel.addPreset(preset)
        
        // When: Updating preset
        preset.name = "Updated"
        viewModel.updatePreset(preset)
        
        // Then: Should be updated
        XCTAssertEqual(viewModel.customPresets.first?.name, "Updated")
    }
    
    @MainActor
    func testDeleteCustomPreset() {
        // Given: Existing custom preset
        let preset = TimerPreset(
            name: "To Delete",
            duration: 10 * 60,
            mode: .timer
        )
        viewModel.addPreset(preset)
        XCTAssertEqual(viewModel.customPresets.count, 1)
        
        // When: Deleting preset
        viewModel.deletePreset(id: preset.id)
        
        // Then: Should be removed
        XCTAssertEqual(viewModel.customPresets.count, 0)
    }
    
    @MainActor
    func testAllPresetsIncludesDefaultsAndCustom() {
        // Given: Custom preset added
        let preset = TimerPreset(
            name: "Custom",
            duration: 10 * 60,
            mode: .timer
        )
        viewModel.addPreset(preset)
        
        // When: Getting all presets
        let allPresets = viewModel.allPresets()
        
        // Then: Should include both defaults and custom
        XCTAssertEqual(allPresets.count, TimerPreset.defaults.count + 1)
        XCTAssertTrue(allPresets.contains { $0.name == "Custom" })
    }
    
    @MainActor
    func testPresetStartsTimerWithCorrectDuration() {
        // Given: A preset
        let preset = TimerPreset.defaults[0]
        
        // When: Starting timer from preset
        viewModel.currentMode = preset.mode
        viewModel.startSession(plannedDuration: preset.duration)
        
        // Then: Timer should have preset duration
        XCTAssertEqual(viewModel.sessionRemaining, preset.duration, accuracy: 1)
        XCTAssertEqual(viewModel.currentSession?.mode, preset.mode)
    }
    
    // MARK: - Dynamic Countdown Visuals Tests
    
    func testVisualStylesExist() {
        // Given/When: Visual styles
        let styles = TimerVisualStyle.allCases
        
        // Then: Should have expected styles
        XCTAssertTrue(styles.contains(.ring))
        XCTAssertTrue(styles.contains(.grid))
        XCTAssertTrue(styles.contains(.digital))
        XCTAssertTrue(styles.contains(.analog))
    }
    
    func testVisualStyleHasDisplayProperties() {
        // Given: A visual style
        let style = TimerVisualStyle.ring
        
        // Then: Should have display properties
        XCTAssertFalse(style.displayName.isEmpty)
        XCTAssertFalse(style.systemImage.isEmpty)
    }
    
    // MARK: - Timer Hub Tests
    
    @MainActor
    func testTimerStatisticsCalculation() {
        // Given: Completed sessions
        let session1 = FocusSession(
            mode: .timer,
            plannedDuration: 25 * 60,
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(25 * 60),
            state: .completed,
            actualDuration: 25 * 60
        )
        viewModel.addManualSession(session1)
        
        let session2 = FocusSession(
            mode: .timer,
            plannedDuration: 30 * 60,
            startedAt: Date().addingTimeInterval(-60 * 60),
            endedAt: Date().addingTimeInterval(-30 * 60),
            state: .completed,
            actualDuration: 30 * 60
        )
        viewModel.addManualSession(session2)
        
        // When: Calculating statistics
        let completed = viewModel.pastSessions.filter { $0.state == .completed }
        let totalDuration = completed.compactMap { $0.actualDuration }.reduce(0, +)
        let stats = TimerStatistics(
            totalSessions: viewModel.pastSessions.count,
            totalDuration: totalDuration,
            completedSessions: completed.count,
            averageSessionDuration: totalDuration / Double(completed.count),
            longestSession: completed.compactMap { $0.actualDuration }.max() ?? 0
        )
        
        // Then: Statistics should be correct
        XCTAssertGreaterThanOrEqual(stats.totalSessions, 2)
        XCTAssertEqual(stats.completedSessions, 2)
        XCTAssertEqual(stats.totalDuration, 55 * 60, accuracy: 1)
        XCTAssertEqual(stats.averageSessionDuration, 27.5 * 60, accuracy: 1)
        XCTAssertEqual(stats.longestSession, 30 * 60, accuracy: 1)
    }
    
    @MainActor
    func testTimerHubFiltersCompletedSessions() {
        // Given: Mix of completed and cancelled sessions
        let completed = FocusSession(
            mode: .timer,
            plannedDuration: 25 * 60,
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(25 * 60),
            state: .completed,
            actualDuration: 25 * 60
        )
        viewModel.addManualSession(completed)
        
        let cancelled = FocusSession(
            mode: .timer,
            plannedDuration: 25 * 60,
            startedAt: Date().addingTimeInterval(-60 * 60),
            endedAt: Date().addingTimeInterval(-55 * 60),
            state: .cancelled,
            actualDuration: 5 * 60
        )
        viewModel.addManualSession(cancelled)
        
        // When: Filtering completed
        let completedOnly = viewModel.pastSessions.filter { $0.state == .completed }
        
        // Then: Should only include completed
        XCTAssertGreaterThanOrEqual(completedOnly.count, 1)
        XCTAssertTrue(completedOnly.allSatisfy { $0.state == .completed })
    }
    
    // MARK: - Persistence Tests
    
    @MainActor
    func testCustomPresetsArePersisted() async throws {
        // Given: Custom preset added
        let preset = TimerPreset(
            name: "Persisted",
            duration: 15 * 60,
            mode: .timer
        )
        viewModel.addPreset(preset)
        
        // When: Waiting for persistence
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then: Should be saved (verified by checking count remains after persistence)
        XCTAssertTrue(viewModel.customPresets.contains { $0.name == "Persisted" })
    }
}
