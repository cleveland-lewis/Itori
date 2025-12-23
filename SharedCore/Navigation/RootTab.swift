import Foundation

/// Cross-platform tab identifier
/// Represents all possible tabs across iOS/iPadOS/macOS/watchOS
public enum RootTab: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case dashboard
    case timer
    case planner
    case assignments
    case courses
    case grades
    case calendar
    case practice
    case decks
    case settings  // iOS/watchOS only; macOS uses menu-based settings
    
    public var id: String { rawValue }
}
