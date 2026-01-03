import Foundation
import Combine

// MARK: - Intelligent Scheduling Coordinator

/// Unified coordinator that integrates grade monitoring and auto-rescheduling
@MainActor
final class IntelligentSchedulingCoordinator: ObservableObject {
    static let shared = IntelligentSchedulingCoordinator()
    
    // MARK: - Published Properties
    
    @Published private(set) var isActive: Bool = false
    @Published private(set) var allNotifications: [SchedulingNotification] = []
    
    // MARK: - Notification Model
    
    enum SchedulingNotification: Identifiable {
        case studyTime(StudyTimeRecommendation)
        case reschedule(EnhancedAutoRescheduleService.RescheduleNotification)
        
        var id: UUID {
            switch self {
            case .studyTime(let rec): return rec.id
            case .reschedule(let not): return not.id
            }
        }
        
        var timestamp: Date {
            switch self {
            case .studyTime(let rec): return rec.timestamp
            case .reschedule(let not): return not.timestamp
            }
        }
    }
    
    // MARK: - Dependencies
    
    private let gradeMonitor = GradeMonitoringService.shared
    private let autoReschedule = EnhancedAutoRescheduleService.shared
    private let settings = AppSettingsModel.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
        LOG_UI(.info, "IntelligentScheduling", "Coordinator initialized")
    }
    
    // MARK: - Public API
    
    /// Start the intelligent scheduling system
    func start() {
        guard !isActive else {
            LOG_UI(.debug, "IntelligentScheduling", "Already active")
            return
        }
        
        isActive = true
        
        // Start grade monitoring
        gradeMonitor.startMonitoring()
        
        // Start auto-reschedule checking
        autoReschedule.startAutoCheck()
        
        LOG_UI(.info, "IntelligentScheduling", "Started intelligent scheduling system")
    }
    
    /// Stop the intelligent scheduling system
    func stop() {
        guard isActive else {
            LOG_UI(.debug, "IntelligentScheduling", "Already inactive")
            return
        }
        
        isActive = false
        
        // Stop grade monitoring
        gradeMonitor.stopMonitoring()
        
        // Stop auto-reschedule checking
        autoReschedule.stopAutoCheck()
        
        LOG_UI(.info, "IntelligentScheduling", "Stopped intelligent scheduling system")
    }
    
    /// Add a grade for monitoring
    func addGrade(courseId: UUID, score: Double, assignmentName: String? = nil) {
        gradeMonitor.addGrade(courseId: courseId, score: score, assignmentName: assignmentName)
    }
    
    /// Set weekly study hours for a course
    func setStudyHours(courseId: UUID, weeklyHours: Double) {
        gradeMonitor.setStudyHours(courseId: courseId, weeklyHours: weeklyHours)
    }
    
    /// Manually trigger overdue task check
    func checkOverdueTasks() async {
        await autoReschedule.checkAndRescheduleOverdueTasks()
    }
    
    /// Dismiss a notification
    func dismissNotification(_ notification: SchedulingNotification) {
        switch notification {
        case .studyTime(let rec):
            gradeMonitor.clearRecommendation(id: rec.id)
        case .reschedule(let not):
            autoReschedule.clearNotification(id: not.id)
        }
        
        updateAllNotifications()
    }
    
    /// Get study recommendation for a course
    func getStudyRecommendation(for courseId: UUID) -> StudyTimeRecommendation? {
        gradeMonitor.getStudyRecommendation(for: courseId)
    }
    
    // MARK: - Configuration
    
    /// Configure grade monitoring threshold
    func setGradeChangeThreshold(_ threshold: Double) {
        gradeMonitor.gradeChangeThreshold = threshold
    }
    
    /// Configure work hours for rescheduling
    func setWorkHours(start: Int, end: Int) {
        autoReschedule.workHoursStart = start
        autoReschedule.workHoursEnd = end
    }
    
    /// Configure auto-check interval
    func setCheckInterval(_ interval: TimeInterval) {
        autoReschedule.checkInterval = interval
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Observe study time recommendations
        gradeMonitor.$studyRecommendations
            .sink { [weak self] _ in
                self?.updateAllNotifications()
            }
            .store(in: &cancellables)
        
        // Observe reschedule notifications
        autoReschedule.$rescheduleNotifications
            .sink { [weak self] _ in
                self?.updateAllNotifications()
            }
            .store(in: &cancellables)
    }
    
    private func updateAllNotifications() {
        var notifications: [SchedulingNotification] = []
        
        // Add study time recommendations
        for recommendation in gradeMonitor.studyRecommendations {
            notifications.append(.studyTime(recommendation))
        }
        
        // Add reschedule notifications
        for reschedule in autoReschedule.rescheduleNotifications {
            notifications.append(.reschedule(reschedule))
        }
        
        // Sort by timestamp (newest first)
        allNotifications = notifications.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - App Settings Extension

extension AppSettingsModel {
    /// Enable or disable intelligent scheduling
    var enableIntelligentScheduling: Bool {
        get { UserDefaults.standard.bool(forKey: "enableIntelligentScheduling") }
        set {
            UserDefaults.standard.set(newValue, forKey: "enableIntelligentScheduling")
            
            if newValue {
                Task { @MainActor in
                    IntelligentSchedulingCoordinator.shared.start()
                }
            } else {
                Task { @MainActor in
                    IntelligentSchedulingCoordinator.shared.stop()
                }
            }
        }
    }
    
    /// Grade change threshold for triggering study time recommendations
    var gradeChangeThreshold: Double {
        get {
            let value = UserDefaults.standard.double(forKey: "gradeChangeThreshold")
            return value > 0 ? value : 5.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "gradeChangeThreshold")
            Task { @MainActor in
                IntelligentSchedulingCoordinator.shared.setGradeChangeThreshold(newValue)
            }
        }
    }
}
