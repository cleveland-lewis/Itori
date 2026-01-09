import XCTest
@testable import Itori

/// Tests to verify the global AI privacy kill switch (Issue #390)
/// Ensures that when AI is disabled, NO AI calls can occur
@MainActor
final class AIPrivacyGateTests: XCTestCase {
    var router: AIRouter!
    var settings: AppSettingsModel!
    var originalAIEnabled: Bool = false

    override func setUp() async throws {
        try await super.setUp()

        settings = AppSettingsModel.shared
        originalAIEnabled = settings.aiEnabled

        router = AIRouter(mode: .auto)
    }

    override func tearDown() async throws {
        // Restore original state
        settings.aiEnabled = originalAIEnabled
        settings.save()

        try await super.tearDown()
    }

    // MARK: - Privacy Gate Tests

    func testAIDisabled_GenerateThrowsDisabledByPrivacy() async throws {
        // Given AI is disabled
        settings.aiEnabled = false
        settings.save()

        // When attempting to generate
        do {
            _ = try await router.generate(
                prompt: "Test prompt",
                taskKind: .syllabusParser,
                options: .default
            )
            XCTFail("Expected disabledByPrivacy error but generation succeeded")
        } catch let error as AIError {
            // Then it should throw disabledByPrivacy
            XCTAssertEqual(error, .disabledByPrivacy, "Expected disabledByPrivacy error")
        } catch {
            XCTFail("Expected AIError.disabledByPrivacy but got: \(error)")
        }
    }

    func testAIEnabled_GenerateCanProceed() async throws {
        // Given AI is enabled
        settings.aiEnabled = true
        settings.save()

        // Note: This test will fail if no providers are available
        // In production, we expect at least one provider (local) to be available

        // When attempting to generate
        // We expect either success or providerUnavailable (not disabledByPrivacy)
        do {
            _ = try await router.generate(
                prompt: "Test prompt",
                taskKind: .syllabusParser,
                options: .default
            )
            // Success - test passed
        } catch let error as AIError {
            // Should not be disabledByPrivacy
            XCTAssertNotEqual(error, .disabledByPrivacy, "Should not throw disabledByPrivacy when AI is enabled")

            // Other errors are acceptable (providerUnavailable, networkError, etc.)
            print("ℹ️ AI generation failed with acceptable error: \(error)")
        }
    }

    func testAIDisabled_MultipleTaskKindsAllBlocked() async throws {
        // Given AI is disabled
        settings.aiEnabled = false
        settings.save()

        let taskKinds: [AITaskKind] = [
            .syllabusParser,
            .testGenerator,
            .summaryGenerator,
            .questionAnswering,
            .codeCompletion,
            .generalAssistance
        ]

        // When attempting to generate for each task kind
        for taskKind in taskKinds {
            do {
                _ = try await router.generate(
                    prompt: "Test for \(taskKind.rawValue)",
                    taskKind: taskKind,
                    options: .default
                )
                XCTFail("Expected disabledByPrivacy for \(taskKind.rawValue)")
            } catch let error as AIError {
                // Then all should be blocked
                XCTAssertEqual(error, .disabledByPrivacy, "Expected disabledByPrivacy for \(taskKind.rawValue)")
            } catch {
                XCTFail("Expected AIError.disabledByPrivacy for \(taskKind.rawValue) but got: \(error)")
            }
        }
    }

    func testAIToggle_EnableAfterDisable() async throws {
        // Given AI is disabled
        settings.aiEnabled = false
        settings.save()

        // When checking the state
        XCTAssertFalse(settings.aiEnabled, "AI should be disabled")

        // And we try to generate
        do {
            _ = try await router.generate(prompt: "Test", taskKind: .generalAssistance)
            XCTFail("Expected disabledByPrivacy")
        } catch let error as AIError {
            XCTAssertEqual(error, .disabledByPrivacy)
        }

        // When re-enabling AI
        settings.aiEnabled = true
        settings.save()

        // Then it should be enabled
        XCTAssertTrue(settings.aiEnabled, "AI should be enabled")

        // And generation attempts should not throw disabledByPrivacy
        do {
            _ = try await router.generate(prompt: "Test", taskKind: .generalAssistance)
        } catch let error as AIError {
            XCTAssertNotEqual(error, .disabledByPrivacy, "Should not be disabled after re-enabling")
        }
    }

    func testSettings_AIEnabledDefaultValue() {
        // The default should be false (disabled by default per Issue #175.H)
        let freshSettings = AppSettingsModel()
        XCTAssertFalse(freshSettings.aiEnabled, "AI should be disabled by default for privacy")
    }

    func testSettings_AIEnabledPersistence() {
        // Given we change the setting
        let originalValue = settings.aiEnabled
        settings.aiEnabled = !originalValue
        settings.save()

        // When we read it back
        let readValue = settings.aiEnabled

        // Then it should match
        XCTAssertEqual(readValue, !originalValue, "AI enabled should persist")

        // Cleanup
        settings.aiEnabled = originalValue
        settings.save()
    }

    // MARK: - Edge Cases

    func testAIDisabled_EmptyPrompt() async throws {
        settings.aiEnabled = false
        settings.save()

        do {
            _ = try await router.generate(prompt: "", taskKind: .generalAssistance)
            XCTFail("Expected disabledByPrivacy")
        } catch let error as AIError {
            XCTAssertEqual(error, .disabledByPrivacy, "Privacy gate should block even empty prompts")
        }
    }

    func testAIDisabled_CustomOptions() async throws {
        settings.aiEnabled = false
        settings.save()

        let customOptions = AIGenerateOptions(
            temperature: 0.5,
            maxTokens: 100,
            strictJSON: true,
            systemPrompt: "Custom system prompt"
        )

        do {
            _ = try await router.generate(
                prompt: "Test",
                taskKind: .generalAssistance,
                options: customOptions
            )
            XCTFail("Expected disabledByPrivacy")
        } catch let error as AIError {
            XCTAssertEqual(error, .disabledByPrivacy, "Privacy gate should block regardless of options")
        }
    }

    // MARK: - Performance

    func testPrivacyGate_Performance() throws {
        settings.aiEnabled = false
        settings.save()

        // Privacy gate check should be instant (< 0.001 seconds)
        measure {
            Task {
                do {
                    _ = try await router.generate(prompt: "Test", taskKind: .generalAssistance)
                } catch {
                    // Expected
                }
            }
        }
    }
}

/// Tests for AIError enum
final class AIErrorTests: XCTestCase {
    func testAIError_DisabledByPrivacy_Exists() {
        // Ensure the error case exists
        let error = AIError.disabledByPrivacy
        XCTAssertNotNil(error)
    }

    func testAIError_DisabledByPrivacy_Description() {
        let error = AIError.disabledByPrivacy
        let description = error.localizedDescription
        XCTAssertFalse(description.isEmpty, "Error should have a description")
        XCTAssertTrue(
            description.localizedCaseInsensitiveContains("privacy") ||
                description.localizedCaseInsensitiveContains("disabled"),
            "Description should mention privacy or disabled: '\(description)'"
        )
    }

    func testAIError_AllCasesHaveDescriptions() {
        // Ensure all error cases have meaningful descriptions
        let errors: [AIError] = [
            .providerUnavailable,
            .networkError("test"),
            .invalidResponse,
            .rateLimitExceeded,
            .disabledByPrivacy
        ]

        for error in errors {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Error \(error) should have a description")
        }
    }
}

/// Integration tests for privacy gate
@MainActor
final class AIPrivacyGateIntegrationTests: XCTestCase {
    func testPrivacySettings_ControlsAIRouter() async throws {
        let settings = AppSettingsModel.shared
        let router = AIRouter(mode: .auto)
        let originalState = settings.aiEnabled

        // Test disable
        settings.aiEnabled = false
        settings.save()

        do {
            _ = try await router.generate(prompt: "Test", taskKind: .generalAssistance)
            XCTFail("Expected error when disabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .disabledByPrivacy)
        }

        // Test enable
        settings.aiEnabled = true
        settings.save()

        do {
            _ = try await router.generate(prompt: "Test", taskKind: .generalAssistance)
            // May succeed or fail with other errors, but not disabledByPrivacy
        } catch let error as AIError {
            XCTAssertNotEqual(error, .disabledByPrivacy)
        }

        // Restore
        settings.aiEnabled = originalState
        settings.save()
    }

    func testPrivacyGate_NoProviderCallsWhenDisabled() async throws {
        // This is a smoke test to ensure no providers are invoked
        let settings = AppSettingsModel.shared
        let router = AIRouter(mode: .auto)

        settings.aiEnabled = false
        settings.save()

        // Register a test provider that should never be called
        var providerWasCalled = false
        let testProvider = TestAIProvider {
            providerWasCalled = true
            return AIResult(text: "Should not be returned", metadata: [:])
        }

        router.registerProvider(testProvider)

        do {
            _ = try await router.generate(prompt: "Test", taskKind: .generalAssistance)
            XCTFail("Expected disabledByPrivacy")
        } catch {
            // Expected
        }

        XCTAssertFalse(providerWasCalled, "Provider should not be called when AI is disabled")
    }
}

// MARK: - Test Helper

/// Mock AI provider for testing
private class TestAIProvider: AIProvider {
    let name = "TestProvider"
    let generateHandler: () -> AIResult

    init(generateHandler: @escaping () -> AIResult) {
        self.generateHandler = generateHandler
    }

    func generate(prompt _: String, taskKind _: AITaskKind, options _: AIGenerateOptions) async throws -> AIResult {
        generateHandler()
    }

    func isAvailable() -> Bool {
        true
    }
}
