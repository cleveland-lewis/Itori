import SwiftUI
import Combine
#if os(iOS)

struct IOSFlashcardsSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: binding(for: \.enableFlashcardsStorage)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Flashcards")
                        Text("Turn flashcard system on or off")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Flashcard System")
            }
            
            Section {
                Text("Daily limits and study options")
                    .foregroundColor(.secondary)
            } header: {
                Text("Study Options")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Flashcards")
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

#Preview {
    NavigationStack {
        IOSFlashcardsSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
