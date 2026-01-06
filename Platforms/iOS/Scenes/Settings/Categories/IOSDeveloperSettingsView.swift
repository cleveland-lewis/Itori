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
                        Text(NSLocalizedString("settings.developer.mode", value: "Developer Mode", comment: "Developer mode toggle"))
                        Text(NSLocalizedString("settings.developer.mode.detail", value: "Enable debugging features", comment: "Developer mode detail"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(NSLocalizedString("settings.developer.debug.header", value: "Debug Options", comment: "Debug options header"))
            }
            
            Section {
                HStack {
                    Text(NSLocalizedString("settings.developer.app_version", value: "App Version", comment: "App version label"))
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? NSLocalizedString("settings.developer.unknown", value: "Unknown", comment: "Unknown value"))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(NSLocalizedString("settings.developer.build_number", value: "Build Number", comment: "Build number label"))
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? NSLocalizedString("settings.developer.unknown", value: "Unknown", comment: "Unknown value"))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("settings.developer.info.header", value: "App Info", comment: "App info header"))
            }
            
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Text(NSLocalizedString("settings.developer.reset", value: "Reset All Settings", comment: "Reset settings button"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } footer: {
                Text(NSLocalizedString("settings.developer.reset.footer", value: "This will reset all settings to their default values", comment: "Reset settings footer"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.developer", comment: "Developer"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(NSLocalizedString("settings.developer.reset.confirm.title", value: "Reset All Settings?", comment: "Reset settings confirmation title"), isPresented: $showResetAlert) {
            Button(NSLocalizedString("common.cancel", comment: "Cancel"), role: .cancel) { }
            Button(NSLocalizedString("settings.developer.reset.confirm.action", value: "Reset", comment: "Reset settings confirmation action"), role: .destructive) {
                // Reset functionality placeholder
            }
        } message: {
            Text(NSLocalizedString("settings.developer.reset.confirm.message", value: "This will reset all settings to their default values. This action cannot be undone.", comment: "Reset settings confirmation message"))
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

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSDeveloperSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
