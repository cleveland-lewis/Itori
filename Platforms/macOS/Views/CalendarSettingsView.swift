#if os(macOS)
    import EventKit
    import SwiftUI

    struct CalendarSettingsView: View {
        @EnvironmentObject var calendarManager: CalendarManager
        @EnvironmentObject var settings: AppSettingsModel
        @State private var showingRevokeAlert = false
        @State private var isRequestingAccess = false

        private var isAuthorized: Bool {
            calendarManager.eventAuthorizationStatus == .fullAccess || calendarManager
                .eventAuthorizationStatus == .writeOnly
        }

        var body: some View {
            Form {
                Section("Calendar Sync") {
                    if !isAuthorized && !isRequestingAccess {
                        Button(NSLocalizedString(
                            "settings.button.connect.calendar",
                            value: "Connect Calendar",
                            comment: "Connect Calendar"
                        )) {
                            isRequestingAccess = true
                            Task { @MainActor in
                                await calendarManager.requestAccess()
                                isRequestingAccess = false
                            }
                        }
                        .buttonStyle(.itoriLiquidProminent)
                    } else if isRequestingAccess {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Requesting access...")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.enable.calendar.sync",
                                value: "Enable Calendar Sync",
                                comment: "Enable Calendar Sync"
                            ),
                            isOn: .constant(true)
                        )
                        .disabled(true)
                        .toggleStyle(.switch)

                        Button(NSLocalizedString(
                            "settings.button.disconnect",
                            value: "Disconnect",
                            comment: "Disconnect"
                        )) {
                            showingRevokeAlert = true
                        }
                        .buttonStyle(.itoriLiquidProminent)
                    }

                    HStack {
                        Text(NSLocalizedString("settings.status", value: "Status:", comment: "Status:"))
                            .foregroundStyle(.secondary)
                        if isAuthorized {
                            Text(NSLocalizedString("settings.connected", value: "Connected", comment: "Connected"))
                                .foregroundStyle(.green)
                        } else if calendarManager.isCalendarAccessDenied {
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
                    Section("School Calendar") {
                        Picker(
                            "School Calendar",
                            selection: Binding(
                                get: {
                                    calendarManager.selectedCalendarID.isEmpty ? nil : calendarManager
                                        .selectedCalendarID
                                },
                                set: { calendarManager.selectedCalendarID = $0 ?? "" }
                            )
                        ) {
                            Text(NSLocalizedString(
                                "settings.select.a.calendar",
                                value: "Select a Calendar",
                                comment: "Select a Calendar"
                            )).tag(String?.none)
                            ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { cal in
                                HStack {
                                    if let cgColor = cal.cgColor, let nsColor = NSColor(cgColor: cgColor) {
                                        Circle().fill(Color(nsColor: nsColor)).frame(width: 8, height: 8)
                                    } else {
                                        Circle().fill(Color.accentColor).frame(width: 8, height: 8)
                                    }
                                    Text(cal.title)
                                }
                                .tag(Optional(cal.calendarIdentifier))
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: calendarManager.selectedCalendarID) { _, _ in
                            _Concurrency.Task { await calendarManager.refreshAll() }
                        }

                        Text(NSLocalizedString(
                            "settings.select.the.calendar.used.for.schoolacademic.events",
                            value: "Select the calendar used for school/academic events.",
                            comment: "Select the calendar used for school/academic event..."
                        ))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    }

                    Section("Scheduling") {
                        Picker("Refresh Range", selection: Binding(
                            get: { refreshRangeOption },
                            set: { newValue in
                                switch newValue {
                                case 0: UserDefaults.standard.set(7, forKey: "calendarRefreshRangeDays")
                                case 1: UserDefaults.standard.set(14, forKey: "calendarRefreshRangeDays")
                                case 2: UserDefaults.standard.set(30, forKey: "calendarRefreshRangeDays")
                                case 3: UserDefaults.standard.set(60, forKey: "calendarRefreshRangeDays")
                                default: break
                                }
                                // Refresh calendar with new range
                                _Concurrency.Task { await calendarManager.refreshAll() }
                            }
                        )) {
                            Text(NSLocalizedString("settings.1.week", value: "1 Week", comment: "1 Week")).tag(0)
                            Text(NSLocalizedString("settings.2.weeks", value: "2 Weeks", comment: "2 Weeks")).tag(1)
                            Text(NSLocalizedString("settings.1.month", value: "1 Month", comment: "1 Month")).tag(2)
                            Text(NSLocalizedString("settings.2.months", value: "2 Months", comment: "2 Months")).tag(3)
                        }
                        .pickerStyle(.menu)

                        Text(NSLocalizedString(
                            "settings.how.far.ahead.to.scan.for.events.when.refreshing",
                            value: "How far ahead to scan for events when refreshing.",
                            comment: "How far ahead to scan for events when refreshing."
                        ))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    }

                    Section("Calendar View Filter") {
                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.show.only.school.calendar",
                                value: "Show Only School Calendar",
                                comment: "Show Only School Calendar"
                            ),
                            isOn: $settings.showOnlySchoolCalendar
                        )
                        .toggleStyle(.switch)
                        .onChange(of: settings.showOnlySchoolCalendar) { _, _ in
                            settings.save()
                            _Concurrency.Task { await calendarManager.refreshAll() }
                        }

                        Text(settings
                            .showOnlySchoolCalendar ? "Calendar UI will only show events from your school calendar." :
                            "Calendar UI will show events from all calendars.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    AssignmentSyncSection()
                }
            }
            .formStyle(.grouped)
            .listSectionSpacing(10)
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .controlBackgroundColor))
            .navigationTitle("Calendar")
            .alert("Disable Calendar Sync", isPresented: $showingRevokeAlert) {
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
                    value: "To disconnect Itori from your Calendar, please revoke access in System Settings > Privacy & Security > Calendars.",
                    comment: "To disconnect Itori from your Calendar, please rev..."
                ))
            }
            .onAppear {
                _Concurrency.Task { await calendarManager.refreshAuthStatus() }
            }
        }

        private var refreshRangeDays: Int {
            UserDefaults.standard.integer(forKey: "calendarRefreshRangeDays") != 0
                ? UserDefaults.standard.integer(forKey: "calendarRefreshRangeDays")
                : 14
        }

        private var refreshRangeOption: Int {
            switch refreshRangeDays {
            case 7: 0
            case 14: 1
            case 30: 2
            case 60: 3
            default: 1
            }
        }
    }

    // MARK: - Assignment Sync Section

    struct AssignmentSyncSection: View {
        @StateObject private var syncManager = AssignmentCalendarSyncManager.shared
        @State private var showingPermissionAlert = false

        var body: some View {
            Section("Assignment Sync") {
                Toggle(
                    NSLocalizedString(
                        "settings.toggle.sync.assignments.to.calendar",
                        value: "Sync Assignments to Calendar",
                        comment: "Sync Assignments to Calendar"
                    ),
                    isOn: Binding(
                        get: { syncManager.isSyncEnabled },
                        set: { newValue in
                            handleToggleChange(newValue)
                        }
                    )
                )
                .toggleStyle(.switch)

                Text(NSLocalizedString(
                    "settings.automatically.create.calendar.events.for",
                    value: "Automatically create calendar events for your assignments.",
                    comment: "Automatically create calendar events for your assi..."
                ))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

                if syncManager.isSyncEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(NSLocalizedString("settings.last.sync", value: "Last Sync:", comment: "Last Sync:"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(.secondary)
                            if let lastSync = syncManager.lastSyncDate {
                                Text(lastSync, style: .relative)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(NSLocalizedString("settings.never", value: "Never", comment: "Never"))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !syncManager.syncErrors.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(verbatim: "\(syncManager.syncErrors.count) sync errors")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.orange)
                            }
                        }

                        Button(NSLocalizedString("settings.button.sync.now", value: "Sync Now", comment: "Sync Now")) {
                            Task {
                                await syncManager.performFullSync()
                            }
                        }
                        .buttonStyle(.itariLiquidProminent)
                        .tint(.accentColor)
                        .controlSize(.small)
                    }
                    .padding(.top, 4)
                }
            }
            .alert("Calendar Permission Required", isPresented: $showingPermissionAlert) {
                Button(NSLocalizedString(
                    "settings.button.grant.access",
                    value: "Grant Access",
                    comment: "Grant Access"
                )) {
                    Task {
                        let granted = await syncManager.requestPermissionsIfNeeded()
                        if granted {
                            syncManager.setSyncEnabled(true)
                        }
                    }
                }
                Button(NSLocalizedString("Cancel", value: "Cancel", comment: ""), role: .cancel) {}
            } message: {
                Text(NSLocalizedString(
                    "settings.itori.needs.access.to.your",
                    value: "Itori needs access to your calendar to sync assignments. You can grant this in System Settings if you previously denied access.",
                    comment: "Itori needs access to your calendar to sync assign..."
                ))
            }
        }

        private func handleToggleChange(_ newValue: Bool) {
            if newValue {
                Task {
                    let hasPermission = await syncManager.requestPermissionsIfNeeded()
                    if hasPermission {
                        syncManager.setSyncEnabled(true)
                    } else {
                        showingPermissionAlert = true
                    }
                }
            } else {
                syncManager.setSyncEnabled(false)
            }
        }
    }

    #if !DISABLE_PREVIEWS
        #if !DISABLE_PREVIEWS
            #Preview {
                CalendarSettingsView()
                    .environmentObject(CalendarManager.shared)
                    .environmentObject(AppSettingsModel.shared)
                    .frame(width: 500, height: 600)
            }
        #endif
    #endif
#endif
