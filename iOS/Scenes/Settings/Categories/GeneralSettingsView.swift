import SwiftUI
#if os(iOS)

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: $settings.use24HourTimeStorage) {
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
                    Picker("", selection: $settings.workdayStartHourStorage) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                }
                
                HStack {
                    Text(NSLocalizedString("settings.general.workday_end", comment: "Workday End"))
                    Spacer()
                    Picker("", selection: $settings.workdayEndHourStorage) {
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
                Toggle(isOn: $settings.showEnergyPanelStorage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.general.show_energy", comment: "Show Energy Panel"))
                        Text(NSLocalizedString("settings.general.show_energy.detail", comment: "Display energy levels in dashboard and planner"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $settings.highContrastModeStorage) {
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
        if settings.use24HourTimeStorage {
            return String(format: "%02d:00", hour)
        } else {
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let period = hour < 12 ? NSLocalizedString("time.am", comment: "AM") : NSLocalizedString("time.pm", comment: "PM")
            return "\(displayHour):00 \(period)"
        }
    }
}

#Preview {
    NavigationStack {
        GeneralSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
