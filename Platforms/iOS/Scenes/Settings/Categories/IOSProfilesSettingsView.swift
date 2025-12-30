import SwiftUI
#if os(iOS)

struct IOSProfilesSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Name")
                    Spacer()
                    Text("Student")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Profile Type")
                    Spacer()
                    Text("Academic")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Current Profile")
            }
            
            Section {
                NavigationLink("Manage Profiles") {
                    Text("Profile management coming soon")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Profile Management")
            } footer: {
                Text("Switch between different profiles for work, school, or personal use")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profiles")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    NavigationStack {
        IOSProfilesSettingsView()
            .environmentObject(AppSettingsModel.shared)
    }
}
#endif
#endif
