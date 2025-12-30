#if os(iOS)
import SwiftUI

/// Global app shell that provides consistent top bar across all pages
struct IOSAppShell<Content: View>: View {
    @EnvironmentObject private var navigation: IOSNavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var sheetRouter: IOSSheetRouter
    @EnvironmentObject private var toastRouter: IOSToastRouter
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var plannerStore: PlannerStore
    @EnvironmentObject private var filterState: IOSFilterState
    @EnvironmentObject private var settings: AppSettingsModel
    @State private var safeAreaInsets: EdgeInsets = .init()
    @State private var showSettingsSheet = false

    private let overlayTopInset: CGFloat = 10
    private let overlayTrailingInset: CGFloat = 16
    private let buttonSpacing: CGFloat = 12
    private let headerHeight: CGFloat = 52
    
    let title: String
    let content: Content
    let hideNavigationButtons: Bool
    
    init(title: String, hideNavigationButtons: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.hideNavigationButtons = hideNavigationButtons
        self.content = content()
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
            top: safeAreaInsets.top + headerHeight,
            leading: 0,
            bottom: 0,
            trailing: overlayTrailingInset + 44 + buttonSpacing + 44
        )
        let base = ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                headerView
                content
            }
        }
        .readSafeAreaInsets { safeAreaInsets = $0 }
        .environment(\.overlayInsets, overlayInsets)
        .overlay(alignment: .topTrailing) {
            if shouldShowButtons {
                topRightControls
                    .padding(.top, safeAreaInsets.top + overlayTopInset)
                    .padding(.trailing, overlayTrailingInset)
                    .zIndex(1000)
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsRootView()
                .environmentObject(settings)
        }

        if PlatformCapabilities.supportsHiddenNavigationBar {
            base.toolbar(.hidden, for: .navigationBar)
        } else {
            base
        }
    }

    private var headerView: some View {
        HStack {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            Spacer()
        }
        .frame(height: headerHeight)
        .padding(.top, safeAreaInsets.top + overlayTopInset)
        .padding(.horizontal, 16)
    }

    private var topRightControls: some View {
        HStack(spacing: 12) {
            energyIndicator
            quickAddButton
            settingsButton
        }
    }

    private var energyIndicator: some View {
        Group {
            if settings.showEnergyPanel && settings.energySelectionConfirmed {
                Menu {
                    Button("High") { setEnergy("High") }
                    Button("Medium") { setEnergy("Medium") }
                    Button("Low") { setEnergy("Low") }
                } label: {
                    Text("Energy: \(settings.defaultEnergyLevel)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Energy level")
            }
        }
    }

    private var quickAddButton: some View {
        Menu {
            Button {
                handleQuickAction(.add_assignment)
            } label: {
                Label(NSLocalizedString("ios.menu.add_assignment", comment: "Add Assignment"), systemImage: "plus.square.on.square")
            }

            Button {
                handleQuickAction(.add_grade)
            } label: {
                Label(NSLocalizedString("ios.menu.add_grade", comment: "Add Grade"), systemImage: "number.circle")
            }

            Button {
                handleQuickAction(.auto_schedule)
            } label: {
                Label(NSLocalizedString("ios.menu.auto_schedule", comment: "Auto Schedule"), systemImage: "calendar.badge.clock")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: settings.largeTapTargets ? 20 : 18, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(NSLocalizedString("ios.menu.quick_add", comment: "Quick add"))
        .accessibilityHint("Opens quick add actions")
        .accessibilityIdentifier("Overlay.QuickAdd")
    }

    private var settingsButton: some View {
        Button {
            showSettingsSheet = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: settings.largeTapTargets ? 20 : 18, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
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
        let result = PlannerEngine.scheduleSessionsWithStrategy(sessions, settings: settings, energyProfile: defaultEnergyProfile())
        plannerStore.persist(scheduled: result.scheduled, overflow: result.overflow)
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
               course.semesterId != semesterId {
                return false
            }
            return true
        }
    }

    private func category(for task: AppTask) -> AssignmentCategory {
        switch task.category {
        case .exam: return .exam
        case .quiz: return .quiz
        case .homework: return .homework
        case .reading: return .reading
        case .review: return .review
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
            17: 0.6, 18: 0.5, 19: 0.4, 20: 0.35
        ]
    }
}
#endif
