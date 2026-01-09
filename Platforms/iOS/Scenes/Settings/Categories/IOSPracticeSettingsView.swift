#if os(iOS)
    import SwiftUI

    struct IOSPracticeSettingsView: View {
        @EnvironmentObject private var settings: AppSettingsModel

        var body: some View {
            Form {
                Section {
                    HStack {
                        Text(NSLocalizedString(
                            "settings.practice.multiplier.label",
                            value: "Practice Test Time Multiplier",
                            comment: "Practice test time multiplier label"
                        ))
                        Spacer()
                        Text(String(format: "%.1fx", settings.practiceTestTimeMultiplier))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.practiceTestTimeMultiplier, in: 0.5 ... 2.0, step: 0.1)
                    Text(NSLocalizedString(
                        "settings.practice.multiplier.hint",
                        value: "Adjusts scheduled practice test time per module.",
                        comment: "Practice test multiplier hint"
                    ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } header: {
                    Text(NSLocalizedString(
                        "settings.practice.section",
                        value: "Practice Tests",
                        comment: "Practice settings section title"
                    ))
                }
            }
            .navigationTitle(NSLocalizedString(
                "settings.practice.title",
                value: "Practice",
                comment: "Practice settings title"
            ))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
#endif
