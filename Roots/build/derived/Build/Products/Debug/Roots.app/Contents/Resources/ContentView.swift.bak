import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var coursesStore: CoursesStore
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator
    @State private var selectedTab: RootTab = .dashboard
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(nsColor: .windowBackgroundColor).ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    currentPageView
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                    RootsFloatingTabBar(
                        items: RootTab.allCases,
                        selected: $selectedTab,
                        mode: settings.tabBarMode,
                        onSelect: { _ in }
                    )
                    .frame(height: 72)
                    .frame(maxWidth: 640)
                    .padding(.horizontal, 16)
                        .padding(.bottom, proxy.safeAreaInsets.bottom == 0 ? 16 : proxy.safeAreaInsets.bottom)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(minWidth: RootsWindowSizing.minMainWidth, minHeight: RootsWindowSizing.minMainHeight)
        .onAppear {
            DispatchQueue.main.async {
                if let win = NSApp.keyWindow ?? NSApp.windows.first {
                    win.title = ""
                    win.titleVisibility = .hidden
                    win.titlebarAppearsTransparent = true
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            // Header pill and fan-out menu removed per request

            Spacer()

            RootsHeaderButton(icon: "gearshape") { settingsCoordinator.show() }
                .rootsStandardInteraction()
        }
        .contentTransition(.opacity)
    }

    @ViewBuilder
    private var currentPageView: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .calendar:
            CalendarView()
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
        case .decks:
            FlashcardDashboard()
        }
    }

    private func performQuickAction(_ action: QuickAction) {
        switch action {
        case .add_assignment:
            // open add assignment flow
            LOG_UI(.info, "QuickAction", "Add Assignment")
            // placeholder: open AddAssignment sheet if implemented
            break
        case .add_course:
            LOG_UI(.info, "QuickAction", "Add Course")
            break
        case .quick_note:
            LOG_UI(.info, "QuickAction", "Quick Note")
            break
        case .open_new_note:
            LOG_UI(.info, "QuickAction", "Open New Note")
            break
        }
    }
}
