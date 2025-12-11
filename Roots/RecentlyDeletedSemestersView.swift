import SwiftUI

struct RecentlyDeletedSemestersView: View {
    @EnvironmentObject var coursesStore: CoursesStore

    var body: some View {
        List {
            if coursesStore.recentlyDeletedSemesters.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray.full")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                        Text("No recently deleted semesters.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                ForEach(coursesStore.recentlyDeletedSemesters) { semester in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(semester.name)
                            .font(.headline)
                        Text("\(semester.startDate.formatted(date: .abbreviated, time: .omitted)) – \(semester.endDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button("Recover") {
                                coursesStore.recoverSemester(semester.id)
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Delete Immediately", role: .destructive) {
                                coursesStore.permanentlyDeleteSemester(semester.id)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Recently Deleted")
    }
}

#Preview {
    RecentlyDeletedSemestersView()
        .environmentObject(CoursesStore())
}
