import SwiftUI

#if os(macOS)
import AppKit
#endif

/// Utility to access system accessibility preferences
struct AccessibilityPreferences {
    /// Check if Reduce Motion is enabled in system preferences
    static var isReduceMotionEnabled: Bool {
        #if os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #else
        return UIAccessibility.isReduceMotionEnabled
        #endif
    }
    
    /// Check if Increase Contrast is enabled
    static var isIncreaseContrastEnabled: Bool {
        #if os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        #else
        return UIAccessibility.isDarkerSystemColorsEnabled
        #endif
    }
    
    /// Check if Reduce Transparency is enabled
    static var isReduceTransparencyEnabled: Bool {
        #if os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        #else
        return UIAccessibility.isReduceTransparencyEnabled
        #endif
    }
}

// MARK: - Environment Value for Reduce Motion

extension View {
    /// Injects the current Reduce Motion preference into the environment
    func detectReduceMotion() -> some View {
        self.environment(\.reduceMotion, AccessibilityPreferences.isReduceMotionEnabled)
    }
}
