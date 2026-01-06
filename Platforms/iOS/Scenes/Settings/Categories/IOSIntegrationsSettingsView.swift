import SwiftUI
import Combine
#if os(iOS)

struct IOSIntegrationsSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Text(NSLocalizedString("settings.integrations.apple.body", value: "Calendar and Reminders integration options", comment: "Apple services integrations body"))
                    .foregroundColor(.secondary)
            } header: {
                Text(NSLocalizedString("settings.integrations.apple.header", value: "Apple Services", comment: "Apple services header"))
            }
            
            Section {
                NavigationLink(NSLocalizedString("settings.integrations.external.connected", value: "Connected Services", comment: "Connected services")) {
                    Text(NSLocalizedString("settings.integrations.external.empty", value: "No external services connected", comment: "No external services connected"))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("settings.integrations.external.header", value: "External Services", comment: "External services header"))
            } footer: {
                Text(NSLocalizedString("settings.integrations.external.footer", value: "Connect with third-party services for additional features", comment: "External services footer"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings.category.integrations", comment: "Integrations"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSIntegrationsSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
