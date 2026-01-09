import Foundation

enum UILogCategory: String {
    case dashboard
}

enum UILogger {
    static func log(_ category: UILogCategory, _ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        DebugLogger.log("[UI][\(category.rawValue)] \(timestamp) - \(message)")
    }
}
