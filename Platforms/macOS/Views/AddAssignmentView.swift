#if os(macOS)
    import EventKit
    import SwiftUI

    struct AddAssignmentView: View {
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject private var coursesStore: CoursesStore
        @EnvironmentObject private var settings: AppSettingsModel

        @State private var title: String = ""
        @State private var due: Date = .init()
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
        @State private var recurrenceEndDate: Date = .init()
        @State private var recurrenceEndCount: Int = 3
        @State private var skipWeekends: Bool = false
        @State private var skipHolidays: Bool = false
        @State private var holidaySource: RecurrenceRule.HolidaySource = .deviceCalendar

        var onSave: (AppTask) -> Void
        private let editingTask: AppTask?

        init(
            initialType: TaskType = .project,
            preselectedCourseId: UUID? = nil,
            editingTask: AppTask? = nil,
            onSave: @escaping (AppTask) -> Void
        ) {
            self.onSave = onSave
            self.editingTask = editingTask

            if let task = editingTask {
                // Initialize with existing task data
                _title = State(initialValue: task.title)
                _due = State(initialValue: task.due ?? Date())
                _estimatedMinutes = State(initialValue: task.estimatedMinutes)
                _selectedCourseId = State(initialValue: task.courseId)
                _type = State(initialValue: task.type)
                _attachments = State(initialValue: task.attachments)
                _notes = State(initialValue: task.notes ?? "")
                _lockToDueDate = State(initialValue: task.locked)
                _weightPercent = State(initialValue: task.gradeWeightPercent ?? 0)
            } else {
                // New task defaults
                _type = State(initialValue: initialType)
                _selectedCourseId = State(initialValue: preselectedCourseId)
            }
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
                case .none: "None"
                case .daily: "Daily"
                case .weekly: "Weekly"
                case .monthly: "Monthly"
                case .yearly: "Yearly"
                }
            }

            var frequency: RecurrenceRule.Frequency {
                switch self {
                case .none: .weekly
                case .daily: .daily
                case .weekly: .weekly
                case .monthly: .monthly
                case .yearly: .yearly
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
            return !trimmed.isEmpty || selectedCourseId != nil || !attachments.isEmpty || !notes.isEmpty || due
                .timeIntervalSince1970 != 0
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

        private var weightFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimum = 0
            formatter.maximum = 100
            return formatter
        }

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Header Section

                        VStack(alignment: .leading, spacing: 16) {
                            TextField("Assignment Title", text: $title)
                                .font(.title2.weight(.semibold))
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.textBackgroundColor).opacity(0.5))
                                )

                            HStack(spacing: 12) {
                                // Course Picker
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Course")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    coursePicker
                                        .frame(maxWidth: .infinity)
                                }

                                // Type Picker
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Type")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    categoryPicker
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        Divider()
                            .padding(.horizontal, 20)

                        // MARK: - Due Date & Time Section

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Due Date & Time", systemImage: "calendar")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundStyle(.blue)
                                        .frame(width: 24)
                                    Text("Due")
                                        .font(.subheadline)
                                    Spacer()
                                    DatePicker("", selection: $due, displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider()
                                    .padding(.leading, 56)

                                HStack {
                                    Image(systemName: "timer")
                                        .foregroundStyle(.orange)
                                        .frame(width: 24)
                                    Text("Estimated Time")
                                        .font(.subheadline)
                                    Spacer()
                                    Stepper(value: $estimatedMinutes, in: 15 ... 240, step: 15) {
                                        Text("\(estimatedMinutes) min")
                                            .font(.subheadline.weight(.medium))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider()
                                    .padding(.leading, 56)

                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.purple)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Lock to Due Date")
                                            .font(.subheadline)
                                        Text("Prevent rescheduling")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $lockToDueDate)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.controlBackgroundColor))
                            )
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Modules Section (if available)

                        if !availableModules.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Modules", systemImage: "folder")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                VStack(spacing: 8) {
                                    ForEach(availableModules) { module in
                                        Toggle(module.title, isOn: moduleBinding(module.id))
                                            .toggleStyle(.checkbox)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .fill(selectedModuleIds.contains(module.id) ? Color.accentColor
                                                        .opacity(0.1) : Color.clear)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // MARK: - Additional Details

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Details", systemImage: "info.circle")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            VStack(spacing: 0) {
                                HStack {
                                    Text("Weight")
                                        .font(.subheadline)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("0", value: $weightPercent, formatter: weightFormatter)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                    Text("%")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.controlBackgroundColor))
                            )
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Notes Section

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            TextEditor(text: $notes)
                                .font(.body)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.textBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.separatorColor), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Attachments Section

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Attachments", systemImage: "paperclip")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            AttachmentListView(attachments: $attachments, courseId: selectedCourseId)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .navigationTitle(editingTask == nil ? "New Assignment" : "Edit Assignment")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            if hasUnsavedChanges {
                                showDiscardDialog = true
                            } else {
                                dismiss()
                            }
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(editingTask == nil ? "Create" : "Save") {
                            saveTask()
                        }
                        .buttonStyle(.itoriLiquidProminent)
                        .disabled(isSaveDisabled)
                    }
                }
                .alert("Discard Changes?", isPresented: $showDiscardDialog) {
                    Button("Discard", role: .destructive) {
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("You have unsaved changes. Are you sure you want to discard them?")
                }
            }
            .frame(minWidth: 600, idealWidth: 700, maxWidth: 800)
            .frame(minHeight: 500, idealHeight: 700)
            .onAppear {
                preselectCourseIfNeeded()
            }
        }

        private var coursePicker: some View {
            Group {
                if coursesStore.activeCourses.isEmpty {
                    Button {
                        withAnimation(DesignSystem.Motion.standardSpring) { showingAddCourse = true }
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text(NSLocalizedString(
                                "addassignment.add.course",
                                value: "Add Course",
                                comment: "Add Course"
                            ))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.itariLiquid)
                } else {
                    Picker("Course", selection: $selectedCourseId) {
                        // Add "Personal (No Course)" option
                        Text(NSLocalizedString(
                            "addassignment.personal.no.course",
                            value: "Personal (No Course)",
                            comment: "Personal (No Course)"
                        ))
                        .tag(UUID?(nil))

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
            case .project: "Project"
            case .exam: "Exam"
            case .quiz: "Quiz"
            case .homework: "Homework"
            case .reading: "Reading"
            case .review: "Review"
            case .practiceTest: "Practice Test"
            case .study: "Study"
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
                String.localizedStringWithFormat(
                    NSLocalizedString("days_unit", comment: ""),
                    recurrenceInterval
                )
            case .weekly:
                String.localizedStringWithFormat(
                    NSLocalizedString("weeks_unit", comment: ""),
                    recurrenceInterval
                )
            case .monthly:
                String.localizedStringWithFormat(
                    NSLocalizedString("months_unit", comment: ""),
                    recurrenceInterval
                )
            case .yearly:
                String.localizedStringWithFormat(
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
            let end: RecurrenceRule.End = switch recurrenceEndOption {
            case .never:
                .never
            case .onDate:
                .until(recurrenceEndDate)
            case .afterOccurrences:
                .afterOccurrences(max(1, recurrenceEndCount))
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
            // Allow nil courseId for personal tasks
            if (type == .exam || type == .quiz) && selectedModuleIds.isEmpty { return }

            let task = AppTask(
                id: editingTask?.id ?? UUID(), // Preserve ID if editing
                title: trimmed,
                courseId: selectedCourseId, // Can be nil for personal tasks
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
                isCompleted: editingTask?.isCompleted ?? false, // Preserve completion status
                recurrence: buildRecurrenceRule(),
                notes: notes.isEmpty ? nil : notes
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
