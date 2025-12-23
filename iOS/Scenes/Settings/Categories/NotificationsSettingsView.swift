import SwiftUI
#if os(iOS)
import UserNotifications

struct NotificationsSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        List {
            if notificationStatus == .denied {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(NSLocalizedString("settings.notifications.disabled.title", comment: "Notifications Disabled"))
                            .font(.headline)
                        
                        Text(NSLocalizedString("settings.notifications.disabled.message", comment: "Enable notifications in iOS Settings to receive reminders and alerts"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            openAppSettings()
                        } label: {
                            Text(NSLocalizedString("settings.notifications.open_settings", comment: "Open Settings"))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    Toggle(isOn: Binding(
                        get: { settings.notificationsEnabledStorage && notificationStatus == .authorized },
                        set: { newValue in
                            if newValue {
                                requestNotificationPermission()
                            } else {
                                settings.notificationsEnabledStorage = false
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("settings.notifications.enable", comment: "Enable Notifications"))
                            Text(NSLocalizedString("settings.notifications.enable.detail", comment: "Receive reminders and alerts"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(NSLocalizedString("settings.notifications.general.header", comment: "General"))
                }
                
                if settings.notificationsEnabledStorage && notificationStatus == .authorized {
                    Section {
                        Toggle(isOn: $settings.assignmentRemindersEnabledStorage) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString("settings.notifications.assignments", comment: "Assignment Reminders"))
                                Text(NSLocalizedString("settings.notifications.assignments.detail", comment: "Remind me before assignments are due"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if settings.assignmentRemindersEnabledStorage {
                            Picker(selection: Binding(
                                get: { leadTimeOption },
                                set: { newValue in
                                    switch newValue {
                                    case 0: settings.assignmentLeadTimeStorage = 300 // 5 min
                                    case 1: settings.assignmentLeadTimeStorage = 900 // 15 min
                                    case 2: settings.assignmentLeadTimeStorage = 1800 // 30 min
                                    case 3: settings.assignmentLeadTimeStorage = 3600 // 1 hour
                                    case 4: settings.assignmentLeadTimeStorage = 7200 // 2 hours
                                    default: break
                                    }
                                }
                            )) {
                                Text(NSLocalizedString("settings.notifications.lead_time.5_min", comment: "5 minutes")).tag(0)
                                Text(NSLocalizedString("settings.notifications.lead_time.15_min", comment: "15 minutes")).tag(1)
                                Text(NSLocalizedString("settings.notifications.lead_time.30_min", comment: "30 minutes")).tag(2)
                                Text(NSLocalizedString("settings.notifications.lead_time.1_hour", comment: "1 hour")).tag(3)
                                Text(NSLocalizedString("settings.notifications.lead_time.2_hours", comment: "2 hours")).tag(4)
                            } label: {
                                Text(NSLocalizedString("settings.notifications.lead_time", comment: "Reminder Lead Time"))
                            }
                        }
                    } header: {
                        Text(NSLocalizedString("settings.notifications.reminders.header", comment: "Reminders"))
                    }
                    
                    Section {
                        Toggle(isOn: $settings.dailyOverviewEnabledStorage) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString("settings.notifications.daily_overview", comment: "Daily Overview"))
                                Text(NSLocalizedString("settings.notifications.daily_overview.detail", comment: "Morning summary of today's schedule"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if settings.dailyOverviewEnabledStorage {
                            DatePicker(
                                NSLocalizedString("settings.notifications.overview_time", comment: "Overview Time"),
                                selection: $settings.dailyOverviewTimeStorage,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    } header: {
                        Text(NSLocalizedString("settings.notifications.summaries.header", comment: "Summaries"))
                    }
                    
                    Section {
                        Toggle(isOn: $settings.affirmationsEnabledStorage) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString("settings.notifications.affirmations", comment: "Motivational Messages"))
                                Text(NSLocalizedString("settings.notifications.affirmations.detail", comment: "Receive encouraging notifications"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text(NSLocalizedString("settings.notifications.motivation.header", comment: "Motivation"))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.notifications", comment: "Notifications"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private var leadTimeOption: Int {
        let time = settings.assignmentLeadTimeStorage
        switch time {
        case 300: return 0
        case 900: return 1
        case 1800: return 2
        case 3600: return 3
        case 7200: return 4
        default: return 3
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    settings.notificationsEnabledStorage = true
                    notificationStatus = .authorized
                } else {
                    settings.notificationsEnabledStorage = false
                }
                checkNotificationStatus()
            }
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
