#if os(macOS)
import SwiftUI
import EventKit

struct PlannerView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case today = "Today"  // Keep English for now since it's used as tag
        case week = "This Week"
        case upcoming = "Upcoming"
        var id: String { rawValue }
        
        var localizedString: String {
            switch self {
            case .today: return "planner.mode.today".localized
            case .week: return "planner.mode.this_week".localized
            case .upcoming: return "planner.mode.upcoming".localized
            }
        }
    }

    @State private var mode: Mode = .today

    // No sample tasks — empty state only
    private let todayTasks: [Any] = []
    private let weekTasks: [Any] = []
    private let unscheduledTasks: [Any] = []

    // Scheduler controls
    @State private var minBlockMinutes: Int = 25
    @State private var maxBlockMinutes: Int = 90
    @State private var horizonDays: Int = 7
    @State private var weightUrgency: Double = 0.45
    @State private var weightImportance: Double = 0.35
    @State private var weightDifficulty: Double = 0.10
    @State private var weightSize: Double = 0.10
    @State private var showScheduleResult: Bool = false
    @State private var scheduleResult: ScheduleResult? = nil

    @StateObject private var assignmentsStore = AssignmentsStore.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @ObservedObject private var calendarAuth = CalendarAuthorizationManager.shared
    private let deviceCalendar = DeviceCalendarManager.shared


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
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
                }
                // Header controls (title removed)
                HStack {
                    Spacer()
                    Button("planner.action.schedule".localized) { runScheduler() }
                        .buttonStyle(.glassBlueProminent)
                    Button("Re-learn") {
                        var prefs = SchedulerPreferencesStore.shared.preferences
                        SchedulerLearner.updatePreferences(from: SchedulerFeedbackStore.shared.feedback, preferences: &prefs)
                        SchedulerPreferencesStore.shared.preferences = prefs
                        SchedulerPreferencesStore.shared.save()
                        SchedulerFeedbackStore.shared.clear()
                    }
                    .buttonStyle(.bordered)
                }

                // Mode picker
                Picker("planner.mode.picker_label".localized, selection: $mode) {
                    ForEach(Mode.allCases) { m in
                        Text(m.localizedString).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)

                GroupBox("planner.scheduler.title".localized) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        HStack {
                            Text("planner.scheduler.min_block".localized)
                            Spacer()
                            Stepper("\(minBlockMinutes) \("planner.scheduler.minutes_short".localized)", value: $minBlockMinutes, in: 15...60, step: 5)
                                .labelsHidden()
                        }
                        HStack {
                            Text("planner.scheduler.max_block".localized)
                            Spacer()
                            Stepper("\(maxBlockMinutes) \("planner.scheduler.minutes_short".localized)", value: $maxBlockMinutes, in: 30...240, step: 5)
                                .labelsHidden()
                        }
                        HStack {
                            Text("planner.scheduler.horizon_days".localized)
                            Spacer()
                            Stepper("\(horizonDays)", value: $horizonDays, in: 1...30)
                                .labelsHidden()
                        }

                        HStack(alignment: .top) {
                            Text("planner.scheduler.weights".localized)
                            Spacer()
                            VStack(alignment: .trailing) {
                                HStack { Text("planner.scheduler.weight.urgency".localized); Slider(value: $weightUrgency, in: 0...1) }
                                HStack { Text("planner.scheduler.weight.importance".localized); Slider(value: $weightImportance, in: 0...1) }
                                HStack { Text("planner.scheduler.weight.difficulty".localized); Slider(value: $weightDifficulty, in: 0...1) }
                                HStack { Text("planner.scheduler.weight.size".localized); Slider(value: $weightSize, in: 0...1) }
                            }
                        }
                    }
                    .controlSize(.small)
                }

                // Sections
                LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    // Today's Plan
                    Section(header: Text("Today's Plan").font(DesignSystem.Typography.body)) {
                        if todayTasks.isEmpty {
                            if calendarManager.reminderAuthorizationStatus == .denied || calendarManager.reminderAuthorizationStatus == .restricted {
                                AppCard {
                                    VStack(spacing: DesignSystem.Spacing.small) {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .imageScale(.large)
                                        Text("planner.reminders.access_off".localized)
                                            .font(DesignSystem.Typography.title)
                                        Text("planner.reminders.enable_instructions".localized)
                                            .font(DesignSystem.Typography.body)
                                        Button("planner.reminders.open_settings".localized) {
                                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
                                                #if os(macOS)
                                                NSWorkspace.shared.open(url)
                                                #endif
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .onAppear {
                                    #if os(macOS)
                                    HapticsManager.shared.play(.warning)
                                    #endif
                                }
                                .frame(minHeight: DesignSystem.Cards.defaultHeight)
                            } else {
                                AppCard {
                                    VStack(spacing: DesignSystem.Spacing.small) {
                                        Image(systemName: "checklist")
                                            .imageScale(.large)
                                        Text("Today's Plan")
                                            .font(DesignSystem.Typography.title)
                                        Text(DesignSystem.emptyStateMessage)
                                            .font(DesignSystem.Typography.body)
                                    }
                                }
                                .frame(minHeight: DesignSystem.Cards.defaultHeight)
                            }
                        } else {
                            // TODO: render today's tasks
                            Text("TODO: Today's tasks")
                        }
                    }

                    // This Week
                    Section(header: Text("planner.section.this_week".localized).font(DesignSystem.Typography.body)) {
                        if weekTasks.isEmpty {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "calendar.badge.clock")
                                        .imageScale(.large)
                                    Text("planner.section.this_week".localized)
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        } else {
                            // TODO: render week tasks
                            Text("TODO: Week tasks")
                        }
                    }

                    // Unscheduled Tasks
                    Section(header: Text("planner.section.unscheduled".localized).font(DesignSystem.Typography.body)) {
                        if unscheduledTasks.isEmpty {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "tray")
                                        .imageScale(.large)
                                    Text("planner.section.unscheduled".localized)
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        } else {
                            // TODO: render unscheduled tasks
                            Text("TODO: Unscheduled tasks")
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.large)
        }
        .contextMenu {
            Button {
                SceneActivationHelper.openPlannerWindow(for: Date())
            } label: {
                Label("Open in New Window", systemImage: "doc.on.doc")
            }
        }
        .onAppear {
            _Concurrency.Task { await calendarManager.requestAccess() }
        }
        .background(DesignSystem.background(for: .light))
        .sheet(isPresented: $showScheduleResult) {
            if let res = scheduleResult {
                ScheduleResultView(result: res)
            } else {
                Text("planner.schedule_result.none".localized)
            }
        }
    }


    // Run scheduler with current empty data (no sample tasks) — constructs constraints from UI
    private func runScheduler() {
        // Build tasks from AssignmentsStore
        let tasks: [AppTask] = AssignmentsStore.shared.incompleteTasks()

        // Build fixed events from CalendarManager's events (treat as locked)
        let fixed: [FixedEvent] = DeviceCalendarManager.shared.events.map { ev in
            FixedEvent(id: UUID(), title: ev.title ?? "", start: ev.startDate, end: ev.endDate, isLocked: true, source: .calendar)
        }

        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: horizonDays, to: now)!

        // Load preferences and use learned energy profile
        let prefs = SchedulerPreferencesStore.shared.preferences
        var energy: [Int: Double] = (0..<24).reduce(into: [:]) { acc, hr in acc[hr] = (hr >= 9 && hr <= 21) ? 0.8 : 0.3 }
        for (h, v) in prefs.learnedEnergyProfile { energy[h] = v }

        let constraints = Constraints(horizonStart: now, horizonEnd: end, dayStartHour: 7, dayEndHour: 23, maxStudyMinutesPerDay: 6*60, maxStudyMinutesPerBlock: maxBlockMinutes, minGapBetweenBlocksMinutes: 10, doNotScheduleWindows: [], energyProfile: energy)

        // Call scheduler (use learned preferences)
        let res = AIScheduler.generateSchedule(tasks: tasks, fixedEvents: fixed, constraints: constraints, preferences: prefs)
        self.scheduleResult = res
        self.showScheduleResult = true
    }

}

// Simple sheet to show ScheduleResult
private struct ScheduleResultView: View {
    let result: ScheduleResult

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Schedule Result")
                .font(DesignSystem.Typography.title)

            Text("Blocks: \(result.blocks.count)")
            if result.blocks.isEmpty {
                AppCard {
                    VStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .imageScale(.large)
                        Text(DesignSystem.emptyStateMessage)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(.primary)
                    }
                }
                .frame(minHeight: DesignSystem.Cards.defaultHeight)
            } else {
                List {
                    ForEach(result.blocks, id: \.id) { b in
                        VStack(alignment: .leading) {
                            let task = AssignmentsStore.shared.tasks.first { $0.id == b.taskId }
                            Text(task?.title ?? b.taskId.uuidString)
                                .font(DesignSystem.Typography.body)
                            if let t = task {
                                if let course = t.courseId {
                                    Text("Course: \(course.uuidString)")
                                        .font(DesignSystem.Typography.caption)
                                }
                            }
                            Text(AppSettingsModel.shared.formattedTimeRange(start: b.start, end: b.end))
                                .font(DesignSystem.Typography.caption)
                        }
                        .contextMenu {
                            Button("Mark as kept") {
                                if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                    let fb = BlockFeedback(blockId: b.id, taskId: task.id, courseId: task.courseId, type: task.type, start: b.start, end: b.end, completion: 1.0, action: .kept)
                                    SchedulerFeedbackStore.shared.append(fb)
                                }
                            }
                            Button("Mark as rescheduled") {
                                if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                    let fb = BlockFeedback(blockId: b.id, taskId: task.id, courseId: task.courseId, type: task.type, start: b.start, end: b.end, completion: 0.6, action: .rescheduled)
                                    SchedulerFeedbackStore.shared.append(fb)
                                }
                            }
                            Button("Mark as deleted") {
                                if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                    let fb = BlockFeedback(blockId: b.id, taskId: task.id, courseId: task.courseId, type: task.type, start: b.start, end: b.end, completion: 0.0, action: .deleted)
                                    SchedulerFeedbackStore.shared.append(fb)
                                }
                            }
                            Button("Mark as shortened") {
                                if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                    let fb = BlockFeedback(blockId: b.id, taskId: task.id, courseId: task.courseId, type: task.type, start: b.start, end: b.end, completion: 0.4, action: .shortened)
                                    SchedulerFeedbackStore.shared.append(fb)
                                }
                            }
                            Button("Mark as extended") {
                                if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                    let fb = BlockFeedback(blockId: b.id, taskId: task.id, courseId: task.courseId, type: task.type, start: b.start, end: b.end, completion: 1.0, action: .extended)
                                    SchedulerFeedbackStore.shared.append(fb)
                                }
                            }
                        }
                    }
                }
            }

            Text("Logs")
                .font(DesignSystem.Typography.body)
            List {
                ForEach(Array(result.log.enumerated()), id: \.offset) { idx, line in
                    Text(line)
                }
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.large)
    }
}


struct PlannerView_Previews: PreviewProvider {
    static var previews: some View {
        PlannerView()
    }
}
#endif
