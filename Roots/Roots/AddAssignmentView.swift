import SwiftUI

struct AddAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coursesStore: CoursesStore

    @State private var title: String = ""
    @State private var due: Date = Date()
    @State private var estimatedMinutes: Int = 60
    @State private var selectedCourseId: UUID? = nil
    @State private var type: TaskType
    @State private var attachments: [Attachment] = []
    @State private var showDiscardDialog = false
    @State private var showingAddCourse = false

    var onSave: (AppTask) -> Void

    init(initialType: TaskType = .project, onSave: @escaping (AppTask) -> Void) {
        self.onSave = onSave
        self._type = State(initialValue: initialType)
    }

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCourseId == nil
    }

    private var hasUnsavedChanges: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty || selectedCourseId != nil || !attachments.isEmpty || due.timeIntervalSince1970 != 0
    }

    var body: some View {
        ZStack {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add Assignment")
                            .font(.title3).bold()
                        Text("Title, due date, course, and type are required.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Core
                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                        Text("Title").font(.subheadline).bold()
                        TextField("e.g. Read Chapter 3", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Schedule
                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                        Text("Schedule").font(.subheadline).bold()

                        DatePicker("Due date", selection: $due, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.field)

                        Stepper(value: $estimatedMinutes, in: 15...240, step: 15) {
                            Text("Estimated: \(estimatedMinutes) min")
                        }
                    }

                    // Context
                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                        Text("Context").font(.subheadline).bold()

                        // Course picker
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Course").font(DesignSystem.Typography.caption)
                                Spacer()
                                Button("Add Course...") {
                                    withAnimation(.spring()) {
                                        showingAddCourse = true
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(DesignSystem.Typography.caption)
                            }

                            if coursesStore.currentSemesterId == nil {
                                Text("Select a current semester in Courses before adding assignments.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Picker("Course", selection: $selectedCourseId) {
                                    Text("No courses").tag(Optional<UUID>(nil))
                                }
                                .disabled(true)
                            } else {
                                if coursesStore.currentSemesterCourses.isEmpty {
                                    Text("No courses in the current semester. Add courses and mark the semester as current first.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Picker("Course", selection: $selectedCourseId) {
                                        Text("No courses").tag(Optional<UUID>(nil))
                                    }
                                    .disabled(true)
                                } else {
                                    Picker("Course", selection: $selectedCourseId) {
                                        ForEach(coursesStore.currentSemesterCourses, id: \.id) { c in
                                            Text("\(c.code) · \(c.title)").tag(Optional(c.id))
                                        }
                                    }
                                    .labelsHidden()
                                }
                            }
                        }

                        // Type picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Type").font(DesignSystem.Typography.caption)
                            Picker("Type", selection: $type) {
                                ForEach(TaskType.allCases, id: \.self) { t in
                                    Text(displayName(for: t)).tag(t)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    Divider()

                    // References & Rubrics
                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                        Text("References & Rubrics").font(DesignSystem.Typography.subHeader)

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
                .padding(DesignSystem.Layout.spacing.small)
            }
            .opacity(showingAddCourse ? 0.3 : 1.0)
            .disabled(showingAddCourse)

            if showingAddCourse {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) { showingAddCourse = false }
                    }

                // Placeholder for actual add-course UI
                AddCourseSheet()
                    .frame(maxWidth: 520)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(DesignSystem.Motion.interactiveSpring, value: showingAddCourse)
        .frame(minWidth: 420)
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

    private func displayName(for t: TaskType) -> String {
        switch t {
        case .project: return "Project"
        case .exam: return "Exam"
        case .quiz: return "Quiz"
        case .practiceHomework: return "Practice Homework"
        case .reading: return "Reading"
        case .review: return "Review"
        case .studying: return "Studying"
        }
    }

    private func preselectCourseIfNeeded() {
        if selectedCourseId == nil, let first = coursesStore.currentSemesterCourses.first {
            selectedCourseId = first.id
        }
    }

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let courseId = selectedCourseId else { return }

        let task = AppTask(id: UUID(), title: trimmed, courseId: courseId, due: due, estimatedMinutes: estimatedMinutes, minBlockMinutes: 20, maxBlockMinutes: 180, difficulty: 0.5, importance: 0.5, type: type, locked: false, attachments: attachments, isCompleted: false)
        onSave(task)
        dismiss()
    }
}
