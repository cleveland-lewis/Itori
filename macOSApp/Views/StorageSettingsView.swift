#if os(macOS)
import SwiftUI

struct StorageSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @State private var cloudKitEnabled = PersistenceController.shared.isCloudKitEnabled
    @State private var cloudKitStatusMessage = PersistenceController.shared.lastCloudKitStatusMessage ?? "Disabled by user"
    
    var body: some View {
        Form {
            Section {
                Text("Storage & Sync")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 4)
                
                Text("Manage data storage and iCloud synchronization.")
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            
            Section("iCloud Sync") {
                Toggle("Enable iCloud Sync", isOn: $settings.enableICloudSync)
                    .onChange(of: settings.enableICloudSync) { _, newValue in
                        settings.save()
                        NotificationCenter.default.post(
                            name: .iCloudSyncSettingChanged,
                            object: newValue
                        )
                    }
                
                Text(cloudKitEnabled ? "iCloud is connected." : "iCloud sync is disabled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(cloudKitStatusMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Section("Storage Usage") {
                HStack {
                    Text("Local Database")
                    Spacer()
                    Text("Storage info unavailable")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Cache")
                    Spacer()
                    Button("Clear Cache") {
                        // Clear any cached data
                        UserDefaults.standard.removeObject(forKey: "debug.logs")
                        UserDefaults.standard.removeObject(forKey: "analytics.events")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onReceive(NotificationCenter.default.publisher(for: .iCloudSyncStatusChanged)) { notification in
            if let enabled = notification.object as? Bool {
                cloudKitEnabled = enabled
                if !enabled, settings.enableICloudSync {
                    settings.enableICloudSync = false
                    settings.save()
                }
                if let reason = notification.userInfo?["reason"] as? String, !reason.isEmpty {
                    cloudKitStatusMessage = reason
                }
            }
        }
    }
}

#Preview {
    StorageSettingsView()
        .environmentObject(AppSettingsModel.shared)
        .frame(width: 600, height: 400)
}
#endif
