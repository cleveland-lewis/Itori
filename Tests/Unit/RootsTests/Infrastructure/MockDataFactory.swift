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
            type: .homework,
            estimatedMinutes: 90
        )
    }
    
    func createQuizTask() -> AppTask {
        createTask(
            title: "Physics Quiz Prep",
            type: .quiz,
            estimatedMinutes: 45
        )
    }
    
    func createExamTask() -> AppTask {
        createTask(
            title: "History Exam Review",
            type: .exam,
            estimatedMinutes: 180,
            importance: 0.9
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
        colorTag: ColorTag = .blue,
        isArchived: Bool = false
    ) -> Course {
        Course(
            id: id,
            title: title,
            code: code,
            semesterId: semesterId ?? UUID(),
            instructor: instructor,
            location: location,
            colorTag: colorTag,
            isArchived: isArchived
        )
    }
    
    // MARK: - Semester Creation
    
    func createSemester(
        id: UUID = UUID(),
        term: SemesterTerm = .fall,
        academicYear: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> Semester {
        let year = academicYear ?? "2024"
        let start = startDate ?? date(year: 2024, month: 9, day: 1)
        let end = endDate ?? date(year: 2024, month: 12, day: 20)
        
        return Semester(
            id: id,
            semesterTerm: term,
            academicYear: year,
            startDate: start,
            endDate: end
        )
    }
    
    // MARK: - Timer Session Creation
    
    func createTimerSession(
        id: UUID = UUID(),
        activityID: UUID? = nil,
        mode: TimerMode = .pomodoro,
        plannedDuration: TimeInterval? = 1500, // 25 minutes
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        state: FocusSession.State = .completed,
        actualDuration: TimeInterval? = nil
    ) -> FocusSession {
        FocusSession(
            id: id,
            activityID: activityID,
            mode: mode,
            plannedDuration: plannedDuration,
            startedAt: startedAt ?? Date(),
            endedAt: endedAt,
            state: state,
            actualDuration: actualDuration
        )
    }
    
    // MARK: - Planner Block Creation
    
    func createPlannerBlock(
        taskId: UUID,
        startDate: Date? = nil,
        durationMinutes: Int = 60,
        dayIndex: Int = 0
    ) -> PlannedBlock {
        let start = startDate ?? Date()
        return PlannedBlock(
            id: UUID(),
            taskId: taskId,
            startDate: start,
            endDate: start.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            dayIndex: dayIndex,
            isLocked: false
        )
    }
    
    // MARK: - Calendar Event Creation
    
    func createFixedEvent(
        id: UUID = UUID(),
        title: String = "Meeting",
        startDate: Date? = nil,
        endDate: Date? = nil,
        isAllDay: Bool = false,
        source: EventSource = .roots
    ) -> FixedEvent {
        let start = startDate ?? Date()
        let end = endDate ?? start.addingTimeInterval(3600) // 1 hour
        
        return FixedEvent(
            id: id,
            title: title,
            startDate: start,
            endDate: end,
            isAllDay: isAllDay,
            source: source
        )
    }
    
    // MARK: - Recurrence Rule Creation
    
    func createRecurrenceRule(
        frequency: RecurrenceFrequency = .weekly,
        interval: Int = 1,
        daysOfWeek: [Weekday]? = nil,
        endDate: Date? = nil,
        occurrenceCount: Int? = nil
    ) -> RecurrenceRule {
        RecurrenceRule(
            frequency: frequency,
            interval: interval,
            daysOfWeek: daysOfWeek,
            endDate: endDate,
            occurrenceCount: occurrenceCount
        )
    }
    
    // MARK: - Practice Test Creation
    
    func createPracticeTest(
        id: UUID = UUID(),
        courseId: UUID,
        title: String = "Practice Test",
        topics: [String] = ["Topic 1", "Topic 2"],
        questionCount: Int = 10,
        status: PracticeTestStatus = .draft
    ) -> PracticeTest {
        PracticeTest(
            id: id,
            courseId: courseId,
            title: title,
            topics: topics,
            questions: [],
            createdAt: Date(),
            updatedAt: Date(),
            status: status
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
