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
            return true
        case .sensitive:
            return provider != .bringYourOwn
        case .onDeviceOnly:
            return provider == .appleFoundationAI || provider == .localCoreML
        }
    }

    public func redactIfNeeded(inputJSON: Data, privacy: AIPrivacyLevel) throws -> Data {
        // Placeholder for future redaction logic; pass-through by default.
        return inputJSON
    }
}

public struct DefaultRateLimitPolicy: AIRateLimitPolicy {
    public init() {}
    public func allows(port: AIPortID) -> Bool { true }
}

public struct DefaultCapabilityPolicy: AICapabilityPolicy {
    public init() {}
    public func isPortEnabled(_ port: AIPortID) -> Bool { true }
}
