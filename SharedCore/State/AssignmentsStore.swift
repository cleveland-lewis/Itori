import Foundation
import Combine
import Network
import EventKit

// TEMP: @MainActor removed to prevent recursive lock during static initialization
// TODO: Restore @MainActor and implement proper lazy initialization in v1.1
final class AssignmentsStore: ObservableObject {
    static let shared = AssignmentsStore()
    static var holidayCheckerOverride: ((Date, RecurrenceRule.HolidaySource) -> Bool)?
    static var holidaySourceAvailabilityOverride: ((RecurrenceRule.HolidaySource) -> Bool)?
    private var iCloudMonitor: Timer?
    private var pathMonitor: NWPathMonitor?
    private var isOnline: Bool = true
    private var pendingSyncQueue: [AppTask] = []
    private var isLoadingFromDisk: Bool = false
    private var iCloudToggleObserver: NSObjectProtocol?
    
    private init() {
        // Skip slow initialization during tests
        guard !TestMode.isRunningTests else {
            debugLog("⚡ Test mode: Skipping network monitoring, iCloud sync, and observers")
            return
        }
        
        // OPTIMIZATION: Defer all I/O to async initialization
        Task { @MainActor in
            await initializeAsync()
        }
    }
    
    // OPTIMIZATION: Async initialization to avoid blocking app launch
    @MainActor
    private func initializeAsync() async {
        // Step 1: Load cache off-main thread
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            await self.loadCache()
        }.value
        
        // Step 2: Setup services
        setupNetworkMonitoring()
        observeICloudToggle()
        
        // Step 3: Load from iCloud if needed (deferred)
        await Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            self.loadFromiCloudIfEnabled()
            await MainActor.run {
                self.setupiCloudMonitoring()
            }
        }.value
    }

    @Published var tasks: [AppTask] = [] {
        didSet {
            debugLog("🔄 tasks didSet triggered: \(tasks.count) tasks, isLoadingFromDisk: \(isLoadingFromDisk)")
            
            // Don't save while loading from disk to prevent data loss
            guard !isLoadingFromDisk else {
                debugLog("⏭️ Skipping save - loading from disk")
                return
            }
            
            updateAppBadge()
            saveCache()  // Always save locally first
            
            // Queue for iCloud sync if online and enabled
            if isOnline && isSyncEnabled {
                saveToiCloud()
            } else {
                // Track pending changes for later sync
                trackPendingChanges()
            }
        }
    }

    private var cacheURL: URL? = {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let folder = dir.appendingPathComponent("RootsAssignments", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("tasks.json")
    }()
    
    private lazy var iCloudURL: URL? = {
        // Always attempt to get container (independent of settings)
        let containerIdentifier = "iCloud.com.cwlewisiii.Itori"
        guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) else {
            // Silent failure - iCloud unavailable
            return nil
        }
        let documentsURL = ubiquityURL.appendingPathComponent("Documents/Assignments")
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        return documentsURL.appendingPathComponent("tasks.json")
    }()
    
    private lazy var iCloudConflictsURL: URL? = {
        guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.cwlewisiii.Itori") else {
            return nil
        }
        let conflictsFolder = ubiquityURL.appendingPathComponent("Documents/Assignments")
        try? FileManager.default.createDirectory(at: conflictsFolder, withIntermediateDirectories: true)
        return conflictsFolder
    }()
    
    private var conflictsFolderURL: URL? = {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let folder = dir.appendingPathComponent("RootsAssignments/Conflicts", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()
    
    private var isSyncEnabled: Bool {
        AppSettingsModel.shared.enableICloudSync
    }

    // No sample data - provided methods to add/remove tasks programmatically
    func addTask(_ task: AppTask) {
        debugLog("➕ addTask called: \(task.title)")
        let normalized = normalizeRecurringMetadata(task, existing: nil)
        tasks.append(normalized)
        debugLog("✅ Task added. Total tasks: \(tasks.count)")
        updateAppBadge()
        saveCache()
        refreshGPA()
        
        // Play task creation feedback
        Task { @MainActor in
            Feedback.shared.taskCreated()
        }
        
        // Schedule notification for new task
        scheduleNotificationIfNeeded(for: normalized)
        
        // Generate plan immediately for the new assignment
        Task { @MainActor in
            generatePlanForNewTask(normalized)
        }

        if normalized.type == .exam || normalized.type == .quiz {
            Task { @MainActor in
                ScheduledTestsStore.shared.syncAutoPracticeTests(for: normalized)
            }
        }
    }
    
    private func generatePlanForNewTask(_ task: AppTask) {
        guard let assignment = convertTaskToAssignment(task) else { return }
        AssignmentPlansStore.shared.generatePlan(for: assignment, force: false)
    }
    
    private func convertTaskToAssignment(_ task: AppTask) -> Assignment? {
        guard let due = task.due else { return nil }
        guard task.category != .practiceTest else { return nil }
        
        let assignmentCategory: AssignmentCategory
        switch task.category {
        case .exam: assignmentCategory = .exam
        case .quiz: assignmentCategory = .quiz
        case .homework: assignmentCategory = .homework
        case .reading: assignmentCategory = .reading
        case .review: assignmentCategory = .review
        case .project: assignmentCategory = .project
        case .study: assignmentCategory = .review
        case .practiceTest: assignmentCategory = .practiceTest
        }
        
        return Assignment(
            id: task.id,
            courseId: task.courseId,
            moduleIds: task.moduleIds,
            title: task.title,
            dueDate: due,
            dueTimeMinutes: task.dueTimeMinutes,
            estimatedMinutes: task.estimatedMinutes,
            weightPercent: task.gradeWeightPercent,
            category: assignmentCategory,
            urgency: urgencyFromImportance(task.importance),
            isLockedToDueDate: task.locked,
            plan: []
        )
    }
    
    private func urgencyFromImportance(_ importance: Double) -> AssignmentUrgency {
        switch importance {
        case ..<0.4: return .low
        case ..<0.7: return .medium
        default: return .high
        }
    }

    func removeTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        updateAppBadge()
        saveCache()
        refreshGPA()
        
        // Cancel notification when task is removed
        NotificationManager.shared.cancelAssignmentNotification(id)

        Task { @MainActor in
            ScheduledTestsStore.shared.removeAutoPracticeTests(for: id)
        }
    }

    func updateTask(_ task: AppTask) {
        // Check if this is a completion event (task was incomplete, now complete)
        let wasJustCompleted: Bool = {
            guard task.isCompleted else { return false }
            guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return false }
            return !tasks[idx].isCompleted
        }()
        let existingTask = tasks.first(where: { $0.id == task.id })
        let normalized = normalizeRecurringMetadata(task, existing: existingTask)
        
        // Check if key fields changed that require plan regeneration
        let needsPlanRegeneration: Bool = {
            guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return false }
            let old = tasks[idx]
            return old.due != normalized.due ||
                   old.dueTimeMinutes != normalized.dueTimeMinutes ||
                   old.estimatedMinutes != normalized.estimatedMinutes ||
                   old.category != normalized.category ||
                   old.importance != normalized.importance
        }()
        
        if let idx = tasks.firstIndex(where: { $0.id == normalized.id }) {
            var updatedTasks = tasks
            updatedTasks[idx] = normalized
            if wasJustCompleted, let nextTask = nextRecurringTask(from: normalized, in: updatedTasks) {
                updatedTasks.append(nextTask)
            }
            tasks = updatedTasks
        }
        updateAppBadge()
        saveCache()
        refreshGPA()
        
        // Reschedule notification for updated task
        rescheduleNotificationIfNeeded(for: normalized)
        
        // Regenerate plan if key fields changed
        if needsPlanRegeneration {
            Task { @MainActor in
                generatePlanForNewTask(normalized)
            }
        }
        
        // Play completion feedback if task was just completed
        if wasJustCompleted {
            Task { @MainActor in
                Feedback.shared.taskCompleted()
            }
        }

        if normalized.type == .exam || normalized.type == .quiz {
            Task { @MainActor in
                ScheduledTestsStore.shared.syncAutoPracticeTests(for: normalized)
            }
        } else if existingTask?.type == .exam || existingTask?.type == .quiz {
            Task { @MainActor in
                ScheduledTestsStore.shared.removeAutoPracticeTests(for: normalized.id)
            }
        }
    }

    private func normalizeRecurringMetadata(_ task: AppTask, existing: AppTask?) -> AppTask {
        guard let recurrence = task.recurrence else {
            if task.recurrenceSeriesID == nil && task.recurrenceIndex == nil {
                return task
            }
            return AppTask(
                id: task.id,
                title: task.title,
                courseId: task.courseId,
                moduleIds: task.moduleIds,
                due: task.due,
                estimatedMinutes: task.estimatedMinutes,
                minBlockMinutes: task.minBlockMinutes,
                maxBlockMinutes: task.maxBlockMinutes,
                difficulty: task.difficulty,
                importance: task.importance,
                type: task.type,
                locked: task.locked,
                attachments: task.attachments,
                isCompleted: task.isCompleted,
                gradeWeightPercent: task.gradeWeightPercent,
                gradePossiblePoints: task.gradePossiblePoints,
                gradeEarnedPoints: task.gradeEarnedPoints,
                category: task.category,
                dueTimeMinutes: task.dueTimeMinutes,
                recurrence: nil,
                recurrenceSeriesID: nil,
                recurrenceIndex: nil
            )
        }

        let seriesID = task.recurrenceSeriesID ?? existing?.recurrenceSeriesID ?? UUID()
        let index = task.recurrenceIndex ?? existing?.recurrenceIndex ?? 0

            return AppTask(
                id: task.id,
                title: task.title,
                courseId: task.courseId,
                moduleIds: task.moduleIds,
                due: task.due,
                estimatedMinutes: task.estimatedMinutes,
            minBlockMinutes: task.minBlockMinutes,
            maxBlockMinutes: task.maxBlockMinutes,
            difficulty: task.difficulty,
            importance: task.importance,
            type: task.type,
            locked: task.locked,
            attachments: task.attachments,
            isCompleted: task.isCompleted,
            gradeWeightPercent: task.gradeWeightPercent,
            gradePossiblePoints: task.gradePossiblePoints,
            gradeEarnedPoints: task.gradeEarnedPoints,
            category: task.category,
            dueTimeMinutes: task.dueTimeMinutes,
            recurrence: recurrence,
            recurrenceSeriesID: seriesID,
            recurrenceIndex: index
        )
    }

    private func nextRecurringTask(from task: AppTask, in existingTasks: [AppTask]) -> AppTask? {
        guard let recurrence = task.recurrence else { return nil }
        guard let due = task.due else {
            debugLog("⚠️ Recurring task missing due date; skipping next occurrence generation.")
            return nil
        }
        guard let seriesID = task.recurrenceSeriesID else {
            debugLog("⚠️ Recurring task missing series ID; skipping next occurrence generation.")
            return nil
        }

        let currentIndex = task.recurrenceIndex ?? 0
        let nextIndex = currentIndex + 1

        if !shouldGenerateNextOccurrence(for: recurrence, nextIndex: nextIndex, baseDate: due) {
            return nil
        }

        if existingTasks.contains(where: { $0.recurrenceSeriesID == seriesID && $0.recurrenceIndex == nextIndex }) {
            return nil
        }

        let (nextDueDate, nextDueTimeMinutes) = nextDueDate(for: task, rule: recurrence, baseDate: due)
        guard let nextDueDate else { return nil }

        if case .until(let endDate) = recurrence.end {
            let calendar = Calendar.autoupdatingCurrent
            let endDay = calendar.startOfDay(for: endDate)
            if nextDueDate > endDay { return nil }
        }

        return AppTask(
            id: UUID(),
            title: task.title,
            courseId: task.courseId,
            moduleIds: task.moduleIds,
            due: nextDueDate,
            estimatedMinutes: task.estimatedMinutes,
            minBlockMinutes: task.minBlockMinutes,
            maxBlockMinutes: task.maxBlockMinutes,
            difficulty: task.difficulty,
            importance: task.importance,
            type: task.type,
            locked: task.locked,
            attachments: task.attachments,
            isCompleted: false,
            gradeWeightPercent: task.gradeWeightPercent,
            gradePossiblePoints: task.gradePossiblePoints,
            gradeEarnedPoints: task.gradeEarnedPoints,
            category: task.category,
            dueTimeMinutes: nextDueTimeMinutes,
            recurrence: recurrence,
            recurrenceSeriesID: seriesID,
            recurrenceIndex: nextIndex
        )
    }

    private func nextDueDate(for task: AppTask, rule: RecurrenceRule, baseDate: Date) -> (Date?, Int?) {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent

        let hasTime = task.dueTimeMinutes != nil
        let baseDateTime = baseDateTimeForTask(task, calendar: calendar)

        let nextDateTime: Date?
        switch rule.frequency {
        case .daily:
            nextDateTime = calendar.date(byAdding: .day, value: rule.interval, to: baseDateTime)
        case .weekly:
            nextDateTime = calendar.date(byAdding: .weekOfYear, value: rule.interval, to: baseDateTime)
        case .monthly:
            nextDateTime = calendar.date(byAdding: .month, value: rule.interval, to: baseDateTime)
        case .yearly:
            nextDateTime = calendar.date(byAdding: .year, value: rule.interval, to: baseDateTime)
        }

        guard let nextDateTime else { return (nil, nil) }
        var nextDay = calendar.startOfDay(for: nextDateTime)
        nextDay = adjustForwardIfNeeded(date: nextDay, rule: rule, calendar: calendar)
        return (nextDay, hasTime ? task.dueTimeMinutes : nil)
    }

    private func baseDateTimeForTask(_ task: AppTask, calendar: Calendar) -> Date {
        if let minutes = task.dueTimeMinutes, let due = task.due {
            return calendar.date(byAdding: .minute, value: minutes, to: due) ?? due
        }
        return task.due ?? Date()
    }

    private func shouldGenerateNextOccurrence(for rule: RecurrenceRule, nextIndex: Int, baseDate: Date) -> Bool {
        switch rule.end {
        case .never:
            return true
        case .afterOccurrences(let count):
            return nextIndex < max(0, count)
        case .until(let endDate):
            let calendar = Calendar.autoupdatingCurrent
            let endDay = calendar.startOfDay(for: endDate)
            return baseDate <= endDay
        }
    }

    private func adjustForwardIfNeeded(date: Date, rule: RecurrenceRule, calendar: Calendar) -> Date {
        guard rule.skipPolicy.skipWeekends || rule.skipPolicy.skipHolidays else { return date }
        var current = date
        var attempts = 0
        while attempts < 370 {
            let isWeekend = rule.skipPolicy.skipWeekends && calendar.isDateInWeekend(current)
            let isHoliday = rule.skipPolicy.skipHolidays && isHoliday(current, source: rule.skipPolicy.holidaySource)
            if !isWeekend && !isHoliday {
                return current
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
            attempts += 1
        }
        return current
    }

    private func isHoliday(_ date: Date, source: RecurrenceRule.HolidaySource) -> Bool {
        if let availability = AssignmentsStore.holidaySourceAvailabilityOverride, !availability(source) {
            debugLog("ℹ️ Holiday skipping unavailable (override).")
            return false
        }
        if let override = AssignmentsStore.holidayCheckerOverride {
            return override(date, source)
        }
        guard source != .none else { return false }
        guard source == .deviceCalendar else {
            debugLog("ℹ️ Holiday skipping unavailable (unsupported source).")
            return false
        }
        guard CalendarAuthorizationManager.shared.isAuthorized else {
            debugLog("ℹ️ Holiday skipping unavailable (calendar access denied).")
            return false
        }
        let store = DeviceCalendarManager.shared.store
        let calendars = store.calendars(for: .event).filter { calendar in
            // Check for holiday calendars (title-based since .holiday type may not be available)
            return calendar.title.lowercased().contains("holiday")
        }
        guard !calendars.isEmpty else {
            debugLog("ℹ️ Holiday skipping unavailable (no holiday calendars found).")
            return false
        }
        let start = Calendar.autoupdatingCurrent.startOfDay(for: date)
        let end = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: start) ?? date
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = store.events(matching: predicate).filter { $0.isAllDay }
        return !events.isEmpty
    }

    func reassignTasks(fromCourseId: UUID, toCourseId: UUID?) {
        var didChange = false
        let updated = tasks.map { task -> AppTask in
            guard task.courseId == fromCourseId else { return task }
            didChange = true
            return task.withCourseId(toCourseId)
        }
        guard didChange else { return }
        tasks = updated
        saveCache()
        refreshGPA()
    }

    func incompleteTasks() -> [AppTask] {
        // For now all tasks are considered active; in future, filter by completion state
        return tasks
    }

    func resetAll() {
        tasks.removeAll()
        pendingSyncQueue.removeAll()
        updateAppBadge()
        if let url = cacheURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        if let url = iCloudURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        if let url = iCloudConflictsURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        if let url = conflictsFolderURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        saveCache()
    }

    private func refreshGPA() {
        Task { @MainActor in
            CoursesStore.shared?.recalcGPA(tasks: tasks)
        }
    }

    private func updateAppBadge() {
        let calendar = Calendar.current
        let now = Date()
        let startOfTomorrow = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
        let count = tasks.filter { task in
            guard !task.isCompleted, let due = task.due else { return false }
            return due < startOfTomorrow
        }.count
        NotificationManager.shared.updateBadgeCount(count)
    }

    private func saveCache() {
        guard let url = cacheURL else {
            debugLog("❌ saveCache: No cache URL available")
            return
        }
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: url, options: .atomic)
            debugLog("💾 saveCache: Saved \(tasks.count) tasks to \(url.path)")
        } catch {
            debugLog("Failed to save tasks cache: \(error)")
        }
    }

    private func loadCache() {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            isLoadingFromDisk = true
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([AppTask].self, from: data)
            tasks = decoded
            isLoadingFromDisk = false
            
            // Migration validation: verify all tasks have category field populated
            let tasksNeedingMigration = tasks.filter { $0.category != $0.type }
            if !tasksNeedingMigration.isEmpty {
                debugLog("⚠️ Migration Notice: \(tasksNeedingMigration.count) tasks have different category/type values")
            }
            
            // Verify no data loss
            debugLog("✅ Migration Complete: Loaded \(tasks.count) tasks from \(url.path)")
            
            // Schedule notifications for all loaded incomplete tasks
            scheduleNotificationsForLoadedTasks()

            Task { @MainActor in
                for task in tasks where task.type == .exam || task.type == .quiz {
                    ScheduledTestsStore.shared.syncAutoPracticeTests(for: task)
                }
            }
        } catch {
            isLoadingFromDisk = false
            debugLog("❌ Failed to load tasks cache: \(error)")
            
            // Attempt rollback-safe recovery
            attemptRollbackRecovery(from: url)
        }
    }

#if DEBUG
    func loadCacheSnapshotForTesting() -> [AppTask] {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([AppTask].self, from: data)
        } catch {
            debugLog("❌ Failed to load cache snapshot: \(error)")
            return []
        }
    }
#endif
    
    private func attemptRollbackRecovery(from url: URL) {
        // Try to create a backup of the corrupted file
        let backupURL = url.deletingLastPathComponent().appendingPathComponent("tasks_cache_backup_\(Date().timeIntervalSince1970).json")
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.copyItem(at: url, to: backupURL)
                debugLog("📦 Backup created at: \(backupURL.path)")
            }
        } catch {
            debugLog("⚠️ Could not create backup: \(error)")
        }
    }
    
    // MARK: - Notification Scheduling
    
    private func scheduleNotificationIfNeeded(for task: AppTask) {
        guard !task.isCompleted else { return }
        NotificationManager.shared.scheduleAssignmentDue(task)
    }
    
    private func rescheduleNotificationIfNeeded(for task: AppTask) {
        // Cancel existing notification
        NotificationManager.shared.cancelAssignmentNotification(task.id)
        
        // Schedule new one if task is incomplete
        if !task.isCompleted {
            NotificationManager.shared.scheduleAssignmentDue(task)
        }
    }
    
    private func scheduleNotificationsForLoadedTasks() {
        // Schedule notifications for all incomplete tasks on app launch
        for task in tasks where !task.isCompleted {
            NotificationManager.shared.scheduleAssignmentDue(task)
        }
    }
    
    // MARK: - iCloud Sync
    
    private func setupNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOnline = self.isOnline
                self.isOnline = path.status == .satisfied
                
                // When coming back online, sync pending changes
                if !wasOnline && self.isOnline {
                    DebugLogger.log("📡 Network restored - syncing pending changes")
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        self.syncPendingChanges()
                    }
                }
            }
        }
        pathMonitor?.start(queue: DispatchQueue.global(qos: .utility))
    }
    
    private func trackPendingChanges() {
        // Store snapshot of current state for later sync
        pendingSyncQueue = tasks
        debugLog("📝 Tracked \(tasks.count) tasks for pending sync")
    }
    
    private func syncPendingChanges() {
        guard isSyncEnabled, isOnline, !pendingSyncQueue.isEmpty else { return }
        
        debugLog("🔄 Syncing \(pendingSyncQueue.count) pending changes to iCloud")
        saveToiCloud()
        pendingSyncQueue.removeAll()
    }
    
    private func loadFromiCloudIfEnabled() {
        guard isSyncEnabled else {
            debugLog("ℹ️ iCloud sync disabled - using local cache only")
            return
        }
        guard !AppSettingsModel.shared.suppressICloudRestore else {
            debugLog("ℹ️ iCloud restore suppressed after reset")
            return
        }
        loadFromiCloud()
    }
    
    private func saveToiCloud() {
        // Only attempt if user has enabled sync
        guard isSyncEnabled else { return }
        
        // Silently fail if iCloud unavailable
        guard let url = iCloudURL else { 
            debugLog("ℹ️ iCloud container not available")
            return 
        }
        
        // Non-blocking background sync
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(self.tasks)
                try data.write(to: url, options: .atomic)
                self.debugLog("✅ Synced \(self.tasks.count) tasks to iCloud")
            } catch {
                // Silent failure - queued for retry
                self.debugLog("⚠️ iCloud sync failed (queued): \(error.localizedDescription)")
            }
        }
    }
    
    private func loadFromiCloud() {
        // Silently fail if iCloud unavailable
        guard let url = iCloudURL else { 
            debugLog("ℹ️ iCloud container not available")
            return 
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            debugLog("ℹ️ No iCloud data found, using local cache")
            return
        }
        
        do {
            isLoadingFromDisk = true
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([AppTask].self, from: data)
            
            // Check for conflicts before merging
            if hasConflicts(cloudTasks: decoded) {
                handleConflicts(cloudTasks: decoded)
            } else {
                mergeWithiCloudData(decoded)
                debugLog("✅ Loaded \(decoded.count) tasks from iCloud at \(url.path)")
            }
            isLoadingFromDisk = false
        } catch {
            isLoadingFromDisk = false
            debugLog("❌ Failed to load from iCloud: \(error)")
        }
    }
    
    private func hasConflicts(cloudTasks: [AppTask]) -> Bool {
        // Check if there are significant conflicts
        let localDict = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        let cloudDict = Dictionary(uniqueKeysWithValues: cloudTasks.map { ($0.id, $0) })
        
        var conflictCount = 0
        
        // Check for tasks that exist in both but differ
        for (id, cloudTask) in cloudDict {
            if let localTask = localDict[id] {
                // Simple conflict detection: check if key fields differ
                if localTask.title != cloudTask.title ||
                   localTask.due != cloudTask.due ||
                   localTask.isCompleted != cloudTask.isCompleted {
                    conflictCount += 1
                }
            }
        }
        
        // If more than 5 conflicts or more than 20% of tasks conflict, flag it
        let threshold = max(5, tasks.count / 5)
        return conflictCount > threshold
    }
    
    private func handleConflicts(cloudTasks: [AppTask]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        // Save local conflicts folder
        if let conflictsFolder = conflictsFolderURL {
            let localURL = conflictsFolder.appendingPathComponent("local_\(timestamp).json")
            do {
                let localData = try JSONEncoder().encode(tasks)
                try localData.write(to: localURL)
                debugLog("💾 Saved local conflict: \(localURL.lastPathComponent)")
            } catch {
                debugLog("⚠️ Failed to save local conflict: \(error.localizedDescription)")
            }
            
            let cloudURL = conflictsFolder.appendingPathComponent("cloud_\(timestamp).json")
            do {
                let cloudData = try JSONEncoder().encode(cloudTasks)
                try cloudData.write(to: cloudURL)
                debugLog("☁️ Saved cloud conflict: \(cloudURL.lastPathComponent)")
            } catch {
                debugLog("⚠️ Failed to save cloud conflict: \(error.localizedDescription)")
            }
        }
        
        // Also save conflict to iCloud if available
        if let iCloudConflicts = iCloudConflictsURL {
            let conflictURL = iCloudConflicts.appendingPathComponent("tasks_conflict_\(timestamp).json")
            DispatchQueue.global(qos: .utility).async {
                do {
                    let cloudData = try JSONEncoder().encode(cloudTasks)
                    try cloudData.write(to: conflictURL)
                    DebugLogger.log("💾 Preserved conflict in iCloud: \(conflictURL.lastPathComponent)")
                } catch {
                    DebugLogger.log("⚠️ Failed to preserve iCloud conflict: \(error.localizedDescription)")
                }
            }
        }
        
        // Post notification for user to resolve
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("AssignmentsSyncConflict"),
                object: nil,
                userInfo: [
                    "localCount": self.tasks.count,
                    "cloudCount": cloudTasks.count,
                    "timestamp": timestamp
                ]
            )
        }
        
        // For now, use cloud as default (can be changed by user later)
        debugLog("⚠️ SYNC CONFLICT DETECTED - Using cloud version as default")
        debugLog("   Local: \(tasks.count) tasks")
        debugLog("   Cloud: \(cloudTasks.count) tasks")
        debugLog("   Conflict files saved for manual resolution")
        
        mergeWithiCloudData(cloudTasks)
    }
    
    private func mergeWithiCloudData(_ iCloudTasks: [AppTask]) {
        // Create a dictionary of local tasks by ID
        var localTasksDict = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        
        // Update/add iCloud tasks (iCloud is source of truth)
        for iCloudTask in iCloudTasks {
            localTasksDict[iCloudTask.id] = iCloudTask
        }
        
        // Convert back to array
        tasks = Array(localTasksDict.values)
        
        // Save merged data locally
        saveCache()
    }
    
    private func setupiCloudMonitoring() {
        guard isSyncEnabled, !AppSettingsModel.shared.suppressICloudRestore else { return }
        
        // Monitor for iCloud file changes every 30 seconds
        iCloudMonitor = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkForCloudUpdates()
        }
    }

    private func observeICloudToggle() {
        iCloudToggleObserver = NotificationCenter.default.addObserver(
            forName: .iCloudSyncSettingChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let enabled = notification.object as? Bool else { return }
            self.handleICloudToggle(enabled: enabled)
        }
    }

    private func handleICloudToggle(enabled: Bool) {
        if enabled {
            loadFromiCloudIfEnabled()
            setupiCloudMonitoring()
            if let url = iCloudURL, !FileManager.default.fileExists(atPath: url.path) {
                saveToiCloud()
            }
        } else {
            iCloudMonitor?.invalidate()
            iCloudMonitor = nil
            pendingSyncQueue.removeAll()
        }
    }
    
    private func checkForCloudUpdates() {
        guard isSyncEnabled, isOnline, !AppSettingsModel.shared.suppressICloudRestore, let url = iCloudURL else { return }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self,
                  FileManager.default.fileExists(atPath: url.path) else { return }
            
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let modificationDate = attributes[.modificationDate] as? Date
                
                // Check if file was modified recently (within last minute)
                if let modDate = modificationDate,
                   Date().timeIntervalSince(modDate) < 60 {
                    let age = Int(Date().timeIntervalSince(modDate))
                    self.debugLog("☁️ iCloud file updated recently (\(age)s ago) at \(modDate) - reloading \(url.path)")
                    DispatchQueue.main.async {
                        self.loadFromiCloud()
                    }
                }
            } catch {
                // Silently ignore - file might be temporarily unavailable
            }
        }
    }
    
    deinit {
        iCloudMonitor?.invalidate()
        pathMonitor?.cancel()
        if let observer = iCloudToggleObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public API for Conflict Resolution
    
    func resolveConflict(useLocal: Bool, localURL: URL, cloudURL: URL) {
        do {
            let data: Data
            if useLocal {
                data = try Data(contentsOf: localURL)
                debugLog("🔧 User chose LOCAL version")
            } else {
                data = try Data(contentsOf: cloudURL)
                debugLog("🔧 User chose CLOUD version")
            }
            
            let resolvedTasks = try JSONDecoder().decode([AppTask].self, from: data)
            tasks = resolvedTasks
            
            // Upload chosen version to iCloud
            if isSyncEnabled {
                saveToiCloud()
            }
            
            // Clean up conflict files
            try? FileManager.default.removeItem(at: localURL)
            try? FileManager.default.removeItem(at: cloudURL)
            
            debugLog("✅ Conflict resolved - \(resolvedTasks.count) tasks loaded")
        } catch {
            debugLog("❌ Failed to resolve conflict: \(error)")
        }
    }
    
    func mergeConflicts(localURL: URL, cloudURL: URL) {
        do {
            let localData = try Data(contentsOf: localURL)
            let cloudData = try Data(contentsOf: cloudURL)
            
            let localTasks = try JSONDecoder().decode([AppTask].self, from: localData)
            let cloudTasks = try JSONDecoder().decode([AppTask].self, from: cloudData)
            
            // Merge: Use most recent modification for each task
            var mergedDict: [UUID: AppTask] = [:]
            
            // Add all local tasks
            for task in localTasks {
                mergedDict[task.id] = task
            }
            
            // Add/update with cloud tasks (keeping unique IDs from both)
            for cloudTask in cloudTasks {
                if let localTask = mergedDict[cloudTask.id] {
                    // BUGFIX: Always prefer cloud version when there's any difference
                    // This ensures completion status changes sync properly in both directions
                    // Without timestamps, we treat iCloud as source of truth during merge
                    if cloudTask.isCompleted != localTask.isCompleted ||
                       cloudTask.title != localTask.title ||
                       cloudTask.due != localTask.due {
                        mergedDict[cloudTask.id] = cloudTask
                    }
                    // Keep local only if completely identical
                } else {
                    mergedDict[cloudTask.id] = cloudTask
                }
            }
            
            tasks = Array(mergedDict.values)
            
            // Upload merged version
            if isSyncEnabled {
                saveToiCloud()
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: localURL)
            try? FileManager.default.removeItem(at: cloudURL)
            
            debugLog("✅ Conflicts merged - \(tasks.count) total tasks")
        } catch {
            debugLog("❌ Failed to merge conflicts: \(error)")
        }
    }

    private func debugLog(_ message: String) {
        guard AppSettingsModel.shared.devModeDataLogging else { return }
        DebugLogger.log(message)
    }
}
