#if !os(macOS)
import Foundation
import SwiftUI
import UIKit

// Minimal stubs for macOS-only types used by shared code when building for iOS.

// Map NSColor to UIColor for cross-platform compatibility
public typealias NSColor = UIColor

// Allow constructing SwiftUI Color from an NSColor-like initializer used in shared code
public extension Color {
    init(nsColor: NSColor) {
        self.init(nsColor)
    }
} 

// Provide commonly used NSColor-like static properties used in code
public extension NSColor {
    static var controlAccentColor: NSColor { UIColor.systemBlue }
    static var controlBackgroundColor: NSColor { UIColor.systemBackground }
    static var separatorColor: NSColor { UIColor.separator }
    static var windowBackgroundColor: NSColor { UIColor.systemBackground }
    static var underPageBackgroundColor: NSColor { UIColor.secondarySystemBackground }
    static var controlHighlightColor: NSColor { UIColor.systemGray }
    static var alternatingContentBackgroundColors: [NSColor] { [UIColor.systemBackground, UIColor.secondarySystemBackground] }
    static var unemphasizedSelectedContentBackgroundColor: NSColor { UIColor.systemGray2 }
}

public struct LocalTimerSession: Identifiable, Codable, Hashable {
    public enum Mode: String, Codable, Hashable {
        case work, breakMode = "break", other
    }

    public let id: UUID
    public var activityID: UUID
    public var mode: Mode
    public var startDate: Date
    public var endDate: Date?
    public var duration: TimeInterval

    public init(id: UUID = UUID(), activityID: UUID, mode: Mode = .other, startDate: Date, endDate: Date? = nil, duration: TimeInterval = 0) {
        self.id = id
        self.activityID = activityID
        self.mode = mode
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
    }
}

public struct LocalTimerActivity: Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var category: String
    public var courseCode: String?
    public var assignmentTitle: String?
    public var colorTag: ColorTag
    public var isPinned: Bool
    public var totalTrackedSeconds: TimeInterval
    public var todayTrackedSeconds: TimeInterval

    public init(id: UUID = UUID(), name: String = "", category: String = "", courseCode: String? = nil, assignmentTitle: String? = nil, colorTag: ColorTag = .blue, isPinned: Bool = false, totalTrackedSeconds: TimeInterval = 0, todayTrackedSeconds: TimeInterval = 0) {
        self.id = id
        self.name = name
        self.category = category
        self.courseCode = courseCode
        self.assignmentTitle = assignmentTitle
        self.colorTag = colorTag
        self.isPinned = isPinned
        self.totalTrackedSeconds = totalTrackedSeconds
        self.todayTrackedSeconds = todayTrackedSeconds
    }
}

public enum ColorTag: String, CaseIterable, Identifiable {
    case blue, green, purple, orange, pink, yellow, gray
    public var id: String { rawValue }
    public var color: Color { .blue }
    public static func fromHex(_ hex: String?) -> ColorTag? { nil }
    public static func hex(for tag: ColorTag) -> String { "#000000" }
}

public enum SettingsToolbarIdentifier: String, CaseIterable, Identifiable {
    case general
    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }
    public var toolbarItemIdentifier: String { rawValue }
    public var windowTitle: String { "Settings" }
}

public class SettingsWindowController {
    public static let lastPaneKey = "roots.settings.lastSelectedPane"
    public init(appSettings: Any, coursesStore: Any, coordinator: Any) {}
    public func showSettings() {}
}



// Additional lightweight stubs for shared types referenced by iOS target when macOS sources are excluded

public enum RootTab: String, CaseIterable, Identifiable {
    case dashboard, planner, courses, grades, timer
    public var id: String { rawValue }
}

public enum AssignmentCategory: String, CaseIterable, Codable {
    case reading, exam, homework, other
}

public struct Assignment: Identifiable, Codable, Hashable {
    public let id: UUID
    public var courseId: UUID?
    public var title: String
    public var dueDate: Date
    public var estimatedMinutes: Int?
    public var weightPercent: Double?
    public var category: AssignmentCategory?
}

public enum CalendarViewMode: String, Codable {
    case day, week, month
}

public struct GradeCourseSummary: Hashable {
    public var id: UUID
    public var title: String
}

public struct StoredScheduledSession: Codable, Hashable {
    public var id: UUID = UUID()
}

public struct StoredOverflowSession: Codable, Hashable {
    public var id: UUID = UUID()
}

open class LoadableViewModel: ObservableObject {}

#endif
