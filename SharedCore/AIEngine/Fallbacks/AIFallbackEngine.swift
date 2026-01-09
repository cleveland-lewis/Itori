import Foundation

public protocol AIFallbackEngine: Sendable {
    func canFallback(for port: AIPortID) -> Bool

    func executeFallback<P: AIPort>(
        _ portType: P.Type,
        input: P.Input,
        context: AIRequestContext
    ) async throws -> AIResult<P.Output>
}

public struct NoOpFallbackEngine: AIFallbackEngine {
    public init() {}

    public func canFallback(for _: AIPortID) -> Bool {
        false
    }

    public func executeFallback<P: AIPort>(
        _: P.Type,
        input _: P.Input,
        context _: AIRequestContext
    ) async throws -> AIResult<P.Output> {
        throw AIEngineError.capabilityUnavailable(port: P.id)
    }
}
