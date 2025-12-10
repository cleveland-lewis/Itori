import SwiftUI

struct CoursesSettingsView: View {
    @EnvironmentObject var coursesStore: CoursesStore
    @State private var editingCourse: Course?
    @State private var showingAddCourse = false

    var body: some View {
        Form {
            Section {
                if coursesStore.activeCourses.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 48))
                                .foregroundStyle(.tertiary)
                            Text("No active courses")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Button("Add Your First Course") {
                                showingAddCourse = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 40)
                        Spacer()
                    }
                } else {
                    ForEach(coursesStore.activeCourses) { course in
                        CourseSettingsRow(
                            course: course,
                            onEdit: { editingCourse = course },
                            onArchive: { coursesStore.toggleArchiveCourse(course) }
                        )
                    }
                }
            } header: {
                HStack {
                    Text("Active Courses")
                    Spacer()
                    Button {
                        showingAddCourse = true
                    } label: {
                        Label("Add Course", systemImage: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            } footer: {
                Text("Manage your current courses. Archived courses are hidden from the main interface but remain accessible.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !coursesStore.archivedCourses.isEmpty {
                Section("Archived Courses") {
                    ForEach(coursesStore.archivedCourses) { course in
                        CourseSettingsRow(
                            course: course,
                            onEdit: { editingCourse = course },
                            onArchive: { coursesStore.toggleArchiveCourse(course) }
                        )
                    }
                }
            }
        }
        .formStyle(.grouped)
        .sheet(item: $editingCourse) { course in
            CourseEditView(course: course, coursesStore: coursesStore)
        }
        .sheet(isPresented: $showingAddCourse) {
            if let currentSemester = coursesStore.currentSemester {
                CourseEditView(course: nil, semester: currentSemester, coursesStore: coursesStore)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("No Active Semester")
                        .font(.headline)
                    Text("Please create a semester first in the Semesters section.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Go to Semesters") {
                        showingAddCourse = false
                        // Navigate to semesters section
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
            }
        }
    }
}

// MARK: - Course Settings Row

struct CourseSettingsRow: View {
    let course: Course
    let onEdit: () -> Void
    let onArchive: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Color Indicator
            if let colorHex = course.colorHex, let color = Color(hex: colorHex) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color)
                    .frame(width: 6, height: 40)
            } else {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 40)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(course.code)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    if course.isArchived {
                        Text("ARCHIVED")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary, in: Capsule())
                    }

                    if course.courseType != .regular {
                        Text(course.courseType.rawValue)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2), in: Capsule())
                    }
                }

                Text(course.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let instructor = course.instructor {
                    Text(instructor)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .help("Edit Course")

                Button {
                    onArchive()
                } label: {
                    Image(systemName: course.isArchived ? "tray.and.arrow.up" : "archivebox")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .help(course.isArchived ? "Unarchive" : "Archive")
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CoursesSettingsView()
        .environmentObject(CoursesStore())
        .frame(width: 500, height: 600)
}
