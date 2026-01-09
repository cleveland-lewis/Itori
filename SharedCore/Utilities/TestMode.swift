import Foundation

/// Helper to detect if running in test mode
enum TestMode {
    /// Returns true if running under XCTest
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil ||
            NSClassFromString("XCTest") != nil
    }

    /// Returns true if running UI tests specifically
    static var isRunningUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("UITestingMode")
    }
}
