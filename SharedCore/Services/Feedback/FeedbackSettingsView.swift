import SwiftUI

/// Settings view for configuring haptics and sound feedback
public struct FeedbackSettingsView: View {
    @ObservedObject private var coordinator = FeedbackCoordinator.shared
    
    public init() {}
    
    public var body: some View {
        Form {
            Section {
                Toggle("Enable Sounds", isOn: $coordinator.soundEnabled)
                    .disabled(!coordinator.supportsSound)
                
                if coordinator.supportsHaptics {
                    Toggle("Enable Haptics", isOn: $coordinator.hapticsEnabled)
                }
            } header: {
                Text("Feedback")
            } footer: {
                if !coordinator.supportsHaptics {
                    Text("Haptics are not available on this device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Test Feedback") {
                Button("Test Success") {
                    coordinator.play(.success)
                }
                Button("Test Warning") {
                    coordinator.play(.warning)
                }
                Button("Test Error") {
                    coordinator.play(.error)
                }
                Button("Test Task Complete") {
                    coordinator.play(.taskCompleted)
                }
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
    }
}
