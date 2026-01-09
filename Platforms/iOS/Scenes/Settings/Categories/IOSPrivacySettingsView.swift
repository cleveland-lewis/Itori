import SwiftUI

#if os(iOS)

    struct IOSPrivacySettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @State private var showingClearConfirmation = false

        var body: some View {
            List {
                Section {
                    Text(NSLocalizedString(
                        "settings.privacy.local_only.footer",
                        comment: "All your data stays on this device. No cloud sync or external services are used."
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Text(NSLocalizedString(
                        "settings.privacy.icloud_hint",
                        value: "Manage iCloud sync in Storage settings.",
                        comment: "iCloud settings hint"
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)
                } header: {
                    Text(NSLocalizedString("settings.privacy.data.header", comment: "Data Storage"))
                }

                Section {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(NSLocalizedString("settings.privacy.clear_logs", comment: "Clear Debug Logs"))
                        }
                    }
                    .confirmationDialog(
                        NSLocalizedString("settings.privacy.clear_logs.confirm.title", comment: "Clear Debug Logs?"),
                        isPresented: $showingClearConfirmation
                    ) {
                        Button(
                            NSLocalizedString("settings.privacy.clear_logs.confirm.action", comment: "Clear Logs"),
                            role: .destructive
                        ) {
                            clearDebugLogs()
                        }
                        Button(NSLocalizedString("common.cancel", comment: "Cancel"), role: .cancel) {}
                    } message: {
                        Text(NSLocalizedString(
                            "settings.privacy.clear_logs.confirm.message",
                            comment: "This will clear all debug logs and analytics data stored on your device."
                        ))
                    }
                } header: {
                    Text(NSLocalizedString("settings.privacy.diagnostics.header", comment: "Diagnostics"))
                }

                Section {
                    Button {
                        openAppSettings()
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised")
                            Text(NSLocalizedString("settings.privacy.permissions", comment: "Manage Permissions"))
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(NSLocalizedString("settings.privacy.permissions.header", comment: "Permissions"))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.privacy.permissions.footer",
                        comment: "Open iOS Settings to manage calendar, notifications, and other permissions"
                    ))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("settings.category.privacy", comment: "Privacy"))
            .navigationBarTitleDisplayMode(.inline)
        }

        private func clearDebugLogs() {
            // Clear any debug logs or analytics data
            UserDefaults.standard.removeObject(forKey: "debug.logs")
            UserDefaults.standard.removeObject(forKey: "analytics.events")
        }

        private func openAppSettings() {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            NavigationStack {
                IOSPrivacySettingsView()
                    .environmentObject(AppSettingsModel.shared)
            }
        }
    #endif
#endif
