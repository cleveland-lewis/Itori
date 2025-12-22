import Foundation

/// Represents the current state of the onboarding flow
public enum OnboardingState: Codable, Equatable {
    /// User has never seen onboarding
    case neverSeen
    
    /// User is currently progressing through onboarding at a specific step
    case inProgress(stepId: String)
    
    /// User has completed the full onboarding flow
    case completed
    
    /// User skipped onboarding
    case skipped
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case type
        case stepId
    }
    
    private enum StateType: String, Codable {
        case neverSeen
        case inProgress
        case completed
        case skipped
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StateType.self, forKey: .type)
        
        switch type {
        case .neverSeen:
            self = .neverSeen
        case .inProgress:
            let stepId = try container.decode(String.self, forKey: .stepId)
            self = .inProgress(stepId: stepId)
        case .completed:
            self = .completed
        case .skipped:
            self = .skipped
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .neverSeen:
            try container.encode(StateType.neverSeen, forKey: .type)
        case .inProgress(let stepId):
            try container.encode(StateType.inProgress, forKey: .type)
            try container.encode(stepId, forKey: .stepId)
        case .completed:
            try container.encode(StateType.completed, forKey: .type)
        case .skipped:
            try container.encode(StateType.skipped, forKey: .type)
        }
    }
    
    // MARK: - Convenience Properties
    
    /// Whether onboarding should be shown
    public var shouldShowOnboarding: Bool {
        switch self {
        case .neverSeen, .inProgress:
            return true
        case .completed, .skipped:
            return false
        }
    }
    
    /// Current step ID if in progress, nil otherwise
    public var currentStepId: String? {
        if case .inProgress(let stepId) = self {
            return stepId
        }
        return nil
    }
    
    /// Human-readable description for debugging
    public var debugDescription: String {
        switch self {
        case .neverSeen:
            return "Never Seen"
        case .inProgress(let stepId):
            return "In Progress (step: \(stepId))"
        case .completed:
            return "Completed"
        case .skipped:
            return "Skipped"
        }
    }
}
