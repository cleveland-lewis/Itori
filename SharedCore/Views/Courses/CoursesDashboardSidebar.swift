import SwiftUI

struct CoursesDashboardSidebar: View {
    let courses: [CourseDashboard]
    @Binding var selectedCourse: CourseDashboard?
    @State private var searchText = ""
    @State private var selectedSemesterID: UUID?
    let semesters: [Semester]
    let onNewCourse: () -> Void
    let onEditCourses: () -> Void

    private var filteredCourses: [CourseDashboard] {
        let semesterFiltered: [CourseDashboard] = {
            guard let selectedSemesterID else { return courses }
            return courses.filter { $0.semesterId == selectedSemesterID }
        }()

        guard !searchText.isEmpty else { return semesterFiltered }

        return semesterFiltered.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.instructor.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            // Search + Semester Filter
            filterBar
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider()

            // Course List
            List(selection: $selectedCourse) {
                ForEach(filteredCourses) { course in
                    CourseListRow(course: course)
                        .tag(course)
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)

            Divider()

            // Footer Actions
            sidebarFooter
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .frame(width: 300)
        #if os(macOS)
        .background(DesignSystem.Colors.sidebarBackground)
        #else
        .background(DesignSystem.Materials.sidebar)
        #endif
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(NSLocalizedString("Courses", value: "Courses", comment: ""))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(.primary)

            Text(NSLocalizedString("Fall 2025", value: "Fall 2025", comment: ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterBar: some View {
        HStack(spacing: DesignSystem.Layout.spacing.small) {
            HStack(spacing: DesignSystem.Layout.spacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(DesignSystem.Typography.body)

                TextField("Search courses...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(DesignSystem.Typography.body)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Picker("", selection: $selectedSemesterID) {
                Text(NSLocalizedString("All", value: "All", comment: "")).tag(Optional<UUID>(nil))
                ForEach(semesters) { semester in
                    Text(semester.name).tag(Optional(semester.id))
                }
            }
            .frame(width: 140)
            .labelsHidden()
        }
    }

    private var sidebarFooter: some View {
        HStack(spacing: DesignSystem.Layout.spacing.small) {
            Button {
                onNewCourse()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(DesignSystem.Typography.body)
                    Text(NSLocalizedString("New Course", value: "New Course", comment: ""))
                        .font(DesignSystem.Typography.body)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderless)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Button {
                onEditCourses()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(DesignSystem.Typography.body)
                    Text(NSLocalizedString("Edit", value: "Edit", comment: ""))
                        .font(DesignSystem.Typography.body)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderless)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}

// MARK: - Course List Row

struct CourseListRow: View {
    let course: CourseDashboard
    var body: some View {
        HStack(spacing: 12) {
            // Color Indicator
            Circle()
                .fill(course.color.opacity(0.9))
                .frame(width: 10, height: 10)

            // Course Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(course.code)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(.primary)

                    Text(course.gradePercentage)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(gradeColor)
                }

                Text(course.title)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(course.instructor)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Grade Badge
            Text(course.letterGrade)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(.white)
                .frame(width: 32, height: 24)
                .background(gradeColor.opacity(0.9), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .padding(.vertical, 8)
        .frame(minHeight: 60, alignment: .center)
    }

    private var gradeColor: Color {
        Color.accentColor
    }
}
