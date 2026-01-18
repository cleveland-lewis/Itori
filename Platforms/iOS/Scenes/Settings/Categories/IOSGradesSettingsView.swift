import SwiftUI

#if os(iOS)

    struct IOSGradesSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel

        var body: some View {
            List {
                // Empty for now - Grade Display Format removed
            }
            .listStyle(.insetGrouped)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(NSLocalizedString("settings.category.grades", value: "Grades", comment: "Grades"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            NavigationStack {
                IOSGradesSettingsView()
                    .environmentObject(AppSettingsModel.shared)
            }
        }
    #endif
#endif
