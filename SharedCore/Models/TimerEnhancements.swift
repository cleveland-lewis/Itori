import Foundation

/// Timer preset configuration for quick access
public struct TimerPreset: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var duration: TimeInterval
    public var emoji: String?
    public var colorHex: String?
    public var mode: TimerMode
    public var isDefault: Bool
    public var sortOrder: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        duration: TimeInterval,
        emoji: String? = nil,
        colorHex: String? = nil,
        mode: TimerMode = .timer,
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.emoji = emoji
        self.colorHex = colorHex
        self.mode = mode
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
    
    /// Default presets provided by the app
    public static let defaults: [TimerPreset] = [
        TimerPreset(name: "Quick Focus", duration: 15 * 60, emoji: "⚡", mode: .pomodoro, isDefault: true, sortOrder: 0),
        TimerPreset(name: "Pomodoro", duration: 25 * 60, emoji: "🍅", mode: .pomodoro, isDefault: true, sortOrder: 1),
        TimerPreset(name: "Short Break", duration: 5 * 60, emoji: "☕", mode: .timer, isDefault: true, sortOrder: 2),
        TimerPreset(name: "Long Break", duration: 15 * 60, emoji: "🌟", mode: .timer, isDefault: true, sortOrder: 3),
        TimerPreset(name: "Deep Work", duration: 90 * 60, emoji: "🧠", mode: .focus, isDefault: true, sortOrder: 4),
        TimerPreset(name: "Exercise", duration: 30 * 60, emoji: "💪", mode: .timer, isDefault: true, sortOrder: 5),
    ]
}

/// Visual theme for timer display
public struct TimerTheme: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var primaryColorHex: String
    public var secondaryColorHex: String?
    public var accentColorHex: String?
    public var visualStyle: TimerVisualStyle
    public var isDefault: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        primaryColorHex: String,
        secondaryColorHex: String? = nil,
        accentColorHex: String? = nil,
        visualStyle: TimerVisualStyle = .ring,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.accentColorHex = accentColorHex
        self.visualStyle = visualStyle
        self.isDefault = isDefault
    }
    
    /// Default themes provided by the app
    public static let defaults: [TimerTheme] = [
        TimerTheme(name: "Classic", primaryColorHex: "#007AFF", visualStyle: .ring, isDefault: true),
        TimerTheme(name: "Focus", primaryColorHex: "#FF3B30", secondaryColorHex: "#FF9500", visualStyle: .ring),
        TimerTheme(name: "Calm", primaryColorHex: "#5AC8FA", secondaryColorHex: "#34C759", visualStyle: .ring),
        TimerTheme(name: "Energy", primaryColorHex: "#FF9500", secondaryColorHex: "#FFCC00", visualStyle: .grid),
        TimerTheme(name: "Minimal", primaryColorHex: "#8E8E93", visualStyle: .digital),
    ]
}

/// Visual style for timer countdown display
public enum TimerVisualStyle: String, Codable, CaseIterable, Identifiable {
    case ring       // Circular progress ring
    case grid       // Grid-based countdown
    case digital    // Digital numbers only
    case analog     // Analog clock face
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .ring: return "Ring"
        case .grid: return "Grid"
        case .digital: return "Digital"
        case .analog: return "Analog"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .ring: return "circle.circle"
        case .grid: return "square.grid.3x3"
        case .digital: return "textformat.123"
        case .analog: return "clock"
        }
    }
}

/// Timer statistics for insights
public struct TimerStatistics: Codable {
    public var totalSessions: Int
    public var totalDuration: TimeInterval
    public var completedSessions: Int
    public var averageSessionDuration: TimeInterval
    public var longestSession: TimeInterval
    public var currentStreak: Int
    public var lastSessionDate: Date?
    
    public init(
        totalSessions: Int = 0,
        totalDuration: TimeInterval = 0,
        completedSessions: Int = 0,
        averageSessionDuration: TimeInterval = 0,
        longestSession: TimeInterval = 0,
        currentStreak: Int = 0,
        lastSessionDate: Date? = nil
    ) {
        self.totalSessions = totalSessions
        self.totalDuration = totalDuration
        self.completedSessions = completedSessions
        self.averageSessionDuration = averageSessionDuration
        self.longestSession = longestSession
        self.currentStreak = currentStreak
        self.lastSessionDate = lastSessionDate
    }
}
