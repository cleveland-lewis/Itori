#if os(macOS)
import SwiftUI
import Combine
import AppKit

struct TimerPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: AppSettingsModel
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var calendarManager: CalendarManager
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var settingsCoordinator: SettingsCoordinator
    
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
    
    private var collections: [String] {
        var set: Set<String> = ["All"]
        set.formUnion(activities.map { $0.category })
        return Array(set).sorted()
    }
    
    @State private var cachedPinnedActivities: [LocalTimerActivity] = []
    @State private var cachedFilteredActivities: [LocalTimerActivity] = []
    @State private var searchText: String = ""
    @State private var selectedCollection: String = "All"
    
    @State private var activityNotes: [UUID: String] = [:]
    
    private var pinnedActivities: [LocalTimerActivity] {
        cachedPinnedActivities
    }
    
    private var filteredActivities: [LocalTimerActivity] {
        cachedFilteredActivities
    }
    
    private func updateCachedValues() {
        cachedPinnedActivities = activities.filter { $0.isPinned }
        
        let query = searchText.lowercased()
        cachedFilteredActivities = activities.filter { activity in
            (!activity.isPinned) &&
            (selectedCollection == "All" || activity.category.lowercased().contains(selectedCollection.lowercased())) &&
            (query.isEmpty || activity.name.lowercased().contains(query) || activity.category.lowercased().contains(query))
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
    
    private func saveNotes(_ notes: String, for activityID: UUID) {
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
        activities.reduce(0) { $0 + $1.todayTrackedSeconds }
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
            HStack {
                Text(NSLocalizedString("timer.label.activities", comment: "Activities"))
                    .font(DesignSystem.Typography.subHeader)
                Spacer()
            }
            
            collectionsFilter
            
            TextField(NSLocalizedString("timer.label.search", comment: "Search"), text: $searchText)
                .textFieldStyle(.roundedBorder)
            
            activityList
        }
        .padding(cardPadding)
        .glassCard(cornerRadius: cardCorner)
    }
    
    private var timerCard: some View {
        timerCoreCard
    }
    
    private var studySummaryCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.medium) {
            Text(NSLocalizedString("timer.stats.study_summary", comment: "Study summary"))
                .font(DesignSystem.Typography.subHeader)
            
            // Check if there's data to display
            let todayTasks = tasksDueToday()
            let weekTasks = tasksDueThisWeek()
            let hasData = !todayTasks.isEmpty || !weekTasks.isEmpty
            
            if !hasData {
                // No data state
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text(NSLocalizedString("timer.stats.no_data", comment: "No data available"))
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                // Data available
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.medium) {
                    // Tasks Due Today Section
                    if !todayTasks.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                            Text(NSLocalizedString("timer.tasks.due_today", comment: "Tasks Due Today"))
                                .font(DesignSystem.Typography.body.weight(.semibold))
                            
                            ForEach(todayTasks, id: \.id) { task in
                                taskCheckboxRow(task)
                            }
                        }
                    }
                    
                    if !todayTasks.isEmpty && !weekTasks.isEmpty {
                        Divider()
                    }
                    
                    // Tasks Due This Week Section
                    if !weekTasks.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                            Text(NSLocalizedString("timer.tasks.due_this_week", comment: "Tasks Due This Week"))
                                .font(DesignSystem.Typography.body.weight(.semibold))
                            
                            ForEach(weekTasks, id: \.id) { task in
                                taskCheckboxRow(task)
                            }
                        }
                    }
                }
            }
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
                    Text(NSLocalizedString("timer.label.pinned", comment: "Pinned"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(cachedPinnedActivities) { activity in
                        activityRow(activity)
                    }
                }
                
                Text(NSLocalizedString("timer.label.all_activities", comment: "All activities"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                
                ForEach(cachedFilteredActivities) { activity in
                    activityRow(activity)
                }
            }
            .padding(.horizontal, 4)
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
        GlassClockCard(cornerRadius: cardCorner) {
            VStack(spacing: 16) {
                // Top bar with expand button and mode menu
                HStack(alignment: .center) {
                    Button(action: openFocusWindow) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    if !isRunning {
                        Button(action: { showingModeMenu = true }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingModeMenu, arrowEdge: .bottom) {
                            VStack(alignment: .leading, spacing: 8) {
                                // Timer Mode section
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Timer Mode")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.top, 4)
                                    
                                    ForEach(LocalTimerMode.allCases, id: \.self) { timerMode in
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
                                                Text(timerMode.label)
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
                                    Text("Appearance")
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
                                            Text("Digital")
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
                                            Text("Analog")
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
                }
                .frame(height: 36)
                
                // Activity pill - shows only when activity is selected, with bounce animation
                if let activity = currentActivity {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text(activity.name)
                            .font(DesignSystem.Typography.caption.weight(.medium))
                            .foregroundStyle(.primary)
                        if let course = activity.courseCode {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(course)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
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
                        Text(NSLocalizedString("timer.label.no_activity_selected", comment: "No activity selected"))
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
                    
                    // POMODORO CIRCLES - FIXED VERSION
                    Group {
                        if mode == .pomodoro {
                            HStack(spacing: 8) {
                                ForEach(Array(0..<max(1, settings.pomodoroIterations)), id: \.self) { index in
                                    Circle()
                                        .fill(index < completedPomodoroSessions ? Color.accentColor : .tertiary)
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
                            Image(systemName: "pause.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: resetTimer) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    clockGlassContainer {
                        clockDisplayContent(isRunningState: false)
                    }
                    
                    // POMODORO CIRCLES - FIXED VERSION
                    Group {
                        if mode == .pomodoro {
                            HStack(spacing: 8) {
                                ForEach(Array(0..<max(1, settings.pomodoroIterations)), id: \.self) { index in
                                    Circle()
                                        .fill(index < completedPomodoroSessions ? Color.accentColor : Color.accentColor.opacity(0.3))
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
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, 4)
                }
                
                Text(NSLocalizedString("timer.focus.message", comment: "Focus message"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func clockGlassContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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
    private func clockDisplayContent(isRunningState: Bool) -> some View {
        VStack(spacing: 8) {
            if settings.isTimerAnalog {
                // Triple dial analog display
                TripleDialTimer(
                    totalSeconds: clockTimeForAnalog,
                    accentColor: .accentColor
                )
                .frame(height: 200)
            } else {
                // Digital display
                if mode == .pomodoro {
                    Text(isPomodorBreak ? "Break" : "Work")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                } else {
                    Text(mode.label)
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
                .frame(height: 200)
            }
        }
        .padding(.vertical, 12)
    }
    
    private var clockTimeForAnalog: TimeInterval {
        guard isRunning else { return 0 }
        
        switch mode {
        case .stopwatch:
            return elapsedSeconds
        case .pomodoro, .countdown:
            return max(0, currentBlockDuration - remainingSeconds)
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
        case .pomodoro, .countdown:
            let m = Int(remainingSeconds) / 60
            let s = Int(remainingSeconds) % 60
            return String(format: "%02d:%02d", m, s)
        }
    }
    
    private func startTimer() {
        guard !isRunning else { return }
        if mode != .stopwatch && remainingSeconds == 0 {
            remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
            currentBlockDuration = remainingSeconds
        } else if mode == .pomodoro || mode == .countdown {
            currentBlockDuration = max(currentBlockDuration, remainingSeconds)
        }
        if mode == .stopwatch {
            currentBlockDuration = 0
        }
        isRunning = true
    }
    
    private func pauseTimer() {
        isRunning = false
    }
    
    private func resetTimer() {
        isRunning = false
        elapsedSeconds = 0
        remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
        isPomodorBreak = false
        currentBlockDuration = remainingSeconds
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
        case .countdown:
            remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
            currentBlockDuration = remainingSeconds
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
        case .pomodoro, .countdown:
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
                Text("Selected: \(activity.name) • \(formattedDuration(activity.todayTrackedSeconds)) today")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                .primaryBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Add topBar
                    topBar
                    
                    // Add MINIMAL mainGrid (just text to start)
                    mainGrid
                    
                    // Add bottomSummary
                    bottomSummary
                }
                .padding(.horizontal, RootsSpacing.pagePadding)
                .padding(.vertical, RootsSpacing.l)
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

private struct FocusWindowView: View {
    @Binding var mode: LocalTimerMode
    @Binding var remainingSeconds: TimeInterval
    @Binding var elapsedSeconds: TimeInterval
    @Binding var currentBlockDuration: TimeInterval
    @Binding var completedPomodoroSessions: Int
    @Binding var isPomodorBreak: Bool
    @Binding var isRunning: Bool
    
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
        // When idle (not running), return 0 to show 12:00:00
        guard isRunning else { return 0 }
        
        switch mode {
        case .stopwatch:
            return elapsedSeconds
        case .pomodoro, .countdown:
            return max(0, currentBlockDuration - remainingSeconds)
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
                    
                    // Clock/Timer display - ONLY difference between analog and digital
                    if settings.isTimerAnalog {
                        TripleDialTimer(
                            totalSeconds: clockTime,
                            accentColor: accentColor
                        )
                        .frame(height: 200)
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
                            ForEach(Array(0..<max(1, pomodoroSessions)), id: \.self) { index in
                                Circle()
                                    .fill(index < completedPomodoroSessions ? accentColor : .tertiary)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .id(pomodoroSessions)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabelWithTooltip("\(completedPomodoroSessions) of \(pomodoroSessions) completed")
                    } else {
                        Text("\(mode.label) running")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Timer control buttons
                HStack(spacing: 12) {
                    if isRunning {
                        Button(action: onPause) {
                            Label("Pause", systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .keyboardShortcut(.space, modifiers: [])
                    } else {
                        Button(action: onStart) {
                            Label(remainingSeconds == 0 && mode != .stopwatch ? "Start" : "Resume", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.space, modifiers: [])
                    }
                    
                    Button(action: onReset) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
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
            Text(NSLocalizedString("timer.label.current_activity", comment: "Current activity"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let activity {
                VStack(alignment: .leading, spacing: 10) {
                    Text(activity.name)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)
                    if let course = activity.courseCode {
                        Text(course)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

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
                Text(NSLocalizedString("timer.label.no_activity_short", comment: "No activity"))
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
        case .pomodoro, .countdown:
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

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
#endif
