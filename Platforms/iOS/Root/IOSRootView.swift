#if os(iOS)
import SwiftUI

struct IOSRootView: View {
    @EnvironmentObject private var settings: AppSettingsModel
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var sheetRouter: IOSSheetRouter
    @EnvironmentObject private var toastRouter: IOSToastRouter
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var gradesStore: GradesStore
    @EnvironmentObject private var plannerCoordinator: PlannerCoordinator
    @StateObject private var navigation = IOSNavigationCoordinator()
    @StateObject private var tabBarPrefs: TabBarPreferencesStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTab: RootTab = .dashboard
    @State private var selectedTabOrMore: TabSelection = .tab(.dashboard)
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showMoreMenu = false
    @State private var moreMenuSelected = false
    @State private var selectedMorePage: AppPage? = nil
    @State private var showingCoursesSyncConflict = false
    
    private enum TabSelection: Hashable {
        case tab(RootTab)
        case more
    }
    
    init() {
        _tabBarPrefs = StateObject(wrappedValue: TabBarPreferencesStore(settings: AppSettingsModel.shared))
    }
    
    private var interfacePreferences: InterfacePreferences {
        InterfacePreferences.from(preferences, settings: settings, colorScheme: colorScheme)
    }
    
    private var layoutMetrics: LayoutMetrics {
        LayoutMetrics(
            compactMode: settings.compactModeStorage,
            largeTapTargets: settings.largeTapTargetsStorage
        )
    }

    private var starredTabs: [RootTab] {
        var tabs = settings.starredTabs
        
        // Remove Practice tab from iOS (not supported on mobile)
        tabs.removeAll { $0 == .practice }
        
        // Ensure at least Dashboard is present
        if tabs.isEmpty {
            tabs = [.dashboard]
        }
        
        // Validate current selection
        if !tabs.contains(selectedTab) {
            selectedTab = tabs.first ?? .dashboard
        }
        
        return tabs
    }
    
    private var isPad: Bool {
        horizontalSizeClass == .regular
    }
    
    private var preferredColorScheme: ColorScheme? {
        switch settings.interfaceStyle {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            let hour = Calendar.current.component(.hour, from: Date())
            return (hour >= 19 || hour < 7) ? .dark : .light
        }
    }

    var body: some View {
        bodyContent
            .background(DesignSystem.Colors.appBackground)
            .environmentObject(navigation)
            .environmentObject(tabBarPrefs)
            .layoutMetrics(layoutMetrics)
            .interfacePreferences(interfacePreferences)
            .preferredColorScheme(preferredColorScheme)
            .transaction { transaction in
                if !settings.showAnimations {
                    transaction.disablesAnimations = true
                }
            }
            .overlay(alignment: .top) {
                toastOverlay
            }
            .sheet(item: $sheetRouter.activeSheet) { sheet in
                sheetContent(for: sheet)
            }
            .alert(
                NSLocalizedString("sync.conflict.courses.title", value: "Courses Sync Conflict", comment: "Courses sync conflict title"),
                isPresented: $showingCoursesSyncConflict
            ) {
                Button(NSLocalizedString("sync.conflict.courses.keep_local", value: "Keep Local", comment: "Keep local data")) {
                    CoursesStore.shared?.resolveSyncConflict(useCloud: false)
                }
                Button(NSLocalizedString("sync.conflict.courses.use_icloud", value: "Use iCloud", comment: "Use iCloud data"), role: .destructive) {
                    CoursesStore.shared?.resolveSyncConflict(useCloud: true)
                }
            } message: {
                Text(NSLocalizedString("sync.conflict.courses.message", value: "Courses and semesters differ between this device and iCloud. Choose which data to keep.", comment: "Courses sync conflict message"))
            }
            .onChange(of: plannerCoordinator.requestedDate) { _, date in
                guard date != nil else { return }
                openPlannerPage()
                plannerCoordinator.requestedDate = nil
            }
            .onChange(of: plannerCoordinator.requestedCourseId) { _, _ in
                openPlannerPage()
            }
            .onReceive(NotificationCenter.default.publisher(for: .coursesSyncConflict)) { _ in
                showingCoursesSyncConflict = true
            }
    }
    
    private var bodyContent: some View {
        ZStack {
            if isPad && settings.showSidebarByDefault {
                ipadWithSidebarView
            } else {
                standardNavigationView
            }
        }
        .background(DesignSystem.Colors.appBackground)
    }
    
    private var ipadWithSidebarView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
        } detail: {
            detailContent
        }
        .onAppear {
            columnVisibility = .all
        }
    }
    
    private var standardNavigationView: some View {
        NavigationStack(path: $navigation.path) {
            TabView(selection: $selectedTabOrMore) {
                ForEach(starredTabs, id: \.self) { tab in
                    IOSAppShell(title: tab.title) {
                        tabView(for: tab)
                    }
                    .tag(TabSelection.tab(tab))
                    .tabItem {
                        if let def = TabRegistry.definition(for: tab) {
                            Label(def.title, systemImage: def.icon)
                        }
                    }
                }
                
                // More menu tab (rightmost position)
                IOSAppShell(title: moreTabTitle) {
                    moreTabContent
                }
                    .tag(TabSelection.more)
                    .tabItem {
                        Label(NSLocalizedString("iosroot.label.more", value: "More", comment: "More"), systemImage: "ellipsis.circle")
                    }
            }
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar(.visible, for: .tabBar)
            .navigationDestination(for: IOSNavigationTarget.self) { destination in
                IOSAppShell(title: destinationTitle(for: destination), hideNavigationButtons: false) {
                    switch destination {
                    case .page(let page):
                        pageView(for: page)
                    }
                }
            }
        }
        .toolbarBackground(.automatic, for: .navigationBar)
        .sheet(isPresented: $showMoreMenu) {
            moreMenuSheet
        }
        .onChange(of: selectedTabOrMore) { oldValue, newValue in
            if case .more = newValue {
                // If tapping More while already in More tab, show the menu
                if case .more = oldValue {
                    showMoreMenu = true
                } else if selectedMorePage == nil {
                    // First time selecting More tab with no page selected
                    showMoreMenu = false
                } else {
                    // Switching to More tab while a page is already selected
                    showMoreMenu = false
                }
            } else if case .tab(let tab) = newValue {
                selectedTab = tab
                // Clear selected more page when switching away from More tab
                if case .more = oldValue {
                    selectedMorePage = nil
                }
            }
        }
        .onChange(of: settings.enableFlashcards) { _, enabled in
            guard !enabled else { return }
            
            // If currently on flashcards tab, switch to dashboard
            if selectedTab == .flashcards {
                selectedTab = .dashboard
                selectedTabOrMore = .tab(.dashboard)
            }
            
            // If flashcards page is selected in More tab, clear it
            if selectedMorePage == .flashcards {
                selectedMorePage = nil
            }
            
            // Clear navigation path to remove any flashcards page from stack
            navigation.path = NavigationPath()
        }
    }
    
    @ViewBuilder
    private var toastOverlay: some View {
        if let message = toastRouter.message {
            toastView(message)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeOut(duration: 0.2), value: toastRouter.message)
        }
    }
    
    // MARK: - iPad Sidebar Navigation
    
    @ViewBuilder
    private var sidebarContent: some View {
        List {
            ForEach(starredTabs, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    if let def = TabRegistry.definition(for: tab) {
                        Label(def.title, systemImage: def.icon)
                    }
                }
                .listRowBackground(selectedTab == tab ? Color.primary.opacity(0.12) : Color.clear)
            }
            
            Section("Other Pages") {
                ForEach(nonStarredTabs, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        if let def = TabRegistry.definition(for: tab) {
                            Label(def.title, systemImage: def.icon)
                        }
                    }
                }
            }
        }
        .navigationTitle("Itori")
        .listStyle(.sidebar)
    }
    
    @ViewBuilder
    private var detailContent: some View {
        NavigationStack(path: $navigation.path) {
            tabView(for: selectedTab)
                .navigationDestination(for: IOSNavigationTarget.self) { destination in
                    switch destination {
                    case .page(let page):
                        pageView(for: page)
                    }
                }
        }
    }
    
    private var nonStarredTabs: [RootTab] {
        TabRegistry.allTabs.map { $0.id }.filter { !starredTabs.contains($0) }
    }

    private func toastView(_ message: String) -> some View {
        VStack {
            Text(message)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .shadow(radius: 6, y: 3)
                )
            Spacer()
        }
        .padding(.top, 18)
        .padding(.horizontal, 16)
    }

    private func openPlannerPage() {
        if starredTabs.contains(.planner) {
            selectedTab = .planner
            navigation.path = NavigationPath()
        } else {
            navigation.open(page: .planner, starredTabs: starredTabs)
        }
    }

    private func gradeCourseSummaries() -> [GradeCourseSummary] {
        coursesStore.activeCourses.map { course in
            GradeCourseSummary(id: course.id, title: course.code.isEmpty ? course.title : course.code)
        }
    }

    @ViewBuilder
    private func tabView(for tab: RootTab) -> some View {
        switch tab {
        case .dashboard:
            IOSDashboardView()
        case .calendar:
            IOSCalendarView()
        case .planner:
            IOSPlannerView()
        case .assignments:
            IOSAssignmentsView()
        case .courses:
            IOSCoursesView()
        case .grades:
            IOSGradesView()
        case .timer:
            IOSTimerPageView()
        case .flashcards:
            IOSFlashcardsView()
        case .practice:
            IOSPlaceholderView(title: "Practice Tests", subtitle: "Practice tests are only available on macOS.")
        default:
            IOSPlaceholderView(title: tab.title, subtitle: "This page is not available on iOS yet.")
        }
    }

    @ViewBuilder
    private func pageView(for page: AppPage) -> some View {
        switch page {
        case .dashboard:
            IOSDashboardView()
        case .calendar:
            IOSCalendarView()
        case .planner:
            IOSPlannerView()
        case .assignments:
            IOSAssignmentsView()
        case .courses:
            IOSCoursesView()
        case .grades:
            IOSGradesView()
        case .timer:
            IOSTimerPageView()
        case .flashcards:
            IOSFlashcardsView()
        case .practice:
            IOSPlaceholderView(title: "Practice Tests", subtitle: "Practice tests are only available on macOS.")
        default:
            IOSPlaceholderView(title: page.title, subtitle: "This view is coming soon.")
        }
    }

    private func destinationTitle(for destination: IOSNavigationTarget) -> String {
        switch destination {
        case .page(let page):
            return page.title
        }
    }
    
    // MARK: - More Menu
    
    private var moreMenuSheet: some View {
        NavigationStack {
            List {
                ForEach(nonStarredTabs, id: \.self) { tab in
                    Button {
                        selectedMorePage = AppPage.from(tab)
                        showMoreMenu = false
                    } label: {
                        HStack {
                            if let def = TabRegistry.definition(for: tab) {
                                Label {
                                    Text(def.title)
                                        .foregroundColor(.primary)
                                } icon: {
                                    Image(systemName: def.icon)
                                        .foregroundColor(.accentColor)
                                        .frame(width: 28, height: 28)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More Pages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("iosroot.button.done", value: "Done", comment: "Done")) {
                        showMoreMenu = false
                    }
                }
            }
        }
    }

    private var moreTabTitle: String {
        selectedMorePage?.title ?? NSLocalizedString("iosroot.label.more", value: "More", comment: "More")
    }

    @ViewBuilder
    private var moreTabContent: some View {
        if let page = selectedMorePage {
            pageView(for: page)
        } else {
            List {
                ForEach(nonStarredTabs, id: \.self) { tab in
                    Button {
                        selectedMorePage = AppPage.from(tab)
                    } label: {
                        if let def = TabRegistry.definition(for: tab) {
                            Label(def.title, systemImage: def.icon)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
        private var settingsContent: some View {
        List {
            ForEach(SettingsCategory.allCases) { category in
                NavigationLink(destination: category.destinationView()) {
                    Label {
                        Text(category.title)
                    } icon: {
                        Image(systemName: category.systemImage)
                            .foregroundColor(.accentColor)
                            .frame(width: 28, height: 28)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("ios.settings.title", comment: "Settings"))
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: IOSSheetRouter.SheetKind) -> some View {
        switch sheet {
        case .addAssignment(let defaults):
            IOSTaskEditorView(
                task: nil,
                courses: coursesStore.activeCourses,
                defaults: .init(
                    title: defaults.title,
                    courseId: defaults.courseId,
                    dueDate: defaults.dueDate,
                    type: defaults.type
                ),
                itemLabel: defaults.itemLabel,
                onSave: { draft in
                    let task = draft.makeTask(existing: nil)
                    assignmentsStore.addTask(task)
                    toastRouter.show(String(format: NSLocalizedString("ios.toast.assignment_added", comment: "Assignment added"), defaults.itemLabel))
                }
            )
        case .addCourse(let defaults):
            IOSCourseEditorView(
                semesters: coursesStore.activeSemesters,
                currentSemesterId: defaults.semesterId ?? coursesStore.currentSemesterId,
                defaults: .init(title: defaults.title, code: defaults.code, semesterId: defaults.semesterId),
                onSave: { draft in
                    guard let semester = coursesStore.semesters.first(where: { $0.id == draft.semesterId }) else { return }
                    coursesStore.addCourse(title: draft.title, code: draft.code, to: semester)
                    toastRouter.show(NSLocalizedString("ios.toast.course_added", comment: "Course added"))
                }
            )
        case .addGrade:
            AddGradeSheet(
                assignments: assignmentsStore.tasks,
                courses: gradeCourseSummaries(),
                onSave: { updatedTask in
                    assignmentsStore.updateTask(updatedTask)
                    if let courseId = updatedTask.courseId {
                        gradesStore.upsert(courseId: courseId, percent: updatedTask.gradeWeightPercent, letter: nil)
                    }
                    toastRouter.show(NSLocalizedString("ios.toast.grade_added", comment: "Grade added"))
                }
            )
        }
    }
}
#endif
