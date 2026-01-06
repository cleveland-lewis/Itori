#if os(macOS)
import SwiftUI

struct PlannerSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel

    var body: some View {
        Form {
            Section("planner.settings.section.title".localized) {
                Toggle("planner.settings.enable_ai".localized, isOn: Binding(
                    get: { settings.enableAIPlanner },
                    set: { newValue in settings.enableAIPlanner = newValue; settings.save() }
                ))
                .toggleStyle(.switch)
                .onChange(of: settings.enableAIPlanner) { _, _ in settings.save() }

                Toggle(NSLocalizedString("settings.toggle.show.energy.panel", value: "Show Energy Panel", comment: "Show Energy Panel"), isOn: $settings.showEnergyPanel)
                    .toggleStyle(.switch)
                    .onChange(of: settings.showEnergyPanel) { _, _ in settings.save() }
                Text(NSLocalizedString("settings.turning.off.energy.panel.will", value: "Turning off Energy Panel will make the planning algorithm default to medium energy for all days.", comment: "Turning off Energy Panel will make the planning al..."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("planner.settings.horizon".localized, selection: Binding(
                    get: { settings.plannerHorizon },
                    set: { newValue in settings.plannerHorizon = newValue; settings.save() }
                )) {
                    Text(NSLocalizedString("planner.settings.horizon.one_week", value: "planner.settings.horizon.one_week", comment: "")).tag("1w")
                    Text(NSLocalizedString("planner.settings.horizon.two_weeks", value: "planner.settings.horizon.two_weeks", comment: "")).tag("2w")
                    Text(NSLocalizedString("planner.settings.horizon.one_month", value: "planner.settings.horizon.one_month", comment: "")).tag("1m")
                    Text(NSLocalizedString("planner.settings.horizon.two_months", value: "planner.settings.horizon.two_months", comment: "")).tag("2m")
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
    }
}
#endif
