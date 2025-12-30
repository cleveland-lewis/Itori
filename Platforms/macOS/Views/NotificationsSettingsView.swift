#if os(macOS)
import SwiftUI

struct NotificationsSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var badgeManager = BadgeManager.shared
    
    var body: some View {
        Form {
            Section {
                Text("Configure when and how Roots sends you notifications.")
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
            Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
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

                Button("Open System Settings") {
                    notificationManager.openNotificationSettings()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var notificationWarningText: String {
        switch notificationManager.authorizationState {
        case .denied:
            return "Notifications are disabled. Enable them in System Settings to receive alerts."
        case .error(let message):
            return "Notifications could not be enabled (\(message)). You can enable them in System Settings."
        case .notRequested, .granted:
            return "Notifications may be disabled in System Settings. Please enable them to receive alerts."
        }
    }
    
    private var timerSection: some View {
        Section("Timer") {
            Toggle("Timer Complete Alerts", isOn: $settings.timerAlertsEnabled)
                .toggleStyle(.switch)
                .onChange(of: settings.timerAlertsEnabled) { _, _ in
                    settings.save()
                }

            Text("Get notified when countdown or stopwatch timers complete")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
        }
    }
    
    private var pomodoroSection: some View {
        Section("Pomodoro") {
            Toggle("Pomodoro Alerts", isOn: $settings.pomodoroAlertsEnabled)
                .toggleStyle(.switch)
                .onChange(of: settings.pomodoroAlertsEnabled) { _, _ in
                    settings.save()
                }

            Text("Get notified when work sessions and breaks complete")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
        }
    }
    
    private var assignmentSection: some View {
        Section("Assignments") {
            Toggle("Assignment Reminders", isOn: $settings.assignmentRemindersEnabled)
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
                    Text("Remind me:")
                        .font(.subheadline)
                        .padding(.leading, 20)

                    Picker("Lead Time", selection: $settings.assignmentLeadTime) {
                        Text("15 minutes before").tag(TimeInterval(15 * 60))
                        Text("30 minutes before").tag(TimeInterval(30 * 60))
                        Text("1 hour before").tag(TimeInterval(60 * 60))
                        Text("2 hours before").tag(TimeInterval(2 * 60 * 60))
                        Text("1 day before").tag(TimeInterval(24 * 60 * 60))
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

            Text("Get notified before assignments are due")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
        }
    }
    
    private var dailyOverviewSection: some View {
        Section("Daily Overview") {
            Toggle("Daily Overview", isOn: $settings.dailyOverviewEnabled)
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
                    Text("Include in overview:")
                        .font(.subheadline)
                        .padding(.leading, 20)
                        .padding(.top, 8)

                    Toggle("Today's due assignments", isOn: $settings.dailyOverviewIncludeTasks)
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeTasks) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }

                    Toggle("Today's calendar events", isOn: $settings.dailyOverviewIncludeEvents)
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeEvents) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }

                    Toggle("Yesterday's completed tasks", isOn: $settings.dailyOverviewIncludeYesterdayCompleted)
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeYesterdayCompleted) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }

                    Toggle("Yesterday's study time", isOn: $settings.dailyOverviewIncludeYesterdayStudyTime)
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeYesterdayStudyTime) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }

                    Toggle("Motivational message", isOn: $settings.dailyOverviewIncludeMotivation)
                        .toggleStyle(.switch)
                        .padding(.leading, 40)
                        .onChange(of: settings.dailyOverviewIncludeMotivation) { _, _ in
                            settings.save()
                            NotificationManager.shared.scheduleDailyOverview()
                        }
                }
            }

            Text("Receive a daily summary of your schedule and tasks")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
        }
    }
    
    private var motivationalSection: some View {
        Section("Motivational Messages") {
            Toggle("Motivational Messages", isOn: $settings.affirmationsEnabled)
                .toggleStyle(.switch)
                .onChange(of: settings.affirmationsEnabled) { _, newValue in
                    settings.save()
                    if newValue {
                        notificationManager.scheduleMotivationalMessages()
                    } else {
                        notificationManager.cancelMotivationalMessages()
                    }
                }

            Text("Receive encouraging notifications throughout the day")
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

            Text("Choose what the app icon badge count represents")
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
