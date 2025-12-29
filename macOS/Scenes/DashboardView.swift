#if os(macOS)
import SwiftUI
import Charts
import CoreData
import EventKit
import Foundation
import Combine
import _Concurrency

struct DashboardView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var calendarManager: CalendarManager
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var gradesStore: GradesStore
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isLoaded = false
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var todayBounce = false
    @State private var energyBounce = false
    @State private var selectedDate: Date = Date()
    @State private var tasks: [DashboardTask] = []
    @State private var events: [DashboardEvent] = []
    @EnvironmentObject private var deviceCalendar: DeviceCalendarManager
    @State private var showAddAssignmentSheet = false
    @State private var showAddGradeSheet = false
    @State private var showAddEventSheet = false
    @State private var showAddTaskSheet = false
    @ObservedObject private var studyHoursTracker = StudyHoursTracker.shared
    @State private var studyTrendRange: StudyTrendRange = .seven
    @State private var studyTrend: [StudyTrendPoint] = []
    @State private var columnMode: ColumnMode = .four
#if DEBUG
    @State private var debugLayoutState: DashboardDebugState = .live
    @State private var debugLogSizes = false
    @State private var debugSizes: [DashboardSlot: CGSize] = [:]
#endif

    // Layout tokens
    private let rowSpacing: CGFloat = 20
    private let columnSpacing: CGFloat = 20
    private let bottomDockClearancePadding: CGFloat = 120
    private let widthThresholdOneToTwo: CGFloat = 700
    private let widthThresholdTwoToFour: CGFloat = 1100
    private let hysteresisBuffer: CGFloat = 60

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                let mode = columnMode
                VStack(spacing: rowSpacing) {
#if DEBUG
                    debugControls
#endif
                    dashboardGrid(mode: mode)
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.horizontal, DesignSystem.Layout.padding.window)
                    .padding(.top, DesignSystem.Layout.spacing.medium)
                    .padding(.bottom, bottomDockClearancePadding)
            }
            .onAppear {
                columnMode = resolvedColumnMode(for: proxy.size.width)
#if DEBUG
                DashboardLayoutSpec.validate(for: columnMode)
#endif
            }
            .onChange(of: proxy.size.width) { _, newValue in
                columnMode = resolvedColumnMode(for: newValue)
#if DEBUG
                DashboardLayoutSpec.validate(for: columnMode)
#endif
            }
        }
        .sheet(isPresented: $showAddAssignmentSheet) {
            AddAssignmentView(initialType: .homework) { task in
                assignmentsStore.addTask(task)
            }
            .environmentObject(coursesStore)
        }
        .sheet(isPresented: $showAddTaskSheet) {
            AddAssignmentView(initialType: .project) { task in
                assignmentsStore.addTask(task)
            }
            .environmentObject(coursesStore)
        }
        .sheet(isPresented: $showAddGradeSheet) {
            AddGradeSheet(
                assignments: assignmentsStore.tasks,
                courses: gradeCourseSummaries
            ) { task in
                LOG_UI(.info, "Dashboard", "Add Grade saved sample for \(task.title)")
            }
        }
        .sheet(isPresented: $showAddEventSheet) {
            AddEventPopup()
                .environmentObject(calendarManager)
        }
        .onAppear {
            isLoaded = true
            LOG_UI(.info, "Navigation", "Displayed DashboardView")
            syncTasks()
            syncEvents()
            ensureEnergyReset(now: Date())
            refreshStudyTrend()

            // subscribe to course deletions
            CoursesStore.courseDeletedPublisher
                .receive(on: DispatchQueue.main)
                .sink { deletedId in
                    assignmentsStore.tasks.removeAll { $0.courseId == deletedId }
                    syncTasks()
                }
                .store(in: &cancellables)
        }
        .background(DesignSystem.Colors.appBackground)
        .onReceive(assignmentsStore.$tasks) { _ in
            syncTasks()
        }
        .onReceive(studyHoursTracker.$totals) { _ in
            refreshStudyTrend()
        }
        .onReceive(deviceCalendar.$events) { _ in
            syncEvents()
        }
        .onChange(of: calendarManager.selectedCalendarID) { _, _ in
            syncEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addEvent)) { _ in
            showAddEventSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .addEventRequested)) { _ in
            showAddEventSheet = true
        }
        .onReceive(energyResetTimer) { now in
            ensureEnergyReset(now: now)
        }
        .animation(.easeInOut(duration: 0.25), value: columnMode)
    }


    private func triggerNextAssignment() {
        let today = Calendar.current.startOfDay(for: Date())
        let upcoming = assignmentsStore.tasks
            .filter { !$0.isCompleted }
            .compactMap { task -> (task: AppTask, due: Date)? in
                guard let due = task.due else { return nil }
                return (task, due)
            }
            .sorted { $0.due < $1.due }

        let candidateDue = upcoming.first(where: { $0.due >= today })?.due ?? upcoming.first?.due
        appModel.selectedPage = .assignments
        appModel.requestedAssignmentDueDate = candidateDue
    }

    private var gradeCourseSummaries: [GradeCourseSummary] {
        coursesStore.activeCourses.map { course in
            let grade = gradesStore.grade(for: course.id)
            return GradeCourseSummary(
                id: course.id,
                courseCode: course.code,
                courseTitle: course.title,
                currentPercentage: grade?.percent,
                targetPercentage: nil,
                letterGrade: grade?.letter,
                creditHours: Int(course.credits ?? 0),
                colorTag: gradeColor(for: course.colorHex)
            )
        }
    }

    private var hasEvents: Bool {
        !events.isEmpty
    }

    private var hasTasks: Bool {
        !tasks.isEmpty
    }

    private var hasGrades: Bool {
        !gradesStore.grades.isEmpty || coursesStore.currentGPA > 0
    }

    private var hasWorkloadData: Bool {
        weeklyWorkloadBuckets().contains { $0.minutes > 0 }
    }

    private var hasAssignmentsData: Bool {
        !assignmentsStore.tasks.isEmpty
    }

    private var hasStudyTrendData: Bool {
        studyTrend.contains { $0.minutes > 0 }
    }

    private var nextEvent: DashboardEvent? {
        let now = Date()
        return events
            .filter { $0.date >= now }
            .sorted { $0.date < $1.date }
            .first
    }

    private var todayMode: DashboardCardMode {
        .full
    }

    private var eventsMode: DashboardCardMode {
        accessibilitySafe(modeOverride(defaultMode: EmptyStatePolicy.mode(hasData: hasWorkloadData)))
    }

    private var assignmentsMode: DashboardCardMode {
        accessibilitySafe(modeOverride(defaultMode: EmptyStatePolicy.mode(hasData: hasTasks)))
    }

    private var energyMode: DashboardCardMode {
        accessibilitySafe(modeOverride(defaultMode: EmptyStatePolicy.mode(hasData: hasAssignmentsData)))
    }

    private var studyHoursMode: DashboardCardMode {
        accessibilitySafe(modeOverride(defaultMode: EmptyStatePolicy.mode(hasData: hasStudyTrendData)))
    }

    private var todayCompactState: DashboardCompactState {
        DashboardCompactState(
            title: "Quiet Day",
            description: "No tasks or events on deck yet.",
            actionTitle: "Open Planner"
        ) {
            appModel.selectedPage = .planner
        }
    }

    private var eventsCompactState: DashboardCompactState {
        return DashboardCompactState(
            title: "No Workload Yet",
            description: "Assignments scheduled this week show up here.",
            actionTitle: "Add Assignment"
        ) {
            showAddAssignmentSheet = true
        }
    }

    private var assignmentsCompactState: DashboardCompactState {
        DashboardCompactState(
            title: "No Upcoming Assignments",
            description: "When you add assignments, they appear here.",
            actionTitle: "Add Assignment"
        ) {
            showAddAssignmentSheet = true
        }
    }

    private var energyCompactState: DashboardCompactState {
        return DashboardCompactState(
            title: "No Status Yet",
            description: "Assignment progress shows here once you add tasks.",
            actionTitle: "Add Assignment"
        ) {
            showAddAssignmentSheet = true
        }
    }

    private var studyHoursCompactState: DashboardCompactState {
        DashboardCompactState(
            title: "No Study Time Logged",
            description: "Track a session to see your trend.",
            actionTitle: "Open Timer"
        ) {
            appModel.selectedPage = .timer
        }
    }

    @ViewBuilder
    private func dashboardGrid(mode: ColumnMode) -> some View {
        Grid(horizontalSpacing: columnSpacing, verticalSpacing: rowSpacing) {
            ForEach(Array(DashboardLayoutSpec.rows(for: mode).enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(row, id: \.self) { slot in
                        dashboardSlot(slot: slot)
                            .gridCellColumns(DashboardLayoutSpec.span(for: slot, mode: mode))
                    }
                    let remaining = mode.rawValue - rowSpanWidth(row, mode: mode)
                    if remaining > 0 {
                        dashboardSpacer
                            .gridCellColumns(remaining)
                    }
                }
            }
        }
        .overlay {
#if DEBUG
            Color.clear.onPreferenceChange(DashboardCardSizeKey.self) { sizes in
                if sizes != debugSizes {
                    debugSizes = sizes
                    validateDebugSizes(sizes: sizes, mode: columnMode)
                    if debugLogSizes {
                        for (slot, size) in sizes {
                            print("Dashboard size \(slot): \(size)")
                        }
                    }
                }
            }
#endif
        }
    }

    private func dashboardSlot(slot: DashboardSlot) -> some View {
        render(slot: slot)
            .frame(
                maxWidth: .infinity,
                minHeight: DashboardLayoutSpec.minHeight(for: slot, mode: modeFor(slot: slot)),
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .background(slotSizeReporter(slot: slot))
            .animation(.easeInOut(duration: 0.25), value: modeFor(slot: slot))
    }

    private var dashboardSpacer: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: 1)
    }

    private var upNextCard: some View? {
        let nextAssignment = upcomingAssignments().first
        let nextEvent = upcomingCalendarEvents().first

        if nextAssignment == nil && nextEvent == nil {
            return nil
        }

        return RootsCard(
            title: cardTitle("Up Next"),
            icon: "sparkles"
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                if let event = nextEvent {
                    Button {
                        appModel.selectedPage = .calendar
                        NotificationCenter.default.post(
                            name: .selectCalendarEvent,
                            object: nil,
                            userInfo: [
                                "ekIdentifier": event.ekIdentifier as Any,
                                "date": event.date
                            ]
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next Event")
                                .rootsBodySecondary()
                            Text(event.title)
                                .font(DesignSystem.Typography.body)
                            Text(event.time)
                                .rootsCaption()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }

                if let task = nextAssignment {
                    if nextEvent != nil {
                        Divider()
                    }
                    Button {
                        appModel.selectedPage = .assignments
                        appModel.requestedAssignmentDueDate = task.due
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next Assignment")
                                .rootsBodySecondary()
                            Text(task.title)
                                .font(DesignSystem.Typography.body)
                            if let due = task.due {
                                Text(due.formatted(date: .abbreviated, time: .shortened))
                                    .rootsCaption()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func gradeColor(for hex: String?) -> Color {
        if let colorTag = ColorTag.fromHex(hex) {
            return colorTag.color
        }
        // Try to parse as hex color directly
        if let hex = hex, let hexColor = Color(hex: hex) {
            return hexColor
        }
        // Fallback to blue only if no hex provided
        return Color.blue
    }

    private func relativeTimeString(to date: Date, from now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: now)
    }

    private var todayCard: some View {
        DashboardCard(
            title: "Status",
            systemImage: "sparkles",
            isLoading: debugIsLoading,
            mode: todayMode,
            compactState: debugCompactState(defaultState: todayCompactState)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today / Focus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                let dueToday = tasksDueToday().count
                Text("\(dueToday)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)
                Text(dueToday == 1 ? "Task due today" : "Tasks due today")
                    .font(.title3.weight(.semibold))

                let eventsTodayCount = todaysCalendarEvents().count
                Text(eventsTodayCount == 0 ? "No events scheduled" : "\(eventsTodayCount) events scheduled")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open Assignments") {
                    appModel.selectedPage = .assignments
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
        }
        .onTapGesture {
            todayBounce.toggle()
            print("[Dashboard] card tapped: todayOverview")
        }
        .help("Today Overview")
        .accessibilityIdentifier("DashboardHeader")
    }

    private var energyCard: some View {
        DashboardCard(
            title: "Assignment Status",
            systemImage: "chart.pie",
            isLoading: debugIsLoading,
            mode: energyMode,
            compactState: debugCompactState(defaultState: energyCompactState)
        ) {
            assignmentStatusChart
        }
        .onTapGesture {
            energyBounce.toggle()
            print("[Dashboard] card tapped: assignmentStatus")
        }
        .help("Assignment Status")
    }

    @ViewBuilder
    private func energyButton(_ title: String, level: EnergyLevel) -> some View {
        let isSelected = settings.defaultEnergyLevel == title
        Button {
            setEnergy(level)
            settings.defaultEnergyLevel = title
            settings.energySelectionConfirmed = true
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.vertical, 8)
        }
        .buttonStyle(isSelected ? .borderedProminent : .bordered)
        .tint(isSelected ? settings.activeAccentColor : .secondary)
        .accessibilityLabel("Set energy level to \(title)")
        .accessibilityHint("Updates your current energy level")
    }

    @ViewBuilder
    private func plannerButton(_ title: String) -> some View {
        let a11yContent = VoiceOverLabels.navigationButton(to: "Planner")
        Button {
            appModel.selectedPage = .planner
        } label: {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .voiceOver(a11yContent)
    }

    private var workloadCard: some View {
        DashboardCard(
            title: "Weekly Workload",
            systemImage: "chart.bar.xaxis",
            isLoading: debugIsLoading,
            mode: eventsMode,
            compactState: debugCompactState(defaultState: eventsCompactState)
        ) {
            weeklyWorkloadChart
        }
    }

    private var assignmentsCard: some View {
        DashboardCard(
            title: "Upcoming Assignments",
            systemImage: "checkmark.circle",
            isLoading: debugIsLoading,
            mode: assignmentsMode,
            compactState: debugCompactState(defaultState: assignmentsCompactState)
        ) {
            let upcoming = upcomingAssignments()
            VStack(alignment: .leading, spacing: 10) {
                Text("\(upcoming.count)")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                Text("Due soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(upcoming.prefix(3)) { task in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.body)
                                .lineLimit(1)
                            if let due = task.due {
                                Text(due.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if upcoming.isEmpty {
                        Text("Nothing due soon.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Open Assignments") {
                    appModel.selectedPage = .assignments
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private var gradesCard: some View {
        RootsCard(
            title: cardTitle("Grades"),
            icon: "chart.bar.doc.horizontal"
        ) {
            let courseCount = coursesStore.activeCourses.count
            let gpa = coursesStore.currentGPA
            DashboardTileBody(rows: [
                ("Current GPA", gpa > 0 ? String(format: "%.2f", gpa) : "—"),
                ("Active Courses", "\(courseCount)")
            ])
        }
    }

    private var timeCard: some View {
        DashboardCard(
            title: "Time",
            systemImage: "clock",
            isLoading: debugIsLoading,
            mode: modeOverride(defaultMode: .full),
            compactState: debugCompactState(defaultState: timeCompactState)
        ) {
            TimelineView(.animation(minimumInterval: 1.0, paused: false)) { context in
                VStack(alignment: .leading, spacing: RootsSpacing.m) {
                    let clockSize: CGFloat = 140
                    HStack(alignment: .center, spacing: DesignSystem.Layout.spacing.large) {
                        RootsAnalogClock(
                            style: .clock,
                            diameter: clockSize,
                            showSecondHand: true,
                            accentColor: settings.activeAccentColor
                        )
                        .frame(width: clockSize, height: clockSize)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(context.date, style: .time)
                                .font(.title2.weight(.semibold))
                            Text(context.date, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let nextEvent {
                                Text("Next up \(relativeTimeString(to: nextEvent.date, from: context.date))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, DesignSystem.Layout.spacing.small)
                }
            }
        }
    }

    private var studyHoursCard: some View {
        DashboardCard(
            title: "Study Time Trend",
            systemImage: "chart.line.uptrend.xyaxis",
            isLoading: debugIsLoading,
            mode: studyHoursMode,
            compactState: debugCompactState(defaultState: studyHoursCompactState)
        ) {
            studyTrendChart
        }
    }

    private var timeCompactState: DashboardCompactState {
        DashboardCompactState(
            title: "Clock Ready",
            description: "Your local time and date are available.",
            actionTitle: "Open Calendar"
        ) {
            appModel.selectedPage = .calendar
        }
    }



    private func quickActionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .frame(minHeight: 34)
        }
        .buttonStyle(.borderedProminent)
        .tint(settings.activeAccentColor)
        .controlSize(.small)
        .transition(DesignSystem.Motion.slideTrailingTransition)
    }

    private var quickActionList: [(label: String, icon: String, handler: () -> Void)] {
        [
            ("Add Assignment", "doc.badge.plus", { showAddAssignmentSheet = true }),
            ("Next Assignment", "arrow.right.circle", { triggerNextAssignment() }),
            ("Add Grade", "chart.bar.doc.horizontal", { showAddGradeSheet = true }),
            ("Add Event", "calendar.badge.plus", { showAddEventSheet = true }),
            ("Add Task", "list.bullet.rectangle", { showAddTaskSheet = true })
        ]
    }

    private func cardTitle(_ title: String) -> String? { title }

    private enum StudyTrendRange: String, CaseIterable, Identifiable {
        case seven = "7D"
        case fourteen = "14D"
        case thirty = "30D"

        var id: String { rawValue }
        var days: Int {
            switch self {
            case .seven: return 7
            case .fourteen: return 14
            case .thirty: return 30
            }
        }
    }

    private struct WorkloadBucket: Identifiable {
        let id = UUID()
        let day: Date
        let category: TaskType
        let minutes: Double
    }

    private struct StudyTrendPoint: Identifiable {
        let id = UUID()
        let day: Date
        let minutes: Double
    }

    private struct AssignmentStatusItem: Identifiable {
        let id = UUID()
        let status: String
        let count: Int
        let color: Color
    }

    private var dashboardTodayStats: some View {
        let eventsTodayCount = todaysCalendarEvents().count
        let dueToday = tasksDueToday().count

        return DashboardTileBody(
            rows: [
                ("Events Today", "\(eventsTodayCount)"),
                ("Items Due Today", "\(dueToday)")
            ]
        )
    }

    private var weeklyWorkloadChart: some View {
        let buckets = weeklyWorkloadBuckets()
        return Chart(buckets) { item in
            BarMark(
                x: .value("Day", item.day, unit: .day),
                y: .value("Minutes", item.minutes)
            )
            .foregroundStyle(by: .value("Category", item.category.rawValue))
        }
        .chartForegroundStyleScale(
            domain: TaskType.allCases.map { $0.rawValue },
            range: TaskType.allCases.map { categoryColor($0) }
        )
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .frame(height: 180)
    }

    private var studyTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("Range", selection: $studyTrendRange) {
                    ForEach(StudyTrendRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)

                Spacer()
            }

            Chart(studyTrend) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(settings.activeAccentColor)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Day", point.day),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            settings.activeAccentColor.opacity(0.35),
                            settings.activeAccentColor.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .frame(height: 180)
        }
        .onChange(of: studyTrendRange) { _, _ in
            refreshStudyTrend()
        }
    }

    private var assignmentStatusChart: some View {
        let items = assignmentStatusItems()
        let total = items.reduce(0) { $0 + $1.count }

        return Chart(items) { item in
            SectorMark(
                angle: .value("Count", item.count),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .foregroundStyle(item.color)
        }
        .frame(height: 180)
        .overlay {
            VStack(spacing: 4) {
                Text("\(total)")
                    .font(.title2.bold())
                Text("Assignments")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func weeklyWorkloadBuckets() -> [WorkloadBucket] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start

        let upcoming = assignmentsStore.tasks.filter { task in
            guard let due = task.due else { return false }
            return due >= start && due <= end && !task.isCompleted
        }

        var buckets: [WorkloadBucket] = []
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }
            let dayTasks = upcoming.filter { task in
                guard let due = task.due else { return false }
                return calendar.isDate(due, inSameDayAs: day)
            }
            let grouped = Dictionary(grouping: dayTasks, by: { $0.category })
            for (category, tasks) in grouped {
                let minutes = tasks.reduce(0.0) { $0 + Double($1.estimatedMinutes) }
                if minutes > 0 {
                    buckets.append(WorkloadBucket(day: day, category: category, minutes: minutes))
                }
            }
        }
        return buckets
    }

    private func assignmentStatusItems() -> [AssignmentStatusItem] {
        let plans = AssignmentPlansStore.shared
        let completed = assignmentsStore.tasks.filter { $0.isCompleted }.count
        let inProgress = assignmentsStore.tasks.filter { task in
            !task.isCompleted && plans.plan(for: task.id) != nil
        }.count
        let notStarted = assignmentsStore.tasks.filter { task in
            !task.isCompleted && plans.plan(for: task.id) == nil
        }.count

        return [
            AssignmentStatusItem(status: "Not Started", count: notStarted, color: .orange),
            AssignmentStatusItem(status: "In Progress", count: inProgress, color: .yellow),
            AssignmentStatusItem(status: "Completed", count: completed, color: .green)
        ]
    }

    private func refreshStudyTrend() {
        let days = studyTrendRange.days
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date().addingTimeInterval(TimeInterval(-(days - 1) * 24 * 60 * 60)))

        let request = NSFetchRequest<NSManagedObject>(entityName: "TimerSession")
        request.predicate = NSPredicate(format: "startedAt >= %@", start as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: true)]

        var totalsByDay: [Date: Double] = [:]
        do {
            let results = try PersistenceController.shared.viewContext.fetch(request)
            for session in results {
                let startedAt = session.value(forKey: "startedAt") as? Date ?? start
                let durationSeconds = session.value(forKey: "durationSeconds") as? Double ?? 0
                let day = calendar.startOfDay(for: startedAt)
                totalsByDay[day, default: 0] += durationSeconds / 60.0
            }
        } catch {
            LOG_DATA(.error, "Dashboard", "Failed to load timer sessions: \(error.localizedDescription)")
        }

        var points: [StudyTrendPoint] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let minutes = totalsByDay[calendar.startOfDay(for: day), default: 0]
            points.append(StudyTrendPoint(day: day, minutes: minutes))
        }
        studyTrend = points
    }

    private func categoryColor(_ category: TaskType) -> Color {
        switch category {
        case .reading: return .blue.opacity(0.7)
        case .homework: return .green.opacity(0.7)
        case .exam: return .red.opacity(0.7)
        case .quiz: return .orange.opacity(0.7)
        case .review: return .purple.opacity(0.6)
        case .project: return .teal.opacity(0.7)
        }
    }

    private func syncTasks() {
        let dueTodayTasks = tasksDueToday()
        let mapped = dueTodayTasks.map { appTask in
            DashboardTask(title: appTask.title, course: appTask.courseId?.uuidString, isDone: appTask.isCompleted)
        }
        withAnimation(DesignSystem.Motion.standardSpring) {
            tasks = mapped
        }
    }

    private func syncEvents() {
        let todayEvents = todaysCalendarEvents()
        let mapped = todayEvents.map { event in
            DashboardEvent(
                title: event.title,
                time: "\(event.startDate.formatted(date: .omitted, time: .shortened)) – \(event.endDate.formatted(date: .omitted, time: .shortened))",
                location: nil,
                date: event.startDate,
                ekIdentifier: event.eventIdentifier
            )
        }
        withAnimation(DesignSystem.Motion.standardSpring) {
            events = mapped.sorted { $0.date < $1.date }
        }
    }

    private func todaysCalendarEvents() -> [EKEvent] {
        let cal = Calendar.current
        let source = DeviceCalendarManager.shared.events
        return source.filter { event in
            cal.isDateInToday(event.startDate) &&
            (calendarManager.selectedCalendarID.isEmpty || event.calendar.calendarIdentifier == calendarManager.selectedCalendarID)
        }
    }

    private func tasksDueToday() -> [AppTask] {
        let cal = Calendar.current
        return assignmentsStore.tasks
            .filter { !$0.isCompleted }
            .filter { task in
                guard let due = task.due else { return false }
                return cal.isDateInToday(due)
            }
            .sorted { ($0.due ?? Date.distantFuture) < ($1.due ?? Date.distantFuture) }
    }

    private func upcomingAssignments() -> [AppTask] {
        let now = Date()
        return assignmentsStore.tasks
            .filter { !$0.isCompleted }
            .compactMap { task -> AppTask? in
                guard let due = task.due else { return nil }
                return due >= now ? task : nil
            }
            .sorted { ($0.due ?? Date.distantFuture) < ($1.due ?? Date.distantFuture) }
    }

    private func upcomingCalendarEvents() -> [DashboardEvent] {
        let now = Date()
        let source = DeviceCalendarManager.shared.events
        let filtered = source.filter { event in
            event.startDate >= now &&
            (calendarManager.selectedCalendarID.isEmpty || event.calendar.calendarIdentifier == calendarManager.selectedCalendarID)
        }
        return filtered
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                DashboardEvent(
                    title: event.title,
                    time: "\(event.startDate.formatted(date: .omitted, time: .shortened)) – \(event.endDate.formatted(date: .omitted, time: .shortened))",
                    location: nil,
                    date: event.startDate,
                    ekIdentifier: event.eventIdentifier
                )
            }
    }

    private func setEnergy(_ level: EnergyLevel) {
        let current = SchedulerPreferencesStore.shared.preferences.learnedEnergyProfile
        let base: [Int: Double]
        switch level {
        case .high:
            base = current.mapValues { min(1.0, $0 + 0.2) }
        case .medium:
            base = current
        case .low:
            base = current.mapValues { max(0.1, $0 - 0.2) }
        }
        SchedulerPreferencesStore.shared.updateEnergyProfile(base)
    }

    private var energyResetTimer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 900, on: .main, in: .common).autoconnect()
    }

    private func ensureEnergyReset(now: Date) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: now)
        let resetTimeToday = calendar.date(byAdding: .hour, value: 4, to: dayStart) ?? dayStart
        let mostRecentReset = now >= resetTimeToday
            ? resetTimeToday
            : (calendar.date(byAdding: .day, value: -1, to: resetTimeToday) ?? resetTimeToday)

        if settings.energySelectionResetDate < mostRecentReset {
            settings.energySelectionConfirmed = false
            settings.energySelectionResetDate = now
        }
    }

    private enum EnergyLevel {
        case high, medium, low
    }
}
#if DEBUG
private enum DashboardDebugState: String, CaseIterable, Identifiable {
    case live
    case compact
    case full
    case loading
    case error

    var id: String { rawValue }
}

private struct DashboardCardSizeKey: PreferenceKey {
    static var defaultValue: [DashboardSlot: CGSize] = [:]
    static func reduce(value: inout [DashboardSlot: CGSize], nextValue: () -> [DashboardSlot: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// Removed card width preferences (no longer needed for layout)
#endif

private extension DashboardView {
    var debugIsLoading: Bool {
#if DEBUG
        return debugLayoutState == .loading
#else
        return false
#endif
    }

    func debugCompactState(defaultState: DashboardCompactState) -> DashboardCompactState {
#if DEBUG
        if debugLayoutState == .error {
            return DashboardCompactState(
                title: "Data Unavailable",
                description: "An error occurred while loading this card.",
                actionTitle: "Retry",
                action: {}
            )
        }
        return defaultState
#else
        return defaultState
#endif
    }

    func modeFor(slot: DashboardSlot) -> DashboardCardMode {
        switch slot {
        case .today:
            return todayMode
        case .time:
            return .full
        case .upcoming:
            return eventsMode
        case .assignments:
            return assignmentsMode
        case .energy:
            return energyMode
        case .studyHours:
            return studyHoursMode
        }
    }

    @ViewBuilder
    func render(slot: DashboardSlot) -> some View {
        switch slot {
        case .today:
            todayCard
        case .time:
            timeCard
        case .upcoming:
            workloadCard
        case .assignments:
            assignmentsCard
        case .energy:
            energyCard
        case .studyHours:
            studyHoursCard
        }
    }

    func rowSpanWidth(_ row: [DashboardSlot], mode: ColumnMode) -> Int {
        row.reduce(0) { $0 + DashboardLayoutSpec.span(for: $1, mode: mode) }
    }

    @ViewBuilder
    func slotSizeReporter(slot: DashboardSlot) -> some View {
#if DEBUG
        GeometryReader { proxy in
            Color.clear.preference(key: DashboardCardSizeKey.self, value: [slot: proxy.size])
        }
#else
        EmptyView()
#endif
    }

    func modeOverride(defaultMode: DashboardCardMode) -> DashboardCardMode {
#if DEBUG
        switch debugLayoutState {
        case .live:
            return defaultMode
        case .compact:
            return .compactEmpty
        case .full, .loading, .error:
            return .full
        }
#else
        return defaultMode
#endif
    }

    func accessibilitySafe(_ mode: DashboardCardMode) -> DashboardCardMode {
        dynamicTypeSize.isAccessibilitySize ? .full : mode
    }

    func resolvedColumnMode(for width: CGFloat) -> ColumnMode {
        switch columnMode {
        case .one:
            if width >= widthThresholdOneToTwo {
                return .two
            }
            return .one
        case .two:
            if width >= widthThresholdTwoToFour {
                return .four
            }
            if width < (widthThresholdOneToTwo - hysteresisBuffer) {
                return .one
            }
            return .two
        case .four:
            if width < (widthThresholdOneToTwo - hysteresisBuffer) {
                return .one
            }
            if width < (widthThresholdTwoToFour - hysteresisBuffer) {
                return .two
            }
            return .four
        }
    }

#if DEBUG
    func validateDebugSizes(sizes: [DashboardSlot: CGSize], mode: ColumnMode) {
        for (slot, size) in sizes {
            let minHeight = DashboardLayoutSpec.minHeight(for: slot, mode: modeFor(slot: slot))
            assert(size.height + 1.0 >= minHeight, "Dashboard card height too small for \(slot).")
        }

        let rows = DashboardLayoutSpec.rows(for: mode)
        for row in rows {
            let heights = row.compactMap { sizes[$0]?.height }
            guard let maxHeight = heights.max(), let minHeight = heights.min() else { continue }
            assert(maxHeight - minHeight <= 1.0, "Dashboard row height mismatch.")
        }
    }
#endif

#if DEBUG
    var debugControls: some View {
        DashboardCard(
            title: "Dashboard Debug",
            systemImage: "ladybug",
            mode: .full
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Layout State", selection: $debugLayoutState) {
                    ForEach(DashboardDebugState.allCases) { state in
                        Text(state.rawValue.capitalized).tag(state)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Log card sizes", isOn: $debugLogSizes)
                    .toggleStyle(.switch)
            }
        }
        .frame(maxWidth: .infinity)
    }
#endif
}

struct DashboardTileBody: View {
    let rows: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.0)
                        .rootsBodySecondary()
                    Text(row.1)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(RootsColor.textPrimary)
                }
            }
        }
    }
}

// MARK: - Models for dashboard layout

struct DashboardTask: Identifiable {
    let id = UUID()
    var title: String
    var course: String?
    var isDone: Bool
}

private struct TodayMiniTimeline: View {
    let items: [DashboardTimelineItem]
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if items.isEmpty {
                Text("All clear for now.")
                    .rootsBodySecondary()
            } else {
                ForEach(items) { item in
                    DashboardTimelineRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        detail: item.detail,
                        isActive: item.time <= now.addingTimeInterval(3600)
                    )
                }
            }
        }
    }
}

private struct DashboardTimelineItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let detail: String?
    let time: Date
}

struct DashboardEvent: Identifiable {
    let id = UUID()
    var title: String
    var time: String
    var location: String?
    var date: Date
    var ekIdentifier: String?
}

// MARK: - Columns

private struct DashboardCalendarColumn: View {
    @Binding var selectedDate: Date
    var events: [DashboardEvent]
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("dashboard.calendar.header".localized).rootsSectionHeader()
            Text(monthHeader(for: selectedDate)).rootsBodySecondary()

            LazyVGrid(columns: columns, spacing: DesignSystem.Layout.spacing.small) {
                       ForEach(dayItems) { item in
                         let day = item.date
                    let isInMonth = calendar.isDate(day, equalTo: selectedDate, toGranularity: .month)
                    let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                    let normalized = calendar.startOfDay(for: day)
                    let count = eventsByDate[normalized] ?? 0

                    Button {
                        selectedDate = day
                    } label: {
                        CalendarDayCell(
                            date: day,
                            isInCurrentMonth: isInMonth,
                            isSelected: isSelected,
                            eventCount: count,
                            calendar: calendar
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .rootsCardBackground(radius: 20)
        }
        .padding(DesignSystem.Layout.padding.card)
        .rootsCardBackground(radius: 22)
    }

    private var eventsByDate: [Date: Int] {
        Dictionary(grouping: events, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { $0.count }
    }

    private struct DayItem: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let isCurrentMonth: Bool
    }

    private var dayItems: [DayItem] {
        days.map { DayItem(date: $0, isCurrentMonth: calendar.isDate($0, equalTo: selectedDate, toGranularity: .month)) }
    }

    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        let monthStart = calendar.startOfDay(for: monthInterval.start)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthStart)) else { return [] }

        let lastOfMonth = calendar.date(byAdding: .second, value: -1, to: monthInterval.end) ?? monthInterval.end
        guard let endOfWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastOfMonth)),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: endOfWeekStart) else { return [] }

        var items: [Date] = []
        var seen = Set<Date>()
        var current = startOfWeek

        while current < endOfWeek && items.count < 42 {
            let s = calendar.startOfDay(for: current)
            if !seen.contains(s) {
                items.append(s)
                seen.insert(s)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        while items.count % 7 != 0 {
            if let last = items.last, let next = calendar.date(byAdding: .day, value: 1, to: last) {
                let s = calendar.startOfDay(for: next)
                if !seen.contains(s) {
                    items.append(s)
                    seen.insert(s)
                } else { break }
            } else { break }
        }

        return items
    }

    private func monthHeader(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Integrated Calendar Grid (no nested card)
private struct DashboardCalendarGrid: View {
    @Binding var selectedDate: Date
    var events: [DashboardEvent]
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
            // Month/year header
            Text(monthHeader(for: selectedDate))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            // Calendar grid - no nested card background
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dayItems) { item in
                    let day = item.date
                    let isInMonth = calendar.isDate(day, equalTo: selectedDate, toGranularity: .month)
                    let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                    let normalized = calendar.startOfDay(for: day)
                    let count = eventsByDate[normalized] ?? 0

                    Button {
                        selectedDate = day
                    } label: {
                        CalendarDayCell(
                            date: day,
                            isInCurrentMonth: isInMonth,
                            isSelected: isSelected,
                            eventCount: count,
                            calendar: calendar
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var eventsByDate: [Date: Int] {
        Dictionary(grouping: events, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { $0.count }
    }
    
    private struct DayItem: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let isCurrentMonth: Bool
    }
    
    private var dayItems: [DayItem] {
        days.map { DayItem(date: $0, isCurrentMonth: calendar.isDate($0, equalTo: selectedDate, toGranularity: .month)) }
    }
    
    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        let monthStart = calendar.startOfDay(for: monthInterval.start)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthStart)) else { return [] }

        let lastOfMonth = calendar.date(byAdding: .second, value: -1, to: monthInterval.end) ?? monthInterval.end
        guard let endOfWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastOfMonth)),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: endOfWeekStart) else { return [] }

        var items: [Date] = []
        var seen = Set<Date>()
        var current = startOfWeek

        while current < endOfWeek && items.count < 42 {
            let s = calendar.startOfDay(for: current)
            if !seen.contains(s) {
                items.append(s)
                seen.insert(s)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        while items.count % 7 != 0 {
            if let last = items.last, let next = calendar.date(byAdding: .day, value: 1, to: last) {
                let s = calendar.startOfDay(for: next)
                if !seen.contains(s) {
                    items.append(s)
                    seen.insert(s)
                } else { break }
            } else { break }
        }

        return items
    }
    
    private func monthHeader(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}

private struct DashboardTasksColumn: View {
    @Binding var tasks: [DashboardTask]
    let maxItems: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("dashboard.assignments.due_today".localized)
                .rootsSectionHeader()

            if tasks.isEmpty {
                Text("dashboard.assignments.empty".localized)
                    .rootsBodySecondary()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        let visibleCount = min(tasks.count, maxItems)
                        ForEach(0..<visibleCount, id: \.self) { index in
                            TaskRow(task: $tasks[index],
                                    showConnectorAbove: index != 0,
                                    showConnectorBelow: index != visibleCount - 1)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: .infinity)
                .animation(DesignSystem.Motion.standardSpring, value: tasks.count)
            }
        }
        .padding(DesignSystem.Layout.padding.card)
        .rootsCardBackground(radius: 22)
    }
}

private struct DashboardEventsColumn: View {
    var events: [DashboardEvent]
    let maxItems: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("dashboard.events.upcoming".localized)
                .rootsSectionHeader()

            if events.isEmpty {
                Text("dashboard.events.empty".localized)
                    .rootsBodySecondary()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(events.prefix(maxItems)) { event in
                            DashboardTimelineRow(
                                title: event.title,
                                subtitle: event.time,
                                detail: event.location,
                                isActive: event.date <= Date().addingTimeInterval(3600)
                            )
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: .infinity)
                .animation(DesignSystem.Motion.standardSpring, value: events.count)
            }
        }
        .padding(DesignSystem.Layout.padding.card)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Calendar Load Helpers


// MARK: - Task Row

private struct TaskRow: View {
    @Binding var task: DashboardTask
    var showConnectorAbove: Bool
    var showConnectorBelow: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                VStack {
                    if showConnectorAbove {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 2, height: 8)
                            .offset(y: -6)
                    }
                    Spacer()
                    if showConnectorBelow {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 2, height: 8)
                            .offset(y: 6)
                    }
                }

                Toggle(isOn: $task.isDone) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .accessibilityLabel(task.isDone ? "Completed" : "Not completed")
                .accessibilityHint("Toggle completion status")
                .accessibilityAddTraits(.isButton)
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(DesignSystem.Typography.body)
                    .strikethrough(task.isDone, color: .secondary)

                if let course = task.course {
                    Text(course)
                        .rootsCaption()
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(DesignSystem.Materials.hud)
                .opacity(isHovered ? 0.45 : 0.0)
        )
        .onHover { hover in
            withAnimation(DesignSystem.Motion.interactiveSpring) {
                isHovered = hover
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title)\(task.course.map { ", \($0)" } ?? ""), \(task.isDone ? "Completed" : "Not completed")")
    }
}

private struct DashboardTimelineRow: View {
    let title: String
    let subtitle: String
    let detail: String?
    let isActive: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 6) {
                Circle()
                    .fill(isActive ? DesignSystem.Colors.accent : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                Text(subtitle)
                    .rootsBodySecondary()
                if let detail {
                    Text(detail)
                        .rootsCaption()
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(DesignSystem.Materials.hud)
                .opacity(isHovered ? 0.45 : 0.0)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onHover { hover in
            withAnimation(DesignSystem.Motion.interactiveSpring) {
                isHovered = hover
            }
        }
        .overlay(alignment: .leading) {
            if isActive {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DesignSystem.Colors.accent.opacity(0.16))
                    .frame(width: 6)
            }
        }
    }
}

// MARK: - Static Month Calendar

struct StaticMonthCalendarView: View {
    let currentDate: Date
    var events: [DashboardEvent] = []
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing.small) {
            weekdayHeader
            LazyVGrid(columns: columns, spacing: DesignSystem.Layout.spacing.small) {
                ForEach(leadingBlanks, id: \.self) { _ in
                    Text(" ")
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                ForEach(daysInMonth, id: \.self) { day in
                    let date = calendar.date(bySetting: .day, value: day, of: currentDate) ?? currentDate
                    let count = events.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
                    let isSelected = calendar.isDate(date, inSameDayAs: currentDate)
                    CalendarDayCell(date: date, isInCurrentMonth: calendar.isDate(date, equalTo: currentDate, toGranularity: .month), isSelected: isSelected, eventCount: count, calendar: calendar)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1 // Calendar is 1-based
        let ordered = Array(symbols[firstWeekdayIndex..<symbols.count] + symbols[0..<firstWeekdayIndex])

        return HStack(spacing: 6) {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayView(_ day: Int) -> some View {
        let isToday = day == todayDay && isCurrentMonth
        return Text("\(day)")
            .font(.caption.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 32)
            .padding(6)
            .background(
                Circle()
                    .fill(isToday ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .foregroundColor(isToday ? .primary : .primary.opacity(0.7))
    }

    private var todayDay: Int {
        calendar.component(.day, from: currentDate)
    }

    private var isCurrentMonth: Bool {
        let now = Date()
        return calendar.isDate(now, equalTo: currentDate, toGranularity: .month)
    }

    private var daysInMonth: [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: currentDate) else { return [] }
        return Array(range)
    }

    private var leadingBlanks: [Int] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: currentDate),
            let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }

        let adjusted = (firstWeekday - calendar.firstWeekday + 7) % 7
        return Array(0..<adjusted)
    }
}
#endif
