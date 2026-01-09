import Foundation

public protocol AIPort: Sendable {
    associatedtype Input: Codable & Sendable
    associatedtype Output: Codable & Sendable

    static var id: AIPortID { get }
    static var name: String { get }
    static var privacyRequirement: AIPrivacyLevel { get }
    static var mergePolicy: AIMergePolicy { get }
    static var inputHashExcludedKeys: Set<String> { get }
    static var unorderedArrayKeys: Set<String> { get }
    static var supportsDeterministicFallback: Bool { get }
    static var preferredProviders: [AIProviderID] { get }

    static func validate(input: Input) throws
    static func validate(output: Output) throws
}

public extension AIPort {
    static var preferredProviders: [AIProviderID] {
        [.appleFoundationAI, .localCoreML, .bringYourOwn, .fallbackHeuristic]
    }

    static var supportsDeterministicFallback: Bool { true }
    static var mergePolicy: AIMergePolicy { .defaultOnly }
    static var inputHashExcludedKeys: Set<String> { [] }
    static var unorderedArrayKeys: Set<String> { [] }
}
