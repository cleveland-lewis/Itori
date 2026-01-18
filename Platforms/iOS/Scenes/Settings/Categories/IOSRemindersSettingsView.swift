import Combine
import SwiftUI

#if os(iOS)

    struct IOSRemindersSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel

        var body: some View {
            List {
                Section {
                    Text(NSLocalizedString(
                        "settings.reminders.integration.body",
                        value: "Reminders integration settings",
                        comment: "Reminders integration body"
                    ))
                    .foregroundColor(.secondary)
                } header: {
                    Text(NSLocalizedString(
                        "settings.reminders.integration.header",
                        value: "Integration",
                        comment: "Reminders integration header"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.reminders.integration.footer",
                        value: "Sync tasks with Apple Reminders",
                        comment: "Reminders integration footer"
                    ))
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(NSLocalizedString("settings.category.reminders", comment: "Reminders"))
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
