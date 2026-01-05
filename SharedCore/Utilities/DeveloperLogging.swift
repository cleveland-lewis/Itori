import Foundation
import os.log

/// Developer logging levels for detailed debugging when developer mode is enabled
enum DeveloperLogLevel {
    case info
    case debug
    case error
    case warning
}

/// Logs messages only when developer mode is enabled in AppSettingsModel
/// - Parameters:
///   - level: The log level (info, debug, error, warning)
///   - category: The logging category (e.g., "LLM", "Data", "UI")
///   - message: The message to log
///   - metadata: Optional key-value pairs for structured logging
///   - file: The source file (automatically captured)
///   - function: The function name (automatically captured)
///   - line: The line number (automatically captured)
func LOG_DEV_LEGACY(
    _ level: DeveloperLogLevel,
    _ category: String,
    _ message: String,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    guard AppSettingsModel.shared.devModeEnabled else { return }
    
    let fileName = (file as NSString).lastPathComponent
    let timestamp = ISO8601DateFormatter().string(from: Date())
    
    let levelString: String
    let osLogType: OSLogType
    
    switch level {
    case .info:
        levelString = "ℹ️ INFO"
        osLogType = .info
    case .debug:
        levelString = "🔍 DEBUG"
        osLogType = .debug
    case .error:
        levelString = "❌ ERROR"
        osLogType = .error
    case .warning:
        levelString = "⚠️ WARNING"
        osLogType = .default
    }
    
    var logMessage = "[\(timestamp)] \(levelString) [\(category)] [\(fileName):\(line)] \(function) - \(message)"
    
    if let metadata = metadata, !metadata.isEmpty {
        let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        logMessage += " | \(metadataString)"
    }
    
    // Use os_log for proper system logging
    let log = OSLog(subsystem: "com.itori.app", category: category)
    os_log("%{public}@", log: log, type: osLogType, logMessage)
    
    // Also print to console for Xcode debugging
    print(logMessage)
}
