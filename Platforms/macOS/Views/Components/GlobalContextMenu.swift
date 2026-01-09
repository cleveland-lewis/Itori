#if os(macOS)
    import SwiftUI

    /// View modifier to add global context menu on right-click
    struct GlobalContextMenuModifier: ViewModifier {
        @EnvironmentObject private var appModel: AppModel
        @EnvironmentObject private var calendarManager: CalendarManager
        @EnvironmentObject private var plannerCoordinator: PlannerCoordinator
        @EnvironmentObject private var settingsCoordinator: SettingsCoordinator
        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var coursesStore: CoursesStore

        @State private var showAddAssignmentPopover = false

        var pageSpecificItems: (() -> AnyView)?

        func body(content: Content) -> some View {
            content
                .contextMenu {
                    // Global items
                    Button(NSLocalizedString("timer.context.refresh_calendar", comment: "")) {
                        GlobalMenuActions.shared.refresh()
                    }
                    .keyboardShortcut("r", modifiers: .command)

                    Button(NSLocalizedString("timer.context.go_to_planner", comment: "")) {
                        GlobalMenuActions.shared.navigateToPlanner()
                    }

                    Button(NSLocalizedString("timer.context.add_assignment", comment: "")) {
                        showAddAssignmentPopover = true
                    }

                    Button(NSLocalizedString("timer.context.add_grade", comment: "")) {
                        GlobalMenuActions.shared.addGrade()
                    }
                }
                .sheet(isPresented: $showAddAssignmentPopover) {
                    AddAssignmentView(initialType: .homework) { task in
                        assignmentsStore.addTask(task)
                        showAddAssignmentPopover = false
                    }
                    .environmentObject(coursesStore)
                }
        }
    }

    /// Timer-specific context menu modifier
    struct TimerContextMenuModifier: ViewModifier {
        @Binding var isRunning: Bool
        let onStart: () -> Void
        let onStop: () -> Void
        let onEnd: () -> Void

        @EnvironmentObject private var appModel: AppModel
        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var coursesStore: CoursesStore

        @State private var showAddAssignmentPopover = false

        func body(content: Content) -> some View {
            content
                .contextMenu {
                    // Timer-specific items
                    Button(NSLocalizedString("timer.context.start_clock", comment: "")) {
                        TimerMenuActions.shared.startClock()
                    }
                    .disabled(isRunning)

                    Button(NSLocalizedString("timer.context.stop_clock", comment: "")) {
                        TimerMenuActions.shared.stopClock()
                    }
                    .disabled(!isRunning)

                    Button(NSLocalizedString("timer.context.end_clock", comment: "")) {
                        TimerMenuActions.shared.endClock()
                    }
                    .disabled(!isRunning)

                    Divider()

                    // Global items
                    Button(NSLocalizedString("timer.context.refresh_calendar", comment: "")) {
                        GlobalMenuActions.shared.refresh()
                    }
                    .keyboardShortcut("r", modifiers: .command)

                    Button(NSLocalizedString("timer.context.go_to_planner", comment: "")) {
                        GlobalMenuActions.shared.navigateToPlanner()
                    }

                    Button(NSLocalizedString("timer.context.add_assignment", comment: "")) {
                        showAddAssignmentPopover = true
                    }

                    Button(NSLocalizedString("timer.context.add_grade", comment: "")) {
                        GlobalMenuActions.shared.addGrade()
                    }
                }
                .sheet(isPresented: $showAddAssignmentPopover) {
                    AddAssignmentView(initialType: .homework) { task in
                        assignmentsStore.addTask(task)
                        showAddAssignmentPopover = false
                    }
                    .environmentObject(coursesStore)
                }
        }
    }

    /// Practice Test-specific context menu modifier
    struct PracticeTestContextMenuModifier: ViewModifier {
        @ObservedObject var practiceStore: PracticeTestStore
        @ObservedObject var scheduledTestsStore: ScheduledTestsStore
        let onNewTest: () -> Void
        let onRefreshStats: () -> Void

        @State private var showDeleteConfirmation = false

        func body(content: Content) -> some View {
            content
                .contextMenu {
                    // Practice Test-specific items
                    Button(NSLocalizedString(
                        "ui.button.new.practice.test",
                        value: "New Practice Test",
                        comment: "New Practice Test"
                    )) {
                        onNewTest()
                    }
                    .keyboardShortcut("n", modifiers: [.command, .shift])

                    if let currentTest = practiceStore.currentTest {
                        if currentTest.status == .ready || currentTest.status == .inProgress {
                            Button(NSLocalizedString(
                                "ui.button.submit.test",
                                value: "Submit Test",
                                comment: "Submit Test"
                            )) {
                                practiceStore.submitTest(currentTest.id)
                            }
                            .keyboardShortcut(.return, modifiers: [.command, .shift])
                        }

                        if currentTest.status == .submitted {
                            Button(NSLocalizedString(
                                "ui.button.review.test",
                                value: "Review Test",
                                comment: "Review Test"
                            )) {
                                // Test is already showing
                            }
                        }

                        if currentTest.status == .failed {
                            Button(NSLocalizedString(
                                "ui.button.retry.generation",
                                value: "Retry Generation",
                                comment: "Retry Generation"
                            )) {
                                Task {
                                    await practiceStore.retryGeneration(testId: currentTest.id)
                                }
                            }
                            .keyboardShortcut("r", modifiers: [.command, .shift])
                        }

                        Divider()

                        Button(NSLocalizedString(
                            "ui.button.back.to.list",
                            value: "Back to List",
                            comment: "Back to List"
                        )) {
                            practiceStore.clearCurrentTest()
                        }
                        .keyboardShortcut(.leftArrow, modifiers: .command)
                    }

                    if !practiceStore.tests.isEmpty {
                        Divider()

                        Button(NSLocalizedString(
                            "ui.button.refresh.statistics",
                            value: "Refresh Statistics",
                            comment: "Refresh Statistics"
                        )) {
                            onRefreshStats()
                        }
                        .keyboardShortcut("r", modifiers: [.command])

                        Button(NSLocalizedString(
                            "ui.button.clear.all.tests",
                            value: "Clear All Tests",
                            comment: "Clear All Tests"
                        )) {
                            showDeleteConfirmation = true
                        }
                        .keyboardShortcut(.delete, modifiers: [.command, .shift])
                    }

                    Divider()

                    // Navigation items
                    Button(NSLocalizedString(
                        "ui.button.go.to.courses",
                        value: "Go to Courses",
                        comment: "Go to Courses"
                    )) {
                        GlobalMenuActions.shared.navigateToCourses()
                    }
                    .keyboardShortcut("1", modifiers: [.command, .option])

                    Button(NSLocalizedString(
                        "ui.button.go.to.planner",
                        value: "Go to Planner",
                        comment: "Go to Planner"
                    )) {
                        GlobalMenuActions.shared.navigateToPlanner()
                    }
                    .keyboardShortcut("2", modifiers: [.command, .option])
                }
                .alert("Clear All Tests", isPresented: $showDeleteConfirmation) {
                    Button(NSLocalizedString("Cancel", value: "Cancel", comment: ""), role: .cancel) {}
                    Button(NSLocalizedString("Clear All", value: "Clear All", comment: ""), role: .destructive) {
                        practiceStore.resetAll()
                    }
                } message: {
                    Text(NSLocalizedString(
                        "ui.are.you.sure.you.want",
                        value: "Are you sure you want to delete all practice tests? This action cannot be undone.",
                        comment: "Are you sure you want to delete all practice tests..."
                    ))
                }
        }
    }

    // MARK: - Action Handlers

    /// Global menu action handler
    class GlobalMenuActions: NSObject {
        static let shared = GlobalMenuActions()

        @objc func refresh() {
            CalendarRefreshCoordinator.shared.refresh()
        }

        @objc func navigateToCalendar() {
            NotificationCenter.default.post(name: .navigateToTab, object: nil, userInfo: ["tab": "calendar"])
        }

        @objc func navigateToCourses() {
            Task { @MainActor in
                AppModel.shared.selectedPage = .courses
            }
        }

        @objc func navigateToPlanner() {
            Task { @MainActor in
                AppModalRouter.shared.present(.planner)
            }
        }

        @objc func addAssignment() {
            Task { @MainActor in
                AppModalRouter.shared.present(.addAssignment)
            }
        }

        @objc func addGrade() {
            Task { @MainActor in
                AppModalRouter.shared.present(.addGrade)
            }
        }
    }

    /// Timer-specific menu action handler
    class TimerMenuActions: NSObject {
        static let shared = TimerMenuActions()

        @objc func startClock() {
            NotificationCenter.default.post(name: .timerStartRequested, object: nil)
        }

        @objc func stopClock() {
            NotificationCenter.default.post(name: .timerStopRequested, object: nil)
        }

        @objc func endClock() {
            NotificationCenter.default.post(name: .timerEndRequested, object: nil)
        }
    }

    // MARK: - Notification Names

    // MARK: - View Extensions

    extension View {
        func globalContextMenu(pageSpecificItems: (() -> AnyView)? = nil) -> some View {
            modifier(GlobalContextMenuModifier(pageSpecificItems: pageSpecificItems))
        }

        func timerContextMenu(
            isRunning: Binding<Bool>,
            onStart: @escaping () -> Void,
            onStop: @escaping () -> Void,
            onEnd: @escaping () -> Void
        ) -> some View {
            modifier(TimerContextMenuModifier(isRunning: isRunning, onStart: onStart, onStop: onStop, onEnd: onEnd))
        }

        func practiceTestContextMenu(
            practiceStore: PracticeTestStore,
            scheduledTestsStore: ScheduledTestsStore,
            onNewTest: @escaping () -> Void,
            onRefreshStats: @escaping () -> Void
        ) -> some View {
            modifier(PracticeTestContextMenuModifier(
                practiceStore: practiceStore,
                scheduledTestsStore: scheduledTestsStore,
                onNewTest: onNewTest,
                onRefreshStats: onRefreshStats
            ))
        }
    }

#endif
