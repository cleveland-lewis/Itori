#if os(macOS)
import SwiftUI
import EventKit

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

struct AddAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var settings: AppSettingsModel

    @State private var title: String = ""
    @State private var due: Date = Date()
    @State private var estimatedMinutes: Int = 60
    @State private var selectedCourseId: UUID? = nil
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
    @State private var holidaySource: RecurrenceRule.HolidaySource = .systemCalendar

    var onSave: (AppTask) -> Void

    init(initialType: TaskType = .project, preselectedCourseId: UUID? = nil, onSave: @escaping (AppTask) -> Void) {
        self.onSave = onSave
        self._type = State(initialValue: initialType)
        self._selectedCourseId = State(initialValue: preselectedCourseId)
    }

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCourseId == nil
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

                    // Timing
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TIMING")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        RootsCard(compact: true) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Due Date")
                                    Spacer()
                                    DatePicker("", selection: $due, displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.field)
                                        .labelsHidden()
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Estimated")
                                        
                                        Spacer()
                                        
                                        Stepper(value: $estimatedMinutes, in: 15...240, step: currentStepSize) {
                                            Text("\(estimatedMinutes) min")
                                        }
                                    }
                                    
                                    Text(decompositionHintText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                HStack {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Lock")
                                            .font(.body)
                                        Text("Lock work to due date")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $lockToDueDate)
                                        .labelsHidden()
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Repeat")
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
                                            Text("Every \(recurrenceInterval) \(recurrenceUnitLabel)")
                                        }

                                        Picker("End", selection: $recurrenceEndOption) {
                                            Text("Never").tag(RecurrenceEndOption.never)
                                            Text("On Date").tag(RecurrenceEndOption.onDate)
                                            Text("After").tag(RecurrenceEndOption.afterOccurrences)
                                        }
                                        .pickerStyle(.menu)

                                        if recurrenceEndOption == .onDate {
                                            DatePicker("End Date", selection: $recurrenceEndDate, displayedComponents: .date)
                                        } else if recurrenceEndOption == .afterOccurrences {
                                            Stepper(value: $recurrenceEndCount, in: 1...99) {
                                                Text("\(recurrenceEndCount) occurrences")
                                            }
                                        }

                                        Toggle("Skip weekends", isOn: $skipWeekends)
                                        Toggle("Skip holidays", isOn: $skipHolidays)

                                        if skipHolidays {
                                            Picker("Holiday Source", selection: $holidaySource) {
                                                Text("System Calendar").tag(RecurrenceRule.HolidaySource.systemCalendar)
                                                Text("None").tag(RecurrenceRule.HolidaySource.none)
                                            }
                                            .pickerStyle(.menu)

                                            if !holidaySourceAvailable && holidaySource == .systemCalendar {
                                                Text("No holiday source configured.")
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
                        Text("DETAILS")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        RootsCard(compact: true) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Urgency").font(.caption).foregroundStyle(.secondary)
                                    Picker("", selection: $urgency) {
                                        ForEach(AssignmentUrgency.allCases) { u in
                                            Text(u.rawValue.capitalized).tag(u)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Weight %").font(.caption).foregroundStyle(.secondary)
                                    TextField("0", value: $weightPercent, formatter: weightFormatter)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Status").font(.caption).foregroundStyle(.secondary)
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
                        Text("NOTES")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                        .frame(minHeight: 140)
                        .padding(10)
                        .background(DesignSystem.Materials.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Attachments
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ATTACHMENTS")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        AttachmentListView(attachments: $attachments, courseId: selectedCourseId)
                    }

                    // Footer buttons
                    HStack {
                        Button("Cancel") {
                            if hasUnsavedChanges {
                                showDiscardDialog = true
                            } else {
                                dismiss()
                            }
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button("Save") {
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
        .interactiveDismissDisabled(hasUnsavedChanges)
        .confirmationDialog(
            "Discard changes?",
            isPresented: $showDiscardDialog,
            titleVisibility: .visible
        ) {
            Button("Save and Close") {
                saveTask()
            }
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Save before closing to avoid losing them.")
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
            if coursesStore.currentSemesterCourses.isEmpty {
                Button {
                    withAnimation(DesignSystem.Motion.standardSpring) { showingAddCourse = true }
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Course")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Picker("Course", selection: $selectedCourseId) {
                    ForEach(coursesStore.currentSemesterCourses, id: \.id) { c in
                        Text("\(c.code) · \(c.title)").tag(Optional(c.id))
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
        }
    }

    private func preselectCourseIfNeeded() {
        if selectedCourseId == nil, let first = coursesStore.currentSemesterCourses.first {
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
        case .daily: return recurrenceInterval == 1 ? "day" : "days"
        case .weekly: return recurrenceInterval == 1 ? "week" : "weeks"
        case .monthly: return recurrenceInterval == 1 ? "month" : "months"
        case .yearly: return recurrenceInterval == 1 ? "year" : "years"
        }
    }

    private var holidaySourceAvailable: Bool {
        guard CalendarAuthorizationManager.shared.isAuthorized else { return false }
        let calendars = DeviceCalendarManager.shared.store.calendars(for: .event)
        return calendars.contains { $0.type == .holiday || $0.title.lowercased().contains("holiday") }
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

        let task = AppTask(
            id: UUID(),
            title: trimmed,
            courseId: courseId,
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
}
#endif
