import SwiftUI
#if os(iOS)
    import UserNotifications

    struct IOSNotificationsSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @StateObject private var notificationManager = NotificationManager.shared
        @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
        @State private var showingPermissionAlert = false

        var body: some View {
            List {
                if authorizationStatus == .denied {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.largeTitle)
                                .imageScale(.large)
                                .foregroundColor(.secondary)

                            Text(NSLocalizedString(
                                "settings.notifications.disabled.title",
                                comment: "Notifications Disabled"
                            ))
                            .font(.headline)

                            Text(NSLocalizedString(
                                "settings.notifications.disabled.message",
                                comment: "Enable notifications in iOS Settings to receive reminders and alerts"
                            ))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                            Button {
                                notificationManager.openNotificationSettings()
                            } label: {
                                Text(NSLocalizedString(
                                    "settings.notifications.open_settings",
                                    comment: "Open Settings"
                                ))
                            }
                            .buttonStyle(.itariLiquid)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        Toggle(isOn: Binding(
                            get: {
                                settings.notificationsEnabled && authorizationStatus == .authorized
                            },
                            set: { newValue in
                                handleMasterToggle(enabled: newValue)
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString(
                                    "settings.notifications.enable",
                                    comment: "Enable Notifications"
                                ))
                                Text(NSLocalizedString(
                                    "settings.notifications.enable.detail",
                                    comment: "Receive reminders and alerts"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text(NSLocalizedString("settings.notifications.general.header", comment: "General"))
                    }

                    let isEnabled = settings.notificationsEnabled && authorizationStatus == .authorized

                    Section {
                        Toggle(isOn: Binding(
                            get: { settings.assignmentRemindersEnabled },
                            set: { newValue in
                                settings.assignmentRemindersEnabled = newValue
                                if newValue {
                                    notificationManager.scheduleAllAssignmentReminders()
                                } else {
                                    notificationManager.cancelAllAssignmentReminders()
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString(
                                    "settings.notifications.assignments",
                                    comment: "Assignment Reminders"
                                ))
                                Text(NSLocalizedString(
                                    "settings.notifications.assignments.detail",
                                    comment: "Remind me before assignments are due"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .disabled(!isEnabled)

                        if settings.assignmentRemindersEnabled {
                            Picker(selection: Binding(
                                get: { leadTimeOption },
                                set: { newValue in
                                    let newLeadTime: TimeInterval = switch newValue {
                                    case 0: 900 // 15 min
                                    case 1: 1800 // 30 min
                                    case 2: 3600 // 1 hour
                                    case 3: 7200 // 2 hours
                                    case 4: 21600 // 6 hours
                                    case 5: 43200 // 12 hours
                                    case 6: 86400 // 1 day
                                    case 7: 172_800 // 2 days
                                    default: 3600
                                    }
                                    settings.assignmentLeadTime = newLeadTime
                                    // Reschedule all assignment reminders with new lead time
                                    notificationManager.cancelAllAssignmentReminders()
                                    notificationManager.scheduleAllAssignmentReminders()
                                }
                            )) {
                                Text(NSLocalizedString(
                                    "settings.notifications.lead_time.15_min",
                                    comment: "15 minutes"
                                )).tag(0)
                                Text(NSLocalizedString(
                                    "settings.notifications.lead_time.30_min",
                                    comment: "30 minutes"
                                )).tag(1)
                                Text(NSLocalizedString("settings.notifications.lead_time.1_hour", comment: "1 hour"))
                                    .tag(2)
                                Text(NSLocalizedString("settings.notifications.lead_time.2_hours", comment: "2 hours"))
                                    .tag(3)
                                Text(NSLocalizedString("settings.notifications.lead_time.6_hours", comment: "6 hours"))
                                    .tag(4)
                                Text(NSLocalizedString(
                                    "settings.notifications.lead_time.12_hours",
                                    comment: "12 hours"
                                )).tag(5)
                                Text(NSLocalizedString("settings.notifications.lead_time.1_day", comment: "1 day"))
                                    .tag(6)
                                Text(NSLocalizedString("settings.notifications.lead_time.2_days", comment: "2 days"))
                                    .tag(7)
                            } label: {
                                Text(NSLocalizedString(
                                    "settings.notifications.lead_time",
                                    comment: "Reminder Lead Time"
                                ))
                            }
                            .disabled(!isEnabled)
                        }
                    } header: {
                        Text(NSLocalizedString("settings.notifications.reminders.header", comment: "Reminders"))
                    }

                    Section {
                        Toggle(isOn: Binding(
                            get: { settings.dailyOverviewEnabled },
                            set: { newValue in
                                settings.dailyOverviewEnabled = newValue
                                if newValue {
                                    notificationManager.scheduleDailyOverview()
                                } else {
                                    notificationManager.cancelDailyOverview()
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString(
                                    "settings.notifications.daily_overview",
                                    comment: "Daily Overview"
                                ))
                                Text(NSLocalizedString(
                                    "settings.notifications.daily_overview.detail",
                                    comment: "Morning summary of today's schedule"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .disabled(!isEnabled)

                        if settings.dailyOverviewEnabled {
                            DatePicker(
                                NSLocalizedString("settings.notifications.overview_time", comment: "Overview Time"),
                                selection: Binding(
                                    get: { settings.dailyOverviewTime },
                                    set: { newValue in
                                        settings.dailyOverviewTime = newValue
                                        notificationManager.scheduleDailyOverview()
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .disabled(!isEnabled)
                        }
                    } header: {
                        Text(NSLocalizedString("settings.notifications.summaries.header", comment: "Summaries"))
                    }

                    Section {
                        Toggle(isOn: Binding(
                            get: { settings.affirmationsEnabled },
                            set: { newValue in
                                settings.affirmationsEnabled = newValue
                                if newValue {
                                    notificationManager.scheduleMotivationalMessages()
                                } else {
                                    notificationManager.cancelMotivationalMessages()
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString(
                                    "settings.notifications.affirmations",
                                    comment: "Motivational Messages"
                                ))
                                Text(NSLocalizedString(
                                    "settings.notifications.affirmations.detail",
                                    comment: "Receive encouraging notifications"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .disabled(!isEnabled)
                    } header: {
                        Text(NSLocalizedString("settings.notifications.motivation.header", comment: "Motivation"))
                    }

                    #if DEBUG
                        Section {
                            Button {
                                notificationManager.printPendingNotifications()
                            } label: {
                                Label(
                                    NSLocalizedString(
                                        "settings.notifications.debug.print",
                                        comment: "Print Pending Notifications"
                                    ),
                                    systemImage: "list.bullet"
                                )
                            }

                            Button {
                                notificationManager.sendTestNotification()
                            } label: {
                                Label(
                                    NSLocalizedString(
                                        "settings.notifications.debug.test",
                                        comment: "Send Test Notification (5s)"
                                    ),
                                    systemImage: "paperplane"
                                )
                            }
                        } header: {
                            Text(NSLocalizedString("settings.notifications.debug.header", comment: "Debug"))
                        }
                    #endif
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("settings.category.notifications", comment: "Notifications"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                NSLocalizedString("settings.notifications.permission.denied.title", comment: "Notifications Disabled"),
                isPresented: $showingPermissionAlert
            ) {
                Button(NSLocalizedString("settings.notifications.permission.open_settings", comment: "Open Settings")) {
                    notificationManager.openNotificationSettings()
                }
                Button(NSLocalizedString("common.cancel", comment: "Cancel"), role: .cancel) {}
            } message: {
                Text(NSLocalizedString(
                    "settings.notifications.permission.denied.message",
                    comment: "Please enable notifications in Settings to use this feature"
                ))
            }
            .task {
                checkAuthorizationStatus()
            }
        }

        private var leadTimeOption: Int {
            let time = settings.assignmentLeadTime
            switch time {
            case 900: return 0
            case 1800: return 1
            case 3600: return 2
            case 7200: return 3
            case 21600: return 4
            case 43200: return 5
            case 86400: return 6
            case 172_800: return 7
            default: return 2
            }
        }

        private func checkAuthorizationStatus() {
            UNUserNotificationCenter.current().getNotificationSettings { settingsObj in
                DispatchQueue.main.async {
                    authorizationStatus = settingsObj.authorizationStatus
                }
            }
        }

        private func handleMasterToggle(enabled: Bool) {
            if enabled {
                // Request permission
                notificationManager.requestAuthorization()

                // Check result after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    checkAuthorizationStatus()
                    if authorizationStatus == .authorized {
                        settings.notificationsEnabled = true
                        scheduleAllNotifications()
                    } else if authorizationStatus == .denied {
                        settings.notificationsEnabled = false
                        showingPermissionAlert = true
                    }
                }
            } else {
                // Disable and cancel all
                settings.notificationsEnabled = false
                notificationManager.cancelAllScheduledNotifications()
            }
        }

        private func scheduleAllNotifications() {
            if settings.assignmentRemindersEnabled {
                notificationManager.scheduleAllAssignmentReminders()
            }

            if settings.dailyOverviewEnabled {
                notificationManager.scheduleDailyOverview()
            }

            if settings.affirmationsEnabled {
                notificationManager.scheduleMotivationalMessages()
            }
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            NavigationStack {
                IOSNotificationsSettingsView()
                    .environmentObject(AppSettingsModel.shared)
            }
        }
    #endif
#endif
