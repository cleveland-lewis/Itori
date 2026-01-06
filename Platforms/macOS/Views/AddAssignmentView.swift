#if os(macOS)
import SwiftUI
import EventKit

struct AddAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var settings: AppSettingsModel

    @State private var title: String = ""
    @State private var due: Date = Date()
    @State private var estimatedMinutes: Int = 60
    @State private var selectedCourseId: UUID? = nil
    @State private var selectedModuleIds: Set<UUID> = []
    @State private var type: TaskType
    @State private var attachments: [Attachment] = []
    @State private var notes: String = ""
    @State private var showDiscardDialog = false
    @State private var showingAddCourse = false
    @State private var lockToDueDate = false
    @State private var weightPercent: Double = 0
    @State private var urgency: AssignmentUrgency = .medium
    @State private var status: AssignmentStatus = .notStarted
    @State private var recurrenceEnabled: Bool = false
    @State private var recurrenceFrequency: RecurrenceRule.Frequency = .weekly
    @State private var recurrenceInterval: Int = 1
    @State private var recurrenceEndOption: RecurrenceEndOption = .never
    @State private var recurrenceEndDate: Date = Date()
    @State private var recurrenceEndCount: Int = 3
    @State private var skipWeekends: Bool = false
    @State private var skipHolidays: Bool = false
    @State private var holidaySource: RecurrenceRule.HolidaySource = .deviceCalendar

    var onSave: (AppTask) -> Void

    init(initialType: TaskType = .project, preselectedCourseId: UUID? = nil, onSave: @escaping (AppTask) -> Void) {
        self.onSave = onSave
        self._type = State(initialValue: initialType)
        self._selectedCourseId = State(initialValue: preselectedCourseId)
    }

    private enum RecurrenceEndOption: String, CaseIterable, Identifiable {
        case never
        case onDate
        case afterOccurrences

        var id: String { rawValue }
    }

    private enum RecurrenceSelection: String, CaseIterable, Identifiable {
        case none
        case daily
        case weekly
        case monthly
        case yearly

        var id: String { rawValue }

        var label: String {
            switch self {
            case .none: return "None"
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }

        var frequency: RecurrenceRule.Frequency {
            switch self {
            case .none: return .weekly
            case .daily: return .daily
            case .weekly: return .weekly
            case .monthly: return .monthly
            case .yearly: return .yearly
            }
        }
    }

    private var isSaveDisabled: Bool {
        // Only require title - course is now optional for personal tasks
        let titleEmpty = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let modulesValid: Bool = {
            guard type == .exam || type == .quiz else { return true }
            return !selectedModuleIds.isEmpty
        }()
        return titleEmpty || !modulesValid
    }

    private var hasUnsavedChanges: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty || selectedCourseId != nil || !attachments.isEmpty || !notes.isEmpty || due.timeIntervalSince1970 != 0
    }
    
    private var currentStepSize: Int {
        type.stepSize
    }
    
    private var decompositionHintText: String {
        DurationEstimator.decompositionHint(
            category: type.asAssignmentCategory,
            estimatedMinutes: estimatedMinutes,
            dueDate: due
        )
    }

    var body: some View {
        ZStack {
            AppCard {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero inputs
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Title", text: $title)
                            .font(.title3.weight(.semibold))
                            .textFieldStyle(.plain)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(DesignSystem.Materials.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        HStack(spacing: 12) {
                            coursePicker
                            categoryPicker
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("Modules", value: "Modules", comment: ""))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        if availableModules.isEmpty {
                            Text(selectedCourseId == nil ? "Select a course to choose modules." : "No modules added for this course yet.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(availableModules) { module in
                                Toggle(module.title, isOn: moduleBinding(module.id))
                            }
                        }
                        if type == .exam || type == .quiz {
                            Text(NSLocalizedString("Exams and quizzes require at least one module.", value: "Exams and quizzes require at least one module.", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Timing
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("addassignment.timing", value: "TIMING", comment: "TIMING"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        RootsCard(compact: true) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(NSLocalizedString("addassignment.due.date", value: "Due Date", comment: "Due Date"))
                                    Spacer()
                                    DatePicker("", selection: $due, displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.field)
                                        .labelsHidden()
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(NSLocalizedString("addassignment.estimated", value: "Estimated", comment: "Estimated"))
                                        
                                        Spacer()
                                        
                                        Stepper(value: $estimatedMinutes, in: 15...240, step: currentStepSize) {
                                            Text(verbatim: "\(estimatedMinutes) min")
                                        }
                                    }
                                    
                                    Text(decompositionHintText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                HStack {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(NSLocalizedString("addassignment.lock", value: "Lock", comment: "Lock"))
                                            .font(.body)
                                        Text(NSLocalizedString("addassignment.lock.work.to.due.date", value: "Lock work to due date", comment: "Lock work to due date"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle(NSLocalizedString("addassignment.toggle.", value: "", comment: ""), isOn: $lockToDueDate)
                                        .labelsHidden()
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(NSLocalizedString("addassignment.repeat", value: "Repeat", comment: "Repeat"))
                                        Spacer()
                                        Picker("", selection: recurrenceSelection) {
                                            ForEach(RecurrenceSelection.allCases) { option in
                                                Text(option.label).tag(option)
                                            }
                                        }
                                        .labelsHidden()
                                        .pickerStyle(.menu)
                                    }

                                    if recurrenceEnabled {
                                        Stepper(value: $recurrenceInterval, in: 1...30) {
                                            Text(verbatim: "Every \(recurrenceInterval) \(recurrenceUnitLabel)")
                                        }

                                        Picker("End", selection: $recurrenceEndOption) {
                                            Text(NSLocalizedString("addassignment.never", value: "Never", comment: "Never")).tag(RecurrenceEndOption.never)
                                            Text(NSLocalizedString("addassignment.on.date", value: "On Date", comment: "On Date")).tag(RecurrenceEndOption.onDate)
                                            Text(NSLocalizedString("addassignment.after", value: "After", comment: "After")).tag(RecurrenceEndOption.afterOccurrences)
                                        }
                                        .pickerStyle(.menu)

                                        if recurrenceEndOption == .onDate {
                                            DatePicker("End Date", selection: $recurrenceEndDate, displayedComponents: .date)
                                        } else if recurrenceEndOption == .afterOccurrences {
                                            Stepper(value: $recurrenceEndCount, in: 1...99) {
                                                Text(verbatim: "\(recurrenceEndCount) occurrences")
                                            }
                                        }

                                        Toggle(NSLocalizedString("addassignment.toggle.skip.weekends", value: "Skip weekends", comment: "Skip weekends"), isOn: $skipWeekends)
                                        Toggle(NSLocalizedString("addassignment.toggle.skip.holidays", value: "Skip holidays", comment: "Skip holidays"), isOn: $skipHolidays)

                                        if skipHolidays {
                                            Picker("Holiday Source", selection: $holidaySource) {
                                                Text(NSLocalizedString("addassignment.system.calendar", value: "System Calendar", comment: "System Calendar")).tag(RecurrenceRule.HolidaySource.deviceCalendar)
                                                Text(NSLocalizedString("addassignment.none", value: "None", comment: "None")).tag(RecurrenceRule.HolidaySource.none)
                                            }
                                            .pickerStyle(.menu)

                                            if !holidaySourceAvailable && holidaySource == .deviceCalendar {
                                                Text(NSLocalizedString("addassignment.no.holiday.source.configured", value: "No holiday source configured.", comment: "No holiday source configured."))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Details
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("addassignment.details", value: "DETAILS", comment: "DETAILS"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        RootsCard(compact: true) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("addassignment.urgency", value: "Urgency", comment: "Urgency")).font(.caption).foregroundStyle(.secondary)
                                    Picker("", selection: $urgency) {
                                        ForEach(AssignmentUrgency.allCases) { u in
                                            Text(u.rawValue.capitalized).tag(u)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("addassignment.weight", value: "Weight %", comment: "Weight %")).font(.caption).foregroundStyle(.secondary)
                                    TextField("0", value: $weightPercent, formatter: weightFormatter)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("addassignment.status", value: "Status", comment: "Status")).font(.caption).foregroundStyle(.secondary)
                                    Picker("", selection: $status) {
                                        ForEach(AssignmentStatus.allCases) { s in
                                            Text(s.label).tag(s)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                Spacer()
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("addassignment.notes", value: "NOTES", comment: "NOTES"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                        .frame(minHeight: 140)
                        .padding(10)
                        .background(DesignSystem.Materials.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Attachments
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("addassignment.attachments", value: "ATTACHMENTS", comment: "ATTACHMENTS"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        AttachmentListView(attachments: $attachments, courseId: selectedCourseId)
                    }

                    // Footer buttons
                    HStack {
                        Button(NSLocalizedString("addassignment.button.cancel", value: "Cancel", comment: "Cancel")) {
                            if hasUnsavedChanges {
                                showDiscardDialog = true
                            } else {
                                dismiss()
                            }
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button(NSLocalizedString("addassignment.button.save", value: "Save", comment: "Save")) {
                            saveTask()
                        }
                        .buttonStyle(.glassBlueProminent)
                        .keyboardShortcut(.defaultAction)
                        .disabled(isSaveDisabled)
                    }
                }
                .padding(20)
            }
            .opacity(showingAddCourse ? 0.3 : 1.0)
            .disabled(showingAddCourse)

            if showingAddCourse {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(DesignSystem.Motion.standardSpring) { showingAddCourse = false }
                    }

                // Placeholder for actual add-course UI
                AddCourseSheet()
                    .frame(maxWidth: 520)
                    .transition(DesignSystem.Motion.scaleTransition)
                    .zIndex(1)
            }
        }
        .animation(DesignSystem.Motion.interactiveSpring, value: showingAddCourse)
        .frame(minWidth: 420)
        .onAppear {
            preselectCourseIfNeeded()
        }
        .onChange(of: coursesStore.currentSemesterCourses) { _, _ in
            preselectCourseIfNeeded()
        }
        .onChange(of: selectedCourseId) { _, _ in
            let allowed = Set(availableModules.map { $0.id })
            selectedModuleIds = selectedModuleIds.filter { allowed.contains($0) }
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
        .confirmationDialog(
            "Discard changes?",
            isPresented: $showDiscardDialog,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("addassignment.button.save.and.close", value: "Save and Close", comment: "Save and Close")) {
                saveTask()
            }
            Button(NSLocalizedString("Discard Changes", value: "Discard Changes", comment: ""), role: .destructive) {
                dismiss()
            }
            Button(NSLocalizedString("Cancel", value: "Cancel", comment: ""), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("addassignment.you.have.unsaved.changes.save", value: "You have unsaved changes. Save before closing to avoid losing them.", comment: "You have unsaved changes. Save before closing to a..."))
        }
    }

    private var weightFormatter: NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 1
        return nf
    }

    private var coursePicker: some View {
        Group {
            if coursesStore.activeCourses.isEmpty {
                Button {
                    withAnimation(DesignSystem.Motion.standardSpring) { showingAddCourse = true }
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text(NSLocalizedString("addassignment.add.course", value: "Add Course", comment: "Add Course"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Picker("Course", selection: $selectedCourseId) {
                    // Add "Personal (No Course)" option
                    Text(NSLocalizedString("addassignment.personal.no.course", value: "Personal (No Course)", comment: "Personal (No Course)"))
                        .tag(Optional<UUID>(nil))
                    
                    Divider()
                    
                    ForEach(coursesStore.activeCourses, id: \.id) { c in
                        Text(verbatim: "\(c.code) · \(c.title)").tag(Optional(c.id))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $type) {
            ForEach(TaskType.allCases, id: \.self) { t in
                Text(displayName(for: t)).tag(t)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func displayName(for t: TaskType) -> String {
        switch t {
        case .project: return "Project"
        case .exam: return "Exam"
        case .quiz: return "Quiz"
        case .homework: return "Homework"
        case .reading: return "Reading"
        case .review: return "Review"
        case .practiceTest: return "Practice Test"
        case .study: return "Study"
        }
    }

    private func preselectCourseIfNeeded() {
        if selectedCourseId == nil, let first = coursesStore.activeCourses.first {
            selectedCourseId = first.id
        }
    }

    private var recurrenceSelection: Binding<RecurrenceSelection> {
        Binding(
            get: {
                guard recurrenceEnabled else { return .none }
                switch recurrenceFrequency {
                case .daily: return .daily
                case .weekly: return .weekly
                case .monthly: return .monthly
                case .yearly: return .yearly
                }
            },
            set: { selection in
                if selection == .none {
                    recurrenceEnabled = false
                } else {
                    recurrenceEnabled = true
                    recurrenceFrequency = selection.frequency
                }
            }
        )
    }

    private var recurrenceUnitLabel: String {
        switch recurrenceFrequency {
        case .daily: 
            return String.localizedStringWithFormat(
                NSLocalizedString("days_unit", comment: ""),
                recurrenceInterval
            )
        case .weekly: 
            return String.localizedStringWithFormat(
                NSLocalizedString("weeks_unit", comment: ""),
                recurrenceInterval
            )
        case .monthly: 
            return String.localizedStringWithFormat(
                NSLocalizedString("months_unit", comment: ""),
                recurrenceInterval
            )
        case .yearly: 
            return String.localizedStringWithFormat(
                NSLocalizedString("years_unit", comment: ""),
                recurrenceInterval
            )
        }
    }

    private var holidaySourceAvailable: Bool {
        guard CalendarAuthorizationManager.shared.isAuthorized else { return false }
        let calendars = DeviceCalendarManager.shared.store.calendars(for: .event)
        return calendars.contains(where: { $0.title.lowercased().contains("holiday") })
    }

    private func buildRecurrenceRule() -> RecurrenceRule? {
        guard recurrenceEnabled else { return nil }
        let end: RecurrenceRule.End
        switch recurrenceEndOption {
        case .never:
            end = .never
        case .onDate:
            end = .until(recurrenceEndDate)
        case .afterOccurrences:
            end = .afterOccurrences(max(1, recurrenceEndCount))
        }
        let skipPolicy = RecurrenceRule.SkipPolicy(
            skipWeekends: skipWeekends,
            skipHolidays: skipHolidays,
            holidaySource: holidaySource,
            adjustment: .forward
        )
        return RecurrenceRule(
            frequency: recurrenceFrequency,
            interval: max(1, recurrenceInterval),
            end: end,
            skipPolicy: skipPolicy
        )
    }

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let courseId = selectedCourseId else { return }
        if (type == .exam || type == .quiz) && selectedModuleIds.isEmpty { return }

        let task = AppTask(
            id: UUID(),
            title: trimmed,
            courseId: courseId,
            moduleIds: Array(selectedModuleIds),
            due: due,
            estimatedMinutes: estimatedMinutes,
            minBlockMinutes: 20,
            maxBlockMinutes: 180,
            difficulty: 0.5,
            importance: 0.5,
            type: type,
            locked: lockToDueDate,
            attachments: attachments,
            isCompleted: false,
            recurrence: buildRecurrenceRule()
        )
        onSave(task)
        dismiss()
    }

    private var availableModules: [CourseOutlineNode] {
        guard let courseId = selectedCourseId else { return [] }
        return coursesStore.outlineNodes(for: courseId)
            .filter { $0.type == .module }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    private func moduleBinding(_ moduleId: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedModuleIds.contains(moduleId) },
            set: { isSelected in
                if isSelected {
                    selectedModuleIds.insert(moduleId)
                } else {
                    selectedModuleIds.remove(moduleId)
                }
            }
        )
    }
}
#endif
