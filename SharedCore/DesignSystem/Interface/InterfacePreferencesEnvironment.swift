import SwiftUI

// MARK: - Environment Key

private struct InterfacePreferencesKey: EnvironmentKey {
    static let defaultValue: InterfacePreferences = .default
}

extension EnvironmentValues {
    var interfacePreferences: InterfacePreferences {
        get { self[InterfacePreferencesKey.self] }
        set { self[InterfacePreferencesKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject interface preferences into the environment
    func interfacePreferences(_ preferences: InterfacePreferences) -> some View {
        self.environment(\.interfacePreferences, preferences)
    }
}

// MARK: - Dev-Only Debugging

#if DEBUG
extension View {
    /// Debug overlay to verify preferences injection (dev-only)
    func debugInterfacePreferences() -> some View {
        self.overlay(alignment: .bottomTrailing) {
            InterfacePreferencesDebugView()
        }
    }
}

private struct InterfacePreferencesDebugView: View {
    @Environment(\.interfacePreferences) private var prefs
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("Interface Preferences", value: "Interface Preferences", comment: "")).font(.caption.bold())
                    Divider()
                    Text(String(format: NSLocalizedString("interface.debug.reduce_motion", value: "Reduce Motion: %@", comment: "Interface preferences debug"), prefs.reduceMotion ? "✓" : "✗"))
                    Text(String(format: NSLocalizedString("interface.debug.increase_contrast", value: "Increase Contrast: %@", comment: "Interface preferences debug"), prefs.increaseContrast ? "✓" : "✗"))
                    Text(String(format: NSLocalizedString("interface.debug.reduce_transparency", value: "Reduce Transparency: %@", comment: "Interface preferences debug"), prefs.reduceTransparency ? "✓" : "✗"))
                    Text(String(format: NSLocalizedString("interface.debug.compact_density", value: "Compact Density: %@", comment: "Interface preferences debug"), prefs.compactDensity ? "✓" : "✗"))
                    Text(String(format: NSLocalizedString("interface.debug.large_tap_targets", value: "Large Tap Targets: %@", comment: "Interface preferences debug"), prefs.largeTapTargets ? "✓" : "✗"))
                    Text(String(format: NSLocalizedString("interface.debug.material_intensity", value: "Material Intensity: %.1f", comment: "Interface preferences debug"), prefs.materialIntensity))
                    Text(String(format: NSLocalizedString("interface.debug.animations", value: "Animations: %@", comment: "Interface preferences debug"), prefs.animation.enabled ? "✓" : "✗"))
                    Text(String(format: NSLocalizedString("interface.debug.haptics", value: "Haptics: %@", comment: "Interface preferences debug"), prefs.haptics.enabled ? "✓" : "✗"))
                    Text(String(format: NSLocalizedString("interface.debug.tooltips", value: "Tooltips: %@", comment: "Interface preferences debug"), prefs.tooltips.enabled ? "✓" : "✗"))
                }
                .font(.caption2)
                .padding(8)
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "xmark.circle.fill" : "info.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
            }
        }
        .padding()
    }
}

/// Dev-only assertion to ensure preferences are injected
func assertInterfacePreferencesInjected(_ prefs: InterfacePreferences, file: StaticString = #file, line: UInt = #line) {
    if prefs == .default {
        print("⚠️ WARNING: InterfacePreferences appears to be default at \(file):\(line)")
        print("   This may indicate missing environment injection.")
        print("   Ensure .interfacePreferences() is called at the root.")
    }
}
#endif
