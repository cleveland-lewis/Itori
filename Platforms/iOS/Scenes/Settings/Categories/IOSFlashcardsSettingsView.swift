import SwiftUI
import Combine
#if os(iOS)

struct IOSFlashcardsSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: binding(for: \.enableFlashcards)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.flashcards.enable", value: "Enable Flashcards", comment: "Enable flashcards"))
                        Text(NSLocalizedString("settings.flashcards.enable.detail", value: "Turn flashcard system on or off", comment: "Enable flashcards detail"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(NSLocalizedString("settings.flashcards.system.header", value: "Flashcard System", comment: "Flashcard system header"))
            }
            
            Section {
                Text(NSLocalizedString("settings.flashcards.study.body", value: "Daily limits and study options", comment: "Flashcards study body"))
                    .foregroundColor(.secondary)
            } header: {
                Text(NSLocalizedString("settings.flashcards.study.header", value: "Study Options", comment: "Flashcards study header"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.flashcards", comment: "Flashcards"))
        .navigationBarTitleDisplayMode(.inline)
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

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSFlashcardsSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
