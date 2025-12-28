#if os(macOS)
import SwiftUI
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

    // Layout tokens
    private let cardSpacing: CGFloat = DesignSystem.Spacing.large
    private let contentPadding: CGFloat = DesignSystem.Spacing.large
    private let bottomDockClearancePadding: CGFloat = 100

    var body: some View {
        // HIG-compliant adaptive dashboard grid
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 300, maximum: 600), spacing: cardSpacing)
                ],
                spacing: cardSpacing
            ) {
                todayCard
                    .animateEntry(isLoaded: isLoaded, index: 0)

                clockAndCalendarCard
                    .animateEntry(isLoaded: isLoaded, index: 1)

                eventsCard
                    .animateEntry(isLoaded: isLoaded, index: 2)

                assignmentsCard
                    .animateEntry(isLoaded: isLoaded, index: 3)

                if settings.showEnergyPanel {
                    energyCard
                        .animateEntry(isLoaded: isLoaded, index: 4)
                }
                
                if settings.trackStudyHours {
                    studyHoursCard
                        .animateEntry(isLoaded: isLoaded, index: 5)
                }
            }
            .padding(contentPadding)
            .padding(.bottom, bottomDockClearancePadding)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showAddAssignmentSheet) {
            AddAssignmentView(initialType: .practiceHomework) { task in
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

    private var todayCard: some View {
        DashboardCard(
            title: "Today",
            systemImage: "sun.max.fill",
            isLoading: !isLoaded
        ) {
            let eventStatus = calendarManager.eventAuthorizationStatus
            
            if eventStatus == .notDetermined {
                calendarPermissionPrompt
            } else if eventStatus == .denied || eventStatus == .restricted {
                calendarAccessDeniedView
            } else {
                dashboardTodayStats
            }
        } footer: {
            HStack(spacing: DesignSystem.Spacing.small) {
                Button {
                    showAddAssignmentSheet = true
                } label: {
                    Label("Add Assignment", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button {
                    showAddEventSheet = true
                } label: {
                    Label("Add Event", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Today overview")
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
            title: "Energy & Focus",
            systemImage: "bolt.heart.fill",
            isLoading: !isLoaded
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Optimize your study schedule by setting your current energy level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: DesignSystem.Spacing.small) {
                    energyButton("High", level: .high, icon: "bolt.fill", color: .green)
                    energyButton("Medium", level: .medium, icon: "bolt", color: .orange)
                    energyButton("Low", level: .low, icon: "bolt.slash", color: .red)
                }
            }
        } footer: {
            Button {
                appModel.selectedPage = .planner
            } label: {
                HStack {
                    Text("Open Planner")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Energy and focus settings")
    }

    @ViewBuilder
    private func energyButton(_ title: String, level: EnergyLevel, icon: String, color: Color) -> some View {
        Button {
            setEnergy(level)
        } label: {
            VStack(spacing: DesignSystem.Spacing.xsmall) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.medium)
        }
        .buttonStyle(.bordered)
        .help("Set energy level to \(title.lowercased())")
    }
    
    // MARK: - Study Hours Card
    
    @ObservedObject private var tracker = StudyHoursTracker.shared
    
    private var studyHoursCard: some View {
        DashboardCard(
            title: "Study Hours",
            systemImage: "clock.fill",
            isLoading: !isLoaded
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                DashboardStatRow(
                    label: "Today",
                    value: StudyHoursTotals.formatMinutes(tracker.totals.todayMinutes),
                    icon: "sun.max.fill",
                    valueColor: .blue
                )
                
                DashboardStatRow(
                    label: "This Week",
                    value: StudyHoursTotals.formatMinutes(tracker.totals.weekMinutes),
                    icon: "calendar.badge.clock",
                    valueColor: .blue
                )
                
                DashboardStatRow(
                    label: "This Month",
                    value: StudyHoursTotals.formatMinutes(tracker.totals.monthMinutes),
                    icon: "calendar",
                    valueColor: .blue
                )
            }
        } footer: {
            Button {
                appModel.selectedPage = .timer
            } label: {
                HStack {
                    Text("View Details")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Study hours summary")
    }

    private var eventsCard: some View {
        DashboardCard(
            title: "Upcoming Events",
            systemImage: "calendar",
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
            title: "Assignments",
            systemImage: "doc.text.fill",
            isLoading: !isLoaded
        ) {
            if tasks.isEmpty {
                DashboardEmptyState(
                    title: "No Assignments",
                    systemImage: "doc.badge.plus",
                    description: "Create your first assignment",
                    action: { showAddAssignmentSheet = true },
                    actionTitle: "Add Assignment"
                )
            } else {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    ForEach(tasks.prefix(5), id: \.id) { task in
                        assignmentRow(task)
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
            if tasks.count > 5 {
                Button {
                    appModel.selectedPage = .assignments
                } label: {
                    HStack {
                        Text("View All Assignments (\(tasks.count))")
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
    
    private func assignmentRow(_ task: DashboardTask) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundStyle(task.isDone ? .green : .secondary)
            
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

    private var clockAndCalendarCard: some View {
        DashboardCard(
            title: "Time",
            systemImage: "clock.fill",
            isLoading: !isLoaded
        ) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.large) {
                // Analog clock
                VStack(spacing: DesignSystem.Spacing.small) {
                    NativeAnalogClock(diameter: 120, showDigitalTime: false)
                        .frame(width: 120, height: 120)
                    
                    Text(Date(), style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                
                // Mini calendar
                DashboardCalendarGrid(
                    selectedDate: $selectedDate,
                    events: events
                )
                .frame(maxWidth: .infinity)
            }
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
        .accessibilityLabel("Current time and calendar")
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

