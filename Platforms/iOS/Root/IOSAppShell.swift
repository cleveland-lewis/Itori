#if os(iOS)
    import SwiftUI

    /// Global app shell that provides consistent top bar across all pages
    struct IOSAppShell<Content: View>: View {
        @EnvironmentObject private var navigation: IOSNavigationCoordinator
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.appLayout) private var appLayout
        @EnvironmentObject private var sheetRouter: IOSSheetRouter
        @EnvironmentObject private var toastRouter: IOSToastRouter
        @EnvironmentObject private var coursesStore: CoursesStore
        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var plannerStore: PlannerStore
        @EnvironmentObject private var filterState: IOSFilterState
        @EnvironmentObject private var settings: AppSettingsModel
        @EnvironmentObject private var preferences: AppPreferences
        @State private var safeAreaInsets: EdgeInsets = .init()
        @State private var showSettingsSheet = false
        @Environment(\.colorScheme) private var colorScheme

        private let buttonSpacing: CGFloat = 12

        let title: String
        let content: Content
        let hideNavigationButtons: Bool

        init(title: String, hideNavigationButtons: Bool = false, @ViewBuilder content: () -> Content) {
            self.title = title
            self.hideNavigationButtons = hideNavigationButtons
            self.content = content()
        }

        private var interfacePreferences: InterfacePreferences {
            InterfacePreferences.from(preferences, settings: settings, colorScheme: colorScheme)
        }

        private var shouldShowButtons: Bool {
            if hideNavigationButtons { return false }

            // On iPhone (compact width), hide buttons when navigated (back button present)
            if horizontalSizeClass == .compact {
                return navigation.path.isEmpty
            }

            // On iPad (regular width), always show buttons
            return true
        }

        var body: some View {
            let overlayInsets = EdgeInsets(
                top: safeAreaInsets.top,
                leading: 0,
                bottom: 0,
                trailing: appLayout.overlayTrailingInset + 44 + buttonSpacing + 44
            )

            let contentView = ZStack(alignment: .top) {
                // Content extends to top edge
                content
                    .toolbarBackground(.hidden, for: .navigationBar)

                // Floating header title with glass effect
                VStack(spacing: 0) {
                    HStack {
                        Menu {
                            ForEach(TabRegistry.allTabs.map(\.id)) { tab in
                                if let def = TabRegistry.definition(for: tab) {
                                    Button {
                                        NotificationCenter.default.post(name: .iosOpenPage, object: tab)
                                    } label: {
                                        Label(def.title, systemImage: def.icon)
                                    }
                                } else {
                                    Button {
                                        NotificationCenter.default.post(name: .iosOpenPage, object: tab)
                                    } label: {
                                        Text(tab.title)
                                    }
                                }
                            }
                        } label: {
                            Group {
                                if #available(iOS 26.0, *) {
                                    Text(title)
                                        .font(.title2.weight(.semibold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .glassEffect(.regular)
                                } else {
                                    Text(title)
                                        .font(.title2.weight(.semibold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, safeAreaInsets.top + appLayout.overlayTopInset)
                    .padding(.horizontal, 16)
                    Spacer()
                }

                // Floating buttons overlay with glass effect
                if shouldShowButtons {
                    VStack {
                        HStack {
                            Spacer()
                            topRightControls
                                .padding(.top, safeAreaInsets.top + appLayout.overlayTopInset)
                                .padding(.trailing, appLayout.overlayTrailingInset)
                        }
                        Spacer()
                    }
                }
            }
            .readSafeAreaInsets { safeAreaInsets = $0 }
            .environment(\.overlayInsets, overlayInsets)
            .interfacePreferences(interfacePreferences)
            .sheet(isPresented: $showSettingsSheet) {
                SettingsRootView()
                    .environmentObject(settings)
            }

            contentView
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .navigationBar)
        }

        private var topRightControls: some View {
            HStack(spacing: 12) {
                quickAddButton
                settingsButton
            }
        }

        private var quickAddButton: some View {
            Menu {
                // Energy Section - Top
                if settings.showEnergyPanel {
                    Section {
                        Label(
                            NSLocalizedString(
                                "ui.label.energy.settingsdefaultenergylevel",
                                value: "Energy: \(settings.defaultEnergyLevel)",
                                comment: "Energy: \(settings.defaultEnergyLevel)"
                            ),
                            systemImage: "bolt.circle"
                        )
                        .foregroundStyle(.secondary)

                        Menu("Change Energy") {
                            Picker("Energy", selection: Binding(
                                get: { settings.defaultEnergyLevel },
                                set: { setEnergy($0) }
                            )) {
                                Text(NSLocalizedString("ui.high", value: "High", comment: "High")).tag("High")
                                Text(NSLocalizedString("ui.medium", value: "Medium", comment: "Medium")).tag("Medium")
                                Text(NSLocalizedString("ui.low", value: "Low", comment: "Low")).tag("Low")
                            }
                        }
                    }

                    Divider()
                }

                // Quick Actions Section
                Section {
                    Button {
                        handleQuickAction(.add_assignment)
                    } label: {
                        Label(
                            NSLocalizedString("ios.menu.add_assignment", comment: "Add Assignment"),
                            systemImage: "plus.square.on.square"
                        )
                    }

                    Button {
                        handleQuickAction(.add_grade)
                    } label: {
                        Label(
                            NSLocalizedString("ios.menu.add_grade", comment: "Add Grade"),
                            systemImage: "number.circle"
                        )
                    }

                    Button {
                        handleQuickAction(.auto_schedule)
                    } label: {
                        Label(
                            NSLocalizedString("ios.menu.auto_schedule", comment: "Auto Schedule"),
                            systemImage: "calendar.badge.clock"
                        )
                    }
                }
            } label: {
                Group {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .glassEffect(.regular.tint(settings.activeAccentColor).interactive())
                    } else {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(settings.activeAccentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .buttonStyle(NoHighlightButtonStyle())
            .accessibilityLabel(NSLocalizedString("ios.menu.quick_add", comment: "Quick add"))
            .accessibilityHint("Opens quick add actions")
            .accessibilityIdentifier("Overlay.QuickAdd")
        }

        private var settingsButton: some View {
            Button {
                showSettingsSheet = true
            } label: {
                Group {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .glassEffect(.regular.tint(settings.activeAccentColor).interactive())
                    } else {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(settings.activeAccentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .buttonStyle(NoHighlightButtonStyle())
            .accessibilityLabel(NSLocalizedString("ios.menu.settings", comment: "Settings"))
            .accessibilityHint("Opens settings")
            .accessibilityIdentifier("Overlay.Settings")
        }

        private func handleQuickAction(_ action: QuickAction) {
            switch action {
            case .add_assignment:
                let defaults = IOSSheetRouter.TaskDefaults(
                    courseId: filterState.selectedCourseId,
                    dueDate: Date(),
                    title: "",
                    type: .homework,
                    itemLabel: "Assignment"
                )
                sheetRouter.activeSheet = .addAssignment(defaults)
            case .add_grade:
                sheetRouter.activeSheet = .addGrade(UUID())
            case .auto_schedule:
                autoSchedule()
            default:
                break
            }
        }

        private func setEnergy(_ level: String) {
            settings.defaultEnergyLevel = level
            settings.energySelectionConfirmed = true
            settings.save()
        }

        private func autoSchedule() {
            let assignments = assignmentsForPlanning()
            guard !assignments.isEmpty else {
                toastRouter.show(NSLocalizedString("ios.toast.no_tasks_schedule", comment: "No tasks to schedule"))
                return
            }
            let settings = StudyPlanSettings()
            let sessions = assignments.flatMap { PlannerEngine.generateSessions(for: $0, settings: settings) }
            let result = PlannerEngine.scheduleSessionsWithStrategy(
                sessions,
                settings: settings,
                energyProfile: defaultEnergyProfile()
            )
            plannerStore.persist(scheduled: result.scheduled, overflow: result.overflow)
            syncPlannerCalendar(for: result.scheduled)
            toastRouter.show(NSLocalizedString("ios.toast.schedule_updated", comment: "Schedule updated"))
        }

        private func assignmentsForPlanning() -> [Assignment] {
            let today = Calendar.current.startOfDay(for: Date())
            return filteredTasks.compactMap { task in
                guard !task.isCompleted, let due = task.due else { return nil }
                if due < today { return nil }
                return Assignment(
                    id: task.id,
                    courseId: task.courseId,
                    title: task.title,
                    dueDate: due,
                    estimatedMinutes: task.estimatedMinutes,
                    weightPercent: nil,
                    category: category(for: task),
                    urgency: urgency(for: task.importance),
                    isLockedToDueDate: task.locked,
                    plan: []
                )
            }
        }

        private var filteredTasks: [AppTask] {
            let courseLookup = coursesStore.courses
            return assignmentsStore.tasks.filter { task in
                guard let courseId = task.courseId else {
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
                return true
            }
        }

        private func category(for task: AppTask) -> AssignmentCategory {
            switch task.category {
            case .exam: .exam
            case .quiz: .quiz
            case .homework: .homework
            case .reading: .reading
            case .review: .review
            case .project: .project
            case .study: .homework // Map study to homework category
            case .practiceTest: .practiceTest
            }
        }

        private func syncPlannerCalendar(for scheduled: [ScheduledSession]) {
            guard let start = scheduled.map(\.start).min(),
                  let end = scheduled.map(\.end).max() else { return }
            Task { await CalendarManager.shared.syncPlannerSessionsToCalendar(in: start ... end) }
        }

        private func urgency(for value: Double) -> AssignmentUrgency {
            switch value {
            case ..<0.3: .low
            case ..<0.6: .medium
            case ..<0.85: .high
            default: .critical
            }
        }

        private func defaultEnergyProfile() -> [Int: Double] {
            [
                9: 0.55, 10: 0.65, 11: 0.7, 12: 0.6,
                13: 0.5, 14: 0.55, 15: 0.65, 16: 0.7,
                17: 0.6, 18: 0.5, 19: 0.4, 20: 0.35
            ]
        }
    }

    private struct NoHighlightButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }
#endif
