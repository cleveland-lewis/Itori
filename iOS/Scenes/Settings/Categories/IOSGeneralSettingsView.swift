import SwiftUI
import Combine
#if os(iOS)

struct IOSGeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: binding(for: \.isSchoolModeStorage)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.isSchoolMode ? "School Mode" : "Self-Study Mode")
                            .font(.body.weight(.medium))
                        Text(settings.isSchoolMode 
                             ? "Organize studies with courses, semesters, and assignments" 
                             : "Study independently without course structure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Study Mode")
            }
            
            Section {
                Toggle(isOn: binding(for: \.use24HourTimeStorage)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.general.use_24h", comment: "Use 24-Hour Time"))
                        Text(NSLocalizedString("settings.general.use_24h.detail", comment: "Display times in 24-hour format"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                HStack {
                    Text(NSLocalizedString("settings.general.workday_start", comment: "Workday Start"))
                    Spacer()
                    Picker("", selection: binding(for: \.workdayStartHourStorage)) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                }
                
                HStack {
                    Text(NSLocalizedString("settings.general.workday_end", comment: "Workday End"))
                    Spacer()
                    Picker("", selection: binding(for: \.workdayEndHourStorage)) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                }
            } header: {
                Text(NSLocalizedString("settings.general.workday.header", comment: "Workday Hours"))
            } footer: {
                Text(NSLocalizedString("settings.general.workday.footer", comment: "Affects planner scheduling and energy tracking"))
            }
            
            Section {
                Toggle(isOn: binding(for: \.showEnergyPanelStorage)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.general.show_energy", comment: "Show Energy Panel"))
                        Text(NSLocalizedString("settings.general.show_energy.detail", comment: "Display energy levels in dashboard and planner"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: binding(for: \.highContrastModeStorage)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.general.high_contrast", comment: "High Contrast"))
                        Text(NSLocalizedString("settings.general.high_contrast.detail", comment: "Increase visual contrast for better readability"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(NSLocalizedString("settings.general.display.header", comment: "Display"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.general", comment: "General"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatHour(_ hour: Int) -> String {
        if settings.use24HourTime {
            return String(format: "%02d:00", hour)
        } else {
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let period = hour < 12 ? NSLocalizedString("time.am", comment: "AM") : NSLocalizedString("time.pm", comment: "PM")
            return "\(displayHour):00 \(period)"
        }
    }

    private func binding<Value>(for keyPath: ReferenceWritableKeyPath<AppSettingsModel, Value>) -> Binding<Value> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { newValue in
                settings.objectWillChange.send()
                settings[keyPath: keyPath] = newValue
                settings.save()
            }
        )
    }
}

#Preview {
    NavigationStack {
        IOSGeneralSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
