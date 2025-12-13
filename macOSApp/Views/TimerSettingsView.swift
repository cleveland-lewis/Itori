#if os(macOS)
import SwiftUI

struct TimerSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel

    var body: some View {
        Form {
            Section {
                Stepper("Focus Duration: \(settings.pomodoroFocusMinutes) minutes", value: $settings.pomodoroFocusMinutes, in: 5...60, step: 5)
                    .onChange(of: settings.pomodoroFocusMinutes) { _, _ in
                        settings.save()
                    }
                
                Stepper("Short Break: \(settings.pomodoroShortBreakMinutes) minutes", value: $settings.pomodoroShortBreakMinutes, in: 1...15)
                    .onChange(of: settings.pomodoroShortBreakMinutes) { _, _ in
                        settings.save()
                    }
                
                Stepper("Long Break: \(settings.pomodoroLongBreakMinutes) minutes", value: $settings.pomodoroLongBreakMinutes, in: 10...60, step: 5)
                    .onChange(of: settings.pomodoroLongBreakMinutes) { _, _ in
                        settings.save()
                    }

                Stepper("Iterations per Set: \(settings.pomodoroIterations)", value: $settings.pomodoroIterations, in: 1...12)
                    .onChange(of: settings.pomodoroIterations) { _, _ in
                        settings.save()
                    }

                Stepper("Long Break After: \(settings.longBreakCadence) iterations", value: $settings.longBreakCadence, in: 1...12)
                    .onChange(of: settings.longBreakCadence) { _, _ in
                        settings.save()
                    }

            } header: {
                Text("Pomodoro Timer")
            } footer: {
                Text("Configure Pomodoro work/break durations and iteration behavior. Changes apply to new timer sessions.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Timer")
    }
}
#endif
