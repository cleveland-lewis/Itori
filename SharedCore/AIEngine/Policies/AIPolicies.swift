import Foundation

public protocol AIPrivacyPolicy: Sendable {
    func allows(provider: AIProviderID, for privacy: AIPrivacyLevel) -> Bool
    func redactIfNeeded(inputJSON: Data, privacy: AIPrivacyLevel) throws -> Data
}

public protocol AIRateLimitPolicy: Sendable {
    func allows(port: AIPortID) -> Bool
}

public protocol AICapabilityPolicy: Sendable {
    func isPortEnabled(_ port: AIPortID) -> Bool
}

public struct DefaultPrivacyPolicy: AIPrivacyPolicy {
    public init() {}

    public func allows(provider: AIProviderID, for privacy: AIPrivacyLevel) -> Bool {
        switch privacy {
        case .normal:
            true
        case .sensitive:
            provider != .bringYourOwn
        case .onDeviceOnly:
            provider == .appleFoundationAI || provider == .localCoreML
        }
    }

    public func redactIfNeeded(inputJSON: Data, privacy _: AIPrivacyLevel) throws -> Data {
        // Placeholder for future redaction logic; pass-through by default.
        inputJSON
    }
}

public struct DefaultRateLimitPolicy: AIRateLimitPolicy {
    public init() {}
    public func allows(port _: AIPortID) -> Bool { true }
}

public struct DefaultCapabilityPolicy: AICapabilityPolicy {
    public init() {}
    public func isPortEnabled(_: AIPortID) -> Bool { true }
}
