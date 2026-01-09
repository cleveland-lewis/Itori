import XCTest
@testable import Itori

final class OnboardingStateTests: XCTestCase {
    func testNeverSeenState() {
        let state = OnboardingState.neverSeen
        XCTAssertTrue(state.shouldShowOnboarding)
        XCTAssertNil(state.currentStepId)
        XCTAssertEqual(state.debugDescription, "Never Seen")
    }

    func testInProgressState() {
        let state = OnboardingState.inProgress(stepId: "step-2")
        XCTAssertTrue(state.shouldShowOnboarding)
        XCTAssertEqual(state.currentStepId, "step-2")
        XCTAssertEqual(state.debugDescription, "In Progress (step: step-2)")
    }

    func testCompletedState() {
        let state = OnboardingState.completed
        XCTAssertFalse(state.shouldShowOnboarding)
        XCTAssertNil(state.currentStepId)
        XCTAssertEqual(state.debugDescription, "Completed")
    }

    func testSkippedState() {
        let state = OnboardingState.skipped
        XCTAssertFalse(state.shouldShowOnboarding)
        XCTAssertNil(state.currentStepId)
        XCTAssertEqual(state.debugDescription, "Skipped")
    }

    // MARK: - Codable Tests

    func testNeverSeenCodable() throws {
        let state = OnboardingState.neverSeen
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(OnboardingState.self, from: data)
        XCTAssertEqual(state, decoded)
    }

    func testInProgressCodable() throws {
        let state = OnboardingState.inProgress(stepId: "onboarding-courses")
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(OnboardingState.self, from: data)
        XCTAssertEqual(state, decoded)
        XCTAssertEqual(decoded.currentStepId, "onboarding-courses")
    }

    func testCompletedCodable() throws {
        let state = OnboardingState.completed
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(OnboardingState.self, from: data)
        XCTAssertEqual(state, decoded)
    }

    func testSkippedCodable() throws {
        let state = OnboardingState.skipped
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(OnboardingState.self, from: data)
        XCTAssertEqual(state, decoded)
    }

    // MARK: - Persistence Tests

    func testDefaultOnboardingState() {
        let settings = AppSettingsModel()
        // Default should be neverSeen when no data exists
        XCTAssertEqual(settings.onboardingState, .neverSeen)
    }

    func testPersistNeverSeen() {
        let settings = AppSettingsModel()
        settings.onboardingState = .neverSeen
        XCTAssertEqual(settings.onboardingState, .neverSeen)
    }

    func testPersistInProgress() {
        let settings = AppSettingsModel()
        settings.onboardingState = .inProgress(stepId: "step-3")
        XCTAssertEqual(settings.onboardingState, .inProgress(stepId: "step-3"))
        XCTAssertEqual(settings.onboardingState.currentStepId, "step-3")
    }

    func testPersistCompleted() {
        let settings = AppSettingsModel()
        settings.onboardingState = .completed
        XCTAssertEqual(settings.onboardingState, .completed)
    }

    func testPersistSkipped() {
        let settings = AppSettingsModel()
        settings.onboardingState = .skipped
        XCTAssertEqual(settings.onboardingState, .skipped)
    }

    func testOnboardingStateTransitions() {
        let settings = AppSettingsModel()

        // Start: neverSeen
        XCTAssertEqual(settings.onboardingState, .neverSeen)
        XCTAssertTrue(settings.onboardingState.shouldShowOnboarding)

        // Transition to inProgress
        settings.onboardingState = .inProgress(stepId: "step-1")
        XCTAssertEqual(settings.onboardingState.currentStepId, "step-1")
        XCTAssertTrue(settings.onboardingState.shouldShowOnboarding)

        // Update progress
        settings.onboardingState = .inProgress(stepId: "step-2")
        XCTAssertEqual(settings.onboardingState.currentStepId, "step-2")

        // Complete
        settings.onboardingState = .completed
        XCTAssertFalse(settings.onboardingState.shouldShowOnboarding)
        XCTAssertNil(settings.onboardingState.currentStepId)
    }

    func testOnboardingStateSkipFlow() {
        let settings = AppSettingsModel()

        // Start at step 1
        settings.onboardingState = .inProgress(stepId: "step-1")
        XCTAssertTrue(settings.onboardingState.shouldShowOnboarding)

        // User skips
        settings.onboardingState = .skipped
        XCTAssertFalse(settings.onboardingState.shouldShowOnboarding)
        XCTAssertEqual(settings.onboardingState, .skipped)
    }

    // MARK: - Round-trip Encoding Tests

    func testSettingsEncodingWithOnboardingState() throws {
        let settings = AppSettingsModel()
        settings.onboardingState = .inProgress(stepId: "onboarding-planner")

        // Encode settings
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)

        // Decode settings
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppSettingsModel.self, from: data)

        // Verify onboarding state persisted
        XCTAssertEqual(decoded.onboardingState, .inProgress(stepId: "onboarding-planner"))
        XCTAssertEqual(decoded.onboardingState.currentStepId, "onboarding-planner")
    }
}
