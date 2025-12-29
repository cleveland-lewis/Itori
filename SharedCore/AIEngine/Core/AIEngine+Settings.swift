import Foundation

extension AIEngine {
    struct AppleAvailability {
        let available: Bool
        let reason: String
    }

    struct LocalModelInfo {
        let name: String
        let size: String
    }

    static func appleAvailability() -> AppleAvailability {
        let availability = AppleIntelligenceProvider.availability()
        return AppleAvailability(available: availability.available, reason: availability.reason)
    }

    static func localModelInfo() -> LocalModelInfo {
        #if os(macOS)
        let type: LocalModelType = .macOSStandard
        #else
        let type: LocalModelType = .iOSLite
        #endif
        return LocalModelInfo(name: type.displayName, size: type.estimatedSize)
    }
}
