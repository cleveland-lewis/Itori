import SwiftUI
#if os(iOS)

struct IOSCoursesSettingsView: View {
    @EnvironmentObject var coursesStore: CoursesStore
    
    var body: some View {
        List {
            Section {
                NavigationLink("Manage Courses") {
                    Text("Course management coming soon")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink("Archive Settings") {
                    Text("Archive settings coming soon")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Course Management")
            } footer: {
                Text("Manage your active and archived courses")
            }
            
            Section {
                HStack {
                    Text("Active Courses")
                    Spacer()
                    Text("\(coursesStore.activeCourses.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Archived Courses")
                    Spacer()
                    Text("\(coursesStore.archivedCourses.count)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Statistics")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Courses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        IOSCoursesSettingsView()
            .environmentObject(CoursesStore.shared ?? CoursesStore())
    }
}
#endif
