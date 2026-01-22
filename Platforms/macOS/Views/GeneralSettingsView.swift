#if os(macOS)
    import SwiftUI

    struct GeneralSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @EnvironmentObject var timerManager: TimerManager
        @EnvironmentObject var assignmentsStore: AssignmentsStore
        @EnvironmentObject var coursesStore: CoursesStore
        @EnvironmentObject var plannerStore: PlannerStore
        @EnvironmentObject var gradesStore: GradesStore

        @State private var showResetSheet = false
        @State private var resetCode: String = ""
        @State private var resetInput: String = ""
        @State private var isResetting = false
        @State private var didCopyResetCode = false

        enum StartOfWeek: String, CaseIterable, Identifiable {
            case sunday = "Sunday"
            case monday = "Monday"

            var id: String { rawValue }
        }

        enum DefaultView: String, CaseIterable, Identifiable {
            case dashboard = "Dashboard"
            case calendar = "Calendar"
            case planner = "Planner"
            case courses = "Courses"

            var id: String { rawValue }
        }

        enum PlannerLookahead: String, CaseIterable, Identifiable {
            case oneWeek = "1w"
            case twoWeeks = "2w"
            case oneMonth = "1m"
            case twoMonths = "2m"

            var id: String { rawValue }

            var displayName: String {
                switch self {
                case .oneWeek: NSLocalizedString("settings.planner.lookahead.1week", value: "1 Week", comment: "1 Week")
                case .twoWeeks: NSLocalizedString(
                        "settings.planner.lookahead.2weeks",
                        value: "2 Weeks",
                        comment: "2 Weeks"
                    )
                case .oneMonth: NSLocalizedString(
                        "settings.planner.lookahead.1month",
                        value: "1 Month",
                        comment: "1 Month"
                    )
                case .twoMonths: NSLocalizedString(
                        "settings.planner.lookahead.2months",
                        value: "2 Months",
                        comment: "2 Months"
                    )
                }
            }
        }

        enum BreakDuration: String, CaseIterable, Identifiable {
            case five = "5 minutes"
            case ten = "10 minutes"
            case fifteen = "15 minutes"

            var id: String { rawValue }

            var minutes: Int {
                switch self {
                case .five: 5
                case .ten: 10
                case .fifteen: 15
                }
            }
        }

        enum EnergyLevel: String, CaseIterable, Identifiable {
            case low = "Low"
            case medium = "Medium"
            case high = "High"

            var id: String { rawValue }
        }

        @State private var startOfWeek: StartOfWeek = .sunday
        @State private var defaultView: DefaultView = .dashboard
        @State private var breakDuration: BreakDuration = .five
        @State private var energyLevel: EnergyLevel = .medium

        var body: some View {
            Form {
                Section("Preferences") {
                    Picker("Start of Week", selection: $startOfWeek) {
                        ForEach(StartOfWeek.allCases) { day in
                            Text(day.rawValue).tag(day)
                        }
                    }
                    .onChange(of: startOfWeek) { _, newValue in
                        settings.startOfWeek = newValue.rawValue
                        settings.save()
                    }

                    Picker("Default View", selection: $defaultView) {
                        ForEach(DefaultView.allCases) { view in
                            Text(view.rawValue).tag(view)
                        }
                    }
                    .onChange(of: defaultView) { _, newValue in
                        settings.defaultView = newValue.rawValue
                        settings.save()
                    }
                }

                Section("Display") {
                    Toggle(
                        NSLocalizedString(
                            "settings.toggle.24hour.time",
                            value: "24-Hour Time",
                            comment: "24-Hour Time"
                        ),
                        isOn: $settings.use24HourTime
                    )
                    .onChange(of: settings.use24HourTime) { _, _ in settings.save() }
                }

                Section("Workday") {
                    DatePicker("Start", selection: Binding(
                        get: { settings.date(from: settings.defaultWorkdayStart) },
                        set: { settings.defaultWorkdayStart = settings.components(from: $0)
                            settings.save()
                        }
                    ), displayedComponents: .hourAndMinute)

                    DatePicker("End", selection: Binding(
                        get: { settings.date(from: settings.defaultWorkdayEnd) },
                        set: { settings.defaultWorkdayEnd = settings.components(from: $0)
                            settings.save()
                        }
                    ), displayedComponents: .hourAndMinute)
                    HStack(alignment: .center) {
                        Text("Days")
                        Spacer(minLength: 12)
                        HStack(spacing: 6) {
                            ForEach(weekdayOptions, id: \.index) { day in
                                Button(day.label) {
                                    toggleWorkday(day.index)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(
                                            settings.workdayWeekdays.contains(day.index)
                                                ? Color.accentColor.opacity(0.2)
                                                : Color.secondary.opacity(0.1)
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            settings.workdayWeekdays.contains(day.index)
                                                ? Color.accentColor
                                                : Color.secondary.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }
                }

                Section {
                    Picker("Break Duration", selection: $breakDuration) {
                        ForEach(BreakDuration.allCases) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .onChange(of: breakDuration) { _, newValue in
                        settings.defaultBreakDuration = newValue.minutes
                        settings.save()
                    }

                    Picker("Default Energy Level", selection: $energyLevel) {
                        ForEach(EnergyLevel.allCases) { level in
                            HStack {
                                energyIcon(for: level)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                    .onChange(of: energyLevel) { _, newValue in
                        settings.defaultEnergyLevel = newValue.rawValue
                        settings.save()
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.study.session.defaults",
                        value: "Study Session Defaults",
                        comment: "Study Session Defaults"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.these.settings.determine.your.default",
                        value: "These settings determine your default study session configuration. You can adjust them for individual sessions.",
                        comment: "These settings determine your default study sessio..."
                    ))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                }

                Section {
                    Toggle(
                        NSLocalizedString(
                            "settings.toggle.autoschedule.breaks",
                            value: "Auto-Schedule Breaks",
                            comment: "Auto-Schedule Breaks"
                        ),
                        isOn: $settings.autoScheduleBreaks
                    )
                    .onChange(of: settings.autoScheduleBreaks) { _, _ in
                        settings.save()
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.study.features",
                        value: "Study Features",
                        comment: "Study Features"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.auto.breaks.description",
                        value: "Automatically schedule breaks during study sessions to maintain focus and productivity.",
                        comment: "Auto-schedule breaks description"
                    ))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                }

                Section {
                    Toggle(
                        NSLocalizedString(
                            "settings.toggle.weekly.summary.notifications",
                            value: "Weekly Summary Notifications",
                            comment: "Weekly Summary Notifications"
                        ),
                        isOn: $settings.weeklySummaryNotifications
                    )
                    .onChange(of: settings.weeklySummaryNotifications) { _, _ in
                        settings.save()
                        NotificationManager.shared.updateSmartNotificationSchedules()
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.notifications",
                        value: "Notifications",
                        comment: "Notifications"
                    ))
                }

                Section("Auto-Reschedule") {
                    Toggle(
                        NSLocalizedString(
                            "settings.toggle.enable.autoreschedule",
                            value: "Enable Auto-Reschedule",
                            comment: "Enable Auto-Reschedule"
                        ),
                        isOn: Binding(
                            get: { settings.enableAutoReschedule },
                            set: { newValue in
                                settings.enableAutoReschedule = newValue
                                settings.save()
                                if newValue {
                                    MissedEventDetectionService.shared.startMonitoring()
                                } else {
                                    MissedEventDetectionService.shared.stopMonitoring()
                                }
                            }
                        )
                    )
                    .help("Automatically reschedule missed tasks to available time slots")

                    if settings.enableAutoReschedule {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString(
                                    "settings.check.interval",
                                    value: "Check Interval",
                                    comment: "Check Interval"
                                ))
                                Text("How often to scan for missed tasks.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Stepper(value: Binding(
                                get: { settings.autoRescheduleCheckInterval },
                                set: { newValue in
                                    settings.autoRescheduleCheckInterval = max(1, min(60, newValue))
                                    settings.save()
                                    if settings.enableAutoReschedule {
                                        MissedEventDetectionService.shared.stopMonitoring()
                                        MissedEventDetectionService.shared.startMonitoring()
                                    }
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
                        .help("Move lower priority tasks to make room for high-priority missed tasks")

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
                                        .foregroundStyle(.secondary)
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
                    }

                    Text(settings.enableAutoReschedule
                        ? "Tasks you've manually edited or locked will never be moved automatically."
                        : "When enabled, missed tasks are automatically rescheduled to keep your schedule current.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Demo Data") {
                    Button {
                        loadSampleData()
                    } label: {
                        Label("Show Sample Data", systemImage: "sparkles")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    
                    Text("Load sample courses, assignments, and grades to explore the app. Your current data remains saved and can be restored.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Danger Zone") {
                    Button(role: .destructive) {
                        resetInput = ""
                        showResetSheet = true
                    } label: {
                        Text(NSLocalizedString(
                            "settings.reset.all.data",
                            value: "Reset All Data",
                            comment: "Reset All Data"
                        ))
                        .fontWeight(.semibold)
                    }
                }
            }
            .formStyle(.grouped)
            .compactFormSections()
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .controlBackgroundColor))
            .navigationTitle("General")
            .onAppear {
                startOfWeek = StartOfWeek(rawValue: settings.startOfWeek) ?? .sunday
                defaultView = DefaultView(rawValue: settings.defaultView) ?? .dashboard
                loadProfileDefaults()
            }
            .sheet(isPresented: $showResetSheet) {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString(
                            "settings.reset.all.data",
                            value: "Reset All Data",
                            comment: "Reset All Data"
                        ))
                        .font(.title2.weight(.bold))
                        Text(NSLocalizedString(
                            "settings.this.will.remove.all.app",
                            value: "This will remove all app data including courses, assignments, settings, and cached sessions. This action cannot be undone.",
                            comment: "This will remove all app data including courses, a..."
                        ))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString(
                            "settings.type.the.code.to.confirm",
                            value: "Type the code to confirm",
                            comment: "Type the code to confirm"
                        ))
                        .font(.headline.weight(.semibold))
                        HStack {
                            Text(resetCode)
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.red.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
                                )
                            Button {
                                Clipboard.copy(resetCode)
                                didCopyResetCode = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    didCopyResetCode = false
                                }
                            } label: {
                                Text(didCopyResetCode ? "Copied" : "Copy")
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.itoriLiquidProminent)
                            .controlSize(.small)
                            Spacer()
                        }
                        TextField("Enter code exactly", text: $resetInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .disableAutocorrection(true)
                    }

                    HStack(spacing: 12) {
                        Button(NSLocalizedString("settings.button.cancel", value: "Cancel", comment: "Cancel")) {
                            showResetSheet = false
                        }
                        .buttonStyle(.itariLiquid)
                        Spacer()
                        Button(NSLocalizedString(
                            "settings.button.reset.now",
                            value: "Reset Now",
                            comment: "Reset Now"
                        )) {
                            performReset()
                        }
                        .buttonStyle(.itoriLiquidProminent)
                        .tint(.red)
                        .keyboardShortcut(.defaultAction)
                        .disabled(!resetCodeMatches || isResetting)
                    }
                }
                .padding(26)
                .frame(minWidth: 440, maxWidth: 520)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(DesignSystem.Materials.card)
                )
                .padding()
                .onAppear {
                    if resetCode.isEmpty {
                        resetCode = ConfirmationCode.generate()
                    }
                }
            }
            .onChange(of: showResetSheet) { _, isPresented in
                if !isPresented {
                    resetCode = ""
                    resetInput = ""
                    didCopyResetCode = false
                }
            }
        }

        private func performReset() {
            guard resetCodeMatches else { return }
            isResetting = true
            AppModel.shared.requestReset()
            timerManager.stop()
            // Reset local UI state
            startOfWeek = .sunday
            defaultView = .dashboard
            resetInput = ""
            showResetSheet = false
            isResetting = false
        }

        private var resetCodeMatches: Bool {
            resetInput.trimmingCharacters(in: .whitespacesAndNewlines) == resetCode
        }

        private var weekdayOptions: [(index: Int, label: String)] {
            Calendar.current.shortWeekdaySymbols.enumerated().map { idx, label in
                (index: idx + 1, label: label)
            }
        }

        private func toggleWorkday(_ index: Int) {
            var days = Set(settings.workdayWeekdays)
            if days.contains(index) {
                if days.count == 1 { return }
                days.remove(index)
            } else {
                days.insert(index)
            }
            settings.workdayWeekdays = Array(days).sorted()
            settings.save()
        }

        private func energyIcon(for level: EnergyLevel) -> some View {
            Group {
                switch level {
                case .low:
                    Image(systemName: "battery.25")
                        .foregroundStyle(.orange)
                case .medium:
                    Image(systemName: "battery.50")
                        .foregroundStyle(.yellow)
                case .high:
                    Image(systemName: "battery.100")
                        .foregroundStyle(.green)
                }
            }
            .font(DesignSystem.Typography.body)
        }

        private func loadProfileDefaults() {
            let breakDurationValue = settings.defaultBreakDuration
            switch breakDurationValue {
            case 5: breakDuration = .five
            case 10: breakDuration = .ten
            case 15: breakDuration = .fifteen
            default: breakDuration = .five
            }

            energyLevel = EnergyLevel(rawValue: settings.defaultEnergyLevel) ?? .medium
        }
        
        private func loadSampleData() {
            let calendar = Calendar.current
            let now = Date()
            
            // Create sample semesters if none exist
            if coursesStore.semesters.isEmpty {
                createSampleSemesters()
            }
            
            // Use existing current semester or create one
            let targetSemester: Semester
            if let currentSemester = coursesStore.semesters.first(where: { $0.isCurrent }) {
                targetSemester = currentSemester
            } else if let firstSemester = coursesStore.semesters.first {
                targetSemester = firstSemester
                coursesStore.currentSemesterId = firstSemester.id
            } else {
                // Create a sample semester as fallback
                let semesterStart = calendar.date(byAdding: .month, value: -2, to: now) ?? now
                let semesterEnd = calendar.date(byAdding: .month, value: 2, to: now) ?? now
                let semester = Semester(
                    id: UUID(),
                    name: "Spring 2026",
                    startDate: semesterStart,
                    endDate: semesterEnd,
                    isArchived: false,
                    isCurrent: true,
                    educationLevel: .college,
                    semesterTerm: .spring,
                    academicYear: "2025-2026"
                )
                coursesStore.addSemester(semester)
                coursesStore.currentSemesterId = semester.id
                targetSemester = semester
            }
            
            // Sample courses with different colors
            let sampleCourses: [(title: String, code: String, color: String, instructor: String)] = [
                ("Introduction to Computer Science", "CS 101", ColorTag.blue.hexValue, "Dr. Sarah Johnson"),
                ("Calculus II", "MATH 201", ColorTag.purple.hexValue, "Prof. Michael Chen"),
                ("World History", "HIST 150", ColorTag.green.hexValue, "Dr. Emily Rodriguez"),
                ("Biology Lab", "BIO 120", ColorTag.orange.hexValue, "Prof. David Kim"),
                ("Creative Writing", "ENG 225", ColorTag.pink.hexValue, "Dr. Jennifer Martinez")
            ]
            
            var createdCourses: [Course] = []
            for sample in sampleCourses {
                let course = Course(
                    id: UUID(),
                    title: sample.title,
                    code: sample.code,
                    semesterId: targetSemester.id,
                    colorHex: sample.color,
                    isArchived: false,
                    courseType: .regular,
                    instructor: sample.instructor,
                    location: "Main Campus",
                    credits: 3.0,
                    creditType: .credits,
                    meetingTimes: nil,
                    syllabus: nil,
                    notes: nil,
                    attachments: []
                )
                coursesStore.addCourse(course)
                createdCourses.append(course)
            }
            
            // Sample assignments with realistic due dates
            let sampleAssignments: [(title: String, type: TaskType, daysFromNow: Int, courseIndex: Int, estimatedMinutes: Int)] = [
                // Upcoming assignments
                ("Final Project Proposal", .project, 3, 0, 120),
                ("Weekly Problem Set", .homework, 2, 1, 90),
                ("Essay Draft: Renaissance Art", .homework, 5, 2, 150),
                ("Lab Report: Cell Division", .homework, 4, 3, 60),
                ("Short Story Submission", .homework, 6, 4, 180),
                
                // This week
                ("Midterm Exam", .exam, 7, 0, 120),
                ("Quiz: Derivatives", .quiz, 1, 1, 30),
                ("Reading: Chapter 12-14", .reading, 2, 2, 45),
                
                // Completed assignments
                ("Database Design Project", .project, -7, 0, 240),
                ("Integration Homework", .homework, -5, 1, 75),
                ("History Presentation", .project, -10, 2, 90)
            ]
            
            for sample in sampleAssignments {
                let dueDate = calendar.date(byAdding: .day, value: sample.daysFromNow, to: now) ?? now
                let course = createdCourses[sample.courseIndex]
                
                let task = AppTask(
                    id: UUID(),
                    title: sample.title,
                    type: sample.type,
                    category: sample.type,
                    courseId: course.id,
                    courseName: course.title,
                    courseCode: course.code,
                    due: dueDate,
                    estimatedMinutes: sample.estimatedMinutes,
                    isCompleted: sample.daysFromNow < 0,
                    completedAt: sample.daysFromNow < 0 ? dueDate : nil,
                    locked: false,
                    hasExplicitDueTime: false,
                    priority: .medium,
                    tags: [],
                    notes: nil,
                    attachments: [],
                    subtasks: [],
                    dependencies: [],
                    recurrence: nil,
                    isPersonal: false,
                    createdAt: calendar.date(byAdding: .day, value: sample.daysFromNow - 14, to: now) ?? now,
                    updatedAt: now
                )
                assignmentsStore.addTask(task)
            }
            
            // Sample grades
            let sampleGrades: [(courseIndex: Int, percent: Double, letter: String)] = [
                (0, 92.5, "A"),
                (1, 88.0, "B+"),
                (2, 95.0, "A"),
                (3, 85.5, "B"),
                (4, 90.0, "A-")
            ]
            
            for sample in sampleGrades {
                let course = createdCourses[sample.courseIndex]
                gradesStore.upsert(
                    courseId: course.id,
                    percent: sample.percent,
                    letter: sample.letter
                )
            }
            
            // Create sample plans for upcoming assignments
            let upcomingTasks = assignmentsStore.tasks.filter { task in
                guard let due = task.due else { return false }
                return due > now && due < calendar.date(byAdding: .day, value: 8, to: now)!
            }
            
            for task in upcomingTasks {
                let plan = AssignmentPlan(
                    assignmentId: task.id,
                    steps: generateSamplePlanSteps(for: task),
                    createdAt: now,
                    updatedAt: now
                )
                AssignmentPlansStore.shared.savePlan(plan)
            }
            
            // Trigger notifications
            NotificationCenter.default.post(name: .init("SampleDataLoaded"), object: nil)
        }
        
        private func createSampleSemesters() {
            let calendar = Calendar.current
            let now = Date()
            let currentYear = calendar.component(.year, from: now)
            let currentMonth = calendar.component(.month, from: now)
            
            // Determine which semesters to create based on current month
            let semestersToCreate: [(term: SemesterTerm, year: Int, isCurrent: Bool)] = {
                if currentMonth >= 1 && currentMonth <= 5 {
                    // Spring semester - create Fall (previous), Spring (current), Summer (upcoming)
                    return [
                        (.fall, currentYear - 1, false),
                        (.spring, currentYear, true),
                        (.summer, currentYear, false)
                    ]
                } else if currentMonth >= 6 && currentMonth <= 7 {
                    // Summer - create Spring (previous), Summer (current), Fall (upcoming)
                    return [
                        (.spring, currentYear, false),
                        (.summer, currentYear, true),
                        (.fall, currentYear, false)
                    ]
                } else {
                    // Fall semester - create Summer (previous), Fall (current), Spring (next)
                    return [
                        (.summer, currentYear, false),
                        (.fall, currentYear, true),
                        (.spring, currentYear + 1, false)
                    ]
                }
            }()
            
            for semesterInfo in semestersToCreate {
                let semester = createSemester(
                    term: semesterInfo.term,
                    year: semesterInfo.year,
                    isCurrent: semesterInfo.isCurrent
                )
                coursesStore.addSemester(semester)
                
                if semesterInfo.isCurrent {
                    coursesStore.currentSemesterId = semester.id
                }
            }
        }
        
        private func createSemester(term: SemesterTerm, year: Int, isCurrent: Bool) -> Semester {
            let calendar = Calendar.current
            
            // Define semester date ranges
            let (startMonth, startDay, endMonth, endDay, academicYearStart) = {
                switch term {
                case .spring:
                    return (1, 15, 5, 15, year - 1) // Jan 15 - May 15
                case .summer:
                    return (6, 1, 7, 31, year - 1) // Jun 1 - Jul 31
                case .fall:
                    return (8, 20, 12, 15, year) // Aug 20 - Dec 15
                case .winter:
                    return (12, 16, 1, 14, year - 1) // Dec 16 - Jan 14
                }
            }()
            
            let startComponents = DateComponents(year: year, month: startMonth, day: startDay)
            let endYear = term == .winter ? year + 1 : year
            let endComponents = DateComponents(year: endYear, month: endMonth, day: endDay)
            
            let startDate = calendar.date(from: startComponents) ?? Date()
            let endDate = calendar.date(from: endComponents) ?? Date()
            
            let academicYear = "\(academicYearStart)-\(academicYearStart + 1)"
            
            return Semester(
                id: UUID(),
                name: "\(term.rawValue.capitalized) \(year)",
                startDate: startDate,
                endDate: endDate,
                isArchived: false,
                isCurrent: isCurrent,
                educationLevel: .college,
                semesterTerm: term,
                academicYear: academicYear
            )
        }
        
        private func generateSamplePlanSteps(for task: AppTask) -> [PlanStep] {
            let baseSteps: [(String, Double)] = {
                switch task.category {
                case .project:
                    return [
                        ("Research and gather materials", 0.3),
                        ("Create outline", 0.15),
                        ("Write first draft", 0.35),
                        ("Review and finalize", 0.2)
                    ]
                case .homework:
                    return [
                        ("Review lecture notes", 0.25),
                        ("Solve problems", 0.6),
                        ("Check work", 0.15)
                    ]
                case .reading:
                    return [
                        ("Read assigned chapters", 0.7),
                        ("Take notes", 0.3)
                    ]
                case .exam:
                    return [
                        ("Review all materials", 0.4),
                        ("Practice problems", 0.4),
                        ("Mock test", 0.2)
                    ]
                default:
                    return [("Complete assignment", 1.0)]
                }
            }()
            
            return baseSteps.enumerated().map { index, step in
                PlanStep(
                    id: UUID(),
                    title: step.0,
                    expectedMinutes: Int(Double(task.estimatedMinutes) * step.1),
                    isCompleted: false,
                    order: index
                )
            }
        }
    }

    #if !DISABLE_PREVIEWS
        #if !DISABLE_PREVIEWS
            #Preview {
                GeneralSettingsView()
                    .environmentObject(AppSettingsModel.shared)
                    .environmentObject(TimerManager())
                    .environmentObject(AssignmentsStore.shared)
                    .environmentObject(CoursesStore())
                    .frame(width: 500, height: 600)
            }
        #endif
    #endif
#endif
