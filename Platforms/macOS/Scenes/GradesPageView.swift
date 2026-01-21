#if os(macOS)
    import Combine
    import SwiftUI

    // MARK: - Models

    struct GradeCourseSummary: Identifiable, Hashable {
        let id: UUID
        var courseCode: String
        var courseTitle: String
        var currentPercentage: Double?
        var targetPercentage: Double?
        var letterGrade: String?
        var creditHours: Int
        var colorTag: Color
    }

    struct GradeComponent: Identifiable, Hashable {
        let id: UUID
        var name: String
        var weightPercent: Double
        var earnedPercent: Double?
    }

    struct CourseGradeDetail: Identifiable, Hashable {
        let id: UUID
        var course: GradeCourseSummary
        var components: [GradeComponent]
        var notes: String
    }

    // MARK: - Root View

    struct GradesPageView: View {
        @EnvironmentObject private var settings: AppSettings
        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var coursesStore: CoursesStore
        @EnvironmentObject private var gradesStore: GradesStore
        @Environment(\.appLayout) private var appLayout

        @State private var allCourses: [GradeCourseSummary] = []
        @State private var courseDetails: [CourseGradeDetail] = []
        @State private var selectedCourseDetail: CourseGradeDetail? = nil
        @State private var searchText: String = ""
        @AppStorage("grades.gpaScale") private var gpaScale: Double = 4.0
        @State private var showEditTargetSheet: Bool = false
        @State private var courseToEditTarget: GradeCourseSummary? = nil
        @State private var whatIfSlider: Double = 90
        @State private var showAddGradeSheet: Bool = false
        @State private var gradeAnalyticsWindowOpen: Bool = false
        @State private var showNewCourseSheet: Bool = false
        @State private var editingCourse: Course? = nil
        @State private var courseDeletedCancellable: AnyCancellable? = nil
        @State private var showExportSheet: Bool = false

        private let cardCorner: CGFloat = 24

        var body: some View {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        header

                        adaptiveColumns(width: proxy.size.width)
                    }
                    .padding(.horizontal, ItariSpacing.pagePadding)
                    .padding(.top, appLayout.topContentInset)
                    .padding(.bottom, ItariSpacing.l)
                }
                .itoriSystemBackground()
            }
            .sheet(isPresented: Binding(
                get: {
                    showEditTargetSheet &&
                        courseToEditTarget != nil &&
                        courseDetails.contains(where: { $0.id == courseToEditTarget?.id })
                },
                set: { newValue in
                    showEditTargetSheet = newValue
                    if !newValue {
                        courseToEditTarget = nil
                    }
                }
            )) {
                if let course = courseToEditTarget, let detail = courseDetails.first(where: { $0.id == course.id }) {
                    EditTargetGradeSheet(course: course, detail: detail) { updatedTarget, letter, components in
                        updateTarget(for: course, to: updatedTarget, letter: letter, components: components)
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                GradesExportSheet(courses: allCourses, courseDetails: courseDetails)
            }
            .sheet(isPresented: $showNewCourseSheet) {
                let editorModel = editingCourse.flatMap(courseEditorModel(from:))
                CourseEditorSheet(course: editorModel) { updated in
                    persistCourseEditorModel(updated)
                    editingCourse = nil
                    refreshCourses()
                }
            }
            .sheet(isPresented: $showAddGradeSheet) {
                AddGradeSheet(
                    assignments: assignmentsStore.tasks,
                    courses: allCourses,
                    onSave: { updatedTask in
                        assignmentsStore.updateTask(updatedTask)
                        persistGrade(for: updatedTask)
                    }
                )
            }
            .sheet(isPresented: $gradeAnalyticsWindowOpen) {
                GradesAnalyticsView()
                    .environmentObject(settings)
                    .environmentObject(assignmentsStore)
                    .environmentObject(coursesStore)
            }
            .onAppear {
                refreshCourses()
                requestGPARecalc()

                // Subscribe to course deletions
                courseDeletedCancellable = CoursesStore.courseDeletedPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { deletedId in
                        gradesStore.remove(courseId: deletedId)
                        refreshCourses()
                        if let selected = selectedCourseDetail, selected.id == deletedId {
                            selectedCourseDetail = nil
                        }
                    }
            }
            .onReceive(assignmentsStore.$tasks) { _ in
                requestGPARecalc()
            }
            .onReceive(coursesStore.$courses) { _ in
                refreshCourses()
            }
            .onReceive(gradesStore.$grades) { _ in
                refreshCourses()
            }
            .onReceive(NotificationCenter.default.publisher(for: .addGradeRequested)) { _ in
                showAddGradeSheet = true
            }
        }

        // MARK: Header

        private var header: some View {
            HStack(alignment: .center, spacing: 12) {
                Spacer()

                TextField("Search courses", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)

                Button {
                    showExportSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                        .frame(width: 32, height: 32)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Share or export grades")
            }
        }

        // MARK: Columns

        @ViewBuilder
        private func adaptiveColumns(width: CGFloat) -> some View {
            let isCompact = width < 1100

            if isCompact {
                VStack(spacing: 16) {
                    overallColumn
                    courseListCard
                    detailCard
                }
            } else {
                let spacing: CGFloat = 22
                let overallWidth = max(280, width * 0.22)
                let courseWidth = max(340, width * 0.34)

                HStack(alignment: .top, spacing: spacing) {
                    overallColumn
                        .frame(width: overallWidth)
                    courseListCard
                        .frame(width: courseWidth)
                    detailCard
                        .frame(maxWidth: .infinity)
                }
            }
        }

        private var overallColumn: some View {
            VStack(spacing: 12) {
                GPABreakdownCard(
                    currentGPA: coursesStore.currentGPA,
                    academicYearGPA: coursesStore.currentGPA,
                    cumulativeGPA: coursesStore.currentGPA,
                    isLoading: gradesStore.isLoading,
                    courseCount: coursesStore.activeCourses.count
                )
                HStack(spacing: 12) {
                    Button {
                        showAddGradeSheet = true
                    } label: {
                        Label(
                            NSLocalizedString("grades.label.add.grade", value: "Add Grade", comment: "Add Grade"),
                            systemImage: "plus.circle"
                        )
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .tint(.accentColor)

                    Button {
                        gradeAnalyticsWindowOpen = true
                        // Placeholder: open analytics window
                        DebugLogger.log("Analytics tapped")
                    } label: {
                        Label(
                            NSLocalizedString("grades.label.analytics", value: "Analytics", comment: "Analytics"),
                            systemImage: "chart.bar.xaxis"
                        )
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.itariLiquid)
                    .tint(.accentColor)
                }
            }
        }

        private var courseListCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(NSLocalizedString("grades.section.courses", comment: "Courses"))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Picker("Sort", selection: .constant(0)) {
                        Text(NSLocalizedString("grades.column.course", comment: "Course")).tag(0)
                        Text(NSLocalizedString("grades.column.grade", comment: "Grade")).tag(1)
                        Text(NSLocalizedString("grades.column.credits", comment: "Credits")).tag(2)
                    }
                    .pickerStyle(.menu)
                }

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredCourses) { course in
                            CourseGradeRow(
                                course: course,
                                isSelected: course.id == selectedCourseDetail?.course.id,
                                isScenarioHighlight: false,
                                onSelect: {
                                    withAnimation(DesignSystem.Motion.standardSpring) {
                                        selectedCourseDetail = courseDetails.first(where: { $0.course.id == course.id })
                                    }
                                },
                                onEditTarget: {
                                    courseToEditTarget = course
                                    showEditTargetSheet = true
                                },
                                onEditCourse: {
                                    // find full Course model and present editor
                                    if let full = coursesStore.courses.first(where: { $0.id == course.id }) {
                                        editingCourse = full
                                        showNewCourseSheet = true
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(cardBackground)
            .overlay(cardStroke)
        }

        private var detailCard: some View {
            VStack(spacing: 16) {
                GradeDetailCard(
                    detail: Binding(
                        get: { selectedCourseDetail },
                        set: { selectedCourseDetail = $0 }
                    ),
                    whatIfInput: $whatIfSlider,
                    gpaScale: gpaScale,
                    onEditTarget: { course in
                        courseToEditTarget = course
                        showEditTargetSheet = true
                    },
                    onUpdateNotes: { updated in
                        if let idx = courseDetails.firstIndex(where: { $0.id == updated.id }) {
                            courseDetails[idx] = updated
                            if selectedCourseDetail?.id == updated.id {
                                selectedCourseDetail = updated
                            }
                        }
                    }
                )
            }
            .padding(16)
            .background(cardBackground)
            .overlay(cardStroke)
        }

        // MARK: Helpers

        private var filteredCourses: [GradeCourseSummary] {
            let hydrated = allCourses.map { course -> GradeCourseSummary in
                var updated = course
                if let pct = GradeCalculator.calculateCourseGrade(courseID: course.id, tasks: assignmentsStore.tasks) {
                    updated.currentPercentage = pct
                }
                return updated
            }

            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return hydrated }
            let q = searchText.lowercased()
            return hydrated.filter { course in
                course.courseCode.lowercased().contains(q) || course.courseTitle.lowercased().contains(q)
            }
        }

        private func isNearThreshold(_ course: GradeCourseSummary) -> Bool {
            guard let percent = course.currentPercentage else { return false }
            let fractional = percent.truncatingRemainder(dividingBy: 10)
            return fractional >= 7
        }

        private func updateTarget(
            for course: GradeCourseSummary,
            to target: Double?,
            letter: String?,
            components: [GradeComponent]
        ) {
            // Update course summary
            if let idx = allCourses.firstIndex(where: { $0.id == course.id }) {
                allCourses[idx].targetPercentage = target
                allCourses[idx].letterGrade = letter ?? allCourses[idx].letterGrade
            }
            // Update detail and components
            if let detailIdx = courseDetails.firstIndex(where: { $0.course.id == course.id }) {
                courseDetails[detailIdx].course.targetPercentage = target
                courseDetails[detailIdx].course.letterGrade = letter ?? courseDetails[detailIdx].course.letterGrade
                courseDetails[detailIdx].components = components
                selectedCourseDetail = courseDetails[detailIdx]
            }
        }

        private func refreshCourses() {
            let summaries = coursesStore.activeCourses.map { course in
                let grade = gradesStore.grade(for: course.id)
                return GradeCourseSummary(
                    id: course.id,
                    courseCode: course.code,
                    courseTitle: course.title,
                    currentPercentage: grade?.percent,
                    targetPercentage: nil,
                    letterGrade: grade?.letter,
                    creditHours: Int(course.credits ?? 0),
                    colorTag: colorTag(for: course.colorHex)
                )
            }
            allCourses = summaries
            courseDetails = summaries.map { summary in
                CourseGradeDetail(
                    id: summary.id,
                    course: summary,
                    components: [],
                    notes: "Add grade components to see breakdown."
                )
            }
            if selectedCourseDetail == nil {
                selectedCourseDetail = courseDetails.first
            } else if let current = selectedCourseDetail, !courseDetails.contains(where: { $0.id == current.id }) {
                selectedCourseDetail = courseDetails.first
            }
        }

        private func requestGPARecalc() {
            Task { @MainActor in
                coursesStore.recalcGPA(tasks: assignmentsStore.tasks)
            }
        }

        private func persistGrade(for task: AppTask) {
            guard let courseId = task.courseId,
                  let earned = task.gradeEarnedPoints,
                  let possible = task.gradePossiblePoints,
                  possible > 0 else { return }

            let percent = (earned / possible) * 100
            let letter = GradeCalculator.letterGrade(for: percent)
            gradesStore.upsert(courseId: courseId, percent: percent, letter: letter)
            requestGPARecalc()
        }

        private func colorTag(for hex: String?) -> Color {
            if let colorTag = ColorTag.fromHex(hex) {
                return colorTag.color
            }
            // Try to parse as hex color directly
            if let hex, let hexColor = Color(hex: hex) {
                return hexColor
            }
            // Fallback to blue only if no hex provided
            return Color.blue
        }

        private func courseEditorModel(from course: Course) -> CoursesPageModel.Course {
            let semesterName = coursesStore.semesters.first(where: { $0.id == course.semesterId })?.name ?? "Current Term"
            let colorTag = ColorTag.fromHex(course.colorHex) ?? .blue
            let gradeEntry = gradesStore.grade(for: course.id)
            let gradeInfo = CoursesPageModel.CourseGradeInfo(
                currentPercentage: gradeEntry?.percent,
                targetPercentage: nil,
                letterGrade: gradeEntry?.letter
            )

            return CoursesPageModel.Course(
                id: course.id,
                code: course.code,
                title: course.title,
                instructor: course.instructor ?? "Instructor",
                location: course.location ?? "Location TBA",
                credits: Int(course.credits ?? 3),
                colorTag: colorTag,
                semesterId: course.semesterId,
                semesterName: semesterName,
                isArchived: course.isArchived,
                meetingTimes: [],
                gradeInfo: gradeInfo,
                syllabus: nil
            )
        }

        private func persistCourseEditorModel(_ course: CoursesPageModel.Course) {
            let semesterId = course.semesterId ?? ensureSemester()
            if let idx = coursesStore.courses.firstIndex(where: { $0.id == course.id }) {
                var existing = coursesStore.courses[idx]
                existing.code = course.code
                existing.title = course.title
                existing.instructor = course.instructor
                existing.location = course.location
                existing.credits = Double(course.credits)
                existing.semesterId = semesterId
                existing.isArchived = course.isArchived
                existing.colorHex = ColorTag.hex(for: course.colorTag)
                coursesStore.updateCourse(existing)
            } else {
                let newCourse = Course(
                    id: course.id,
                    title: course.title,
                    code: course.code,
                    semesterId: semesterId,
                    colorHex: ColorTag.hex(for: course.colorTag),
                    isArchived: course.isArchived,
                    courseType: .regular,
                    instructor: course.instructor,
                    location: course.location,
                    credits: Double(course.credits),
                    creditType: .credits,
                    meetingTimes: nil,
                    syllabus: nil,
                    notes: nil,
                    attachments: []
                )
                coursesStore.addCourse(newCourse)
            }

            if coursesStore.currentSemesterId == nil {
                coursesStore.currentSemesterId = semesterId
            }
        }

        private func ensureSemester() -> UUID {
            if let current = coursesStore.currentSemesterId { return current }
            if let first = coursesStore.semesters.first {
                coursesStore.currentSemesterId = first.id
                return first.id
            }

            let calendar = Calendar.current
            let now = Date()
            let end = calendar.date(byAdding: .month, value: 4, to: now) ?? now
            let defaultSemester = Semester(
                startDate: now,
                endDate: end,
                isCurrent: true,
                educationLevel: .college,
                semesterTerm: .fall,
                academicYear: "\(calendar.component(.year, from: now))-\(calendar.component(.year, from: end))"
            )
            coursesStore.addSemester(defaultSemester)
            coursesStore.currentSemesterId = defaultSemester.id
            return defaultSemester.id
        }

        private var cardBackground: some View {
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous).fill(.thinMaterial)
        }

        private var cardStroke: some View {
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .stroke(.separatorColor, lineWidth: 1)
        }
    }

    // MARK: - Overall Status

    struct OverallStatusCard: View {
        var courses: [GradeCourseSummary]
        var gpaScale: Double
        var emphasize: Bool

        var body: some View {
            let overallPercent = weightedOverallPercent
            let gpa = gpaValue(overallPercent: overallPercent)
            VStack(alignment: .leading, spacing: 10) {
                Text(NSLocalizedString("grades.section.overall_status", comment: "Overall status"))
                    .font(.subheadline.weight(.semibold))

                Text(String(
                    format: NSLocalizedString("grades.overview.gpa", value: "GPA %.2f / %.1f", comment: "GPA summary"),
                    gpa,
                    gpaScale
                ))
                .font(emphasize ? .title : .title2)

                Text(String(
                    format: NSLocalizedString(
                        "grades.overview.weighted",
                        value: "Weighted %.1f%% • %d courses",
                        comment: "Weighted overall summary"
                    ),
                    overallPercent,
                    courses.count
                ))
                .font(.footnote)
                .foregroundColor(.secondary)

                ProgressView(value: overallPercent / 100)
                    .progressViewStyle(.linear)

                HStack {
                    if let maxCourse = courses.max(by: { ($0.currentPercentage ?? 0) < ($1.currentPercentage ?? 0) }) {
                        Text(verbatim: "Highest: \(maxCourse.courseCode) \(Int(maxCourse.currentPercentage ?? 0))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let minCourse = courses.min(by: { ($0.currentPercentage ?? 0) < ($1.currentPercentage ?? 0) }) {
                        Text(verbatim: "Lowest: \(minCourse.courseCode) \(Int(minCourse.currentPercentage ?? 0))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.separatorColor, lineWidth: 1)
            )
        }

        private var weightedOverallPercent: Double {
            let totalCredits = courses.reduce(0) { $0 + $1.creditHours }
            guard totalCredits > 0 else { return 0 }
            let weighted = courses.reduce(0.0) { partial, course in
                let pct = course.currentPercentage ?? 0
                return partial + pct * Double(course.creditHours)
            }
            return weighted / Double(totalCredits)
        }

        private func gpaValue(overallPercent: Double) -> Double {
            // Simple linear mapping: 90-100 -> 4.0, 80-89 -> 3.0, etc.
            let scaled = (overallPercent / 100) * gpaScale
            return min(gpaScale, max(0, scaled))
        }
    }

    // MARK: - Course Row

    struct CourseGradeRow: View {
        var course: GradeCourseSummary
        var isSelected: Bool
        var isScenarioHighlight: Bool
        var onSelect: () -> Void
        var onEditTarget: () -> Void
        var onEditCourse: (() -> Void)?

        private var ringColor: Color { course.colorTag }

        var body: some View {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(ringColor)
                        .frame(width: 4)
                        .cornerRadius(2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: "\(course.courseCode) · \(course.courseTitle)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            if let pct = course.currentPercentage {
                                Text(String(
                                    format: NSLocalizedString(
                                        "grades.course.percent",
                                        value: "%.1f%%",
                                        comment: "Course percent"
                                    ),
                                    pct
                                ))
                            } else {
                                Text(NSLocalizedString("grades.display.no_grade", comment: "No grade"))
                            }
                            if let letter = course.letterGrade { Text(verbatim: "· \(letter)") }
                            Text(String(
                                format: NSLocalizedString(
                                    "grades.course.credits",
                                    value: "· %d credits",
                                    comment: "Course credits"
                                ),
                                course.creditHours
                            ))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        ring
                        if let target = course.targetPercentage {
                            Text(String(
                                format: NSLocalizedString(
                                    "grades.course.target",
                                    value: "Target %d%%",
                                    comment: "Target percent"
                                ),
                                Int(target)
                            ))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.secondaryBackground))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? .accentQuaternary : .secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isScenarioHighlight ? Color.accentColor : .separatorColor, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(NSLocalizedString("grades.button.edit.target", value: "Edit Target", comment: "Edit Target")) {
                    onEditTarget()
                }
                if let onEditCourse {
                    Button(NSLocalizedString(
                        "grades.button.edit.course",
                        value: "Edit Course",
                        comment: "Edit Course"
                    )) { onEditCourse() }
                }
            }
        }

        private var ring: some View {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 6)
                    .frame(width: 44, height: 44)
                if let pct = course.currentPercentage {
                    Circle()
                        .trim(from: 0, to: CGFloat(min(max(pct / 100, 0), 1)))
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 44, height: 44)
                    Text(verbatim: "\(Int(pct))%")
                        .font(.caption2.weight(.semibold))
                } else {
                    Text(NSLocalizedString("—", value: "—", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Detail Card

    struct GradeDetailCard: View {
        @Binding var detail: CourseGradeDetail?
        @Binding var whatIfInput: Double
        var gpaScale: Double
        var onEditTarget: (GradeCourseSummary) -> Void
        var onUpdateNotes: (CourseGradeDetail) -> Void

        var body: some View {
            if let detail {
                VStack(alignment: .leading, spacing: 12) {
                    header(detail.course)
                    components(detail.components)
                    notes(detail)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("grades.empty.select_course", comment: "Select course"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }

        private func header(_ course: GradeCourseSummary) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(String(
                        format: NSLocalizedString(
                            "grades.detail.components.title",
                            value: "Grade Components – %@",
                            comment: "Grade components title"
                        ),
                        course.courseCode
                    ))
                    .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(String(
                        format: NSLocalizedString(
                            "grades.gpa_scale",
                            value: "GPA Scale: %.1f",
                            comment: "GPA scale label"
                        ),
                        gpaScale
                    ))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
                }
                Text(course.courseTitle)
                    .font(.headline)
                HStack(spacing: 8) {
                    if let current = course.currentPercentage {
                        Text(String(
                            format: NSLocalizedString(
                                "grades.current.percent",
                                value: "Current: %.1f%%",
                                comment: "Current percent"
                            ),
                            current
                        ))
                    } else { Text(NSLocalizedString("grades.current", value: "Current: —", comment: "Current: —")) }
                    if let target = course.targetPercentage {
                        Text(String(
                            format: NSLocalizedString(
                                "grades.target.percent",
                                value: "· Target: %d%%",
                                comment: "Target percent"
                            ),
                            Int(target)
                        ))
                    }
                    if let letter = course.letterGrade { Text(verbatim: "· \(letter)") }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Button(NSLocalizedString("grades.button.edit.target", value: "Edit target", comment: "Edit target")) {
                    onEditTarget(course)
                }
                .buttonStyle(.itoriLiquidProminent)
                .controlSize(.small)
            }
        }

        private func components(_ components: [GradeComponent]) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(components) { comp in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(comp.name)
                                .font(.caption.weight(.semibold))
                            Spacer()
                            if let earned = comp.earnedPercent {
                                Text(verbatim: "\(Int(earned))%")
                                    .font(.caption.weight(.semibold))
                            } else {
                                Text(NSLocalizedString(
                                    "grades.no.data.yet",
                                    value: "No data yet",
                                    comment: "No data yet"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        Text(String(
                            format: NSLocalizedString(
                                "grades.component.weight",
                                value: "Weight: %d%%",
                                comment: "Component weight"
                            ),
                            Int(comp.weightPercent)
                        ))
                        .font(.caption)
                        .foregroundColor(.secondary)

                        if let earned = comp.earnedPercent {
                            ProgressView(value: min(max(earned / 100, 0), 1))
                                .tint(progressColor(earned))
                        }
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }

        private func progressColor(_ percent: Double) -> Color {
            switch percent {
            case ..<70: .red
            case 70 ..< 85: .yellow
            default: .green
            }
        }

        private func whatIf(_ detail: CourseGradeDetail) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString(
                    "grades.whatif.scenario",
                    value: "What-If Scenario",
                    comment: "What-If Scenario"
                ))
                .font(.subheadline.weight(.semibold))
                Slider(value: $whatIfInput, in: 50 ... 100, step: 1) {
                    Text(NSLocalizedString(
                        "grades.expected.average.on.remaining.work",
                        value: "Expected average on remaining work",
                        comment: "Expected average on remaining work"
                    ))
                }
                Text(String(
                    format: NSLocalizedString(
                        "grades.whatif.summary",
                        value: "If you score %d%% on remaining work, your projected final grade is %.1f%%.",
                        comment: "What-if summary"
                    ),
                    Int(whatIfInput),
                    projectedGrade(detail)
                ))
                .font(.footnote)
                .foregroundColor(.secondary)
            }
        }

        private func projectedGrade(_ detail: CourseGradeDetail) -> Double {
            // Simplistic blend: average known earnedPercent weighted, remaining weight uses whatIfInput
            let knownWeight = detail.components.reduce(0) { $0 + ($1.earnedPercent == nil ? 0 : $1.weightPercent) }
            let knownScore = detail.components.reduce(0) { partial, comp in
                guard let earned = comp.earnedPercent else { return partial }
                return partial + earned * (comp.weightPercent / 100)
            }
            let remainingWeight = max(0, 100 - knownWeight)
            let projected = knownScore + whatIfInput * (remainingWeight / 100)
            return projected
        }

        private func notes(_ detail: CourseGradeDetail) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("grades.notes", value: "Notes", comment: "Notes"))
                    .font(.subheadline.weight(.semibold))
                TextEditor(text: Binding(
                    get: { detail.notes },
                    set: { newValue in
                        var updated = detail
                        updated.notes = newValue
                        onUpdateNotes(updated)
                        self.detail = updated
                    }
                ))
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.separatorColor, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Edit Target Sheet

    struct EditTargetGradeSheet: View {
        var course: GradeCourseSummary
        var detail: CourseGradeDetail
        var onSave: (Double?, String?, [GradeComponent]) -> Void
        @Environment(\.dismiss) private var dismiss

        @State private var targetPercent: Double
        @State private var letter: String
        @State private var components: [GradeComponent]

        private let letters = ["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D", "F"]

        init(
            course: GradeCourseSummary,
            detail: CourseGradeDetail,
            onSave: @escaping (Double?, String?, [GradeComponent]) -> Void
        ) {
            self.course = course
            self.detail = detail
            self.onSave = onSave
            _targetPercent = State(initialValue: course.targetPercentage ?? 90)
            _letter = State(initialValue: course.letterGrade ?? "A")
            _components = State(initialValue: detail.components)
        }

        var body: some View {
            VStack(spacing: 0) {
                // Custom title bar
                HStack {
                    Text("Edit Target for \(course.courseCode)")
                        .font(.headline)
                    Spacer()
                    Button(NSLocalizedString("grades.button.cancel", value: "Cancel", comment: "Cancel")) {
                        dismiss()
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Cancel grade editing")
                    Button(NSLocalizedString("grades.button.save", value: "Save", comment: "Save")) {
                        onSave(targetPercent, letter, components)
                        dismiss()
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .accessibilityLabel("Save grade target changes")
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(NSLocalizedString("grades.target", value: "Target %", comment: "Target %"))
                                    .font(.body)
                                Spacer()
                                Text(verbatim: "\(Int(targetPercent))%")
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                            }
                            Slider(value: $targetPercent, in: 0 ... 100, step: 1)
                        }
                    } header: {
                        Text("Target Grade")
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach($components) { $comp in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        TextField(
                                            "Component Name",
                                            text: Binding(get: { comp.name }, set: { comp.name = $0 })
                                        )
                                        .textFieldStyle(.roundedBorder)
                                        Spacer()
                                        Button(role: .destructive) {
                                            components.removeAll(where: { $0.id == comp.id })
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Delete component")
                                    }

                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Weight")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            HStack {
                                                Slider(
                                                    value: Binding(
                                                        get: { comp.weightPercent },
                                                        set: { comp.weightPercent = $0 }
                                                    ),
                                                    in: 0 ... 100,
                                                    step: 1
                                                )
                                                Text(verbatim: "\(Int(comp.weightPercent))%")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                    .frame(width: 50, alignment: .trailing)
                                            }
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Score")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            HStack {
                                                Slider(
                                                    value: Binding(
                                                        get: { comp.earnedPercent ?? 0 },
                                                        set: { comp.earnedPercent = $0 }
                                                    ),
                                                    in: 0 ... 100,
                                                    step: 1
                                                )
                                                Text(verbatim: "\(Int(comp.earnedPercent ?? 0))%")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                    .frame(width: 50, alignment: .trailing)
                                            }
                                        }
                                    }

                                    Divider()
                                        .padding(.top, 4)
                                }
                            }

                            Button {
                                components.append(GradeComponent(
                                    id: UUID(),
                                    name: "New Component",
                                    weightPercent: 0,
                                    earnedPercent: nil
                                ))
                            } label: {
                                Label(
                                    NSLocalizedString(
                                        "grades.label.add.component",
                                        value: "Add Component",
                                        comment: "Add Component"
                                    ),
                                    systemImage: "plus"
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                        }
                    } header: {
                        Text("Grade Components")
                    }

                    Section {
                        Picker(selection: $letter) {
                            ForEach(letters, id: \.self) { l in
                                Text(l).tag(l)
                            }
                        } label: {
                            Text("Letter Grade")
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Letter Grade")
                    }

                    Section {
                        Text(NSLocalizedString(
                            "grades.targets.help.scenario.calculations.and",
                            value: "Targets help scenario calculations and visual indicators. This does not affect official grades.",
                            comment: "Targets help scenario calculations and visual indi..."
                        ))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }
                .formStyle(.grouped)
                .compactFormSections()
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
    }

    // MARK: - Grades Export Sheet

    struct GradesExportSheet: View {
        var courses: [GradeCourseSummary]
        var courseDetails: [CourseGradeDetail]

        @Environment(\.dismiss) private var dismiss
        @State private var selectedSemester: String = "All Semesters"
        @State private var filterCompleted: Bool = true
        @State private var filterIncomplete: Bool = true
        @State private var filterWithGrades: Bool = true
        @State private var filterWithoutGrades: Bool = true
        @State private var sortBy: ExportSortOption = .courseCode
        @State private var sortAscending: Bool = true
        @State private var includeComponents: Bool = true
        @State private var includeTargets: Bool = true
        @State private var includeNotes: Bool = false
        @State private var exportFormat: ExportFormat = .csv
        @State private var showingShareSheet: Bool = false

        enum ExportSortOption: String, CaseIterable, Identifiable {
            case courseCode = "Course Code"
            case courseTitle = "Course Title"
            case currentGrade = "Current Grade"
            case targetGrade = "Target Grade"
            case creditHours = "Credit Hours"

            var id: String { rawValue }
        }

        enum ExportFormat: String, CaseIterable, Identifiable {
            case csv = "CSV (Comma Separated)"
            case tsv = "TSV (Tab Separated)"
            case json = "JSON"
            case excel = "Excel (.xlsx)"
            case pdf = "PDF Document"

            var id: String { rawValue }

            var fileExtension: String {
                switch self {
                case .csv: "csv"
                case .tsv: "tsv"
                case .json: "json"
                case .excel: "xlsx"
                case .pdf: "pdf"
                }
            }
        }

        var filteredCourses: [GradeCourseSummary] {
            var filtered = courses

            // Apply completion filter
            filtered = filtered.filter { course in
                let hasGrade = course.currentPercentage != nil
                if hasGrade {
                    return filterWithGrades
                } else {
                    return filterWithoutGrades
                }
            }

            // Sort
            filtered.sort { c1, c2 in
                let comparison: Bool = switch sortBy {
                case .courseCode:
                    c1.courseCode < c2.courseCode
                case .courseTitle:
                    c1.courseTitle < c2.courseTitle
                case .currentGrade:
                    (c1.currentPercentage ?? 0) < (c2.currentPercentage ?? 0)
                case .targetGrade:
                    (c1.targetPercentage ?? 0) < (c2.targetPercentage ?? 0)
                case .creditHours:
                    c1.creditHours < c2.creditHours
                }
                return sortAscending ? comparison : !comparison
            }

            return filtered
        }

        var body: some View {
            VStack(spacing: 0) {
                // Custom title bar
                HStack {
                    Text("Export Grades")
                        .font(.headline)
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Cancel grade export")
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                Form {
                    Section {
                        Picker("Semester", selection: $selectedSemester) {
                            Text("All Semesters").tag("All Semesters")
                            Text("Current Semester").tag("Current Semester")
                            Text("Fall 2025").tag("Fall 2025")
                            Text("Spring 2026").tag("Spring 2026")
                        }
                    } header: {
                        Text("Time Range")
                    }

                    Section {
                        Toggle("Courses with grades", isOn: $filterWithGrades)
                        Toggle("Courses without grades", isOn: $filterWithoutGrades)
                    } header: {
                        Text("Filter by Grade Status")
                    } footer: {
                        Text("\(filteredCourses.count) course(s) will be exported")
                            .font(.caption)
                    }

                    Section {
                        Picker("Sort by", selection: $sortBy) {
                            ForEach(ExportSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }

                        Picker("Order", selection: $sortAscending) {
                            Text("Ascending").tag(true)
                            Text("Descending").tag(false)
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Sort Options")
                    }

                    Section {
                        Toggle("Include grade components", isOn: $includeComponents)
                        Toggle("Include target grades", isOn: $includeTargets)
                        Toggle("Include notes", isOn: $includeNotes)
                    } header: {
                        Text("Export Details")
                    }

                    Section {
                        Picker("Export Format", selection: $exportFormat) {
                            ForEach(ExportFormat.allCases) { format in
                                HStack {
                                    Image(systemName: iconForFormat(format))
                                        .frame(width: 20)
                                    Text(format.rawValue)
                                }
                                .tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                    } header: {
                        Text("Format")
                    } footer: {
                        Text(descriptionForFormat(exportFormat))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Section {
                        Button {
                            exportAndShare()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                Text("Export & Share")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .buttonStyle(ItoriLiquidProminentButtonStyle())
                        .disabled(filteredCourses.isEmpty)
                    }
                }
                .formStyle(.grouped)
                .compactFormSections()
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .controlBackgroundColor))
            }
            .frame(minWidth: 500, minHeight: 600)
        }

        private func iconForFormat(_ format: ExportFormat) -> String {
            switch format {
            case .csv, .tsv: "tablecells"
            case .json: "curlybraces"
            case .excel: "doc.text"
            case .pdf: "doc.richtext"
            }
        }

        private func descriptionForFormat(_ format: ExportFormat) -> String {
            switch format {
            case .csv:
                "Compatible with Excel, Google Sheets, and most spreadsheet applications"
            case .tsv:
                "Tab-separated format, ideal for importing into databases"
            case .json:
                "Structured data format, perfect for programmatic access"
            case .excel:
                "Native Excel format with formatting and multiple sheets"
            case .pdf:
                "Formatted document ready for printing or sharing"
            }
        }

        private func exportAndShare() {
            let fileURL = generateExportFile()

            #if os(macOS)
                let sharingPicker = NSSharingServicePicker(items: [fileURL])
                if let contentView = NSApp.keyWindow?.contentView {
                    sharingPicker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
                }
            #endif
        }

        private func generateExportFile() -> URL {
            let fileName = "Grades_Export_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).\(exportFormat.fileExtension)"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            switch exportFormat {
            case .csv:
                generateCSV(to: fileURL)
            case .tsv:
                generateTSV(to: fileURL)
            case .json:
                generateJSON(to: fileURL)
            case .excel:
                generateExcel(to: fileURL)
            case .pdf:
                generatePDF(to: fileURL)
            }

            return fileURL
        }

        private func generateCSV(to url: URL) {
            var csvText = "Course Code,Course Title,Current Grade,Target Grade,Letter Grade,Credit Hours"

            if includeComponents {
                csvText += ",Components"
            }
            if includeTargets {
                csvText += ",Target Details"
            }
            if includeNotes {
                csvText += ",Notes"
            }
            csvText += "\n"

            for course in filteredCourses {
                var row = [
                    course.courseCode,
                    course.courseTitle,
                    course.currentPercentage.map { String(format: "%.2f", $0) } ?? "",
                    course.targetPercentage.map { String(format: "%.2f", $0) } ?? "",
                    course.letterGrade ?? "",
                    String(course.creditHours)
                ]

                if includeComponents {
                    let detail = courseDetails.first(where: { $0.id == course.id })
                    let componentsStr = detail?.components.map { "\($0.name): \(Int($0.weightPercent))%" }
                        .joined(separator: "; ") ?? ""
                    row.append(componentsStr)
                }

                if includeTargets {
                    row.append(course.targetPercentage.map { String(format: "%.2f%%", $0) } ?? "")
                }

                if includeNotes {
                    let detail = courseDetails.first(where: { $0.id == course.id })
                    row.append(detail?.notes.replacingOccurrences(of: "\"", with: "\"\"") ?? "")
                }

                csvText += row.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
            }

            try? csvText.write(to: url, atomically: true, encoding: .utf8)
        }

        private func generateTSV(to url: URL) {
            var tsvText = "Course Code\tCourse Title\tCurrent Grade\tTarget Grade\tLetter Grade\tCredit Hours"

            if includeComponents {
                tsvText += "\tComponents"
            }
            if includeTargets {
                tsvText += "\tTarget Details"
            }
            if includeNotes {
                tsvText += "\tNotes"
            }
            tsvText += "\n"

            for course in filteredCourses {
                var row = [
                    course.courseCode,
                    course.courseTitle,
                    course.currentPercentage.map { String(format: "%.2f", $0) } ?? "",
                    course.targetPercentage.map { String(format: "%.2f", $0) } ?? "",
                    course.letterGrade ?? "",
                    String(course.creditHours)
                ]

                if includeComponents {
                    let detail = courseDetails.first(where: { $0.id == course.id })
                    let componentsStr = detail?.components.map { "\($0.name): \(Int($0.weightPercent))%" }
                        .joined(separator: "; ") ?? ""
                    row.append(componentsStr)
                }

                if includeTargets {
                    row.append(course.targetPercentage.map { String(format: "%.2f%%", $0) } ?? "")
                }

                if includeNotes {
                    let detail = courseDetails.first(where: { $0.id == course.id })
                    row.append(detail?.notes ?? "")
                }

                tsvText += row.joined(separator: "\t") + "\n"
            }

            try? tsvText.write(to: url, atomically: true, encoding: .utf8)
        }

        private func generateJSON(to url: URL) {
            let exportData = filteredCourses.map { course -> [String: Any] in
                var data: [String: Any] = [
                    "courseCode": course.courseCode,
                    "courseTitle": course.courseTitle,
                    "currentGrade": course.currentPercentage as Any,
                    "targetGrade": course.targetPercentage as Any,
                    "letterGrade": course.letterGrade as Any,
                    "creditHours": course.creditHours
                ]

                if includeComponents, let detail = courseDetails.first(where: { $0.id == course.id }) {
                    data["components"] = detail.components.map { comp in
                        [
                            "name": comp.name,
                            "weight": comp.weightPercent,
                            "earned": comp.earnedPercent as Any
                        ]
                    }
                }

                if includeNotes, let detail = courseDetails.first(where: { $0.id == course.id }) {
                    data["notes"] = detail.notes
                }

                return data
            }

            if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
                try? jsonData.write(to: url)
            }
        }

        private func generateExcel(to url: URL) {
            // Placeholder - would require external library like xlsxwriter
            // For now, generate CSV as fallback
            generateCSV(to: url)
        }

        private func generatePDF(to url: URL) {
            // Placeholder - would require PDF generation
            // For now, generate CSV as fallback
            generateCSV(to: url)
        }
    }

    // MARK: - Samples

    private extension GradesPageView {
        static var sampleCourses: [GradeCourseSummary] { [] }

        static var sampleCourseDetails: [CourseGradeDetail] { [] }
    }
#endif
