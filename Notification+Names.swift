import Foundation

// Centralized notification names used across the app.
extension Notification.Name {
    // Global actions
    static let refreshRequested = Notification.Name("refreshRequested")
    static let navigateToTab = Notification.Name("navigateToTab")
    static let addAssignmentRequested = Notification.Name("addAssignmentRequested")
    static let addGradeRequested = Notification.Name("addGradeRequested")

    // Timer actions
    static let timerStartRequested = Notification.Name("timerStartRequested")
    static let timerStopRequested = Notification.Name("timerStopRequested")
    static let timerEndRequested = Notification.Name("timerEndRequested")

    // Timer state updates (menu bar manager uses this)
    static let timerStateDidChange = Notification.Name("timerStateDidChange")
    
    // Planner settings
    static let plannerHorizonDidChange = Notification.Name("plannerHorizonDidChange")
    
    // Navigation
    static let navigatePrevious = Notification.Name("navigatePrevious")
    static let navigateNext = Notification.Name("navigateNext")
}
