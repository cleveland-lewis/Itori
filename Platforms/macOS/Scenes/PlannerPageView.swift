#if os(macOS)
    import AppKit
    import Combine
    import EventKit
    import SwiftUI
    import UniformTypeIdentifiers

    // MARK: - Models

    enum PlannerBlockStatus {
        case upcoming
        case inProgress
        case completed
        case overdue
    }

    struct PlannedBlock: Identifiable {
        let id: UUID
        var taskId: UUID?
        var courseId: UUID?
        var title: String
        var course: String?
        var start: Date
        var end: Date
        var isLocked: Bool
        var status: PlannerBlockStatus
        var source: String
        var isOmodoroLinked: Bool
        var isAutoRescheduled: Bool = false // NEW: Track auto-reschedule status
        var rescheduleStrategy: String? // NEW: Track strategy used
    }

    struct PlannerTask: Identifiable {
        let id: UUID
        var courseId: UUID?
        var assignmentId: UUID?
        var title: String
        var course: String?
        var dueDate: Date
        var estimatedMinutes: Int
        var isLockedToDueDate: Bool
        var isScheduled: Bool
        var isCompleted: Bool
        var importance: Double? // 0...1
        var difficulty: Double? // 0...1
        var category: AssignmentCategory?
    }

    // New task drafting types
    struct PlannerTaskDraft {
        var id: UUID?
        var title: String
        var courseId: UUID?
        var courseCode: String?
        var assignmentID: UUID?
        var dueDate: Date
        var estimatedMinutes: Int
        var lockToDueDate: Bool
        var priority: PlannerTaskPriority
        var recurrenceEnabled: Bool
        var recurrenceFrequency: RecurrenceRule.Frequency
        var recurrenceInterval: Int
        var recurrenceEndOption: RecurrenceEndOption
        var recurrenceEndDate: Date
        var recurrenceEndCount: Int
        var skipWeekends: Bool
        var skipHolidays: Bool
        var holidaySource: RecurrenceRule.HolidaySource
    }

    enum RecurrenceEndOption: String, CaseIterable, Identifiable {
        case never
        case onDate
        case afterOccurrences

        var id: String { rawValue }
    }

    enum RecurrenceSelection: String, CaseIterable, Identifiable {
        case none
        case daily
        case weekly
        case monthly
        case yearly

        var id: String { rawValue }

        var label: String {
            switch self {
            case .none: NSLocalizedString("planner.recurrence.type.none", comment: "")
            case .daily: NSLocalizedString("planner.recurrence.type.daily", comment: "")
            case .weekly: NSLocalizedString("planner.recurrence.type.weekly", comment: "")
            case .monthly: NSLocalizedString("planner.recurrence.type.monthly", comment: "")
            case .yearly: NSLocalizedString("planner.recurrence.type.yearly", comment: "")
            }
        }

        var frequency: RecurrenceRule.Frequency {
            switch self {
            case .none: .weekly
            case .daily: .daily
            case .weekly: .weekly
            case .monthly: .monthly
            case .yearly: .yearly
            }
        }
    }

    // Overdue task row view
    struct OverdueTaskRow: View {
        var item: PlannerTask
        var onTap: () -> Void
        var onComplete: () -> Void

        @ScaledMetric private var emptyIconSize: CGFloat = 48

        @ScaledMetric private var normalTextSize: CGFloat = 18

        @Environment(\.colorScheme) private var colorScheme
        private var neutralLine: Color { DesignSystem.Colors.neutralLine(for: colorScheme) }

        private var daysLate: Int {
            let now = Date()
            let days = Calendar.current.dateComponents([.day], from: item.dueDate, to: now).day ?? 0
            return max(0, days)
        }

        private var pillColor: Color {
            switch daysLate {
            case 0 ... 1: .yellow
            case 2 ... 7: .orange
            default: .red
            }
        }

        private var pillText: String {
            switch daysLate {
            case 0: NSLocalizedString("planner.overdue.today", comment: "")
            case 1: NSLocalizedString("planner.overdue.one_day", comment: "")
            default: String(format: NSLocalizedString("planner.overdue.days", comment: ""), daysLate)
            }
        }

        private func dueText(from date: Date) -> String {
            let now = Date()
            let days = Calendar.current.dateComponents([.day], from: date, to: now).day ?? 0
            if days == 0 { return NSLocalizedString("planner.due.today", comment: "") }
            if days == 1 { return NSLocalizedString("planner.due.one_day_ago", comment: "") }
            return String(format: NSLocalizedString("planner.due.days_ago", comment: ""), days)
        }

        var body: some View {
            Button {
                onTap()
            } label: {
                HStack(spacing: DesignSystem.Layout.spacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(DesignSystem.Typography.body)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            if let course = item.course { Text(course) }
                            Text(NSLocalizedString("·", value: "·", comment: ""))
                            Text(dueText(from: item.dueDate))
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }

                    Spacer()

                    Text(pillText)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(pillColor.opacity(0.18)))

                    Button {
                        onComplete()
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(DesignSystem.Typography.body)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DesignSystem.Materials.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(neutralLine.opacity(0.22), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabelWithTooltip("Overdue, due \(item.dueDate)")
        }
    }

    enum PlannerTaskPriority: String, CaseIterable, Identifiable {
        case low, normal, high, critical
        var id: String { rawValue }
    }

    /// Tracks day progress (time remaining / elapsed) for header metrics or future use.
    final class DayProgressModel: ObservableObject {
        @Published var elapsedFraction: Double = 0.0
        @Published var remainingMinutes: Int = 0

        private var timer: Timer?

        func startUpdating(clock: Calendar = .current) {
            timer?.invalidate()
            update(clock: clock)
            // schedule to fire on next minute boundary to align nicely
            let nextInterval = 60.0 - Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + nextInterval) { [weak self] in
                self?.timer?.invalidate()
                self?.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                    self?.update(clock: clock)
                }
            }
        }

        func stopUpdating() {
            timer?.invalidate()
            timer = nil
        }

        private func update(clock: Calendar) {
            let now = Date()
            let startOfDay = clock.startOfDay(for: now)
            guard let endOfDay = clock.date(byAdding: .day, value: 1, to: startOfDay) else { return }

            let totalSeconds = endOfDay.timeIntervalSince(startOfDay)
            let elapsedSeconds = now.timeIntervalSince(startOfDay)
            let clampedElapsed = max(0, min(elapsedSeconds, totalSeconds))

            elapsedFraction = totalSeconds > 0 ? clampedElapsed / totalSeconds : 0
            let remaining = max(0, Int((totalSeconds - clampedElapsed) / 60))
            remainingMinutes = remaining
        }
    }

    struct CourseSummary: Identifiable, Hashable {
        let id: UUID
        var code: String
        var title: String
    }

    // MARK: - Root Planner Page

    // Minimal PlannerSettings used locally
    struct PlannerSettings {
        var isOmodoroLinkedForToday: Bool = false
    }

    struct PlannerPageView: View {
        @EnvironmentObject var settings: AppSettings
        @EnvironmentObject var plannerStore: PlannerStore
        @EnvironmentObject var assignmentsStore: AssignmentsStore
        @EnvironmentObject var plannerCoordinator: PlannerCoordinator
        @EnvironmentObject var coursesStore: CoursesStore
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.appLayout) private var appLayout
        @StateObject private var dayProgress = DayProgressModel()

        @State private var selectedDate: Date = .init()
        @State private var isRunningPlanner: Bool = false
        @State private var showTaskSheet: Bool = false
        @State private var editingTask: PlannerTask? = nil

        // new sheet state
        @State private var editingTaskDraft: PlannerTaskDraft? = nil

        // local simplified planner settings used during build
        @State private var plannerSettings = PlannerSettings()
        @State private var focusPulse = false
        @State private var dropTargetHour: Int? = nil
        @State private var rowHeights: [Int: CGFloat] = [:]
        @State private var dropTargetMinuteOffset: [Int: Int] = [:]

        private let cardCornerRadius: CGFloat = 26
        private let studySettings = StudyPlanSettings()
        private var neutralLine: Color { DesignSystem.Colors.neutralLine(for: colorScheme) }

        private var plannerLoading: Bool {
            plannerStore.isLoading || isRunningPlanner
        }

        private var hasStoredSessionsForSelectedDay: Bool {
            plannerStore.scheduled.contains { Calendar.current.isDate($0.start, inSameDayAs: selectedDate) }
        }

        private var plannedBlocks: [PlannedBlock] {
            let calendar = Calendar.current
            let tasksById = Dictionary(uniqueKeysWithValues: assignmentsStore.tasks.map { ($0.id, $0) })
            let coursesById = Dictionary(uniqueKeysWithValues: coursesStore.courses.map { ($0.id, $0) })
            let filterId = plannerCoordinator.selectedCourseFilter
            return plannerStore.scheduled.compactMap { stored in
                guard calendar.isDate(stored.start, inSameDayAs: selectedDate) else { return nil }
                let task = stored.assignmentId.flatMap { tasksById[$0] }
                if let filterId, let courseId = task?.courseId, courseId != filterId {
                    return nil
                } else if filterId != nil && task?.courseId == nil {
                    return nil
                }
                let isCompleted = task?.isCompleted ?? false
                if isCompleted {
                    return nil
                }
                let courseCode = task?.courseId.flatMap { coursesById[$0]?.code }

                // Check if this session was auto-rescheduled
                let isAutoRescheduled = stored.aiProvenance?.contains("auto-reschedule") ?? false
                let rescheduleStrategy = stored.aiProvenance?.replacingOccurrences(of: "auto-reschedule-", with: "")

                return PlannedBlock(
                    id: stored.id,
                    taskId: stored.assignmentId,
                    courseId: task?.courseId,
                    title: stored.title,
                    course: courseCode,
                    start: stored.start,
                    end: stored.end,
                    isLocked: stored.isLocked,
                    status: isCompleted ? .completed : .upcoming,
                    source: stored
                        .isUserEdited ? NSLocalizedString("planner.session.source.adjusted", comment: "") :
                        NSLocalizedString(
                            "planner.session.source.auto_plan",
                            comment: ""
                        ),
                    isOmodoroLinked: false,
                    isAutoRescheduled: isAutoRescheduled,
                    rescheduleStrategy: isAutoRescheduled ? rescheduleStrategy : nil
                )
            }
        }

        private var unscheduledTasks: [PlannerTask] {
            let tasksById = Dictionary(uniqueKeysWithValues: assignmentsStore.tasks.map { ($0.id, $0) })
            let coursesById = Dictionary(uniqueKeysWithValues: coursesStore.courses.map { ($0.id, $0) })
            let filterId = plannerCoordinator.selectedCourseFilter
            return plannerStore.overflow.map { stored in
                let task = stored.assignmentId.flatMap { tasksById[$0] }
                if let filterId, let courseId = task?.courseId, courseId != filterId {
                    return nil
                } else if filterId != nil && task?.courseId == nil {
                    return nil
                }
                let isCompleted = task?.isCompleted ?? false
                if isCompleted {
                    return nil
                }
                let courseCode = task?.courseId.flatMap { coursesById[$0]?.code }
                return PlannerTask(
                    id: stored.id,
                    courseId: task?.courseId,
                    assignmentId: stored.assignmentId,
                    title: stored.title,
                    course: courseCode,
                    dueDate: stored.dueDate,
                    estimatedMinutes: stored.estimatedMinutes,
                    isLockedToDueDate: stored.isLockedToDueDate,
                    isScheduled: false,
                    isCompleted: isCompleted,
                    importance: stored.category == .exam ? 0.8 : 0.5,
                    difficulty: stored.category == .project ? 0.7 : 0.5,
                    category: stored.category
                )
            }
            .compactMap { $0 }
        }

        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Color.primaryBackground.ignoresSafeArea()

                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                headerBar

                                HStack(alignment: .top, spacing: 18) {
                                    timelineCard
                                        .id(PlannerScrollTarget.timeline)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)
                                        .layoutPriority(1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                                                .stroke(Color.accentColor.opacity(focusPulse ? 0.4 : 0), lineWidth: 2)
                                        )
                                        .animation(.easeInOut(duration: 0.35), value: focusPulse)

                                    rightColumn
                                        .frame(minWidth: 280, idealWidth: 320, maxWidth: 360, alignment: .top)
                                }
                            }
                            .frame(maxWidth: min(geometry.size.width, 1400))
                            .frame(maxWidth: .infinity)
                            .padding(.top, appLayout.topContentInset)
                            .padding(.horizontal, responsivePadding(for: geometry.size.width))
                            .padding(.bottom, DesignSystem.Layout.spacing.large)
                        }
                        .onReceive(plannerCoordinator.$requestedDate) { date in
                            guard let date else { return }
                            selectedDate = date
                            withAnimation(DesignSystem.Motion.fluidSpring) {
                                proxy.scrollTo(PlannerScrollTarget.timeline, anchor: .top)
                            }
                            focusPulse = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                focusPulse = false
                            }
                            plannerCoordinator.requestedDate = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showTaskSheet) {
                if let draft = editingTaskDraft {
                    NewTaskSheet(
                        draft: draft,
                        isNew: draft.id == nil,
                        availableCourses: coursesStore.courses.map { course in
                            CourseSummary(id: course.id, code: course.code, title: course.title)
                        }
                    ) { updated in
                        applyDraft(updated)
                    }
                }
            }
            .onAppear {
                dayProgress.startUpdating()
            }
            .onDisappear {
                dayProgress.stopUpdating()
            }
        }

        private enum PlannerScrollTarget: Hashable {
            case timeline
        }
    }

    // MARK: - Header

    private extension PlannerPageView {
        var headerBar: some View {
            HStack(alignment: .center, spacing: 16) {
                HStack(spacing: DesignSystem.Layout.spacing.small) {
                    Button {
                        withAnimation(DesignSystem.Motion.standardSpring) { adjustDate(by: -1) }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(DesignSystem.Typography.body)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Self.dayFormatter.string(from: selectedDate))
                            .font(DesignSystem.Typography.body)
                        Text(subtitleText)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        withAnimation(DesignSystem.Motion.standardSpring) { adjustDate(by: 1) }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(DesignSystem.Typography.body)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                HStack(spacing: DesignSystem.Layout.spacing.small) {
                    Button {
                        showNewTaskSheet()
                    } label: {
                        Label(NSLocalizedString("planner.action.new_task", comment: ""), systemImage: "plus")
                            .font(DesignSystem.Typography.body)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(height: 38)
                            .background(.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        runAIScheduler()
                    } label: {
                        Label(
                            isRunningPlanner ? NSLocalizedString("planner.action.planning", comment: "") :
                                NSLocalizedString(
                                    "planner.action.plan_day",
                                    comment: ""
                                ),
                            systemImage: "calendar.badge.clock"
                        )
                        .font(DesignSystem.Typography.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .controlSize(.regular)
                    .disabled(isRunningPlanner)
                    .opacity(isRunningPlanner ? 0.85 : 1)
                }
            }
        }

        var subtitleText: String {
            ""
        }

        func adjustDate(by offset: Int) {
            let component: Calendar.Component = .day
            if let newDate = Calendar.current.date(byAdding: component, value: offset, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }

    // MARK: - Timeline Card

    private extension PlannerPageView {
        var timelineCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(NSLocalizedString("planner.timeline.title", comment: ""))
                        .font(DesignSystem.Typography.subHeader)
                    if !unscheduledTasks.isEmpty {
                        Text(
                            "• \(unscheduledTasks.count) \(NSLocalizedString("planner.timeline.overflow", comment: ""))"
                        )
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.secondaryBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(neutralLine.opacity(0.2), lineWidth: 1)
                        )
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    if plannerLoading {
                        plannerLoadingState
                    } else if plannedBlocks.isEmpty && !hasStoredSessionsForSelectedDay {
                        plannerEmptyState
                    } else {
                        ForEach(9 ... 21, id: \.self) { hour in
                            timelineRow(for: hour)
                        }
                    }
                }
            }
            .padding(18)
            .itoriCardBackground(radius: cardCornerRadius)
        }

        func timelineRow(for hour: Int) -> some View {
            let calendar = Calendar.current
            let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourDate) ?? hourDate
            let blocks = plannedBlocks.filter { $0.start < hourEnd && $0.end > hourDate }

            return HStack(alignment: .top, spacing: 12) {
                Text(Self.hourFormatter.string(from: hourDate))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 52, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    if blocks.isEmpty {
                        RoundedRectangle(cornerRadius: DesignSystem.Corners.block, style: .continuous)
                            .stroke(neutralLine.opacity(0.8), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.Corners.block, style: .continuous)
                                    .fill(.secondaryBackground.opacity(0.7))
                            )
                            .frame(height: 34)
                            .overlay(
                                HStack {
                                    Text(NSLocalizedString("planner.timeline.free", comment: "")).font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                            )
                    } else {
                        ForEach(blocks) { block in
                            if block.isLocked {
                                PlannerBlockRow(block: block, onStatusChange: updateBlockStatus)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Corners.block, style: .continuous)
                                            .stroke(neutralLine.opacity(0.25), lineWidth: 1)
                                    )
                            } else {
                                PlannerBlockRow(block: block, onStatusChange: updateBlockStatus)
                                    .onDrag {
                                        NSItemProvider(object: block.id.uuidString as NSString)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Corners.block, style: .continuous)
                                            .stroke(neutralLine.opacity(0.25), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .onDrop(of: [UTType.text], delegate: PlannerBlockDropDelegate(
                hourDate: hourDate,
                hour: hour,
                dropTargetHour: $dropTargetHour,
                dropTargetMinuteOffset: $dropTargetMinuteOffset,
                rowHeight: rowHeights[hour] ?? 60
            ) { blockId, targetHour, minuteOffset in
                moveBlock(id: blockId, to: targetHour, minuteOffset: minuteOffset)
            })
            .overlay(alignment: .top) {
                GeometryReader { proxy in
                    if dropTargetHour == hour {
                        let rowHeight = max(1, proxy.size.height)
                        let minuteOffset = dropTargetMinuteOffset[hour] ?? 0
                        let y = (CGFloat(minuteOffset) / 60.0) * rowHeight
                        let label = previewTimeLabel(hourDate: hourDate, minuteOffset: minuteOffset)
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(height: 2)
                            .offset(y: y)
                        Text(label)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Color.accentColor)
                            )
                            .offset(y: max(0, y - 12))
                    }
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { rowHeights[hour] = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, newValue in rowHeights[hour] = newValue }
                }
            )
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

        private var plannerLoadingState: some View {
            HStack(spacing: 8) {
                ProgressView()
                Text(NSLocalizedString("planner.message.loading", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        }

        private var plannerEmptyState: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("planner.empty.no_sessions", comment: ""))
                    .font(.subheadline.weight(.semibold))
                Text(NSLocalizedString("planner.message.run_plan_day", comment: ""))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Right Column

    private extension PlannerPageView {
        var rightColumn: some View {
            VStack(alignment: .leading, spacing: 16) {
                unscheduledTasksCard
                overdueTasksCard
            }
        }

        var unscheduledTasksCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(NSLocalizedString("planner.unscheduled.title", comment: ""))
                        .font(DesignSystem.Typography.body)
                    Spacer()
                    if !unscheduledTasks.isEmpty {
                        Text(verbatim: "\(unscheduledTasks.count)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.secondaryBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(neutralLine.opacity(0.2), lineWidth: 1)
                            )
                    }
                    Button {
                        showNewTaskSheet()
                    } label: {
                        Image(systemName: "plus")
                            .font(DesignSystem.Typography.body)
                            .padding(DesignSystem.Layout.spacing.small)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: DesignSystem.Layout.cornerRadiusStandard,
                                    style: .continuous
                                )
                                .fill(.secondaryBackground)
                            )
                            .overlay(
                                RoundedRectangle(
                                    cornerRadius: DesignSystem.Layout.cornerRadiusStandard,
                                    style: .continuous
                                )
                                .stroke(neutralLine.opacity(0.22), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                if plannerLoading {
                    plannerLoadingState
                        .padding(.vertical, 4)
                } else if unscheduledTasks.isEmpty && plannerStore.overflow.isEmpty {
                    Text(NSLocalizedString("planner.unscheduled.empty", comment: ""))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Layout.spacing.small) {
                            ForEach(unscheduledTasks) { task in
                                PlannerTaskRow(task: task) {
                                    editingTask = task
                                    let recurrenceDefaults = recurrenceDefaults(from: recurrenceForTask(task.id))
                                    editingTaskDraft = PlannerTaskDraft(
                                        id: task.id,
                                        title: task.title,
                                        courseId: task.courseId,
                                        courseCode: task.course,
                                        assignmentID: nil,
                                        dueDate: task.dueDate,
                                        estimatedMinutes: task.estimatedMinutes,
                                        lockToDueDate: task.isLockedToDueDate,
                                        priority: .normal,
                                        recurrenceEnabled: recurrenceDefaults.enabled,
                                        recurrenceFrequency: recurrenceDefaults.frequency,
                                        recurrenceInterval: recurrenceDefaults.interval,
                                        recurrenceEndOption: recurrenceDefaults.endOption,
                                        recurrenceEndDate: recurrenceDefaults.endDate,
                                        recurrenceEndCount: recurrenceDefaults.endCount,
                                        skipWeekends: recurrenceDefaults.skipWeekends,
                                        skipHolidays: recurrenceDefaults.skipHolidays,
                                        holidaySource: recurrenceDefaults.holidaySource
                                    )
                                    showTaskSheet = true
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(DesignSystem.Layout.padding.card)
            .itoriCardBackground(radius: cardCornerRadius)
        }

        var overdueTasksCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(NSLocalizedString("planner.overdue.title", comment: ""))
                        .font(DesignSystem.Typography.body)
                    Spacer()
                    if !overdueTasks.isEmpty {
                        Text(verbatim: "● \(overdueTasks.count)")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.accentColor.opacity(0.18)))
                    }
                }

                if overdueTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("planner.overdue.caught_up", comment: ""))
                            .font(.subheadline.weight(.semibold))
                        Text(NSLocalizedString("planner.overdue.caught_up_description", comment: ""))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                } else {
                    let items = overdueTasks
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Layout.spacing.small) {
                            ForEach(items.prefix(10)) { item in
                                OverdueTaskRow(
                                    item: item,
                                    onTap: {
                                        if item.isScheduled {
                                            plannerCoordinator.openPlanner(
                                                for: selectedDate,
                                                courseId: item.courseId
                                            )
                                        } else {
                                            let recurrenceDefaults =
                                                recurrenceDefaults(from: recurrenceForTask(item.id))
                                            editingTaskDraft = PlannerTaskDraft(
                                                id: item.id,
                                                title: item.title,
                                                courseId: item.courseId,
                                                courseCode: item.course,
                                                assignmentID: nil,
                                                dueDate: item.dueDate,
                                                estimatedMinutes: 60,
                                                lockToDueDate: false,
                                                priority: .normal,
                                                recurrenceEnabled: recurrenceDefaults.enabled,
                                                recurrenceFrequency: recurrenceDefaults.frequency,
                                                recurrenceInterval: recurrenceDefaults.interval,
                                                recurrenceEndOption: recurrenceDefaults.endOption,
                                                recurrenceEndDate: recurrenceDefaults.endDate,
                                                recurrenceEndCount: recurrenceDefaults.endCount,
                                                skipWeekends: recurrenceDefaults.skipWeekends,
                                                skipHolidays: recurrenceDefaults.skipHolidays,
                                                holidaySource: recurrenceDefaults.holidaySource
                                            )
                                            showTaskSheet = true
                                        }
                                    },
                                    onComplete: {
                                        withAnimation(DesignSystem.Motion.fluidSpring) {
                                            markCompleted(item)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 320)
                }
            }
            .padding(DesignSystem.Layout.padding.card)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .stroke(neutralLine.opacity(0.22), lineWidth: 1)
            )
        }

        var overdueTasks: [PlannerTask] {
            let now = Date()
            return (unscheduledTasks + plannedTasksFromBlocks()).filter {
                !$0.isCompleted && ($0.dueDate) < now
            }
            .sorted { $0.dueDate < $1.dueDate }
        }

        private func plannedTasksFromBlocks() -> [PlannerTask] {
            plannedBlocks.compactMap { block in
                PlannerTask(
                    id: block.id,
                    courseId: block.courseId,
                    assignmentId: block.taskId,
                    title: block.title,
                    course: block.course,
                    dueDate: block.end,
                    estimatedMinutes: Int(block.end.timeIntervalSince(block.start) / 60),
                    isLockedToDueDate: block.isLocked,
                    isScheduled: true,
                    isCompleted: block.status == .completed
                )
            }
        }
    }

    // MARK: - Actions & Helpers

    private extension PlannerPageView {
        func applyDraft(_ draft: PlannerTaskDraft) {
            let taskId = draft.assignmentID ?? draft.id ?? UUID()
            if let idx = assignmentsStore.tasks.firstIndex(where: { $0.id == taskId }) {
                let existing = assignmentsStore.tasks[idx]
                let recurrenceRule = buildRecurrenceRule(from: draft)
                let updated = AppTask(
                    id: existing.id,
                    title: draft.title,
                    courseId: draft.courseId,
                    due: draft.dueDate,
                    estimatedMinutes: draft.estimatedMinutes,
                    minBlockMinutes: min(existing.minBlockMinutes, draft.estimatedMinutes),
                    maxBlockMinutes: max(existing.maxBlockMinutes, draft.estimatedMinutes),
                    difficulty: existing.difficulty,
                    importance: existing.importance,
                    type: existing.type,
                    locked: draft.lockToDueDate,
                    attachments: existing.attachments,
                    isCompleted: existing.isCompleted,
                    gradeWeightPercent: existing.gradeWeightPercent,
                    gradePossiblePoints: existing.gradePossiblePoints,
                    gradeEarnedPoints: existing.gradeEarnedPoints,
                    category: existing.category,
                    dueTimeMinutes: existing.dueTimeMinutes,
                    recurrence: recurrenceRule
                )
                assignmentsStore.updateTask(updated)
            } else {
                let recurrenceRule = buildRecurrenceRule(from: draft)
                let newTask = AppTask(
                    id: taskId,
                    title: draft.title,
                    courseId: draft.courseId,
                    due: draft.dueDate,
                    estimatedMinutes: draft.estimatedMinutes,
                    minBlockMinutes: 15,
                    maxBlockMinutes: max(30, draft.estimatedMinutes),
                    difficulty: 0.5,
                    importance: 0.5,
                    type: .homework,
                    locked: draft.lockToDueDate,
                    recurrence: recurrenceRule
                )
                assignmentsStore.addTask(newTask)
            }
        }

        func markCompleted(_ item: PlannerTask) {
            // Mark completed in the underlying AssignmentsStore
            if let assignmentId = item.assignmentId {
                if let taskIndex = assignmentsStore.tasks.firstIndex(where: { $0.id == assignmentId }) {
                    var updatedTask = assignmentsStore.tasks[taskIndex]
                    updatedTask.isCompleted = true
                    assignmentsStore.updateTask(updatedTask)
                }
            }
            Task { @MainActor in
                Feedback.shared.play(.taskCompleted)
            }
        }

        func showNewTaskSheet() {
            editingTaskDraft = PlannerTaskDraft(
                id: nil,
                title: "",
                courseId: nil,
                courseCode: nil,
                assignmentID: nil,
                dueDate: Date(),
                estimatedMinutes: 60,
                lockToDueDate: false,
                priority: .normal,
                recurrenceEnabled: false,
                recurrenceFrequency: .weekly,
                recurrenceInterval: 1,
                recurrenceEndOption: .never,
                recurrenceEndDate: Date(),
                recurrenceEndCount: 3,
                skipWeekends: false,
                skipHolidays: false,
                holidaySource: .deviceCalendar
            )
            showTaskSheet = true
        }

        func recurrenceForTask(_ id: UUID) -> RecurrenceRule? {
            assignmentsStore.tasks.first(where: { $0.id == id })?.recurrence
        }

        func recurrenceDefaults(from rule: RecurrenceRule?)
            -> (
                enabled: Bool,
                frequency: RecurrenceRule.Frequency,
                interval: Int,
                endOption: RecurrenceEndOption,
                endDate: Date,
                endCount: Int,
                skipWeekends: Bool,
                skipHolidays: Bool,
                holidaySource: RecurrenceRule.HolidaySource
            )
        {
            guard let rule else {
                return (false, .weekly, 1, .never, Date(), 3, false, false, .deviceCalendar)
            }
            let endOption: RecurrenceEndOption
            let endDate: Date
            let endCount: Int
            switch rule.end {
            case .never:
                endOption = .never
                endDate = Date()
                endCount = 3
            case let .until(date):
                endOption = .onDate
                endDate = date
                endCount = 3
            case let .afterOccurrences(count):
                endOption = .afterOccurrences
                endDate = Date()
                endCount = max(1, count)
            }
            return (
                true,
                rule.frequency,
                max(1, rule.interval),
                endOption,
                endDate,
                endCount,
                rule.skipPolicy.skipWeekends,
                rule.skipPolicy.skipHolidays,
                rule.skipPolicy.holidaySource
            )
        }

        func buildRecurrenceRule(from draft: PlannerTaskDraft) -> RecurrenceRule? {
            guard draft.recurrenceEnabled else { return nil }
            let end: RecurrenceRule.End = switch draft.recurrenceEndOption {
            case .never:
                .never
            case .onDate:
                .until(draft.recurrenceEndDate)
            case .afterOccurrences:
                .afterOccurrences(max(1, draft.recurrenceEndCount))
            }
            let skipPolicy = RecurrenceRule.SkipPolicy(
                skipWeekends: draft.skipWeekends,
                skipHolidays: draft.skipHolidays,
                holidaySource: draft.holidaySource,
                adjustment: .forward
            )
            return RecurrenceRule(
                frequency: draft.recurrenceFrequency,
                interval: max(1, draft.recurrenceInterval),
                end: end,
                skipPolicy: skipPolicy
            )
        }

        func runAIScheduler() {
            guard !isRunningPlanner else { return }
            isRunningPlanner = true
            PlannerSyncCoordinator.shared.requestRecompute(
                assignmentsStore: assignmentsStore,
                plannerStore: plannerStore,
                settings: settings
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isRunningPlanner = false
            }
        }
    }

    // MARK: - Formatters

    private extension PlannerPageView {
        static let dayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter
        }()

        static let hourFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "h a"
            return formatter
        }()

        static func samplePlannedBlocks(for _: Date) -> [PlannedBlock] {
            []
        }

        static func sampleUnscheduledTasks(for _: Date) -> [PlannerTask] {
            []
        }

        static var sampleCourses: [CourseSummary] {
            []
        }

        private func previewTimeLabel(hourDate: Date, minuteOffset: Int) -> String {
            let calendar = Calendar.current
            let clampedMinutes = min(59, max(0, minuteOffset))
            let date = calendar.date(
                bySettingHour: calendar.component(.hour, from: hourDate),
                minute: clampedMinutes,
                second: 0,
                of: hourDate
            ) ?? hourDate
            return settings.formattedTime(date)
        }
    }

    private extension PlannerPageView {
        func moveBlock(id: UUID, to hourDate: Date, minuteOffset: Int) {
            guard let stored = plannerStore.scheduled.first(where: { $0.id == id }) else { return }
            guard !stored.isLocked else { return }
            let duration = stored.end.timeIntervalSince(stored.start)
            let calendar = Calendar.current
            let snappedMinutes = min(45, max(0, (minuteOffset / 15) * 15))
            var newStart = calendar.date(
                bySettingHour: calendar.component(.hour, from: hourDate),
                minute: snappedMinutes % 60,
                second: 0,
                of: hourDate
            ) ?? hourDate
            if snappedMinutes >= 60 {
                newStart = calendar.date(byAdding: .hour, value: 1, to: newStart) ?? newStart
            }
            let newEnd = newStart.addingTimeInterval(duration)

            let updated = StoredScheduledSession(
                id: stored.id,
                assignmentId: stored.assignmentId,
                sessionIndex: stored.sessionIndex,
                sessionCount: stored.sessionCount,
                title: stored.title,
                dueDate: stored.dueDate,
                estimatedMinutes: stored.estimatedMinutes,
                isLockedToDueDate: stored.isLockedToDueDate,
                category: stored.category,
                start: newStart,
                end: newEnd,
                type: stored.type,
                isLocked: stored.isLocked,
                isUserEdited: true,
                userEditedAt: Date(),
                aiInputHash: stored.aiInputHash,
                aiComputedAt: stored.aiComputedAt,
                aiConfidence: stored.aiConfidence,
                aiProvenance: stored.aiProvenance
            )
            plannerStore.updateScheduledSession(updated)
        }

        func updateBlockStatus(id: UUID, newStatus: PlannerBlockStatus) {
            guard let stored = plannerStore.scheduled.first(where: { $0.id == id }) else { return }

            // If there's an associated task, update its completion status
            if let taskId = stored.assignmentId {
                if let task = assignmentsStore.tasks.first(where: { $0.id == taskId }) {
                    var updatedTask = task
                    updatedTask.isCompleted = (newStatus == .completed)
                    assignmentsStore.updateTask(updatedTask)
                }
            }

            // Note: The block status in the UI will update automatically when
            // the planner refreshes based on the task's completion status
        }
    }

    private struct PlannerBlockDropDelegate: DropDelegate {
        let hourDate: Date
        let hour: Int
        @Binding var dropTargetHour: Int?
        @Binding var dropTargetMinuteOffset: [Int: Int]
        let rowHeight: CGFloat
        let onDrop: (UUID, Date, Int) -> Void

        func validateDrop(info: DropInfo) -> Bool {
            dropTargetHour = hour
            dropTargetMinuteOffset[hour] = snappedMinute(from: info.location.y)
            return true
        }

        func dropEntered(info: DropInfo) {
            dropTargetHour = hour
            dropTargetMinuteOffset[hour] = snappedMinute(from: info.location.y)
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            dropTargetMinuteOffset[hour] = snappedMinute(from: info.location.y)
            return DropProposal(operation: .move)
        }

        func dropExited(info _: DropInfo) {
            if dropTargetHour == hour {
                dropTargetHour = nil
                dropTargetMinuteOffset[hour] = nil
            }
        }

        func performDrop(info: DropInfo) -> Bool {
            dropTargetHour = nil
            dropTargetMinuteOffset[hour] = nil
            guard let provider = info.itemProviders(for: [UTType.text]).first else { return false }
            let snapped = snappedMinute(from: info.location.y)
            provider.loadObject(ofClass: NSString.self) { object, _ in
                guard let nsString = object as? NSString,
                      let blockId = UUID(uuidString: nsString as String) else { return }
                DispatchQueue.main.async {
                    onDrop(blockId, hourDate, snapped)
                }
            }
            return true
        }

        private func snappedMinute(from y: CGFloat) -> Int {
            let clampedHeight = max(1, rowHeight)
            let rawMinutes = Int((y / clampedHeight) * 60.0)
            return Int((Double(rawMinutes) / 15.0).rounded()) * 15
        }
    }

    // MARK: - Block Row

    struct PlannerBlockRow: View {
        var block: PlannedBlock
        var onStatusChange: ((UUID, PlannerBlockStatus) -> Void)?

        @Environment(\.colorScheme) private var colorScheme
        private var neutralLine: Color { DesignSystem.Colors.neutralLine(for: colorScheme) }

        private var isFixedEvent: Bool {
            let lower = block.source.lowercased()
            return lower.contains("class") || lower.contains("calendar") || lower.contains("event")
        }

        private var accentBarColor: Color {
            if isFixedEvent { return .blue.opacity(0.8) }
            switch block.status {
            case .upcoming: return .accentColor
            case .inProgress: return .yellow
            case .completed: return .green
            case .overdue: return .red
            }
        }

        private var statusColor: Color {
            switch block.status {
            case .upcoming: .accentColor
            case .inProgress: .yellow
            case .completed: .green
            case .overdue: .red
            }
        }

        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(accentBarColor)
                    .frame(width: 4, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(block.title)
                            .font(.body.weight(.semibold))
                            .lineLimit(1)

                        // NEW: Reschedule indicator
                        if block.isAutoRescheduled {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.orange)
                                .help("Auto-rescheduled: \(block.rescheduleStrategy ?? "moved")")
                        }
                    }

                    Text(metadataText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Checkbox for non-fixed events
                if !block.isLocked && !isFixedEvent {
                    Button {
                        let newStatus: PlannerBlockStatus = block.status == .completed ? .upcoming : .completed
                        onStatusChange?(block.id, newStatus)
                    } label: {
                        Image(systemName: block.status == .completed ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: normalTextSize))
                            .foregroundStyle(block.status == .completed ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(block.status == .completed ? "Mark as not started" : "Mark as completed")
                    .accessibilityLabel(block.status == .completed ? "Mark as not started" : "Mark as completed")
                }

                if block.isLocked {
                    Image(systemName: "lock.fill")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Locked session")
                }
            }
            .padding(.horizontal, 12)
            .frame(height: DesignSystem.Layout.rowHeight.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Corners.block, style: .continuous)
                    .fill(.secondaryBackground.opacity(isFixedEvent ? 0.95 : 0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Corners.block, style: .continuous)
                    .stroke(neutralLine.opacity(0.25), lineWidth: 1)
            )
        }

        private var metadataText: String {
            let courseText = block.course ?? NSLocalizedString("planner.course.default", comment: "")
            return "\(courseText) · \(block.source)"
        }
    }

    // MARK: - Task Row

    struct PlannerTaskRow: View {
        var task: PlannerTask
        var onTap: (() -> Void)?

        @Environment(\.colorScheme) private var colorScheme
        private var neutralLine: Color { DesignSystem.Colors.neutralLine(for: colorScheme) }

        var body: some View {
            Button {
                onTap?()
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(neutralLine.opacity(0.22), lineWidth: 1)
                        .frame(width: 20, height: 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(DesignSystem.Typography.body)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(task.course ?? NSLocalizedString("planner.course.default", comment: ""))
                            Text(
                                "· ~\(task.estimatedMinutes) \(NSLocalizedString("planner.task.minutes_short", comment: ""))"
                            )
                            Text(
                                "· \(NSLocalizedString("planner.task.due", comment: "")) \(PlannerTaskRow.dateFormatter.string(from: task.dueDate))"
                            )
                            if task.isLockedToDueDate {
                                Image(systemName: "lock.fill")
                            }
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(neutralLine.opacity(0.22), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }

        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            return formatter
        }()
    }

    // MARK: - New Task Sheet (redesigned)

    struct NewTaskSheet: View {
        @Environment(\.dismiss) private var dismiss

        @State var draft: PlannerTaskDraft
        let isNew: Bool
        let availableCourses: [CourseSummary]
        var onSave: (PlannerTaskDraft) -> Void

        private var isSaveDisabled: Bool {
            draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        private var courseSelection: Binding<UUID?> {
            Binding(get: {
                draft.courseId
            }, set: { newValue in
                draft.courseId = newValue
                if let id = newValue, let match = availableCourses.first(where: { $0.id == id }) {
                    draft.courseCode = match.code
                } else {
                    draft.courseCode = nil
                }
            })
        }

        var body: some View {
            ItoriPopupContainer(
                title: isNew ? NSLocalizedString("planner.task_sheet.new_title", comment: "") : NSLocalizedString(
                    "planner.task_sheet.edit_title",
                    comment: ""
                ),
                subtitle: NSLocalizedString("planner.task_sheet.subtitle", comment: "")
            ) {
                VStack(alignment: .leading, spacing: ItariSpacing.l) {
                    taskSection
                    courseSection
                    timingSection
                }
            } footer: {
                footer
            }
            .frame(maxWidth: 560, maxHeight: 380)
            .frame(minWidth: WindowSizing.minPopupWidth, minHeight: WindowSizing.minPopupHeight)
            .onAppear {
                if draft.courseId == nil, let code = draft.courseCode,
                   let match = availableCourses.first(where: { $0.code == code })
                {
                    draft.courseId = match.id
                }
            }
        }

        // Sections
        private var taskSection: some View {
            VStack(alignment: .leading, spacing: ItariSpacing.m) {
                Text(NSLocalizedString("planner.task_sheet.section.task", comment: "")).itoriSectionHeader()
                ItoriFormRow(label: NSLocalizedString("planner.task_sheet.field.title", comment: "")) {
                    TextField(NSLocalizedString("planner.task_sheet.field.title", comment: ""), text: $draft.title)
                        .textFieldStyle(.roundedBorder)
                }
                ItoriFormRow(label: NSLocalizedString("planner.task_sheet.field.priority", comment: "")) {
                    Picker("", selection: $draft.priority) {
                        ForEach(PlannerTaskPriority.allCases) { p in
                            Text(p.rawValue.capitalized).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 240)
                }
            }
        }

        private var courseSection: some View {
            VStack(alignment: .leading, spacing: ItariSpacing.m) {
                Text(NSLocalizedString("planner.task_sheet.section.course", comment: "")).itoriSectionHeader()
                ItoriFormRow(label: NSLocalizedString("planner.task_sheet.field.course", comment: "")) {
                    Picker(
                        NSLocalizedString("planner.task_sheet.field.course", comment: ""),
                        selection: courseSelection
                    ) {
                        Text(NSLocalizedString("planner.task_sheet.field.course_none", comment: "")).tag(UUID?.none)
                        ForEach(availableCourses) { course in
                            Text(verbatim: "\(course.code) · \(course.title)").tag(Optional(course.id))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ItoriFormRow(label: NSLocalizedString("planner.task_sheet.field.assignment", comment: "")) {
                    TextField(
                        NSLocalizedString("planner.task_sheet.field.assignment_placeholder", comment: ""),
                        text: Binding(
                            get: { draft.assignmentID == nil ? "" : NSLocalizedString(
                                "planner.task_sheet.field.assignment_linked",
                                comment: ""
                            ) },
                            set: { _ in /* hook later */ }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                }
            }
        }

        private var timingSection: some View {
            VStack(alignment: .leading, spacing: ItariSpacing.m) {
                Text(NSLocalizedString("planner.task_sheet.section.timing", comment: "")).itoriSectionHeader()
                ItoriFormRow(label: NSLocalizedString("planner.task_sheet.field.due_date", comment: "")) {
                    DatePicker("", selection: $draft.dueDate, in: Date()..., displayedComponents: .date)
                        .labelsHidden()
                }
                ItoriFormRow(label: NSLocalizedString("planner.task_sheet.field.focus_estimate", comment: "")) {
                    Stepper(value: $draft.estimatedMinutes, in: 15 ... 480, step: 15) {
                        Text(
                            "\(draft.estimatedMinutes) \(NSLocalizedString("planner.task_sheet.field.minutes", comment: ""))"
                        )
                    }
                    .frame(maxWidth: 220, alignment: .leading)
                }
                ItoriFormRow(label: "") {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(
                            NSLocalizedString("planner.task_sheet.field.lock_due_date", comment: ""),
                            isOn: $draft.lockToDueDate
                        )
                        Text(NSLocalizedString("planner.task_sheet.field.lock_due_date_help", comment: ""))
                            .itoriCaption()
                    }
                }
                ItoriFormRow(label: NSLocalizedString("planner.recurrence.form.repeat", comment: "")) {
                    Picker("", selection: recurrenceSelection) {
                        ForEach(RecurrenceSelection.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                if draft.recurrenceEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        ItoriFormRow(label: NSLocalizedString("planner.recurrence.form.interval", comment: "")) {
                            Stepper(value: $draft.recurrenceInterval, in: 1 ... 30) {
                                Text(verbatim: "Every \(draft.recurrenceInterval) \(recurrenceUnitLabel)")
                            }
                            .frame(maxWidth: 220, alignment: .leading)
                        }
                        ItoriFormRow(label: NSLocalizedString("planner.recurrence.form.end", comment: "")) {
                            Picker("", selection: $draft.recurrenceEndOption) {
                                Text(NSLocalizedString("planner.recurrence.never", comment: ""))
                                    .tag(RecurrenceEndOption.never)
                                Text(NSLocalizedString("planner.recurrence.on_date", comment: ""))
                                    .tag(RecurrenceEndOption.onDate)
                                Text(NSLocalizedString("planner.recurrence.after", comment: ""))
                                    .tag(RecurrenceEndOption.afterOccurrences)
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        if draft.recurrenceEndOption == .onDate {
                            ItoriFormRow(label: "") {
                                DatePicker("", selection: $draft.recurrenceEndDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                        } else if draft.recurrenceEndOption == .afterOccurrences {
                            ItoriFormRow(label: "") {
                                Stepper(value: $draft.recurrenceEndCount, in: 1 ... 99) {
                                    Text(verbatim: "\(draft.recurrenceEndCount) occurrences")
                                }
                            }
                        }
                        ItoriFormRow(label: NSLocalizedString("planner.recurrence.form.skip", comment: "")) {
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(
                                    NSLocalizedString("planner.recurrence.form.skip_weekends", comment: ""),
                                    isOn: $draft.skipWeekends
                                )
                                Toggle(
                                    NSLocalizedString("planner.recurrence.form.skip_holidays", comment: ""),
                                    isOn: $draft.skipHolidays
                                )
                            }
                        }
                        if draft.skipHolidays {
                            ItoriFormRow(label: NSLocalizedString("planner.recurrence.form.holidays", comment: "")) {
                                Picker("", selection: $draft.holidaySource) {
                                    Text(NSLocalizedString("planner.recurrence.system_calendar", comment: ""))
                                        .tag(RecurrenceRule.HolidaySource.deviceCalendar)
                                    Text(NSLocalizedString("planner.recurrence.none", comment: ""))
                                        .tag(RecurrenceRule.HolidaySource.none)
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                            if !holidaySourceAvailable && draft.holidaySource == .deviceCalendar {
                                Text(NSLocalizedString("planner.recurrence.no_holiday_source", comment: ""))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }

        private var recurrenceSelection: Binding<RecurrenceSelection> {
            Binding(
                get: {
                    guard draft.recurrenceEnabled else { return .none }
                    switch draft.recurrenceFrequency {
                    case .daily: return .daily
                    case .weekly: return .weekly
                    case .monthly: return .monthly
                    case .yearly: return .yearly
                    }
                },
                set: { selection in
                    if selection == .none {
                        draft.recurrenceEnabled = false
                    } else {
                        draft.recurrenceEnabled = true
                        draft.recurrenceFrequency = selection.frequency
                    }
                }
            )
        }

        private var recurrenceUnitLabel: String {
            switch draft.recurrenceFrequency {
            case .daily:
                String.localizedStringWithFormat(
                    NSLocalizedString("days_unit", comment: ""),
                    draft.recurrenceInterval
                )
            case .weekly:
                String.localizedStringWithFormat(
                    NSLocalizedString("weeks_unit", comment: ""),
                    draft.recurrenceInterval
                )
            case .monthly:
                String.localizedStringWithFormat(
                    NSLocalizedString("months_unit", comment: ""),
                    draft.recurrenceInterval
                )
            case .yearly:
                String.localizedStringWithFormat(
                    NSLocalizedString("years_unit", comment: ""),
                    draft.recurrenceInterval
                )
            }
        }

        private var holidaySourceAvailable: Bool {
            guard CalendarAuthorizationManager.shared.isAuthorized else { return false }
            let calendars = DeviceCalendarManager.shared.store.calendars(for: .event)
            return calendars.contains(where: { $0.title.lowercased().contains("holiday") })
        }

        private var footer: some View {
            HStack {
                Spacer()
                Button(NSLocalizedString("planner.task_sheet.action.cancel", comment: "")) { dismiss() }
                Button(isNew ? NSLocalizedString("planner.task_sheet.action.create", comment: "") : NSLocalizedString(
                    "planner.task_sheet.action.save",
                    comment: ""
                )) {
                    onSave(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isSaveDisabled)
            }
        }
    }

    // MARK: - Previews

    struct PlannerPageView_Previews: PreviewProvider {
        static var previews: some View {
            PlannerPageView()
                .environmentObject(AppSettingsModel.shared)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
#endif
