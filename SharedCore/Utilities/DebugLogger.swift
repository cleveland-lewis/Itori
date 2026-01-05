import Foundation

enum DebugLogger {
    static func log(_ message: String) {
        // Requires both dev mode enabled AND data logging enabled
        guard AppSettingsModel.shared.devModeEnabled && AppSettingsModel.shared.devModeDataLogging else { return }
        Swift.print(message)
    }
}
