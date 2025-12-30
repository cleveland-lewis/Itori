import SwiftUI
import Combine
#if os(iOS)

struct IOSPlannerSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Text("Planner configuration settings")
                    .foregroundColor(.secondary)
            } header: {
                Text("Planning")
            } footer: {
                Text("Configure how assignments are automatically scheduled")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Planner")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSPlannerSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
