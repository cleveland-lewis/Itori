#if os(iOS)
import SwiftUI

struct IOSRootView: View {
    @EnvironmentObject private var settings: AppSettingsModel
    @EnvironmentObject private var sheetRouter: IOSSheetRouter
    @EnvironmentObject private var toastRouter: IOSToastRouter
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var gradesStore: GradesStore
    @StateObject private var navigation = IOSNavigationCoordinator()
    @StateObject private var tabBarPrefs = TabBarPreferencesStore(settings: AppSettingsModel.shared)
    
    @State private var selectedTab: RootTab = .dashboard

    private var starredTabs: [RootTab] {
        let starred = settings.starredTabs
        // Ensure at least Dashboard is present
        return starred.isEmpty ? [.dashboard] : starred
    }

    var body: some View {
        ZStack {
            NavigationStack(path: $navigation.path) {
                TabView(selection: $selectedTab) {
                    ForEach(starredTabs, id: \.self) { tab in
                        IOSAppShell {
                            tabView(for: tab)
                        }
                        .tag(tab)
                        .tabItem {
                            if let def = TabRegistry.definition(for: tab) {
                                Label(def.title, systemImage: def.icon)
                            }
                        }
                    }
                }
                .navigationDestination(for: IOSNavigationTarget.self) { destination in
                    IOSAppShell {
                        switch destination {
                        case .page(let page):
                            pageView(for: page)
                        case .settings:
                            IOSSettingsView()
                        }
                    }
                }
            }
            .background(DesignSystem.Colors.appBackground)
            .environmentObject(navigation)
            .environmentObject(tabBarPrefs)

            if let message = toastRouter.message {
                toastView(message)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeOut(duration: 0.2), value: toastRouter.message)
            }
        }
        .sheet(item: $sheetRouter.activeSheet) { sheet in
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
                        toastRouter.show("\(defaults.itemLabel) added")
                    }
                )
            case .addCourse(let defaults):
                IOSCourseEditorView(
                    semesters: coursesStore.activeSemesters,
                    currentSemesterId: defaults.semesterId ?? coursesStore.currentSemesterId,
                    defaults: .init(title: defaults.title, code: defaults.code, semesterId: defaults.semesterId),
                    onSave: { draft in
                        guard let semester = coursesStore.activeSemesters.first(where: { $0.id == draft.semesterId }) else { return }
                        coursesStore.addCourse(title: draft.title, code: draft.code, to: semester)
                        toastRouter.show("Course added")
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
                        toastRouter.show("Grade added")
                    }
                )
            }
        }
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
        case .timer:
            IOSTimerPageView()
        case .practice:
            IOSPracticeView()
        case .settings:
            IOSSettingsView()
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
        case .timer:
            IOSTimerPageView()
        case .practice:
            IOSPracticeView()
        default:
            IOSPlaceholderView(title: page.title, subtitle: "This view is coming soon.")
        }
    }
}
#endif
