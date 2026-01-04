//
//  IOSDashboardView.swift
//  Itori (iOS)
//

#if os(iOS)
import SwiftUI
import EventKit
import Charts

struct IOSDashboardView: View {
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var deviceCalendar: DeviceCalendarManager
    @EnvironmentObject private var settings: AppSettingsModel
    @EnvironmentObject private var sheetRouter: IOSSheetRouter
    @EnvironmentObject private var navigation: IOSNavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var plannerStore = PlannerStore.shared
    @ObservedObject private var calendarAuth = CalendarAuthorizationManager.shared

    @State private var selectedDate = Date()
    @AppStorage("dashboard.greeting.dateKey") private var greetingDateKey: String = ""
    @AppStorage("dashboard.greeting.text") private var storedGreeting: String = ""

    private let calendar = Calendar.current
    
    private var shouldShowProductivityInsights: Bool {
        settings.trackStudyHours && settings.showProductivityInsights
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    heroHeader
                    quickStatsRow
                    
                    // Study hours card (Phase D)
                    if shouldShowProductivityInsights {
                        studyHoursCard
                    }
                    
                    upcomingEventsCard

                    if isWideLayout {
                        HStack(alignment: .top, spacing: 16) {
                            assignmentStatusCard
                            upcomingAssignmentsCard
                        }
                    } else {
                        assignmentStatusCard
                        upcomingAssignmentsCard
                    }

                    if isWideLayout {
                        HStack(alignment: .top, spacing: 16) {
                            plannerTodayCard
                            workRemainingCard
                        }
                        calendarCard
                    } else {
                        plannerTodayCard
                        workRemainingCard
                        calendarCard
                    }
                }
                .frame(maxWidth: min(720, proxy.size.width - 32))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 36)
            }
        }
        .background(DesignSystem.Colors.appBackground.ignoresSafeArea())
        .task {
            await deviceCalendar.bootstrapOnLaunch()
        }
    }

    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.24, blue: 0.32),
                            Color(red: 0.08, green: 0.18, blue: 0.26)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                Text(greeting)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))

                HStack(spacing: 10) {
                    Label("\(todayEventCount) events", systemImage: "calendar")
                    Label("\(todayTaskCount) tasks", systemImage: "checkmark.circle")
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 4)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            statPill(title: NSLocalizedString("ios.dashboard.stats.due_soon", comment: "Due Soon"), value: "\(dueSoonTasks.count)", icon: "bolt")
            statPill(title: NSLocalizedString("ios.dashboard.stats.next_7_days", comment: "Next 7 Days"), value: "\(weekEventCount)", icon: "calendar.badge.clock")
            statPill(title: NSLocalizedString("ios.dashboard.stats.courses", comment: "Courses"), value: "\(coursesStore.activeCourses.count)", icon: "square.grid.2x2")
        }
    }

    private var weekStrip: some View {
        HStack(spacing: 10) {
            ForEach(weekDays, id: \.self) { day in
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                Button {
                    selectedDate = day
                } label: {
                    VStack(spacing: 6) {
                        Text(weekdaySymbol(for: day))
                            .font(.caption2.weight(.semibold))
                        Text(dayNumber(for: day))
                            .font(.callout.weight(.semibold))
                    }
                    .frame(width: 42, height: 56)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isSelected ? Color.accentColor : Color.white.opacity(0.7))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DesignSystem.Materials.hud)
        )
    }
    
    // MARK: - Study Hours Card (Phase D)
    
    @ObservedObject private var tracker = StudyHoursTracker.shared
    
    private var studyHoursCard: some View {
        RootsCard(
            title: NSLocalizedString("ios.dashboard.study_hours.title", value: "Study Hours", comment: "Study hours card title"),
            subtitle: NSLocalizedString("ios.dashboard.study_hours.subtitle", value: "Your progress", comment: "Study hours card subtitle"),
            icon: "clock.fill"
        ) {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    studyHoursStat(
                        label: NSLocalizedString("ios.dashboard.study_hours.today", value: "Today", comment: "Today label"),
                        value: StudyHoursTotals.formatMinutes(tracker.totals.todayMinutes)
                    )
                    
                    studyHoursStat(
                        label: NSLocalizedString("ios.dashboard.study_hours.week", value: "This Week", comment: "This week label"),
                        value: StudyHoursTotals.formatMinutes(tracker.totals.weekMinutes)
                    )
                    
                    studyHoursStat(
                        label: NSLocalizedString("ios.dashboard.study_hours.month", value: "This Month", comment: "This month label"),
                        value: StudyHoursTotals.formatMinutes(tracker.totals.monthMinutes)
                    )
                }
            }
            .frame(minHeight: 80)
        }
    }
    
    private func studyHoursStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.accentColor)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var upcomingEventsCard: some View {
        RootsCard(title: NSLocalizedString("ios.dashboard.upcoming.title", comment: "Upcoming"), subtitle: NSLocalizedString("ios.dashboard.upcoming.subtitle", comment: "From your calendar"), icon: "calendar") {
            Group {
                if calendarAuth.isDenied {
                    CalendarAccessBanner(
                        title: "Calendar access is off",
                        message: "Enable access to show events and allow scheduling.",
                        actionTitle: "Open Settings",
                        action: { calendarAuth.openSettings() }
                    )
                } else if calendarAuth.isNotDetermined {
                    CalendarAccessBanner(
                        title: "Calendar access is off",
                        message: "Enable access to show events and allow scheduling.",
                        actionTitle: "Allow Access",
                        action: {
                            Task { _ = await deviceCalendar.requestFullAccessIfNeeded() }
                        }
                    )
                } else if upcomingEvents.isEmpty {
                    Text(NSLocalizedString("ios.dashboard.upcoming.no_events", comment: "No events"))
                        .rootsBodySecondary()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(upcomingEvents.prefix(4), id: \.eventIdentifier) { event in
                            HStack(alignment: .top, spacing: 12) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.7))
                                    .frame(width: 6)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.body.weight(.medium))
                                    Text(eventTimeRange(event))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 120)
        }
    }

    private var assignmentStatusCard: some View {
        RootsCard(title: nil, subtitle: nil, icon: nil) {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Assignment Status")
                assignmentStatusChart
            }
        }
    }

    private var upcomingAssignmentsCard: some View {
        RootsCard(title: nil, subtitle: nil, icon: nil) {
            let items = upcomingAssignmentItems(limit: 6)
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Upcoming Assignments", trailing: AnyView(
                    Button {
                        presentAddAssignment()
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .buttonStyle(.plain)
                ))

                if items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No upcoming assignments")
                            .font(.subheadline.weight(.semibold))
                        Text("Add an assignment to see it here.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Add Assignment") {
                            presentAddAssignment()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } else {
                    ForEach(items) { item in
                        upcomingAssignmentRow(item)
                    }
                }

                if upcomingAssignmentItems(limit: nil).count > 6 {
                    HStack {
                        Spacer()
                        Button("View All") {
                            openAssignments()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var plannerTodayCard: some View {
        RootsCard(title: "Today", subtitle: "Planner", icon: "list.bullet.rectangle") {
            let sessions = plannerSessionsToday
            if sessions.isEmpty {
                Text("No planned tasks today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sessions.prefix(4), id: \.id) { session in
                        plannerSessionRow(session)
                    }
                }
            }
        }
    }

    private var workRemainingCard: some View {
        RootsCard(title: "Remaining", subtitle: "Today", icon: "chart.bar.fill") {
            let snapshot = remainingWorkSnapshot
            if snapshot.plannedMinutes <= 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("—")
                        .font(.system(size: 32, weight: .bold))
                    Text("No plan time available yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(snapshot.remainingPercent)%")
                        .font(.system(size: 32, weight: .bold))
                    Text("\(snapshot.remainingMinutes) min remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(snapshot.completedMinutes) min completed")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func presentAddAssignment() {
        let defaults = IOSSheetRouter.TaskDefaults(
            courseId: nil,
            dueDate: Date(),
            title: "",
            type: .homework,
            itemLabel: NSLocalizedString("ios.item.assignment", value: "Assignment", comment: "Assignment")
        )
        sheetRouter.activeSheet = .addAssignment(defaults)
    }

    private func openAssignments() {
        navigation.open(page: .assignments, starredTabs: settings.starredTabs)
    }

    private var calendarCard: some View {
        RootsCard(title: "Calendar", subtitle: "This week", icon: "calendar") {
            VStack(alignment: .leading, spacing: 12) {
                weekStrip
                if eventsForSelectedDate.isEmpty {
                    Text("No events on this day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(eventsForSelectedDate.prefix(3), id: \.eventIdentifier) { event in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.7))
                                .frame(width: 6, height: 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.caption.weight(.semibold))
                                Text(eventTimeRange(event))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func statPill(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DesignSystem.Materials.card)
        )
    }

    private func cardHeader(title: String, trailing: AnyView? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .rootsSectionHeader()
            Spacer()
            if let trailing {
                trailing
            }
        }
    }

    private var backgroundView: some View {
        DesignSystem.Colors.appBackground
    }

    private var greeting: String {
        let todayKey = dateKey(for: Date())
        if greetingDateKey == todayKey, !storedGreeting.isEmpty {
            return storedGreeting
        }

        let hour = calendar.component(.hour, from: Date())
        let greetings: [String]

        switch hour {
        case 5..<12:
            greetings = [
                NSLocalizedString("ios.dashboard.greeting.morning.1", comment: "Good morning"),
                NSLocalizedString("ios.dashboard.greeting.morning.2", comment: "Rise and shine"),
                NSLocalizedString("ios.dashboard.greeting.morning.3", comment: "Morning"),
                NSLocalizedString("ios.dashboard.greeting.morning.4", comment: "Start strong today"),
                NSLocalizedString("ios.dashboard.greeting.morning.5", comment: "Welcome back")
            ]
        case 12..<17:
            greetings = [
                NSLocalizedString("ios.dashboard.greeting.afternoon.1", comment: "Good afternoon"),
                NSLocalizedString("ios.dashboard.greeting.afternoon.2", comment: "Afternoon"),
                NSLocalizedString("ios.dashboard.greeting.afternoon.3", comment: "Keep it up"),
                NSLocalizedString("ios.dashboard.greeting.afternoon.4", comment: "Stay focused"),
                NSLocalizedString("ios.dashboard.greeting.afternoon.5", comment: "Making progress")
            ]
        case 17..<22:
            greetings = [
                NSLocalizedString("ios.dashboard.greeting.evening.1", comment: "Good evening"),
                NSLocalizedString("ios.dashboard.greeting.evening.2", comment: "Evening"),
                NSLocalizedString("ios.dashboard.greeting.evening.3", comment: "Wrapping up"),
                NSLocalizedString("ios.dashboard.greeting.evening.4", comment: "Almost there"),
                NSLocalizedString("ios.dashboard.greeting.evening.5", comment: "Finish strong")
            ]
        default:
            greetings = [
                NSLocalizedString("ios.dashboard.greeting.night.1", comment: "Hello"),
                NSLocalizedString("ios.dashboard.greeting.night.2", comment: "Welcome back"),
                NSLocalizedString("ios.dashboard.greeting.night.3", comment: "Still working"),
                NSLocalizedString("ios.dashboard.greeting.night.4", comment: "Burning the midnight oil")
            ]
        }

        let selection = greetings.randomElement() ?? NSLocalizedString("ios.dashboard.greeting.default", comment: "Hello")
        greetingDateKey = todayKey
        storedGreeting = selection
        return selection
    }

    private func dateKey(for date: Date) -> String {
        let cutoffHour = 4
        let adjustedDate = calendar.date(byAdding: .hour, value: -cutoffHour, to: date) ?? date
        let comps = calendar.dateComponents([.year, .month, .day], from: adjustedDate)
        let year = comps.year ?? 0
        let month = comps.month ?? 0
        let day = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private var formattedDate: String {
        LocaleFormatters.fullDate.string(from: Date())
    }

    private var todayEventCount: Int {
        filteredCalendarEvents.filter { calendar.isDateInToday($0.startDate) }.count
    }

    private var todayTaskCount: Int {
        assignmentsStore.tasks.filter { task in
            guard let due = task.due else { return false }
            return calendar.isDateInToday(due) && !task.isCompleted
        }.count
    }

    private var upcomingEvents: [EKEvent] {
        let now = Date()
        return filteredCalendarEvents
            .filter { $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }
    }

    private var weekEventCount: Int {
        let now = Date()
        let end = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        return filteredCalendarEvents.filter { $0.startDate >= now && $0.startDate <= end }.count
    }

    private var filteredCalendarEvents: [EKEvent] {
        let selectedID = settings.selectedSchoolCalendarID
        guard !selectedID.isEmpty else {
            return deviceCalendar.events
        }
        return deviceCalendar.events.filter { $0.calendar.calendarIdentifier == selectedID }
    }

    private var dueSoonTasks: [AppTask] {
        let now = Date()
        let end = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        return assignmentsStore.tasks
            .filter { !$0.isCompleted }
            .compactMap { task -> AppTask? in
                guard let due = task.effectiveDueDateTime else { return nil }
                return (due >= now && due <= end) ? task : nil
            }
            .sorted { ($0.effectiveDueDateTime ?? Date.distantFuture) < ($1.effectiveDueDateTime ?? Date.distantFuture) }
    }

    private var upcomingAssignments: [AppTask] {
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
                let leftCourse = courseName(for: lhs.courseId) ?? ""
                let rightCourse = courseName(for: rhs.courseId) ?? ""
                if leftCourse != rightCourse {
                    return leftCourse < rightCourse
                }
                return lhs.title < rhs.title
            }
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

    private func assignmentStatusLegend(total: Int) -> [AssignmentLegendRow] {
        assignmentStatusItems().map { item in
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

    private var assignmentStatusChart: some View {
        let items = assignmentStatusItems()
        let total = items.reduce(0) { $0 + $1.count }

        return HStack(alignment: .center, spacing: 16) {
            ZStack {
                Chart(items) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color.opacity(0.85))
                }
                .chartLegend(.hidden)

                VStack(spacing: 2) {
                    Text("\(total)")
                        .font(.headline.weight(.bold))
                    Text("Total")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 8) {
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

    private func upcomingAssignmentItems(limit: Int?) -> [UpcomingAssignmentItem] {
        let tasks = upcomingAssignments
        let sliced = limit.map { Array(tasks.prefix($0)) } ?? tasks
        return sliced.map { task in
            let course = coursesStore.courses.first(where: { $0.id == task.courseId })
            return UpcomingAssignmentItem(
                id: task.id,
                title: task.title,
                courseTitle: course?.title ?? "Unassigned",
                courseCode: course?.code,
                dueDate: task.effectiveDueDateTime,
                hasExplicitDueTime: task.hasExplicitDueTime,
                courseColor: courseColor(for: course?.colorHex)
            )
        }
    }

    private func upcomingAssignmentRow(_ item: UpcomingAssignmentItem) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(item.courseColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(item.courseCode?.isEmpty == false ? item.courseCode! : item.courseTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let dueDate = item.dueDate {
                Text(formattedDueDate(dueDate, hasExplicitTime: item.hasExplicitDueTime))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.12))
                    )
            }
        }
    }

    private var eventsForSelectedDate: [EKEvent] {
        filteredCalendarEvents.filter { calendar.isDate($0.startDate, inSameDayAs: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    private func courseColor(for hex: String?) -> Color {
        if let hex, let color = Color(hex: hex) {
            return color
        }
        return Color.accentColor
    }

    private var weekDays: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekInterval.start)
        }
    }

    private func weekdaySymbol(for date: Date) -> String {
        LocaleFormatters.shortDayName.string(from: date).uppercased()
    }

    private func dayNumber(for date: Date) -> String {
        LocaleFormatters.dayOfMonth.string(from: date)
    }

    private func eventTimeRange(_ event: EKEvent) -> String {
        let formatter = LocaleFormatters.shortTime
        return "\(formatter.string(from: event.startDate))-\(formatter.string(from: event.endDate))"
    }

    private var plannerSessionsToday: [StoredScheduledSession] {
        let cal = Calendar.current
        return plannerStore.scheduled
            .filter { cal.isDateInToday($0.start) }
            .sorted {
                if $0.start != $1.start {
                    return $0.start < $1.start
                }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
    }

    private func plannerSessionRow(_ session: StoredScheduledSession) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(session.isUserEdited ? Color.orange : Color.accentColor)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(timeRangeText(for: session))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func timeRangeText(for session: StoredScheduledSession) -> String {
        let formatter = LocaleFormatters.shortTime
        return "\(formatter.string(from: session.start)) – \(formatter.string(from: session.end))"
    }

    private struct RemainingWorkSnapshot {
        let plannedMinutes: Int
        let completedMinutes: Int
        let remainingMinutes: Int
        let remainingPercent: Int
    }

    private var remainingWorkSnapshot: RemainingWorkSnapshot {
        let plannedMinutes = plannedMinutesForToday()
        let studiedMinutes = tracker.totals.todayMinutes
        guard plannedMinutes > 0 else {
            return RemainingWorkSnapshot(
                plannedMinutes: 0,
                completedMinutes: 0,
                remainingMinutes: 0,
                remainingPercent: 0
            )
        }

        let completed = min(studiedMinutes, plannedMinutes)
        let remaining = max(plannedMinutes - studiedMinutes, 0)
        let remainingPct = Int((1.0 - min(Double(studiedMinutes) / Double(plannedMinutes), 1.0)) * 100.0)
        return RemainingWorkSnapshot(
            plannedMinutes: plannedMinutes,
            completedMinutes: completed,
            remainingMinutes: remaining,
            remainingPercent: remainingPct
        )
    }

    private func plannedMinutesForToday() -> Int {
        let sessions = plannerSessionsToday.filter { session in
            session.type == .task || session.type == .study
        }
        let sessionMinutes = sessions.reduce(0) { $0 + max($1.estimatedMinutes, 0) }
        if sessionMinutes > 0 {
            return sessionMinutes
        }
        return assignmentsStore.tasks
            .filter { !$0.isCompleted }
            .filter { task in
                guard let due = task.due else { return false }
                return Calendar.current.isDateInToday(due)
            }
            .reduce(0) { $0 + max($1.estimatedMinutes, 0) }
    }

    private func formatDueDisplay(for task: AppTask) -> String {
        guard let due = task.due else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = task.hasExplicitDueTime ? .short : .none
        let dateText = formatter.string(from: task.hasExplicitDueTime ? (task.effectiveDueDateTime ?? due) : due)
        return dateText
    }
    
    private func formattedDueDate(_ date: Date, hasExplicitTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = hasExplicitTime ? .short : .none
        return formatter.string(from: date)
    }

    private func courseName(for id: UUID?) -> String? {
        guard let id else { return nil }
        if let course = coursesStore.courses.first(where: { $0.id == id }) {
            return course.code.isEmpty ? course.title : course.code
        }
        return nil
    }
}

#endif
