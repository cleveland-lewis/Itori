//
//  MockDataFactory.swift
//  RootsTests
//
//  Factory for creating consistent test data
//

import Foundation
@testable import Roots

/// Factory for creating mock data objects for testing
@MainActor
struct MockDataFactory {
    let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    
    // MARK: - Task Creation
    
    func createTask(
        id: UUID = UUID(),
        title: String = "Test Task",
        courseId: UUID? = nil,
        due: Date? = nil,
        estimatedMinutes: Int = 60,
        minBlockMinutes: Int = 30,
        maxBlockMinutes: Int = 60,
        difficulty: Double = 0.5,
        importance: Double = 0.5,
        type: TaskType = .homework,
        locked: Bool = false,
        isCompleted: Bool = false,
        category: TaskType? = nil
    ) -> AppTask {
        AppTask(
            id: id,
            title: title,
            courseId: courseId,
            due: due ?? Date().addingTimeInterval(86400), // Tomorrow
            estimatedMinutes: estimatedMinutes,
            minBlockMinutes: minBlockMinutes,
            maxBlockMinutes: maxBlockMinutes,
            difficulty: difficulty,
            importance: importance,
            type: type,
            locked: locked,
            isCompleted: isCompleted,
            category: category
        )
    }
    
    func createHomeworkTask() -> AppTask {
        createTask(
            title: "Math Homework",
            estimatedMinutes: 90,
            type: .homework
        )
    }
    
    func createQuizTask() -> AppTask {
        createTask(
            title: "Physics Quiz Prep",
            estimatedMinutes: 45,
            type: .quiz
        )
    }
    
    func createExamTask() -> AppTask {
        createTask(
            title: "History Exam Review",
            estimatedMinutes: 180,
            importance: 0.9,
            type: .exam
        )
    }
    
    // MARK: - Course Creation
    
    func createCourse(
        id: UUID = UUID(),
        title: String = "Test Course",
        code: String = "TEST101",
        semesterId: UUID? = nil,
        instructor: String = "Dr. Test",
        location: String = "Room 101",
        colorHex: String? = nil,
        isArchived: Bool = false
    ) -> Course {
        Course(
            id: id,
            title: title,
            code: code,
            semesterId: semesterId ?? UUID(),
            colorHex: colorHex,
            isArchived: isArchived,
            instructor: instructor,
            location: location
        )
    }
    
    // MARK: - Semester Creation
    
    func createSemester(
        id: UUID = UUID(),
        term: SemesterType = .fall,
        academicYear: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> Semester {
        let start = startDate ?? date(year: 2024, month: 9, day: 1)
        let end = endDate ?? date(year: 2024, month: 12, day: 20)
        
        return Semester(
            id: id,
            startDate: start,
            endDate: end,
            semesterTerm: term,
            academicYear: academicYear
        )
    }
    
    // MARK: - Timer Session Creation
    
    func createTimerSession(
        id: UUID = UUID(),
        activityID: UUID,
        mode: LocalTimerMode = .pomodoro,
        startDate: Date? = nil,
        endDate: Date? = nil,
        duration: TimeInterval = 1500 // 25 minutes
    ) -> LocalTimerSession {
        LocalTimerSession(
            id: id,
            activityID: activityID,
            mode: mode,
            startDate: startDate ?? Date(),
            endDate: endDate,
            duration: duration
        )
    }
    
    // MARK: - Calendar Event Creation
    
    func createFixedEvent(
        id: UUID = UUID(),
        title: String = "Meeting",
        startDate: Date? = nil,
        endDate: Date? = nil,
        isAllDay: Bool = false,
        source: EventSource = .calendar
    ) -> FixedEvent {
        let start = startDate ?? Date()
        let end = endDate ?? start.addingTimeInterval(3600) // 1 hour
        
        return FixedEvent(
            id: id,
            title: title,
            start: start,
            end: end,
            isLocked: false,
            source: source
        )
    }
    
    // MARK: - Recurrence Rule Creation
    
    func createRecurrenceRule(
        frequency: RecurrenceRule.Frequency = .weekly,
        interval: Int = 1,
        end: RecurrenceRule.End = .never
    ) -> RecurrenceRule {
        RecurrenceRule(
            frequency: frequency,
            interval: interval,
            end: end,
            skipPolicy: RecurrenceRule.SkipPolicy()
        )
    }
    
    // MARK: - Practice Test Creation
    
    func createPracticeTest(
        id: UUID = UUID(),
        title: String = "Practice Test",
        subject: String = "Test Subject",
        scheduledAt: Date? = nil,
        difficulty: Int = 3
    ) -> ScheduledPracticeTest {
        ScheduledPracticeTest(
            id: id,
            title: title,
            subject: subject,
            scheduledAt: scheduledAt ?? Date(),
            difficulty: difficulty
        )
    }
    
    // MARK: - Helper Methods
    
    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = calendar.timeZone
        return calendar.date(from: components)!
    }
    
    /// Create a batch of tasks for testing bulk operations
    func createTaskBatch(count: Int, courseId: UUID? = nil) -> [AppTask] {
        (0..<count).map { index in
            createTask(
                title: "Task \(index + 1)",
                courseId: courseId,
                due: Date().addingTimeInterval(TimeInterval(index * 86400))
            )
        }
    }
    
    /// Create a complete course with tasks and a semester
    func createCourseWithTasks(taskCount: Int = 5) -> (course: Course, semester: Semester, tasks: [AppTask]) {
        let semester = createSemester()
        let course = createCourse(semesterId: semester.id)
        let tasks = createTaskBatch(count: taskCount, courseId: course.id)
        return (course, semester, tasks)
    }
}
