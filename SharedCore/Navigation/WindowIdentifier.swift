//
//  WindowIdentifier.swift
//  Roots
//
//  Multi-window support identifiers
//

import Foundation

/// Identifies window types for multi-scene support
enum WindowIdentifier: String {
    case main = "main"
    case assignmentDetail = "assignment-detail"
    case courseDetail = "course-detail"
    case plannerDay = "planner-day"
    case timerSession = "timer-session"
    
    var title: String {
        switch self {
        case .main: return "Roots"
        case .assignmentDetail: return "Assignment"
        case .courseDetail: return "Course"
        case .plannerDay: return "Planner"
        case .timerSession: return "Timer"
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
