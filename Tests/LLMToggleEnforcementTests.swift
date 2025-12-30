//
// LLMToggleEnforcementTests.swift
// CRITICAL: Tests that verify toggle OFF => 0 provider attempts
//

import XCTest
@testable import SharedCore

/// Spy provider that counts perform() invocations
final class SpyAIProvider: AIEngineProvider {
    let id: AIEngineProviderID = .custom("spy_provider")
    var performCallCount = 0
    var lastPortID: AIPortID?
    
    func isAvailable() -> Bool {
        return true
    }
    
    func supports(port: AIPortID) -> Bool {
        return true
    }
    
    func execute(port: AIPortID, inputJSON: Data, context: AIRequestContext) async throws -> (Data, AIDiagnostic) {
        performCallCount += 1
        lastPortID = port
        
        // Return dummy response
        let response = ["result": "spy_response"]
        let data = try JSONEncoder().encode(response)
        let diag = AIDiagnostic(reasonCodes: ["spy"], latencyMs: 10, notes: "spy call")
        return (data, diag)
    }
}

/// Tests proving that LLM toggle OFF => 0 provider attempts
@MainActor
final class LLMToggleDisablesProviderAttemptsTests: XCTestCase {
    
    var spyProvider: SpyAIProvider!
    var engine: AIEngine!
    var originalToggleState: Bool = true
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Save original toggle state
        originalToggleState = AppSettingsModel.shared.enableLLMAssistance
        
        // Create spy provider
        spyProvider = SpyAIProvider()
        
        // Create test engine with spy
        let testFallback = TestFallbackEngine()
        engine = AIEngine(
            providers: [spyProvider],
            fallback: testFallback
        )
        
        // Reset health monitor counters
        await AIEngine.healthMonitor.resetLLMCounters()
    }
    
    override func tearDown() async throws {
        // Restore original toggle state
        AppSettingsModel.shared.enableLLMAssistance = originalToggleState
        
        try await super.tearDown()
    }
    
    // MARK: - Core Enforcement Tests
    
    func testToggleOFF_ZeroProviderAttempts_SinglePort() async throws {
        // Arrange: Disable LLM toggle
        AppSettingsModel.shared.enableLLMAssistance = false
        
        // Act: Call a port multiple times
        for _ in 0..<10 {
            do {
                _ = try await engine.request(
                    DurationEstimationPort.self,
                    input: DurationEstimationInput(
                        title: "Test Assignment",
                        description: "Test description",
                        type: .homework,
                        importance: 0.5,
                        difficulty: 0.5
                    )
                )
            } catch {
                // Fallback might throw if not available, that's OK
            }
        }
        
        // Assert: Spy provider never called
        XCTAssertEqual(spyProvider.performCallCount, 0,
                       "Provider should NEVER be called when toggle is OFF")
        
        // Assert: Health monitor shows zero attempts
        let counters = await AIEngine.healthMonitor.getLLMCounters()
        XCTAssertEqual(counters.providerAttemptCountTotal, 0,
                       "Health monitor should show 0 provider attempts")
        
        // Assert: Suppression count increased
        XCTAssertGreaterThan(counters.suppressedByLLMToggleCount, 0,
                            "Suppression count should increase")
    }
    
    func testToggleOFF_ZeroProviderAttempts_MultiplePorts() async throws {
        // Arrange: Disable LLM toggle
        AppSettingsModel.shared.enableLLMAssistance = false
        
        let ports: [any AIPort.Type] = [
            DurationEstimationPort.self,
            // Add more ports as needed
        ]
        
        // Act: Call multiple ports
        for portType in ports {
            for _ in 0..<5 {
                do {
                    if portType == DurationEstimationPort.self {
                        _ = try await engine.request(
                            DurationEstimationPort.self,
                            input: DurationEstimationInput(
                                title: "Test",
                                description: "Test",
                                type: .homework,
                                importance: 0.5,
                                difficulty: 0.5
                            )
                        )
                    }
                } catch {
                    // Expected - fallback might not be available
                }
            }
        }
        
        // Assert: Zero provider attempts
        XCTAssertEqual(spyProvider.performCallCount, 0)
        
        let counters = await AIEngine.healthMonitor.getLLMCounters()
        XCTAssertEqual(counters.providerAttemptCountTotal, 0)
    }
    
    func testToggleOFF_FallbackCountIncreases() async throws {
        // Arrange: Disable LLM toggle
        AppSettingsModel.shared.enableLLMAssistance = false
        
        // Act: Call port (should use fallback if available)
        do {
            _ = try await engine.request(
                DurationEstimationPort.self,
                input: DurationEstimationInput(
                    title: "Test",
                    description: "Test",
                    type: .homework,
                    importance: 0.5,
                    difficulty: 0.5
                )
            )
        } catch {
            // Expected if fallback not available
        }
        
        // Assert: Fallback-only count increased
        let counters = await AIEngine.healthMonitor.getLLMCounters()
        XCTAssertGreaterThan(counters.fallbackOnlyCount, 0,
                            "Fallback-only count should increase")
    }
    
    func testToggleON_ProviderAttemptsAllowed() async throws {
        // Arrange: Enable LLM toggle
        AppSettingsModel.shared.enableLLMAssistance = true
        
        // Act: Call port
        do {
            _ = try await engine.request(
                DurationEstimationPort.self,
                input: DurationEstimationInput(
                    title: "Test",
                    description: "Test",
                    type: .homework,
                    importance: 0.5,
                    difficulty: 0.5
                )
            )
        } catch {
            // May fail for other reasons
        }
        
        // Assert: Provider can be called (count > 0)
        let counters = await AIEngine.healthMonitor.getLLMCounters()
        // Note: Actual count depends on provider availability and other policies
        // The key is that it's NOT blocked by the toggle
        XCTAssertEqual(counters.suppressedByLLMToggleCount, 0,
                       "Should not suppress when toggle is ON")
    }
    
    // MARK: - Stress Test (Chaos)
    
    func testToggleOFF_HeavyUsage_StillZeroAttempts() async throws {
        // Arrange: Disable LLM toggle
        AppSettingsModel.shared.enableLLMAssistance = false
        
        // Act: Simulate heavy usage (1000+ calls)
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<1000 {
                group.addTask {
                    do {
                        _ = try await self.engine.request(
                            DurationEstimationPort.self,
                            input: DurationEstimationInput(
                                title: "Stress Test",
                                description: "Heavy load",
                                type: .homework,
                                importance: 0.5,
                                difficulty: 0.5
                            )
                        )
                    } catch {
                        // Expected
                    }
                }
            }
        }
        
        // Assert: Still zero provider attempts
        XCTAssertEqual(spyProvider.performCallCount, 0,
                       "Even under heavy load, provider should NEVER be called when toggle is OFF")
        
        let counters = await AIEngine.healthMonitor.getLLMCounters()
        XCTAssertEqual(counters.providerAttemptCountTotal, 0,
                       "Health monitor should show 0 attempts even after 1000+ requests")
    }
    
    // MARK: - Provenance Verification
    
    func testToggleOFF_ResultHasFallbackProvenance() async throws {
        // Arrange: Disable LLM toggle
        AppSettingsModel.shared.enableLLMAssistance = false
        
        // Act: Call port that supports fallback
        let result = try await engine.request(
            DurationEstimationPort.self,
            input: DurationEstimationInput(
                title: "Test",
                description: "Test",
                type: .homework,
                importance: 0.5,
                difficulty: 0.5
            )
        )
        
        // Assert: Provenance indicates fallback
        switch result.provenance {
        case .fallback(let reason):
            XCTAssertEqual(reason, "llm_disabled",
                          "Provenance should indicate LLM disabled")
        default:
            XCTFail("Expected fallback provenance when toggle is OFF")
        }
        
        // Assert: Reason codes include suppression
        XCTAssertTrue(result.diagnostic.reasonCodes.contains("llm_disabled"),
                     "Diagnostic should include llm_disabled reason code")
    }
}

// MARK: - Test Fallback Engine

private final class TestFallbackEngine: AIFallbackEngine {
    func canFallback(for port: AIPortID) -> Bool {
        return true
    }
    
    func executeFallback<P: AIPort>(
        _ portType: P.Type,
        input: P.Input,
        context: AIRequestContext
    ) async throws -> AIResult<P.Output> {
        // Return a dummy result
        // This is simplified - real fallback would produce proper output
        throw AIEngineError.capabilityUnavailable(port: P.id)
    }
}

// MARK: - Performance Tests

extension LLMToggleDisablesProviderAttemptsTests {
    
    func testToggleOFF_PerformanceOverhead() async throws {
        // Arrange
        AppSettingsModel.shared.enableLLMAssistance = false
        
        // Measure: Time for 100 suppressed calls
        measure {
            Task {
                for _ in 0..<100 {
                    do {
                        _ = try await self.engine.request(
                            DurationEstimationPort.self,
                            input: DurationEstimationInput(
                                title: "Perf Test",
                                description: "Performance",
                                type: .homework,
                                importance: 0.5,
                                difficulty: 0.5
                            )
                        )
                    } catch {
                        // Expected
                    }
                }
            }
        }
        
        // Assert: Still zero attempts
        XCTAssertEqual(spyProvider.performCallCount, 0)
    }
}
