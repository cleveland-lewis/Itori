import SwiftUI

#if os(iOS)

    struct IOSProfilesSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel

        var body: some View {
            List {
                Section {
                    HStack {
                        Text(NSLocalizedString(
                            "settings.profiles.current.name",
                            value: "Name",
                            comment: "Profile name label"
                        ))
                        Spacer()
                        Text(NSLocalizedString(
                            "settings.profiles.current.name.value",
                            value: "Student",
                            comment: "Profile name value"
                        ))
                        .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(NSLocalizedString(
                            "settings.profiles.current.type",
                            value: "Profile Type",
                            comment: "Profile type label"
                        ))
                        Spacer()
                        Text(NSLocalizedString(
                            "settings.profiles.current.type.value",
                            value: "Academic",
                            comment: "Profile type value"
                        ))
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.profiles.current.header",
                        value: "Current Profile",
                        comment: "Current profile header"
                    ))
                }

                Section {
                    NavigationLink(NSLocalizedString(
                        "settings.profiles.manage",
                        value: "Manage Profiles",
                        comment: "Manage profiles"
                    )) {
                        Text(NSLocalizedString(
                            "settings.profiles.manage.placeholder",
                            value: "Profile management coming soon",
                            comment: "Manage profiles placeholder"
                        ))
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.profiles.manage.header",
                        value: "Profile Management",
                        comment: "Profile management header"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.profiles.manage.footer",
                        value: "Switch between different profiles for work, school, or personal use",
                        comment: "Profile management footer"
                    ))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("settings.category.profiles", comment: "Profiles"))
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
