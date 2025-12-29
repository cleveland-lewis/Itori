import Foundation

public struct FeatureStateVersionTracker: Codable, Sendable {
    public private(set) var version: Int

    public init(version: Int = 0) {
        self.version = version
    }

    @discardableResult
    public mutating func recordAssignmentChange(
        dueDateChanged: Bool,
        categoryChanged: Bool,
        titleChanged: Bool
    ) -> Bool {
        if dueDateChanged || categoryChanged {
            version += 1
            return true
        }

        if titleChanged {
            return false
        }

        return false
    }

    @discardableResult
    public mutating func recordManualSessionEdit(_ changed: Bool) -> Bool {
        guard changed else { return false }
        version += 1
        return true
    }

    @discardableResult
    public mutating func recordConstraintChange(_ changed: Bool) -> Bool {
        guard changed else { return false }
        version += 1
        return true
    }
}
