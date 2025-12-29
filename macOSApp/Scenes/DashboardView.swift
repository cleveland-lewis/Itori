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

    // Layout tokens
    private let cardSpacing: CGFloat = DesignSystem.Spacing.large
    private let contentPadding: CGFloat = DesignSystem.Spacing.large
    private let bottomDockClearancePadding: CGFloat = 100

    var body: some View {
        // Fixed hierarchy grid - no ad-hoc cards
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                // ROW 1: STATUS STRIP (no card chrome)
                statusStrip
                    .animateEntry(isLoaded: isLoaded, index: 0)
                    .padding(.horizontal, contentPadding)
                    .padding(.top, contentPadding)
                    .padding(.bottom, cardSpacing)
                
                // ROW 2: ANALYTICS
                HStack(alignment: .top, spacing: cardSpacing) {
                    workloadCard
                        .animateEntry(isLoaded: isLoaded, index: 1)
                        .frame(maxWidth: .infinity)
                    
                    studyHoursCard
                        .animateEntry(isLoaded: isLoaded, index: 2)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, contentPadding)
                .padding(.bottom, cardSpacing)
                
                // ROW 3: STATUS + UPCOMING
                HStack(alignment: .top, spacing: cardSpacing) {
                    energyCard
                        .animateEntry(isLoaded: isLoaded, index: 3)
                        .frame(maxWidth: .infinity)
                    
                    assignmentsCard
                        .animateEntry(isLoaded: isLoaded, index: 4)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, contentPadding)
                .padding(.bottom, cardSpacing)
                
                // ROW 4: TIME + CALENDAR (wide)
                HStack(alignment: .top, spacing: cardSpacing) {
                    timeCard
                        .animateEntry(isLoaded: isLoaded, index: 5)
                        .frame(maxWidth: .infinity)
                    
                    calendarCard
                        .animateEntry(isLoaded: isLoaded, index: 6)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, contentPadding)
                .padding(.bottom, bottomDockClearancePadding)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
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

    private struct DaySummary {
        let headline: String
        let energy: String
        let secondary: String
    }
    
    private struct DailyLoad: Identifiable {
        let id = UUID()
        let day: Date
        let totals: [AssignmentCategory: Int] // minutes per category
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

    private struct AssignmentLegendRow: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let color: Color
        let percentText: String?
    }

    private struct UpcomingAssignmentItem: Identifiable {
        let id: UUID
        let title: String
        let courseTitle: String
        let courseCode: String?
        let dueDate: Date?
        let hasExplicitDueTime: Bool
        let courseColor: Color
    }

    // ROW 1: STATUS STRIP (no card chrome - this is a HUD)
    private var statusStrip: some View {
        HStack(spacing: 24) {
            // Primary headline
            Text(statusHeadline)
                .font(.system(size: 28, weight: .semibold))
            
            Spacer()
            
            // Energy indicator (placeholder - can be enhanced later)
            Text(energyLevel)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Secondary info
            Text(statusSecondary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Status overview")
    }
    
    private var statusHeadline: String {
        let dueCount = tasksDueToday().count
        let plannedCount = assignmentsStore.tasks.filter { !$0.isCompleted && AssignmentPlansStore.shared.plan(for: $0.id) != nil }.count
        let scheduledMinutes = tasksDueToday().reduce(0) { $0 + $1.estimatedMinutes }
        
        return "Today: \(dueCount) due · \(plannedCount) planned · \(scheduledMinutes) min scheduled"
    }
    
    private var energyLevel: String {
        // Placeholder - can be enhanced with actual energy tracking
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "High Energy"
        } else if hour < 18 {
            return "Medium Energy"
        } else {
            return "Low Energy"
        }
    }
    
    private var statusSecondary: String {
        // Placeholder for semester progress or streak
        let totalAssignments = assignmentsStore.tasks.count
        let completedAssignments = assignmentsStore.tasks.filter { $0.isCompleted }.count
        if totalAssignments > 0 {
            let percentage = (Double(completedAssignments) / Double(totalAssignments)) * 100
            return "Progress: \(Int(percentage))%"
        }
        return "No assignments yet"
    }

    private var statusStripCard: some View {
        DashboardCard(
            title: "Today's Overview",
            isLoading: !isLoaded
        ) {
            HStack(spacing: 32) {
                // Due Today
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Due Today")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(tasksDueToday().count)")
                        .font(.system(size: 32, weight: .bold))
                        .contentTransition(.numericText())
                }
                
                Divider()
                
                // Events Today
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                        Text("Events Today")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(todaysCalendarEvents().count)")
                        .font(.system(size: 32, weight: .bold))
                        .contentTransition(.numericText())
                }
                
                Divider()
                
                // Total Assignments
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.purple)
                        Text("Active Assignments")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(assignmentsStore.tasks.filter { !$0.isCompleted }.count)")
                        .font(.system(size: 32, weight: .bold))
                        .contentTransition(.numericText())
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Status overview")
    }

    private var todayCard: some View {
        DashboardCard(
            title: "Status",
            isLoading: !isLoaded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today / Focus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                let dueToday = tasksDueToday().count
                Text("\(dueToday)")
                    .font(.system(size: 40, weight: .bold))
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Today overview")
    }

    private var workloadCard: some View {
        DashboardCard(
            title: "Weekly Workload",
            isLoading: !isLoaded
        ) {
            weeklyWorkloadChart
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekly workload forecast")
    }

    private var studyHoursCard: some View {
        DashboardCard(
            title: "Study Time Trend",
            isLoading: !isLoaded
        ) {
            studyTrendChart
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Study time trend")
    }
    
    private var calendarPermissionPrompt: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("Connect your calendar to see events")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Connect Calendar") {
                Task {
                    await calendarManager.requestAccess()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.small)
    }
    
    private var calendarAccessDeniedView: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            
            Text("Calendar access denied")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Open Settings") {
                calendarManager.openSystemPrivacySettings()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.small)
    }

    private var energyCard: some View {
        DashboardCard(
            title: "Assignment Status",
            isLoading: !isLoaded
        ) {
            assignmentStatusChart
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Assignment status breakdown")
    }

    private var eventsCard: some View {
        DashboardCard(
            title: "Upcoming Events",
            isLoading: !isLoaded
        ) {
            if events.isEmpty {
                DashboardEmptyState(
                    title: "No Events",
                    systemImage: "calendar.badge.plus",
                    description: "Add events to see them here",
                    action: { showAddEventSheet = true },
                    actionTitle: "Add Event"
                )
            } else {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    ForEach(events.prefix(5), id: \.id) { event in
                        eventRow(event)
                    }
                }
            }
        } header: {
            Button {
                showAddEventSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
            .font(.headline)
            .help("Add event")
        } footer: {
            if events.count > 5 {
                Button {
                    appModel.selectedPage = .calendar
                } label: {
                    HStack {
                        Text("View All Events (\(events.count))")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Upcoming events")
    }
    
    private func eventRow(_ event: DashboardEvent) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xsmall) {
                Text(event.title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack(spacing: DesignSystem.Spacing.xsmall) {
                    Text(event.time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let location = event.location {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                // Hover effect handled by system
            }
        }
        .contextMenu {
            Button {
                // View event details
                appModel.selectedPage = .calendar
            } label: {
                Label("View Details", systemImage: "eye")
            }
            
            Divider()
            
            Button {
                // Edit event
                showAddEventSheet = true
            } label: {
                Label("Edit Event", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                // Delete event
                if let index = events.firstIndex(where: { $0.id == event.id }) {
                    events.remove(at: index)
                }
            } label: {
                Label("Delete Event", systemImage: "trash")
            }
        }
    }

    private var assignmentsCard: some View {
        DashboardCard(
            title: "Upcoming Assignments",
            isLoading: !isLoaded
        ) {
            let items = upcomingAssignmentItems(limit: 6)
            if items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No upcoming assignments")
                        .font(.subheadline.weight(.semibold))
                    Text("Add an assignment to see it here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Add Assignment") {
                        showAddAssignmentSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(items) { item in
                        upcomingAssignmentRow(item)
                    }
                }
            }
        } header: {
            Button {
                showAddAssignmentSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
            .font(.headline)
            .help("Add assignment")
        } footer: {
            let total = upcomingAssignmentItems(limit: nil).count
            if total > 6 {
                Button {
                    appModel.selectedPage = .assignments
                } label: {
                    HStack {
                        Text("View All")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Assignments list")
    }

    private var weeklyWorkloadChart: some View {
        let buckets = weeklyWorkloadBuckets()
        return Chart(buckets) { item in
            BarMark(
                x: .value("Day", item.day, unit: .day),
                y: .value("Minutes", item.minutes)
            )
            .foregroundStyle(by: .value("Category", item.category.rawValue))
            .cornerRadius(6)
        }
        .chartForegroundStyleScale(
            domain: TaskType.allCases.map { $0.rawValue },
            range: TaskType.allCases.map { mutedCategoryColor($0) }
        )
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartLegend(position: .bottom, spacing: 8)
        .frame(height: 200)
    }
    
    private func mutedCategoryColor(_ category: TaskType) -> Color {
        switch category {
        case .reading: return .blue.opacity(0.5)
        case .homework: return .green.opacity(0.5)
        case .exam: return .red.opacity(0.5)
        case .quiz: return .orange.opacity(0.5)
        case .review: return .purple.opacity(0.4)
        case .project: return .teal.opacity(0.5)
        }
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
                            settings.activeAccentColor.opacity(0.3),
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

        return HStack(alignment: .center, spacing: DesignSystem.Spacing.large) {
            ZStack {
                Chart(items) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.618),
                        angularInset: 2.0
                    )
                    .foregroundStyle(item.color.opacity(0.85))
                    .cornerRadius(4)
                }
                .chartLegend(.hidden)

                VStack(spacing: 4) {
                    Text("\(total)")
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 150)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(assignmentStatusLegend(total: total)) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        Text(item.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(item.count)")
                            .font(.caption.weight(.semibold))
                        if let percent = item.percentText {
                            Text(percent)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
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
            AssignmentStatusItem(status: "Not Started", count: notStarted, color: .gray),
            AssignmentStatusItem(status: "In Progress", count: inProgress, color: .blue),
            AssignmentStatusItem(status: "Completed", count: completed, color: .green)
        ]
    }

    private func assignmentStatusLegend(total: Int) -> [AssignmentLegendRow] {
        let items = assignmentStatusItems()
        return items.map { item in
            let percentText: String?
            if total > 0 {
                let percent = Int((Double(item.count) / Double(total)) * 100)
                percentText = "\(percent)%"
            } else {
                percentText = nil
            }
            return AssignmentLegendRow(
                label: item.status,
                count: item.count,
                color: item.color,
                percentText: percentText
            )
        }
    }

    private func upcomingAssignments() -> [AppTask] {
        let now = Date()
        return assignmentsStore.tasks
            .filter { !$0.isCompleted }
            .compactMap { task -> AppTask? in
                guard let due = task.effectiveDueDateTime else { return nil }
                return due >= now ? task : nil
            }
            .sorted { lhs, rhs in
                let leftDue = lhs.effectiveDueDateTime ?? Date.distantFuture
                let rightDue = rhs.effectiveDueDateTime ?? Date.distantFuture
                if leftDue != rightDue {
                    return leftDue < rightDue
                }
                let leftCourse = courseTitle(for: lhs.courseId)
                let rightCourse = courseTitle(for: rhs.courseId)
                if leftCourse != rightCourse {
                    return leftCourse < rightCourse
                }
                return lhs.title < rhs.title
            }
    }

    private func upcomingAssignmentItems(limit: Int?) -> [UpcomingAssignmentItem] {
        let tasks = upcomingAssignments()
        let sliced = limit.map { Array(tasks.prefix($0)) } ?? tasks
        return sliced.map { task in
            let course = coursesStore.activeCourses.first(where: { $0.id == task.courseId })
            return UpcomingAssignmentItem(
                id: task.id,
                title: task.title,
                courseTitle: course?.title ?? "Unassigned",
                courseCode: course?.code,
                dueDate: task.effectiveDueDateTime,
                hasExplicitDueTime: task.hasExplicitDueTime,
                courseColor: gradeColor(for: course?.colorHex)
            )
        }
    }

    private func upcomingAssignmentRow(_ item: UpcomingAssignmentItem) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Circle()
                .fill(item.courseColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(item.courseCode?.isEmpty == false ? item.courseCode! : item.courseTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let dueDate = item.dueDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .abbreviated
                formatter.timeStyle = item.hasExplicitDueTime ? .short : .none
                Text(formatter.string(from: dueDate))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
            }
        }
    }

    private func courseTitle(for courseId: UUID?) -> String {
        guard let courseId,
              let course = coursesStore.activeCourses.first(where: { $0.id == courseId }) else {
            return ""
        }
        return course.title
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

        if totalsByDay.values.allSatisfy({ $0 <= 0 }) {
            studyTrend = []
            return
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
    
    private func assignmentRow(_ task: DashboardTask) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xsmall) {
                Text(task.title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .strikethrough(task.isDone)

                if let course = task.course {
                    Text(course)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xsmall)
        .padding(.horizontal, DesignSystem.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                // Hover effect handled by system
            }
        }
        .contextMenu {
            if !task.isDone {
                Button {
                    // Mark as complete
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        tasks[index].isDone = true
                    }
                } label: {
                    Label("Mark Complete", systemImage: "checkmark.circle")
                }
                
                Divider()
            }
            
            Button {
                // View assignment details
                appModel.selectedPage = .assignments
            } label: {
                Label("View Details", systemImage: "eye")
            }
            
            Button {
                // Edit assignment
                showAddAssignmentSheet = true
            } label: {
                Label("Edit Assignment", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                // Delete assignment
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks.remove(at: index)
                }
            } label: {
                Label("Delete Assignment", systemImage: "trash")
            }
        }
        .onTapGesture {
            // Quick complete on click
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                withAnimation(.spring(response: 0.3)) {
                    tasks[index].isDone.toggle()
                }
            }
        }
    }

    private var timeCard: some View {
        DashboardCard(
            title: "Time",
            isLoading: !isLoaded
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                NativeAnalogClock(diameter: 140, showDigitalTime: false)
                    .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Date(), style: .time)
                        .font(.title3.weight(.semibold))
                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Current time")
    }

    private var calendarCard: some View {
        DashboardCard(
            title: "Calendar",
            isLoading: !isLoaded
        ) {
            DashboardCalendarGrid(selectedDate: $selectedDate, events: events)
        } footer: {
            Button {
                appModel.selectedPage = .calendar
            } label: {
                HStack {
                    Text("Open Calendar")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Calendar overview")
    }



    private func quickActionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xsmall) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .frame(minHeight: 34)
        }
        .buttonStyle(.borderedProminent)
        .tint(.accentColor)
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

    private var dashboardTodayStats: some View {
        let eventsTodayCount = todaysCalendarEvents().count
        let dueToday = tasksDueToday().count
        
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            if eventsTodayCount == 0 && dueToday == 0 {
                DashboardEmptyState(
                    title: "All Clear",
                    systemImage: "checkmark.circle.fill",
                    description: "Nothing scheduled for today"
                )
            } else {
                DashboardStatRow(
                    label: "Events Today",
                    value: "\(eventsTodayCount)",
                    icon: "calendar",
                    valueColor: eventsTodayCount > 0 ? .blue : .secondary
                )
                
                DashboardStatRow(
                    label: "Tasks Due",
                    value: "\(dueToday)",
                    icon: "checkmark.circle",
                    valueColor: dueToday > 0 ? .orange : .secondary
                )
            }
        }
    }

    private func syncTasks() {
        let dueTodayTasks = tasksDueToday()
        tasks = dueTodayTasks.map { appTask in
            DashboardTask(title: appTask.title, course: appTask.courseId?.uuidString, isDone: appTask.isCompleted)
        }
    }

    private func syncEvents() {
        let todayEvents = todaysCalendarEvents()
        let mapped = todayEvents.map { event in
            DashboardEvent(
                title: event.title,
                time: "\(event.startDate.formatted(date: .omitted, time: .shortened)) – \(event.endDate.formatted(date: .omitted, time: .shortened))",
                location: event.location,
                date: event.startDate
            )
        }
        events = mapped.sorted { $0.date < $1.date }
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

    private enum EnergyLevel {
        case high, medium, low
    }
}

struct DashboardTileBody: View {
    let rows: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xsmall) {
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

private extension View {
    func animateEntry(isLoaded: Bool, index: Int) -> some View {
        self.staggeredEntry(isLoaded: isLoaded, index: index)
    }
}

// MARK: - Models for dashboard layout

struct DashboardTask: Identifiable {
    let id = UUID()
    var title: String
    var course: String?
    var isDone: Bool
}

struct DashboardEvent: Identifiable {
    let id = UUID()
    var title: String
    var time: String
    var location: String?
    var date: Date
}

// MARK: - Columns

private struct DashboardCalendarColumn: View {
    @Binding var selectedDate: Date
    var events: [DashboardEvent]
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.xsmall), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
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
            .padding(DesignSystem.Spacing.medium)
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
    private let columns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.xsmall), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
            // Month/year header
            Text(monthHeader(for: selectedDate))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            // Calendar grid - no nested card background
            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.xsmall) {
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

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("dashboard.assignments.due_today".localized)
                .rootsSectionHeader()

            if tasks.isEmpty {
                Text("dashboard.assignments.empty".localized)
                    .rootsBodySecondary()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        ForEach(tasks.indices, id: \.self) { index in
                            TaskRow(task: $tasks[index],
                                    showConnectorAbove: index != 0,
                                    showConnectorBelow: index != tasks.count - 1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(DesignSystem.Layout.padding.card)
        .rootsCardBackground(radius: 22)
    }
}

private struct DashboardEventsColumn: View {
    var events: [DashboardEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("dashboard.events.upcoming".localized)
                .rootsSectionHeader()

            if events.isEmpty {
                Text("dashboard.events.empty".localized)
                    .rootsBodySecondary()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        ForEach(events) { event in
                            HStack(alignment: .top, spacing: DesignSystem.Layout.spacing.small) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xsmall) {
                                    Text(event.title)
                                        .font(DesignSystem.Typography.body)
                                    Text(event.time)
                                        .rootsBodySecondary()
                                    if let location = event.location {
                                        Text(location)
                                            .rootsCaption()
                                    }
                                }
                                Spacer()
                            }
                            .padding(DesignSystem.Spacing.small)
                            .rootsCardBackground(radius: 18)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xsmall)
                }
            }
        }
        .padding(DesignSystem.Layout.padding.card)
        .background(DesignSystem.Materials.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Calendar Load Helpers


// MARK: - Task Row

private struct TaskRow: View {
    @Binding var task: DashboardTask
    var showConnectorAbove: Bool
    var showConnectorBelow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
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

                Button {
                    task.isDone.toggle()
                } label: {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.6), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(task.isDone ? Color.accentColor : Color.clear)
                        )
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.white)
                                .opacity(task.isDone ? 1.0 : 0.0)
                        )
                }
                .buttonStyle(.plain)
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xsmall) {
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
        .padding(DesignSystem.Spacing.small)
        .rootsCardBackground(radius: 18)
    }
}

// MARK: - Static Month Calendar

struct StaticMonthCalendarView: View {
    let currentDate: Date
    var events: [DashboardEvent] = []
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.xsmall), count: 7)

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

        return HStack(spacing: DesignSystem.Spacing.xsmall) {
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
            .padding(DesignSystem.Spacing.xsmall)
            .background(
                Circle()
                    .fill(isToday ? Color.accentColor.opacity(0.85) : Color.clear)
                    .background(
                        Circle().fill(Color(nsColor: .controlBackgroundColor).opacity(isToday ? 0.12 : 0.06))
                    )
            )
            .foregroundColor(isToday ? .white : .primary.opacity(0.7))
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
