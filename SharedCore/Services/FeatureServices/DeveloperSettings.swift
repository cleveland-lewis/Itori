import Foundation

/// DEPRECATED: This synchronizer was causing infinite recursion.
/// Developer settings are now read directly from AppSettingsModel when needed.
/// Keep this file for compatibility but do not use.
final class DeveloperSettingsSynchronizer {
    static let shared = DeveloperSettingsSynchronizer()
    
    private init() {
        // No-op: synchronization removed to prevent infinite recursion
    }
}
