import SwiftUI

struct FlashcardSettingsView: View {
    @EnvironmentObject private var settings: AppSettingsModel

    var body: some View {
        Form {
            Section("Flashcards") {
                Toggle("Enable Flashcards", isOn: $settings.enableFlashcards)
                    .onChange(of: settings.enableFlashcards) { _, _ in settings.save() }
            }

            Section {
                Text(NSLocalizedString("Turn flashcards on or off across the app. Disabling hides related UI and study flows.", value: "Turn flashcards on or off across the app. Disabling hides related UI and study flows.", comment: ""))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Flashcards")
    }
}
