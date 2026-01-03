#if os(macOS)
import SwiftUI
import AppKit
import Combine

struct ContentView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var coursesStore: CoursesStore
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator
    @EnvironmentObject var plannerCoordinator: PlannerCoordinator
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var plannerStore: PlannerStore
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var modalRouter: AppModalRouter
    @EnvironmentObject private var preferences: AppPreferences
    @State private var selectedTab: RootTab = .dashboard
    @State private var settingsRotation: Double = 0
    @Environment(\.colorScheme) private var colorScheme
    @FocusedBinding(\.selectedTab) private var focusedTab: RootTab?

    private var interfacePreferences: InterfacePreferences {
        InterfacePreferences.from(preferences, settings: settings, colorScheme: colorScheme)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.primaryBackground.ignoresSafeArea()

                // LAYER 1: Main content
                AppPageScaffold(
                    title: selectedTab.title,
                    quickActions: settings.quickActions,
                    onQuickAction: performQuickAction,
                    onSettings: {
                        withAnimation(.easeInOut(duration: DesignSystem.Motion.deliberate)) {
                            settingsRotation += 360
                        }
                        settingsCoordinator.show()
                    }
                ) {
                    currentPageView
                        .accessibilityIdentifier("Page.\(selectedTab.rawValue)")
                        .frame(maxWidth: RootsWindowSizing.maxMainContentWidth, maxHeight: .infinity, alignment: .top)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 72 + 32 + proxy.safeAreaInsets.bottom)
                        .contentSafeInsetsForOverlay()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Floating tab bar stays at bottom; keep above content
                VStack {
                    Spacer()
                    let orderedTabs = settings.tabOrder.filter { settings.effectiveVisibleTabs.contains($0) }
                    RootsFloatingTabBar(
                        items: orderedTabs,
                        selected: $selectedTab,
                        mode: settings.tabBarMode,
                        onSelect: handleTabSelection
                    )
                    .frame(height: 72)
                    .frame(maxWidth: 640)
                    .padding(.horizontal, 16)
                    .padding(.bottom, proxy.safeAreaInsets.bottom == 0 ? 16 : proxy.safeAreaInsets.bottom)
                    .frame(maxWidth: .infinity)
                }
                .zIndex(1)
            }
        }
        .interfacePreferences(interfacePreferences)
        .frame(minWidth: RootsWindowSizing.minMainWidth, minHeight: RootsWindowSizing.minMainHeight)
        .globalContextMenu()
        .focusedSceneValue(\.selectedTab, $selectedTab)
        .focusedValue(\.canCreateAssignment, true)
        .onAppear {
            setupNotificationObservers()
            DispatchQueue.main.async {
                if let win = NSApp.keyWindow ?? NSApp.windows.first {
                    win.title = ""
                    win.titleVisibility = .hidden
                    win.titlebarAppearsTransparent = true
                }
            }
            if let initialTab = RootTab(rawValue: appModel.selectedPage.rawValue) {
                selectedTab = initialTab
            }
        }
        .onChange(of: plannerCoordinator.requestedCourseId) { _, courseId in
            selectedTab = .planner
            plannerCoordinator.selectedCourseFilter = courseId
        }
        .onChange(of: plannerCoordinator.requestedDate) { _, date in
            guard date != nil else { return }
            selectedTab = .planner
        }
        .onReceive(appModel.$selectedPage) { page in
            if let tab = RootTab(rawValue: page.rawValue), selectedTab != tab {
                selectedTab = tab
            }
        }
        .onChange(of: modalRouter.route) { _, route in
            guard let route else { return }
            switch route {
            case .planner:
                selectedTab = .planner
                appModel.selectedPage = .planner
                modalRouter.clear()
            case .addAssignment:
                selectedTab = .assignments
                appModel.selectedPage = .assignments
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .addAssignmentRequested, object: nil)
                    modalRouter.clear()
                }
            case .addGrade:
                selectedTab = .grades
                appModel.selectedPage = .grades
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .addGradeRequested, object: nil)
                    modalRouter.clear()
                }
            }
        }
        .onChange(of: settings.enableFlashcards) { _, enabled in
            guard !enabled, selectedTab == .flashcards else { return }
            selectedTab = .dashboard
            appModel.selectedPage = .dashboard
        }
        #if os(macOS)
        .onKeyDown { event in
            switch event.keyCode {
            case 125: // down arrow
                scrollActiveView(by: 120)
            case 126: // up arrow
                scrollActiveView(by: -120)
            default:
                break
            }
        }
        #endif
    }

    @ViewBuilder
    private var currentPageView: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .calendar:
            CalendarPageView()
        case .planner:
            PlannerPageView()
        case .assignments:
            AssignmentsPageView()
        case .courses:
            CoursesPageView()
        case .grades:
            GradesPageView()
        case .timer:
            TimerPageView()
        case .flashcards:
            FlashcardsView()
        case .practice:
            PracticeTestPageView()
        }
    }

    private func performQuickAction(_ action: QuickAction) {
        switch action {
        case .add_assignment:
            LOG_UI(.info, "QuickAction", "Add Assignment")
            break
        case .add_course:
            LOG_UI(.info, "QuickAction", "Add Course")
            break
        case .add_task:
            LOG_UI(.info, "QuickAction", "Add Task")
            break
        case .add_grade:
            LOG_UI(.info, "QuickAction", "Add Grade")
            break
        case .auto_schedule:
            autoSchedule()
        case .quick_note:
            LOG_UI(.info, "QuickAction", "Quick Note")
            break
        case .open_new_note:
            LOG_UI(.info, "QuickAction", "Open New Note")
            break
        }
    }

    private func autoSchedule() {
        let assignments = assignmentsForPlanning()
        guard !assignments.isEmpty else { return }
        let settings = StudyPlanSettings()
        let sessions = assignments.flatMap { PlannerEngine.generateSessions(for: $0, settings: settings) }
        let result = PlannerEngine.scheduleSessionsWithStrategy(sessions, settings: settings, energyProfile: defaultEnergyProfile())
        plannerStore.persist(scheduled: result.scheduled, overflow: result.overflow)
    }

    private func assignmentsForPlanning() -> [Assignment] {
        let today = Calendar.current.startOfDay(for: Date())
        return assignmentsStore.tasks.compactMap { task in
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

    private func category(for task: AppTask) -> AssignmentCategory {
        switch task.category {
        case .exam: return .exam
        case .quiz: return .quiz
        case .homework: return .homework
        case .reading: return .reading
        case .review: return .review
        case .study:
            fallthrough
        case .project: return .project
        }
    }

    private func urgency(for value: Double) -> AssignmentUrgency {
        switch value {
        case ..<0.3: return .low
        case ..<0.6: return .medium
        case ..<0.85: return .high
        default: return .critical
        }
    }

    private func defaultEnergyProfile() -> [Int: Double] {
        [
            9: 0.55, 10: 0.65, 11: 0.7, 12: 0.6,
            13: 0.5, 14: 0.55, 15: 0.65, 16: 0.7,
            17: 0.6, 18: 0.5, 19: 0.45, 20: 0.4
        ]
    }

    private func handleTabSelection(_ tab: RootTab) {
        LOG_NAVIGATION(.info, "TabSelection", "User navigated to tab: \(tab.rawValue)")
        selectedTab = tab
        if let page = AppPage(rawValue: tab.rawValue), appModel.selectedPage != page {
            appModel.selectedPage = page
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(forName: .navigateToTab, object: nil, queue: .main) { notification in
            if let tabString = notification.userInfo?["tab"] as? String,
               let tab = RootTab(rawValue: tabString) {
                selectedTab = tab
            }
        }
        
        // Keyboard shortcut: Tab switching
        NotificationCenter.default.addObserver(forName: .switchToTab, object: nil, queue: .main) { notification in
            if let tab = notification.object as? RootTab {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = tab
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: .addAssignmentRequested, object: nil, queue: .main) { _ in
            LOG_UI(.info, "ContextMenu", "Add Assignment requested")
        }
        
        // Keyboard shortcut: New assignment
        NotificationCenter.default.addObserver(forName: .createNewAssignment, object: nil, queue: .main) { _ in
            LOG_UI(.info, "KeyboardShortcut", "New Assignment (⌘T)")
            // TODO: Show new assignment sheet
        }
        
        // Keyboard shortcut: New course
        NotificationCenter.default.addObserver(forName: .createNewCourse, object: nil, queue: .main) { _ in
            LOG_UI(.info, "KeyboardShortcut", "New Course (⌘⇧N)")
            // TODO: Show new course sheet
        }
        
        // Keyboard shortcut: New deck
        NotificationCenter.default.addObserver(forName: .createNewDeck, object: nil, queue: .main) { _ in
            LOG_UI(.info, "KeyboardShortcut", "New Deck (⌘⇧D)")
            // TODO: Show new deck sheet
        }
        
        // Keyboard shortcut: Focus search
        NotificationCenter.default.addObserver(forName: .focusSearchField, object: nil, queue: .main) { _ in
            LOG_UI(.info, "KeyboardShortcut", "Focus Search (⌘F)")
            // TODO: Focus search field in current view
        }
        
        NotificationCenter.default.addObserver(forName: .addGradeRequested, object: nil, queue: .main) { _ in
            LOG_UI(.info, "ContextMenu", "Add Grade requested")
        }
        
        NotificationCenter.default.addObserver(forName: .refreshRequested, object: nil, queue: .main) { _ in
            // Trigger refresh for current view
            LOG_UI(.info, "ContextMenu", "Refresh requested")
        }
    }

    #if os(macOS)
    /// Scrolls the currently focused scroll view (if any) by the given delta.
    private func scrollActiveView(by deltaY: CGFloat) {
        guard let responder = NSApp.keyWindow?.firstResponder as? NSView else { return }
        let targetScrollView = responder.enclosingScrollView ?? responder.superview?.enclosingScrollView
        guard let scrollView = targetScrollView, let documentView = scrollView.documentView else { return }

        let clipView = scrollView.contentView
        var newOrigin = clipView.bounds.origin
        let maxY = max(0, documentView.bounds.height - clipView.bounds.height)
        newOrigin.y = min(max(newOrigin.y + deltaY, 0), maxY)
        clipView.setBoundsOrigin(newOrigin)
        scrollView.reflectScrolledClipView(clipView)
    }
    #endif
}
#endif
