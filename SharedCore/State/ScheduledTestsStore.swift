import Combine
import Foundation
import SwiftUI

@MainActor
final class ScheduledTestsStore: ObservableObject {
    static let shared = ScheduledTestsStore()
    @Published var scheduledTests: [ScheduledPracticeTest] = []
    @Published var attempts: [TestAttempt] = []
    @Published var currentWeek: Date = Date()
    
    private let testsStorageKey = "scheduled_practice_tests_v1"
    private let attemptsStorageKey = "test_attempts_v1"
    
    init() {
        loadData()
    }
    
    // MARK: - Week Navigation
    
    func goToPreviousWeek() {
        currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
    }
    
    func goToNextWeek() {
        currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
    }
    
    func goToThisWeek() {
        currentWeek = Date()
    }
    
    var isCurrentWeek: Bool {
        let thisWeekStart = Calendar.current.startOfWeek(for: Date())
        let selectedWeekStart = Calendar.current.startOfWeek(for: currentWeek)
        return Calendar.current.isDate(thisWeekStart, equalTo: selectedWeekStart, toGranularity: .day)
    }
    
    // MARK: - Data Access
    
    func testsForCurrentWeek() -> [ScheduledPracticeTest] {
        let start = Calendar.current.startOfWeek(for: currentWeek)
        let end = Calendar.current.endOfWeek(for: currentWeek)
        
        return scheduledTests.filter { test in
            test.scheduledAt >= start && test.scheduledAt < end && test.status != .archived
        }
    }
    
    func testsForDay(_ date: Date) -> [ScheduledPracticeTest] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        return testsForCurrentWeek().filter { test in
            test.scheduledAt >= startOfDay && test.scheduledAt < endOfDay
        }.sorted { $0.scheduledAt < $1.scheduledAt }
    }
    
    func hasCompletedAttempt(for scheduledTestID: UUID) -> Bool {
        attempts.contains { attempt in
            attempt.scheduledTestID == scheduledTestID && attempt.isCompleted
        }
    }
    
    func computedStatus(for test: ScheduledPracticeTest) -> ScheduledTestStatus {
        test.computedStatus(hasCompletedAttempt: hasCompletedAttempt(for: test.id))
    }
    
    // MARK: - Mutations
    
    func addScheduledTest(_ test: ScheduledPracticeTest) {
        scheduledTests.append(test)
        saveData()
    }
    
    func updateScheduledTest(_ test: ScheduledPracticeTest) {
        if let index = scheduledTests.firstIndex(where: { $0.id == test.id }) {
            scheduledTests[index] = test
            saveData()
        }
    }
    
    func deleteScheduledTest(_ testID: UUID) {
        scheduledTests.removeAll { $0.id == testID }
        saveData()
    }
    
    func startTest(scheduledTest: ScheduledPracticeTest) -> TestAttempt {
        let attempt = TestAttempt(
            scheduledTestID: scheduledTest.id,
            startedAt: Date()
        )
        attempts.append(attempt)
        saveData()
        return attempt
    }
    
    func completeAttempt(_ attemptID: UUID, score: Double?, outputReference: String? = nil) {
        if let index = attempts.firstIndex(where: { $0.id == attemptID }) {
            attempts[index].completedAt = Date()
            attempts[index].score = score
            attempts[index].outputReference = outputReference
            saveData()
            if let scheduledTestID = attempts[index].scheduledTestID,
               let scheduledTest = scheduledTests.first(where: { $0.id == scheduledTestID }),
               let score {
                handleAutoFollowUp(for: scheduledTest, score: score)
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        // Load scheduled tests
        if let testsData = UserDefaults.standard.data(forKey: testsStorageKey),
           let decoded = try? JSONDecoder().decode([ScheduledPracticeTest].self, from: testsData) {
            scheduledTests = decoded
        }
        
        // Load attempts
        if let attemptsData = UserDefaults.standard.data(forKey: attemptsStorageKey),
           let decoded = try? JSONDecoder().decode([TestAttempt].self, from: attemptsData) {
            attempts = decoded
        }
        
        removeSampleDataIfPresent()
    }
    
    private func saveData() {
        // Save scheduled tests
        if let encoded = try? JSONEncoder().encode(scheduledTests) {
            UserDefaults.standard.set(encoded, forKey: testsStorageKey)
        }
        
        // Save attempts
        if let encoded = try? JSONEncoder().encode(attempts) {
            UserDefaults.standard.set(encoded, forKey: attemptsStorageKey)
        }
    }

    func resetAll() {
        scheduledTests.removeAll()
        attempts.removeAll()
        UserDefaults.standard.removeObject(forKey: testsStorageKey)
        UserDefaults.standard.removeObject(forKey: attemptsStorageKey)
        saveData()
    }
    
    // MARK: - Sample Data Cleanup
    
    private func removeSampleDataIfPresent() {
        let sampleTitles: Set<String> = [
            "Calculus Midterm Practice",
            "Biology Quiz",
            "Physics Problem Set",
            "Chemistry Review"
        ]
        let originalCount = scheduledTests.count
        scheduledTests.removeAll { test in
            sampleTitles.contains(test.title) && test.sourceAssignmentId == nil
        }
        if scheduledTests.count != originalCount {
            saveData()
        }
    }

    // MARK: - Auto Scheduling (Exams/Quizzes)

    func syncAutoPracticeTests(for assignment: AppTask) {
        guard assignment.type == .exam || assignment.type == .quiz else {
            removeAutoPracticeTests(for: assignment.id)
            return
        }
        guard let dueDate = assignment.due else { return }
        guard !assignment.moduleIds.isEmpty else {
            removeAutoPracticeTests(for: assignment.id)
            return
        }

        let moduleTitles = moduleTitlesForAssignment(assignment)
        let moduleCount = max(1, assignment.moduleIds.count)
        let questionCount = moduleCount * 40
        let baseMinutes = moduleCount * 50
        let multiplier = max(0.5, min(2.0, AppSettingsModel.shared.practiceTestTimeMultiplier))
        let timeLimitMinutes = Int(round(Double(baseMinutes) * multiplier))
        let difficulty = difficultyLevel(from: assignment.difficulty)
        let subject = courseDisplayName(for: assignment)
        let unitName = moduleTitles.isEmpty ? nil : moduleTitles.joined(separator: ", ")

        guard let initialDate = scheduleDate(for: assignment, kind: .initial, dueDate: dueDate) else { return }

        if let index = scheduledTests.firstIndex(where: {
            $0.sourceAssignmentId == assignment.id &&
            $0.isAutoGenerated &&
            $0.scheduleKind == .initial
        }) {
            var updated = scheduledTests[index]
            updated.courseId = assignment.courseId
            updated.moduleIds = assignment.moduleIds
            updated.title = practiceTestTitle(for: assignment)
            updated.subject = subject
            updated.unitName = unitName
            updated.scheduledAt = initialDate
            updated.estimatedMinutes = timeLimitMinutes
            updated.difficulty = difficulty
            updated.questionCount = questionCount
            updated.timeLimitMinutes = timeLimitMinutes
            updated.updatedAt = Date()
            updated.taskId = upsertPlannerTask(for: updated, assignment: assignment, scheduledAt: initialDate)
            scheduledTests[index] = updated
        } else {
            var newTest = ScheduledPracticeTest(
                courseId: assignment.courseId,
                moduleIds: assignment.moduleIds,
                sourceAssignmentId: assignment.id,
                taskId: nil,
                scheduleKind: .initial,
                isAutoGenerated: true,
                questionCount: questionCount,
                timeLimitMinutes: timeLimitMinutes,
                title: practiceTestTitle(for: assignment),
                subject: subject,
                unitName: unitName,
                scheduledAt: initialDate,
                estimatedMinutes: timeLimitMinutes,
                difficulty: difficulty
            )
            newTest.taskId = upsertPlannerTask(for: newTest, assignment: assignment, scheduledAt: initialDate)
            scheduledTests.append(newTest)
        }

        if let followUpDate = scheduleDate(for: assignment, kind: .followUp, dueDate: dueDate) {
            for index in scheduledTests.indices where scheduledTests[index].sourceAssignmentId == assignment.id &&
                scheduledTests[index].isAutoGenerated &&
                scheduledTests[index].scheduleKind == .followUp &&
                scheduledTests[index].status == .scheduled {
                var updated = scheduledTests[index]
                updated.courseId = assignment.courseId
                updated.moduleIds = assignment.moduleIds
                updated.title = followUpTitle(for: assignment)
                updated.subject = subject
                updated.unitName = unitName
                updated.scheduledAt = followUpDate
                updated.estimatedMinutes = timeLimitMinutes
                updated.difficulty = difficulty
                updated.questionCount = questionCount
                updated.timeLimitMinutes = timeLimitMinutes
                updated.updatedAt = Date()
                updated.taskId = upsertPlannerTask(for: updated, assignment: assignment, scheduledAt: followUpDate)
                scheduledTests[index] = updated
            }
        }

        saveData()
    }

    func removeAutoPracticeTests(for assignmentId: UUID) {
        let testsToRemove = scheduledTests.filter { test in
            test.sourceAssignmentId == assignmentId && test.isAutoGenerated
        }
        for test in testsToRemove {
            if let taskId = test.taskId {
                AssignmentsStore.shared.removeTask(id: taskId)
            }
        }
        scheduledTests.removeAll { test in
            test.sourceAssignmentId == assignmentId && test.isAutoGenerated
        }
        saveData()
    }

    private func handleAutoFollowUp(for test: ScheduledPracticeTest, score: Double) {
        guard test.isAutoGenerated, let assignmentId = test.sourceAssignmentId else { return }
        guard let assignment = AssignmentsStore.shared.tasks.first(where: { $0.id == assignmentId }) else { return }

        if score >= 0.9 {
            removePendingFollowUps(for: assignmentId)
            return
        }

        guard assignment.type == .exam || assignment.type == .quiz else { return }
        guard !assignment.moduleIds.isEmpty else { return }
        guard let dueDate = assignment.due else { return }

        let hasFollowUp = scheduledTests.contains { scheduled in
            scheduled.sourceAssignmentId == assignmentId &&
            scheduled.isAutoGenerated &&
            scheduled.scheduleKind == .followUp &&
            scheduled.status == .scheduled
        }
        guard !hasFollowUp else { return }
        guard let followUpDate = scheduleDate(for: assignment, kind: .followUp, dueDate: dueDate) else { return }

        let moduleTitles = moduleTitlesForAssignment(assignment)
        let moduleCount = max(1, assignment.moduleIds.count)
        let questionCount = moduleCount * 40
        let baseMinutes = moduleCount * 50
        let multiplier = max(0.5, min(2.0, AppSettingsModel.shared.practiceTestTimeMultiplier))
        let timeLimitMinutes = Int(round(Double(baseMinutes) * multiplier))
        let difficulty = difficultyLevel(from: assignment.difficulty)
        let subject = courseDisplayName(for: assignment)
        let unitName = moduleTitles.isEmpty ? nil : moduleTitles.joined(separator: ", ")

        var followUp = ScheduledPracticeTest(
            courseId: assignment.courseId,
            moduleIds: assignment.moduleIds,
            sourceAssignmentId: assignment.id,
            taskId: nil,
            scheduleKind: .followUp,
            isAutoGenerated: true,
            questionCount: questionCount,
            timeLimitMinutes: timeLimitMinutes,
            title: followUpTitle(for: assignment),
            subject: subject,
            unitName: unitName,
            scheduledAt: followUpDate,
            estimatedMinutes: timeLimitMinutes,
            difficulty: difficulty
        )
        followUp.taskId = upsertPlannerTask(for: followUp, assignment: assignment, scheduledAt: followUpDate)
        scheduledTests.append(followUp)
        saveData()
    }

    private func removePendingFollowUps(for assignmentId: UUID) {
        let pending = scheduledTests.filter { test in
            test.sourceAssignmentId == assignmentId &&
            test.isAutoGenerated &&
            test.scheduleKind == .followUp &&
            test.status == .scheduled
        }
        for test in pending {
            if let taskId = test.taskId {
                AssignmentsStore.shared.removeTask(id: taskId)
            }
        }
        scheduledTests.removeAll { test in
            test.sourceAssignmentId == assignmentId &&
            test.isAutoGenerated &&
            test.scheduleKind == .followUp &&
            test.status == .scheduled
        }
    }

    private func scheduleDate(for assignment: AppTask, kind: PracticeTestScheduleKind, dueDate: Date) -> Date? {
        let calendar = Calendar.current
        let offsetDays: Int
        switch (assignment.type, kind) {
        case (.exam, .initial):
            offsetDays = -14
        case (.exam, .followUp):
            offsetDays = -7
        case (.quiz, .initial):
            offsetDays = -7
        case (.quiz, .followUp):
            offsetDays = -3
        default:
            offsetDays = -7
        }
        guard let base = calendar.date(byAdding: .day, value: offsetDays, to: dueDate) else { return nil }
        let dayStart = calendar.startOfDay(for: base)
        return calendar.date(byAdding: .hour, value: 10, to: dayStart)
    }

    private func practiceTestTitle(for assignment: AppTask) -> String {
        let subject = courseDisplayName(for: assignment)
        switch assignment.type {
        case .exam:
            return "Practice Exam: \(subject)"
        case .quiz:
            return "Practice Quiz: \(subject)"
        default:
            return "Practice Test: \(subject)"
        }
    }

    private func followUpTitle(for assignment: AppTask) -> String {
        let subject = courseDisplayName(for: assignment)
        switch assignment.type {
        case .exam:
            return "Practice Exam (Retake): \(subject)"
        case .quiz:
            return "Practice Quiz (Retake): \(subject)"
        default:
            return "Practice Test (Retake): \(subject)"
        }
    }

    private func courseDisplayName(for assignment: AppTask) -> String {
        guard let courseId = assignment.courseId,
              let course = CoursesStore.shared?.courses.first(where: { $0.id == courseId }) else {
            return assignment.title
        }
        return course.code.isEmpty ? course.title : course.code
    }

    private func moduleTitlesForAssignment(_ assignment: AppTask) -> [String] {
        guard let courseId = assignment.courseId,
              let coursesStore = CoursesStore.shared else { return [] }
        return coursesStore.outlineNodes
            .filter { $0.courseId == courseId && assignment.moduleIds.contains($0.id) }
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { $0.title }
    }

    private func difficultyLevel(from value: Double) -> Int {
        let normalized = max(0.0, min(1.0, value))
        return max(1, min(5, Int(round(normalized * 4.0)) + 1))
    }

    private func upsertPlannerTask(for test: ScheduledPracticeTest, assignment: AppTask, scheduledAt: Date) -> UUID {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: scheduledAt)
        let minutes = max(15, test.timeLimitMinutes)
        let dueTimeMinutes = calendar.component(.hour, from: scheduledAt) * 60 + calendar.component(.minute, from: scheduledAt)

        if let taskId = test.taskId,
           let existingIndex = AssignmentsStore.shared.tasks.firstIndex(where: { $0.id == taskId }) {
            let existing = AssignmentsStore.shared.tasks[existingIndex]
            let updated = AppTask(
                id: existing.id,
                title: test.title,
                courseId: assignment.courseId,
                moduleIds: assignment.moduleIds,
                due: dayStart,
                estimatedMinutes: minutes,
                minBlockMinutes: minutes,
                maxBlockMinutes: minutes,
                difficulty: assignment.difficulty,
                importance: existing.importance,
                type: .practiceTest,
                locked: existing.locked,
                attachments: existing.attachments,
                isCompleted: existing.isCompleted,
                gradeWeightPercent: existing.gradeWeightPercent,
                gradePossiblePoints: existing.gradePossiblePoints,
                gradeEarnedPoints: existing.gradeEarnedPoints,
                category: .practiceTest,
                dueTimeMinutes: dueTimeMinutes,
                recurrence: existing.recurrence,
                recurrenceSeriesID: existing.recurrenceSeriesID,
                recurrenceIndex: existing.recurrenceIndex,
                calendarEventIdentifier: existing.calendarEventIdentifier,
                sourceUniqueKey: existing.sourceUniqueKey,
                sourceFingerprint: existing.sourceFingerprint,
                notes: existing.notes,
                needsReview: existing.needsReview,
                alarmDate: existing.alarmDate,
                alarmEnabled: existing.alarmEnabled,
                alarmSound: existing.alarmSound,
                deletedAt: existing.deletedAt
            )
            AssignmentsStore.shared.updateTask(updated)
            return taskId
        }

        let newTask = AppTask(
            id: UUID(),
            title: test.title,
            courseId: assignment.courseId,
            moduleIds: assignment.moduleIds,
            due: dayStart,
            estimatedMinutes: minutes,
            minBlockMinutes: minutes,
            maxBlockMinutes: minutes,
            difficulty: assignment.difficulty,
            importance: assignment.importance,
            type: .practiceTest,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .practiceTest,
            dueTimeMinutes: dueTimeMinutes
        )
        AssignmentsStore.shared.addTask(newTask)
        return newTask.id
    }
}
