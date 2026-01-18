import SwiftUI

#if os(iOS)
    struct IOSIntelligentSchedulingSettingsView: View {
        @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
        @StateObject private var gradeMonitor = GradeMonitoringService.shared
        @StateObject private var autoReschedule = EnhancedAutoRescheduleService.shared
        @StateObject private var settings = AppSettingsModel.shared

        @State private var showingNotifications = false

        var body: some View {
            List {
                IOSIntelligentSchedulingSettingsContent(
                    coordinator: coordinator,
                    gradeMonitor: gradeMonitor,
                    autoReschedule: autoReschedule,
                    settings: settings,
                    showingNotifications: $showingNotifications
                )
            }
            .navigationTitle(NSLocalizedString(
                "settings.category.intelligentScheduling",
                comment: "Intelligent Scheduling"
            ))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingNotifications) {
                AllNotificationsView()
            }
        }

        private func formatHour(_ hour: Int) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h a"
            let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
            return formatter.string(from: date)
        }
    }

    struct IOSIntelligentSchedulingSettingsContent: View {
        @ObservedObject var coordinator: IntelligentSchedulingCoordinator
        @ObservedObject var gradeMonitor: GradeMonitoringService
        @ObservedObject var autoReschedule: EnhancedAutoRescheduleService
        @ObservedObject var settings: AppSettingsModel
        @Binding var showingNotifications: Bool

        var body: some View {
            // MARK: - System Status (Always On)

            Section {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString(
                            "settings.intelligent.title",
                            value: "Intelligent Scheduling",
                            comment: "Intelligent Scheduling title"
                        ))
                        .font(.headline)
                        Text(NSLocalizedString(
                            "settings.intelligent.always_active",
                            value: "Always Active",
                            comment: "Always Active"
                        ))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            } header: {
                Text(NSLocalizedString("settings.intelligent.status.header", value: "Status", comment: "Status header"))
            } footer: {
                Text(NSLocalizedString(
                    "settings.intelligent.status.footer",
                    value: "Intelligent scheduling is always enabled to provide continuous grade monitoring and task rescheduling.",
                    comment: "Status footer"
                ))
            }

            // MARK: - Grade Monitoring

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                        Text(NSLocalizedString(
                            "settings.intelligent.grade_monitoring.title",
                            value: "Grade Monitoring",
                            comment: "Grade monitoring title"
                        ))
                        .font(.headline)
                        Spacer()
                        if gradeMonitor.isMonitoring {
                            Text(NSLocalizedString(
                                "settings.intelligent.grade_monitoring.active",
                                value: "Active",
                                comment: "Active"
                            ))
                            .font(.caption)
                            .foregroundColor(.green)
                        }
                    }
                    Text(NSLocalizedString(
                        "settings.intelligent.grade_monitoring.body",
                        value: "Detects grade changes and suggests study time adjustments",
                        comment: "Grade monitoring body"
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                HStack {
                    Text(NSLocalizedString(
                        "settings.intelligent.grade_monitoring.threshold",
                        value: "Grade Change Threshold",
                        comment: "Grade change threshold"
                    ))
                    Spacer()
                    Text(verbatim: "\(Int(settings.gradeChangeThreshold))%")
                        .foregroundColor(.secondary)
                }

                Slider(
                    value: $settings.gradeChangeThreshold,
                    in: 1 ... 20,
                    step: 1
                ) {
                    Text(NSLocalizedString(
                        "settings.intelligent.grade_monitoring.threshold.label",
                        value: "Threshold",
                        comment: "Threshold label"
                    ))
                } minimumValueLabel: {
                    Text(NSLocalizedString(
                        "settings.intelligent.grade_monitoring.threshold.min",
                        value: "1%",
                        comment: "Threshold min"
                    ))
                    .font(.caption)
                } maximumValueLabel: {
                    Text(NSLocalizedString(
                        "settings.intelligent.grade_monitoring.threshold.max",
                        value: "20%",
                        comment: "Threshold max"
                    ))
                    .font(.caption)
                }

                if !gradeMonitor.studyRecommendations.isEmpty {
                    NavigationLink {
                        StudyRecommendationsView()
                    } label: {
                        HStack {
                            Text(NSLocalizedString(
                                "settings.intelligent.recommendations.active",
                                value: "Active Recommendations",
                                comment: "Active recommendations"
                            ))
                            Spacer()
                            Text(verbatim: "\(gradeMonitor.studyRecommendations.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text(NSLocalizedString(
                    "settings.intelligent.grade_monitoring.header",
                    value: "Grade Monitoring",
                    comment: "Grade monitoring header"
                ))
            } footer: {
                Text(NSLocalizedString(
                    "settings.intelligent.grade_monitoring.footer",
                    value: "Monitors your grades and suggests additional study time when grades decline by the threshold percentage.",
                    comment: "Grade monitoring footer"
                ))
            }

            // MARK: - Auto-Reschedule

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.orange)
                        Text(NSLocalizedString(
                            "settings.intelligent.reschedule.title",
                            value: "Auto-Reschedule",
                            comment: "Auto-reschedule title"
                        ))
                        .font(.headline)
                        Spacer()
                        if autoReschedule.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    Text(NSLocalizedString(
                        "settings.intelligent.reschedule.body",
                        value: "Automatically reschedules overdue tasks based on priority and available time",
                        comment: "Auto-reschedule body"
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                if let lastCheck = autoReschedule.lastCheckTime {
                    HStack {
                        Text(NSLocalizedString(
                            "settings.intelligent.reschedule.last_check",
                            value: "Last Check",
                            comment: "Last check label"
                        ))
                        Spacer()
                        Text(lastCheck, style: .relative)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }

                Picker(
                    NSLocalizedString(
                        "settings.intelligent.reschedule.work_start",
                        value: "Work Hours Start",
                        comment: "Work hours start"
                    ),
                    selection: Binding(
                        get: { autoReschedule.workHoursStart },
                        set: { newValue in
                            coordinator.setWorkHours(
                                start: newValue,
                                end: autoReschedule.workHoursEnd
                            )
                        }
                    )
                ) {
                    ForEach(0 ..< 24) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }

                Picker(
                    NSLocalizedString(
                        "settings.intelligent.reschedule.work_end",
                        value: "Work Hours End",
                        comment: "Work hours end"
                    ),
                    selection: Binding(
                        get: { autoReschedule.workHoursEnd },
                        set: { newValue in
                            coordinator.setWorkHours(
                                start: autoReschedule.workHoursStart,
                                end: newValue
                            )
                        }
                    )
                ) {
                    ForEach(0 ..< 24) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString(
                            "settings.check.interval",
                            value: "Check Interval",
                            comment: "Check Interval"
                        ))
                        Text("How often to scan for missed tasks.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Stepper(value: Binding(
                        get: { settings.autoRescheduleCheckInterval },
                        set: { newValue in
                            settings.autoRescheduleCheckInterval = max(1, min(60, newValue))
                            settings.save()
                        }
                    ), in: 1 ... 60) {
                        Text(verbatim: "\(settings.autoRescheduleCheckInterval) min")
                            .frame(width: 60, alignment: .trailing)
                    }
                }

                Toggle(
                    NSLocalizedString(
                        "settings.toggle.allow.pushing.lower.priority.tasks",
                        value: "Allow Pushing Lower Priority Tasks",
                        comment: "Allow Pushing Lower Priority Tasks"
                    ),
                    isOn: Binding(
                        get: { settings.autoReschedulePushLowerPriority },
                        set: { settings.autoReschedulePushLowerPriority = $0
                            settings.save()
                        }
                    )
                )

                if settings.autoReschedulePushLowerPriority {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString(
                                "settings.max.tasks.to.push",
                                value: "Max Tasks to Push",
                                comment: "Max Tasks to Push"
                            ))
                            Text("Limit how many lower-priority tasks can move.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Stepper(value: Binding(
                            get: { settings.autoRescheduleMaxPushCount },
                            set: { newValue in
                                settings.autoRescheduleMaxPushCount = max(0, min(5, newValue))
                                settings.save()
                            }
                        ), in: 0 ... 5) {
                            Text(verbatim: "\(settings.autoRescheduleMaxPushCount)")
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }

                Button {
                    Task {
                        await coordinator.checkOverdueTasks()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(NSLocalizedString(
                            "settings.intelligent.reschedule.check_now",
                            value: "Check Now",
                            comment: "Check now"
                        ))
                    }
                }

                if !autoReschedule.rescheduleNotifications.isEmpty {
                    NavigationLink {
                        RescheduleNotificationsView()
                    } label: {
                        HStack {
                            Text(NSLocalizedString(
                                "settings.intelligent.reschedule.recent",
                                value: "Recent Reschedules",
                                comment: "Recent reschedules"
                            ))
                            Spacer()
                            Text(verbatim: "\(autoReschedule.rescheduleNotifications.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text(NSLocalizedString(
                    "settings.intelligent.reschedule.header",
                    value: "Auto-Reschedule",
                    comment: "Auto-reschedule header"
                ))
            } footer: {
                Text(NSLocalizedString(
                    "settings.intelligent.reschedule.footer",
                    value: "Checks for overdue tasks hourly and automatically reschedules them to the next available time slot based on priority.",
                    comment: "Auto-reschedule footer"
                ))
            }

            // MARK: - All Notifications

            if !coordinator.allNotifications.isEmpty {
                Section {
                    Button {
                        showingNotifications = true
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.red)
                            Text(NSLocalizedString(
                                "settings.intelligent.notifications.view_all",
                                value: "View All Notifications",
                                comment: "View all notifications"
                            ))
                            Spacer()
                            Text(verbatim: "\(coordinator.allNotifications.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.intelligent.notifications.header",
                        value: "Notifications",
                        comment: "Notifications header"
                    ))
                }
            }
        }

        private func formatHour(_ hour: Int) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h a"
            let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
            return formatter.string(from: date)
        }
    }

    // MARK: - Study Recommendations View

    struct StudyRecommendationsView: View {
        @StateObject private var gradeMonitor = GradeMonitoringService.shared
        @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared

        var body: some View {
            List {
                ForEach(gradeMonitor.studyRecommendations) { recommendation in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(recommendation.courseName)
                                    .font(.headline)
                                Text(recommendation.reason)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                coordinator.dismissNotification(.studyTime(recommendation))
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityLabel("Dismiss notification")
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading) {
                                Text(NSLocalizedString(
                                    "settings.intelligent.recommendations.current",
                                    value: "Current",
                                    comment: "Current label"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                Text(String(
                                    format: NSLocalizedString(
                                        "settings.intelligent.recommendations.hours_per_week",
                                        value: "%.1f hrs/week",
                                        comment: "Hours per week"
                                    ),
                                    recommendation.currentWeeklyHours
                                ))
                                .font(.callout)
                                .fontWeight(.medium)
                            }

                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading) {
                                Text(NSLocalizedString(
                                    "settings.intelligent.recommendations.suggested",
                                    value: "Suggested",
                                    comment: "Suggested label"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                Text(String(
                                    format: NSLocalizedString(
                                        "settings.intelligent.recommendations.hours_per_week",
                                        value: "%.1f hrs/week",
                                        comment: "Hours per week"
                                    ),
                                    recommendation.suggestedWeeklyHours
                                ))
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text(NSLocalizedString(
                                    "settings.intelligent.recommendations.additional",
                                    value: "Additional",
                                    comment: "Additional label"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                Text(String(
                                    format: NSLocalizedString(
                                        "settings.intelligent.recommendations.additional_hours",
                                        value: "+%.1f hrs",
                                        comment: "Additional hours"
                                    ),
                                    recommendation.additionalHours
                                ))
                                .font(.callout)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            }
                        }

                        (Text(NSLocalizedString(
                            "settings.intelligent.recommendations.recommended_prefix",
                            value: "Recommended",
                            comment: "Recommended prefix"
                        ))
                            + Text(NSLocalizedString(" ", value: " ", comment: ""))
                            + Text(recommendation.timestamp, style: .relative))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(NSLocalizedString(
                "settings.intelligent.recommendations.title",
                value: "Study Recommendations",
                comment: "Study recommendations title"
            ))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Reschedule Notifications View

    struct RescheduleNotificationsView: View {
        @StateObject private var autoReschedule = EnhancedAutoRescheduleService.shared
        @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared

        var body: some View {
            List {
                ForEach(autoReschedule.rescheduleNotifications) { notification in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(notification.assignmentTitle)
                                    .font(.headline)
                                if let courseName = notification.courseName {
                                    Text(courseName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                coordinator.dismissNotification(.reschedule(notification))
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityLabel("Dismiss notification")
                        }

                        HStack {
                            Label(notification.priority.rawValue.capitalized, systemImage: "exclamationmark.circle")
                                .font(.caption)
                                .foregroundColor(priorityColor(notification.priority))
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(NSLocalizedString(
                                    "settings.intelligent.reschedule.old_deadline",
                                    value: "Old deadline:",
                                    comment: "Old deadline label"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                Text(notification.oldDueDate, style: .date)
                                    .font(.caption)
                            }

                            HStack {
                                Text(NSLocalizedString(
                                    "settings.intelligent.reschedule.new_deadline",
                                    value: "New deadline:",
                                    comment: "New deadline label"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                Text(notification.newDueDate, style: .date)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }

                            HStack {
                                Text(NSLocalizedString(
                                    "settings.intelligent.reschedule.start_by",
                                    value: "Start by:",
                                    comment: "Start by label"
                                ))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                Text(notification.suggestedStartTime, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        (Text(NSLocalizedString(
                            "settings.intelligent.reschedule.rescheduled_prefix",
                            value: "Rescheduled",
                            comment: "Rescheduled prefix"
                        ))
                            + Text(NSLocalizedString(" ", value: " ", comment: ""))
                            + Text(notification.timestamp, style: .relative))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(NSLocalizedString(
                "settings.intelligent.reschedule.recent.title",
                value: "Recent Reschedules",
                comment: "Recent reschedules title"
            ))
            .navigationBarTitleDisplayMode(.inline)
        }

        private func priorityColor(_ priority: AssignmentUrgency) -> Color {
            switch priority {
            case .low: .green
            case .medium: .yellow
            case .high: .orange
            case .critical: .red
            }
        }
    }

    // MARK: - All Notifications View

    struct AllNotificationsView: View {
        @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationView {
                List {
                    ForEach(coordinator.allNotifications) { notification in
                        switch notification {
                        case let .studyTime(rec):
                            StudyTimeNotificationRow(recommendation: rec)
                        case let .reschedule(not):
                            RescheduleNotificationRow(notification: not)
                        }
                    }
                }
                .navigationTitle(NSLocalizedString(
                    "settings.intelligent.notifications.all",
                    value: "All Notifications",
                    comment: "All notifications title"
                ))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("common.done", comment: "Done")) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    struct StudyTimeNotificationRow: View {
        let recommendation: StudyTimeRecommendation
        @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                    Text(NSLocalizedString(
                        "settings.intelligent.notifications.study_time",
                        value: "Study Time Recommendation",
                        comment: "Study time recommendation"
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        coordinator.dismissNotification(.studyTime(recommendation))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Dismiss notification")
                }

                Text(recommendation.courseName)
                    .font(.headline)

                Text(String(
                    format: NSLocalizedString(
                        "settings.intelligent.notifications.study_time.body",
                        value: "Increase study time by %.1f hours per week",
                        comment: "Study time recommendation body"
                    ),
                    recommendation.additionalHours
                ))
                .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }

    struct RescheduleNotificationRow: View {
        let notification: EnhancedAutoRescheduleService.RescheduleNotification
        @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.orange)
                    Text(NSLocalizedString(
                        "settings.intelligent.notifications.rescheduled",
                        value: "Task Rescheduled",
                        comment: "Task rescheduled"
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        coordinator.dismissNotification(.reschedule(notification))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Dismiss notification")
                }

                Text(notification.assignmentTitle)
                    .font(.headline)

                (Text(NSLocalizedString(
                    "settings.intelligent.reschedule.new_deadline",
                    value: "New deadline:",
                    comment: "New deadline label"
                ))
                    + Text(NSLocalizedString(" ", value: " ", comment: ""))
                    + Text(notification.newDueDate, style: .date))
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }

    #Preview {
        NavigationView {
            IOSIntelligentSchedulingSettingsView()
        }
    }

#endif
