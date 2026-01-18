#if os(macOS)
    import SwiftUI

    struct CoursesView: View {
        @EnvironmentObject private var coursesStore: CoursesStore

        @State private var showingAddSemester = false
        @State private var showingAddCourse = false

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title removed
                    Color.clear.frame(height: 12)

                    // Current semester selector
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(NSLocalizedString(
                                    "courses.active.semesters",
                                    value: "Active Semesters",
                                    comment: "Active Semesters"
                                ))
                                .font(DesignSystem.Typography.subHeader)

                                Spacer()

                                Button {
                                    showingAddSemester = true
                                } label: {
                                    Label(
                                        NSLocalizedString(
                                            "courses.label.add.semester",
                                            value: "Add Semester",
                                            comment: "Add Semester"
                                        ),
                                        systemImage: "plus"
                                    )
                                    .labelStyle(.iconOnly)
                                }
                                .buttonStyle(.plain)
                            }

                            if coursesStore.semesters.isEmpty {
                                Text(NSLocalizedString(
                                    "courses.no.semesters.yet.add.one",
                                    value: "No semesters yet. Add one to begin organizing your courses.",
                                    comment: "No semesters yet. Add one to begin organizing your..."
                                ))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            } else {
                                // NEW: Use multi-select semester picker
                                SemesterPickerView()

                                if coursesStore.currentSemesterId == nil {
                                    Text(NSLocalizedString(
                                        "courses.select.one.or.more.semesters.to.view.courses",
                                        value: "Select one or more semesters to view courses",
                                        comment: "Select one or more semesters to view courses"
                                    ))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Courses for active semesters
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(NSLocalizedString("courses.courses", value: "Courses", comment: "Courses"))
                                    .font(DesignSystem.Typography.subHeader)

                                Spacer()

                                Button {
                                    showingAddCourse = true
                                } label: {
                                    Label(
                                        NSLocalizedString(
                                            "courses.label.add.course",
                                            value: "Add Course",
                                            comment: "Add Course"
                                        ),
                                        systemImage: "plus"
                                    )
                                }
                                .buttonStyle(.itariLiquid)
                                .controlSize(.small)
                            }

                            if coursesStore.activeSemesters.isEmpty {
                                Text(NSLocalizedString(
                                    "courses.no.active.semesters.selected",
                                    value: "No active semesters selected",
                                    comment: "No active semesters selected"
                                ))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            } else if coursesStore.activeCourses.isEmpty {
                                Text(NSLocalizedString(
                                    "courses.no.courses.yet.add.a.course.to.get.started",
                                    value: "No courses yet. Add a course to get started.",
                                    comment: "No courses yet. Add a course to get started."
                                ))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            } else {
                                CardGrid {
                                    ForEach(coursesStore.activeCourses) { course in
                                        // Find the semester for this course
                                        if let semester = coursesStore.semesters
                                            .first(where: { $0.id == course.semesterId })
                                        {
                                            CourseCard(course: course, semester: semester)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
            .sheet(isPresented: $showingAddSemester) {
                AddSemesterSheet()
                    .environmentObject(coursesStore)
            }
            .sheet(isPresented: $showingAddCourse) {
                AddCourseSheet()
                    .environmentObject(coursesStore)
            }
        }
    }

    // Define the course card (uniform style)
    struct CourseCard: View {
        let course: Course
        let semester: Semester

        var body: some View {
            NavigationLink(destination: CourseDetailView(course: course, semester: semester)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.code)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)

                    Text(course.title)
                        .font(DesignSystem.Typography.subHeader)

                    Text(semester.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    SceneActivationHelper.openCourseWindow(for: course)
                } label: {
                    Label(
                        NSLocalizedString(
                            "courses.label.open.in.new.window",
                            value: "Open in New Window",
                            comment: "Open in New Window"
                        ),
                        systemImage: "doc.on.doc"
                    )
                }
            }
        }
    }
#endif
