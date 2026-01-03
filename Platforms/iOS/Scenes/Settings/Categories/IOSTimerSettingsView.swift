import SwiftUI
#if os(iOS)

struct IOSTimerSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @AppStorage("timer.display.style") private var timerDisplayStyleRaw: String = TimerDisplayStyle.digital.rawValue
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text(NSLocalizedString("settings.timer.focus_duration", comment: "Focus Duration"))
                    Spacer()
                    Text("\(settings.pomodoroFocusStorage) " + NSLocalizedString("time.minutes", comment: "min"))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(settings.pomodoroFocusStorage) },
                    set: { settings.pomodoroFocusStorage = Int($0) }
                ), in: 5...90, step: 5)
                
                HStack {
                    Text(NSLocalizedString("settings.timer.short_break", comment: "Short Break"))
                    Spacer()
                    Text("\(settings.pomodoroShortBreakStorage) " + NSLocalizedString("time.minutes", comment: "min"))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(settings.pomodoroShortBreakStorage) },
                    set: { settings.pomodoroShortBreakStorage = Int($0) }
                ), in: 1...30, step: 1)
                
                HStack {
                    Text(NSLocalizedString("settings.timer.long_break", comment: "Long Break"))
                    Spacer()
                    Text("\(settings.pomodoroLongBreakStorage) " + NSLocalizedString("time.minutes", comment: "min"))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(settings.pomodoroLongBreakStorage) },
                    set: { settings.pomodoroLongBreakStorage = Int($0) }
                ), in: 5...60, step: 5)
                
                Stepper(value: $settings.pomodoroIterationsStorage, in: 1...10) {
                    HStack {
                        Text(NSLocalizedString("settings.timer.iterations", comment: "Pomodoro Cycles"))
                        Spacer()
                        Text("\(settings.pomodoroIterationsStorage)")
                            .foregroundColor(.secondary)
                    }
                }
                
            } header: {
                Text(NSLocalizedString("settings.timer.pomodoro.header", comment: "Pomodoro Settings"))
            }

            Section {
                HStack {
                    Text(NSLocalizedString("settings.timer.timer_duration", comment: "Timer Duration"))
                    Spacer()
                    Text("\(settings.timerDurationMinutes) " + NSLocalizedString("time.minutes", comment: "min"))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(settings.timerDurationMinutes) },
                    set: { settings.timerDurationMinutes = Int($0) }
                ), in: 1...180, step: 1)
            } header: {
                Text(NSLocalizedString("settings.timer.timer_duration", comment: "Timer Duration"))
            }

            Section {
                Picker(NSLocalizedString("settings.timer.display", comment: "Timer display"), selection: timerDisplayStyleBinding) {
                    ForEach(TimerDisplayStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
            } header: {
                Text(NSLocalizedString("settings.timer.display", comment: "Timer display"))
            }
            
            Section {
                Toggle(isOn: $settings.timerAlertsEnabledStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.timer.alerts", comment: "Timer Alerts"))
                        Text(NSLocalizedString("settings.timer.alerts.detail", comment: "Show notification when timer completes"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $settings.pomodoroAlertsEnabledStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.timer.pomodoro_alerts", comment: "Pomodoro Alerts"))
                        Text(NSLocalizedString("settings.timer.pomodoro_alerts.detail", comment: "Alert at each pomodoro phase change"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(NSLocalizedString("settings.timer.alerts.header", comment: "Alerts"))
            }
            
            // Phase 2.3: AlarmKit Settings Section
            Section {
                AlarmKitSettingsRow()
            } header: {
                Text(NSLocalizedString("settings.timer.alarmkit.header", comment: "AlarmKit (iOS/iPadOS Only)"))
            } footer: {
                Text(NSLocalizedString("settings.timer.alarmkit.footer", comment: "AlarmKit provides system-level loud alarms that work even when the app is closed. Requires iOS 26.0 or later."))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.timer", comment: "Timer"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var timerDisplayStyleBinding: Binding<TimerDisplayStyle> {
        Binding(
            get: { TimerDisplayStyle(rawValue: timerDisplayStyleRaw) ?? .digital },
            set: { timerDisplayStyleRaw = $0.rawValue }
        )
    }
}

// MARK: - AlarmKit Settings Row (Phase 2.3)

@available(iOS 17.0, *)
struct AlarmKitSettingsRow: View {
    @EnvironmentObject var settings: AppSettingsModel
    @State private var alarmScheduler = IOSTimerAlarmScheduler()
    @State private var showingAuthAlert = false
    @State private var authorizationMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Availability status
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
            }
            
            if alarmScheduler.alarmKitAvailable {
                // Toggle (disabled if not authorized)
                Toggle(isOn: toggleBinding) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.timer.alarmkit.enable", comment: "Enable AlarmKit"))
                        Text(NSLocalizedString("settings.timer.alarmkit.enable_detail", comment: "Use loud alarms for timer completion"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!alarmScheduler.isAuthorized)
                
                // Authorization button
                if !alarmScheduler.isAuthorized {
                    Button {
                        requestAuthorization()
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                            Text(NSLocalizedString("settings.timer.alarmkit.request_auth", comment: "Request Authorization"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                }
            } else {
                // Not available message
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("settings.timer.alarmkit.unavailable", comment: "AlarmKit is not available on this device."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("settings.timer.alarmkit.requires", comment: "Requires iOS 26.0 or later"))
                        .font(.caption)
                        .foregroundColor(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
        .alert(NSLocalizedString("settings.timer.alarmkit.authorization", comment: "AlarmKit Authorization"), isPresented: $showingAuthAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authorizationMessage)
        }
    }
    
    private var statusIcon: String {
        if !alarmScheduler.alarmKitAvailable {
            return "exclamationmark.triangle"
        } else if alarmScheduler.isAuthorized {
            return "checkmark.circle.fill"
        } else {
            return "bell.slash"
        }
    }
    
    private var statusColor: Color {
        if !alarmScheduler.alarmKitAvailable {
            return .orange
        } else if alarmScheduler.isAuthorized {
            return .green
        } else {
            return .gray
        }
    }
    
    private var statusText: String {
        if !alarmScheduler.alarmKitAvailable {
            return NSLocalizedString("settings.timer.alarmkit.status.unavailable", comment: "Not Available")
        } else if alarmScheduler.isAuthorized {
            return NSLocalizedString("settings.timer.alarmkit.status.authorized", comment: "Authorized")
        } else {
            return NSLocalizedString("settings.timer.alarmkit.status.not_authorized", comment: "Not Authorized")
        }
    }
    
    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { settings.alarmKitTimersEnabledStorage && alarmScheduler.isAuthorized },
            set: { newValue in
                settings.alarmKitTimersEnabledStorage = newValue
            }
        )
    }
    
    private func requestAuthorization() {
        Task {
            let granted = await alarmScheduler.requestAuthorizationIfNeeded()
            await MainActor.run {
                if granted {
                    authorizationMessage = NSLocalizedString("settings.timer.alarmkit.auth_granted", comment: "AlarmKit authorization granted. You can now enable loud alarms.")
                } else {
                    authorizationMessage = NSLocalizedString("settings.timer.alarmkit.auth_denied", comment: "AlarmKit authorization was denied. Please enable it in Settings.")
                }
                showingAuthAlert = true
            }
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSTimerSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
