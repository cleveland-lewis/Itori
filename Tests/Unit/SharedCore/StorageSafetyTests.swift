import XCTest
@testable import Roots

final class StorageSafetyTests: XCTestCase {
    private var originalTasks: [AppTask] = []

    override func setUp() {
        super.setUp()
        originalTasks = AssignmentsStore.shared.tasks
        AssignmentsStore.shared.tasks = []
        AssignmentsStore.holidayCheckerOverride = nil
        AssignmentsStore.holidaySourceAvailabilityOverride = nil
    }

    override func tearDown() {
        AssignmentsStore.shared.tasks = originalTasks
        AssignmentsStore.holidayCheckerOverride = nil
        AssignmentsStore.holidaySourceAvailabilityOverride = nil
        super.tearDown()
    }

    @MainActor
    func testDeleteCourseReassignsTasksToUnassignedWithoutLoss() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("storage_safety_\(UUID().uuidString)")
            .appendingPathComponent("courses.json")
        let coursesStore = CoursesStore(storageURL: tempURL)

        let semester = Semester(
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 90),
            isCurrent: true,
            notes: ""
        )
        coursesStore.addSemester(semester)

        let courseId = UUID()
        let course = Course(id: courseId, title: "Biology", code: "BIO101", semesterId: semester.id, isArchived: false)
        coursesStore.addCourse(course)

        let keepTask = AppTask(
            id: UUID(),
            title: "Keep",
            courseId: UUID(),
            due: nil,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .reading,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .reading
        )
        let reassignedTask = AppTask(
            id: UUID(),
            title: "Reassign",
            courseId: courseId,
            due: nil,
            estimatedMinutes: 45,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.6,
            importance: 0.7,
            type: .project,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .project
        )
        AssignmentsStore.shared.tasks = [keepTask, reassignedTask]

        coursesStore.deleteCourse(course)

        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 2)
        let updated = AssignmentsStore.shared.tasks.first { $0.id == reassignedTask.id }
        XCTAssertNotNil(updated)
        XCTAssertNil(updated?.courseId)
        let untouched = AssignmentsStore.shared.tasks.first { $0.id == keepTask.id }
        XCTAssertEqual(untouched?.courseId, keepTask.courseId)
    }

    @MainActor
    func testTaskCompletionPersistsToDisk() {
        let taskId = UUID()
        let task = AppTask(
            id: taskId,
            title: "Persist Completion",
            courseId: nil,
            due: Date(),
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .reading,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .reading
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)

        let snapshot = AssignmentsStore.shared.loadCacheSnapshotForTesting()
        let persisted = snapshot.first { $0.id == taskId }
        XCTAssertNotNil(persisted)
        XCTAssertEqual(persisted?.isCompleted, true)
    }

    @MainActor
    func testRecurringCompletionCreatesOnlyOneNextOccurrence() {
        let taskId = UUID()
        let rule = RecurrenceRule(frequency: .weekly, interval: 1, end: .never, skipPolicy: .init())
        let task = AppTask(
            id: taskId,
            title: "Weekly Reading",
            courseId: nil,
            due: Date(),
            estimatedMinutes: 45,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.3,
            importance: 0.4,
            type: .reading,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .reading,
            dueTimeMinutes: 9 * 60,
            recurrence: rule
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)
        AssignmentsStore.shared.updateTask(completed)

        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 2)
    }

    @MainActor
    func testRecurrenceIntervalEveryThreeDays() {
        let rule = RecurrenceRule(frequency: .daily, interval: 3, end: .never, skipPolicy: .init())
        let baseDate = Calendar.current.startOfDay(for: Date())
        let task = AppTask(
            id: UUID(),
            title: "Interval Test",
            courseId: nil,
            due: baseDate,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .homework,
            recurrence: rule
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)

        let next = AssignmentsStore.shared.tasks.first { $0.id != task.id }
        XCTAssertNotNil(next?.due)
        let delta = Calendar.current.dateComponents([.day], from: baseDate, to: next?.due ?? baseDate).day
        XCTAssertEqual(delta, 3)
    }

    @MainActor
    func testRecurrenceEndAfterOccurrencesStopsAtCount() {
        let rule = RecurrenceRule(frequency: .daily, interval: 1, end: .afterOccurrences(3), skipPolicy: .init())
        let baseDate = Calendar.current.startOfDay(for: Date())
        let task = AppTask(
            id: UUID(),
            title: "End After 3",
            courseId: nil,
            due: baseDate,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            recurrence: rule
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 2)

        if let second = AssignmentsStore.shared.tasks.first(where: { $0.id != task.id }) {
            var completedSecond = second
            completedSecond.isCompleted = true
            AssignmentsStore.shared.updateTask(completedSecond)
        }
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 3)

        if let third = AssignmentsStore.shared.tasks.first(where: { $0.id != task.id && $0.recurrenceIndex == 2 }) {
            var completedThird = third
            completedThird.isCompleted = true
            AssignmentsStore.shared.updateTask(completedThird)
        }
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 3)
    }

    @MainActor
    func testRecurrenceEndUntilDateIsInclusive() {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        let endDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate)
        let rule = RecurrenceRule(frequency: .daily, interval: 1, end: .until(endDate), skipPolicy: .init())
        let task = AppTask(
            id: UUID(),
            title: "Until Date",
            courseId: nil,
            due: baseDate,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            recurrence: rule
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)
        let next = AssignmentsStore.shared.tasks.first { $0.id != task.id }
        XCTAssertNotNil(next)
        XCTAssertEqual(next?.due, calendar.startOfDay(for: endDate))

        if let nextTask = next {
            var completedNext = nextTask
            completedNext.isCompleted = true
            AssignmentsStore.shared.updateTask(completedNext)
        }
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 2)
    }

    @MainActor
    func testRecurringTaskWithoutDueDateDoesNotGenerateNext() {
        let rule = RecurrenceRule(frequency: .weekly, interval: 1, end: .never, skipPolicy: .init())
        let task = AppTask(
            id: UUID(),
            title: "No Due",
            courseId: nil,
            due: nil,
            estimatedMinutes: 20,
            minBlockMinutes: 10,
            maxBlockMinutes: 40,
            difficulty: 0.2,
            importance: 0.2,
            type: .reading,
            locked: false,
            recurrence: rule
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)

        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 1)
    }

    @MainActor
    func testSkipWeekendsAdjustsForward() {
        let calendar = Calendar.current
        let friday = calendar.date(from: DateComponents(year: 2024, month: 6, day: 7)) ?? Date()
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            end: .never,
            skipPolicy: .init(skipWeekends: true, skipHolidays: false, holidaySource: .none, adjustment: .forward)
        )
        let task = AppTask(
            id: UUID(),
            title: "Weekend Skip",
            courseId: nil,
            due: friday,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            recurrence: rule
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)

        let next = AssignmentsStore.shared.tasks.first { $0.id != task.id }
        let nextComponents = calendar.dateComponents([.weekday], from: next?.due ?? Date())
        XCTAssertEqual(nextComponents.weekday, 2)
    }

    @MainActor
    func testSkipHolidaysAdjustsForwardWithOverride() {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        let holidayDate = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        AssignmentsStore.holidayCheckerOverride = { date, _ in
            calendar.isDate(date, inSameDayAs: holidayDate)
        }
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            end: .never,
            skipPolicy: .init(skipWeekends: false, skipHolidays: true, holidaySource: .deviceCalendar, adjustment: .forward)
        )
        let task = AppTask(
            id: UUID(),
            title: "Holiday Skip",
            courseId: nil,
            due: baseDate,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            recurrence: rule
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)

        let next = AssignmentsStore.shared.tasks.first { $0.id != task.id }
        let nextComponents = calendar.dateComponents([.day], from: next?.due ?? Date())
        let holidayComponents = calendar.dateComponents([.day], from: holidayDate)
        XCTAssertNotEqual(nextComponents.day, holidayComponents.day)
    }

    @MainActor
    func testSkipHolidaysUnavailableDoesNotAdjust() {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        let holidayDate = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        AssignmentsStore.holidayCheckerOverride = { _, _ in true }
        AssignmentsStore.holidaySourceAvailabilityOverride = { _ in false }

        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            end: .never,
            skipPolicy: .init(skipWeekends: false, skipHolidays: true, holidaySource: .deviceCalendar, adjustment: .forward)
        )
        let task = AppTask(
            id: UUID(),
            title: "Holiday Unavailable",
            courseId: nil,
            due: baseDate,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            recurrence: rule
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)

        let next = AssignmentsStore.shared.tasks.first { $0.id != task.id }
        XCTAssertEqual(next?.due, holidayDate)
    }

    @MainActor
    func testRecurrencePreservesTimeAcrossDST() {
        let originalTimeZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "America/New_York") ?? .current
        defer { NSTimeZone.default = originalTimeZone }

        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        let baseDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 9)) ?? Date()
        let rule = RecurrenceRule(frequency: .daily, interval: 1, end: .never, skipPolicy: .init())
        let task = AppTask(
            id: UUID(),
            title: "DST Check",
            courseId: nil,
            due: baseDate,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.3,
            importance: 0.3,
            type: .homework,
            locked: false,
            dueTimeMinutes: 9 * 60,
            recurrence: rule
        )
        AssignmentsStore.shared.tasks = [task]

        var completed = task
        completed.isCompleted = true
        AssignmentsStore.shared.updateTask(completed)

        let next = AssignmentsStore.shared.tasks.first { $0.id != task.id }
        XCTAssertEqual(next?.dueTimeMinutes, task.dueTimeMinutes)
    }
    
    // MARK: - Deletion/Reassign Invariants Tests (Issue #235)
    
    @MainActor
    func testDeleteSemesterWithCascadeRemovesAllChildren() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("deletion_test_\(UUID().uuidString)")
            .appendingPathComponent("courses.json")
        let coursesStore = CoursesStore(storageURL: tempURL)
        
        let semester = Semester(
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 90),
            isCurrent: true,
            notes: ""
        )
        coursesStore.addSemester(semester)
        
        let course1 = Course(id: UUID(), title: "Math", code: "MATH101", semesterId: semester.id, isArchived: false)
        let course2 = Course(id: UUID(), title: "Physics", code: "PHYS101", semesterId: semester.id, isArchived: false)
        coursesStore.addCourse(course1)
        coursesStore.addCourse(course2)
        
        let task1 = AppTask(
            id: UUID(),
            title: "Math HW",
            courseId: course1.id,
            due: nil,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            category: .homework
        )
        let task2 = AppTask(
            id: UUID(),
            title: "Physics Lab",
            courseId: course2.id,
            due: nil,
            estimatedMinutes: 60,
            minBlockMinutes: 30,
            maxBlockMinutes: 90,
            difficulty: 0.6,
            importance: 0.7,
            type: .project,
            locked: false,
            category: .project
        )
        AssignmentsStore.shared.tasks = [task1, task2]
        
        coursesStore.permanentlyDeleteSemester(semester.id)
        
        XCTAssertFalse(coursesStore.semesters.contains(where: { $0.id == semester.id }))
        XCTAssertFalse(coursesStore.courses.contains(where: { $0.id == course1.id }))
        XCTAssertFalse(coursesStore.courses.contains(where: { $0.id == course2.id }))
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 2, "Tasks should persist after semester cascade delete")
        let reassigned1 = AssignmentsStore.shared.tasks.first { $0.id == task1.id }
        let reassigned2 = AssignmentsStore.shared.tasks.first { $0.id == task2.id }
        XCTAssertNil(reassigned1?.courseId, "Task should be reassigned to Unassigned")
        XCTAssertNil(reassigned2?.courseId, "Task should be reassigned to Unassigned")
    }
    
    @MainActor
    func testDeleteCourseWithCascadeRemovesOnlyCourseChildren() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("deletion_test_\(UUID().uuidString)")
            .appendingPathComponent("courses.json")
        let coursesStore = CoursesStore(storageURL: tempURL)
        
        let semester = Semester(
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 90),
            isCurrent: true,
            notes: ""
        )
        coursesStore.addSemester(semester)
        
        let deleteCourse = Course(id: UUID(), title: "Delete Me", code: "DEL101", semesterId: semester.id, isArchived: false)
        let keepCourse = Course(id: UUID(), title: "Keep Me", code: "KEEP101", semesterId: semester.id, isArchived: false)
        coursesStore.addCourse(deleteCourse)
        coursesStore.addCourse(keepCourse)
        
        let deleteTask = AppTask(
            id: UUID(),
            title: "Delete Task",
            courseId: deleteCourse.id,
            due: nil,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            category: .homework
        )
        let keepTask = AppTask(
            id: UUID(),
            title: "Keep Task",
            courseId: keepCourse.id,
            due: nil,
            estimatedMinutes: 45,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.5,
            importance: 0.6,
            type: .reading,
            locked: false,
            category: .reading
        )
        AssignmentsStore.shared.tasks = [deleteTask, keepTask]
        
        coursesStore.deleteCourse(deleteCourse)
        
        XCTAssertFalse(coursesStore.courses.contains(where: { $0.id == deleteCourse.id }))
        XCTAssertTrue(coursesStore.courses.contains(where: { $0.id == keepCourse.id }))
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 2, "Both tasks should persist")
        let reassignedTask = AssignmentsStore.shared.tasks.first { $0.id == deleteTask.id }
        XCTAssertNil(reassignedTask?.courseId, "Deleted course's task should be reassigned to Unassigned")
        let untouchedTask = AssignmentsStore.shared.tasks.first { $0.id == keepTask.id }
        XCTAssertEqual(untouchedTask?.courseId, keepCourse.id, "Other course's task should remain unchanged")
    }
    
    @MainActor
    func testDeletionWithDeepNestingPreservesDataIntegrity() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("deletion_test_\(UUID().uuidString)")
            .appendingPathComponent("courses.json")
        let coursesStore = CoursesStore(storageURL: tempURL)
        
        let semester1 = Semester(
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 90),
            isCurrent: true,
            notes: ""
        )
        let semester2 = Semester(
            startDate: Date().addingTimeInterval(86400 * 100),
            endDate: Date().addingTimeInterval(86400 * 190),
            isCurrent: false,
            notes: ""
        )
        coursesStore.addSemester(semester1)
        coursesStore.addSemester(semester2)
        
        let s1Course1 = Course(id: UUID(), title: "S1C1", code: "S1C1", semesterId: semester1.id, isArchived: false)
        let s1Course2 = Course(id: UUID(), title: "S1C2", code: "S1C2", semesterId: semester1.id, isArchived: false)
        let s2Course1 = Course(id: UUID(), title: "S2C1", code: "S2C1", semesterId: semester2.id, isArchived: false)
        coursesStore.addCourse(s1Course1)
        coursesStore.addCourse(s1Course2)
        coursesStore.addCourse(s2Course1)
        
        let s1c1Task1 = AppTask(
            id: UUID(),
            title: "S1C1T1",
            courseId: s1Course1.id,
            due: nil,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            category: .homework
        )
        let s1c1Task2 = AppTask(
            id: UUID(),
            title: "S1C1T2",
            courseId: s1Course1.id,
            due: nil,
            estimatedMinutes: 45,
            minBlockMinutes: 20,
            maxBlockMinutes: 60,
            difficulty: 0.5,
            importance: 0.6,
            type: .reading,
            locked: false,
            category: .reading
        )
        let s1c2Task = AppTask(
            id: UUID(),
            title: "S1C2T",
            courseId: s1Course2.id,
            due: nil,
            estimatedMinutes: 60,
            minBlockMinutes: 30,
            maxBlockMinutes: 90,
            difficulty: 0.6,
            importance: 0.7,
            type: .project,
            locked: false,
            category: .project
        )
        let s2c1Task = AppTask(
            id: UUID(),
            title: "S2C1T",
            courseId: s2Course1.id,
            due: nil,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            category: .homework
        )
        AssignmentsStore.shared.tasks = [s1c1Task1, s1c1Task2, s1c2Task, s2c1Task]
        
        coursesStore.permanentlyDeleteSemester(semester1.id)
        
        XCTAssertFalse(coursesStore.semesters.contains(where: { $0.id == semester1.id }))
        XCTAssertTrue(coursesStore.semesters.contains(where: { $0.id == semester2.id }))
        XCTAssertFalse(coursesStore.courses.contains(where: { $0.id == s1Course1.id }))
        XCTAssertFalse(coursesStore.courses.contains(where: { $0.id == s1Course2.id }))
        XCTAssertTrue(coursesStore.courses.contains(where: { $0.id == s2Course1.id }))
        
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 4, "All tasks should persist")
        let task1 = AssignmentsStore.shared.tasks.first { $0.id == s1c1Task1.id }
        let task2 = AssignmentsStore.shared.tasks.first { $0.id == s1c1Task2.id }
        let task3 = AssignmentsStore.shared.tasks.first { $0.id == s1c2Task.id }
        let task4 = AssignmentsStore.shared.tasks.first { $0.id == s2c1Task.id }
        XCTAssertNil(task1?.courseId)
        XCTAssertNil(task2?.courseId)
        XCTAssertNil(task3?.courseId)
        XCTAssertEqual(task4?.courseId, s2Course1.id, "Semester 2 task should remain assigned")
    }
    
    @MainActor
    func testMultipleSequentialDeletionsPreserveCorrectState() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("deletion_test_\(UUID().uuidString)")
            .appendingPathComponent("courses.json")
        let coursesStore = CoursesStore(storageURL: tempURL)
        
        let semester = Semester(
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 90),
            isCurrent: true,
            notes: ""
        )
        coursesStore.addSemester(semester)
        
        let course1 = Course(id: UUID(), title: "Course 1", code: "C1", semesterId: semester.id, isArchived: false)
        let course2 = Course(id: UUID(), title: "Course 2", code: "C2", semesterId: semester.id, isArchived: false)
        let course3 = Course(id: UUID(), title: "Course 3", code: "C3", semesterId: semester.id, isArchived: false)
        coursesStore.addCourse(course1)
        coursesStore.addCourse(course2)
        coursesStore.addCourse(course3)
        
        let task1 = AppTask(
            id: UUID(),
            title: "Task 1",
            courseId: course1.id,
            due: nil,
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.4,
            importance: 0.5,
            type: .homework,
            locked: false,
            category: .homework
        )
        let task2 = AppTask(
            id: UUID(),
            title: "Task 2",
            courseId: course2.id,
            due: nil,
            estimatedMinutes: 45,
            minBlockMinutes: 20,
            maxBlockMinutes: 60,
            difficulty: 0.5,
            importance: 0.6,
            type: .reading,
            locked: false,
            category: .reading
        )
        let task3 = AppTask(
            id: UUID(),
            title: "Task 3",
            courseId: course3.id,
            due: nil,
            estimatedMinutes: 60,
            minBlockMinutes: 30,
            maxBlockMinutes: 90,
            difficulty: 0.6,
            importance: 0.7,
            type: .project,
            locked: false,
            category: .project
        )
        AssignmentsStore.shared.tasks = [task1, task2, task3]
        
        coursesStore.deleteCourse(course1)
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 3)
        XCTAssertNil(AssignmentsStore.shared.tasks.first { $0.id == task1.id }?.courseId)
        
        coursesStore.deleteCourse(course2)
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 3)
        XCTAssertNil(AssignmentsStore.shared.tasks.first { $0.id == task2.id }?.courseId)
        
        let finalTask3 = AssignmentsStore.shared.tasks.first { $0.id == task3.id }
        XCTAssertEqual(finalTask3?.courseId, course3.id, "Remaining task should still be assigned")
    }
}
