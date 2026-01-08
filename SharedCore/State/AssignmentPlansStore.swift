import Foundation
import Combine

/// Store for managing assignment plans
/// Handles persistence, refresh triggers, and plan lifecycle
@MainActor
final class AssignmentPlansStore: ObservableObject {
    static let shared = AssignmentPlansStore()
    
    @Published private(set) var plans: [UUID: AssignmentPlan] = [:]
    @Published private(set) var isLoading = true
    @Published var lastRefreshDate: Date?
    
    private let storageURL: URL
    private let settings: PlanGenerationSettings
    private var iCloudMonitor: Timer?
    private var iCloudToggleObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var iCloudURL: URL? = {
        let containerIdentifier = "iCloud.com.cwlewisiii.Itori"
        guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) else {
            return nil
        }
        let documentsURL = ubiquityURL.appendingPathComponent("Documents/Plans")
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        return documentsURL.appendingPathComponent("assignment_plans.json")
    }()
    
    private var isSyncEnabled: Bool {
        AppSettingsModel.shared.enableICloudSync
    }
    
    private init() {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("RootsPlans", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        self.storageURL = folder.appendingPathComponent("assignment_plans.json")
        self.settings = .default
        
        load()
        isLoading = false
        
        observeICloudToggle()
        if isSyncEnabled {
            loadFromiCloudIfEnabled()
            setupiCloudMonitoring()
        }
    }
    
    // MARK: - Plan Access
    
    func plan(for assignmentId: UUID) -> AssignmentPlan? {
        plans[assignmentId]
    }
    
    func hasPlan(for assignmentId: UUID) -> Bool {
        plans[assignmentId] != nil
    }
    
    // MARK: - Plan Generation
    
    /// Generate or regenerate a plan for a single assignment
    func generatePlan(for assignment: Assignment, force: Bool = false) {
        if !force && hasPlan(for: assignment.id) {
            return
        }
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment, settings: settings)
        plans[assignment.id] = plan
        save()
        
        // Trigger AI scheduler to schedule the sessions
        Task { @MainActor in
            scheduleAssignmentSessions(for: assignment)
        }
    }
    
    /// Generate plans for multiple assignments
    func generatePlans(for assignments: [Assignment], force: Bool = false) {
        for assignment in assignments {
            generatePlan(for: assignment, force: force)
        }
    }
    
    /// Regenerate all plans (manual refresh)
    func regenerateAllPlans(for assignments: [Assignment]) {
        generatePlans(for: assignments, force: true)
        lastRefreshDate = Date()
    }

    func resetAll() {
        plans.removeAll()
        lastRefreshDate = nil
        try? FileManager.default.removeItem(at: storageURL)
        save()
    }
    
    // MARK: - AI Scheduler Integration
    
    private func scheduleAssignmentSessions(for assignment: Assignment) {
        Task { @MainActor in
            let settings = StudyPlanSettings()
            
            // Use fallback planner directly (AI scheduling ports disabled due to Sendable requirements)
            let fallbackSessions = PlannerEngine.generateSessions(for: assignment, settings: settings)
            
            let energyProfile = SchedulerPreferencesStore.shared.energyProfileForPlanning()
            let result = PlannerEngine.scheduleSessions(fallbackSessions, settings: settings, energyProfile: energyProfile)
            let scheduled = result.scheduled
            let finalOverflow = result.overflow

            let metadata = AIScheduleMetadata(
                inputHash: UUID().uuidString,
                computedAt: Date(),
                confidence: 0.8,
                provenance: "fallback_heuristic"
            )
            logPlanDiff(for: assignment.id, scheduled: scheduled)
            PlannerStore.shared.persist(scheduled: scheduled, overflow: finalOverflow, metadata: metadata)
        }
    }

    /* Disabled - AI scheduling ports not available due to Sendable requirements
    private func plannerSessions(from proposals: [GenerateStudyPlanPort.SessionProposal]) -> [PlannerSession] {
        proposals.map {
            PlannerSession(
                assignmentId: $0.assignmentId,
                sessionIndex: $0.sessionIndex,
                sessionCount: $0.sessionCount,
                title: $0.title,
                dueDate: $0.dueDate,
                category: $0.category,
                importance: $0.urgency,
                difficulty: $0.urgency,
                estimatedMinutes: $0.estimatedMinutes,
                isLockedToDueDate: $0.isLockedToDueDate,
                scheduleIndex: 0
            )
        }
    }

    private func plannerSessionLookup(
        from proposals: [GenerateStudyPlanPort.SessionProposal]
    ) -> [SessionLookupKey: PlannerSession] {
        let sessions = plannerSessions(from: proposals)
        return Dictionary(uniqueKeysWithValues: sessions.map { (SessionLookupKey(session: $0), $0) })
    }

    private func scheduledSessions(
        from blocks: [SchedulePlacementPort.ScheduledBlock],
        lookup: [SessionLookupKey: PlannerSession]
    ) -> [ScheduledSession] {
        blocks.compactMap { block in
            let key = SessionLookupKey(assignmentId: block.assignmentId, sessionIndex: block.sessionIndex)
            guard let session = lookup[key] else { return nil }
            return ScheduledSession(id: UUID(), session: session, start: block.start, end: block.end)
        }
    }

    private func sessionProposal(from session: PlannerSession) -> GenerateStudyPlanPort.SessionProposal {
        GenerateStudyPlanPort.SessionProposal(
            assignmentId: session.assignmentId,
            title: session.title,
            dueDate: session.dueDate,
            category: session.category,
            urgency: session.importance,
            estimatedMinutes: session.estimatedMinutes,
            isLockedToDueDate: session.isLockedToDueDate,
            sessionIndex: session.sessionIndex,
            sessionCount: session.sessionCount
        )
    }

    private func metadata<T: Encodable>(
        from result: AIResult<T>?,
        fallbackInput: Encodable
    ) -> AIScheduleMetadata {
        if let result {
            return AIScheduleMetadata(
                inputHash: result.metadata.inputHash,
                computedAt: result.metadata.computedAt,
                confidence: result.confidence.value,
                provenance: result.provenance.primaryProvider.rawValue
            )
        }
        let inputHash = (try? encodedHash(for: fallbackInput)) ?? UUID().uuidString
        return AIScheduleMetadata(
            inputHash: inputHash,
            computedAt: Date(),
            confidence: 0.5,
            provenance: AIProviderID.fallbackHeuristic.rawValue
        )
    }

    private func mergeMetadata(_ primary: AIScheduleMetadata, _ secondary: AIScheduleMetadata) -> AIScheduleMetadata {
        let combinedHash = "\(primary.inputHash)|\(secondary.inputHash)".data(using: .utf8)?.sha256Hash() ?? primary.inputHash
        let confidence = min(primary.confidence, secondary.confidence)
        let computedAt = max(primary.computedAt, secondary.computedAt)
        let provenance = "mixed:\(primary.provenance),\(secondary.provenance)"
        return AIScheduleMetadata(
            inputHash: combinedHash,
            computedAt: computedAt,
            confidence: confidence,
            provenance: provenance
        )
    }
    */ // End of disabled AI scheduling helper functions

    private func encodedHash(for input: Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(AnyEncodable(input))
        return data.sha256Hash()
    }

    private struct AnyEncodable: Encodable {
        private let encodeFunc: (Encoder) throws -> Void
        init(_ value: Encodable) {
            self.encodeFunc = value.encode(to:)
        }
        func encode(to encoder: Encoder) throws {
            try encodeFunc(encoder)
        }
    }

    private struct SessionLookupKey: Hashable {
        let assignmentId: UUID
        let sessionIndex: Int

        init(assignmentId: UUID, sessionIndex: Int) {
            self.assignmentId = assignmentId
            self.sessionIndex = sessionIndex
        }

        init(session: PlannerSession) {
            self.assignmentId = session.assignmentId
            self.sessionIndex = session.sessionIndex
        }
    }

    private func logPlanDiff(for assignmentId: UUID, scheduled: [ScheduledSession]) {
        let existing = PlannerStore.shared.scheduled.filter { $0.assignmentId == assignmentId }
        let existingIds = Set(existing.map { $0.id })
        let newIds = Set(scheduled.map { $0.id })
        let added = newIds.subtracting(existingIds).count
        let removed = existingIds.subtracting(newIds).count
        LOG_AI(.info, "PlannerDiff", "Plan proposal generated", metadata: [
            "assignmentId": assignmentId.uuidString,
            "added": "\(added)",
            "removed": "\(removed)"
        ])
    }
    
    // MARK: - Plan Lifecycle
    
    /// Update an existing plan
    func updatePlan(_ plan: AssignmentPlan) {
        plans[plan.assignmentId] = plan
        save()
    }
    
    /// Mark a step as completed
    func completeStep(stepId: UUID, in assignmentId: UUID) {
        guard var plan = plans[assignmentId] else { return }
        
        if let stepIndex = plan.steps.firstIndex(where: { $0.id == stepId }) {
            var step = plan.steps[stepIndex]
            step.isCompleted = true
            step.completedAt = Date()
            plan.steps[stepIndex] = step
            
            if plan.isFullyCompleted {
                plan.status = .completed
            }
            
            plans[assignmentId] = plan
            save()
        }
    }

    // MARK: - iCloud Sync
    
    private func loadFromiCloudIfEnabled() {
        guard isSyncEnabled else { return }
        loadFromiCloud()
    }
    
    private func loadFromiCloud() {
        guard let iCloudURL else { return }
        guard FileManager.default.fileExists(atPath: iCloudURL.path) else { return }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let coordinator = NSFileCoordinator()
            var error: NSError?
            var cloudData: Data?
            
            coordinator.coordinate(readingItemAt: iCloudURL, options: [], error: &error) { url in
                cloudData = try? Data(contentsOf: url)
            }
            
            guard error == nil, let data = cloudData else { return }
            
            do {
                let payload = try JSONDecoder().decode(PlansPayload.self, from: data)
                let cloudPlans = Dictionary(uniqueKeysWithValues: payload.plans.map { ($0.assignmentId, $0) })
                DispatchQueue.main.async {
                    if cloudPlans != self.plans {
                        self.plans = cloudPlans
                        self.save()
                    }
                }
            } catch {
                return
            }
        }
    }
    
    private func saveToiCloud() {
        guard let iCloudURL, isSyncEnabled else { return }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            do {
                let payload = PlansPayload(plans: Array(self.plans.values))
                let data = try JSONEncoder().encode(payload)
                let coordinator = NSFileCoordinator()
                var error: NSError?
                coordinator.coordinate(writingItemAt: iCloudURL, options: .forReplacing, error: &error) { url in
                    try? data.write(to: url, options: [.atomic])
                }
            } catch {
                return
            }
        }
    }
    
    private func setupiCloudMonitoring() {
        guard isSyncEnabled else { return }
        iCloudMonitor = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.loadFromiCloud()
        }
    }
    
    private func observeICloudToggle() {
        iCloudToggleObserver = NotificationCenter.default.addObserver(
            forName: .iCloudSyncSettingChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.isSyncEnabled {
                self.loadFromiCloudIfEnabled()
                self.setupiCloudMonitoring()
            } else {
                self.iCloudMonitor?.invalidate()
                self.iCloudMonitor = nil
            }
        }
    }
    
    /// Mark a step as incomplete
    func uncompleteStep(stepId: UUID, in assignmentId: UUID) {
        guard var plan = plans[assignmentId] else { return }
        
        if let stepIndex = plan.steps.firstIndex(where: { $0.id == stepId }) {
            var step = plan.steps[stepIndex]
            step.isCompleted = false
            step.completedAt = nil
            plan.steps[stepIndex] = step
            
            if plan.status == .completed {
                plan.status = .active
            }
            
            plans[assignmentId] = plan
            save()
        }
    }
    
    /// Delete a plan
    func deletePlan(for assignmentId: UUID) {
        plans.removeValue(forKey: assignmentId)
        save()
    }
    
    /// Archive old plans when assignments are deleted
    func archivePlans(for assignmentIds: [UUID]) {
        for id in assignmentIds {
            if var plan = plans[id] {
                plan.status = .archived
                plans[id] = plan
            }
        }
        save()
    }
    
    // MARK: - Refresh Triggers
    
    /// Regenerate plans after an event is added that affects availability
    func refreshPlansAfterEventAdd(assignments: [Assignment]) {
        generatePlans(for: assignments, force: true)
        lastRefreshDate = Date()
    }
    
    // MARK: - Persistence
    
    private func save() {
        do {
            let payload = PlansPayload(plans: Array(plans.values))
            let data = try JSONEncoder().encode(payload)
            try data.write(to: storageURL, options: [.atomic])
            if isSyncEnabled {
                saveToiCloud()
            }
        } catch {
            DebugLogger.log("Failed to save assignment plans: \(error)")
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: storageURL)
            let payload = try JSONDecoder().decode(PlansPayload.self, from: data)
            
            self.plans = Dictionary(uniqueKeysWithValues: payload.plans.map { ($0.assignmentId, $0) })
        } catch {
            DebugLogger.log("Failed to load assignment plans: \(error)")
        }
    }
    
    private struct PlansPayload: Codable {
        var plans: [AssignmentPlan]
    }
}
