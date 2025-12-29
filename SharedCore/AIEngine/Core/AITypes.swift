import Foundation

public enum AIPortID: String, Codable, CaseIterable, Hashable {
    case documentIngest
    case academicEntityExtract
    case assignmentCreation
    case estimateTaskDuration
    case workloadForecast
    case generateStudyPlan
    case schedulePlacement
    case conflictResolution
}

public enum AIProviderID: String, Codable, Hashable {
    case appleFoundationAI
    case localCoreML
    case bringYourOwn
    case fallbackHeuristic
}

public enum AIPrivacyLevel: String, Codable, Hashable {
    case normal
    case sensitive
    case onDeviceOnly
}

public struct AIRequestContext: Sendable {
    public let requestID: UUID
    public let timestamp: Date
    public let privacy: AIPrivacyLevel
    public let localeIdentifier: String
    public let timeZoneIdentifier: String
    public let featureStateVersion: Int

    public init(
        requestID: UUID = UUID(),
        timestamp: Date = Date(),
        privacy: AIPrivacyLevel = .normal,
        localeIdentifier: String = Locale.current.identifier,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        featureStateVersion: Int = 0
    ) {
        self.requestID = requestID
        self.timestamp = timestamp
        self.privacy = privacy
        self.localeIdentifier = localeIdentifier
        self.timeZoneIdentifier = timeZoneIdentifier
        self.featureStateVersion = featureStateVersion
    }
}

public struct AIConfidence: Codable, Hashable, Sendable {
    public let value: Double
    public init(_ value: Double) { self.value = min(1.0, max(0.0, value)) }
}

public enum AIProvenance: Codable, Hashable, Sendable {
    case provider(AIProviderID)
    case fallback(AIProviderID)
    case mixed(providers: [AIProviderID])

    public var primaryProvider: AIProviderID {
        switch self {
        case .provider(let id): return id
        case .fallback(let id): return id
        case .mixed(let ids): return ids.first ?? .fallbackHeuristic
        }
    }
}

public struct AIDiagnostic: Codable, Hashable, Sendable {
    public let reasonCodes: [String]
    public let latencyMs: Int?
    public let notes: [String: String]

    public init(reasonCodes: [String] = [], latencyMs: Int? = nil, notes: [String: String] = [:]) {
        self.reasonCodes = reasonCodes
        self.latencyMs = latencyMs
        self.notes = notes
    }
}

public struct AIResultMetadata: Codable, Hashable, Sendable {
    public let inputHash: String
    public let computedAt: Date
    public let computedAtUptime: TimeInterval?
    public let featureStateVersion: Int

    public init(
        inputHash: String,
        computedAt: Date,
        computedAtUptime: TimeInterval? = nil,
        featureStateVersion: Int
    ) {
        self.inputHash = inputHash
        self.computedAt = computedAt
        self.computedAtUptime = computedAtUptime
        self.featureStateVersion = featureStateVersion
    }
}

public struct AIResult<Output: Codable & Sendable>: Codable, Sendable {
    public let output: Output
    public let confidence: AIConfidence
    public let provenance: AIProvenance
    public let diagnostic: AIDiagnostic
    public let metadata: AIResultMetadata

    public init(
        output: Output,
        confidence: AIConfidence,
        provenance: AIProvenance,
        diagnostic: AIDiagnostic = .init(),
        metadata: AIResultMetadata
    ) {
        self.output = output
        self.confidence = confidence
        self.provenance = provenance
        self.diagnostic = diagnostic
        self.metadata = metadata
    }
}

public enum AIEngineError: Error, LocalizedError {
    case capabilityUnavailable(port: AIPortID)
    case providerUnavailable(provider: AIProviderID)
    case policyDenied(reason: String)
    case validationFailed(reason: String)
    case providerFailed(underlying: Error)
    case fallbackFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .capabilityUnavailable(let port): return "Capability unavailable: \(port.rawValue)"
        case .providerUnavailable(let p): return "Provider unavailable: \(p.rawValue)"
        case .policyDenied(let r): return "Policy denied: \(r)"
        case .validationFailed(let r): return "Validation failed: \(r)"
        case .providerFailed(let e): return "Provider failed: \(e.localizedDescription)"
        case .fallbackFailed(let e): return "Fallback failed: \(e.localizedDescription)"
        }
    }
}

public extension AIResult {
    func withMetadata(_ metadata: AIResultMetadata) -> AIResult<Output> {
        AIResult(
            output: output,
            confidence: confidence,
            provenance: provenance,
            diagnostic: diagnostic,
            metadata: metadata
        )
    }
}
