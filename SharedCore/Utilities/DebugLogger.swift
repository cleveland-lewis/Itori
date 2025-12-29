import Foundation

enum DebugLogger {
    static func log(_ message: String) {
        guard AppSettingsModel.shared.devModeDataLogging else { return }
        Swift.print(message)
    }
}
