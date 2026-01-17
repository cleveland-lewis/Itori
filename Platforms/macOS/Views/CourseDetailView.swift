#if os(macOS)
    import SwiftUI
    import UniformTypeIdentifiers

    struct CourseDetailView: View {
        let course: Course
        let semester: Semester

        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var dataManager: CoursesStore
        @EnvironmentObject private var parsingStore: SyllabusParsingStore
        @State private var draftCourse: Course
        @State private var showingSyllabusImporter = false

        private var courseAssignments: [AppTask] {
            assignmentsStore.tasks.filter { $0.courseId == draftCourse.id && $0.type != .exam }
        }

        private var courseExams: [AppTask] {
            assignmentsStore.tasks.filter { $0.courseId == draftCourse.id && $0.type == .exam }
        }

        private var upcomingCourseTasks: [AppTask] {
            assignmentsStore.tasks
                .filter { $0.courseId == draftCourse.id && !$0.isCompleted }
                .sorted { ($0.due ?? Date.distantFuture) < ($1.due ?? Date.distantFuture) }
        }

        init(course: Course, semester: Semester) {
            self.course = course
            self.semester = semester
            _draftCourse = State(initialValue: course)
        }

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    CardGrid {
                        assignmentsCard
                        examsCard
                        materialsCard
                        upcomingDeadlinesCard
                        modulesCard
                        practiceQuizzesCard
                    }
                }
                .padding(DesignSystem.Layout.padding.window) // unified token (no-op but ensures presence)
            }
            .onChange(of: draftCourse.attachments) { _, _ in
                dataManager.updateCourse(draftCourse)
            }
            .fileImporter(
                isPresented: $showingSyllabusImporter,
                allowedContentTypes: [.pdf, .plainText, .content, .item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case let .success(urls):
                    guard let url = urls.first else { return }
                    importSyllabus(url: url)
                case .failure:
                    break
                }
            }
        }

        private var upcomingDeadlinesCard: some View {
            AppCard {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                    Text(NSLocalizedString(
                        "coursedetail.upcoming.deadlines",
                        value: "Upcoming Deadlines",
                        comment: "Upcoming Deadlines"
                    ))
                    .font(DesignSystem.Typography.subHeader)
                    if upcomingCourseTasks.isEmpty {
                        Text(NSLocalizedString(
                            "coursedetail.no.upcoming.deadlines",
                            value: "No upcoming deadlines.",
                            comment: "No upcoming deadlines."
                        ))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    } else {
                        ForEach(upcomingCourseTasks.prefix(5), id: \.id) { task in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.subheadline)
                                    if let due = task.due {
                                        Text(due, style: .date)
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if task.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }

        private var header: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(draftCourse.title)
                    .font(.largeTitle.bold())

                Text(verbatim: "\(draftCourse.code) · \(semester.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var assignmentsCard: some View {
            AppCard {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                    Text(NSLocalizedString("coursedetail.assignments", value: "Assignments", comment: "Assignments"))
                        .font(DesignSystem.Typography.subHeader)

                    if courseAssignments.isEmpty {
                        Text(NSLocalizedString(
                            "coursedetail.no.assignments.linked.to.this.course.yet",
                            value: "No assignments linked to this course yet.",
                            comment: "No assignments linked to this course yet."
                        ))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    } else {
                        ForEach(courseAssignments, id: \.id) { assignment in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(assignment.title)
                                        .font(.subheadline)
                                    if let due = assignment.due {
                                        Text(due, style: .date)
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }

        private var examsCard: some View {
            AppCard {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                    Text(NSLocalizedString("coursedetail.exams", value: "Exams", comment: "Exams"))
                        .font(DesignSystem.Typography.subHeader)

                    if courseExams.isEmpty {
                        Text(NSLocalizedString(
                            "coursedetail.no.exams.linked.to.this.course.yet",
                            value: "No exams linked to this course yet.",
                            comment: "No exams linked to this course yet."
                        ))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    } else {
                        ForEach(courseExams, id: \.id) { exam in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exam.title)
                                        .font(.subheadline)
                                    if let due = exam.due {
                                        Text(due, style: .date)
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }

        private var materialsCard: some View {
            AppCard {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                    HStack {
                        Text(NSLocalizedString(
                            "coursedetail.course.materials.syllabus",
                            value: "Course Materials & Syllabus",
                            comment: "Course Materials & Syllabus"
                        ))
                        .font(DesignSystem.Typography.subHeader)
                        Spacer()
                        Button {
                            showingSyllabusImporter = true
                        } label: {
                            Label(
                                NSLocalizedString(
                                    "coursedetail.label.import.syllabus",
                                    value: "Import Syllabus",
                                    comment: "Import Syllabus"
                                ),
                                systemImage: "square.and.arrow.down"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    // Parsing status indicator
                    if let job = parsingStore.parsingJobs
                        .first(where: { $0.courseId == draftCourse.id && $0.status == .running })
                    {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Parsing syllabus...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    // Show parsed assignments ready for review
                    let pendingAssignments = parsingStore.parsedAssignmentsByCourse(draftCourse.id)
                    if !pendingAssignments.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(pendingAssignments.count) assignment(s) ready to import")
                                .font(.caption)
                            Spacer()
                            Button("Review") {
                                LOG_UI(
                                    .info,
                                    "CourseDetailView",
                                    "Review button tapped - parsed assignments review not yet implemented"
                                )
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                    }

                    AttachmentListView(attachments: $draftCourse.attachments, courseId: draftCourse.id)
                }
            }
        }

        private var modulesCard: some View {
            AppCard {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                    HStack {
                        Text(NSLocalizedString("coursedetail.modules", value: "Modules", comment: "Modules"))
                            .font(DesignSystem.Typography.subHeader)
                        Spacer()
                        NavigationLink {
                            CourseOutlineEditorView(course: course)
                                .environmentObject(dataManager)
                        } label: {
                            Label(
                                NSLocalizedString(
                                    "coursedetail.label.edit.outline",
                                    value: "Edit Outline",
                                    comment: "Edit Outline"
                                ),
                                systemImage: "list.bullet.indent"
                            )
                            .font(DesignSystem.Typography.caption)
                        }
                        .buttonStyle(.borderless)
                    }

                    if groupedAttachments.isEmpty {
                        Text(NSLocalizedString(
                            "coursedetail.no.module.files.yet",
                            value: "No module files yet.",
                            comment: "No module files yet."
                        ))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    } else {
                        let moduleNums = groupedAttachments.keys.sorted()
                        ForEach(moduleNums, id: \.self) { moduleNum in
                            moduleDisclosure(for: moduleNum)
                        }
                    }
                }
            }
        }

        private var practiceQuizzesCard: some View {
            AppCard {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                    Text(NSLocalizedString(
                        "coursedetail.practice.quizzes",
                        value: "Practice Quizzes",
                        comment: "Practice Quizzes"
                    ))
                    .font(DesignSystem.Typography.subHeader)
                    Text(NSLocalizedString(
                        "coursedetail.no.practice.quizzes.yet",
                        value: "No practice quizzes yet.",
                        comment: "No practice quizzes yet."
                    ))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
        }

        private func importSyllabus(url: URL) {
            let fm = FileManager.default
            let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destURL = docs.appendingPathComponent("\(UUID().uuidString)-\(url.lastPathComponent)")
            do {
                if fm.fileExists(atPath: destURL.path) {
                    try fm.removeItem(at: destURL)
                }

                // Secure access to the file
                let didStartAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                try fm.copyItem(at: url, to: destURL)
                let attachment = Attachment(name: url.lastPathComponent, localURL: destURL, tag: .syllabus)
                draftCourse.attachments.append(attachment)

                // START PARSING: Create job and trigger parsing
                let job = parsingStore.createJob(courseId: draftCourse.id, fileId: attachment.id)
                parsingStore.startParsing(job: job, fileURL: destURL)

                LOG_UI(.info, "CourseDetailView", "Started parsing syllabus: \(url.lastPathComponent)")
            } catch {
                DebugLogger.log("Failed to import syllabus: \(error)")
                LOG_UI(.error, "CourseDetailView", "Failed to import syllabus: \(error.localizedDescription)")
            }
        }

        private var groupedAttachments: [Int: [Attachment]] {
            let withModule = draftCourse.attachments.compactMap { attachment -> (Int, Attachment)? in
                guard let module = attachment.moduleNumber else { return nil }
                return (module, attachment)
            }
            return Dictionary(grouping: withModule, by: { $0.0 }).mapValues { $0.map(\.1) }
        }

        @ViewBuilder
        private func moduleDisclosure(for moduleNum: Int) -> some View {
            DisclosureGroup("Module \(moduleNum)") {
                let attachments = groupedAttachments[moduleNum] ?? []
                ForEach(attachments.indices, id: \.self) { index in
                    let file = attachments[index]
                    HStack(spacing: 10) {
                        Image(systemName: file.tag?.icon ?? "paperclip")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name ?? "Untitled")
                            Text(file.tag?.rawValue.capitalized ?? "Attachment")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }
#endif
