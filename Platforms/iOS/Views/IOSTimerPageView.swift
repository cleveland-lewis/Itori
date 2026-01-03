//
//  IOSTimerPageView.swift
//  Roots (iOS)
//

#if os(iOS)
import SwiftUI

struct IOSTimerPageView: View {
    @EnvironmentObject private var settings: AppSettingsModel
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @StateObject private var viewModel = TimerPageViewModel()
    @StateObject private var liveActivityManager = IOSTimerLiveActivityManager()
    @State private var activitySearchText = ""
    @State private var selectedCollectionID: UUID? = nil
    @AppStorage("timer.display.style") private var timerDisplayStyleRaw: String = TimerDisplayStyle.digital.rawValue
    @State private var timerCardWidth: CGFloat = 0
    @State private var showingFocusPage = false
    @State private var showingRecentSessions = false
    @State private var showingAddSession = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var sessionState: FocusSession.State {
        viewModel.currentSession?.state ?? .idle
    }

    private var isRunning: Bool {
        sessionState == .running
    }

    private var isPaused: Bool {
        sessionState == .paused
    }

    // MARK: - iPad Layout Detection
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    private var displayStyle: TimerDisplayStyle {
        TimerDisplayStyle(rawValue: timerDisplayStyleRaw) ?? .digital
    }

    private var timerDialSeconds: TimeInterval {
        viewModel.currentMode == .stopwatch ? viewModel.sessionElapsed : viewModel.sessionRemaining
    }

    var body: some View {
        if isIPad {
            iPadLayout
                .modifier(TimerSyncModifiers(viewModel: viewModel, settings: settings, syncLiveActivity: syncLiveActivity, syncSettingsFromApp: syncSettingsFromApp))
        } else {
            mainScroll
                .modifier(TimerSyncModifiers(viewModel: viewModel, settings: settings, syncLiveActivity: syncLiveActivity, syncSettingsFromApp: syncSettingsFromApp))
        }
    }
    
    // MARK: - iPad Split View Layout
    
    private var iPadLayout: some View {
        HStack(alignment: .top, spacing: 20) {
            // Left column: Activity management
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(NSLocalizedString("timer.label.activities", comment: "Activities"))
                        .font(.title2.weight(.bold))
                    
                    activityCollections
                    activitySearch
                    activityList
                }
                .padding(20)
            }
            .frame(minWidth: 300, idealWidth: 350, maxWidth: 400)
            .background(Color(uiColor: .systemGroupedBackground))
            
            // Right column: Timer and details
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    timerStatusCard
                    activityNotes
                    tasksSection
                    sessionButtons
#if DEBUG
                    debugSection
#endif
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var mainScroll: some View {
        ScrollView {
            contentStack
        }
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            timerStatusCard
            
            // Activity Management Section (Enhanced for Phase 1)
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("timer.label.activities", comment: "Activities"))
                    .font(.headline)
                
                activityCollections
                activitySearch
                activityList
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            
            activityNotes
            tasksSection
            sessionButtons
#if DEBUG
            debugSection
#endif
        }
        .padding(20)
    }

    private var timerStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                if sessionState == .idle {
                    Button {
                        showingFocusPage = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.headline)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(NSLocalizedString("timer.focus.window_title", comment: "Focus"))
                } else {
                    Text(statusTitle)
                        .font(.headline)
                        .accessibilityIdentifier("Timer.Status")
                }
                Spacer()
                Menu {
                    ForEach(TimerMode.allCases) { mode in
                        Button {
                            viewModel.currentMode = mode
                        } label: {
                            Label(mode.displayName, systemImage: mode.systemImage)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.headline)
                }
                .accessibilityLabel(NSLocalizedString("ios.timer.mode", comment: "Mode"))
            }
            if displayStyle == .analog {
                RootsAnalogClock(
                    style: .stopwatch,
                    diameter: max(180, timerDialDiameter),
                    showSecondHand: true,
                    accentColor: .accentColor,
                    timerSeconds: timerDialSeconds
                )
                .accessibilityIdentifier("Timer.Clock")
                .frame(maxWidth: .infinity)
            } else {
                Text(timeString(for: viewModel.sessionRemaining, elapsed: viewModel.sessionElapsed))
                    .font(.system(size: timerTextSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .accessibilityIdentifier("Timer.Time")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            if viewModel.currentMode == .pomodoro {
                Text(viewModel.isOnBreak ? NSLocalizedString("ios.timer.break", comment: "Break") : NSLocalizedString("ios.timer.focus", comment: "Focus"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            controlRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: TimerCardWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(TimerCardWidthKey.self) { width in
            guard width > 0 else { return }
            DispatchQueue.main.async {
                timerCardWidth = width
            }
        }
        .task(id: timerCardWidth) {
            let rounded = (timerCardWidth / 2).rounded() * 2
            if abs(rounded - timerCardWidth) > 0.5 {
                timerCardWidth = rounded
            }
        }
        .sheet(isPresented: $showingFocusPage) {
            focusPage
        }
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            if isRunning {
                Button(NSLocalizedString("ios.timer.pause", comment: "Pause")) { viewModel.pauseSession() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("Timer.Pause")
            } else if isPaused {
                Button(NSLocalizedString("ios.timer.resume", comment: "Resume")) { viewModel.resumeSession() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("Timer.Resume")
            } else {
                Button(NSLocalizedString("ios.timer.start", comment: "Start")) { viewModel.startSession() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("Timer.Start")
            }

            Button(NSLocalizedString("ios.timer.stop", comment: "Stop")) { viewModel.endSession(completed: false) }
                .buttonStyle(.bordered)
                .disabled(sessionState == .idle)
                .accessibilityIdentifier("Timer.Stop")

            if viewModel.currentMode == .pomodoro {
                Button(NSLocalizedString("ios.timer.skip", comment: "Skip")) { viewModel.skipSegment() }
                    .buttonStyle(.bordered)
                    .disabled(!isRunning)
                    .accessibilityIdentifier("Timer.Skip")
            }
        }
    }

    // MARK: - Activity List (Phase 1.1: Enhanced with Pinned Section)
    
    private var filteredActivities: [TimerActivity] {
        let query = activitySearchText.lowercased()
        
        return viewModel.activities.filter { activity in
            // Filter by collection
            let collectionMatch = selectedCollectionID == nil || activity.collectionID == selectedCollectionID
            
            // Filter by search text
            let searchMatch = query.isEmpty || 
                activity.name.lowercased().contains(query) ||
                (activity.note?.lowercased().contains(query) ?? false)
            
            return collectionMatch && searchMatch
        }
    }
    
    private var pinnedActivities: [TimerActivity] {
        filteredActivities.filter { $0.isPinned }
    }
    
    private var unpinnedActivities: [TimerActivity] {
        filteredActivities.filter { !$0.isPinned }
    }
    
    private var activityList: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Pinned section
            if !pinnedActivities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("timer.label.pinned", comment: "Pinned"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ForEach(pinnedActivities) { activity in
                        activityRow(activity)
                    }
                }
                
                if !unpinnedActivities.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                }
            }
            
            // All activities section
            if !unpinnedActivities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("timer.label.all_activities", comment: "All Activities"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ForEach(unpinnedActivities) { activity in
                        activityRow(activity)
                    }
                }
            }
            
            // Empty state
            if filteredActivities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(activitySearchText.isEmpty ? 
                         NSLocalizedString("timer.activities.empty", comment: "No activities") :
                         NSLocalizedString("timer.activities.no_results", comment: "No matching activities"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
    }
    
    private func activityRow(_ activity: TimerActivity) -> some View {
        Button {
            viewModel.selectActivity(activity.id)
        } label: {
            HStack(spacing: 12) {
                // Activity indicator
                Circle()
                    .fill(activity.isPinned ? Color.orange : Color.accentColor)
                    .frame(width: 8, height: 8)
                
                // Activity info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if let emoji = activity.emoji {
                            Text(emoji)
                                .font(.caption)
                        }
                        
                        Text(activity.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if activity.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if let note = activity.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Selection indicator
                if viewModel.currentActivityID == activity.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.body)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.currentActivityID == activity.id ? 
                          Color.accentColor.opacity(0.1) : 
                          Color(uiColor: .tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                togglePin(activity)
            } label: {
                Label(
                    activity.isPinned ? 
                        NSLocalizedString("timer.activity.unpin", comment: "Unpin") :
                        NSLocalizedString("timer.activity.pin", comment: "Pin"),
                    systemImage: activity.isPinned ? "pin.slash" : "pin"
                )
            }
            
            Button {
                viewModel.selectActivity(activity.id)
            } label: {
                Label(NSLocalizedString("timer.activity.select", comment: "Select"), systemImage: "checkmark.circle")
            }
            
            Divider()
            
            Button(role: .destructive) {
                viewModel.deleteActivity(id: activity.id)
            } label: {
                Label(NSLocalizedString("common.delete", comment: "Delete"), systemImage: "trash")
            }
        }
    }
    
    private func togglePin(_ activity: TimerActivity) {
        var updated = activity
        updated.isPinned.toggle()
        viewModel.updateActivity(updated)
    }

    private var activityCollections: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    selectedCollectionID = nil
                } label: {
                    collectionChip(title: "All", isSelected: selectedCollectionID == nil)
                }
                .buttonStyle(.plain)

                ForEach(viewModel.collections) { collection in
                    Button {
                        selectedCollectionID = collection.id
                    } label: {
                        collectionChip(title: collection.name, isSelected: selectedCollectionID == collection.id)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func collectionChip(title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(uiColor: .secondarySystemBackground))
            )
    }

    private var activitySearch: some View {
        TextField("Search activities", text: $activitySearchText)
            .textFieldStyle(.roundedBorder)
    }

    private var activityNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let activity = selectedActivity {
                // Activity header
                HStack(spacing: 12) {
                    if let emoji = activity.emoji {
                        Text(emoji)
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.name)
                            .font(.headline)
                        
                        if let category = activity.studyCategory {
                            Text(category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if activity.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                Divider()
                
                // Notes editor
                NotesEditor(
                    title: NSLocalizedString("timer.label.notes", comment: "Notes"),
                    text: activityNoteBinding,
                    minHeight: 100
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("timer.activity.select_to_add_notes", comment: "Select an activity to add notes"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private var sessionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingRecentSessions = true
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Recent Sessions")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)
            
            Button {
                showingAddSession = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Session")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingRecentSessions) {
            RecentSessionsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddSession) {
            AddSessionSheet(viewModel: viewModel)
        }
    }

    private var statusTitle: String {
        switch sessionState {
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .cancelled: return "Stopped"
        case .idle: return "Ready"
        @unknown default: return "Ready"
        }
    }

    private func timeString(for remaining: TimeInterval, elapsed: TimeInterval) -> String {
        switch viewModel.currentMode {
        case .stopwatch:
            return durationString(elapsed)
        case .timer, .pomodoro, .focus:
            return durationString(remaining)
        @unknown default:
            return durationString(remaining)
        }
    }

    private var focusPage: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    if viewModel.currentMode == .pomodoro {
                        Text(viewModel.isOnBreak ? NSLocalizedString("ios.timer.break", comment: "Break") : NSLocalizedString("ios.timer.focus", comment: "Focus"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Clock/Timer display - ONLY difference between analog and digital
                    if displayStyle == .analog {
                        RootsAnalogClock(
                            style: .stopwatch,
                            diameter: min(max(220, timerDialDiameter), 520),
                            showSecondHand: true,
                            accentColor: .accentColor,
                            timerSeconds: timerDialSeconds
                        )
                        .frame(height: 260)
                    } else {
                        Text(timeString(for: viewModel.sessionRemaining, elapsed: viewModel.sessionElapsed))
                            .font(.system(size: 84, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                            .frame(height: 260)
                    }
                }
                
                controlRow
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle(NSLocalizedString("timer.focus.window_title", comment: "Focus"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFocusPage = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    private var timerDialDiameter: CGFloat {
        let available = max(0, timerCardWidth - 32)
        return min(available, 520)
    }

    private var timerTextSize: CGFloat {
        guard timerCardWidth > 0 else { return 48 }
        return min(max(timerCardWidth / 6, 48), 96)
    }
    
    private func durationString(_ seconds: TimeInterval) -> String {
        let total = max(Int(seconds.rounded()), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    private var selectedActivity: TimerActivity? {
        guard let id = viewModel.currentActivityID else { return nil }
        return viewModel.activities.first(where: { $0.id == id })
    }

    private var activityNoteBinding: Binding<String> {
        guard let activity = selectedActivity else { return .constant("") }
        return Binding(
            get: { activity.note ?? "" },
            set: { newValue in
                var updated = activity
                updated.note = newValue
                viewModel.updateActivity(updated)
            }
        )
    }

    private func syncLiveActivity() {
        liveActivityManager.sync(
            currentMode: viewModel.currentMode,
            session: viewModel.currentSession,
            elapsed: viewModel.sessionElapsed,
            remaining: viewModel.sessionRemaining,
            isOnBreak: viewModel.isOnBreak,
            activities: viewModel.activities,
            pomodoroCompletedCycles: viewModel.pomodoroCompletedCycles,
            pomodoroMaxCycles: viewModel.pomodoroMaxCycles
        )
    }

    private func syncSettingsFromApp() {
        viewModel.focusDuration = TimeInterval(settings.pomodoroFocusMinutes * 60)
        viewModel.breakDuration = TimeInterval(settings.pomodoroShortBreakMinutes * 60)
        viewModel.longBreakDuration = TimeInterval(settings.pomodoroLongBreakMinutes * 60)
        viewModel.timerDuration = TimeInterval(settings.timerDurationMinutes * 60)
        viewModel.pomodoroMaxCycles = settings.pomodoroIterations
    }
    
    // MARK: - Phase 4.3: Tasks Section
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("timer.tasks.title", comment: "Tasks"))
                .font(.headline)
            
            tasksDueTodaySection
            tasksDueThisWeekSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
    
    private var tasksDueTodaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                Text(NSLocalizedString("timer.tasks.dueToday", comment: "Due Today"))
                    .font(.subheadline.weight(.medium))
                Spacer()
                if !tasksDueToday.isEmpty {
                    Text("\(tasksDueToday.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(uiColor: .tertiarySystemFill)))
                }
            }
            
            if tasksDueToday.isEmpty {
                Text(NSLocalizedString("timer.tasks.noDueToday", comment: "No tasks due today"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            } else {
                ForEach(tasksDueToday) { task in
                    TaskCheckboxRow(task: task, onToggle: { toggleTaskCompletion($0) })
                }
            }
        }
    }
    
    private var tasksDueThisWeekSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.blue)
                Text(NSLocalizedString("timer.tasks.dueThisWeek", comment: "Due This Week"))
                    .font(.subheadline.weight(.medium))
                Spacer()
                if !tasksDueThisWeek.isEmpty {
                    Text("\(tasksDueThisWeek.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(uiColor: .tertiarySystemFill)))
                }
            }
            
            if tasksDueThisWeek.isEmpty {
                Text(NSLocalizedString("timer.tasks.noDueThisWeek", comment: "No tasks due this week"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            } else {
                ForEach(tasksDueThisWeek) { task in
                    TaskCheckboxRow(task: task, onToggle: { toggleTaskCompletion($0) })
                }
            }
        }
    }
    
    // Task filtering
    private var tasksDueToday: [AppTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return assignmentsStore.tasks
            .filter { task in
                guard let dueDate = task.due else { return false }
                return dueDate >= today && dueDate < tomorrow && !task.isCompleted
            }
            .sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }
    }
    
    private var tasksDueThisWeek: [AppTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return assignmentsStore.tasks
            .filter { task in
                guard let dueDate = task.due else { return false }
                return dueDate >= tomorrow && dueDate < nextWeek && !task.isCompleted
            }
            .sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }
    }
    
    private func toggleTaskCompletion(_ task: AppTask) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        assignmentsStore.updateTask(updatedTask)
    }

#if DEBUG
    private var debugSection: some View {
        Group {
            if ProcessInfo.processInfo.arguments.contains("UITestTimerDebug") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("timer.debug.label", comment: "Debug"))
                        .font(.headline)
                    Text("Session: \(sessionState.rawValue)")
                        .accessibilityIdentifier("Timer.SessionState")
                    Text("LiveActivity: \(liveActivityStatus)")
                        .accessibilityIdentifier("Timer.LiveActivityState")
                    Button("Advance 10k") {
                        viewModel.debugAdvance(seconds: 10_000)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("Timer.DebugAdvance")
                }
            }
        }
    }

    private var liveActivityStatus: String {
        guard liveActivityManager.isAvailable else { return "Unavailable" }
        return liveActivityManager.isActive ? "Active" : "Inactive"
    }
#endif
}

private struct TimerCardWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 {
            value = next
        }
    }
}

private struct TimerSyncModifiers: ViewModifier {
    @ObservedObject var viewModel: TimerPageViewModel
    @ObservedObject var settings: AppSettingsModel
    let syncLiveActivity: () -> Void
    let syncSettingsFromApp: () -> Void

    func body(content: Content) -> some View {
        content
            .modifier(TimerSettingsSync(settings: settings, requestAlarmAuthorization: requestAlarmAuthorization, syncSettingsFromApp: syncSettingsFromApp))
            .modifier(TimerLiveActivitySync(viewModel: viewModel, syncLiveActivity: syncLiveActivity))
            .modifier(TimerDurationSync(viewModel: viewModel, settings: settings))
            .onAppear {
                if viewModel.alarmScheduler == nil {
                    viewModel.alarmScheduler = IOSTimerAlarmScheduler()
                }
                syncSettingsFromApp()
            }
    }

    private func requestAlarmAuthorization() async -> Bool {
        guard let scheduler = viewModel.alarmScheduler as? IOSTimerAlarmScheduler else { return false }
        if #available(iOS 17.0, *) {
            return await scheduler.requestAuthorizationIfNeeded()
        }
        return false
    }
}

private struct TimerSettingsSync: ViewModifier {
    @ObservedObject var settings: AppSettingsModel
    let requestAlarmAuthorization: () async -> Bool
    let syncSettingsFromApp: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: settings.pomodoroFocusMinutes) { _, _ in syncSettingsFromApp() }
            .onChange(of: settings.pomodoroShortBreakMinutes) { _, _ in syncSettingsFromApp() }
            .onChange(of: settings.pomodoroLongBreakMinutes) { _, _ in syncSettingsFromApp() }
            .onChange(of: settings.pomodoroIterations) { _, _ in syncSettingsFromApp() }
            .onChange(of: settings.timerDurationMinutes) { _, _ in syncSettingsFromApp() }
            .onChange(of: settings.timerAlertsEnabled) { _, _ in syncSettingsFromApp() }
            .onChange(of: settings.pomodoroAlertsEnabled) { _, _ in syncSettingsFromApp() }
            .onChange(of: settings.alarmKitTimersEnabled) { _, newValue in
                guard newValue else { return }
                Task { _ = await requestAlarmAuthorization() }
            }
    }
}

private struct TimerLiveActivitySync: ViewModifier {
    @ObservedObject var viewModel: TimerPageViewModel
    let syncLiveActivity: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: viewModel.currentSession) { _, _ in syncLiveActivity() }
            .onChange(of: viewModel.sessionElapsed) { _, _ in syncLiveActivity() }
            .onChange(of: viewModel.sessionRemaining) { _, _ in syncLiveActivity() }
            .onChange(of: viewModel.isOnBreak) { _, _ in syncLiveActivity() }
            .onChange(of: viewModel.currentMode) { _, _ in syncLiveActivity() }
    }
}

private struct TimerDurationSync: ViewModifier {
    @ObservedObject var viewModel: TimerPageViewModel
    @ObservedObject var settings: AppSettingsModel

    func body(content: Content) -> some View {
        content
            .modifier(FocusDurationSync(viewModel: viewModel, settings: settings))
            .modifier(BreakDurationSync(viewModel: viewModel, settings: settings))
            .modifier(TimerValueSync(viewModel: viewModel, settings: settings))
    }
}

private struct FocusDurationSync: ViewModifier {
    @ObservedObject var viewModel: TimerPageViewModel
    @ObservedObject var settings: AppSettingsModel
    
    func body(content: Content) -> some View {
        content.onChange(of: viewModel.focusDuration) { _, newValue in
            settings.pomodoroFocusMinutes = max(Int(newValue / 60), 1)
        }
    }
}

private struct BreakDurationSync: ViewModifier {
    @ObservedObject var viewModel: TimerPageViewModel
    @ObservedObject var settings: AppSettingsModel
    
    func body(content: Content) -> some View {
        content.onChange(of: viewModel.breakDuration) { _, newValue in
            settings.pomodoroShortBreakMinutes = max(Int(newValue / 60), 1)
        }
    }
}

private struct TimerValueSync: ViewModifier {
    @ObservedObject var viewModel: TimerPageViewModel
    @ObservedObject var settings: AppSettingsModel
    
    func body(content: Content) -> some View {
        content.onChange(of: viewModel.timerDuration) { _, newValue in
            settings.timerDurationMinutes = max(Int(newValue / 60), 1)
        }
    }
}
#endif
