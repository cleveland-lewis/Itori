#if os(macOS)
    import EventKit
    import SwiftUI

    struct RemindersSettingsView: View {
        @EnvironmentObject var calendarManager: CalendarManager
        @State private var showingRevokeAlert = false

        private var isAuthorized: Bool {
            calendarManager.reminderAuthorizationStatus == .fullAccess || calendarManager
                .reminderAuthorizationStatus == .writeOnly
        }

        var body: some View {
            List {
                Section("Reminders Sync") {
                    Toggle(
                        NSLocalizedString(
                            "settings.toggle.enable.reminders.sync",
                            value: "Enable Reminders Sync",
                            comment: "Enable Reminders Sync"
                        ),
                        isOn: Binding(
                            get: { isAuthorized },
                            set: { newValue in
                                if newValue {
                                    _Concurrency.Task { await calendarManager.requestAccess() }
                                } else {
                                    showingRevokeAlert = true
                                }
                            }
                        )
                    )
                    .toggleStyle(.switch)

                    HStack {
                        Text(NSLocalizedString("settings.status", value: "Status:", comment: "Status:"))
                            .foregroundStyle(.secondary)
                        if isAuthorized {
                            Text(NSLocalizedString("settings.connected", value: "Connected", comment: "Connected"))
                                .foregroundStyle(.green)
                        } else if calendarManager.isRemindersAccessDenied {
                            Text(NSLocalizedString(
                                "settings.access.denied",
                                value: "Access Denied",
                                comment: "Access Denied"
                            )).foregroundStyle(.red)
                            Button(NSLocalizedString(
                                "settings.button.open.settings",
                                value: "Open Settings",
                                comment: "Open Settings"
                            )) { calendarManager.openSystemPrivacySettings() }
                                .buttonStyle(.link)
                        } else {
                            Text(NSLocalizedString(
                                "settings.not.connected",
                                value: "Not Connected",
                                comment: "Not Connected"
                            )).foregroundStyle(.secondary)
                        }
                    }
                    .font(DesignSystem.Typography.caption)
                }

                if isAuthorized {
                    Section("School List") {
                        Picker(
                            "School List",
                            selection: Binding(
                                get: {
                                    calendarManager.selectedReminderListID.isEmpty ? nil : calendarManager
                                        .selectedReminderListID
                                },
                                set: { calendarManager.selectedReminderListID = $0 ?? "" }
                            )
                        ) {
                            Text(NSLocalizedString(
                                "settings.select.a.list",
                                value: "Select a List",
                                comment: "Select a List"
                            )).tag(String?.none)
                            ForEach(calendarManager.availableReminderLists, id: \.calendarIdentifier) { list in
                                HStack {
                                    if let cgColor = list.cgColor, let nsColor = NSColor(cgColor: cgColor) {
                                        Circle().fill(Color(nsColor: nsColor)).frame(width: 8, height: 8)
                                    } else {
                                        Circle().fill(Color.accentColor).frame(width: 8, height: 8)
                                    }
                                    Text(list.title)
                                }
                                .tag(Optional(list.calendarIdentifier))
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: calendarManager.selectedReminderListID) { _, _ in
                            _Concurrency.Task { await calendarManager.refreshAll() }
                        }

                        Text(NSLocalizedString(
                            "settings.only.reminders.from.this.list.will.appear.in.itori",
                            value: "Only reminders from this list will appear in Itori.",
                            comment: "Only reminders from this list will appear in Itori..."
                        ))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.sidebar)
            .alert("Disable Reminders Sync", isPresented: $showingRevokeAlert) {
                Button(NSLocalizedString(
                    "settings.button.open.system.settings",
                    value: "Open System Settings",
                    comment: "Open System Settings"
                )) {
                    calendarManager.openSystemPrivacySettings()
                }
                Button(NSLocalizedString("Cancel", value: "Cancel", comment: ""), role: .cancel) {}
            } message: {
                Text(NSLocalizedString(
                    "settings.to.disconnect.itori.from.your",
                    value: "To disconnect Itori from your Reminders, please revoke access in System Settings > Privacy & Security > Reminders.",
                    comment: "To disconnect Itori from your Reminders, please re..."
                ))
            }
            .onAppear {
                _Concurrency.Task { await calendarManager.refreshAuthStatus() }
            }
        }
    }

    #if !DISABLE_PREVIEWS
        #if !DISABLE_PREVIEWS
            #Preview {
                RemindersSettingsView()
                    .environmentObject(CalendarManager.shared)
                    .frame(width: 500, height: 600)
            }
        #endif
    #endif
#endif
