#if os(macOS)
    import SwiftUI

    struct NotificationsSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @StateObject private var notificationManager = NotificationManager.shared
        @StateObject private var badgeManager = BadgeManager.shared

        var body: some View {
            Form {
                Section {
                    Text(NSLocalizedString(
                        "settings.configure.when.and.how.itori",
                        value: "Configure when and how Itori sends you notifications.",
                        comment: "Configure when and how Itori sends you notificatio..."
                    ))
                    .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)

                masterToggleSection

                if settings.notificationsEnabled {
                    timerSection
                    pomodoroSection
                    assignmentSection
                    badgeSection
                    dailyOverviewSection
                    motivationalSection
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Notifications")
            .onAppear {
                notificationManager.refreshAuthorizationStatus()
            }
        }

        private var masterToggleSection: some View {
            Section("General") {
                Toggle(
                    NSLocalizedString(
                        "settings.toggle.enable.notifications",
                        value: "Enable Notifications",
                        comment: "Enable Notifications"
                    ),
                    isOn: $settings.notificationsEnabled
                )
                .toggleStyle(.switch)
                .onChange(of: settings.notificationsEnabled) { _, newValue in
                    if newValue && !notificationManager.isAuthorized {
                        notificationManager.requestAuthorization()
                    } else if !newValue {
                        // Cancel all notifications when disabled
                        notificationManager.cancelAllScheduledNotifications()
                    }
                    settings.save()
                }

                if settings.notificationsEnabled && !notificationManager.isAuthorized {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(notificationWarningText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                    Button(NSLocalizedString(
                        "settings.button.open.system.settings",
                        value: "Open System Settings",
                        comment: "Open System Settings"
                    )) {
                        notificationManager.openNotificationSettings()
                    }
                    .buttonStyle(.itariLiquid)
                }
            }
        }

        private var notificationWarningText: String {
            switch notificationManager.authorizationState {
            case .denied:
                "Notifications are disabled. Enable them in System Settings to receive alerts."
            case let .error(message):
                "Notifications could not be enabled (\(message)). You can enable them in System Settings."
            case .notRequested, .granted:
                "Notifications may be disabled in System Settings. Please enable them to receive alerts."
            }
        }

        private var timerSection: some View {
            Section("Timer") {
                Toggle(
                    NSLocalizedString(
                        "settings.toggle.timer.complete.alerts",
                        value: "Timer Complete Alerts",
                        comment: "Timer Complete Alerts"
                    ),
                    isOn: $settings.timerAlertsEnabled
                )
                .toggleStyle(.switch)
                .onChange(of: settings.timerAlertsEnabled) { _, _ in
                    settings.save()
                }

                Text(NSLocalizedString(
                    "settings.get.notified.when.countdown.or",
                    value: "Get notified when countdown or stopwatch timers complete",
                    comment: "Get notified when countdown or stopwatch timers co..."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
            }
        }

        private var pomodoroSection: some View {
            Section("Pomodoro") {
                Toggle(
                    NSLocalizedString(
                        "settings.toggle.pomodoro.alerts",
                        value: "Pomodoro Alerts",
                        comment: "Pomodoro Alerts"
                    ),
                    isOn: $settings.pomodoroAlertsEnabled
                )
                .toggleStyle(.switch)
                .onChange(of: settings.pomodoroAlertsEnabled) { _, _ in
                    settings.save()
                }

                Text(NSLocalizedString(
                    "settings.get.notified.when.work.sessions",
                    value: "Get notified when work sessions and breaks complete",
                    comment: "Get notified when work sessions and breaks complet..."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
            }
        }

        private var assignmentSection: some View {
            Section("Assignments") {
                Toggle(
                    NSLocalizedString(
                        "settings.toggle.assignment.reminders",
                        value: "Assignment Reminders",
                        comment: "Assignment Reminders"
                    ),
                    isOn: $settings.assignmentRemindersEnabled
                )
                .toggleStyle(.switch)
                .onChange(of: settings.assignmentRemindersEnabled) { _, newValue in
                    settings.save()
                    if newValue {
                        notificationManager.scheduleAllAssignmentReminders()
                    } else {
                        notificationManager.cancelAllAssignmentReminders()
                    }
                }

                if settings.assignmentRemindersEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("settings.remind.me", value: "Remind me:", comment: "Remind me:"))
                            .font(.subheadline)
                            .padding(.leading, 20)

                        Picker("Lead Time", selection: $settings.assignmentLeadTime) {
                            Text(NSLocalizedString(
                                "settings.15.minutes.before",
                                value: "15 minutes before",
                                comment: "15 minutes before"
                            )).tag(TimeInterval(15 * 60))
                            Text(NSLocalizedString(
                                "settings.30.minutes.before",
                                value: "30 minutes before",
                                comment: "30 minutes before"
                            )).tag(TimeInterval(30 * 60))
                            Text(NSLocalizedString(
                                "settings.1.hour.before",
                                value: "1 hour before",
                                comment: "1 hour before"
                            )).tag(TimeInterval(60 * 60))
                            Text(NSLocalizedString(
                                "settings.2.hours.before",
                                value: "2 hours before",
                                comment: "2 hours before"
                            )).tag(TimeInterval(2 * 60 * 60))
                            Text(NSLocalizedString(
                                "settings.1.day.before",
                                value: "1 day before",
                                comment: "1 day before"
                            )).tag(TimeInterval(24 * 60 * 60))
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding(.leading, 20)
                        .onChange(of: settings.assignmentLeadTime) { _, _ in
                            settings.save()
                            // Reschedule all assignment reminders with new lead time
                            notificationManager.cancelAllAssignmentReminders()
                            notificationManager.scheduleAllAssignmentReminders()
                        }
                    }
                }

                Text(NSLocalizedString(
                    "settings.get.notified.before.assignments.are.due",
                    value: "Get notified before assignments are due",
                    comment: "Get notified before assignments are due"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
            }
        }

        private var dailyOverviewSection: some View {
            Section("Daily Overview") {
                Toggle(
                    NSLocalizedString(
                        "settings.toggle.daily.overview",
                        value: "Daily Overview",
                        comment: "Daily Overview"
                    ),
                    isOn: $settings.dailyOverviewEnabled
                )
                .toggleStyle(.switch)
                .onChange(of: settings.dailyOverviewEnabled) { _, newValue in
                    settings.save()
                    if newValue {
                        NotificationManager.shared.scheduleDailyOverview()
                    } else {
                        NotificationManager.shared.cancelDailyOverview()
                    }
                }

                if settings.dailyOverviewEnabled {
                    DatePicker("Time", selection: $settings.dailyOverviewTime, displayedComponents: .hourAndMinute)
                        .padding(.leading, 20)
                        .onChange(of: settings.dailyOverviewTime) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString(
                            "settings.include.in.overview",
                            value: "Include in overview:",
                            comment: "Include in overview:"
                        ))
                        .font(.subheadline)
                        .padding(.leading, 20)
                        .padding(.top, 8)

                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.todays.due.assignments",
                                value: "Today's due assignments",
                                comment: "Today's due assignments"
                            ),
                            isOn: $settings.dailyOverviewIncludeTasks
                        )
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeTasks) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }

                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.todays.calendar.events",
                                value: "Today's calendar events",
                                comment: "Today's calendar events"
                            ),
                            isOn: $settings.dailyOverviewIncludeEvents
                        )
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeEvents) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }

                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.yesterdays.completed.tasks",
                                value: "Yesterday's completed tasks",
                                comment: "Yesterday's completed tasks"
                            ),
                            isOn: $settings.dailyOverviewIncludeYesterdayCompleted
                        )
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeYesterdayCompleted) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }

                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.yesterdays.study.time",
                                value: "Yesterday's study time",
                                comment: "Yesterday's study time"
                            ),
                            isOn: $settings.dailyOverviewIncludeYesterdayStudyTime
                        )
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeYesterdayStudyTime) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }

                        Toggle(
                            NSLocalizedString(
                                "settings.toggle.motivational.message",
                                value: "Motivational message",
                                comment: "Motivational message"
                            ),
                            isOn: $settings.dailyOverviewIncludeMotivation
                        )
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeMotivation) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }
                    }
                }

                Text(NSLocalizedString(
                    "settings.receive.a.daily.summary.of.your.schedule.and.tasks",
                    value: "Receive a daily summary of your schedule and tasks",
                    comment: "Receive a daily summary of your schedule and tasks"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
            }
        }

        private var motivationalSection: some View {
            Section("Motivational Messages") {
                Toggle(
                    NSLocalizedString(
                        "settings.toggle.motivational.messages",
                        value: "Motivational Messages",
                        comment: "Motivational Messages"
                    ),
                    isOn: $settings.affirmationsEnabled
                )
                .toggleStyle(.switch)
                .onChange(of: settings.affirmationsEnabled) { _, newValue in
                    settings.save()
                    if newValue {
                        notificationManager.scheduleMotivationalMessages()
                    } else {
                        notificationManager.cancelMotivationalMessages()
                    }
                }

                Text(NSLocalizedString(
                    "settings.receive.encouraging.notifications.throughout.the",
                    value: "Receive encouraging notifications throughout the day",
                    comment: "Receive encouraging notifications throughout the d..."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
            }
        }

        private var badgeSection: some View {
            Section("App Icon Badge") {
                Picker("Badge shows:", selection: $badgeManager.badgeSource) {
                    ForEach(BadgeSource.allCases) { source in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(source.displayName)
                            Text(source.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(source)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Text(NSLocalizedString(
                    "settings.choose.what.the.app.icon.badge.count.represents",
                    value: "Choose what the app icon badge count represents",
                    comment: "Choose what the app icon badge count represents"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
            }
        }
    }

    struct NotificationsSettingsView_Previews: PreviewProvider {
        static var previews: some View {
            NotificationsSettingsView()
                .environmentObject(AppSettingsModel.shared)
                .frame(width: 600, height: 500)
        }
    }

#endif
