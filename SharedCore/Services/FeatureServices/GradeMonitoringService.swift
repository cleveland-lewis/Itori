import Foundation
import Combine
#if canImport(UserNotifications)
import UserNotifications
#endif

// MARK: - Grade Trend Models

enum GradeTrend: String, Codable {
    case improving
    case declining
    case stable
}

struct GradeAnalysis: Codable {
    let courseId: UUID
    let trend: GradeTrend
    let change: Double
    let recentAverage: Double
    let previousAverage: Double
    let requiresAction: Bool
    let timestamp: Date
}

struct StudyTimeRecommendation: Codable, Identifiable {
    let id: UUID
    let courseId: UUID
    let courseName: String
    let currentWeeklyHours: Double
    let suggestedWeeklyHours: Double
    let additionalHours: Double
    let reason: String
    let trend: GradeTrend
    let timestamp: Date
}

// MARK: - Grade Monitoring Service

@MainActor
final class GradeMonitoringService: ObservableObject {
    static let shared = GradeMonitoringService()
    
    // MARK: - Published Properties
    
    @Published private(set) var recentAnalyses: [GradeAnalysis] = []
    @Published private(set) var studyRecommendations: [StudyTimeRecommendation] = []
    @Published private(set) var isMonitoring: Bool = false
    
    // MARK: - Configuration
    
    var gradeChangeThreshold: Double = 5.0 // Percentage drop that triggers alert
    var lookbackPeriod: Int = 3 // Number of recent grades to analyze
    
    // MARK: - Dependencies
    
    private let gradesStore = GradesStore.shared
    private let coursesStore = CoursesStore.shared
    private let notificationManager = NotificationManager.shared
    private let settings = AppSettingsModel.shared
    
    // MARK: - Storage
    
    private var gradeHistory: [UUID: [GradeSnapshot]] = [:]
    private var studyHours: [UUID: Double] = [:] // courseId -> weekly hours
    private var cancellables = Set<AnyCancellable>()
    
    private let storageURL: URL = {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("GradeMonitoring", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("grade_history.json")
    }()
    
    // MARK: - Initialization
    
    private init() {
        loadHistory()
        setupGradeObserver()
        LOG_UI(.info, "GradeMonitoring", "Service initialized")
    }
    
    // MARK: - Grade Snapshot
    
    struct GradeSnapshot: Codable, Identifiable {
        let id: UUID
        let courseId: UUID
        let score: Double
        let date: Date
        let assignmentName: String?
        
        init(courseId: UUID, score: Double, date: Date = Date(), assignmentName: String? = nil) {
            self.id = UUID()
            self.courseId = courseId
            self.score = score
            self.date = date
            self.assignmentName = assignmentName
        }
    }
    
    // MARK: - Public API
    
    /// Start monitoring grade changes
    func startMonitoring() {
        isMonitoring = true
        LOG_UI(.info, "GradeMonitoring", "Started monitoring grades")
    }
    
    /// Stop monitoring grade changes
    func stopMonitoring() {
        isMonitoring = false
        LOG_UI(.info, "GradeMonitoring", "Stopped monitoring grades")
    }
    
    /// Add a grade snapshot for monitoring
    func addGrade(courseId: UUID, score: Double, assignmentName: String? = nil) {
        let snapshot = GradeSnapshot(courseId: courseId, score: score, assignmentName: assignmentName)
        
        if gradeHistory[courseId] == nil {
            gradeHistory[courseId] = []
        }
        gradeHistory[courseId]?.append(snapshot)
        gradeHistory[courseId]?.sort { $0.date < $1.date }
        
        saveHistory()
        
        guard isMonitoring else { return }
        
        // Analyze the grade change
        if let analysis = detectGradeChange(for: courseId) {
            recentAnalyses.append(analysis)
            
            if analysis.requiresAction {
                Task {
                    await handleGradeDecline(courseId: courseId, analysis: analysis)
                }
            }
        }
    }
    
    /// Set current weekly study hours for a course
    func setStudyHours(courseId: UUID, weeklyHours: Double) {
        studyHours[courseId] = weeklyHours
        saveHistory()
    }
    
    /// Get study recommendation for a course
    func getStudyRecommendation(for courseId: UUID) -> StudyTimeRecommendation? {
        studyRecommendations.first { $0.courseId == courseId }
    }
    
    /// Clear recommendation
    func clearRecommendation(id: UUID) {
        studyRecommendations.removeAll { $0.id == id }
    }
    
    // MARK: - Grade Analysis
    
    private func detectGradeChange(for courseId: UUID) -> GradeAnalysis? {
        guard let grades = gradeHistory[courseId],
              grades.count >= 2 else {
            return nil
        }
        
        let recentGrades = Array(grades.suffix(lookbackPeriod))
        
        guard recentGrades.count >= 2 else { return nil }
        
        // Calculate trend
        let recentTwo = Array(recentGrades.suffix(2))
        let recentAvg = recentTwo.map(\.score).reduce(0, +) / Double(recentTwo.count)
        
        let previousGrades = Array(recentGrades.dropLast())
        let previousAvg = previousGrades.isEmpty ? recentAvg : 
            previousGrades.map(\.score).reduce(0, +) / Double(previousGrades.count)
        
        let change = recentAvg - previousAvg
        
        // Determine trend
        let trend: GradeTrend
        if abs(change) < 2 {
            trend = .stable
        } else if change > 0 {
            trend = .improving
        } else {
            trend = .declining
        }
        
        let requiresAction = trend == .declining && abs(change) >= gradeChangeThreshold
        
        return GradeAnalysis(
            courseId: courseId,
            trend: trend,
            change: change,
            recentAverage: recentAvg,
            previousAverage: previousAvg,
            requiresAction: requiresAction,
            timestamp: Date()
        )
    }
    
    // MARK: - Study Time Recommendations
    
    private func handleGradeDecline(courseId: UUID, analysis: GradeAnalysis) async {
        let currentHours = studyHours[courseId] ?? 5.0 // Default 5 hours per week
        
        guard let recommendation = calculateStudyTimeIncrease(
            courseId: courseId,
            currentHours: currentHours,
            gradeChange: abs(analysis.change)
        ) else {
            return
        }
        
        studyRecommendations.append(recommendation)
        
        // Send notification
        await sendStudyTimeNotification(recommendation: recommendation)
    }
    
    private func calculateStudyTimeIncrease(
        courseId: UUID,
        currentHours: Double,
        gradeChange: Double
    ) -> StudyTimeRecommendation? {
        
        guard let coursesStore = coursesStore,
              let course = coursesStore.courses.first(where: { $0.id == courseId }) else {
            return nil
        }
        
        // Calculate increase factor based on severity
        let increaseFactor: Double
        if gradeChange >= 15 {
            increaseFactor = 0.5 // 50% more time
        } else if gradeChange >= 10 {
            increaseFactor = 0.35 // 35% more time
        } else if gradeChange >= 5 {
            increaseFactor = 0.25 // 25% more time
        } else {
            increaseFactor = 0.15 // 15% more time
        }
        
        let suggestedHours = currentHours * (1 + increaseFactor)
        let additionalHours = suggestedHours - currentHours
        
        return StudyTimeRecommendation(
            id: UUID(),
            courseId: courseId,
            courseName: course.code,
            currentWeeklyHours: currentHours,
            suggestedWeeklyHours: suggestedHours,
            additionalHours: additionalHours,
            reason: "Grade declined by \(String(format: "%.1f", gradeChange)) points",
            trend: .declining,
            timestamp: Date()
        )
    }
    
    // MARK: - Notifications
    
    private func sendStudyTimeNotification(recommendation: StudyTimeRecommendation) async {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "📚 Study Time Recommendation"
        content.body = """
        \(recommendation.courseName): Your grades have declined. \
        Consider increasing study time from \(String(format: "%.1f", recommendation.currentWeeklyHours)) to \
        \(String(format: "%.1f", recommendation.suggestedWeeklyHours)) hours per week \
        (+\(String(format: "%.1f", recommendation.additionalHours)) hours).
        """
        content.sound = .default
        content.categoryIdentifier = "STUDY_TIME_RECOMMENDATION"
        
        let request = UNNotificationRequest(
            identifier: "study-recommendation-\(recommendation.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            LOG_NOTIFICATIONS(.info, "GradeMonitoring", "Sent study time notification for \(recommendation.courseName)")
        } catch {
            LOG_NOTIFICATIONS(.error, "GradeMonitoring", "Failed to send notification: \(error)")
        }
        #endif
    }
    
    // MARK: - Grade Observer
    
    private func setupGradeObserver() {
        gradesStore.$grades
            .sink { [weak self] grades in
                self?.syncWithGradesStore(grades)
            }
            .store(in: &cancellables)
    }
    
    private func syncWithGradesStore(_ grades: [GradeEntry]) {
        for gradeEntry in grades {
            guard let percent = gradeEntry.percent else { continue }
            
            // Check if this is a new grade
            let existingGrades = gradeHistory[gradeEntry.courseId] ?? []
            let lastGrade = existingGrades.last
            
            if lastGrade == nil || abs(lastGrade!.score - percent) > 0.1 {
                addGrade(courseId: gradeEntry.courseId, score: percent)
            }
        }
    }
    
    // MARK: - Persistence
    
    private struct StorageData: Codable {
        let gradeHistory: [UUID: [GradeSnapshot]]
        let studyHours: [UUID: Double]
    }
    
    private func saveHistory() {
        let data = StorageData(gradeHistory: gradeHistory, studyHours: studyHours)
        
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: storageURL)
            LOG_UI(.debug, "GradeMonitoring", "Saved history to disk")
        } catch {
            LOG_UI(.error, "GradeMonitoring", "Failed to save history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode(StorageData.self, from: data)
            gradeHistory = decoded.gradeHistory
            studyHours = decoded.studyHours
            LOG_UI(.info, "GradeMonitoring", "Loaded history from disk")
        } catch {
            LOG_UI(.error, "GradeMonitoring", "Failed to load history: \(error)")
        }
    }
}
