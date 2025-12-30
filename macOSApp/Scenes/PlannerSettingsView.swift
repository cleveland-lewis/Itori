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

                Toggle("Show Energy Panel", isOn: $settings.showEnergyPanel)
                    .toggleStyle(.switch)
                    .onChange(of: settings.showEnergyPanel) { _, _ in settings.save() }
                Text("settings.planner.energy_tracking.warning".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("planner.settings.horizon".localized, selection: Binding(
                    get: { settings.plannerHorizon },
                    set: { newValue in settings.plannerHorizon = newValue; settings.save() }
                )) {
                    Text("planner.settings.horizon.one_week".localized).tag("1w")
                    Text("planner.settings.horizon.two_weeks".localized).tag("2w")
                    Text("planner.settings.horizon.one_month".localized).tag("1m")
                    Text("planner.settings.horizon.two_months".localized).tag("2m")
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
    }
}
#endif
