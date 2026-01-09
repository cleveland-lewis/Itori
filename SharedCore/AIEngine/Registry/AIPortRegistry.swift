import Foundation

public struct AIPortAvailability: Codable, Hashable, Sendable {
    public let port: AIPortID
    public let isAvailable: Bool
    public let bestProvider: AIProviderID?
    public let fallbackAvailable: Bool
    public let reasonCodes: [String]

    public init(
        port: AIPortID,
        isAvailable: Bool,
        bestProvider: AIProviderID?,
        fallbackAvailable: Bool,
        reasonCodes: [String] = []
    ) {
        self.port = port
        self.isAvailable = isAvailable
        self.bestProvider = bestProvider
        self.fallbackAvailable = fallbackAvailable
        self.reasonCodes = reasonCodes
    }
}

public final class AIPortRegistry: Sendable {
    private let providers: [AIEngineProvider]
    private let fallback: AIFallbackEngine
    private let privacyPolicy: AIPrivacyPolicy
    private let capabilityPolicy: AICapabilityPolicy

    public init(
        providers: [AIEngineProvider],
        fallback: AIFallbackEngine,
        privacyPolicy: AIPrivacyPolicy,
        capabilityPolicy: AICapabilityPolicy
    ) {
        self.providers = providers
        self.fallback = fallback
        self.privacyPolicy = privacyPolicy
        self.capabilityPolicy = capabilityPolicy
    }

    public func snapshot() -> [AIPortAvailability] {
        AIPortID.allCases.map { availability(for: $0) }
    }

    public func availability(for port: AIPortID) -> AIPortAvailability {
        guard capabilityPolicy.isPortEnabled(port) else {
            return .init(
                port: port,
                isAvailable: false,
                bestProvider: nil,
                fallbackAvailable: fallback.canFallback(for: port),
                reasonCodes: ["disabledByPolicy"]
            )
        }

        if !AppSettingsModel.shared.enableLLMAssistance {
            let fallbackAvailable = fallback.canFallback(for: port)
            return .init(
                port: port,
                isAvailable: fallbackAvailable,
                bestProvider: nil,
                fallbackAvailable: fallbackAvailable,
                reasonCodes: ["llmDisabled"]
            )
        }

        let viable = providers.filter {
            $0.isAvailable() &&
                $0.supports(port: port) &&
                privacyPolicy.allows(provider: $0.id, for: .normal)
        }

        if let best = viable.first {
            return .init(
                port: port,
                isAvailable: true,
                bestProvider: best.id,
                fallbackAvailable: fallback.canFallback(for: port),
                reasonCodes: ["provider=\(best.id.rawValue)"]
            )
        }

        var reasons: [String] = []
        if providers.allSatisfy({ !$0.supports(port: port) }) { reasons.append("noProviderSupportsPort") }
        if providers.allSatisfy({ !$0.isAvailable() }) { reasons.append("noProviderAvailable") }
        if !fallback.canFallback(for: port) { reasons.append("noFallback") }

        return .init(
            port: port,
            isAvailable: fallback.canFallback(for: port),
            bestProvider: nil,
            fallbackAvailable: fallback.canFallback(for: port),
            reasonCodes: reasons
        )
    }
}
