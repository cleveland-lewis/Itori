import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Helper for requesting SwiftUI scene activations with `NSUserActivity` payloads.
enum SceneActivationHelper {
    static let assignmentActivityType = "com.roots.scene.assignmentDetail"
    static let assignmentSceneStorageKey = "roots.scene.assignmentDetail.assignmentId"
    static let assignmentIdKey = "assignmentId"

    static func openAssignmentWindow(for assignmentId: UUID) {
        let activity = NSUserActivity(activityType: assignmentActivityType)
        activity.userInfo = [assignmentIdKey: assignmentId.uuidString]
        activateScene(with: activity)
    }

    private static func activateScene(with activity: NSUserActivity) {
        #if canImport(UIKit)
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { _, _ in }
        #elseif canImport(AppKit)
        NSApp.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { _, _ in }
        #endif
    }
}
