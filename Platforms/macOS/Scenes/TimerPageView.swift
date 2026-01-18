#if os(macOS)
    import AppKit
    import Combine
    import SwiftUI

    // Type aliases for clarity
    typealias LocalTimerActivity = TimerActivity
    typealias LocalTimerSession = FocusSession
    typealias LocalTimerMode = TimerMode

    struct TimerPageView: View {
        @Environment(\.colorScheme) private var colorScheme
        @EnvironmentObject private var settings: AppSettingsModel
        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var calendarManager: CalendarManager
        @EnvironmentObject private var appModel: AppModel
        @EnvironmentObject private var settingsCoordinator: SettingsCoordinator
        @Environment(\.appLayout) private var appLayout

        @State private var mode: LocalTimerMode = .pomodoro
        @State private var activities: [LocalTimerActivity] = []
        @State private var selectedActivityID: UUID? = nil
        @State private var showActivityEditor: Bool = false
        @State private var editingActivity: LocalTimerActivity? = nil

        @State private var isRunning: Bool = false
        @State private var remainingSeconds: TimeInterval = 0
        @State private var elapsedSeconds: TimeInterval = 0
        @State private var pomodoroSessions: Int = 4
        @State private var completedPomodoroSessions: Int = 0
        @State private var isPomodorBreak: Bool = false
        @State private var sessions: [LocalTimerSession] = []
        @State private var loadedSessions = false
        @State private var tickCancellable: AnyCancellable?
        @State private var focusWindowController: NSWindowController? = nil
        @State private var focusWindowDelegate: FocusWindowDelegate? = nil
        @State private var currentBlockDuration: TimeInterval = 0
        @State private var countdownDuration: TimeInterval = 600 // Default 10 minutes

        private var collections: [String] {
            ["All"]
        }

        @State private var cachedPinnedActivities: [LocalTimerActivity] = []
        @State private var cachedFilteredActivities: [LocalTimerActivity] = []
        @State private var searchText: String = ""
        @State private var selectedCollection: String = "All"

        @State private var activityNotes: [UUID: String] = [:]

        @State private var taskSearchText: String = ""
        @State private var taskDateFilter: TaskDateFilter = .today
        @State private var taskStatusFilter: TaskStatusFilter = .due
        @State private var studyRange: StudyTimeRange = .thisWeek
        @State private var customRangeStart: Date = Calendar.current
            .date(byAdding: .day, value: -7, to: Date()) ?? Date()
        @State private var customRangeEnd: Date = .init()

        private enum TaskDateFilter: String, CaseIterable, Identifiable {
            case today, tomorrow, month, all

            var id: String { rawValue }
            var label: String {
                switch self {
                case .today: "Today"
                case .tomorrow: "Tomorrow"
                case .month: "Month"
                case .all: "All"
                }
            }
        }

        private enum TaskStatusFilter: String, CaseIterable, Identifiable {
            case due, inProgress, completed

            var id: String { rawValue }
            var label: String {
                switch self {
                case .due: "Due"
                case .inProgress: "In Progress"
                case .completed: "Completed"
                }
            }
        }

        enum StudyTimeRange: String, CaseIterable, Identifiable {
            case today, thisWeek, thisMonth, allTime, custom

            var id: String { rawValue }
            var label: String {
                switch self {
                case .today: "Today"
                case .thisWeek: "This Week"
                case .thisMonth: "This Month"
                case .allTime: "All Time"
                case .custom: "Date Range"
                }
            }
        }

        private var pinnedActivities: [LocalTimerActivity] {
            cachedPinnedActivities
        }

        private var filteredActivities: [LocalTimerActivity] {
            cachedFilteredActivities
        }

        private func updateCachedValues() {
            cachedPinnedActivities = activities.filter(\.isPinned)

            let query = searchText.lowercased()
            cachedFilteredActivities = activities.filter { activity in
                // Filter by name and collection
                (!activity.isPinned) &&
                    (activity.assignmentID != nil) && // Only show assignment-linked activities
                    (query.isEmpty || activity.name.lowercased().contains(query))
            }
        }

        private func startTickTimer() {
            stopTickTimer()

            tickCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    tick()
                }
        }

        private func stopTickTimer() {
            tickCancellable?.cancel()
            tickCancellable = nil
        }

        private func saveNotes(_: String, for _: UUID) {
            // Placeholder for persistence
        }

        // Minimal implementations for testing
        private func loadSessions() {
            // Placeholder for persistence
        }

        private func syncTimerWithAssignment() {
            // Placeholder for assignment sync
        }

        // MARK: - Subviews

        private var totalToday: TimeInterval {
            0
        }

        private var currentActivity: LocalTimerActivity? {
            activities.first(where: { $0.id == selectedActivityID }) ?? activities.first
        }

        private var selectedActivity: LocalTimerActivity? {
            currentActivity
        }

        private func formattedDuration(_ seconds: TimeInterval) -> String {
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            let secs = Int(seconds) % 60
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, secs)
            } else {
                return String(format: "%d:%02d", minutes, secs)
            }
        }

        private let cardCorner: CGFloat = DesignSystem.Layout.cornerRadiusStandard
        private let cardPadding: CGFloat = DesignSystem.Layout.padding.card

        private var topBar: some View {
            HStack(alignment: .center, spacing: DesignSystem.Layout.spacing.medium) {
                Spacer()
                // Top spacer only; time/date removed per request
                Spacer()
            }
            .frame(height: 24)
        }

        private func activityTasks(_ activityId: UUID) -> [AppTask]? {
            guard let activity = activities.first(where: { $0.id == activityId }) else { return nil }
            let normName = activity.name.lowercased()
            let tasks = assignmentsStore.tasks.filter { task in
                guard !task.isCompleted else { return false }
                let title = task.title.lowercased()
                return normName.contains(title) || title.contains(normName)
            }
            return tasks.isEmpty ? nil : tasks
        }

        private var mainGrid: some View {
            HStack(alignment: .top, spacing: DesignSystem.Layout.spacing.small) {
                // Left sidebar - Activities
                activitiesColumn
                    .frame(width: 280)

                // Right side - Timer and Study Summary
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                    timerCard
                    studySummaryCard
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }

        private var activitiesColumn: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text(NSLocalizedString("timer.label.activities", value: "Activities", comment: "Activities"))
                        .font(DesignSystem.Typography.subHeader)
                    Spacer()
                    Menu {
                        ForEach(TaskDateFilter.allCases) { filter in
                            Button(filter.label) { taskDateFilter = filter }
                        }
                    } label: {
                        Label(
                            String(
                                format: NSLocalizedString(
                                    "timer.filter.date_label",
                                    value: "Date: %@",
                                    comment: "Date filter label on timer"
                                ),
                                taskDateFilter.label
                            ),
                            systemImage: "calendar"
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    Menu {
                        ForEach(TaskStatusFilter.allCases) { filter in
                            Button(filter.label) { taskStatusFilter = filter }
                        }
                    } label: {
                        Label(
                            String(
                                format: NSLocalizedString(
                                    "timer.filter.status_label",
                                    value: "Status: %@",
                                    comment: "Status filter label on timer"
                                ),
                                taskStatusFilter.label
                            ),
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }

                TextField(
                    NSLocalizedString("timer.label.search", value: "Search", comment: "Search"),
                    text: $taskSearchText
                )
                .textFieldStyle(.roundedBorder)

                taskList
            }
            .padding(cardPadding)
            .glassCard(cornerRadius: cardCorner)
        }

        private var timerCard: some View {
            timerCoreCard
        }

        private var studySummaryCard: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.medium) {
                HStack {
                    Text(NSLocalizedString(
                        "timer.stats.study_summary",
                        value: "Study summary",
                        comment: "Study summary"
                    ))
                    .font(DesignSystem.Typography.subHeader)
                    Spacer()
                    Picker("", selection: $studyRange) {
                        ForEach(StudyTimeRange.allCases) { range in
                            Text(range.label).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 420)
                    .accessibilityLabel("Study time range")
                }

                if studyRange == .custom {
                    HStack(spacing: 12) {
                        DatePicker("From", selection: $customRangeStart, displayedComponents: .date)
                        DatePicker("To", selection: $customRangeEnd, displayedComponents: .date)
                    }
                    .font(.caption)
                }

                StudyTimeGraphView(
                    sessions: sessions,
                    range: studyRange,
                    customStart: customRangeStart,
                    customEnd: customRangeEnd
                )
                .frame(maxWidth: .infinity, minHeight: 260)
            }
            .frame(maxWidth: .infinity, minHeight: 400, alignment: .topLeading)
            .padding(cardPadding)
            .glassCard(cornerRadius: cardCorner)
        }

        private var collectionsFilter: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Layout.spacing.small) {
                    ForEach(collections, id: \.self) { collection in
                        let isSelected = selectedCollection == collection
                        Button(action: { selectedCollection = collection }) {
                            Text(collection)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? .accentTertiary : .secondaryBackground)
                                )
                                .overlay(
                                    Capsule().stroke(DesignSystem.Colors.neutralLine(for: colorScheme), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 32)
        }

        private var activityList: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if !cachedPinnedActivities.isEmpty {
                        Text(NSLocalizedString("timer.label.pinned", value: "Pinned", comment: "Pinned"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)

                        ForEach(cachedPinnedActivities) { activity in
                            activityRow(activity)
                        }
                    }

                    Text(NSLocalizedString(
                        "timer.label.all_activities",
                        value: "All activities",
                        comment: "All activities"
                    ))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)

                    ForEach(cachedFilteredActivities) { activity in
                        activityRow(activity)
                    }
                }
                .padding(.horizontal, 4)
            }
        }

        private var taskList: some View {
            let tasks = filteredTasks()
            return ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if tasks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checklist")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                            Text(NSLocalizedString(
                                "timer.tasks.empty.filtered",
                                value: "No tasks match this filter.",
                                comment: "Empty state for filtered tasks list"
                            ))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 160)
                    } else {
                        ForEach(tasks, id: \.id) { task in
                            taskRow(task)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }

        private func taskRow(_ task: AppTask) -> some View {
            Button(action: { toggleTaskCompletion(task) }) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.isCompleted ? .green : .secondary)
                        .font(.body)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)
                            .strikethrough(task.isCompleted)
                            .lineLimit(2)

                        if let due = task.due {
                            Text(due, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text(NSLocalizedString(
                                "timer.tasks.no_due_date",
                                value: "No due date",
                                comment: "Task row placeholder for missing due date"
                            ))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(8)
                .background(task.isCompleted ? .secondaryBackground.opacity(0.3) : .secondaryBackground)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }

        private func filteredTasks() -> [AppTask] {
            let calendar = Calendar.current
            let now = Date()
            let todayStart = calendar.startOfDay(for: now)
            let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? now
            let dayAfterStart = calendar.date(byAdding: .day, value: 2, to: todayStart) ?? now

            return assignmentsStore.tasks.filter { task in
                let matchesSearch: Bool = {
                    let query = taskSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    guard !query.isEmpty else { return true }
                    return task.title.lowercased().contains(query)
                }()

                guard matchesSearch else { return false }

                let matchesDate: Bool = {
                    guard let due = task.due else { return taskDateFilter == .all }
                    switch taskDateFilter {
                    case .today:
                        return due >= todayStart && due < tomorrowStart
                    case .tomorrow:
                        return due >= tomorrowStart && due < dayAfterStart
                    case .month:
                        return calendar.isDate(due, equalTo: now, toGranularity: .month)
                    case .all:
                        return true
                    }
                }()

                guard matchesDate else { return false }

                switch taskStatusFilter {
                case .completed:
                    return task.isCompleted
                case .due:
                    return !task.isCompleted && task.due != nil
                case .inProgress:
                    return !task.isCompleted && (task.due == nil || (task.due ?? now) > now)
                }
            }
            .sorted { lhs, rhs in
                (lhs.due ?? Date.distantFuture) < (rhs.due ?? Date.distantFuture)
            }
        }

        private func activityRow(_ activity: LocalTimerActivity) -> some View {
            Button(action: { selectedActivityID = activity.id }) {
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text(activity.name)
                        .font(DesignSystem.Typography.body)
                    Spacer()
                    if selectedActivityID == activity.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(8)
                .background(selectedActivityID == activity.id ? .accentQuaternary : .secondaryBackground)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }

        private var rightPane: some View {
            EmptyView()
        }

        private func taskCheckboxRow(_ task: AppTask) -> some View {
            Button(action: { toggleTaskCompletion(task) }) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.isCompleted ? .green : .secondary)
                        .font(.body)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)
                            .strikethrough(task.isCompleted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let due = task.due {
                            Text(due, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(6)
                .background(.secondaryBackground.opacity(0.3))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }

        private func tasksDueToday() -> [AppTask] {
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

            return assignmentsStore.tasks.filter { task in
                guard let due = task.due else { return false }
                return due >= today && due < tomorrow
            }
            .sorted { ($0.due ?? Date.distantFuture) < ($1.due ?? Date.distantFuture) }
        }

        private func tasksDueThisWeek() -> [AppTask] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

            // Get the end of this week (Sunday)
            let weekday = calendar.component(.weekday, from: today)
            let daysUntilEndOfWeek = 8 - weekday // Sunday = 1, so we want to reach the next Sunday
            let endOfWeek = calendar.date(byAdding: .day, value: daysUntilEndOfWeek, to: today)!

            return assignmentsStore.tasks.filter { task in
                guard let due = task.due else { return false }
                // Exclude today's tasks (already shown in "Due Today")
                return due >= tomorrow && due < endOfWeek
            }
            .sorted { ($0.due ?? Date.distantFuture) < ($1.due ?? Date.distantFuture) }
        }

        private func toggleTaskCompletion(_ task: AppTask) {
            var updatedTask = task
            updatedTask.isCompleted.toggle()
            assignmentsStore.updateTask(updatedTask)
        }

        @State private var showingModeMenu = false

        private var timerCoreCard: some View {
            GlassClockCard(cornerRadius: cardCorner, paddingAmount: 20) {
                VStack(spacing: 16) {
                    // Activity pill - shows only when activity is selected, with bounce animation
                    if let activity = currentActivity {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text(activity.name)
                                .font(DesignSystem.Typography.caption.weight(.medium))
                                .foregroundStyle(.primary)
                            // Course code display removed - courseID is UUID
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.accentQuaternary)
                        )
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedActivityID)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.caption)
                            Text(NSLocalizedString(
                                "timer.label.no_activity_selected",
                                value: "No activity selected",
                                comment: "No activity selected"
                            ))
                            .font(DesignSystem.Typography.caption)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }

                    if isRunning {
                        clockGlassContainer {
                            clockDisplayContent(isRunningState: true)
                        }
                        .overlay(alignment: .topLeading) {
                            Button(action: openFocusWindow) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(12)
                        }

                        // POMODORO CIRCLES - FIXED VERSION
                        Group {
                            if mode == .pomodoro {
                                HStack(spacing: 8) {
                                    ForEach(Array(0 ..< max(1, settings.pomodoroIterations)), id: \.self) { index in
                                        Circle()
                                            .fill(index < completedPomodoroSessions ? Color.accentColor : Color
                                                .secondary.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .id(settings.pomodoroIterations)
                            } else {
                                Color.clear.frame(height: 8)
                            }
                        }
                        .frame(height: 12)
                        .padding(.bottom, 4)

                        HStack(spacing: 18) {
                            Button(action: pauseTimer) {
                                Label {
                                    Text(NSLocalizedString("timer.pause", value: "Pause", comment: "Pause button"))
                                } icon: {
                                    Image(systemName: "pause.fill")
                                }
                                .font(.title2)
                            }
                            .buttonStyle(.itariLiquid)
                            .help("Pause the timer (it can be resumed)")
                            .accessibilityLabel("Pause timer")
                            .accessibilityHint("Pauses the running timer")

                            Button(action: resetTimer) {
                                Label {
                                    Text(NSLocalizedString("timer.stop", value: "Stop", comment: "Stop button"))
                                } icon: {
                                    Image(systemName: "stop.fill")
                                }
                                .font(.title2)
                            }
                            .buttonStyle(.itariLiquid)
                            .help("Stop and reset the timer")
                            .accessibilityLabel("Stop timer")
                            .accessibilityHint("Stops and resets the timer")
                        }
                    } else {
                        clockGlassContainer {
                            clockDisplayContent(isRunningState: false)
                        }
                        .overlay(alignment: .topLeading) {
                            Button(action: openFocusWindow) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(12)
                        }
                        .overlay(alignment: .topTrailing) {
                            Button(action: { showingModeMenu = true }) {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(12)
                            .popover(isPresented: $showingModeMenu, arrowEdge: .bottom) {
                                VStack(alignment: .leading, spacing: 8) {
                                    // Timer Mode section
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(NSLocalizedString(
                                            "timer.timer.mode",
                                            value: "Timer Mode",
                                            comment: "Timer Mode"
                                        ))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.top, 4)

                                        ForEach(
                                            [TimerMode.pomodoro, TimerMode.timer, TimerMode.stopwatch] as [TimerMode],
                                            id: \.self
                                        ) { timerMode in
                                            Button(action: {
                                                mode = timerMode
                                                showingModeMenu = false
                                            }) {
                                                HStack {
                                                    if mode == timerMode {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.accentColor)
                                                            .frame(width: 16)
                                                    } else {
                                                        Spacer().frame(width: 16)
                                                    }
                                                    Text(timerMode.displayName)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }

                                    Divider()
                                        .padding(.vertical, 4)

                                    // Appearance section
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(NSLocalizedString(
                                            "timer.appearance",
                                            value: "Appearance",
                                            comment: "Appearance"
                                        ))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)

                                        Button(action: {
                                            settings.timerAppearance = "digital"
                                            showingModeMenu = false
                                        }) {
                                            HStack {
                                                if settings.timerAppearance == "digital" {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.accentColor)
                                                        .frame(width: 16)
                                                } else {
                                                    Spacer().frame(width: 16)
                                                }
                                                Text(NSLocalizedString(
                                                    "timer.digital",
                                                    value: "Digital",
                                                    comment: "Digital"
                                                ))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: {
                                            settings.timerAppearance = "analog"
                                            showingModeMenu = false
                                        }) {
                                            HStack {
                                                if settings.timerAppearance == "analog" {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.accentColor)
                                                        .frame(width: 16)
                                                } else {
                                                    Spacer().frame(width: 16)
                                                }
                                                Text(NSLocalizedString(
                                                    "timer.analog",
                                                    value: "Analog",
                                                    comment: "Analog"
                                                ))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 8)
                                .frame(minWidth: 180)
                            }
                        }

                        // POMODORO CIRCLES - FIXED VERSION
                        Group {
                            if mode == .pomodoro {
                                HStack(spacing: 8) {
                                    ForEach(Array(0 ..< max(1, settings.pomodoroIterations)), id: \.self) { index in
                                        Circle()
                                            .fill(index < completedPomodoroSessions ? Color.accentColor : Color
                                                .accentColor.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .id(settings.pomodoroIterations)
                            } else {
                                Color.clear.frame(height: 8)
                            }
                        }
                        .frame(height: 12)
                        .padding(.bottom, 4)

                        Button(NSLocalizedString("timer.action.start", comment: "Start"), action: startTimer)
                            .buttonStyle(.itoriLiquidProminent)
                            .controlSize(.large)
                            .padding(.top, 4)
                    }
                }
            }
        }

        @ViewBuilder
        private func clockGlassContainer(@ViewBuilder content: () -> some View) -> some View {
            let strokeColor = DesignSystem.Colors.neutralLine(for: colorScheme).opacity(0.55)

            content()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.35 : 0.55),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        }

        @ViewBuilder
        private func clockDisplayContent(isRunningState _: Bool) -> some View {
            VStack(spacing: 8) {
                if settings.isTimerAnalog {
                    GeometryReader { proxy in
                        let availableWidth = max(proxy.size.width - 48, 0)
                        let dialSize = min(max(140, availableWidth / 3), 220)

                        TripleDialTimer(
                            totalSeconds: clockTimeForAnalog,
                            accentColor: .accentColor,
                            dialSize: dialSize
                        )
                        .frame(height: dialSize + 60)
                    }
                    .frame(height: 260)
                } else {
                    // Digital display
                    if mode == .pomodoro {
                        Text(isPomodorBreak ? "Break" : "Work")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    } else {
                        Text(mode.displayName)
                            .font(.headline.weight(.medium))
                    }

                    GeometryReader { proxy in
                        let base = min(proxy.size.width, proxy.size.height)
                        let size = max(88, min(base * 0.45, 220))
                        Text(timeDisplay)
                            .font(.system(size: size, weight: .light, design: .monospaced))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 220)
                }
            }
            .padding(.vertical, 12)
        }

        private var clockTimeForAnalog: TimeInterval {
            // Show elapsed time even when paused
            switch mode {
            case .stopwatch:
                elapsedSeconds
            case .pomodoro, .timer, .focus:
                max(0, currentBlockDuration - remainingSeconds)
            }
        }

        private var timeDisplay: String {
            switch mode {
            case .stopwatch:
                let h = Int(elapsedSeconds) / 3600
                let m = (Int(elapsedSeconds) % 3600) / 60
                let s = Int(elapsedSeconds) % 60
                if h > 0 {
                    return String(format: "%02d:%02d:%02d", h, m, s)
                } else {
                    return String(format: "%02d:%02d", m, s)
                }
            case .pomodoro, .timer, .focus:
                let m = Int(remainingSeconds) / 60
                let s = Int(remainingSeconds) % 60
                return String(format: "%02d:%02d", m, s)
            }
        }

        private func startTimer() {
            guard !isRunning else { return }
            if mode != .stopwatch && remainingSeconds == 0 {
                if mode == .timer {
                    remainingSeconds = countdownDuration
                    currentBlockDuration = countdownDuration
                } else {
                    remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
                    currentBlockDuration = remainingSeconds
                }
            } else if mode == .pomodoro || mode == .timer {
                currentBlockDuration = max(currentBlockDuration, remainingSeconds)
            }
            if mode == .stopwatch {
                currentBlockDuration = 0
            }
            isRunning = true
        }

        private func pauseTimer() {
            guard isRunning else { return }
            isRunning = false
            // Timer state (remainingSeconds/elapsedSeconds) should NOT be modified
            // They will resume from where they left off when startTimer() is called again
        }

        private func resetTimer() {
            isRunning = false
            elapsedSeconds = 0
            if mode == .timer {
                remainingSeconds = countdownDuration
                currentBlockDuration = countdownDuration
            } else {
                remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
                currentBlockDuration = remainingSeconds
            }
            isPomodorBreak = false
        }

        private func completeCurrentBlock() {
            isRunning = false
            switch mode {
            case .pomodoro:
                if isPomodorBreak {
                    isPomodorBreak = false
                    remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
                    currentBlockDuration = remainingSeconds
                } else {
                    isPomodorBreak = true
                    completedPomodoroSessions += 1
                    remainingSeconds = TimeInterval(settings.pomodoroShortBreakMinutes * 60)
                    currentBlockDuration = remainingSeconds
                }
            case .timer, .focus:
                remainingSeconds = countdownDuration
                currentBlockDuration = countdownDuration
            case .stopwatch:
                elapsedSeconds = 0
                currentBlockDuration = 0
            }
        }

        private func openFocusWindow() {
            // Singleton pattern: if Focus window already exists, bring it to front
            if let existing = focusWindowController, let win = existing.window {
                win.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            let tasks = selectedActivity.flatMap { activityTasks($0.id) } ?? []
            let focusView = FocusWindowView(
                mode: $mode,
                remainingSeconds: $remainingSeconds,
                elapsedSeconds: $elapsedSeconds,
                currentBlockDuration: $currentBlockDuration,
                completedPomodoroSessions: $completedPomodoroSessions,
                isPomodorBreak: $isPomodorBreak,
                isRunning: $isRunning,
                countdownDuration: $countdownDuration,
                accentColor: .accentColor,
                activity: selectedActivity,
                tasks: tasks,
                pomodoroSessions: settings.pomodoroIterations,
                toggleTask: { task in
                    var updated = task
                    updated.isCompleted.toggle()
                    assignmentsStore.updateTask(updated)
                },
                onStart: { startTimer() },
                onPause: { pauseTimer() },
                onReset: { resetTimer() }
            )
            let focusViewWithEnv = focusView
                .environmentObject(assignmentsStore)
                .environmentObject(settings)
            let hosting = NSHostingController(rootView: focusViewWithEnv)
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = NSWindow.StyleMask([.titled, .closable, .miniaturizable, .resizable])
            window.setContentSize(NSSize(width: 640, height: 480))
            window.center()
            window.title = NSLocalizedString("timer.focus.window_title", comment: "Focus")
            window.isReleasedWhenClosed = false

            let delegate = FocusWindowDelegate {
                // Window closed - clear the controller reference to allow reopening
                // Note: Can't use [weak self] because TimerPageView is a struct
                // The closure will be released when the delegate is deallocated
                focusWindowController = nil
                focusWindowDelegate = nil
            }
            window.delegate = delegate
            focusWindowDelegate = delegate

            window.makeKeyAndOrderFront(NSApp)
            focusWindowController = NSWindowController(window: window)
        }

        private func tick() {
            guard isRunning else { return }

            switch mode {
            case .pomodoro, .timer, .focus:
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    completeCurrentBlock()
                }
            case .stopwatch:
                elapsedSeconds += 1
            }
        }

        private var bottomSummary: some View {
            HStack {
                if let activity = currentActivity {
                    Text(String(
                        format: NSLocalizedString(
                            "timer.selected_activity.today",
                            value: "Selected: %@ • %@ today",
                            comment: "Selected activity summary with today's time"
                        ),
                        activity.name,
                        "N/A"
                    ))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }

        var body: some View {
            ScrollView {
                ZStack {
                    Color.primaryBackground.ignoresSafeArea()

                    VStack(spacing: 20) {
                        // Add topBar
                        topBar

                        // Add MINIMAL mainGrid (just text to start)
                        mainGrid

                        // Add bottomSummary
                        bottomSummary
                    }
                    .padding(.horizontal, ItariSpacing.pagePadding)
                    .padding(.top, appLayout.topContentInset)
                    .padding(.bottom, ItariSpacing.l)
                }
            }
            .onAppear {
                startTickTimer()
                updateCachedValues()
                pomodoroSessions = settings.pomodoroIterations
                if remainingSeconds == 0 {
                    remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
                    currentBlockDuration = remainingSeconds
                }
                if !loadedSessions {
                    loadSessions()
                    loadedSessions = true
                }
                syncTimerWithAssignment()
                applyFocusDeepLinkIfNeeded()
            }
            .onChange(of: activities) { _, _ in
                updateCachedValues()
            }
            .onChange(of: searchText) { _, _ in
                updateCachedValues()
            }
            .onChange(of: sessions) { _, _ in
                // persistSessions() - commented out for testing
            }
            .onChange(of: selectedActivityID) { _, _ in
                // syncTimerWithAssignment() - commented out for testing
            }
            .onChange(of: settings.pomodoroIterations) { _, newValue in
                pomodoroSessions = newValue
            }
            .onDisappear {
                stopTickTimer()
                isRunning = false
            }
        }

        private func applyFocusDeepLinkIfNeeded() {
            if let link = appModel.focusDeepLink {
                if let newMode = link.mode {
                    mode = newMode
                }
                if let activityId = link.activityId {
                    selectedActivityID = activityId
                }
                appModel.focusDeepLink = nil
            }
            if appModel.focusWindowRequested {
                appModel.focusWindowRequested = false
                openFocusWindow()
            }
        }
    }

    private struct StudyTimeGraphView: View {
        let sessions: [LocalTimerSession]
        let range: TimerPageView.StudyTimeRange
        let customStart: Date
        let customEnd: Date

        private struct StudyTimePoint: Identifiable {
            let id = UUID()
            let label: String
            let value: Double
        }

        var body: some View {
            let points = buildPoints()
            let maxValue = points.map(\.value).max() ?? 0

            if points.isEmpty || maxValue == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text(NSLocalizedString(
                        "timer.study_time.empty",
                        value: "No study time yet",
                        comment: "Empty state for study time graph"
                    ))
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { proxy in
                    let height = proxy.size.height - 28
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(points) { point in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.7))
                                    .frame(height: max(2, (point.value / maxValue) * height))
                                Text(point.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
        }

        private func buildPoints() -> [StudyTimePoint] {
            let calendar = Calendar.current
            let now = Date()

            switch range {
            case .today:
                let total = totalDuration(in: calendar.startOfDay(for: now) ... endOfDay(for: now, calendar: calendar))
                return [StudyTimePoint(label: "Today", value: total)]
            case .thisWeek:
                let start = calendar
                    .date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? calendar
                    .startOfDay(for: now)
                return (0 ..< 7).compactMap { offset in
                    guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
                    let label = calendar.shortWeekdaySymbols[(calendar.component(.weekday, from: day) - 1 + 7) % 7]
                    let value = totalDuration(in: calendar.startOfDay(for: day) ... endOfDay(
                        for: day,
                        calendar: calendar
                    ))
                    return StudyTimePoint(label: label, value: value)
                }
            case .thisMonth:
                guard let monthRange = calendar.range(of: .day, in: .month, for: now),
                      let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
                else { return [] }
                return monthRange.compactMap { day in
                    guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { return nil }
                    let value = totalDuration(in: calendar.startOfDay(for: date) ... endOfDay(
                        for: date,
                        calendar: calendar
                    ))
                    return StudyTimePoint(label: "\(day)", value: value)
                }
            case .allTime:
                let start = calendar.date(byAdding: .month, value: -11, to: calendar.startOfDay(for: now)) ?? calendar
                    .startOfDay(for: now)
                return (0 ..< 12).compactMap { offset in
                    guard let month = calendar.date(byAdding: .month, value: offset, to: start) else { return nil }
                    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
                    let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
                    let label = DateFormatter.cachedShortMonth.string(from: monthStart)
                    let value = totalDuration(in: monthStart ... monthEnd)
                    return StudyTimePoint(label: label, value: value)
                }
            case .custom:
                let start = calendar.startOfDay(for: customStart)
                let end = endOfDay(for: customEnd, calendar: calendar)
                let dayCount = calendar.dateComponents([.day], from: start, to: end).day ?? 0
                if dayCount > 14 {
                    let weeks = max(1, dayCount / 7)
                    return (0 ..< weeks).compactMap { index in
                        guard let weekStart = calendar.date(byAdding: .day, value: index * 7, to: start)
                        else { return nil }
                        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                        let label = "W\(index + 1)"
                        let value = totalDuration(in: weekStart ... weekEnd)
                        return StudyTimePoint(label: label, value: value)
                    }
                }
                return (0 ... dayCount).compactMap { offset in
                    guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
                    let label = "\(calendar.component(.day, from: day))"
                    let value = totalDuration(in: calendar.startOfDay(for: day) ... endOfDay(
                        for: day,
                        calendar: calendar
                    ))
                    return StudyTimePoint(label: label, value: value)
                }
            }
        }

        private func totalDuration(in range: ClosedRange<Date>) -> Double {
            sessions.reduce(0.0) { partial, session in
                guard let startDate = session.startedAt,
                      let endDate = session.endedAt
                else {
                    return partial
                }
                let overlaps = startDate <= range.upperBound && endDate >= range.lowerBound
                return overlaps ? partial + (session.actualDuration ?? 0) : partial
            }
        }

        private func endOfDay(for date: Date, calendar: Calendar) -> Date {
            let start = calendar.startOfDay(for: date)
            return calendar.date(byAdding: .day, value: 1, to: start) ?? date
        }
    }

    private extension DateFormatter {
        static let cachedShortMonth: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter
        }()
    }

    private struct FocusWindowView: View {
        @Binding var mode: LocalTimerMode
        @Binding var remainingSeconds: TimeInterval
        @Binding var elapsedSeconds: TimeInterval
        @Binding var currentBlockDuration: TimeInterval
        @Binding var completedPomodoroSessions: Int
        @Binding var isPomodorBreak: Bool
        @Binding var isRunning: Bool
        @Binding var countdownDuration: TimeInterval

        var accentColor: Color
        var activity: LocalTimerActivity?
        var tasks: [AppTask]
        var pomodoroSessions: Int
        var toggleTask: (AppTask) -> Void
        var onStart: () -> Void
        var onPause: () -> Void
        var onReset: () -> Void

        @EnvironmentObject private var settings: AppSettingsModel

        private var clockTime: TimeInterval {
            // When idle (not running), show the full duration for countdown
            guard isRunning else {
                if mode == .timer {
                    return countdownDuration
                }
                return 0
            }

            switch mode {
            case .stopwatch:
                return elapsedSeconds
            case .pomodoro:
                return max(0, currentBlockDuration - remainingSeconds)
            case .timer, .focus:
                return max(0, remainingSeconds) // Countdown shows remaining time
            }
        }

        var body: some View {
            GlassClockCard(cornerRadius: DesignSystem.Layout.cornerRadiusLarge) {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        if mode == .pomodoro {
                            Text(isPomodorBreak ? "Break" : "Work")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                        }

                        if mode == .timer && !isRunning {
                            // Duration selector for countdown mode
                            HStack(spacing: 12) {
                                ForEach([5, 10, 15, 20, 25, 30], id: \.self) { minutes in
                                    Button(action: {
                                        countdownDuration = TimeInterval(minutes * 60)
                                    }) {
                                        Text("\(minutes)m")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(countdownDuration == TimeInterval(minutes * 60) ? .white :
                                                .primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                countdownDuration == TimeInterval(minutes * 60) ? accentColor : Color
                                                    .secondary.opacity(0.2),
                                                in: Capsule()
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Clock/Timer display - ONLY difference between analog and digital
                        if settings.isTimerAnalog {
                            TripleDialTimer(
                                totalSeconds: clockTime,
                                accentColor: accentColor,
                                dialSize: 118
                            )
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 240, alignment: .center)
                        } else {
                            GeometryReader { proxy in
                                let base = min(proxy.size.width, proxy.size.height)
                                let size = max(96, min(base * 0.45, 220))
                                Text(timeText)
                                    .font(.system(size: size, weight: .light, design: .monospaced))
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                            .frame(height: 200)
                        }

                        if mode == .pomodoro {
                            HStack(spacing: 8) {
                                ForEach(Array(0 ..< max(1, pomodoroSessions)), id: \.self) { index in
                                    Circle()
                                        .fill(index < completedPomodoroSessions ? accentColor : Color.secondary
                                            .opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .id(pomodoroSessions)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabelWithTooltip(
                                "\(completedPomodoroSessions) of \(pomodoroSessions) completed"
                            )
                        } else {
                            Text(verbatim: "\(mode.displayName) running")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Timer control buttons
                    HStack(spacing: 12) {
                        if isRunning {
                            Button(action: onPause) {
                                Label(
                                    NSLocalizedString("timer.label.pause", value: "Pause", comment: "Pause"),
                                    systemImage: "pause.fill"
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.itariLiquid)
                            .controlSize(.large)
                            .keyboardShortcut(.space, modifiers: [])
                        } else {
                            Button(action: onStart) {
                                Label(
                                    remainingSeconds == 0 && mode != .stopwatch ? "Start" : "Resume",
                                    systemImage: "play.fill"
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.itoriLiquidProminent)
                            .controlSize(.large)
                            .keyboardShortcut(.space, modifiers: [])
                        }

                        Button(action: onReset) {
                            Label(
                                NSLocalizedString("timer.label.reset", value: "Reset", comment: "Reset"),
                                systemImage: "arrow.counterclockwise"
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.itariLiquid)
                        .controlSize(.large)
                        .keyboardShortcut("r", modifiers: [.command])
                    }
                    .padding(.horizontal, 8)

                    activityCard
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var activityCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString(
                    "timer.label.current_activity",
                    value: "Current activity",
                    comment: "Current activity"
                ))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                if let activity {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(activity.name)
                            .font(.title3.weight(.semibold))
                            .lineLimit(2)
                        // Course display removed - courseID is UUID, not display code

                        if tasks.isEmpty {
                            Text(NSLocalizedString("timer.focus.no_linked_tasks", comment: "No tasks"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(tasks, id: \.id) { task in
                                    Button {
                                        toggleTask(task)
                                    } label: {
                                        HStack {
                                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(task.isCompleted ? .green : .secondary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(task.title)
                                                    .font(.body)
                                                if let due = task.due {
                                                    Text(due, style: .date)
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                } else {
                    Text(NSLocalizedString(
                        "timer.label.no_activity_short",
                        value: "No activity",
                        comment: "No activity"
                    ))
                    .font(.body)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.secondaryBackground)
            )
        }

        private var timeText: String {
            switch mode {
            case .stopwatch:
                let h = Int(elapsedSeconds) / 3600
                let m = (Int(elapsedSeconds) % 3600) / 60
                let s = Int(elapsedSeconds) % 60
                if h > 0 {
                    return String(format: "%02d:%02d:%02d", h, m, s)
                } else {
                    return String(format: "%02d:%02d", m, s)
                }
            case .pomodoro, .timer, .focus:
                let m = Int(remainingSeconds) / 60
                let s = Int(remainingSeconds) % 60
                return String(format: "%02d:%02d", m, s)
            }
        }
    }

    private class FocusWindowDelegate: NSObject, NSWindowDelegate {
        let onClose: () -> Void

        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }

        func windowWillClose(_: Notification) {
            onClose()
        }
    }
#endif
