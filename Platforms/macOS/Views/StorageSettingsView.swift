#if os(macOS)
    import SwiftUI

    struct StorageSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @EnvironmentObject var timerManager: TimerManager
        @State private var cloudKitEnabled = PersistenceController.shared.isCloudKitEnabled
        @State private var cloudKitStatusMessage = PersistenceController.shared.lastCloudKitStatusMessage ?? "Disabled by user"
        @State private var statusLabel: String = "Disconnected"
        @State private var syncTimeoutWorkItem: DispatchWorkItem?

        // Reset data state
        @State private var showResetSheet = false
        @State private var resetCode: String = ""
        @State private var resetInput: String = ""
        @State private var isResetting = false
        @State private var didCopyResetCode = false

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
                        .buttonStyle(.itoriLiquidProminent)
                        .controlSize(.small)
                    }
                }

                Section("Danger Zone") {
                    Button(role: .destructive) {
                        resetInput = ""
                        showResetSheet = true
                    } label: {
                        Text(NSLocalizedString(
                            "settings.reset.all.data",
                            value: "Reset All Data",
                            comment: "Reset All Data"
                        ))
                        .fontWeight(.semibold)
                    }
                    .accessibilityLabel(NSLocalizedString(
                        "settings.reset.all.data",
                        value: "Reset All Data",
                        comment: "Reset All Data"
                    ))
                    .accessibilityHint(NSLocalizedString(
                        "settings.reset.all.data.hint",
                        value: "Permanently deletes all app data",
                        comment: "Accessibility hint for reset button"
                    ))
                }
            }
            .formStyle(.grouped)
            .compactFormSections()
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .controlBackgroundColor))
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
            .sheet(isPresented: $showResetSheet) {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString(
                            "settings.reset.all.data",
                            value: "Reset All Data",
                            comment: "Reset All Data"
                        ))
                        .font(.title2.weight(.bold))
                        Text(NSLocalizedString(
                            "settings.this.will.remove.all.app",
                            value: "This will remove all app data including courses, assignments, settings, and cached sessions. This action cannot be undone.",
                            comment: "This will remove all app data including courses, a..."
                        ))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString(
                            "settings.type.the.code.to.confirm",
                            value: "Type the code to confirm",
                            comment: "Type the code to confirm"
                        ))
                        .font(.headline.weight(.semibold))
                        HStack {
                            Text(resetCode)
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.red.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
                                )
                            Button {
                                Clipboard.copy(resetCode)
                                didCopyResetCode = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    didCopyResetCode = false
                                }
                            } label: {
                                Text(didCopyResetCode ? "Copied" : "Copy")
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.itoriLiquidProminent)
                            .controlSize(.small)
                            Spacer()
                        }
                        TextField("Enter code exactly", text: $resetInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .disableAutocorrection(true)
                    }

                    HStack(spacing: 12) {
                        Button(NSLocalizedString("settings.button.cancel", value: "Cancel", comment: "Cancel")) {
                            showResetSheet = false
                        }
                        .buttonStyle(.itariLiquid)
                        Spacer()
                        Button(NSLocalizedString(
                            "settings.button.reset.now",
                            value: "Reset Now",
                            comment: "Reset Now"
                        )) {
                            performReset()
                        }
                        .buttonStyle(.itoriLiquidProminent)
                        .tint(.red)
                        .keyboardShortcut(.defaultAction)
                        .disabled(!resetCodeMatches || isResetting)
                    }
                }
                .padding(26)
                .frame(minWidth: 440, maxWidth: 520)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(DesignSystem.Materials.card)
                )
                .padding()
                .onAppear {
                    if resetCode.isEmpty {
                        resetCode = ConfirmationCode.generate()
                    }
                }
            }
            .onChange(of: showResetSheet) { _, isPresented in
                if !isPresented {
                    resetCode = ""
                    resetInput = ""
                    didCopyResetCode = false
                }
            }
        }

        private func performReset() {
            guard resetCodeMatches else { return }
            isResetting = true
            AppModel.shared.requestReset()
            timerManager.stop()
            // Reset UI state
            resetInput = ""
            showResetSheet = false
            isResetting = false
        }

        private var resetCodeMatches: Bool {
            resetInput.trimmingCharacters(in: .whitespacesAndNewlines) == resetCode
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
