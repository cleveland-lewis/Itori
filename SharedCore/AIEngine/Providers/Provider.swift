import Foundation

public protocol AIEngineProvider: Sendable {
    var id: AIProviderID { get }

    func isAvailable() -> Bool

    func supports(port: AIPortID) -> Bool

    func execute(
        port: AIPortID,
        inputJSON: Data,
        context: AIRequestContext
    ) async throws -> (outputJSON: Data, diagnostic: AIDiagnostic)
}
