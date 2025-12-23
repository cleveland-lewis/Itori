#if os(macOS)
import SwiftUI

private struct StorageCenterItem: Identifiable {
    let id: UUID
    let displayTitle: String
    let entityType: StorageEntityType
    let contextDescription: String?
    let primaryDate: Date
    let statusDescription: String?
    let searchText: String
    let editPayload: StorageEditPayload
    let deleteAction: () -> Void
}

private enum StorageEditPayload: Identifiable {
    case course(Course)
    case semester(Semester)
    case assignment(AppTask)
    case practiceTest(PracticeTest)
    case courseFile(CourseFile)
    case outlineNode(CourseOutlineNode)

    var id: UUID {
        switch self {
        case .course(let course): return course.id
        case .semester(let semester): return semester.id
        case .assignment(let task): return task.id
        case .practiceTest(let test): return test.id
        case .courseFile(let file): return file.id
        case .outlineNode(let node): return node.id
        }
    }
}

struct StorageSettingsView: View {
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var gradesStore: GradesStore
    @State private var practiceStore = PracticeTestStore()
    @StateObject private var index = StorageIndex()

    @State private var searchText = ""
    @State private var selectedTypes: Set<StorageEntityType> = []
    @State private var sortOption: StorageSortOption = .mostRecent
    @State private var activeEdit: StorageEditPayload?
    @State private var detailItem: StorageCenterItem?
    @State private var pendingDelete: StorageCenterItem?
    @State private var showDeleteOptions = false
    @State private var showDeleteConfirm = false

    private var allItems: [StorageCenterItem] {
        var all: [StorageCenterItem] = []
        let semestersById = Dictionary(uniqueKeysWithValues: coursesStore.semesters.map { ($0.id, $0) })
        let coursesById = Dictionary(uniqueKeysWithValues: coursesStore.courses.map { ($0.id, $0) })

        for semester in coursesStore.semesters {
            all.append(
                StorageCenterItem(
                    id: semester.id,
                    displayTitle: semester.displayTitle,
                    entityType: semester.entityType,
                    contextDescription: semester.contextDescription,
                    primaryDate: semester.primaryDate,
                    statusDescription: semester.statusDescription,
                    searchText: semester.searchableText.lowercased(),
                    editPayload: .semester(semester),
                    deleteAction: { coursesStore.permanentlyDeleteSemester(semester.id) }
                )
            )
        }

        for course in coursesStore.courses {
            let semesterTitle = semestersById[course.semesterId]?.displayTitle
            all.append(
                StorageCenterItem(
                    id: course.id,
                    displayTitle: course.displayTitle,
                    entityType: course.entityType,
                    contextDescription: semesterTitle ?? course.contextDescription,
                    primaryDate: course.primaryDate,
                    statusDescription: course.statusDescription,
                    searchText: "\(course.searchableText) \(semesterTitle ?? "")".lowercased(),
                    editPayload: .course(course),
                    deleteAction: { coursesStore.deleteCourse(course) }
                )
            )
        }

        for task in assignmentsStore.tasks {
            let courseTitle = task.courseId.flatMap { coursesById[$0]?.title }
            all.append(
                StorageCenterItem(
                    id: task.id,
                    displayTitle: task.displayTitle,
                    entityType: task.entityType,
                    contextDescription: courseTitle ?? "Unassigned",
                    primaryDate: task.primaryDate,
                    statusDescription: task.statusDescription,
                    searchText: "\(task.searchableText) \(courseTitle ?? "Unassigned")".lowercased(),
                    editPayload: .assignment(task),
                    deleteAction: { assignmentsStore.removeTask(id: task.id) }
                )
            )
        }

        for test in practiceStore.tests {
            all.append(
                StorageCenterItem(
                    id: test.id,
                    displayTitle: test.displayTitle,
                    entityType: test.entityType,
                    contextDescription: test.contextDescription,
                    primaryDate: test.primaryDate,
                    statusDescription: test.statusDescription,
                    searchText: test.searchableText.lowercased(),
                    editPayload: .practiceTest(test),
                    deleteAction: { practiceStore.deleteTest(test.id) }
                )
            )
        }

        for node in coursesStore.outlineNodes {
            let courseTitle = coursesById[node.courseId]?.title
            all.append(
                StorageCenterItem(
                    id: node.id,
                    displayTitle: node.displayTitle,
                    entityType: node.entityType,
                    contextDescription: courseTitle ?? node.contextDescription,
                    primaryDate: node.primaryDate,
                    statusDescription: node.statusDescription,
                    searchText: "\(node.searchableText) \(courseTitle ?? "")".lowercased(),
                    editPayload: .outlineNode(node),
                    deleteAction: { coursesStore.deleteOutlineNode(node.id) }
                )
            )
        }

        for file in coursesStore.courseFiles {
            let courseTitle = coursesById[file.courseId]?.title
            all.append(
                StorageCenterItem(
                    id: file.id,
                    displayTitle: file.displayTitle,
                    entityType: file.entityType,
                    contextDescription: courseTitle ?? file.contextDescription,
                    primaryDate: file.primaryDate,
                    statusDescription: file.statusDescription,
                    searchText: "\(file.searchableText) \(courseTitle ?? "")".lowercased(),
                    editPayload: .courseFile(file),
                    deleteAction: { coursesStore.deleteFile(file.id) }
                )
            )
        }

        return all
    }

    private var semesterSummaries: [SemesterSummary] {
        let coursesBySemester = Dictionary(grouping: coursesStore.courses, by: \.semesterId)
        let assignmentsByCourse = Dictionary(grouping: assignmentsStore.tasks, by: { $0.courseId })
        let filesByCourse = Dictionary(grouping: coursesStore.courseFiles, by: \.courseId)
        let outlineByCourse = Dictionary(grouping: coursesStore.outlineNodes, by: \.courseId)
        let testsByCourse = Dictionary(grouping: practiceStore.tests, by: \.courseId)

        return coursesStore.semesters.map { semester in
            let courses = coursesBySemester[semester.id] ?? []
            let courseIds = Set(courses.map(\.id))
            let assignmentCount = courseIds.reduce(0) { $0 + (assignmentsByCourse[$1] ?? []).count }
            let fileCount = courseIds.reduce(0) { $0 + (filesByCourse[$1] ?? []).count }
            let outlineCount = courseIds.reduce(0) { $0 + (outlineByCourse[$1] ?? []).count }
            let testCount = courseIds.reduce(0) { $0 + (testsByCourse[$1] ?? []).count }
            return SemesterSummary(
                semester: semester,
                courses: courses.count,
                assignments: assignmentCount,
                files: fileCount,
                outlines: outlineCount,
                tests: testCount
            )
        }
        .sorted { $0.semester.startDate > $1.semester.startDate }
    }

    private var courseSummaries: [CourseSummary] {
        let assignmentsByCourse = Dictionary(grouping: assignmentsStore.tasks, by: { $0.courseId })
        let filesByCourse = Dictionary(grouping: coursesStore.courseFiles, by: \.courseId)
        let outlineByCourse = Dictionary(grouping: coursesStore.outlineNodes, by: \.courseId)
        let testsByCourse = Dictionary(grouping: practiceStore.tests, by: \.courseId)
        let gradesByCourse = Dictionary(grouping: gradesStore.grades, by: \.courseId)

        return coursesStore.courses.map { course in
            let assignments = assignmentsByCourse[course.id] ?? []
            let files = filesByCourse[course.id] ?? []
            let outlines = outlineByCourse[course.id] ?? []
            let tests = testsByCourse[course.id] ?? []
            let grades = gradesByCourse[course.id] ?? []
            return CourseSummary(
                course: course,
                assignments: assignments.count,
                files: files.count,
                outlines: outlines.count,
                tests: tests.count,
                grades: grades.count
            )
        }
        .sorted { $0.course.title < $1.course.title }
    }

    private var assignmentSummaries: [AssignmentSummary] {
        let courseById = Dictionary(uniqueKeysWithValues: coursesStore.courses.map { ($0.id, $0) })
        return assignmentsStore.tasks.map { task in
            let courseTitle = task.courseId.flatMap { courseById[$0]?.displayTitle } ?? "Unassigned"
            return AssignmentSummary(task: task, courseTitle: courseTitle)
        }
        .sorted { $0.task.primaryDate > $1.task.primaryDate }
    }

    private var fileSummaries: [FileSummary] {
        let courseById = Dictionary(uniqueKeysWithValues: coursesStore.courses.map { ($0.id, $0) })
        let nodeById = Dictionary(uniqueKeysWithValues: coursesStore.outlineNodes.map { ($0.id, $0) })
        return coursesStore.courseFiles.map { file in
            let courseTitle = courseById[file.courseId]?.displayTitle ?? "Unassigned"
            let nodeTitle = file.nodeId.flatMap { nodeById[$0]?.displayTitle }
            return FileSummary(file: file, courseTitle: courseTitle, nodeTitle: nodeTitle)
        }
        .sorted { $0.file.createdAt > $1.file.createdAt }
    }

    private var items: [StorageCenterItem] {
        let sortedIds = index.search(query: searchText, types: selectedTypes, sort: sortOption)
        let map = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
        return sortedIds.compactMap { map[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Center")
                .font(.title2.weight(.bold))

            Text("Browse, edit, or delete any saved item. Search by title to find specific data quickly.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Picker("Sort", selection: $sortOption) {
                    ForEach(StorageSortOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)

                Menu("Filter") {
                    Button("All Types") {
                        selectedTypes.removeAll()
                    }
                    Divider()
                    ForEach(StorageEntityType.allCases) { entity in
                        Button {
                            toggleType(entity)
                        } label: {
                            Label(entity.displayTypeName, systemImage: selectedTypes.contains(entity) ? "checkmark.circle.fill" : "circle")
                        }
                    }
                }

                if !selectedTypes.isEmpty {
                    Text("\(selectedTypes.count) type(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            GroupBox("Semesters") {
                VStack(spacing: 8) {
                    ForEach(semesterSummaries) { summary in
                        Button {
                            let item = StorageCenterItem(
                                id: summary.semester.id,
                                displayTitle: summary.semester.displayTitle,
                                entityType: summary.semester.entityType,
                                contextDescription: summary.semester.contextDescription,
                                primaryDate: summary.semester.primaryDate,
                                statusDescription: summary.semester.statusDescription,
                                searchText: summary.semester.searchableText.lowercased(),
                                editPayload: .semester(summary.semester),
                                deleteAction: { coursesStore.permanentlyDeleteSemester(summary.semester.id) }
                            )
                            detailItem = item
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(summary.semester.displayTitle)
                                        .font(.headline)
                                    Text("Courses: \(summary.courses)  Assignments: \(summary.assignments)  Files: \(summary.files)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(summary.semester.primaryDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Courses") {
                VStack(spacing: 8) {
                    ForEach(courseSummaries) { summary in
                        Button {
                            let item = StorageCenterItem(
                                id: summary.course.id,
                                displayTitle: summary.course.displayTitle,
                                entityType: summary.course.entityType,
                                contextDescription: summary.course.contextDescription,
                                primaryDate: summary.course.primaryDate,
                                statusDescription: summary.course.statusDescription,
                                searchText: summary.course.searchableText.lowercased(),
                                editPayload: .course(summary.course),
                                deleteAction: { coursesStore.deleteCourse(summary.course) }
                            )
                            detailItem = item
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(summary.course.displayTitle)
                                        .font(.headline)
                                    Text("Assignments: \(summary.assignments)  Files: \(summary.files)  Tests: \(summary.tests)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(summary.course.primaryDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Assignments") {
                VStack(spacing: 8) {
                    ForEach(assignmentSummaries) { summary in
                        Button {
                            let item = StorageCenterItem(
                                id: summary.task.id,
                                displayTitle: summary.task.displayTitle,
                                entityType: summary.task.entityType,
                                contextDescription: summary.courseTitle,
                                primaryDate: summary.task.primaryDate,
                                statusDescription: summary.task.statusDescription,
                                searchText: summary.task.searchableText.lowercased(),
                                editPayload: .assignment(summary.task),
                                deleteAction: { assignmentsStore.removeTask(id: summary.task.id) }
                            )
                            detailItem = item
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(summary.task.displayTitle)
                                        .font(.headline)
                                    Text(summary.courseTitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let due = summary.task.due {
                                    Text(due, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Files") {
                VStack(spacing: 8) {
                    ForEach(fileSummaries) { summary in
                        Button {
                            let item = StorageCenterItem(
                                id: summary.file.id,
                                displayTitle: summary.file.displayTitle,
                                entityType: summary.file.entityType,
                                contextDescription: summary.courseTitle,
                                primaryDate: summary.file.primaryDate,
                                statusDescription: summary.file.statusDescription,
                                searchText: summary.file.searchableText.lowercased(),
                                editPayload: .courseFile(summary.file),
                                deleteAction: { coursesStore.deleteFile(summary.file.id) }
                            )
                            detailItem = item
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(summary.file.displayTitle)
                                        .font(.headline)
                                    var details = summary.courseTitle
                                    if let nodeTitle = summary.nodeTitle {
                                        details += " - \(nodeTitle)"
                                    }
                                    Text(details)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(summary.file.primaryDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            List(items) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.entityType.icon)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayTitle)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text(item.entityType.displayTypeName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let context = item.contextDescription, !context.isEmpty {
                                Text(context)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let status = item.statusDescription {
                                Text(status)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Text(item.primaryDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("View") {
                        detailItem = item
                    }
                    .buttonStyle(.bordered)

                    Button("Edit") {
                        activeEdit = item.editPayload
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Delete") {
                        if requiresDeleteChoice(item) {
                            pendingDelete = item
                            showDeleteOptions = true
                        } else {
                            pendingDelete = item
                            showDeleteConfirm = true
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.vertical, 6)
            }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search by title")
        }
        .padding(20)
        .onAppear {
            refreshIndex()
        }
        .onChange(of: coursesStore.courses.count) { _, _ in refreshIndex() }
        .onChange(of: coursesStore.semesters.count) { _, _ in refreshIndex() }
        .onChange(of: coursesStore.outlineNodes.count) { _, _ in refreshIndex() }
        .onChange(of: coursesStore.courseFiles.count) { _, _ in refreshIndex() }
        .onChange(of: assignmentsStore.tasks.count) { _, _ in refreshIndex() }
        .onChange(of: practiceStore.tests.count) { _, _ in refreshIndex() }
        .sheet(item: $activeEdit) { payload in
            StorageEditSheet(payload: payload, coursesStore: coursesStore, assignmentsStore: assignmentsStore, practiceStore: practiceStore)
        }
        .sheet(item: $detailItem) { item in
            StorageDetailSheet(
                item: item,
                coursesStore: coursesStore,
                assignmentsStore: assignmentsStore,
                practiceStore: practiceStore,
                onEdit: { activeEdit = item.editPayload },
                onDelete: {
                    pendingDelete = item
                    if requiresDeleteChoice(item) {
                        showDeleteOptions = true
                    } else {
                        showDeleteConfirm = true
                    }
                }
            )
        }
        .confirmationDialog("Delete Container", isPresented: $showDeleteOptions, presenting: pendingDelete) { item in
            Button("Delete Only (Keep Children)") {
                handleDelete(item, mode: .detach)
            }
            Button("Delete with All Contents", role: .destructive) {
                handleDelete(item, mode: .cascade)
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { _ in
            Text(deleteImpactSummary(for: pendingDelete))
        }
        .alert("Delete Item?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    handleDelete(pendingDelete, mode: .simple)
                }
            }
        } message: {
            Text("This will permanently remove the selected item.")
        }
    }

    private func toggleType(_ entity: StorageEntityType) {
        if selectedTypes.contains(entity) {
            selectedTypes.remove(entity)
        } else {
            selectedTypes.insert(entity)
        }
    }

    private func requiresDeleteChoice(_ item: StorageCenterItem) -> Bool {
        switch item.entityType {
        case .semester, .course, .courseOutline:
            return true
        default:
            return false
        }
    }

    private enum DeleteMode {
        case simple
        case detach
        case cascade
    }

    private func handleDelete(_ item: StorageCenterItem, mode: DeleteMode) {
        switch item.editPayload {
        case .semester(let semester):
            switch mode {
            case .detach:
                let unassigned = coursesStore.ensureUnassignedSemester()
                coursesStore.reassignCourses(fromSemesterId: semester.id, toSemesterId: unassigned.id)
                coursesStore.permanentlyDeleteSemester(semester.id)
            case .cascade:
                let courses = coursesStore.courses.filter { $0.semesterId == semester.id }
                for course in courses {
                    deleteCourseCascade(course)
                }
                coursesStore.permanentlyDeleteSemester(semester.id)
            case .simple:
                coursesStore.permanentlyDeleteSemester(semester.id)
            }
        case .course(let course):
            switch mode {
            case .detach:
                let unassignedCourse = coursesStore.ensureUnassignedCourse()
                assignmentsStore.detachTasks(fromCourseId: course.id)
                coursesStore.reassignCourseAssets(fromCourseId: course.id, toCourseId: unassignedCourse.id)
                practiceStore.reassignCourse(from: course.id, to: unassignedCourse.id)
                gradesStore.reassignCourse(from: course.id, to: unassignedCourse.id)
                coursesStore.deleteCourse(course)
            case .cascade:
                deleteCourseCascade(course)
            case .simple:
                coursesStore.deleteCourse(course)
            }
        case .outlineNode(let node):
            switch mode {
            case .detach:
                coursesStore.detachOutlineNodeChildren(nodeId: node.id)
                coursesStore.deleteOutlineNode(node.id)
            case .cascade:
                coursesStore.deleteSubtree(node.id)
            case .simple:
                coursesStore.deleteOutlineNode(node.id)
            }
        case .assignment(let task):
            assignmentsStore.removeTask(id: task.id)
            AssignmentPlansStore.shared.deletePlan(for: task.id)
        case .practiceTest(let test):
            practiceStore.deleteTest(test.id)
        case .courseFile(let file):
            coursesStore.deleteFile(file.id)
        }
        refreshIndex()
        pendingDelete = nil
        showDeleteOptions = false
        showDeleteConfirm = false
    }

    private func deleteCourseCascade(_ course: Course) {
        let tasks = assignmentsStore.tasks.filter { $0.courseId == course.id }
        for task in tasks {
            assignmentsStore.removeTask(id: task.id)
            AssignmentPlansStore.shared.deletePlan(for: task.id)
        }
        let tests = practiceStore.tests.filter { $0.courseId == course.id }
        for test in tests {
            practiceStore.deleteTest(test.id)
        }
        gradesStore.remove(courseId: course.id)
        coursesStore.deleteCourseAssets(courseId: course.id)
        coursesStore.deleteCourse(course)
    }

    private func deleteImpactSummary(for item: StorageCenterItem?) -> String {
        guard let item else { return "Choose how to handle items inside this container." }
        switch item.editPayload {
        case .semester(let semester):
            let courses = coursesStore.courses.filter { $0.semesterId == semester.id }
            let courseIds = Set(courses.map(\.id))
            let assignments = assignmentsStore.tasks.filter { $0.courseId.map { courseIds.contains($0) } ?? false }.count
            let files = coursesStore.courseFiles.filter { courseIds.contains($0.courseId) }.count
            let outlines = coursesStore.outlineNodes.filter { courseIds.contains($0.courseId) }.count
            let tests = practiceStore.tests.filter { courseIds.contains($0.courseId) }.count
            let grades = gradesStore.grades.filter { courseIds.contains($0.courseId) }.count
            return "Contained items: Courses \(courses.count), Assignments \(assignments), Files \(files), Outline Nodes \(outlines), Practice Tests \(tests), Grades \(grades)."
        case .course(let course):
            let assignments = assignmentsStore.tasks.filter { $0.courseId == course.id }.count
            let files = coursesStore.courseFiles.filter { $0.courseId == course.id }.count
            let outlines = coursesStore.outlineNodes.filter { $0.courseId == course.id }.count
            let tests = practiceStore.tests.filter { $0.courseId == course.id }.count
            let grades = gradesStore.grades.filter { $0.courseId == course.id }.count
            return "Contained items: Assignments \(assignments), Files \(files), Outline Nodes \(outlines), Practice Tests \(tests), Grades \(grades)."
        case .outlineNode(let node):
            let childCount = coursesStore.countSubtreeNodes(node.id) - 1
            return "Contained items: Child outline nodes \(max(childCount, 0))."
        case .assignment, .practiceTest, .courseFile:
            return "Choose how to handle items inside this container."
        }
    }

    private func refreshIndex() {
        let entries = allItems.map {
            StorageIndexEntry(
                id: $0.id,
                title: $0.displayTitle,
                searchText: $0.searchText,
                entityType: $0.entityType,
                primaryDate: $0.primaryDate
            )
        }
        index.update(with: entries)
    }
}

private struct SemesterSummary: Identifiable {
    let id = UUID()
    let semester: Semester
    let courses: Int
    let assignments: Int
    let files: Int
    let outlines: Int
    let tests: Int
}

private struct CourseSummary: Identifiable {
    let id = UUID()
    let course: Course
    let assignments: Int
    let files: Int
    let outlines: Int
    let tests: Int
    let grades: Int
}

private struct AssignmentSummary: Identifiable {
    let id = UUID()
    let task: AppTask
    let courseTitle: String
}

private struct FileSummary: Identifiable {
    let id = UUID()
    let file: CourseFile
    let courseTitle: String
    let nodeTitle: String?
}

private struct StorageDetailSheet: View {
    let item: StorageCenterItem
    let coursesStore: CoursesStore
    let assignmentsStore: AssignmentsStore
    let practiceStore: PracticeTestStore
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let linked = linkedItems()
        VStack(alignment: .leading, spacing: 16) {
            Text(item.displayTitle)
                .font(.title2.weight(.bold))

            HStack(spacing: 8) {
                Label(item.entityType.displayTypeName, systemImage: item.entityType.icon)
                if let status = item.statusDescription {
                    Text(status)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)

            if let context = item.contextDescription, !context.isEmpty {
                Text(context)
                    .foregroundStyle(.secondary)
            }

            Text("Last Updated: \(item.primaryDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !linked.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Linked Items")
                        .font(.headline)
                    ForEach(linked, id: \.self) { entry in
                        Text(entry)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            HStack {
                Button("Delete", role: .destructive, action: onDelete)
                Spacer()
                Button("Edit", action: onEdit)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 240)
    }

    private func linkedItems() -> [String] {
        switch item.editPayload {
        case .course(let course):
            let semesterTitle = coursesStore.semesters.first(where: { $0.id == course.semesterId })?.displayTitle
            let assignments = assignmentsStore.tasks.filter { $0.courseId == course.id }.count
            let files = coursesStore.courseFiles.filter { $0.courseId == course.id }.count
            let outlines = coursesStore.outlineNodes.filter { $0.courseId == course.id }.count
            let tests = practiceStore.tests.filter { $0.courseId == course.id }.count
            let grades = gradesStore.grades.filter { $0.courseId == course.id }.count
            var rows: [String] = []
            if let semesterTitle { rows.append("Semester: \(semesterTitle)") }
            rows.append("Assignments: \(assignments)")
            rows.append("Course Files: \(files)")
            rows.append("Outline Nodes: \(outlines)")
            rows.append("Practice Tests: \(tests)")
            if grades > 0 {
                rows.append("Grades: \(grades)")
            }
            return rows
        case .semester(let semester):
            let courses = coursesStore.courses.filter { $0.semesterId == semester.id }
            let courseIds = Set(courses.map(\.id))
            let assignments = assignmentsStore.tasks.filter { $0.courseId.map { courseIds.contains($0) } ?? false }.count
            let files = coursesStore.courseFiles.filter { courseIds.contains($0.courseId) }.count
            let outlines = coursesStore.outlineNodes.filter { courseIds.contains($0.courseId) }.count
            let tests = practiceStore.tests.filter { courseIds.contains($0.courseId) }.count
            return [
                "Courses: \(courses.count)",
                "Assignments: \(assignments)",
                "Course Files: \(files)",
                "Outline Nodes: \(outlines)",
                "Practice Tests: \(tests)"
            ]
        case .assignment(let task):
            if let courseId = task.courseId,
               let courseTitle = coursesStore.courses.first(where: { $0.id == courseId })?.title {
                return ["Course: \(courseTitle)"]
            }
            return []
        case .practiceTest(let test):
            if let courseTitle = coursesStore.courses.first(where: { $0.id == test.courseId })?.title {
                return ["Course: \(courseTitle)"]
            }
            return []
        case .courseFile(let file):
            var rows: [String] = []
            if let courseTitle = coursesStore.courses.first(where: { $0.id == file.courseId })?.title {
                rows.append("Course: \(courseTitle)")
            }
            if let nodeId = file.nodeId,
               let nodeTitle = coursesStore.outlineNodes.first(where: { $0.id == nodeId })?.displayTitle {
                rows.append("Outline Node: \(nodeTitle)")
            }
            return rows
        case .outlineNode(let node):
            var rows: [String] = []
            if let courseTitle = coursesStore.courses.first(where: { $0.id == node.courseId })?.title {
                rows.append("Course: \(courseTitle)")
            }
            if let parentId = node.parentId,
               let parentTitle = coursesStore.outlineNodes.first(where: { $0.id == parentId })?.displayTitle {
                rows.append("Parent Node: \(parentTitle)")
            }
            return rows
        }
    }
}

private struct StorageEditSheet: View {
    let payload: StorageEditPayload
    let coursesStore: CoursesStore
    let assignmentsStore: AssignmentsStore
    let practiceStore: PracticeTestStore

    var body: some View {
        switch payload {
        case .course(let course):
            CourseEditSheet(course: course, coursesStore: coursesStore)
        case .semester(let semester):
            SemesterEditSheet(semester: semester, coursesStore: coursesStore)
        case .assignment(let task):
            AssignmentEditSheet(task: task, assignmentsStore: assignmentsStore)
        case .practiceTest(let test):
            PracticeTestEditSheet(test: test, practiceStore: practiceStore)
        case .courseFile(let file):
            CourseFileEditSheet(file: file, coursesStore: coursesStore)
        case .outlineNode(let node):
            OutlineNodeEditSheet(node: node, coursesStore: coursesStore)
        }
    }
}

private struct CourseEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let course: Course
    let coursesStore: CoursesStore

    @State private var title: String
    @State private var code: String
    @State private var isArchived: Bool

    init(course: Course, coursesStore: CoursesStore) {
        self.course = course
        self.coursesStore = coursesStore
        _title = State(initialValue: course.title)
        _code = State(initialValue: course.code)
        _isArchived = State(initialValue: course.isArchived)
    }

    var body: some View {
        Form {
            TextField("Title", text: $title)
            TextField("Code", text: $code)
            Toggle("Archived", isOn: $isArchived)
        }
        .padding(24)
        .frame(minWidth: 420)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var updated = course
                    updated.title = title
                    updated.code = code
                    updated.isArchived = isArchived
                    coursesStore.updateCourse(updated)
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

private struct SemesterEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let semester: Semester
    let coursesStore: CoursesStore

    @State private var term: SemesterType
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var academicYear: String
    @State private var isArchived: Bool
    @State private var notes: String

    init(semester: Semester, coursesStore: CoursesStore) {
        self.semester = semester
        self.coursesStore = coursesStore
        _term = State(initialValue: semester.semesterTerm)
        _startDate = State(initialValue: semester.startDate)
        _endDate = State(initialValue: semester.endDate)
        _academicYear = State(initialValue: semester.academicYear ?? "")
        _isArchived = State(initialValue: semester.isArchived)
        _notes = State(initialValue: semester.notes ?? "")
    }

    var body: some View {
        Form {
            Picker("Term", selection: $term) {
                ForEach(SemesterType.allCases) { term in
                    Text(term.rawValue).tag(term)
                }
            }
            DatePicker("Start", selection: $startDate, displayedComponents: .date)
            DatePicker("End", selection: $endDate, displayedComponents: .date)
            TextField("Academic Year", text: $academicYear)
            Toggle("Archived", isOn: $isArchived)
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
        .padding(24)
        .frame(minWidth: 460)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var updated = semester
                    updated.semesterTerm = term
                    updated.startDate = startDate
                    updated.endDate = endDate
                    updated.academicYear = academicYear.isEmpty ? nil : academicYear
                    updated.isArchived = isArchived
                    updated.notes = notes.isEmpty ? nil : notes
                    coursesStore.updateSemester(updated)
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

private struct AssignmentEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let task: AppTask
    let assignmentsStore: AssignmentsStore

    @State private var title: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var estimatedMinutes: Int
    @State private var isCompleted: Bool

    init(task: AppTask, assignmentsStore: AssignmentsStore) {
        self.task = task
        self.assignmentsStore = assignmentsStore
        _title = State(initialValue: task.title)
        _dueDate = State(initialValue: task.due ?? Date())
        _hasDueDate = State(initialValue: task.due != nil)
        _estimatedMinutes = State(initialValue: task.estimatedMinutes)
        _isCompleted = State(initialValue: task.isCompleted)
    }

    var body: some View {
        Form {
            TextField("Title", text: $title)
            Toggle("Has Due Date", isOn: $hasDueDate)
            if hasDueDate {
                DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
            }
            Stepper("Estimated Minutes: \(estimatedMinutes)", value: $estimatedMinutes, in: 5...600, step: 5)
            Toggle("Completed", isOn: $isCompleted)
        }
        .padding(24)
        .frame(minWidth: 440)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var updated = task
                    updated.title = title
                    updated.due = hasDueDate ? dueDate : nil
                    updated.estimatedMinutes = estimatedMinutes
                    updated.isCompleted = isCompleted
                    assignmentsStore.updateTask(updated)
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

private struct PracticeTestEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let test: PracticeTest
    let practiceStore: PracticeTestStore

    @State private var courseName: String
    @State private var topics: String

    init(test: PracticeTest, practiceStore: PracticeTestStore) {
        self.test = test
        self.practiceStore = practiceStore
        _courseName = State(initialValue: test.courseName)
        _topics = State(initialValue: test.topics.joined(separator: ", "))
    }

    var body: some View {
        Form {
            TextField("Course Name", text: $courseName)
            TextField("Topics (comma separated)", text: $topics)
        }
        .padding(24)
        .frame(minWidth: 420)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var updated = test
                    updated.courseName = courseName
                    updated.topics = topics.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                    practiceStore.updateTest(updated)
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

private struct CourseFileEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let file: CourseFile
    let coursesStore: CoursesStore

    @State private var filename: String
    @State private var fileType: String
    @State private var isSyllabus: Bool
    @State private var isPracticeExam: Bool

    init(file: CourseFile, coursesStore: CoursesStore) {
        self.file = file
        self.coursesStore = coursesStore
        _filename = State(initialValue: file.filename)
        _fileType = State(initialValue: file.fileType)
        _isSyllabus = State(initialValue: file.isSyllabus)
        _isPracticeExam = State(initialValue: file.isPracticeExam)
    }

    var body: some View {
        Form {
            TextField("Filename", text: $filename)
            TextField("File Type", text: $fileType)
            Toggle("Syllabus", isOn: $isSyllabus)
            Toggle("Practice Exam", isOn: $isPracticeExam)
        }
        .padding(24)
        .frame(minWidth: 420)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var updated = file
                    updated.filename = filename
                    updated.fileType = fileType
                    updated.isSyllabus = isSyllabus
                    updated.isPracticeExam = isPracticeExam
                    coursesStore.updateFile(updated)
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

private struct OutlineNodeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let node: CourseOutlineNode
    let coursesStore: CoursesStore

    @State private var title: String

    init(node: CourseOutlineNode, coursesStore: CoursesStore) {
        self.node = node
        self.coursesStore = coursesStore
        _title = State(initialValue: node.title)
    }

    var body: some View {
        Form {
            TextField("Title", text: $title)
        }
        .padding(24)
        .frame(minWidth: 360)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var updated = node
                    updated.title = title
                    coursesStore.updateOutlineNode(updated)
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    StorageSettingsView()
        .environmentObject(CoursesStore())
        .environmentObject(AssignmentsStore.shared)
        .environmentObject(GradesStore.shared)
        .frame(width: 900, height: 650)
}
#endif
#endif
