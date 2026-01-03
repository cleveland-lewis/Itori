#if os(macOS)
import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Models (namespaced to avoid clashing with existing Course model)

enum CoursesPageModel {
    struct Course: Identifiable, Hashable {
        let id: UUID
        var code: String
        var title: String
        var instructor: String
        var location: String
        var credits: Int
        var colorTag: ColorTag
        var semesterId: UUID?
        var semesterName: String
        var isArchived: Bool

        var meetingTimes: [CourseMeeting]
        var gradeInfo: CourseGradeInfo
        var syllabus: CourseSyllabus?
    }

    struct CourseMeeting: Identifiable, Hashable {
        let id: UUID
        var weekday: Int
        var startTime: Date
        var endTime: Date
        var type: String
    }

    struct CourseGradeInfo: Hashable {
        var currentPercentage: Double?
        var targetPercentage: Double?
        var letterGrade: String?
    }

    struct CourseSyllabus: Hashable {
        var categories: [SyllabusCategory]
        var notes: String
    }

    struct SyllabusCategory: Identifiable, Hashable {
        let id: UUID
        var name: String
        var weight: Double
    }


}

// Short aliases for readability inside this file
typealias CoursePageCourse = CoursesPageModel.Course
typealias CourseMeeting = CoursesPageModel.CourseMeeting
typealias CourseGradeInfo = CoursesPageModel.CourseGradeInfo
typealias CourseSyllabus = CoursesPageModel.CourseSyllabus
typealias SyllabusCategory = CoursesPageModel.SyllabusCategory


// MARK: - Root Page

struct CoursesPageView: View {
    @EnvironmentObject private var settings: AppSettingsModel
    @EnvironmentObject private var settingsCoordinator: SettingsCoordinator
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var timerManager: TimerManager
    @EnvironmentObject private var calendarManager: CalendarManager
    @EnvironmentObject private var gradesStore: GradesStore
    @EnvironmentObject private var plannerCoordinator: PlannerCoordinator
    @EnvironmentObject private var parsingStore: SyllabusParsingStore

    @State private var showingAddTaskSheet = false
    @State private var addTaskType: TaskType = .homework
    @State private var addTaskCourseId: UUID? = nil
    @State private var showingGradeSheet = false
    @State private var gradePercentInput: Double = 90
    @State private var gradeLetterInput: String = "A"
    @State private var showingParsedAssignmentsReview = false
    @State private var showingCreateModuleSheet = false
    @State private var showingFileImporter = false
    @State private var selectedModuleId: UUID? = nil
    @State private var showingBatchReview = false

    @State private var selectedCourseId: UUID? = nil
    @State private var searchText: String = ""
    @State private var showNewCourseSheet: Bool = false
    @State private var editingCourse: CoursePageCourse? = nil

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let isStacked = width < 820
            let ratios: (CGFloat, CGFloat) = {
                if isStacked { return (1, 1) }
                if width < 1200 { return (0.4, 0.6) }
                return (1.0 / 3.0, 2.0 / 3.0)
            }()

            let sidebarWidth = isStacked ? width : max(240, width * ratios.0)

            ZStack {
                Color.primaryBackground.ignoresSafeArea()

                if isStacked {
                    VStack(spacing: RootsSpacing.l) {
                        sidebarView
                            .frame(maxWidth: .infinity)
                            .layoutPriority(1)

                        rightColumn
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .layoutPriority(2)
                    }
                    .frame(maxWidth: min(proxy.size.width, 1400))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, responsivePadding(for: proxy.size.width))
                    .padding(.vertical, RootsSpacing.l)
                } else {
                    HStack(alignment: .top, spacing: RootsSpacing.l) {
                        sidebarView
                            .frame(width: sidebarWidth)
                            .layoutPriority(1)

                        rightColumn
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .layoutPriority(2)
                    }
                    .frame(maxWidth: min(proxy.size.width, 1400))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, responsivePadding(for: proxy.size.width))
                    .padding(.vertical, RootsSpacing.l)
                }
            }
        }
        .sheet(isPresented: $showNewCourseSheet) {
            CourseEditorSheet(course: editingCourse) { updated in
                persistCourse(updated)
                selectedCourseId = updated.id
            }
        }
        .sheet(isPresented: $showingAddTaskSheet) {
            AddAssignmentView(initialType: addTaskType, preselectedCourseId: addTaskCourseId) { task in
                assignmentsStore.addTask(task)
            }
            .environmentObject(coursesStore)
        }
        .sheet(isPresented: $showingGradeSheet) {
            gradeEntrySheet
        }
        .sheet(isPresented: $showingParsedAssignmentsReview) {
            if let courseId = selectedCourseId {
                ParsedAssignmentsReviewView(courseId: courseId)
                    .environmentObject(parsingStore)
                    .environmentObject(assignmentsStore)
                    .environmentObject(coursesStore)
            }
        }
        .sheet(isPresented: $showingCreateModuleSheet) {
            if let courseId = selectedCourseId {
                CreateModuleSheet(courseId: courseId) { module in
                    coursesStore.addOutlineNode(module)
                }
            }
        }
        .sheet(isPresented: $showingBatchReview) {
            // TODO: Restore BatchReviewSheet once FileParsingService is stabilized
            Text("Batch review temporarily unavailable")
                .padding()
            // if let batchState = FileParsingService.shared.batchReviewItems {
            //     BatchReviewSheet(
            //         state: batchState,
            //         onApprove: {
            //             await FileParsingService.shared.approveBatchReview(batchState)
            //         },
            //         onCancel: {
            //             Task {
            //                 await FileParsingService.shared.cancelBatchReview()
            //             }
            //         }
            //     )
            // }
        }
        .onReceive(FileParsingService.shared.$batchReviewItems) { batchState in
            showingBatchReview = batchState != nil
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .onAppear {
            if selectedCourseId == nil {
                selectedCourseId = filteredCourses.first?.id
            }
        }
        .onChange(of: filteredCourses.count) { _, _ in
            guard let currentSelection = selectedCourseId else { return }
            if !filteredCourses.contains(where: { $0.id == currentSelection }) {
                selectedCourseId = filteredCourses.first?.id
            }
        }
    }

    private var sidebarView: some View {
        CoursesSidebarView(
            courses: filteredCourses,
            selectedCourse: $selectedCourseId,
            searchText: $searchText,
            currentSemesterName: sidebarSemesterName,
            totalCreditsText: sidebarCreditsText,
            onNewCourse: {
                editingCourse = nil
                showNewCourseSheet = true
            }
        )
        .rootsCardBackground(radius: RootsRadius.card)
    }

    private var rightColumn: some View {
        Group {
            if let moduleId = selectedModuleId, 
               let module = coursesStore.outlineNodes.first(where: { $0.id == moduleId }) {
                // Show module detail
                let moduleFiles = coursesStore.nodeFiles(for: moduleId)
                ModuleDetailView(
                    module: module,
                    files: moduleFiles,
                    onBack: { selectedModuleId = nil },
                    onAddFiles: { beginAddFilesForModule(moduleId) }
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            } else if let course = currentSelection {
                CoursesPageDetailView(
                    course: course,
                    modules: coursesStore.rootOutlineNodes(for: course.id),
                    files: coursesStore.rootFiles(for: course.id),
                    onEdit: {
                        editingCourse = course
                        showNewCourseSheet = true
                    },
                    onAddAssignment: {
                        beginAddTask(for: course, type: .homework)
                    },
                    onAddExam: {
                        beginAddTask(for: course, type: .exam)
                    },
                    onAddGrade: {
                        beginAddGrade(for: course)
                    },
                    onViewPlanner: {
                        openPlanner(for: course)
                    },
                    onReviewParsedAssignments: hasParsedAssignments(for: course) ? {
                        showingParsedAssignmentsReview = true
                    } : nil,
                    onCreateModule: {
                        showingCreateModuleSheet = true
                    },
                    onAddFiles: {
                        showingFileImporter = true
                    },
                    onSelectModule: { module in
                        selectedModuleId = module.id
                    }
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                emptyDetailState
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .rootsCardBackground(radius: RootsRadius.card)
    }

    private func placeholderModule(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: RootsSpacing.s) {
            Text(title)
                .rootsSectionHeader()
            Text(detail)
                .rootsBodySecondary()
        }
        .padding(RootsSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: RootsRadius.card, style: .continuous)
                .fill(.secondaryBackground)
        )
    }

    private var filteredCourses: [CoursePageCourse] {
        let active = liveCourses.filter { !$0.isArchived }
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return active }
        let query = searchText.lowercased()
        return active.filter { course in
            course.code.lowercased().contains(query) ||
            course.title.lowercased().contains(query) ||
            course.instructor.lowercased().contains(query)
        }
    }

    private var liveCourses: [CoursePageCourse] {
        coursesStore.activeCourses.map { vm(from: $0) }
    }

    private var currentSelection: CoursePageCourse? {
        guard let selectedCourseId else { return filteredCourses.first }
        return filteredCourses.first(where: { $0.id == selectedCourseId }) ?? filteredCourses.first
    }

    private func responsivePadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<600: return 16
        case 600..<900: return 20
        case 900..<1200: return 24
        case 1200..<1600: return 32
        default: return 40
        }
    }

    private func vm(from course: Course) -> CoursePageCourse {
        let semesterName = coursesStore.semesters.first(where: { $0.id == course.semesterId })?.name ?? NSLocalizedString("courses.default.current_term", comment: "")
        let colorTag: ColorTag = {
            if let hex = course.colorHex, let tag = ColorTag.fromHex(hex) {
                return tag
            }
            let allColors = ColorTag.allCases
            let index = abs(course.id.hashValue) % allColors.count
            return allColors[index]
        }()
        let gradeEntry = gradesStore.grade(for: course.id)
        let gradeInfo = CourseGradeInfo(currentPercentage: gradeEntry?.percent, targetPercentage: nil, letterGrade: gradeEntry?.letter)
        return CoursePageCourse(
            id: course.id,
            code: course.code,
            title: course.title,
            instructor: course.instructor ?? NSLocalizedString("courses.default.instructor", comment: ""),
            location: course.location ?? NSLocalizedString("courses.default.location_tba", comment: ""),
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

    private func persistCourse(_ course: CoursePageCourse) {
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
        if let current = coursesStore.currentSemesterId {
            return current
        }
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

    private func beginAddTask(for course: CoursePageCourse, type: TaskType) {
        selectedCourseId = course.id
        addTaskCourseId = course.id
        addTaskType = type
        showingAddTaskSheet = true
    }

    private func beginAddGrade(for course: CoursePageCourse) {
        selectedCourseId = course.id
        gradePercentInput = gradesStore.grade(for: course.id)?.percent ?? 90
        gradeLetterInput = gradesStore.grade(for: course.id)?.letter ?? "A"
        showingGradeSheet = true
    }

    private func openPlanner(for course: CoursePageCourse) {
        selectedCourseId = course.id
        plannerCoordinator.openPlanner(with: course.id)
    }
    
    private func hasParsedAssignments(for course: CoursePageCourse) -> Bool {
        return !parsingStore.parsedAssignmentsByCourse(course.id).isEmpty
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard let courseId = selectedCourseId else { return }
        
        switch result {
        case .success(let urls):
            for url in urls {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let filename = url.lastPathComponent
                let fileType = url.pathExtension
                
                // Store bookmark data for persistent access
                var bookmarkData: Data?
                do {
                    bookmarkData = try url.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                } catch {
                    print("Failed to create bookmark: \(error)")
                }
                
                // Read file data for fingerprinting
                var fileData: Data?
                do {
                    fileData = try Data(contentsOf: url)
                } catch {
                    print("Failed to read file data: \(error)")
                }
                
                var file = CourseFile(
                    courseId: courseId,
                    nodeId: selectedModuleId,
                    filename: filename,
                    fileType: fileType,
                    localURL: bookmarkData?.base64EncodedString() ?? url.path,
                    isSyllabus: false,
                    isPracticeExam: false
                )
                
                // Calculate fingerprint
                file.contentFingerprint = FileParsingService.shared.calculateFingerprint(for: file)
                
                // Add to store
                coursesStore.addFile(file)
                
                // Queue for parsing if appropriate category
                if file.category.triggersAutoParsing {
                    FileParsingService.shared.queueFileForParsing(file, courseId: file.courseId)
                }
            }
        case .failure(let error):
            print("File import failed: \(error)")
        }
    }
    
    private func beginAddFilesForModule(_ moduleId: UUID) {
        selectedModuleId = moduleId
        showingFileImporter = true
    }

    private var emptyDetailState: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("courses.empty.select", comment: "Select course"))
                .font(DesignSystem.Typography.subHeader)
            Text(NSLocalizedString("courses.empty.overview", comment: "Overview"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sidebarSemesterName: String {
        if let selectedCourseId,
           let course = coursesStore.courses.first(where: { $0.id == selectedCourseId }) {
            let semesterId = course.semesterId
            if let semester = coursesStore.semesters.first(where: { $0.id == semesterId }) {
                return semester.name
            }
        }
        return coursesStore.currentSemester?.name ?? NSLocalizedString("courses.default.current_term", comment: "")
    }

    private var sidebarCreditsText: String {
        let semesterId: UUID? = {
            if let selectedCourseId,
               let course = coursesStore.courses.first(where: { $0.id == selectedCourseId }) {
                return course.semesterId
            }
            return coursesStore.currentSemesterId
        }()

        let credits = coursesStore.courses
            .filter { $0.semesterId == semesterId }
            .compactMap { $0.credits }
            .reduce(0.0, +)

        if credits <= 0 {
            return "—"
        }

        return "\(Int(credits.rounded()))"
    }
}

// MARK: - Sidebar

struct CoursesSidebarView: View {
    @EnvironmentObject private var settingsCoordinator: SettingsCoordinator

    var courses: [CoursePageCourse]
    @Binding var selectedCourse: UUID?
    @Binding var searchText: String
    var currentSemesterName: String
    var totalCreditsText: String
    var onNewCourse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("courses.list.title", comment: ""))
                    .font(DesignSystem.Typography.body)
                Text(currentSemesterName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 8)

            TextField(NSLocalizedString("courses.search.placeholder", comment: ""), text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: RootsSpacing.s) {
                HStack(spacing: RootsSpacing.s) {
                    Button {
                        onNewCourse()
                    } label: {
                        Label(NSLocalizedString("courses.action.new_course", comment: ""), systemImage: "plus")
                            .font(DesignSystem.Typography.body)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .glassChrome(cornerRadius: DesignSystem.Layout.cornerRadiusStandard)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Button {
                        settingsCoordinator.show(selecting: .courses)
                    } label: {
                        Label(NSLocalizedString("courses.action.edit_courses", comment: ""), systemImage: "pencil")
                            .font(DesignSystem.Typography.body)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .glassChrome(cornerRadius: DesignSystem.Layout.cornerRadiusStandard)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, RootsSpacing.m)

                VStack(spacing: RootsSpacing.s) {
                    SidebarWidgetTile(label: NSLocalizedString("courses.widget.current_semester", comment: ""), value: currentSemesterName)
                    SidebarWidgetTile(label: NSLocalizedString("courses.widget.total_credits", comment: ""), value: totalCreditsText)
                }
                .padding(.horizontal, RootsSpacing.m)
                .padding(.bottom, RootsSpacing.s)
            }

            Divider()
                .padding(.vertical, RootsSpacing.s)

            // Scrollable Course List
            ScrollView {
                VStack(spacing: DesignSystem.Layout.spacing.small) {
                    ForEach(courses) { course in
                        CourseSidebarRow(course: course, isSelected: selectedCourse == course.id) {
                            selectedCourse = course.id
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    }
}

private struct SidebarWidgetTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(DesignSystem.Typography.body.weight(.semibold))
                .foregroundStyle(RootsColor.textPrimary)
        }
        .padding(.horizontal, RootsSpacing.m)
        .padding(.vertical, RootsSpacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Materials.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CourseSidebarRow: View {
    var course: CoursePageCourse
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Layout.spacing.small) {
                Circle()
                    .fill(course.colorTag.color.opacity(0.9))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(course.code)
                        .rootsBody()
                        .lineLimit(1)
                    Text(course.title)
                        .rootsCaption()
                        .foregroundColor(RootsColor.textSecondary)
                        .lineLimit(1)
                    Text(course.instructor)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                GradeChip(gradeInfo: course.gradeInfo)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                        ? Color.accentColor.opacity(0.14)
                        : .secondaryBackground.opacity(0.12)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected
                        ? Color.accentColor.opacity(0.35)
                        : .separatorColor.opacity(0.18),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabelWithTooltip("\(course.code), \(course.title)")
    }
}

// MARK: - Detail

struct CoursesPageDetailView: View {
    let course: CoursePageCourse
    let modules: [CourseOutlineNode]
    let files: [CourseFile]
    var onEdit: () -> Void
    var onAddAssignment: () -> Void
    var onAddExam: () -> Void
    var onAddGrade: () -> Void
    var onViewPlanner: () -> Void
    var onReviewParsedAssignments: (() -> Void)? = nil
    var onCreateModule: () -> Void
    var onAddFiles: () -> Void
    var onSelectModule: (CourseOutlineNode) -> Void

    private let cardCorner: CGFloat = 24

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                
                // Modules & Files Section
                CourseModulesFilesSection(
                    course: course,
                    modules: modules,
                    files: files,
                    onCreateModule: onCreateModule,
                    onAddFiles: onAddFiles,
                    onSelectModule: onSelectModule
                )
                
                HStack(alignment: .top, spacing: 16) {
                    meetingsCard
                    syllabusCard
                }
            }
            .padding(.trailing, 6)
            .padding(.vertical, 12)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.code)
                        .font(DesignSystem.Typography.subHeader)
                        .foregroundStyle(.secondary)
                    Text(course.title)
                        .font(.title2.weight(.semibold))
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    GradeRing(gradeInfo: course.gradeInfo)
                    Button(NSLocalizedString("common.button.edit", comment: "")) { onEdit() }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.secondaryBackground.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous))
                        .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                Label(course.instructor, systemImage: "person")
                Label(course.location, systemImage: "mappin.and.ellipse")
                Label("\(course.credits) credits", systemImage: "number")
                Label(course.semesterName, systemImage: "calendar")
            }
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .rootsCardBackground(radius: cardCorner)
    }

    private var meetingsCard: some View {
        VStack(alignment: .leading, spacing: RootsSpacing.m) {
            sectionHeader(NSLocalizedString("courses.section.meetings", comment: ""))

            if course.meetingTimes.isEmpty {
                VStack(alignment: .leading, spacing: RootsSpacing.s) {
                    Text(NSLocalizedString("courses.empty.no_meetings", comment: "No meetings"))
                        .rootsBodySecondary()

                }
            } else {
                VStack(alignment: .leading, spacing: RootsSpacing.s) {
                    ForEach(course.meetingTimes) { meeting in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: NSLocalizedString("courses.meeting.day_time", comment: ""), weekdayName(meeting.weekday), timeRange(for: meeting)))
                                .font(DesignSystem.Typography.body)
                            Text(meeting.type)
                                .rootsCaption()
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                }
            }
        }
        .padding(RootsSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .rootsCardBackground(radius: cardCorner)
    }

    private var syllabusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(NSLocalizedString("courses.section.syllabus", comment: ""))
            if let syllabus = course.syllabus {
                VStack(spacing: DesignSystem.Layout.spacing.small) {
                    ForEach(syllabus.categories) { category in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(category.name)
                                    .font(DesignSystem.Typography.body)
                                Spacer()
                                Text(String(format: NSLocalizedString("courses.meeting.weight", comment: ""), Int(category.weight)))
                                    .font(.caption.weight(.semibold))
                            }
                            ProgressView(value: min(max(category.weight / 100, 0), 1))
                                .progressViewStyle(.linear)
                                .tint(.accentColor)
                        }
                    }
                }

                Text(syllabus.notes)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("courses.empty.no_syllabus", comment: "No syllabus"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("courses.empty.syllabus_parser", comment: ""))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(DesignSystem.Layout.padding.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .rootsCardBackground(radius: cardCorner)
    }

    private func quickActionTile(title: String, subtitle: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: RootsSpacing.m) {
                Image(systemName: systemImage)
                    .font(DesignSystem.Typography.body)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(RootsColor.accent.opacity(0.9))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .rootsBody()
                        .foregroundStyle(RootsColor.textPrimary)

                    Text(subtitle)
                        .rootsCaption()
                        .foregroundStyle(RootsColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(RootsLiquidButtonStyle(cornerRadius: 14, verticalPadding: RootsSpacing.m, horizontalPadding: RootsSpacing.m))
    }


    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.body)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        let index = max(1, min(weekday, symbols.count)) - 1
        return symbols[index]
    }

    private func timeRange(for meeting: CourseMeeting) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: meeting.startTime))–\(formatter.string(from: meeting.endTime))"
    }

    private func openCalendar(for meeting: CourseMeeting?) {
        #if os(macOS)
        guard let meeting = meeting else {
            // No meeting found, open Calendar app normally
            let calendarURL = URL(fileURLWithPath: "/Applications/Calendar.app")
            NSWorkspace.shared.open(calendarURL)
            return
        }

        // Calculate the next occurrence of this weekday
        let calendar = Calendar.current
        let now = Date()

        // Get the current weekday (1 = Sunday in Calendar, but meeting.weekday might be 0-indexed)
        // Assuming meeting.weekday is 1-7 where 1 = Sunday (matching Calendar.component)
        let targetWeekday = meeting.weekday
        let currentWeekday = calendar.component(.weekday, from: now)

        // Calculate days until next occurrence
        var daysUntil = targetWeekday - currentWeekday
        if daysUntil <= 0 {
            daysUntil += 7
        }

        // Get the target date
        guard let targetDate = calendar.date(byAdding: .day, value: daysUntil, to: now) else {
            // Fallback to opening Calendar normally
            let calendarURL = URL(fileURLWithPath: "/Applications/Calendar.app")
            NSWorkspace.shared.open(calendarURL)
            return
        }

        // Combine target date with meeting start time
        let meetingComponents = calendar.dateComponents([.hour, .minute], from: meeting.startTime)
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)

        var finalComponents = DateComponents()
        finalComponents.year = targetComponents.year
        finalComponents.month = targetComponents.month
        finalComponents.day = targetComponents.day
        finalComponents.hour = meetingComponents.hour
        finalComponents.minute = meetingComponents.minute

        guard let finalDate = calendar.date(from: finalComponents) else {
            let calendarURL = URL(fileURLWithPath: "/Applications/Calendar.app")
            NSWorkspace.shared.open(calendarURL)
            return
        }

        // Open Calendar at the specific date
        let interval = finalDate.timeIntervalSinceReferenceDate
        if let calendarURL = URL(string: "calshow:\(interval)") {
            NSWorkspace.shared.open(calendarURL)
        }
        #endif
    }
}

// MARK: - Notifications for quick actions

extension Notification.Name {
    // Legacy Notification names removed — use PlannerCoordinator and Combine publishers instead
}

// MARK: - Grade chips/rings

struct GradeChip: View {
    var gradeInfo: CourseGradeInfo

    var body: some View {
        HStack(spacing: 6) {
            if let current = gradeInfo.currentPercentage {
                Text(String(format: NSLocalizedString("courses.grade.percent_display", comment: ""), Int(current)))
                    .font(.caption.weight(.semibold))
                if let letter = gradeInfo.letterGrade {
                    Text(letter)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(NSLocalizedString("courses.grade.no_grade_yet", comment: ""))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous))
    }
}

struct GradeRing: View {
    var gradeInfo: CourseGradeInfo

    var body: some View {
        ZStack {
            Circle()
                .stroke(.separatorColor.opacity(0.08), lineWidth: 6)
                .frame(width: 64, height: 64)

            if let current = gradeInfo.currentPercentage {
                Circle()
                    .trim(from: 0, to: min(max(current / 100, 0), 1))
                    .stroke(AngularGradient(gradient: Gradient(colors: [.accentColor, .accentColor.opacity(0.5)]), center: .center), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 64, height: 64)

                VStack(spacing: 2) {
                    Text(String(format: NSLocalizedString("courses.grade.percent_display", comment: ""), Int(current)))
                        .font(DesignSystem.Typography.body)
                    Text(NSLocalizedString("courses.grade.current", comment: ""))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 2) {
                    Text(NSLocalizedString("courses.grade.no_grade_dash", comment: ""))
                        .font(DesignSystem.Typography.body)
                    Text(NSLocalizedString("courses.grade.no_grade", comment: ""))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Color tag picker

struct ColorTagPicker: View {
    @Binding var selected: ColorTag
    @EnvironmentObject private var appSettings: AppSettingsModel

    var body: some View {
        HStack(spacing: DesignSystem.Layout.spacing.small) {
            ForEach(ColorTag.allCases) { tag in
                Button {
                    selected = tag
                } label: {
                    Circle()
                        .fill(tag.color.opacity(0.95))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                        .stroke(selected == tag ? Color.accentColor : Color.separatorColor.opacity(0.12), lineWidth: selected == tag ? 3 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Editor Sheet (System Settings style)

struct CourseEditorSheet: View {
    @EnvironmentObject private var coursesStore: CoursesStore
    @Environment(\.dismiss) private var dismiss

    var course: CoursePageCourse?
    var onSave: (CoursePageCourse) -> Void

    @State private var code: String = ""
    @State private var title: String = ""
    @State private var instructor: String = ""
    @State private var instructorEmail: String = ""
    @State private var location: String = ""
    @State private var credits: Int = 3
    @State private var semesterId: UUID? = nil
    @State private var semesterName: String = ""
    @State private var colorTag: ColorTag = .blue

    private var isNew: Bool { course == nil }
    private var isSaveDisabled: Bool {
        code.trimmingCharacters(in: .whitespaces).isEmpty ||
        title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        RootsPopupContainer(
            title: isNew ? NSLocalizedString("courses.form.new_title", comment: "") : NSLocalizedString("courses.form.edit_title", comment: ""),
            subtitle: NSLocalizedString("courses.form.subtitle", comment: "")
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: RootsSpacing.l) {
                    courseSection
                    detailsSection
                }
            }
        } footer: {
            actionBar
        }
        .frame(maxWidth: 580, maxHeight: 420)
        .frame(minWidth: RootsWindowSizing.minPopupWidth, minHeight: RootsWindowSizing.minPopupHeight)
        .onAppear(perform: loadDraft)
        .onChange(of: semesterId) { _, newValue in
            if let id = newValue, let match = coursesStore.semesters.first(where: { $0.id == id }) {
                semesterName = match.name
            }
        }
    }

    private var courseSection: some View {
        VStack(alignment: .leading, spacing: RootsSpacing.m) {
            Text(NSLocalizedString("courses.section.course", comment: "Course")).rootsSectionHeader()
            RootsFormRow(label: NSLocalizedString("courses.form.label.code", comment: "")) {
                TextField("e.g. BIO 101", text: $code)
                    .frame(width: 120)
                    .textFieldStyle(.roundedBorder)
            }
            .validationHint(isInvalid: code.trimmingCharacters(in: .whitespaces).isEmpty, text: NSLocalizedString("courses.form.validation.code_required", comment: ""))

            RootsFormRow(label: NSLocalizedString("courses.form.label.title", comment: "")) {
                TextField(NSLocalizedString("courses.form.placeholder.title", comment: ""), text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            .validationHint(isInvalid: title.trimmingCharacters(in: .whitespaces).isEmpty, text: NSLocalizedString("courses.form.validation.title_required", comment: ""))

            RootsFormRow(label: NSLocalizedString("courses.form.label.instructor", comment: "")) {
                TextField(NSLocalizedString("courses.form.placeholder.instructor", comment: ""), text: $instructor)
                    .textFieldStyle(.roundedBorder)
            }

            RootsFormRow(label: NSLocalizedString("courses.form.label.email", comment: "")) {
                TextField("name@university.edu", text: $instructorEmail)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
            }

            RootsFormRow(label: NSLocalizedString("courses.form.label.location", comment: "")) {
                TextField(NSLocalizedString("courses.form.placeholder.location", comment: ""), text: $location)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: RootsSpacing.m) {
            Text(NSLocalizedString("courses.section.details", comment: "Details")).rootsSectionHeader()
            RootsFormRow(label: NSLocalizedString("courses.form.label.credits", comment: "")) {
                Stepper(value: $credits, in: 1...8) {
                    Text(String(format: NSLocalizedString("courses.info.credits_format", comment: ""), credits))
                }
                .frame(width: 120, alignment: .leading)
            }

            RootsFormRow(label: NSLocalizedString("courses.form.label.semester", comment: "")) {
                SemesterPicker(selectedSemesterId: $semesterId)
                    .frame(maxWidth: 260)
                    .environmentObject(coursesStore)
            }

            RootsFormRow(label: NSLocalizedString("courses.form.label.color", comment: "")) {
                ColorTagPicker(selected: $colorTag)
            }
        }
    }

    private var actionBar: some View {
        HStack {
            Text(NSLocalizedString("courses.info.edit_later", comment: "Edit later"))
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            Button(NSLocalizedString("courses.form.button.cancel", comment: "")) { dismiss() }
            Button(isNew ? NSLocalizedString("courses.form.button.create", comment: "") : NSLocalizedString("courses.form.button.save", comment: "")) {
                let resolvedSemesterName: String = {
                    if let id = semesterId, let match = coursesStore.semesters.first(where: { $0.id == id }) {
                        return match.name
                    }
                    return semesterName.isEmpty ? NSLocalizedString("courses.default.current_term", comment: "") : semesterName
                }()

                let newCourse = CoursePageCourse(
                    id: course?.id ?? UUID(),
                    code: code,
                    title: title,
                    instructor: instructor.isEmpty ? NSLocalizedString("courses.default.tbd", comment: "") : instructor,
                    location: location.isEmpty ? NSLocalizedString("courses.default.tbd", comment: "") : location,
                    credits: credits,
                    colorTag: colorTag,
                    semesterId: semesterId,
                    semesterName: resolvedSemesterName,
                    isArchived: course?.isArchived ?? false,
                    meetingTimes: course?.meetingTimes ?? [],
                    gradeInfo: course?.gradeInfo ?? CourseGradeInfo(currentPercentage: nil, targetPercentage: 92, letterGrade: nil),
                    syllabus: course?.syllabus
                )
                onSave(newCourse)
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(isSaveDisabled)
        }
    }

    private func loadDraft() {
        if let course {
            code = course.code
            title = course.title
            instructor = course.instructor
            instructorEmail = "" // Populate when email is available in model
            location = course.location
            credits = course.credits
            semesterId = course.semesterId
            semesterName = course.semesterName
            colorTag = course.colorTag
        } else {
            if let current = coursesStore.currentSemesterId ?? coursesStore.semesters.first?.id,
               let match = coursesStore.semesters.first(where: { $0.id == current }) {
                semesterId = match.id
                semesterName = match.name
            }
        }
    }
}

private extension View {
    func validationHint(isInvalid: Bool, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            self
            if isInvalid {
                Text(text)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Sample Data

private extension CoursesPageView {}

// MARK: - Grade Entry Sheet

private extension CoursesPageView {
    var gradeEntrySheet: some View {
        VStack(alignment: .leading, spacing: RootsSpacing.m) {
            Text(String(format: NSLocalizedString("courses.grade.add_title", comment: ""), currentSelection?.code ?? NSLocalizedString("planner.course.default", comment: "")))
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: RootsSpacing.s) {
                Text(NSLocalizedString("courses.grade.percentage", comment: "Percentage"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $gradePercentInput, in: 0...100, step: 1)
                HStack {
                    Text(String(format: NSLocalizedString("courses.grade.percent_display", comment: ""), Int(gradePercentInput)))
                    Spacer()
                    TextField(NSLocalizedString("courses.grade.letter_placeholder", comment: ""), text: $gradeLetterInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }

            HStack {
                Spacer()
                Button(NSLocalizedString("courses.form.button.cancel", comment: "")) {
                    showingGradeSheet = false
                }
                Button(NSLocalizedString("courses.form.button.save", comment: "")) {
                    if let courseId = currentSelection?.id {
                        gradesStore.upsert(courseId: courseId, percent: gradePercentInput, letter: gradeLetterInput.isEmpty ? nil : gradeLetterInput)
                    }
                    showingGradeSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 360)
    }
}
#endif
