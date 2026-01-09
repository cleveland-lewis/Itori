import Foundation

#if canImport(FoundationModels)
    import FoundationModels
#endif

/// Apple Intelligence Provider (Foundation Models)
///
/// Deployment targets (from project settings):
/// - iOS: 26.1
/// - macOS: 14.0
/// Availability is gated by runtime OS version + framework availability.
public final class AppleIntelligenceProvider: AIProvider {
    public let name = "Apple Intelligence"

    public var capabilities: AICapabilities {
        AICapabilities(
            isOffline: true,
            supportsTools: true,
            supportsSchema: true,
            maxContextLength: 8192,
            supportedTasks: [
                .intentToAction,
                .summarize,
                .rewrite,
                .textCompletion,
                .chat
            ],
            estimatedLatency: 0.5
        )
    }

    public init() {}

    public struct Availability {
        let available: Bool
        let reason: String
    }

    public static func availability() -> Availability {
        #if canImport(FoundationModels)
            if #available(iOS 26.0, macOS 26.0, *) {
                #if os(iOS) || os(macOS)
                    if AppleFoundationClient.isAvailable() {
                        return Availability(available: true, reason: "Apple Foundation Models available")
                    }
                    return Availability(available: false, reason: "Apple Intelligence not available on this device")
                #else
                    return Availability(available: false, reason: "Unsupported OS for Apple Intelligence")
                #endif
            }
            return Availability(available: false, reason: "Requires iOS 26+ / macOS 26+")
        #else
            return Availability(available: false, reason: "FoundationModels framework not available in this SDK")
        #endif
    }

    public func generate(
        prompt: String,
        task _: AITaskKind,
        schema: [String: Any]?,
        temperature: Double
    ) async throws -> AIProviderResult {
        let availability = Self.availability()
        guard availability.available else {
            throw AIError.providerUnavailable("Apple Intelligence unavailable: \(availability.reason)")
        }

        let startTime = Date()

        #if canImport(FoundationModels)
            if #available(iOS 26.0, macOS 26.0, *) {
                let responseText = try await AppleFoundationClient.generate(prompt: prompt, temperature: temperature)
                let latency = Int(Date().timeIntervalSince(startTime) * 1000)
                return AIProviderResult(
                    text: responseText,
                    provider: name,
                    latencyMs: latency,
                    tokenCount: nil,
                    cached: false,
                    structuredData: schema != nil ? ["provider": "apple"] : nil
                )
            }
        #endif

        throw AIError.providerUnavailable("Apple Intelligence unavailable: \(availability.reason)")
    }

    public func isAvailable() async -> Bool {
        Self.availability().available
    }
}

#if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private enum AppleFoundationClient {
        static func isAvailable() -> Bool {
            SystemLanguageModel.default.isAvailable
        }

        static func generate(prompt: String, temperature _: Double) async throws -> String {
            let session = LanguageModelSession(model: .default)
            let response = try await session.respond(to: prompt)
            return response.content
        }
    }
#endif
