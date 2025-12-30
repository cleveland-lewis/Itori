#if os(macOS)
import SwiftUI

struct FlashcardSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        Form {
            Section {
                Text("Flashcard Settings")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 4)
                
                Text("Configure flashcard study modes and preferences.")
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            
            Section("Flashcard Feature") {
                Toggle("Enable Flashcards", isOn: binding(for: \.enableFlashcards))
                
                Text("Enable or disable the flashcard study system")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Study Settings") {
                Text("Additional flashcard preferences will be added here")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
    FlashcardSettingsView()
        .environmentObject(AppSettingsModel.shared)
        .frame(width: 600, height: 400)
}
#endif
