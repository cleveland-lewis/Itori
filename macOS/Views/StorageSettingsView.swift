#if os(macOS)
import SwiftUI

struct StorageSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
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
                
                if PersistenceController.shared.isCloudKitEnabled {
                    Text("iCloud is connected and protected by native iCloud protections")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label {
                        Text("iCloud sync is disabled. All data stays on this device only.")
                    } icon: {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.caption)
                }
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
    }
}

#Preview {
    StorageSettingsView()
        .environmentObject(AppSettingsModel.shared)
        .frame(width: 600, height: 400)
}
#endif
