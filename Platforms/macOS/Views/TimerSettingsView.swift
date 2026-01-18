#if os(macOS)
    import SwiftUI

    struct TimerSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @StateObject private var notificationManager = NotificationManager.shared

        var body: some View {
            Form {
                Section("Timer Display") {
                    Picker(
                        NSLocalizedString(
                            "settings.timer.display",
                            value: "Display Style",
                            comment: "Display Style"
                        ),
                        selection: $settings.timerAppearanceStorage
                    ) {
                        Text(NSLocalizedString(
                            "settings.timer.analog",
                            value: "Analog",
                            comment: "Analog"
                        )).tag("analog")
                        Text(NSLocalizedString(
                            "settings.timer.digital",
                            value: "Digital",
                            comment: "Digital"
                        )).tag("digital")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settings.timerAppearanceStorage) { _, _ in
                        settings.save()
                    }

                    Stepper(
                        "Default Timer Duration: \(settings.timerDurationStorage) minutes",
                        value: $settings.timerDurationStorage,
                        in: 1 ... 120,
                        step: 5
                    )
                    .onChange(of: settings.timerDurationStorage) { _, _ in
                        settings.save()
                    }

                    Text(NSLocalizedString(
                        "settings.timer.display.description",
                        value: "Choose how the timer appears and set the default duration for countdown timers.",
                        comment: "Timer display description"
                    ))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                }

                Section {
                    Stepper(
                        "Work Duration: \(settings.pomodoroFocusMinutes) minutes",
                        value: $settings.pomodoroFocusMinutes,
                        in: 5 ... 60,
                        step: 5
                    )
                    .onChange(of: settings.pomodoroFocusMinutes) { _, _ in
                        settings.save()
                    }

                    Stepper(
                        "Short Break: \(settings.pomodoroShortBreakMinutes) minutes",
                        value: $settings.pomodoroShortBreakMinutes,
                        in: 1 ... 15
                    )
                    .onChange(of: settings.pomodoroShortBreakMinutes) { _, _ in
                        settings.save()
                    }

                    Stepper(
                        "Long Break: \(settings.pomodoroLongBreakMinutes) minutes",
                        value: $settings.pomodoroLongBreakMinutes,
                        in: 10 ... 60,
                        step: 5
                    )
                    .onChange(of: settings.pomodoroLongBreakMinutes) { _, _ in
                        settings.save()
                    }

                    Stepper(
                        "Iterations per Set: \(settings.pomodoroIterations)",
                        value: $settings.pomodoroIterations,
                        in: 1 ... 12
                    )
                    .onChange(of: settings.pomodoroIterations) { _, _ in
                        settings.save()
                    }

                    Stepper(
                        "Long Break After: \(settings.longBreakCadence) iterations",
                        value: $settings.longBreakCadence,
                        in: 1 ... 12
                    )
                    .onChange(of: settings.longBreakCadence) { _, _ in
                        settings.save()
                    }

                } header: {
                    Text(NSLocalizedString(
                        "settings.pomodoro.timer",
                        value: "Pomodoro Timer",
                        comment: "Pomodoro Timer"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.configure.pomodoro.workbreak.durations.and",
                        value: "Configure Pomodoro work/break durations and iteration behavior. Changes apply to new timer sessions.",
                        comment: "Configure Pomodoro work/break durations and iterat..."
                    ))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                }

                Section("Timer Notifications") {
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
                }

                Section("Pomodoro Notifications") {
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
                }
            }
            .formStyle(.grouped)
            .listSectionSpacing(10)
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .controlBackgroundColor))
            .navigationTitle("Timer")
        }
    }
#endif
