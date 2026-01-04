#if os(macOS)
import SwiftUI
import AppKit

struct PrivacySettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        Form {
            Section {
                Text("Privacy & Security")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 4)
                
                Text("Control how Roots uses your data and manages privacy-sensitive features.")
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            
            Section("LLM Settings") {
                Text("LLM configuration has been moved to the LLM settings page.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Data Storage") {
                Text("Manage iCloud sync in Storage settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Diagnostics") {
                Button(role: .destructive) {
                    clearDebugLogs()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Debug Logs")
                    }
                }
                
                Text("Clear all debug logs and analytics data stored on your device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("System Permissions") {
                Button {
                    openSystemPrivacySettings()
                } label: {
                    HStack {
                        Image(systemName: "hand.raised")
                        Text("Manage Permissions")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("Open System Settings to manage calendar, notifications, and other permissions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Privacy")
        .frame(minWidth: 500, maxWidth: 700)
    }
    
    private func clearDebugLogs() {
        // Clear any debug logs or analytics data
        UserDefaults.standard.removeObject(forKey: "debug.logs")
        UserDefaults.standard.removeObject(forKey: "analytics.events")
    }
    
    private func openSystemPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Privacy Feature Row

private struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isEnabled ? .blue : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.body)
                    Spacer()
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isEnabled ? .green : .red)
                        .font(.caption)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.secondaryBackground)
        )
    }
}

#endif
