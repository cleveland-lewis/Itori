import SwiftUI
import Combine
#if os(iOS)

struct IOSRemindersSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                Text("Reminders integration settings")
                    .foregroundColor(.secondary)
            } header: {
                Text("Integration")
            } footer: {
                Text("Sync tasks with Apple Reminders")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSRemindersSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
