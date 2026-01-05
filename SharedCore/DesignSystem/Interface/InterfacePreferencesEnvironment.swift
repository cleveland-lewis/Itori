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
                    Text("Interface Preferences").font(.caption.bold())
                    Divider()
                    Text("Reduce Motion: \(prefs.reduceMotion ? "✓" : "✗")")
                    Text("Increase Contrast: \(prefs.increaseContrast ? "✓" : "✗")")
                    Text("Reduce Transparency: \(prefs.reduceTransparency ? "✓" : "✗")")
                    Text("Compact Density: \(prefs.compactDensity ? "✓" : "✗")")
                    Text("Large Tap Targets: \(prefs.largeTapTargets ? "✓" : "✗")")
                    Text("Material Intensity: \(String(format: "%.1f", prefs.materialIntensity))")
                    Text("Animations: \(prefs.animation.enabled ? "✓" : "✗")")
                    Text("Haptics: \(prefs.haptics.enabled ? "✓" : "✗")")
                    Text("Tooltips: \(prefs.tooltips.enabled ? "✓" : "✗")")
                }
                .font(.caption2)
                .padding(8)
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "xmark.circle.fill" : "info.circle.fill")
                    .foregroundColor(.blue)
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
