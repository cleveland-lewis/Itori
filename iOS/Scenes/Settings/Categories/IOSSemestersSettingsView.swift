import SwiftUI
#if os(iOS)

struct IOSSemestersSettingsView: View {
    @EnvironmentObject var coursesStore: CoursesStore
    
    var body: some View {
        List {
            Section {
                NavigationLink("Manage Semesters") {
                    Text("Semester management coming soon")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Semester Management")
            } footer: {
                Text("Create and manage academic semesters")
            }
            
            Section {
                HStack {
                    Text("Current Semester")
                    Spacer()
                    Text(coursesStore.currentSemester?.name ?? "None")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Active Semester")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Semesters")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        IOSSemestersSettingsView()
            .environmentObject(CoursesStore.shared ?? CoursesStore())
    }
}
#endif
