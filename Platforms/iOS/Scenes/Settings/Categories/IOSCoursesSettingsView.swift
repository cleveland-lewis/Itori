import SwiftUI

#if os(iOS)

    struct IOSCoursesSettingsView: View {
        @EnvironmentObject var coursesStore: CoursesStore

        var body: some View {
            List {
                Section {
                    NavigationLink(NSLocalizedString(
                        "settings.courses.manage",
                        value: "Manage Courses",
                        comment: "Manage courses"
                    )) {
                        Text(NSLocalizedString(
                            "settings.courses.manage.placeholder",
                            value: "Course management coming soon",
                            comment: "Manage courses placeholder"
                        ))
                        .foregroundColor(.secondary)
                    }

                    NavigationLink(NSLocalizedString(
                        "settings.courses.archive",
                        value: "Archive Settings",
                        comment: "Archive settings"
                    )) {
                        Text(NSLocalizedString(
                            "settings.courses.archive.placeholder",
                            value: "Archive settings coming soon",
                            comment: "Archive settings placeholder"
                        ))
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.courses.management.header",
                        value: "Course Management",
                        comment: "Course management header"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.courses.management.footer",
                        value: "Manage your active and archived courses",
                        comment: "Course management footer"
                    ))
                }

                Section {
                    HStack {
                        Text(NSLocalizedString(
                            "settings.courses.stats.active",
                            value: "Active Courses",
                            comment: "Active courses label"
                        ))
                        Spacer()
                        Text(verbatim: "\(coursesStore.activeCourses.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(NSLocalizedString(
                            "settings.courses.stats.archived",
                            value: "Archived Courses",
                            comment: "Archived courses label"
                        ))
                        Spacer()
                        Text(verbatim: "\(coursesStore.archivedCourses.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.courses.stats.header",
                        value: "Statistics",
                        comment: "Courses statistics header"
                    ))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("settings.category.courses", comment: "Courses"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            NavigationStack {
                IOSCoursesSettingsView()
                    .environmentObject(CoursesStore.shared ?? CoursesStore())
            }
        }
    #endif
#endif
