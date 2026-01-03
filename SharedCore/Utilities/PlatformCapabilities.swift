import Foundation

// MARK: - Legacy Platform Capabilities
// Note: This file is deprecated. Use PlatformUnification.swift instead.
// Kept for backward compatibility during migration.

@available(*, deprecated, message: "Use Platform and CapabilityDomain from PlatformUnification.swift instead")
enum PlatformCapabilities {
    static var supportsHiddenNavigationBar: Bool {
#if os(iOS)
        if #available(iOS 16.0, *) {
            return true
        }
        return false
#else
        return false
#endif
    }
}
