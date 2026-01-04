import Foundation
import Combine

#if canImport(UserNotifications)
import UserNotifications
#endif

// MARK: - Enhanced Auto-Reschedule Service
// NOTE: This service is currently disabled pending API updates
// TODO: Update to use AssignmentsStore.tasks instead of .assignments

#if false // Temporarily disabled - needs API update

@MainActor
final class EnhancedAutoRescheduleService: ObservableObject {
    static let shared = EnhancedAutoRescheduleService()
    
    // MARK: - Published Properties
    
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var rescheduleNotifications: [RescheduleNotification] = []
    @Published private(set) var lastCheckTime: Date?
    
    // MARK: - Models
    
    struct RescheduleNotification: Identifiable, Codable {
        let id: UUID
        let assignmentId: UUID
        let assignmentTitle: String
        let courseName: String?
        let oldDueDate: Date
        let newDueDate: Date
        let priority: AssignmentUrgency
        let estimatedHours: Double
        let suggestedStartTime: Date
        let reason: String
        let timestamp: Date
    }
    
    // MARK: - Dependencies
    
    private let assignmentsStore = AssignmentsStore.shared
    private let plannerStore = PlannerStore.shared
    private let coursesStore = CoursesStore.shared
    private let settings = AppSettingsModel.shared
    private let notificationManager = NotificationManager.shared
    private let autoRescheduleEngine = AutoRescheduleEngine.shared
    
    // MARK: - Configuration
    
    var workHoursStart: Int = 8  // 8 AM
    var workHoursEnd: Int = 22   // 10 PM
    var checkInterval: TimeInterval = 3600 // Check every hour
    
    // MARK: - Timer
    
    private var checkTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        LOG_UI(.info, "EnhancedAutoReschedule", "Service initialized")
    }
    
    // MARK: - Public API
    
    /// Start automatic checking for overdue tasks
    func startAutoCheck() {
        stopAutoCheck()
        
        checkTimer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndRescheduleOverdueTasks()
            }
        }
        
        // Run initial check
        Task {
            await checkAndRescheduleOverdueTasks()
        }
        
        LOG_UI(.info, "EnhancedAutoReschedule", "Started auto-check with interval: \(checkInterval)s")
    }
    
    /// Stop automatic checking
    func stopAutoCheck() {
        checkTimer?.invalidate()
        checkTimer = nil
        LOG_UI(.info, "EnhancedAutoReschedule", "Stopped auto-check")
    }
    
    /// Manually trigger check for overdue tasks
    func checkAndRescheduleOverdueTasks() async {
        guard !isProcessing else {
            LOG_UI(.warn, "EnhancedAutoReschedule", "Already processing, skipping")
            return
        }
        
        guard settings.enableAutoReschedule else {
            LOG_UI(.debug, "EnhancedAutoReschedule", "Auto-reschedule disabled in settings")
            return
        }
        
        isProcessing = true
        lastCheckTime = Date()
        defer { isProcessing = false }
        
        LOG_UI(.info, "EnhancedAutoReschedule", "Checking for overdue tasks")
        
        let now = Date()
        let overdueTasks = findOverdueTasks(currentTime: now)
        
        guard !overdueTasks.isEmpty else {
            LOG_UI(.debug, "EnhancedAutoReschedule", "No overdue tasks found")
            return
        }
        
        LOG_UI(.info, "EnhancedAutoReschedule", "Found \(overdueTasks.count) overdue tasks")
        
        for task in overdueTasks {
            await rescheduleTask(task, currentTime: now)
        }
    }
    
    /// Clear a notification
    func clearNotification(id: UUID) {
        rescheduleNotifications.removeAll { $0.id == id }
    }
    
    // MARK: - Task Detection
    
    private func findOverdueTasks(currentTime: Date) -> [Assignment] {
        assignmentsStore.tasks.filter { assignment in
            guard assignment.status != .completed && assignment.status != .archived else {
                return false
            }
            
            let dueDateTime = dueDateWithTime(for: assignment)
            return dueDateTime < currentTime
        }
    }
    
    private func dueDateWithTime(for assignment: Assignment) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: assignment.dueDate)
        
        if let dueTimeMinutes = assignment.dueTimeMinutes {
            components.hour = dueTimeMinutes / 60
            components.minute = dueTimeMinutes % 60
        } else {
            components.hour = 23
            components.minute = 59
        }
        
        return Calendar.current.date(from: components) ?? assignment.dueDate
    }
    
    // MARK: - Rescheduling Logic
    
    private func rescheduleTask(_ assignment: Assignment, currentTime: Date) async {
        LOG_UI(.info, "EnhancedAutoReschedule", "Rescheduling task: \(assignment.title)")
        
        guard let newDueDate = findBestRescheduleSlot(
            for: assignment,
            currentTime: currentTime
        ) else {
            LOG_UI(.warn, "EnhancedAutoReschedule", "Could not find suitable slot for: \(assignment.title)")
            await sendNoSlotNotification(for: assignment)
            return
        }
        
        // Update assignment in store
        var updatedAssignment = assignment
        updatedAssignment.dueDate = newDueDate
        assignmentsStore.update(updatedAssignment)
        
        // Create notification
        let notification = createRescheduleNotification(
            assignment: assignment,
            newDueDate: newDueDate,
            currentTime: currentTime
        )
        
        rescheduleNotifications.append(notification)
        
        // Send user notification
        await sendRescheduleNotification(notification)
        
        LOG_UI(.info, "EnhancedAutoReschedule", "Rescheduled \(assignment.title) to \(newDueDate)")
    }
    
    private func findBestRescheduleSlot(
        for assignment: Assignment,
        currentTime: Date
    ) -> Date? {
        
        let estimatedHours = Double(assignment.estimatedMinutes) / 60.0
        let freeSlots = getFreeTimeSlots(
            startDate: currentTime,
            daysAhead: 14
        )
        
        // Filter slots that can accommodate the task
        let suitableSlots = freeSlots.filter { slot in
            let slotDuration = slot.end.timeIntervalSince(slot.start) / 3600.0
            return slotDuration >= estimatedHours
        }
        
        guard !suitableSlots.isEmpty else { return nil }
        
        // Prioritize based on urgency
        switch assignment.urgency {
        case .critical:
            // Schedule ASAP
            return suitableSlots.first?.start.addingTimeInterval(estimatedHours * 3600)
            
        case .high:
            // Schedule within next 3 days
            let threeDaysOut = currentTime.addingTimeInterval(3 * 24 * 3600)
            if let slot = suitableSlots.first(where: { $0.start < threeDaysOut }) {
                return slot.start.addingTimeInterval(estimatedHours * 3600)
            }
            return suitableSlots.first?.start.addingTimeInterval(estimatedHours * 3600)
            
        case .medium, .low:
            // Schedule at next convenient time
            return suitableSlots.first?.start.addingTimeInterval(estimatedHours * 3600)
        }
    }
    
    // MARK: - Free Time Calculation
    
    struct TimeSlot {
        let start: Date
        let end: Date
    }
    
    private func getFreeTimeSlots(
        startDate: Date,
        daysAhead: Int
    ) -> [TimeSlot] {
        var freeSlots: [TimeSlot] = []
        let calendar = Calendar.current
        
        for day in 0..<daysAhead {
            guard let currentDay = calendar.date(byAdding: .day, value: day, to: startDate) else {
                continue
            }
            
            var dayStartComponents = calendar.dateComponents([.year, .month, .day], from: currentDay)
            dayStartComponents.hour = workHoursStart
            dayStartComponents.minute = 0
            
            var dayEndComponents = calendar.dateComponents([.year, .month, .day], from: currentDay)
            dayEndComponents.hour = workHoursEnd
            dayEndComponents.minute = 0
            
            guard let dayStart = calendar.date(from: dayStartComponents),
                  let dayEnd = calendar.date(from: dayEndComponents) else {
                continue
            }
            
            // Get scheduled tasks for this day
            let dayTasks = getScheduledTasksForDay(currentDay)
            
            if dayTasks.isEmpty {
                // Entire work day is free
                freeSlots.append(TimeSlot(start: dayStart, end: dayEnd))
            } else {
                // Find gaps between tasks
                let sortedTasks = dayTasks.sorted { $0.dueDate < $1.dueDate }
                
                // Check time before first task
                if let firstTask = sortedTasks.first {
                    let firstTaskStart = dueDateWithTime(for: firstTask)
                    if firstTaskStart > dayStart {
                        freeSlots.append(TimeSlot(start: dayStart, end: firstTaskStart))
                    }
                }
                
                // Check gaps between consecutive tasks
                for i in 0..<(sortedTasks.count - 1) {
                    let currentEnd = dueDateWithTime(for: sortedTasks[i])
                    let nextStart = dueDateWithTime(for: sortedTasks[i + 1])
                    
                    if nextStart > currentEnd {
                        freeSlots.append(TimeSlot(start: currentEnd, end: nextStart))
                    }
                }
                
                // Check time after last task
                if let lastTask = sortedTasks.last {
                    let lastTaskEnd = dueDateWithTime(for: lastTask)
                    if lastTaskEnd < dayEnd {
                        freeSlots.append(TimeSlot(start: lastTaskEnd, end: dayEnd))
                    }
                }
            }
        }
        
        return freeSlots
    }
    
    private func getScheduledTasksForDay(_ date: Date) -> [Assignment] {
        let calendar = Calendar.current
        return assignmentsStore.tasks.filter { assignment in
            guard assignment.status != .completed && assignment.status != .archived else {
                return false
            }
            return calendar.isDate(assignment.dueDate, inSameDayAs: date)
        }
    }
    
    // MARK: - Notification Creation
    
    private func createRescheduleNotification(
        assignment: Assignment,
        newDueDate: Date,
        currentTime: Date
    ) -> RescheduleNotification {
        
        let course = coursesStore.courses.first { $0.id == assignment.courseId }
        let estimatedHours = Double(assignment.estimatedMinutes) / 60.0
        let suggestedStart = newDueDate.addingTimeInterval(-estimatedHours * 3600)
        
        return RescheduleNotification(
            id: UUID(),
            assignmentId: assignment.id,
            assignmentTitle: assignment.title,
            courseName: course?.name,
            oldDueDate: assignment.dueDate,
            newDueDate: newDueDate,
            priority: assignment.urgency,
            estimatedHours: estimatedHours,
            suggestedStartTime: suggestedStart,
            reason: "Task was past due date",
            timestamp: currentTime
        )
    }
    
    // MARK: - User Notifications
    
    private func sendRescheduleNotification(_ notification: RescheduleNotification) async {
        let content = UNMutableNotificationContent()
        content.title = "📅 Task Rescheduled"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var body = "'\(notification.assignmentTitle)'"
        if let courseName = notification.courseName {
            body += " (\(courseName))"
        }
        body += "\n\nOriginal deadline: \(dateFormatter.string(from: notification.oldDueDate))"
        body += "\nNew deadline: \(dateFormatter.string(from: notification.newDueDate))"
        body += "\nPriority: \(notification.priority.rawValue.capitalized)"
        body += "\nEstimated time: \(String(format: "%.1f", notification.estimatedHours)) hours"
        body += "\n\nSuggested start: \(dateFormatter.string(from: notification.suggestedStartTime))"
        
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "TASK_RESCHEDULE"
        
        let request = UNNotificationRequest(
            identifier: "reschedule-\(notification.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            LOG_NOTIFICATIONS(.info, "EnhancedAutoReschedule", "Sent reschedule notification for \(notification.assignmentTitle)")
        } catch {
            LOG_NOTIFICATIONS(.error, "EnhancedAutoReschedule", "Failed to send notification: \(error)")
        }
    }
    
    private func sendNoSlotNotification(for assignment: Assignment) async {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Unable to Reschedule"
        content.body = "Could not find a suitable time slot for '\(assignment.title)'. Please reschedule manually."
        content.sound = .default
        content.categoryIdentifier = "RESCHEDULE_FAILED"
        
        let request = UNNotificationRequest(
            identifier: "reschedule-failed-\(assignment.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            LOG_NOTIFICATIONS(.error, "EnhancedAutoReschedule", "Failed to send no-slot notification: \(error)")
        }
    }
}

#endif // Temporarily disabled

// MARK: - Stub Implementation (while service is disabled)

@MainActor
final class EnhancedAutoRescheduleService: ObservableObject {
    static let shared = EnhancedAutoRescheduleService()
    
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var rescheduleNotifications: [RescheduleNotification] = []
    @Published private(set) var lastCheckTime: Date?
    
    // Stub properties
    var checkInterval: TimeInterval = 300 // 5 minutes
    var workHoursStart: Int = 8
    var workHoursEnd: Int = 22
    
    struct RescheduleNotification: Identifiable, Codable {
        let id: UUID
        let assignmentId: UUID
        let assignmentTitle: String
        let courseName: String?
        let oldDueDate: Date
        let newDueDate: Date
        let priority: AssignmentUrgency
        let estimatedHours: Double
        let suggestedStartTime: Date
        let reason: String
        let timestamp: Date
    }
    
    private init() {}
    
    func startAutoCheck() {
        // Disabled - needs API update
    }
    
    func stopAutoCheck() {
        // Disabled - needs API update
    }
    
    func checkAndRescheduleOverdueTasks() async {
        // Disabled - needs API update
    }
    
    func clearNotification(id: UUID) {
        // Disabled - needs API update
    }
    
    func checkForRescheduling(assignmentsStore: AssignmentsStore, coursesStore: CoursesStore?) async {
        // Disabled - needs API update
    }
    
    func acceptReschedule(_ notification: RescheduleNotification, assignmentsStore: AssignmentsStore) {
        // Disabled - needs API update
    }
    
    func dismissNotification(_ id: UUID) {
        // Disabled - needs API update
    }
    
    func clearAllNotifications() {
        // Disabled - needs API update
    }
}
