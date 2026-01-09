//
//  WindowIdentifier.swift
//  Itori
//
//  Multi-window support identifiers
//

import Foundation

/// Identifies window types for multi-scene support
enum WindowIdentifier: String {
    case main
    case assignmentDetail = "assignment-detail"
    case courseDetail = "course-detail"
    case plannerDay = "planner-day"
    case timerSession = "timer-session"

    var title: String {
        switch self {
        case .main: "Itori"
        case .assignmentDetail: "Assignment"
        case .courseDetail: "Course"
        case .plannerDay: "Planner"
        case .timerSession: "Timer"
        }
    }
}

/// Represents window state for scene restoration
struct WindowState: Codable, Hashable {
    let windowId: String
    var entityId: String?
    var displayTitle: String?

    init(windowId: WindowIdentifier, entityId: String? = nil, displayTitle: String? = nil) {
        self.windowId = windowId.rawValue
        self.entityId = entityId
        self.displayTitle = displayTitle
    }
}
