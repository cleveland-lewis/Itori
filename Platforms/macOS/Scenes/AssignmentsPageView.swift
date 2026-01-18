#if os(macOS)
    import Combine
    import SwiftUI

    // MARK: - Models

    enum EffortBias: String, Codable {
        case shortBursts
        case mediumBlocks
        case longBlocks
    }

    struct CategoryEffortProfile: Codable, Equatable {
        let baseMinutes: Int
        let minSessions: Int
        let spreadDaysBeforeDue: Int
        let sessionBias: EffortBias
    }

    extension AssignmentCategory {
        var effortProfile: CategoryEffortProfile {
            switch self {
            case .project:
                .init(baseMinutes: 240, minSessions: 4, spreadDaysBeforeDue: 7, sessionBias: .longBlocks)
            case .exam:
                .init(baseMinutes: 180, minSessions: 3, spreadDaysBeforeDue: 5, sessionBias: .mediumBlocks)
            case .quiz:
                .init(baseMinutes: 60, minSessions: 2, spreadDaysBeforeDue: 2, sessionBias: .shortBursts)
            case .homework, .homework:
                .init(baseMinutes: 60, minSessions: 1, spreadDaysBeforeDue: 2, sessionBias: .mediumBlocks)
            case .reading:
                .init(baseMinutes: 45, minSessions: 1, spreadDaysBeforeDue: 1, sessionBias: .shortBursts)
            case .review:
                .init(baseMinutes: 90, minSessions: 2, spreadDaysBeforeDue: 3, sessionBias: .shortBursts)
            case .practiceTest:
                .init(baseMinutes: 50, minSessions: 1, spreadDaysBeforeDue: 1, sessionBias: .mediumBlocks)
            }
        }
    }

    extension Assignment {
        static func defaultPlan(for category: AssignmentCategory, due: Date, totalMinutes: Int) -> [PlanStepStub] {
            let cal = Calendar.current
            func dayOffset(_ days: Int) -> Date {
                cal.date(byAdding: .day, value: -days, to: due) ?? due
            }

            let minutes = max(totalMinutes, category.effortProfile.baseMinutes)

            switch category {
            case .project:
                let chunk = max(60, minutes / 4)
                return [
                    PlanStepStub(title: "assignments.plan.research_gather".localized, expectedMinutes: chunk),
                    PlanStepStub(title: "assignments.plan.outline_plan".localized, expectedMinutes: chunk),
                    PlanStepStub(title: "assignments.plan.draft".localized, expectedMinutes: chunk),
                    PlanStepStub(title: "assignments.plan.polish_submit".localized, expectedMinutes: chunk)
                ]
            case .exam:
                let chunk = max(60, minutes / 3)
                return [
                    PlanStepStub(title: "assignments.plan.review_notes".localized, expectedMinutes: chunk),
                    PlanStepStub(title: "assignments.plan.practice_problems".localized, expectedMinutes: chunk),
                    PlanStepStub(title: "assignments.plan.mock_test".localized, expectedMinutes: chunk)
                ]
            case .quiz:
                let chunk = max(45, minutes / 2)
                return [
                    PlanStepStub(title: "assignments.plan.skim_outline".localized, expectedMinutes: chunk),
                    PlanStepStub(title: "assignments.plan.practice_set".localized, expectedMinutes: chunk)
                ]
            case .homework, .homework:
                let chunk = max(45, minutes)
                return [
                    PlanStepStub(title: "assignments.plan.solve_set".localized, expectedMinutes: chunk)
                ]
            case .reading:
                return [
                    PlanStepStub(
                        title: "assignments.plan.read_annotate".localized,
                        expectedMinutes: max(30, minutes / 2)
                    ),
                    PlanStepStub(title: "assignments.plan.summarize".localized, expectedMinutes: max(20, minutes / 2))
                ]
            case .review:
                return [
                    PlanStepStub(
                        title: "assignments.plan.review_key_points".localized,
                        expectedMinutes: max(30, minutes / 2)
                    ),
                    PlanStepStub(
                        title: "assignments.plan.flashcards_drill".localized,
                        expectedMinutes: max(20, minutes / 2)
                    )
                ]
            case .practiceTest:
                return [
                    PlanStepStub(title: "assignments.plan.mock_test".localized, expectedMinutes: max(40, minutes))
                ]
            }
        }
    }

    fileprivate func suggestedSessionLength(_ bias: EffortBias) -> Int {
        switch bias {
        case .shortBursts: 30
        case .mediumBlocks: 60
        case .longBlocks: 90
        }
    }

    enum AssignmentSegment: String, CaseIterable, Identifiable {
        case upcoming, all, completed
        var id: String { rawValue }

        var label: String {
            switch self {
            case .upcoming: "assignments.segment.upcoming".localized
            case .all: "assignments.segment.all".localized
            case .completed: "assignments.segment.completed".localized
            }
        }
    }

    enum AssignmentSortOption: String, CaseIterable, Identifiable {
        case byDueDate, byCourse, byUrgency
        var id: String { rawValue }

        var label: String {
            switch self {
            case .byDueDate: "assignments.sort.due_date".localized
            case .byCourse: "assignments.sort.course".localized
            case .byUrgency: "assignments.sort.urgency".localized
            }
        }
    }

    // MARK: - Root View

    struct AssignmentsPageView: View {
        @ScaledMetric private var emptyIconSize: CGFloat = 48

        @EnvironmentObject private var settings: AppSettings
        @EnvironmentObject private var coursesStore: CoursesStore
        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var appModel: AppModel
        @EnvironmentObject private var settingsCoordinator: SettingsCoordinator
        @Environment(\.appLayout) private var appLayout

        @State private var assignments: [Assignment] = []
        @State private var courseDeletedCancellable: AnyCancellable? = nil
        @State private var selectedSegment: AssignmentSegment = .upcoming
        @State private var selectedAssignment: Assignment? = nil
        @State private var searchText: String = ""
        @State private var showAddAssignmentSheet: Bool = false
        @State private var editingTask: AppTask? = nil
        @State private var sortOption: AssignmentSortOption = .byDueDate
        @State private var filterStatus: AssignmentStatus? = nil
        @State private var filterCourse: String? = nil
        @State private var showFilterPopover: Bool = false
        // Drag selection state
        @State private var selectionStart: CGPoint?
        @State private var selectionRect: CGRect?
        @State private var selectionMenuLocation: CGPoint?
        @State private var selectedIDs: Set<UUID> = []
        @State private var assignmentFrames: [UUID: CGRect] = [:]
        @State private var clipboard: [Assignment] = []

        private let cardCorner: CGFloat = 24

        var body: some View {
            GeometryReader { proxy in
                let width = proxy.size.width
                let leftWidth = min(max(width * 0.22, 240), 320)
                let rightWidth = min(max(width * 0.3, 320), 420)

                VStack(spacing: ItariSpacing.l) {
                    topControls

                    HStack(alignment: .top, spacing: 16) {
                        leftSummaryColumn
                            .frame(width: leftWidth)

                        assignmentListCard
                            .coordinateSpace(name: "assignmentsArea")
                            .gesture(dragSelectionGesture())
                            .overlay(selectionOverlay)
                            .layoutPriority(1)

                        detailPanel
                            .frame(width: rightWidth)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: min(proxy.size.width, 1400))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, responsivePadding(for: proxy.size.width))
                .padding(.top, appLayout.topContentInset)
                .padding(.bottom, ItariSpacing.l)
                .itoriSystemBackground()
            }
            .tint(settings.activeAccentColor)
            .accentColor(settings.activeAccentColor)
            .sheet(isPresented: $showAddAssignmentSheet) {
                AddAssignmentView(initialType: .homework) { task in
                    assignmentsStore.addTask(task)
                }
                .environmentObject(coursesStore)
            }
            .sheet(item: $editingTask) { task in
                AddAssignmentView(editingTask: task) { updatedTask in
                    assignmentsStore.updateTask(updatedTask)
                    editingTask = nil
                }
                .environmentObject(coursesStore)
            }
            .onChange(of: appModel.requestedAssignmentDueDate) { _, dueDate in
                guard let dueDate else { return }
                focusAssignment(closestTo: dueDate)
                appModel.requestedAssignmentDueDate = nil
            }
            .onAppear {
                syncAssignmentsFromStore()
                // subscribe to course deletions
                courseDeletedCancellable = CoursesStore.courseDeletedPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { deletedId in
                        assignmentsStore.tasks.removeAll { $0.courseId == deletedId }
                        if let fc = filterCourse, UUID(uuidString: fc) == deletedId {
                            filterCourse = nil
                        }
                        if let sel = selectedAssignment, sel.courseId == deletedId {
                            selectedAssignment = nil
                        }
                    }
            }
            .onChange(of: assignmentsStore.tasks) { _, _ in
                syncAssignmentsFromStore()
            }
        }

        // MARK: Top Controls

        private var topControls: some View {
            HStack(spacing: ItariSpacing.m) {
                Picker(
                    "assignments.segment.label".localized,
                    selection: $selectedSegment.animation(DesignSystem.Motion.standardSpring)
                ) {
                    ForEach(AssignmentSegment.allCases) { seg in
                        Text(seg.label).tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)

                TextField("assignments.search.placeholder".localized, text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 320)

                Picker("assignments.sort.label".localized, selection: $sortOption) {
                    ForEach(AssignmentSortOption.allCases) { opt in
                        Text(opt.label).tag(opt)
                    }
                }
                .pickerStyle(.menu)

                Button {
                    showFilterPopover.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Filter assignments")
                .popover(isPresented: $showFilterPopover, arrowEdge: .top) {
                    filterPopover
                        .padding(DesignSystem.Layout.padding.card)
                        .frame(width: 260)
                }

                Spacer(minLength: 12)

                Button {
                    showAddAssignmentSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.accentColor.opacity(0.18)))
                }
                .buttonStyle(.plain)
                .accessibilityLabelWithTooltip("assignments.action.new".localized)
            }
        }

        private var filterPopover: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("assignments.action.filters", value: "assignments.action.filters", comment: ""))
                    .font(DesignSystem.Typography.subHeader)
                Divider()
                Picker("assignments.filter.status".localized, selection: Binding(
                    get: { filterStatus },
                    set: { filterStatus = $0 }
                )) {
                    Text(NSLocalizedString("assignments.filter.any", value: "assignments.filter.any", comment: ""))
                        .tag(AssignmentStatus?.none)
                    ForEach(AssignmentStatus.allCases) { status in
                        Text(status.label).tag(AssignmentStatus?.some(status))
                    }
                }
                .pickerStyle(.menu)

                Picker("assignments.sort.course".localized, selection: Binding(
                    get: { filterCourse },
                    set: { filterCourse = $0 }
                )) {
                    Text(NSLocalizedString(
                        "assignments.filter.all_courses",
                        value: "assignments.filter.all_courses",
                        comment: ""
                    )).tag(String?.none)
                    ForEach(uniqueCourses, id: \.self) { course in
                        Text(course).tag(String?.some(course))
                    }
                }
                .pickerStyle(.menu)
            }
        }

        // MARK: Columns

        private var leftSummaryColumn: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    TodaySummaryCard(assignments: assignments)
                    UpcomingCountCard(assignments: assignments)
                    MissedCountCard(assignments: assignments)
                    ByCourseSummaryCard(assignments: assignments) { course in
                        filterCourse = course
                    }
                    LoadTimelineCard(assignments: assignments)
                }
                .padding(4)
            }
            .itoriCardBackground(radius: cardCorner)
        }

        private var assignmentListCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                urgencyLegend

                if selectedSegment == .upcoming {
                    if upcomingSections.allSatisfy(\.items.isEmpty) {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: emptyIconSize))
                                .foregroundStyle(.secondary)

                            Text(NSLocalizedString("assignments.empty.no_assignments", comment: ""))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(NSLocalizedString("assignments.empty.create_first", comment: ""))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                                ForEach(upcomingSections.indices, id: \.self) { index in
                                    let section = upcomingSections[index]
                                    if !section.items.isEmpty {
                                        Text(section.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .padding(.top, index == 0 ? 0 : 8)

                                        VStack(spacing: DesignSystem.Layout.spacing.small) {
                                            ForEach(section.items) { assignment in
                                                AssignmentsPageRow(
                                                    assignment: assignment,
                                                    isSelected: assignment.id == selectedAssignment?.id || selectedIDs
                                                        .contains(assignment.id),
                                                    onToggleComplete: { toggleCompletion(for: assignment) },
                                                    onSelect: { selectedAssignment = assignment },
                                                    leadingAction: settings.assignmentSwipeLeading,
                                                    trailingAction: settings.assignmentSwipeTrailing,
                                                    onPerformAction: { performSwipeAction($0, assignment: assignment) },
                                                    onSaveGrade: { earned, possible in
                                                        saveGrade(for: assignment, earned: earned, possible: possible)
                                                    }
                                                )
                                                .background(
                                                    GeometryReader { geo in
                                                        Color.clear
                                                            .preference(
                                                                key: AssignmentFramePreference.self,
                                                                value: [assignment.id: geo
                                                                    .frame(in: .named("assignmentsArea"))]
                                                            )
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else if filteredAndSortedAssignments.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: emptyIconSize))
                            .foregroundStyle(.secondary)

                        Text(NSLocalizedString("assignments.empty.no_assignments", comment: ""))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(NSLocalizedString("assignments.empty.create_first", comment: ""))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.Layout.spacing.small) {
                            ForEach(filteredAndSortedAssignments) { assignment in
                                AssignmentsPageRow(
                                    assignment: assignment,
                                    isSelected: assignment.id == selectedAssignment?.id || selectedIDs
                                        .contains(assignment.id),
                                    onToggleComplete: { toggleCompletion(for: assignment) },
                                    onSelect: { selectedAssignment = assignment },
                                    leadingAction: settings.assignmentSwipeLeading,
                                    trailingAction: settings.assignmentSwipeTrailing,
                                    onPerformAction: { performSwipeAction($0, assignment: assignment) },
                                    onSaveGrade: { earned, possible in
                                        saveGrade(for: assignment, earned: earned, possible: possible)
                                    }
                                )
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: AssignmentFramePreference.self,
                                                value: [assignment.id: geo.frame(in: .named("assignmentsArea"))]
                                            )
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(DesignSystem.Layout.padding.card)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Corners.card, style: .continuous)
                    .fill(Color(nsColor: NSColor.alternatingContentBackgroundColors[0]).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Corners.card, style: .continuous)
                            .stroke(.separatorColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }

        private var urgencyLegend: some View {
            HStack(spacing: 12) {
                Spacer()

                ForEach(AssignmentUrgency.allCases, id: \.self) { urgency in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(urgency.color)
                            .frame(width: 8, height: 8)
                        Text(urgency.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }

        private var detailPanel: some View {
            AssignmentDetailPanel(
                assignment: Binding(
                    get: { selectedAssignment },
                    set: { selectedAssignment = $0 }
                ),
                onUpdate: { updated in
                    upsertAssignment(updated)
                },
                onEdit: { toEdit in
                    openEditor(for: toEdit)
                },
                onDelete: { toDelete in
                    deleteAssignment(toDelete)
                }
            )
        }

        // MARK: Helpers

        private var filteredAndSortedAssignments: [Assignment] {
            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
            let upcomingEnd = calendar.date(byAdding: .day, value: 7, to: todayStart) ?? Date()

            var result = assignments

            // Segment filter
            result = result.filter { assignment in
                switch selectedSegment {
                case .upcoming:
                    assignment.status != .completed &&
                        assignment.dueDate >= todayStart &&
                        assignment.dueDate <= upcomingEnd
                case .all:
                    assignment.status != .archived
                case .completed:
                    assignment.status == .completed
                }
            }

            // Search
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let q = searchText.lowercased()
                result = result.filter {
                    $0.title.lowercased().contains(q) ||
                        ($0.courseCode ?? "").lowercased().contains(q) ||
                        ($0.courseName ?? "").lowercased().contains(q) ||
                        $0.category.localizedName.lowercased().contains(q)
                }
            }

            // Filters
            if let filterStatus {
                result = result.filter { $0.status == filterStatus }
            }
            if let filterCourse {
                result = result.filter { $0.courseCode == filterCourse || $0.courseName == filterCourse }
            }

            // Sort
            switch sortOption {
            case .byDueDate:
                result = result.sorted { $0.dueDate < $1.dueDate }
            case .byCourse:
                result = result.sorted { ($0.courseCode ?? "") < ($1.courseCode ?? "") }
            case .byUrgency:
                let order: [AssignmentUrgency: Int] = [.critical: 0, .high: 1, .medium: 2, .low: 3]
                result = result.sorted { (order[$0.urgency] ?? 99) < (order[$1.urgency] ?? 99) }
            }

            return result
        }

        private var upcomingSections: [(title: String, items: [Assignment])] {
            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: Date())
            let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
            let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: todayStart) ?? Date()
            let upcomingEnd = calendar.date(byAdding: .day, value: 7, to: todayStart) ?? Date()

            var result = assignments.filter { $0.status != .archived }

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let q = searchText.lowercased()
                result = result.filter {
                    $0.title.lowercased().contains(q) ||
                        ($0.courseCode ?? "").lowercased().contains(q) ||
                        ($0.courseName ?? "").lowercased().contains(q) ||
                        $0.category.localizedName.lowercased().contains(q)
                }
            }

            if let filterStatus {
                result = result.filter { $0.status == filterStatus }
            }
            if let filterCourse {
                result = result.filter { $0.courseCode == filterCourse || $0.courseName == filterCourse }
            }

            result = result.filter { $0.status != .completed && $0.dueDate >= todayStart && $0.dueDate <= upcomingEnd }
                .sorted { $0.dueDate < $1.dueDate }

            let todayItems = result.filter { calendar.isDateInToday($0.dueDate) }
            let tomorrowItems = result.filter { calendar.isDateInTomorrow($0.dueDate) }
            let weekItems = result.filter { $0.dueDate >= dayAfterTomorrow && $0.dueDate <= upcomingEnd }

            return [
                (title: "Today", items: todayItems),
                (title: "Tomorrow", items: tomorrowItems),
                (title: "This Week", items: weekItems)
            ]
        }

        private var uniqueCourses: [String] {
            Set(assignments.map { $0.courseCode ?? "" }).sorted()
        }

        private var activeFiltersLabel: String {
            var parts: [String] = []
            parts.append(String.localizedStringWithFormat(
                "assignments.filter.segment_label".localized,
                selectedSegment.label
            ))
            parts.append(String.localizedStringWithFormat(
                "assignments.filter.sort_label".localized,
                sortOption.label
            ))
            parts.append(String.localizedStringWithFormat(
                "assignments.filter.status_label".localized,
                filterStatus?.label ?? "assignments.filter.any".localized
            ))
            parts.append(String.localizedStringWithFormat(
                "assignments.filter.course_label".localized,
                filterCourse ?? "assignments.filter.any".localized
            ))
            return parts.joined(separator: " · ")
        }

        private func responsivePadding(for width: CGFloat) -> CGFloat {
            switch width {
            case ..<600: 16
            case 600 ..< 900: 20
            case 900 ..< 1200: 24
            case 1200 ..< 1600: 32
            default: 40
            }
        }

        private func toggleCompletion(for assignment: Assignment) {
            guard let idx = assignmentsStore.tasks.firstIndex(where: { $0.id == assignment.id }) else { return }
            var task = assignmentsStore.tasks[idx]
            let wasCompleted = task.isCompleted
            task.isCompleted.toggle()
            assignmentsStore.updateTask(task)
            if let updated = assignments.first(where: { $0.id == assignment.id }) {
                selectedAssignment = updated
            }

            // Play feedback when marking as completed (not when uncompleting)
            if !wasCompleted {
                Task { @MainActor in
                    Feedback.shared.play(.taskCompleted)
                }
            }
        }

        private func performSwipeAction(_ action: AssignmentSwipeAction, assignment: Assignment) {
            switch action {
            case .complete:
                toggleCompletion(for: assignment)
            case .edit:
                openEditor(for: assignment)
            case .delete:
                deleteAssignment(assignment)
            case .openDetail:
                selectedAssignment = assignment
            }
        }

        private func saveGrade(for assignment: Assignment, earned: Double, possible: Double) {
            guard let idx = assignmentsStore.tasks.firstIndex(where: { $0.id == assignment.id }) else { return }
            var task = assignmentsStore.tasks[idx]
            task.gradeEarnedPoints = earned
            task.gradePossiblePoints = possible
            assignmentsStore.updateTask(task)

            if let updated = assignments.first(where: { $0.id == assignment.id }) {
                selectedAssignment = updated
            }

            Task { @MainActor in
                Feedback.shared.play(.success)
            }
        }

        private func upsertAssignment(_ assignment: Assignment) {
            let task = AssignmentConverter.toAppTask(assignment)
            if assignmentsStore.tasks.contains(where: { $0.id == assignment.id }) {
                assignmentsStore.updateTask(task)
            } else {
                assignmentsStore.addTask(task)
            }
            selectedAssignment = ensurePlan(assignment)
        }

        private func openEditor(for assignment: Assignment) {
            if let task = assignmentsStore.tasks.first(where: { $0.id == assignment.id }) {
                editingTask = task
            } else {
                editingTask = AssignmentConverter.toAppTask(assignment)
            }
        }

        private func deleteAssignment(_ assignment: Assignment) {
            assignmentsStore.removeTask(id: assignment.id)
            if selectedAssignment?.id == assignment.id {
                selectedAssignment = nil
            }
        }

        private func autoPlanSelectedAssignments() {
            let targetAssignments: [Assignment] = if let selectedAssignment {
                [selectedAssignment]
            } else {
                filteredAndSortedAssignments
            }

            for assignment in targetAssignments {
                let defaultProfile = assignment.category.effortProfile
                var profile = defaultProfile
                if let stored = AppSettingsModel.shared.categoryEffortProfilesStorage[assignment.category.rawValue] {
                    profile = CategoryEffortProfile(
                        baseMinutes: stored.baseMinutes,
                        minSessions: stored.minSessions,
                        spreadDaysBeforeDue: stored.spreadDaysBeforeDue,
                        sessionBias: EffortBias(rawValue: stored.sessionBiasRaw) ?? defaultProfile.sessionBias
                    )
                }

                var totalMinutes = assignment.estimatedMinutes
                if totalMinutes == 0 || totalMinutes == 60 {
                    totalMinutes = profile.baseMinutes
                }
                let suggestedLen = suggestedSessionLength(profile.sessionBias)
                let computedSessions = max(profile.minSessions, Int(round(Double(totalMinutes) / Double(suggestedLen))))
                let days = max(1, profile.spreadDaysBeforeDue)
                DebugLogger
                    .log(
                        "Auto-plan for '\(assignment.title)': Typical: \(computedSessions) × \(suggestedLen) min across \(days) days (category: \(assignment.category.localizedName))"
                    )

                AssignmentPlansStore.shared.generatePlan(for: assignment, force: true)
            }
        }

        private func ensurePlan(_ assignment: Assignment) -> Assignment {
            if assignment.plan.isEmpty {
                var updated = assignment
                updated.plan = Assignment.defaultPlan(
                    for: assignment.category,
                    due: assignment.dueDate,
                    totalMinutes: assignment.estimatedMinutes
                )
                return updated
            }
            return assignment
        }

        private func syncAssignmentsFromStore() {
            let converted = assignmentsStore.tasks.filter { $0.category != .practiceTest }.map { task in
                ensurePlan(AssignmentConverter.toAssignment(task, coursesStore: coursesStore))
            }
            assignments = converted
            if AppSettingsModel.shared.devModeDataLogging {
                DebugLogger.log("✅ AssignmentsPageView sync: \(assignments.count) assignments from store")
            }
            if let selected = selectedAssignment,
               let refreshed = assignments.first(where: { $0.id == selected.id })
            {
                selectedAssignment = refreshed
            }
        }

        private func focusAssignment(closestTo dueDate: Date) {
            let sorted = assignments
                .filter { $0.status != .archived }
                .sorted { $0.dueDate < $1.dueDate }
            guard !sorted.isEmpty else { return }
            if let match = sorted.first(where: { $0.dueDate >= dueDate }) {
                selectedAssignment = match
            } else {
                selectedAssignment = sorted.first
            }
        }
    }

    // MARK: - Summary Cards

    struct TodaySummaryCard: View {
        var assignments: [Assignment]

        var body: some View {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let dueToday = assignments
                .filter { calendar.isDate($0.dueDate, inSameDayAs: today) && $0.status != .archived }
            let planned = dueToday.filter { $0.status == .inProgress }
            let remaining = dueToday.filter { $0.status != .completed }

            ItoriCard(compact: true) {
                HStack {
                    Text(NSLocalizedString(
                        "assignments.section.today",
                        value: "assignments.section.today",
                        comment: ""
                    )).itoriSectionHeader()
                    Spacer()
                }

                Text(String.localizedStringWithFormat(
                    "assignments.stats.due_planned_remaining".localized,
                    dueToday.count,
                    planned.count,
                    remaining.count
                ))
                .itoriCaption()

                HStack(spacing: 6) {
                    ForEach(AssignmentUrgency.allCases, id: \.self) { urgency in
                        let count = dueToday.filter { $0.urgency == urgency }.count
                        if count > 0 {
                            Label(
                                NSLocalizedString("assignments.label.count", value: "\(count)", comment: "\(count)"),
                                systemImage: "circle.fill"
                            )
                            .labelStyle(.titleAndIcon)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(urgency.color)
                        }
                    }
                }
            }
        }
    }

    struct ByCourseSummaryCard: View {
        var assignments: [Assignment]
        var onSelectCourse: (String) -> Void
        @Environment(\.colorScheme) private var colorScheme

        private struct CourseLoad: Identifiable {
            let id = UUID()
            let course: String
            let count: Int
        }

        private func buildCourseLoads() -> [CourseLoad] {
            let activeAssignments = assignments.filter { ($0.status ?? .notStarted) != .archived }
            let grouped = Dictionary(grouping: activeAssignments) { assignment in
                assignment.courseCode ?? "assignments.course.unknown".localized
            }
            return grouped.map { CourseLoad(course: $0.key, count: $0.value.count) }
                .sorted { $0.count > $1.count }
        }

        var body: some View {
            let courseLoads = buildCourseLoads()

            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                sectionHeader
                courseList(courseLoads: courseLoads)
            }
            .padding(DesignSystem.Layout.spacing.small)
            .background(DesignSystem.Materials.card)
            .clipShape(RoundedRectangle(
                cornerRadius: DesignSystem.Cards.cardCornerRadius,
                style: .continuous
            ))
            .overlay(cardBorder)
        }

        private var sectionHeader: some View {
            Text(NSLocalizedString(
                "assignments.section.by_course",
                value: "assignments.section.by_course",
                comment: ""
            )).itoriSectionHeader()
        }

        private func courseList(courseLoads: [CourseLoad]) -> some View {
            ForEach(courseLoads.prefix(4)) { item in
                courseRow(item: item)
            }
        }

        private func courseRow(item: CourseLoad) -> some View {
            HStack {
                Text(item.course)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(verbatim: "\(item.count)").itoriCaption()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous)
                    .stroke(ItariColor.glassBorder(for: colorScheme), lineWidth: 1)
            )
            .onTapGesture {
                onSelectCourse(item.course)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(item.course)
            .accessibilityHint("Select course")
        }

        private var cardBorder: some View {
            RoundedRectangle(
                cornerRadius: DesignSystem.Cards.cardCornerRadius,
                style: .continuous
            )
            .stroke(ItariColor.glassBorder(for: colorScheme), lineWidth: 1)
        }
    }

    struct LoadTimelineCard: View {
        var assignments: [Assignment]

        var body: some View {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let next7 = (0 ..< 7).map { calendar.date(byAdding: .day, value: $0, to: today) ?? today }

            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                Text(NSLocalizedString(
                    "assignments.section.upcoming_load",
                    value: "assignments.section.upcoming_load",
                    comment: ""
                )).itoriSectionHeader()

                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(next7, id: \.self) { day in
                        let dayAssignments = assignments
                            .filter { calendar.isDate($0.dueDate, inSameDayAs: day) && $0.status != .archived }
                        let count = dayAssignments.count
                        let avgUrgency = dayAssignments.map { urgencyValue($0.urgency) }.reduce(0, +) / max(
                            1,
                            dayAssignments.count
                        )
                        let urgencyColor = urgencyFromValue(avgUrgency).color

                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(urgencyColor.opacity(0.85))
                                .frame(width: 22, height: CGFloat(max(10, min(120, count * 14))))
                            Text(shortDayFormatter.string(from: day))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(verbatim: "\(count)")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .itoriCardBackground(radius: 16)
            .frame(maxWidth: .infinity)
        }

        private func urgencyValue(_ urgency: AssignmentUrgency) -> Int {
            switch urgency {
            case .low: 1
            case .medium: 2
            case .high: 3
            case .critical: 4
            }
        }

        private func urgencyFromValue(_ value: Int) -> AssignmentUrgency {
            switch value {
            case 4: .critical
            case 3: .high
            case 2: .medium
            default: .low
            }
        }

        private var shortDayFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return formatter
        }
    }

    struct UpcomingCountCard: View {
        var assignments: [Assignment]

        var body: some View {
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            let upcoming = assignments.filter { task in
                guard task.status != .archived else { return false }
                let due = task.dueDate
                return due >= today
            }.count

            ItoriCard(compact: true) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString(
                        "assignments.section.upcoming",
                        value: "assignments.section.upcoming",
                        comment: ""
                    )).itoriSectionHeader()
                    Text(verbatim: "\(upcoming)")
                        .font(.title.bold())
                    Text(NSLocalizedString(
                        "assignments.stats.assignments_due",
                        value: "assignments.stats.assignments_due",
                        comment: ""
                    ))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    struct MissedCountCard: View {
        var assignments: [Assignment]

        var body: some View {
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            let missed = assignments.filter { task in
                guard task.status != .archived else { return false }
                let due = task.dueDate
                return due < today && task.status != .completed
            }.count

            ItoriCard(compact: true) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString(
                        "assignments.section.missed",
                        value: "assignments.section.missed",
                        comment: ""
                    )).itoriSectionHeader()
                    Text(verbatim: "\(missed)")
                        .font(.title.bold())
                    Text(NSLocalizedString(
                        "assignments.stats.overdue_assignments",
                        value: "assignments.stats.overdue_assignments",
                        comment: ""
                    ))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Assignment Row

    struct AssignmentsPageRow: View {
        var assignment: Assignment
        var isSelected: Bool
        var onToggleComplete: () -> Void
        var onSelect: () -> Void
        var leadingAction: AssignmentSwipeAction
        var trailingAction: AssignmentSwipeAction
        var onPerformAction: (AssignmentSwipeAction) -> Void
        var onSaveGrade: (Double, Double) -> Void
        @EnvironmentObject private var plannerCoordinator: PlannerCoordinator

        @State private var showGradePopover = false
        @State private var earnedPoints: String = ""
        @State private var possiblePoints: String = ""

        private var urgencyColor: Color { assignment.urgency.color }

        var body: some View {
            Button(action: onSelect) {
                HStack(spacing: 10) {
                    Rectangle()
                        .fill(urgencyColor)
                        .frame(width: 4)
                        .cornerRadius(2)
                        .padding(.vertical, 6)

                    Button(action: onToggleComplete) {
                        Image(systemName: assignment.status == .completed ? "checkmark.square.fill" : "square")
                            .foregroundColor(assignment.status == .completed ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(assignment.title)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text(assignment.courseCode ?? "")
                            Text(String.localizedStringWithFormat(
                                "assignments.row.category_label".localized,
                                assignment.category.localizedName
                            ))
                            Text(String.localizedStringWithFormat(
                                "assignments.row.estimated_minutes".localized,
                                assignment.estimatedMinutes
                            ))
                            Text(NSLocalizedString("·", value: "·", comment: ""))
                            Text(String.localizedStringWithFormat(
                                "assignments.row.due".localized,
                                dueFormatter.string(from: assignment.dueDate)
                            ))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.secondaryBackground.opacity(0.95))
                            .overlay(
                                Capsule()
                                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                            if let weight = assignment.weightPercent {
                                Text(String.localizedStringWithFormat(
                                    "assignments.row.weight_percent".localized,
                                    Int(weight)
                                ))
                            }
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }

                    Spacer()

                    statusChip
                }
                .padding(.horizontal, 10)
                .frame(height: DesignSystem.Layout.rowHeight.medium)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? Color(nsColor: NSColor.unemphasizedSelectedContentBackgroundColor)
                            .opacity(0.14) : Color(nsColor: NSColor.alternatingContentBackgroundColors[0]).opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.separatorColor.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                swipeButton(for: leadingAction)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                swipeButton(for: trailingAction)
            }
            .contextMenu {
                Button(NSLocalizedString(
                    "assignments.action.add_grade",
                    value: "assignments.action.add_grade",
                    comment: ""
                )) {
                    showGradePopover = true
                }

                Button(NSLocalizedString(
                    "timer.context.go_to_planner",
                    value: "timer.context.go_to_planner",
                    comment: ""
                )) {
                    plannerCoordinator.openPlanner(for: assignment.dueDate, courseId: assignment.courseId)
                }
            }
            .popover(isPresented: $showGradePopover) {
                gradePopoverContent
            }
        }

        @ViewBuilder
        private func swipeButton(for action: AssignmentSwipeAction) -> some View {
            Button {
                onPerformAction(action)
            } label: {
                Label(action.label, systemImage: action.systemImage)
            }
            .tint(tintColor(for: action))
        }

        private func tintColor(for action: AssignmentSwipeAction) -> Color {
            switch action {
            case .complete: .green
            case .edit: .blue
            case .delete: .red
            case .openDetail: .accentColor
            }
        }

        private var gradePopoverContent: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString(
                    "assignments.action.add_grade",
                    value: "assignments.action.add_grade",
                    comment: ""
                ))
                .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString(
                            "assignments.grade.earned_points",
                            value: "assignments.grade.earned_points",
                            comment: ""
                        ))
                        .font(.subheadline)
                        TextField("0", text: $earnedPoints)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString(
                            "assignments.grade.possible_points",
                            value: "assignments.grade.possible_points",
                            comment: ""
                        ))
                        .font(.subheadline)
                        TextField("100", text: $possiblePoints)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }
                }

                HStack {
                    Button(NSLocalizedString("common.cancel", value: "common.cancel", comment: "")) {
                        showGradePopover = false
                        earnedPoints = ""
                        possiblePoints = ""
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button(NSLocalizedString("assignments.grade.save", value: "assignments.grade.save", comment: "")) {
                        saveGrade()
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isGradeValid)
                }
            }
            .padding(20)
            .frame(width: 300)
        }

        private var isGradeValid: Bool {
            guard let earned = Double(earnedPoints),
                  let possible = Double(possiblePoints),
                  earned >= 0,
                  possible > 0,
                  earned <= possible
            else {
                return false
            }
            return true
        }

        private func saveGrade() {
            guard let earned = Double(earnedPoints),
                  let possible = Double(possiblePoints)
            else {
                return
            }

            onSaveGrade(earned, possible)
            showGradePopover = false
            earnedPoints = ""
            possiblePoints = ""
        }

        private var statusChip: some View {
            Text((assignment.status ?? .notStarted).label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.secondaryBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(.separatorColor, lineWidth: 1)
                )
        }

        private var dueFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            return formatter
        }
    }

    // MARK: - Detail Panel

    struct AssignmentDetailPanel: View {
        @Binding var assignment: Assignment?
        var onUpdate: (Assignment) -> Void
        var onEdit: (Assignment) -> Void
        var onDelete: (Assignment) -> Void
        @EnvironmentObject private var plannerCoordinator: PlannerCoordinator
        @EnvironmentObject private var appModel: AppModel

        private let cardCorner: CGFloat = 24

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                if let assignment {
                    header(for: assignment)
                    Divider()
                    dueSection(for: assignment)
                    gradeImpact(for: assignment)
                    actionsSection(for: assignment)
                    planSection(for: assignment)
                    footerActions(for: assignment)
                } else {
                    placeholder
                }
            }
            .padding(DesignSystem.Layout.padding.card)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .itoriCardBackground(radius: cardCorner)
        }

        private func header(for assignment: Assignment) -> some View {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(assignment.title)
                        .font(.title3.weight(.semibold))
                    Text(String.localizedStringWithFormat(
                        "assignments.detail.course_line".localized,
                        assignment.courseCode ?? "assignments.course.unknown".localized,
                        assignment.courseName ?? "assignments.course.unknown".localized
                    ))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
                Text((assignment.status ?? .notStarted).label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(.secondaryBackground)
                    )
                Button {
                    onEdit(assignment)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .buttonStyle(.plain)
            }
        }

        private func dueSection(for assignment: Assignment) -> some View {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                Text(String.localizedStringWithFormat(
                    "assignments.detail.due".localized,
                    fullDateFormatter.string(from: assignment.dueDate)
                ))
                .font(DesignSystem.Typography.subHeader)
                Text(countdownText(for: assignment.dueDate))
                    .font(.footnote)
                    .foregroundColor(.secondary)

                HStack(spacing: DesignSystem.Layout.spacing.small) {
                    Label(String.localizedStringWithFormat(
                        "assignments.detail.estimated_time".localized,
                        assignment.estimatedMinutes
                    ), systemImage: "timer")
                        .font(DesignSystem.Typography.caption)
                        .padding(DesignSystem.Layout.spacing.small)
                        .background(Capsule().fill(Color(nsColor: NSColor.alternatingContentBackgroundColors[0])))
                    Toggle("assignments.detail.lock_due".localized, isOn: Binding(
                        get: { assignment.isLockedToDueDate },
                        set: { newValue in
                            var updated = assignment
                            updated.isLockedToDueDate = newValue
                            onUpdate(updated)
                            self.assignment = updated
                        }
                    ))
                    .toggleStyle(.switch)
                }
            }
        }

        private func gradeImpact(for assignment: Assignment) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString(
                    "assignments.detail.grade_impact",
                    value: "assignments.detail.grade_impact",
                    comment: ""
                ))
                .font(DesignSystem.Typography.subHeader)
                if let weight = assignment.weightPercent {
                    Text(String.localizedStringWithFormat(
                        "assignments.detail.worth_percent".localized,
                        Int(weight),
                        assignment.category.localizedName
                    ))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                    ProgressView(value: min(max(weight / 100, 0), 1))
                        .progressViewStyle(.linear)
                } else {
                    Text(NSLocalizedString(
                        "assignments.detail.no_weight",
                        value: "assignments.detail.no_weight",
                        comment: ""
                    ))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }

        private func planSection(for assignment: Assignment) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("assignments.detail.plan", value: "assignments.detail.plan", comment: ""))
                    .font(DesignSystem.Typography.subHeader)
                ForEach(assignment.plan) { step in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(DesignSystem.Typography.body)
                            Text(String.localizedStringWithFormat(
                                "assignments.detail.minutes_short".localized,
                                step.expectedMinutes
                            ))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(String.localizedStringWithFormat(
                            "assignments.detail.minutes_estimate".localized,
                            step.expectedMinutes
                        ))
                        .font(DesignSystem.Typography.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(nsColor: NSColor.alternatingContentBackgroundColors[0]))
                    )
                }
            }
        }

        private func actionsSection(for assignment: Assignment) -> some View {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                Text(NSLocalizedString("assignments.detail.actions", value: "assignments.detail.actions", comment: ""))
                    .itoriSectionHeader()
                HStack(spacing: ItariSpacing.s) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString(
                            "assignments.detail.state",
                            value: "assignments.detail.state",
                            comment: ""
                        ))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        Button(NSLocalizedString(
                            "assignments.detail.mark_completed",
                            value: "assignments.detail.mark_completed",
                            comment: ""
                        )) {
                            var updated = assignment
                            let wasCompleted = updated.status == .completed
                            updated.status = .completed
                            onUpdate(updated)
                            self.assignment = updated

                            // Play feedback when newly completing
                            if !wasCompleted {
                                Task { @MainActor in
                                    Feedback.shared.play(.taskCompleted)
                                }
                            }
                        }
                        .buttonStyle(.itoriLiquidProminent)
                        .controlSize(.small)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString(
                            "assignments.detail.planning",
                            value: "assignments.detail.planning",
                            comment: ""
                        ))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        Button(NSLocalizedString(
                            "assignments.detail.planner",
                            value: "assignments.detail.planner",
                            comment: ""
                        )) {
                            plannerCoordinator.openPlanner(for: assignment.dueDate, courseId: assignment.courseId)
                        }
                        .buttonStyle(.itariLiquid)
                        .controlSize(.small)
                        .accessibilityLabelWithTooltip("assignments.detail.planner_accessibility".localized)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString(
                            "assignments.detail.execution",
                            value: "assignments.detail.execution",
                            comment: ""
                        ))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        Button(NSLocalizedString(
                            "assignments.detail.timer",
                            value: "assignments.detail.timer",
                            comment: ""
                        )) {
                            appModel.selectedPage = .timer
                        }
                        .buttonStyle(.itariLiquid)
                        .controlSize(.small)
                        .accessibilityLabelWithTooltip("assignments.detail.timer_accessibility".localized)
                    }
                }
            }
        }

        private func footerActions(for assignment: Assignment) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button(NSLocalizedString(
                        "assignments.detail.mark_completed_full",
                        value: "assignments.detail.mark_completed_full",
                        comment: ""
                    )) {
                        var updated = assignment
                        let wasCompleted = updated.status == .completed
                        updated.status = .completed
                        onUpdate(updated)
                        self.assignment = updated

                        // Play feedback when newly completing
                        if !wasCompleted {
                            Task { @MainActor in
                                Feedback.shared.play(.taskCompleted)
                            }
                        }
                    }

                    Button(NSLocalizedString(
                        "assignments.detail.archive",
                        value: "assignments.detail.archive",
                        comment: ""
                    )) {
                        var updated = assignment
                        updated.status = .archived
                        onUpdate(updated)
                        self.assignment = updated
                    }
                }
                .buttonStyle(.itoriLiquidProminent)
                .controlSize(.small)

                Divider()

                Button(role: .destructive) {
                    onDelete(assignment)
                    self.assignment = nil
                } label: {
                    Text(NSLocalizedString(
                        "assignments.detail.delete",
                        value: "assignments.detail.delete",
                        comment: ""
                    ))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.itoriLiquidProminent)
                .controlSize(.small)
            }
        }

        private var placeholder: some View {
            VStack(spacing: 12) {
                Image(systemName: "tray.full")
                    .font(DesignSystem.Typography.display)
                    .foregroundColor(.secondary)
                Text(NSLocalizedString(
                    "assignments.detail.empty_title",
                    value: "assignments.detail.empty_title",
                    comment: ""
                ))
                .font(.headline.weight(.semibold))
                Text(NSLocalizedString(
                    "assignments.detail.empty_subtitle",
                    value: "assignments.detail.empty_subtitle",
                    comment: ""
                ))
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }

        private func countdownText(for date: Date) -> String {
            let now = Date()
            let components = Calendar.current.dateComponents([.day, .hour], from: now, to: date)
            if let day = components.day, day > 0 {
                return String.localizedStringWithFormat(
                    "assignments.detail.due_in_days".localized,
                    day
                )
            } else if let hour = components.hour, hour > 0 {
                return String.localizedStringWithFormat(
                    "assignments.detail.due_in_hours".localized,
                    hour
                )
            } else {
                return "assignments.detail.due_soon".localized
            }
        }

        private var fullDateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d · h:mm a"
            return formatter
        }
    }

    // MARK: - Editor Sheet

    struct AssignmentEditorSheet: View {
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject private var coursesStore: CoursesStore
        @EnvironmentObject private var settingsCoordinator: SettingsCoordinator

        var assignment: Assignment?
        var onSave: (Assignment) -> Void

        @State private var title: String = ""
        @State private var selectedCourseId: UUID? = nil
        @State private var category: AssignmentCategory = .homework
        @State private var dueDate: Date = .init()
        @State private var estimatedMinutes: Int = 60
        @State private var urgency: AssignmentUrgency = .medium
        @State private var weightText: String = ""
        @State private var isLocked: Bool = false
        @State private var notes: String = ""
        @State private var status: AssignmentStatus = .notStarted

        var body: some View {
            ItoriPopupContainer(
                title: assignment == nil ? "assignments.editor.title.new".localized : "assignments.editor.title.edit"
                    .localized,
                subtitle: "assignments.editor.subtitle".localized
            ) {
                ScrollView {
                    VStack(alignment: .leading, spacing: ItariSpacing.l) {
                        VStack(alignment: .leading, spacing: ItariSpacing.m) {
                            Text(NSLocalizedString(
                                "assignments.editor.section.task",
                                value: "assignments.editor.section.task",
                                comment: ""
                            )).itoriSectionHeader()
                            ItoriFormRow(label: "assignments.editor.field.title".localized) {
                                TextField("assignments.editor.field.title".localized, text: $title)
                                    .textFieldStyle(.roundedBorder)
                            }
                            coursePickerRow
                            ItoriFormRow(label: "assignments.editor.field.category".localized) {
                                Picker("assignments.editor.field.category".localized, selection: $category) {
                                    ForEach(AssignmentCategory.allCases) { cat in
                                        Text(cat.localizedName).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }

                        VStack(alignment: .leading, spacing: ItariSpacing.m) {
                            Text(NSLocalizedString(
                                "assignments.editor.section.timing",
                                value: "assignments.editor.section.timing",
                                comment: ""
                            )).itoriSectionHeader()
                            ItoriFormRow(label: "assignments.editor.field.due_date".localized) {
                                DatePicker("", selection: $dueDate)
                                    .labelsHidden()
                            }
                            ItoriFormRow(label: "assignments.editor.field.estimated".localized) {
                                Stepper(value: $estimatedMinutes, in: 15 ... 240, step: 15) {
                                    Text(String.localizedStringWithFormat(
                                        "assignments.editor.field.estimated_minutes".localized,
                                        estimatedMinutes
                                    ))
                                    .itoriBody()
                                }
                            } helper: {
                                // Show category-driven suggestion
                                let profile = category.effortProfile
                                let sessionLen = suggestedSessionLength(profile.sessionBias)
                                let sessions = max(
                                    profile.minSessions,
                                    Int(round(Double(profile.baseMinutes) / Double(sessionLen)))
                                )
                                Text(String.localizedStringWithFormat(
                                    "assignments.editor.field.typical_sessions".localized,
                                    sessions,
                                    sessionLen,
                                    profile.spreadDaysBeforeDue,
                                    category.localizedName
                                ))
                                .itoriCaption()
                                .foregroundColor(.secondary)
                            }
                            ItoriFormRow(label: "assignments.editor.field.urgency".localized) {
                                Picker("", selection: $urgency) {
                                    ForEach(AssignmentUrgency.creationOptions) { u in
                                        Text(u.label).tag(u)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            ItoriFormRow(label: "assignments.editor.field.weight".localized) {
                                TextField("assignments.editor.field.weight_placeholder".localized, text: $weightText)
                                    .textFieldStyle(.roundedBorder)
                            }
                            ItoriFormRow(label: "assignments.editor.field.lock".localized) {
                                Toggle("assignments.detail.lock_due".localized, isOn: $isLocked)
                                    .toggleStyle(.switch)
                            }
                        }

                        VStack(alignment: .leading, spacing: ItariSpacing.m) {
                            Text(NSLocalizedString(
                                "assignments.editor.section.status",
                                value: "assignments.editor.section.status",
                                comment: ""
                            )).itoriSectionHeader()
                            ItoriFormRow(label: "assignments.editor.field.status".localized) {
                                Picker("", selection: $status) {
                                    ForEach(AssignmentStatus.allCases) { s in
                                        Text(s.label).tag(s)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }

                        VStack(alignment: .leading, spacing: ItariSpacing.m) {
                            Text(NSLocalizedString(
                                "assignments.editor.field.notes",
                                value: "assignments.editor.field.notes",
                                comment: ""
                            )).itoriSectionHeader()
                            TextEditor(text: $notes)
                                .textEditorStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .padding(DesignSystem.Layout.spacing.small)
                                .frame(minHeight: 120)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: DesignSystem.Cards.cardCornerRadius,
                                        style: .continuous
                                    )
                                    .fill(ItariColor.inputBackground)
                                )
                                .clipShape(RoundedRectangle(
                                    cornerRadius: DesignSystem.Cards.cardCornerRadius,
                                    style: .continuous
                                ))
                        }
                    }
                }
            } footer: {
                HStack {
                    Spacer()
                    Button(NSLocalizedString(
                        "assignments.editor.action.cancel",
                        value: "assignments.editor.action.cancel",
                        comment: ""
                    )) { dismiss() }
                    Button(NSLocalizedString(
                        "assignments.editor.action.save",
                        value: "assignments.editor.action.save",
                        comment: ""
                    )) {
                        let weight = Double(weightText)
                        let course = coursesStore.courses.first(where: { $0.id == selectedCourseId })
                        let newAssignment = Assignment(
                            id: assignment?.id ?? UUID(),
                            courseId: course?.id,
                            title: title,
                            dueDate: dueDate,
                            estimatedMinutes: estimatedMinutes,
                            weightPercent: weight,
                            category: category,
                            urgency: urgency,
                            isLockedToDueDate: isLocked,
                            plan: [],
                            status: status,
                            courseCode: course?.code ?? "",
                            courseName: course?.title ?? "",
                            notes: notes
                        )
                        onSave(newAssignment)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCourseId == nil)
                }
            }
            .onAppear {
                prefillCourse()
                if let assignment {
                    title = assignment.title
                    selectedCourseId = assignment.courseId
                    category = assignment.category
                    dueDate = assignment.dueDate
                    estimatedMinutes = assignment.estimatedMinutes
                    urgency = assignment.urgency
                    if let weight = assignment.weightPercent {
                        weightText = "\(weight)"
                    }
                    isLocked = assignment.isLockedToDueDate
                    notes = assignment.notes ?? "" as String
                    status = assignment.status ?? .notStarted
                }
            }
            .frame(minWidth: WindowSizing.minPopupWidth, minHeight: WindowSizing.minPopupHeight)
        }

        private var coursePickerRow: some View {
            let activeCourses = currentSemesterCourses
            return ItoriFormRow(label: "assignments.editor.field.course".localized) {
                if activeCourses.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString(
                            "assignments.editor.course.empty",
                            value: "assignments.editor.course.empty",
                            comment: ""
                        ))
                        .foregroundStyle(.secondary)
                        Button(NSLocalizedString(
                            "assignments.editor.course.add",
                            value: "assignments.editor.course.add",
                            comment: ""
                        )) {
                            settingsCoordinator.show(selecting: .courses)
                        }
                        .buttonStyle(.link)
                    }
                } else {
                    Picker("assignments.editor.field.course".localized, selection: $selectedCourseId) {
                        ForEach(activeCourses) { course in
                            Text(String.localizedStringWithFormat(
                                "assignments.editor.course.option".localized,
                                course.code,
                                course.title
                            ))
                            .tag(Optional(course.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
            } helper: {
                if selectedCourseId == nil {
                    Text(NSLocalizedString(
                        "assignments.editor.course.helper",
                        value: "assignments.editor.course.helper",
                        comment: ""
                    ))
                    .itoriCaption()
                    .foregroundStyle(.red)
                }
            }
        }

        private var currentSemesterCourses: [Course] {
            if let current = coursesStore.currentSemesterId {
                return coursesStore.courses.filter { $0.semesterId == current }
            }
            // Fallback to most recent semester by start date
            if let recent = coursesStore.semesters.sorted(by: { $0.startDate > $1.startDate }).first {
                return coursesStore.courses.filter { $0.semesterId == recent.id }
            }
            return []
        }

        private func prefillCourse() {
            if let assignment, let existingId = assignment.courseId {
                selectedCourseId = existingId
                return
            }
            if selectedCourseId == nil {
                selectedCourseId = currentSemesterCourses.first?.id
            }
        }
    }

    // MARK: - Samples

    private extension AssignmentsPageView {
        static var sampleAssignments: [Assignment] { [] }
    }

    // MARK: - Drag Selection (Assignments)

    private extension AssignmentsPageView {
        func dragSelectionGesture() -> some Gesture {
            DragGesture(minimumDistance: 8, coordinateSpace: .named("assignmentsArea"))
                .onChanged { value in
                    if selectionStart == nil { selectionStart = value.startLocation }
                    if let start = selectionStart {
                        selectionRect = rect(from: start, to: value.location)
                        selectionMenuLocation = nil
                    }
                }
                .onEnded { value in
                    guard let start = selectionStart else { selectionRect = nil
                        return
                    }
                    let finalRect = rect(from: start, to: value.location)
                    let hits = assignmentFrames.compactMap { id, frame in
                        finalRect.intersects(frame) ? id : nil
                    }
                    selectedIDs = Set(hits)
                    selectionMenuLocation = hits.isEmpty ? nil : value.location
                    selectionStart = nil
                    selectionRect = nil
                }
        }

        var selectionOverlay: some View {
            GeometryReader { _ in
                ZStack(alignment: .topLeading) {
                    if let rect = selectionRect {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.accentColor.opacity(0.6), lineWidth: 1.2)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.accentQuaternary)
                            )
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                            .allowsHitTesting(false)
                    }
                    if let menuPoint = selectionMenuLocation, !selectedIDs.isEmpty {
                        selectionMenu
                            .position(menuPoint)
                            .transition(DesignSystem.Motion.scaleTransition)
                    }
                }
                .onPreferenceChange(AssignmentFramePreference.self) { frames in
                    assignmentFrames = frames
                }
            }
        }

        var selectionMenu: some View {
            HStack(spacing: 10) {
                Button(NSLocalizedString(
                    "assignments.selection.cut",
                    value: "assignments.selection.cut",
                    comment: ""
                )) {
                    cutSelection()
                }
                .disabled(selectedIDs.isEmpty)
                Button(NSLocalizedString(
                    "assignments.selection.copy",
                    value: "assignments.selection.copy",
                    comment: ""
                )) { copySelection() }
                    .disabled(selectedIDs.isEmpty)
                Button(NSLocalizedString(
                    "assignments.selection.duplicate",
                    value: "assignments.selection.duplicate",
                    comment: ""
                )) { duplicateSelection() }
                    .disabled(selectedIDs.isEmpty)
                Button(NSLocalizedString(
                    "assignments.selection.paste",
                    value: "assignments.selection.paste",
                    comment: ""
                )) { pasteClipboard() }
                    .disabled(clipboard.isEmpty)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        }

        func rect(from start: CGPoint, to end: CGPoint) -> CGRect {
            CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
        }

        func copySelection() {
            clipboard = assignments.filter { selectedIDs.contains($0.id) }
        }

        func cutSelection() {
            copySelection()
            assignments.removeAll { selectedIDs.contains($0.id) }
            selectedIDs.removeAll()
            selectionMenuLocation = nil
        }

        func duplicateSelection() {
            let toDuplicate = assignments.filter { selectedIDs.contains($0.id) }
            let copies = toDuplicate.map { item in
                Assignment(
                    id: UUID(),
                    courseId: item.courseId,
                    title: item.title + "assignments.selection.copy_suffix".localized,
                    dueDate: item.dueDate,
                    estimatedMinutes: item.estimatedMinutes,
                    weightPercent: item.weightPercent,
                    category: item.category,
                    urgency: item.urgency,
                    isLockedToDueDate: item.isLockedToDueDate,
                    plan: item.plan,
                    status: item.status,
                    courseCode: item.courseCode,
                    courseName: item.courseName,
                    notes: item.notes
                )
            }
            assignments.append(contentsOf: copies)
            selectedIDs.removeAll()
        }

        func pasteClipboard() {
            guard !clipboard.isEmpty else { return }
            let pasted = clipboard.map { item in
                Assignment(
                    id: UUID(),
                    courseId: item.courseId,
                    title: item.title,
                    dueDate: item.dueDate,
                    estimatedMinutes: item.estimatedMinutes,
                    weightPercent: item.weightPercent,
                    category: item.category,
                    urgency: item.urgency,
                    isLockedToDueDate: item.isLockedToDueDate,
                    plan: item.plan,
                    status: item.status,
                    courseCode: item.courseCode,
                    courseName: item.courseName,
                    notes: item.notes
                )
            }
            assignments.append(contentsOf: pasted)
            selectedIDs.removeAll()
        }
    }

    // MARK: - Preferences

    private struct AssignmentFramePreference: PreferenceKey {
        static var defaultValue: [UUID: CGRect] = [:]
        static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }
#endif
