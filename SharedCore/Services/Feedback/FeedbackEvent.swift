import Foundation

/// Events that trigger feedback (haptics + sound) across platforms
public enum FeedbackEvent: String, Sendable {
    case taskCompleted
    case timerStart
    case timerStop
    case success
    case warning
    case error
    
    /// Human-readable description for debugging
    public var description: String {
        switch self {
        case .taskCompleted: return "Task Completed"
        case .timerStart: return "Timer Started"
        case .timerStop: return "Timer Stopped"
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}
