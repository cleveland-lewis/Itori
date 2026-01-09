#if os(macOS)
    import SwiftUI

    struct StorageSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @State private var cloudKitEnabled = PersistenceController.shared.isCloudKitEnabled
        @State private var cloudKitStatusMessage = PersistenceController.shared.lastCloudKitStatusMessage ?? "Disabled by user"
        @State private var statusLabel: String = "Disconnected"
        @State private var syncTimeoutWorkItem: DispatchWorkItem?

        var body: some View {
            Form {
                Section {
                    Text(NSLocalizedString("settings.storage.sync", value: "Storage & Sync", comment: "Storage & Sync"))
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 4)

                    Text(NSLocalizedString(
                        "settings.manage.data.storage.and.icloud.synchronization",
                        value: "Manage data storage and iCloud synchronization.",
                        comment: "Manage data storage and iCloud synchronization."
                    ))
                    .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)

                Section("iCloud Sync") {
                    Toggle(
                        NSLocalizedString(
                            "settings.toggle.enable.icloud.sync",
                            value: "Enable iCloud Sync",
                            comment: "Enable iCloud Sync"
                        ),
                        isOn: $settings.enableICloudSync
                    )
                    .onChange(of: settings.enableICloudSync) { _, newValue in
                        settings.save()
                        statusLabel = "Syncing"
                        scheduleSyncTimeout()
                        NotificationCenter.default.post(
                            name: .iCloudSyncSettingChanged,
                            object: newValue
                        )
                    }

                    Text(verbatim: "Status: \(statusLabel)")
                        .font(.caption)
                        .foregroundStyle(statusLabel == "Error" ? .red :
                            (statusLabel == "Connected" ? .green : .secondary))

                    if !cloudKitStatusMessage.isEmpty && cloudKitStatusMessage != "Disabled by user" {
                        Text(cloudKitStatusMessage)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Section("Storage Usage") {
                    HStack {
                        Text(NSLocalizedString(
                            "settings.local.database",
                            value: "Local Database",
                            comment: "Local Database"
                        ))
                        Spacer()
                        Text(NSLocalizedString(
                            "settings.storage.info.unavailable",
                            value: "Storage info unavailable",
                            comment: "Storage info unavailable"
                        ))
                        .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(NSLocalizedString("settings.cache", value: "Cache", comment: "Cache"))
                        Spacer()
                        Button(NSLocalizedString(
                            "settings.button.clear.cache",
                            value: "Clear Cache",
                            comment: "Clear Cache"
                        )) {
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
                    statusLabel = statusLabelFor(enabled: enabled, reason: notification.userInfo?["reason"] as? String)
                    if let reason = notification.userInfo?["reason"] as? String, !reason.isEmpty {
                        cloudKitStatusMessage = reason
                    }
                    syncTimeoutWorkItem?.cancel()
                }
            }
            .onAppear {
                statusLabel = statusLabelFor(enabled: cloudKitEnabled, reason: cloudKitStatusMessage)
            }
        }

        private func scheduleSyncTimeout() {
            syncTimeoutWorkItem?.cancel()
            let workItem = DispatchWorkItem {
                if statusLabel == "Syncing" {
                    statusLabel = "Taking longer than usual"
                }
            }
            syncTimeoutWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 8 * 60, execute: workItem)
        }

        private func statusLabelFor(enabled: Bool, reason: String?) -> String {
            if enabled { return "Connected" }
            let text = reason?.lowercased() ?? ""
            if text.contains("error") || text.contains("failed") {
                return "Error"
            }
            if text.contains("connecting") || text.contains("syncing") {
                return "Syncing"
            }
            return "Disconnected"
        }
    }

    struct StorageSettingsView_Previews: PreviewProvider {
        static var previews: some View {
            StorageSettingsView()
                .environmentObject(AppSettingsModel.shared)
                .frame(width: 600, height: 400)
        }
    }
#endif
