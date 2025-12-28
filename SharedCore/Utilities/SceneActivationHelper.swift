import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Helper for requesting SwiftUI scene activations with `NSUserActivity` payloads.
enum SceneActivationHelper {
    static let windowActivityType = "com.roots.scene.windowState"
    static let windowStateKey = "roots.scene.windowState"
    static let assignmentSceneStorageKey = "roots.scene.assignmentDetail.assignmentId"
    static let courseSceneStorageKey = "roots.scene.courseDetail.courseId"
    static let plannerSceneStorageKey = "roots.scene.plannerDay.dateId"
    static let timerSceneStorageKey = "roots.scene.timerSession.sessionId"

    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func openAssignmentWindow(for task: AppTask) {
        openAssignmentWindow(withId: task.id, title: task.title)
    }

    static func openAssignmentWindow(withId id: UUID, title: String? = nil) {
        var state = WindowState(windowId: .assignmentDetail,
                                entityId: id.uuidString,
                                displayTitle: title)
        if state.displayTitle == nil {
            state.displayTitle = WindowIdentifier.assignmentDetail.title
        }
        openWindow(state)
    }

    static func openCourseWindow(for course: Course) {
        let displayTitle: String
        if course.code.isEmpty {
            displayTitle = course.title
        } else {
            displayTitle = "\(course.code) • \(course.title)"
        }
        let state = WindowState(windowId: .courseDetail,
                                entityId: course.id.uuidString,
                                displayTitle: displayTitle)
        openWindow(state)
    }

    static func openPlannerWindow(for date: Date) {
        let identifier = isoIdentifier(from: date)
        let displayTitle = "\(WindowIdentifier.plannerDay.title) • \(formattedDate(date))"
        let state = WindowState(windowId: .plannerDay,
                                entityId: identifier,
                                displayTitle: displayTitle)
        openWindow(state)
    }

    static func openTimerWindow() {
        let state = WindowState(windowId: .timerSession,
                                entityId: nil,
                                displayTitle: WindowIdentifier.timerSession.title)
        openWindow(state)
    }

    static func decodeWindowState(from activity: NSUserActivity) -> WindowState? {
        guard let data = activity.userInfo?[windowStateKey] as? Data else { return nil }
        return try? jsonDecoder.decode(WindowState.self, from: data)
    }

    static func date(from identifier: String) -> Date? {
        isoDateFormatter.date(from: identifier)
    }

    static func isoIdentifier(from date: Date) -> String {
        isoDateFormatter.string(from: date)
    }

    private static func formattedDate(_ date: Date) -> String {
        displayDateFormatter.string(from: date)
    }

    private static func openWindow(_ state: WindowState) {
        let activity = NSUserActivity(activityType: windowActivityType)
        if let data = try? jsonEncoder.encode(state) {
            activity.addUserInfoEntries(from: [windowStateKey: data])
        }
        activity.title = state.displayTitle ??
            WindowIdentifier(rawValue: state.windowId)?.title ??
            WindowIdentifier.main.title
        activateScene(with: activity)
    }

    private static func activateScene(with activity: NSUserActivity) {
        #if canImport(UIKit) && !os(macOS)
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
        #elseif canImport(AppKit)
        // macOS doesn't support requestSceneSessionActivation.
        _ = activity
        #endif
    }
}
