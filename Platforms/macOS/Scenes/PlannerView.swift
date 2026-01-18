#if os(macOS)
    import EventKit
    import SwiftUI

    struct PlannerView: View {
        enum Mode: String, CaseIterable, Identifiable {
            case today = "Today" // Keep English for now since it's used as tag
            case week = "This Week"
            case upcoming = "Upcoming"
            var id: String { rawValue }

            var localizedString: String {
                switch self {
                case .today: "planner.mode.today".localized
                case .week: "planner.mode.this_week".localized
                case .upcoming: "planner.mode.upcoming".localized
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

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    // Header controls (title removed)
                    HStack {
                        Spacer()
                        Button(NSLocalizedString(
                            "planner.action.schedule",
                            value: "planner.action.schedule",
                            comment: ""
                        )) { runScheduler() }
                            .buttonStyle(.glassBlueProminent)
                        Button(NSLocalizedString("planner.button.relearn", value: "Re-learn", comment: "Re-learn")) {
                            var prefs = SchedulerPreferencesStore.shared.preferences
                            SchedulerLearner.updatePreferences(
                                from: SchedulerFeedbackStore.shared.feedback,
                                preferences: &prefs
                            )
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

                    // Scheduler tuning UI
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        HStack {
                            Text(NSLocalizedString(
                                "planner.scheduler.min_block",
                                value: "planner.scheduler.min_block",
                                comment: ""
                            ))
                            Spacer()
                            Stepper(
                                "\(minBlockMinutes) \("planner.scheduler.minutes_short".localized)",
                                value: $minBlockMinutes,
                                in: 15 ... 60,
                                step: 5
                            )
                            .labelsHidden()
                        }
                        HStack {
                            Text(NSLocalizedString(
                                "planner.scheduler.max_block",
                                value: "planner.scheduler.max_block",
                                comment: ""
                            ))
                            Spacer()
                            Stepper(
                                "\(maxBlockMinutes) \("planner.scheduler.minutes_short".localized)",
                                value: $maxBlockMinutes,
                                in: 30 ... 240,
                                step: 5
                            )
                            .labelsHidden()
                        }
                        HStack {
                            Text(NSLocalizedString(
                                "planner.scheduler.horizon_days",
                                value: "planner.scheduler.horizon_days",
                                comment: ""
                            ))
                            Spacer()
                            Stepper("\(horizonDays)", value: $horizonDays, in: 1 ... 30)
                                .labelsHidden()
                        }

                        HStack {
                            Text(NSLocalizedString(
                                "planner.scheduler.weights",
                                value: "planner.scheduler.weights",
                                comment: ""
                            ))
                            Spacer()
                            VStack(alignment: .trailing) {
                                HStack { Text(NSLocalizedString(
                                    "planner.scheduler.weight.urgency",
                                    value: "planner.scheduler.weight.urgency",
                                    comment: ""
                                ))
                                Slider(value: $weightUrgency, in: 0 ... 1)
                                }
                                HStack { Text(NSLocalizedString(
                                    "planner.scheduler.weight.importance",
                                    value: "planner.scheduler.weight.importance",
                                    comment: ""
                                ))
                                Slider(value: $weightImportance, in: 0 ... 1)
                                }
                                HStack { Text(NSLocalizedString(
                                    "planner.scheduler.weight.difficulty",
                                    value: "planner.scheduler.weight.difficulty",
                                    comment: ""
                                ))
                                Slider(value: $weightDifficulty, in: 0 ... 1)
                                }
                                HStack { Text(NSLocalizedString(
                                    "planner.scheduler.weight.size",
                                    value: "planner.scheduler.weight.size",
                                    comment: ""
                                ))
                                Slider(value: $weightSize, in: 0 ... 1)
                                }
                            }
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.small)

                    // Sections
                    LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                        // Today's Plan
                        Section(header: Text(NSLocalizedString(
                            "planner.todays.plan",
                            value: "Today's Plan",
                            comment: "Today's Plan"
                        )).font(DesignSystem.Typography.body)) {
                            if todayTasks.isEmpty {
                                if calendarManager.reminderAuthorizationStatus == .denied || calendarManager
                                    .reminderAuthorizationStatus == .restricted
                                {
                                    AppCard {
                                        VStack(spacing: DesignSystem.Spacing.small) {
                                            Image(systemName: "calendar.badge.exclamationmark")
                                                .imageScale(.large)
                                            Text(NSLocalizedString(
                                                "planner.reminders.access_off",
                                                value: "planner.reminders.access_off",
                                                comment: ""
                                            ))
                                            .font(DesignSystem.Typography.title)
                                            Text(NSLocalizedString(
                                                "planner.reminders.enable_instructions",
                                                value: "planner.reminders.enable_instructions",
                                                comment: ""
                                            ))
                                            .font(DesignSystem.Typography.body)
                                            Button(NSLocalizedString(
                                                "planner.reminders.open_settings",
                                                value: "planner.reminders.open_settings",
                                                comment: ""
                                            )) {
                                                if let url =
                                                    URL(
                                                        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
                                                    )
                                                {
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
                                            Text(NSLocalizedString(
                                                "planner.todays.plan",
                                                value: "Today's Plan",
                                                comment: "Today's Plan"
                                            ))
                                            .font(DesignSystem.Typography.title)
                                            Text(DesignSystem.emptyStateMessage)
                                                .font(DesignSystem.Typography.body)
                                        }
                                    }
                                    .frame(minHeight: DesignSystem.Cards.defaultHeight)
                                }
                            }
                        }

                        // This Week
                        Section(header: Text(NSLocalizedString(
                            "planner.section.this_week",
                            value: "planner.section.this_week",
                            comment: ""
                        )).font(DesignSystem.Typography.body)) {
                            if weekTasks.isEmpty {
                                AppCard {
                                    VStack(spacing: DesignSystem.Spacing.small) {
                                        Image(systemName: "calendar.badge.clock")
                                            .imageScale(.large)
                                        Text(NSLocalizedString(
                                            "planner.section.this_week",
                                            value: "planner.section.this_week",
                                            comment: ""
                                        ))
                                        .font(DesignSystem.Typography.title)
                                        Text(DesignSystem.emptyStateMessage)
                                            .font(DesignSystem.Typography.body)
                                    }
                                }
                                .frame(minHeight: DesignSystem.Cards.defaultHeight)
                            }
                        }

                        // Unscheduled Tasks
                        Section(header: Text(NSLocalizedString(
                            "planner.section.unscheduled",
                            value: "planner.section.unscheduled",
                            comment: ""
                        )).font(DesignSystem.Typography.body)) {
                            if unscheduledTasks.isEmpty {
                                AppCard {
                                    VStack(spacing: DesignSystem.Spacing.small) {
                                        Image(systemName: "tray")
                                            .imageScale(.large)
                                        Text(NSLocalizedString(
                                            "planner.section.unscheduled",
                                            value: "planner.section.unscheduled",
                                            comment: ""
                                        ))
                                        .font(DesignSystem.Typography.title)
                                        Text(DesignSystem.emptyStateMessage)
                                            .font(DesignSystem.Typography.body)
                                    }
                                }
                                .frame(minHeight: DesignSystem.Cards.defaultHeight)
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
                    Label(
                        NSLocalizedString(
                            "planner.label.open.in.new.window",
                            value: "Open in New Window",
                            comment: "Open in New Window"
                        ),
                        systemImage: "doc.on.doc"
                    )
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
                    Text(NSLocalizedString(
                        "planner.schedule_result.none",
                        value: "planner.schedule_result.none",
                        comment: ""
                    ))
                }
            }
        }

        // Run scheduler with current empty data (no sample tasks) — constructs constraints from UI
        private func runScheduler() {
            // Build tasks from AssignmentsStore
            let tasks: [AppTask] = AssignmentsStore.shared.incompleteTasks()

            // Build fixed events from CalendarManager's events (treat as locked)
            let fixed: [FixedEvent] = DeviceCalendarManager.shared.events.map { ev in
                FixedEvent(
                    id: UUID(),
                    title: ev.title ?? "",
                    start: ev.startDate,
                    end: ev.endDate,
                    isLocked: true,
                    source: .calendar
                )
            }

            let now = Date()
            let end = Calendar.current.date(byAdding: .day, value: horizonDays, to: now)!

            // Load preferences and use learned energy profile
            let prefs = SchedulerPreferencesStore.shared.preferences
            var energy: [Int: Double] = (0 ..< 24)
                .reduce(into: [:]) { acc, hr in acc[hr] = (hr >= 9 && hr <= 21) ? 0.8 : 0.3 }
            for (h, v) in prefs.learnedEnergyProfile {
                energy[h] = v
            }

            let constraints = Constraints(
                horizonStart: now,
                horizonEnd: end,
                dayStartHour: 7,
                dayEndHour: 23,
                allowedWeekdays: Set(AppSettingsModel.shared.workdayWeekdays),
                maxStudyMinutesPerDay: 6 * 60,
                maxStudyMinutesPerBlock: maxBlockMinutes,
                minGapBetweenBlocksMinutes: 10,
                doNotScheduleWindows: [],
                energyProfile: energy
            )

            // Call scheduler (use learned preferences)
            let res = AIScheduler.generateSchedule(
                tasks: tasks,
                fixedEvents: fixed,
                constraints: constraints,
                preferences: prefs
            )
            self.scheduleResult = res
            self.showScheduleResult = true
        }
    }

    // Simple sheet to show ScheduleResult
    private struct ScheduleResultView: View {
        let result: ScheduleResult

        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text(NSLocalizedString("planner.debug.schedule_result", comment: ""))
                    .font(DesignSystem.Typography.title)

                Text(verbatim: "Blocks: \(result.blocks.count)")
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
                                        Text(verbatim: "Course: \(course.uuidString)")
                                            .font(DesignSystem.Typography.caption)
                                    }
                                }
                                Text(AppSettingsModel.shared.formattedTimeRange(start: b.start, end: b.end))
                                    .font(DesignSystem.Typography.caption)
                            }
                            .contextMenu {
                                Button(NSLocalizedString("planner.debug.mark_kept", comment: "")) {
                                    if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                        let fb = BlockFeedback(
                                            blockId: b.id,
                                            taskId: task.id,
                                            courseId: task.courseId,
                                            type: task.type,
                                            start: b.start,
                                            end: b.end,
                                            completion: 1.0,
                                            action: .kept
                                        )
                                        SchedulerFeedbackStore.shared.append(fb)
                                    }
                                }
                                Button(NSLocalizedString("planner.debug.mark_rescheduled", comment: "")) {
                                    if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                        let fb = BlockFeedback(
                                            blockId: b.id,
                                            taskId: task.id,
                                            courseId: task.courseId,
                                            type: task.type,
                                            start: b.start,
                                            end: b.end,
                                            completion: 0.6,
                                            action: .rescheduled
                                        )
                                        SchedulerFeedbackStore.shared.append(fb)
                                    }
                                }
                                Button(NSLocalizedString("planner.debug.mark_deleted", comment: "")) {
                                    if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                        let fb = BlockFeedback(
                                            blockId: b.id,
                                            taskId: task.id,
                                            courseId: task.courseId,
                                            type: task.type,
                                            start: b.start,
                                            end: b.end,
                                            completion: 0.0,
                                            action: .deleted
                                        )
                                        SchedulerFeedbackStore.shared.append(fb)
                                    }
                                }
                                Button(NSLocalizedString("planner.debug.mark_shortened", comment: "")) {
                                    if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                        let fb = BlockFeedback(
                                            blockId: b.id,
                                            taskId: task.id,
                                            courseId: task.courseId,
                                            type: task.type,
                                            start: b.start,
                                            end: b.end,
                                            completion: 0.4,
                                            action: .shortened
                                        )
                                        SchedulerFeedbackStore.shared.append(fb)
                                    }
                                }
                                Button(NSLocalizedString("planner.debug.mark_extended", comment: "")) {
                                    if let task = AssignmentsStore.shared.tasks.first(where: { $0.id == b.taskId }) {
                                        let fb = BlockFeedback(
                                            blockId: b.id,
                                            taskId: task.id,
                                            courseId: task.courseId,
                                            type: task.type,
                                            start: b.start,
                                            end: b.end,
                                            completion: 1.0,
                                            action: .extended
                                        )
                                        SchedulerFeedbackStore.shared.append(fb)
                                    }
                                }
                            }
                        }
                    }
                }

                Text(NSLocalizedString("planner.debug.logs", comment: ""))
                    .font(DesignSystem.Typography.body)
                List {
                    ForEach(Array(result.log.enumerated()), id: \.offset) { _, line in
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
