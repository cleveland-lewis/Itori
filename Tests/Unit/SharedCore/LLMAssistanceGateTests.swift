import Testing
import Foundation
@testable import Itori

@MainActor
struct LLMAssistanceGateTests {
    @Test func testLLMAssistanceDisabledSkipsProviders() async throws {
        let original = AppSettingsModel.shared.enableLLMAssistance
        AppSettingsModel.shared.enableLLMAssistance = false
        defer { AppSettingsModel.shared.enableLLMAssistance = original }

        let provider = CallTrackingProvider()
        let engine = AIEngine(
            providers: [provider],
            fallback: TestFallbackEngine()
        )

        let result = try await engine.request(
            TestPort.self,
            input: .init(value: "test"),
            context: AIRequestContext(featureStateVersion: 42)
        )

        #expect(provider.executeCallCount == 0)
        #expect(result.provenance.primaryProvider == .fallbackHeuristic)
        #expect(result.diagnostic.reasonCodes.contains("llm_disabled"))
        #expect(result.metadata.featureStateVersion == 42)
    }
}

private enum TestPort: AIPort {
    static let id: AIPortID = .estimateTaskDuration
    static let name: String = "LLM Assist Gate Test"
    static let privacyRequirement: AIPrivacyLevel = .normal

    struct Input: Codable, Sendable {
        let value: String
    }

    struct Output: Codable, Sendable {
        let value: String
    }

    static func validate(input: Input) throws {}
    static func validate(output: Output) throws {}
}

private struct TestFallbackEngine: AIFallbackEngine {
    func canFallback(for port: AIPortID) -> Bool { true }

    func executeFallback<P: AIPort>(
        _ portType: P.Type,
        input: P.Input,
        context: AIRequestContext
    ) async throws -> AIResult<P.Output> {
        guard let output = TestPort.Output(value: "fallback") as? P.Output else {
            throw AIEngineError.capabilityUnavailable(port: P.id)
        }

        return AIResult(
            output: output,
            confidence: AIConfidence(1.0),
            provenance: .fallback(.fallbackHeuristic),
            diagnostic: AIDiagnostic(),
            metadata: AIResultMetadata(
                inputHash: "fallback",
                computedAt: Date(),
                featureStateVersion: context.featureStateVersion
            )
        )
    }
}

private final class CallTrackingProvider: AIEngineProvider, @unchecked Sendable {
    let id: AIProviderID = .localCoreML
    private let lock = NSLock()
    private var _executeCallCount = 0

    var executeCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _executeCallCount
    }

    func isAvailable() -> Bool { true }
    func supports(port: AIPortID) -> Bool { true }

    func execute(
        port: AIPortID,
        inputJSON: Data,
        context: AIRequestContext
    ) async throws -> (outputJSON: Data, diagnostic: AIDiagnostic) {
        lock.lock()
        _executeCallCount += 1
        lock.unlock()
        throw AIEngineError.providerUnavailable(provider: id)
    }
}
