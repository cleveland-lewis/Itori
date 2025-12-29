import SwiftUI
import Combine
#if os(iOS)

struct IOSDeveloperSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @State private var showResetAlert = false
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: binding(for: \.devModeEnabledStorage)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Developer Mode")
                        Text("Enable debugging features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Debug Options")
            }
            
            Section {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build Number")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("App Info")
            }
            
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Text("Reset All Settings")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } footer: {
                Text("This will reset all settings to their default values")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Developer")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset All Settings?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // Reset functionality placeholder
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
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
        IOSDeveloperSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
