import SwiftUI

// MARK: - Assignment Plan Card

struct AssignmentPlanCard: View {
    let assignment: Assignment
    let plan: AssignmentPlan?
    let onGeneratePlan: () -> Void
    let onToggleStep: (UUID) -> Void

    @Environment(\.layoutMetrics) private var metrics

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let plan {
                if isExpanded {
                    planSteps(plan)
                } else {
                    planSummary(plan)
                }
            } else {
                noPlanView
            }
        }
        .padding(metrics.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DesignSystem.Materials.card)
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.headline)
                Text(verbatim: "Due \(formatDueDisplay(for: assignment))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if plan != nil {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .buttonStyle(.itariLiquid)
                .accessibilityLabel(isExpanded ? NSLocalizedString(
                    "iosassignmentplans.button.collapse.plan",
                    value: "Collapse plan",
                    comment: "Collapse plan"
                ) : NSLocalizedString(
                    "iosassignmentplans.button.expand.plan",
                    value: "Expand plan",
                    comment: "Expand plan"
                ))
            }
        }
    }

    private func planSummary(_ plan: AssignmentPlan) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "\(plan.completedStepsCount)/\(plan.steps.count) steps")
                    .font(.subheadline.weight(.semibold))
                Text(verbatim: "\(plan.totalEstimatedMinutes) min total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            progressCircle(plan)
        }
    }

    private func planSteps(_ plan: AssignmentPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(plan.sortedSteps) { step in
                PlanStepRow(
                    step: step,
                    isBlocked: plan.isStepBlocked(step),
                    onToggle: { onToggleStep(step.id) }
                )
            }
        }
    }

    private var noPlanView: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("iosassignmentplans.no.plan.yet", value: "No plan yet", comment: "No plan yet"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(NSLocalizedString(
                "iosassignmentplans.button.generate.plan",
                value: "Generate Plan",
                comment: "Generate Plan"
            )) {
                onGeneratePlan()
            }
            .buttonStyle(.itoriLiquidProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func progressCircle(_ plan: AssignmentPlan) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
                .frame(width: 44, height: 44)

            Circle()
                .trim(from: 0, to: plan.progressPercentage / 100)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))

            Text(verbatim: "\(Int(plan.progressPercentage))%")
                .font(.caption2.weight(.semibold))
        }
    }

    private func formattedDate(_ date: Date) -> String {
        LocaleFormatters.mediumDate.string(from: date)
    }

    private func formatDueDisplay(for assignment: Assignment) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if assignment.hasExplicitDueTime {
            formatter.timeStyle = .short
            // Override for 24-hour time preference
            if AppSettingsModel.shared.use24HourTime {
                formatter.dateFormat = "MMM d, yyyy, HH:mm"
            }
        } else {
            formatter.timeStyle = .none
        }
        let date = assignment.hasExplicitDueTime ? assignment.effectiveDueDateTime : assignment.dueDate
        return formatter.string(from: date)
    }
}

// MARK: - Plan Step Row

struct PlanStepRow: View {
    let step: PlanStep
    let isBlocked: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if !isBlocked {
                    onToggle()
                }
            } label: {
                Image(systemName: checkboxIcon)
                    .foregroundStyle(checkboxColor)
                    .font(.title3)
                    .accessibilityHidden(true)
            }
            .buttonStyle(.itoriLiquidProminent)
            .disabled(isBlocked)
            .accessibilityLabel(isBlocked ? NSLocalizedString(
                "iosassignmentplans.button.step.locked",
                value: "Step locked",
                comment: "Step locked"
            ) : NSLocalizedString(
                "iosassignmentplans.button.toggle.step",
                value: "Toggle step complete",
                comment: "Toggle step complete"
            ))

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(step.isCompleted)
                    .foregroundStyle(step.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    Label(
                        NSLocalizedString(
                            "iosassignmentplans.label.stepestimatedminutes.min",
                            value: "\(step.estimatedMinutes) min",
                            comment: "\(step.estimatedMinutes) min"
                        ),
                        systemImage: "clock"
                    )

                    if let dueBy = step.dueBy {
                        Label(shortDate(dueBy), systemImage: "calendar")
                    }

                    if step.isOverdue {
                        Label(
                            NSLocalizedString("iosassignmentplans.label.overdue", value: "Overdue", comment: "Overdue"),
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.red)
                    }

                    if isBlocked {
                        Label(
                            NSLocalizedString("iosassignmentplans.label.blocked", value: "Blocked", comment: "Blocked"),
                            systemImage: "lock"
                        )
                        .foregroundStyle(.orange)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            stepTypeIcon
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isBlocked ? Color.orange.opacity(0.1) : Color.clear)
        )
    }

    private var checkboxIcon: String {
        if isBlocked {
            return "lock.circle"
        }
        return step.isCompleted ? "checkmark.circle.fill" : "circle"
    }

    private var checkboxColor: Color {
        if isBlocked {
            return .orange
        }
        return step.isCompleted ? .accentColor : .secondary
    }

    private var stepTypeIcon: some View {
        Image(systemName: iconForStepType)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var iconForStepType: String {
        switch step.stepType {
        case .task: "doc.text"
        case .reading: "book"
        case .practice: "pencil.and.list.clipboard"
        case .review: "arrow.triangle.2.circlepath"
        case .research: "magnifyingglass"
        case .writing: "pencil"
        case .preparation: "calendar.badge.checkmark"
        }
    }

    private func shortDate(_ date: Date) -> String {
        LocaleFormatters.shortDate.string(from: date)
    }
}

// MARK: - Plans List View (for iOS)

#if os(iOS)
    struct IOSAssignmentPlansView: View {
        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var plansStore: AssignmentPlansStore
        @EnvironmentObject private var filterState: IOSFilterState
        @EnvironmentObject private var coursesStore: CoursesStore
        @EnvironmentObject private var toastRouter: IOSToastRouter
        @Environment(\.layoutMetrics) private var metrics

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header

                    IOSFilterHeaderView(
                        coursesStore: coursesStore,
                        filterState: filterState
                    )

                    if filteredAssignments.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredAssignments) { assignment in
                            AssignmentPlanCard(
                                assignment: assignment,
                                plan: plansStore.plan(for: assignment.id),
                                onGeneratePlan: {
                                    plansStore.generatePlan(for: assignment)
                                    toastRouter.show("Plan generated")
                                },
                                onToggleStep: { stepId in
                                    toggleStep(stepId, in: assignment.id)
                                }
                            )
                        }
                    }
                }
                .padding(metrics.cardPadding)
            }

            .onAppear {
                ensurePlansExist()
            }
        }

        private var header: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString(
                        "iosassignmentplans.assignment.plans",
                        value: "Assignment Plans",
                        comment: "Assignment Plans"
                    ))
                    .font(.title3.weight(.semibold))
                    if let lastRefresh = plansStore.lastRefreshDate {
                        Text(verbatim: "Updated \(timeAgo(lastRefresh))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }

        private var emptyState: some View {
            VStack(spacing: 12) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(NSLocalizedString(
                    "iosassignmentplans.no.assignments",
                    value: "No assignments",
                    comment: "No assignments"
                ))
                .font(.headline)
                Text(NSLocalizedString(
                    "iosassignmentplans.add.assignments.to.see.their.plans",
                    value: "Add assignments to see their plans",
                    comment: "Add assignments to see their plans"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }

        private var filteredAssignments: [Assignment] {
            let tasks = assignmentsStore.tasks
            let courseLookup = coursesStore.courses

            let filtered = tasks.filter { task in
                guard let assignment = convertTaskToAssignment(task) else { return false }

                guard let courseId = assignment.courseId else {
                    return filterState.selectedCourseId == nil && filterState.selectedSemesterId == nil
                }

                if let selectedCourse = filterState.selectedCourseId, selectedCourse != courseId {
                    return false
                }

                if let semesterId = filterState.selectedSemesterId,
                   let course = courseLookup.first(where: { $0.id == courseId }),
                   course.semesterId != semesterId
                {
                    return false
                }

                return !task.isCompleted
            }

            return filtered.compactMap { convertTaskToAssignment($0) }
                .sorted { $0.effectiveDueDateTime < $1.effectiveDueDateTime }
        }

        private func convertTaskToAssignment(_ task: AppTask) -> Assignment? {
            guard let due = task.due else { return nil }
            guard task.category != .practiceTest else { return nil }

            let assignmentCategory: AssignmentCategory = switch task.category {
            case .exam: .exam
            case .quiz: .quiz
            case .homework: .homework
            case .reading: .reading
            case .review: .review
            case .project: .project
            case .study: .review
            case .practiceTest: .practiceTest
            }

            return Assignment(
                id: task.id,
                courseId: task.courseId,
                moduleIds: task.moduleIds,
                title: task.title,
                dueDate: due,
                dueTimeMinutes: task.dueTimeMinutes,
                estimatedMinutes: task.estimatedMinutes,
                weightPercent: task.gradeWeightPercent,
                category: assignmentCategory,
                urgency: urgencyFromImportance(task.importance),
                isLockedToDueDate: task.locked,
                plan: []
            )
        }

        private func urgencyFromImportance(_ importance: Double) -> AssignmentUrgency {
            switch importance {
            case ..<0.3: .low
            case ..<0.6: .medium
            case ..<0.85: .high
            default: .critical
            }
        }

        private func ensurePlansExist() {
            let assignments = filteredAssignments.filter { !plansStore.hasPlan(for: $0.id) }
            if !assignments.isEmpty {
                plansStore.generatePlans(for: assignments)
            }
        }

        private func regenerateAll() {
            plansStore.regenerateAllPlans(for: filteredAssignments)
            toastRouter.show("Plans regenerated")
        }

        private func toggleStep(_ stepId: UUID, in assignmentId: UUID) {
            guard let plan = plansStore.plan(for: assignmentId),
                  let step = plan.steps.first(where: { $0.id == stepId }) else { return }

            if step.isCompleted {
                plansStore.uncompleteStep(stepId: stepId, in: assignmentId)
            } else {
                plansStore.completeStep(stepId: stepId, in: assignmentId)
            }
        }

        private func timeAgo(_ date: Date) -> String {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = .autoupdatingCurrent
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
#endif
