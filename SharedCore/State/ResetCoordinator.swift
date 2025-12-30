import Foundation
import Combine

@MainActor
final class ResetCoordinator {
    static let shared = ResetCoordinator()

    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func start(appModel: AppModel = .shared) {
        guard cancellables.isEmpty else { return }
        appModel.resetPublisher
            .sink { [weak self] in
                self?.performReset()
            }
            .store(in: &cancellables)
    }

    func performReset() {
        LOG_DATA(.info, "Reset", "Starting global reset")

        let settings = AppSettingsModel.shared
        settings.suppressICloudRestore = true
        settings.enableICloudSync = false
        NotificationCenter.default.post(name: .iCloudSyncSettingChanged, object: false)

        PlannerSyncCoordinator.shared.reset()

        AssignmentsStore.shared.resetAll()
        AssignmentPlansStore.shared.resetAll()
        AssignmentPlanStore.shared.resetAll()
        PlannerStore.shared.resetAll()
        CoursesStore.shared?.resetAll()
        GradesStore.shared.resetAll()
        StudyHoursTracker.shared.resetAllTotals()
        StorageAggregateStore.shared.resetAll()
        SchedulerPreferencesStore.shared.resetAll()
        SyllabusParsingStore.shared.resetAll()
        PracticeTestStore.shared.resetAll()
        ScheduledTestsStore.shared.resetAll()

        PersistenceController.shared.resetPersistentStore()

        settings.resetToDefaults(preservingICloudSuppression: true, preservingICloudSyncSetting: true)

        LOG_DATA(.info, "Reset", "Global reset complete")
    }
}
