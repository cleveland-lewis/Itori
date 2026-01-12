#if os(macOS)
    import AppKit
    import Combine
    import SwiftUI

    enum WindowSizing {
        static let minMainWidth: CGFloat = 1100
        static let minMainHeight: CGFloat = 700
        static let maxMainContentWidth: CGFloat = 1400
        static let minSidebarWidth: CGFloat = 200
        static let idealSidebarWidth: CGFloat = 220
    }

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
        @State private var currentEnergyLevel: EnergyLevel = .medium
        @State private var settingsRotation: Double = 0
        @State private var columnVisibility: NavigationSplitViewVisibility = .all
        @Environment(\.colorScheme) private var colorScheme
        @FocusedBinding(\.selectedTab) private var focusedTab: RootTab?

        private var interfacePreferences: InterfacePreferences {
            InterfacePreferences.from(preferences, settings: settings, colorScheme: colorScheme)
        }

        var body: some View {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // Sidebar
                sidebarContent
            } detail: {
                // Main content
                detailContent
            }
            .interfacePreferences(interfacePreferences)
            .frame(minWidth: WindowSizing.minMainWidth, minHeight: WindowSizing.minMainHeight)
            .globalContextMenu()
            .focusedSceneValue(\FocusedValues.selectedTab, $selectedTab)
            .focusedValue(\FocusedValues.canCreateAssignment, true)
            .onAppear {
                setupNotificationObservers()
                DispatchQueue.main.async {
                    if let win = NSApp.keyWindow ?? NSApp.windows.first {
                        win.title = "Itori"
                        win.titleVisibility = .visible
                        win.titlebarAppearsTransparent = false
                    }
                }
                if let initialTab = RootTab(rawValue: appModel.selectedPage.rawValue) {
                    selectedTab = initialTab
                }
            }
            .onChange(of: selectedTab) { _, newTab in
                // Sync to appModel when sidebar selection changes
                if let page = AppPage(rawValue: newTab.rawValue), appModel.selectedPage != page {
                    appModel.selectedPage = page
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

        // MARK: - Sidebar

        private var sidebarContent: some View {
            List(selection: $selectedTab) {
                ForEach(visibleTabs, id: \.self) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .accessibilityIdentifier("Sidebar.\(tab.rawValue)")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Itori")
            .navigationSplitViewColumnWidth(
                min: WindowSizing.minSidebarWidth,
                ideal: WindowSizing.idealSidebarWidth
            )
        }

        private var visibleTabs: [RootTab] {
            RootTab.allCases.filter { tab in
                // Filter flashcards based on settings
                if tab == .flashcards {
                    return settings.enableFlashcards
                }
                return true
            }
        }

        // MARK: - Detail Content

        private var detailContent: some View {
            VStack(spacing: 0) {
                // Main page content - toolbar integrated into NavigationSplitView
                currentPageView
                    .accessibilityIdentifier("Page.\(selectedTab.rawValue)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("")
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 20)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    // Energy indicator - glass pill
                    energyIndicator
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 30)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                }

                ToolbarItem(placement: .automatic) {
                    // Settings button - glass pill
                    Button(action: {
                        withAnimation(.easeInOut(duration: DesignSystem.Motion.deliberate)) {
                            settingsRotation += 360
                        }
                        settingsCoordinator.show()
                    }) {
                        Image(systemName: "gear")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(settingsRotation))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Open application settings")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(height: 30)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }
        }

        // MARK: - Energy Indicator

        private var energyIndicator: some View {
            HStack(spacing: 6) {
                ForEach(EnergyLevel.allCases, id: \.self) { level in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            currentEnergyLevel = level
                        }
                    }) {
                        Circle()
                            .fill(currentEnergyLevel == level ? level.color : Color.secondary.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        currentEnergyLevel == level ? level.color : Color.clear,
                                        lineWidth: 2
                                    )
                                    .frame(width: 14, height: 14)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("\(level.label) Energy")
                    .accessibilityLabel("\(level.label) Energy")
                    .accessibilityHint("Set your current energy level to \(level.label.lowercased())")
                }
            }
        }

        // MARK: - Page Views

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

        // MARK: - Helper Methods

        private func setupNotificationObservers() {
            NotificationCenter.default.addObserver(forName: .navigateToTab, object: nil, queue: .main) { notification in
                if let tabString = notification.userInfo?["tab"] as? String,
                   let tab = RootTab(rawValue: tabString)
                {
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
                // Deferred: Keyboard shortcut wiring (see BACKLOG.md)
            }

            // Keyboard shortcut: New course
            NotificationCenter.default.addObserver(forName: .createNewCourse, object: nil, queue: .main) { _ in
                LOG_UI(.info, "KeyboardShortcut", "New Course (⌘⇧N)")
                // Deferred: Keyboard shortcut wiring (see BACKLOG.md)
            }

            // Keyboard shortcut: New deck
            NotificationCenter.default.addObserver(forName: .createNewDeck, object: nil, queue: .main) { _ in
                LOG_UI(.info, "KeyboardShortcut", "New Deck (⌘⇧D)")
                // Deferred: Keyboard shortcut wiring (see BACKLOG.md)
            }

            // Keyboard shortcut: Focus search
            NotificationCenter.default.addObserver(forName: .focusSearchField, object: nil, queue: .main) { _ in
                LOG_UI(.info, "KeyboardShortcut", "Focus Search (⌘F)")
                // Deferred: Keyboard shortcut wiring (see BACKLOG.md)
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
