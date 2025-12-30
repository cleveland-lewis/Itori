import SwiftUI
import Combine
#if os(iOS)

struct IOSIntegrationsSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Text("Calendar and Reminders integration options")
                    .foregroundColor(.secondary)
            } header: {
                Text("Apple Services")
            }
            
            Section {
                NavigationLink("Connected Services") {
                    Text("No external services connected")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("External Services")
            } footer: {
                Text("Connect with third-party services for additional features")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Integrations")
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
