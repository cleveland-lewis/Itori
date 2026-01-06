import Foundation
import Combine
import CryptoKit

@MainActor
final class PlannerSyncCoordinator: ObservableObject {
    static let shared = PlannerSyncCoordinator()

    private var cancellables: Set<AnyCancellable> = []
    private var lastScheduleHash: String?
    private var lastCompletionHash: String?

    private init() {}

    func start(
        assignmentsStore: AssignmentsStore,
        plannerStore: PlannerStore,
        settings: AppSettingsModel
    ) {
        guard cancellables.isEmpty else { return }

        assignmentsStore.$tasks
            .map { tasks in
                tasks.map { task in
                    PlannerTaskDTO(
                        id: task.id,
                        title: task.title,
                        courseId: task.courseId,
                        dueDate: task.due,
                        estimatedMinutes: task.estimatedMinutes,
                        category: Self.category(from: task.type),
                        importance: Self.urgency(from: task.importance),
                        difficulty: Self.urgency(from: task.difficulty),
                        isLockedToDueDate: task.locked,
                        isCompleted: task.isCompleted
                    )
                }
            }
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] dtos in
                self?.recomputePlanner(dtos: dtos, plannerStore: plannerStore, settings: settings)
            }
            .store(in: &cancellables)
    }

    func reset() {
        lastScheduleHash = nil
        lastCompletionHash = nil
    }

    func requestRecompute(assignmentsStore: AssignmentsStore, plannerStore: PlannerStore, settings: AppSettingsModel) {
        let dtos = assignmentsStore.tasks.map { task in
            PlannerTaskDTO(
                id: task.id,
                title: task.title,
                courseId: task.courseId,
                dueDate: task.due,
                estimatedMinutes: task.estimatedMinutes,
                category: Self.category(from: task.type),
                importance: Self.urgency(from: task.importance),
                difficulty: Self.urgency(from: task.difficulty),
                isLockedToDueDate: task.locked,
                isCompleted: task.isCompleted
            )
        }
        recomputePlanner(dtos: dtos, plannerStore: plannerStore, settings: settings, force: true)
    }

    private func recomputePlanner(
        dtos: [PlannerTaskDTO],
        plannerStore: PlannerStore,
        settings: AppSettingsModel,
        force: Bool = false
    ) {
        let filtered = filterPlannerTasks(dtos)
        let scheduleHash = hashForSchedule(filtered)
        let completionHash = hashForCompletion(dtos)
        let completionChanged = completionHash != lastCompletionHash
        lastCompletionHash = completionHash

        if !force, scheduleHash == lastScheduleHash {
            if completionChanged {
                syncCalendarNotes(plannerStore: plannerStore)
            }
            return
        }
        lastScheduleHash = scheduleHash

        let sessions = filtered.flatMap { PlannerEngine.generateSessions(for: $0, settings: StudyPlanSettings()) }
        let energy = SchedulerPreferencesStore.shared.energyProfileForPlanning(settings: settings)
        let scheduledResult = PlannerEngine.scheduleSessionsWithStrategy(sessions, settings: StudyPlanSettings(), energyProfile: energy)
        plannerStore.persist(scheduled: scheduledResult.scheduled, overflow: scheduledResult.overflow)
        syncPlannerCalendar(for: scheduledResult.scheduled)
    }

    private func filterPlannerTasks(_ tasks: [PlannerTaskDTO]) -> [PlannerTaskDTO] {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let horizonEnd = calendar.date(byAdding: .day, value: 14, to: now) ?? now
        return tasks.filter { task in
            guard !task.isCompleted else { return false }
            guard task.estimatedMinutes > 0 else { return false }
            guard let dueDate = task.dueDate else { return false }
            return dueDate <= horizonEnd
        }
    }

    private func hashForSchedule(_ tasks: [PlannerTaskDTO]) -> String {
        let payload = tasks
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { task in
                let dueTime = task.dueDate?.timeIntervalSince1970 ?? 0
                return "\(task.id.uuidString)|\(dueTime)|\(task.estimatedMinutes)|\(task.category.rawValue)|\(task.importance.rawValue)|\(task.difficulty.rawValue)|\(task.isLockedToDueDate)"
            }
            .joined(separator: "||")
        let digest = SHA256.hash(data: Data(payload.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func hashForCompletion(_ tasks: [PlannerTaskDTO]) -> String {
        let payload = tasks
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { task in
                "\(task.id.uuidString)|\(task.isCompleted)"
            }
            .joined(separator: "||")
        let digest = SHA256.hash(data: Data(payload.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func syncCalendarNotes(plannerStore: PlannerStore) {
        let sessions = plannerStore.scheduled
        guard let start = sessions.map({ $0.start }).min(),
              let end = sessions.map({ $0.end }).max() else { return }
        Task { await CalendarManager.shared.syncPlannerSessionsToCalendar(in: start...end) }
    }

    private func syncPlannerCalendar(for scheduled: [ScheduledSession]) {
        guard let start = scheduled.map({ $0.start }).min(),
              let end = scheduled.map({ $0.end }).max() else { return }
        Task { await CalendarManager.shared.syncPlannerSessionsToCalendar(in: start...end) }
    }

    private static func urgency(from value: Double) -> AssignmentUrgency {
        switch value {
        case ..<0.3: return .low
        case ..<0.7: return .medium
        default: return .high
        }
    }
    
    private static func category(from type: TaskType) -> AssignmentCategory {
        switch type {
        case .exam: return .exam
        case .quiz: return .quiz
        case .project: return .project
        case .homework: return .homework
        case .reading: return .reading
        case .review: return .review
        case .study: return .review
        case .practiceTest: return .practiceTest
        }
    }
}
