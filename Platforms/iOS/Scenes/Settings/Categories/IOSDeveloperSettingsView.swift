import Combine
import SwiftUI

#if os(iOS)

    struct IOSDeveloperSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @State private var showResetAlert = false
        @StateObject private var syncMonitor = SyncMonitor.shared

        var body: some View {
            List {
                Section {
                    Toggle(isOn: binding(for: \.devModeEnabledStorage)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString(
                                "settings.developer.mode",
                                value: "Developer Mode",
                                comment: "Developer mode toggle"
                            ))
                            Text(NSLocalizedString(
                                "settings.developer.mode.detail",
                                value: "Enable debugging features",
                                comment: "Developer mode detail"
                            ))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.developer.debug.header",
                        value: "Debug Options",
                        comment: "Debug options header"
                    ))
                }

                Section {
                    HStack {
                        Text(NSLocalizedString(
                            "settings.developer.app_version",
                            value: "App Version",
                            comment: "App version label"
                        ))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? NSLocalizedString(
                            "settings.developer.unknown",
                            value: "Unknown",
                            comment: "Unknown value"
                        ))
                        .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(NSLocalizedString(
                            "settings.developer.build_number",
                            value: "Build Number",
                            comment: "Build number label"
                        ))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? NSLocalizedString(
                            "settings.developer.unknown",
                            value: "Unknown",
                            comment: "Unknown value"
                        ))
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.developer.info.header",
                        value: "App Info",
                        comment: "App info header"
                    ))
                }

                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Text(NSLocalizedString(
                            "settings.developer.reset",
                            value: "Reset All Settings",
                            comment: "Reset settings button"
                        ))
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                } footer: {
                    Text(NSLocalizedString(
                        "settings.developer.reset.footer",
                        value: "This will reset all settings to their default values",
                        comment: "Reset settings footer"
                    ))
                }

                Section {
                    HStack {
                        Text(NSLocalizedString(
                            "settings.storage.debug.cloudkit",
                            value: "CloudKit",
                            comment: "CloudKit debug label"
                        ))
                        Spacer()
                        Text(syncMonitor.isCloudKitActive
                            ? NSLocalizedString(
                                "settings.storage.debug.active",
                                value: "Active",
                                comment: "CloudKit active"
                            )
                            : NSLocalizedString(
                                "settings.storage.debug.inactive",
                                value: "Inactive",
                                comment: "CloudKit inactive"
                            ))
                            .foregroundColor(syncMonitor.isCloudKitActive ? .green : .secondary)
                    }
                    if let lastSync = syncMonitor.lastRemoteChange {
                        HStack {
                            Text(NSLocalizedString(
                                "settings.storage.debug.last_sync",
                                value: "Last Sync",
                                comment: "CloudKit last sync label"
                            ))
                            Spacer()
                            Text(lastSync.formatted(.relative(presentation: .numeric)))
                                .foregroundColor(.secondary)
                        }
                    }
                    if let lastError = syncMonitor.lastError {
                        HStack(alignment: .top) {
                            Text(NSLocalizedString(
                                "settings.storage.debug.last_error",
                                value: "Last Error",
                                comment: "CloudKit last error label"
                            ))
                            Spacer()
                            Text(lastError)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    if let latest = syncMonitor.syncEvents.first {
                        HStack(alignment: .top) {
                            Text(NSLocalizedString(
                                "settings.storage.debug.latest_event",
                                value: "Latest Event",
                                comment: "CloudKit latest event label"
                            ))
                            Spacer()
                            Text(latest.details)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.storage.debug.header",
                        value: "iCloud Debug",
                        comment: "CloudKit debug header"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.storage.debug.footer",
                        value: "Debug-only iCloud status and recent sync activity.",
                        comment: "CloudKit debug footer"
                    ))
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(NSLocalizedString("settings.category.developer", comment: "Developer"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                NSLocalizedString(
                    "settings.developer.reset.confirm.title",
                    value: "Reset All Settings?",
                    comment: "Reset settings confirmation title"
                ),
                isPresented: $showResetAlert
            ) {
                Button(NSLocalizedString("common.cancel", comment: "Cancel"), role: .cancel) {}
                Button(
                    NSLocalizedString(
                        "settings.developer.reset.confirm.action",
                        value: "Reset",
                        comment: "Reset settings confirmation action"
                    ),
                    role: .destructive
                ) {
                    // Reset functionality placeholder
                }
            } message: {
                Text(NSLocalizedString(
                    "settings.developer.reset.confirm.message",
                    value: "This will reset all settings to their default values. This action cannot be undone.",
                    comment: "Reset settings confirmation message"
                ))
            }
        }

        private func binding<Value>(for keyPath: ReferenceWritableKeyPath<AppSettingsModel, Value>) -> Binding<Value> {
            Binding(
                get: { settings[keyPath: keyPath] },
                set: { newValue in
                    settings.objectWillChange.send()
                    settings[keyPath: keyPath] = newValue
                    settings.save()
                }
            )
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            NavigationStack {
                IOSDeveloperSettingsView()
                    .environmentObject(AppSettingsModel.shared)
            }
        }
    #endif
#endif
