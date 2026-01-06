#if os(macOS)
import SwiftUI

struct PracticeSettingsView: View {
    @EnvironmentObject private var settings: AppSettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("settings.practice.section", value: "Practice Tests", comment: "Practice settings section title"))
                .font(.headline)

            HStack {
                Text(NSLocalizedString("settings.practice.multiplier.label", value: "Practice Test Time Multiplier", comment: "Practice test time multiplier label"))
                Spacer()
                Text(String(format: "%.1fx", settings.practiceTestTimeMultiplier))
                    .foregroundStyle(.secondary)
            }

            Slider(value: $settings.practiceTestTimeMultiplier, in: 0.5...2.0, step: 0.1)

            Text(NSLocalizedString("settings.practice.multiplier.hint", value: "Adjusts scheduled practice test time per module.", comment: "Practice test multiplier hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
