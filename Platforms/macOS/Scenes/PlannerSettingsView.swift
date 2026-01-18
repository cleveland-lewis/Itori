#if os(macOS)
    import SwiftUI

    struct PlannerSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel

        var body: some View {
            Form {
                Section("planner.settings.section.title".localized) {
                    Text(NSLocalizedString(
                        "settings.llm.settings.moved",
                        value: "LLM assistance is configured in Settings → LLM.",
                        comment: "Planner settings LLM configuration note"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(NSLocalizedString(
                                "planner.settings.planning_ahead",
                                value: "Planning Ahead",
                                comment: "Planning Ahead label"
                            ))

                            Spacer()

                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .help(NSLocalizedString(
                                    "planner.settings.planning_ahead.hint",
                                    value: "How far ahead the planner will schedule events",
                                    comment: "Planning ahead tooltip"
                                ))
                        }

                        Picker("", selection: Binding(
                            get: { settings.plannerHorizon },
                            set: { newValue in settings.plannerHorizon = newValue
                                settings.save()
                            }
                        )) {
                            Text(NSLocalizedString(
                                "planner.settings.horizon.one_week",
                                value: "planner.settings.horizon.one_week",
                                comment: ""
                            )).tag("1w")
                            Text(NSLocalizedString(
                                "planner.settings.horizon.two_weeks",
                                value: "planner.settings.horizon.two_weeks",
                                comment: ""
                            )).tag("2w")
                            Text(NSLocalizedString(
                                "planner.settings.horizon.one_month",
                                value: "planner.settings.horizon.one_month",
                                comment: ""
                            )).tag("1m")
                            Text(NSLocalizedString(
                                "planner.settings.horizon.two_months",
                                value: "planner.settings.horizon.two_months",
                                comment: ""
                            )).tag("2m")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
            }
            .formStyle(.grouped)
            .listSectionSpacing(10)
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
#endif
