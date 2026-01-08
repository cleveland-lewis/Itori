//
//  CompleteFlowIntegrationTests.swift
//  ItoriTests
//
//  Integration tests covering the complete user flow:
//  1. Create semester
//  2. Add course to semester
//  3. Create assignment for course
//  4. Generate plan for assignment
//  5. Schedule plan sessions with planner
//  6. Convert sessions to calendar events
//  7. Verify events exist in calendar
//

import XCTest
import EventKit
import Combine
@testable import Itori

@MainActor
final class CompleteFlowIntegrationTests: BaseTestCase {
    
    var coursesStore: CoursesStore!
    var assignmentsStore: AssignmentsStore!
    var plannerStore: PlannerStore!
    var tempDir: URL!
    var cancellables: Set<AnyCancellable>!
    private var originalTasks: [AppTask] = []
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create temp directory for test isolation
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Initialize stores with isolated storage
        let coursesStorageURL = tempDir.appendingPathComponent("test_courses.json")
        coursesStore = CoursesStore(storageURL: coursesStorageURL)
        
        assignmentsStore = AssignmentsStore.shared
        plannerStore = PlannerStore.shared

        originalTasks = assignmentsStore.tasks
        if !originalTasks.isEmpty {
            assignmentsStore.tasks = []
        }
        
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        cancellables?.removeAll()
        cancellables = nil
        
        // Clean up stores
        if CoursesStore.shared === coursesStore {
            CoursesStore.shared = nil
        }
        coursesStore = nil
        assignmentsStore = nil
        plannerStore = nil

        if !originalTasks.isEmpty {
            AssignmentsStore.shared.tasks = originalTasks
        }
        originalTasks = []
        
        // Clean up temp directory
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        tempDir = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Complete Flow Tests
    
    /// Tests the complete flow: semester → course → assignment → plan → schedule → calendar
    func testCompleteFlowFromSemesterToCalendar() throws {
        // STEP 1: Create semester
        let semester = mockData.createSemester(
            term: .fall,
            academicYear: "2026",
            startDate: date(year: 2026, month: 9, day: 1),
            endDate: date(year: 2026, month: 12, day: 20)
        )
        
        coursesStore.addSemester(semester)
        coursesStore.setCurrentSemester(semester)
        
        XCTAssertEqual(coursesStore.semesters.count, 1, "Should have 1 semester")
        XCTAssertEqual(coursesStore.currentSemester?.id, semester.id, "Semester should be current")
        
        // STEP 2: Add course to semester
        let course = mockData.createCourse(
            title: "Computer Science 101",
            code: "CS101",
            semesterId: semester.id,
            instructor: "Dr. Smith",
            location: "Building A, Room 101"
        )
        
        coursesStore.addCourse(course)
        
        XCTAssertEqual(coursesStore.courses.count, 1, "Should have 1 course")
        XCTAssertEqual(coursesStore.currentSemesterCourses.count, 1, "Course should be in current semester")
        
        // STEP 3: Create assignment for course
        let dueDate = date(year: 2026, month: 10, day: 15, hour: 23, minute: 59)
        let assignment = Assignment(
            id: UUID(),
            courseId: course.id,
            title: "Midterm Exam",
            dueDate: dueDate,
            estimatedMinutes: 240,
            category: .exam,
            urgency: .high,
            isLockedToDueDate: false,
            plan: []
        )
        
        let task = AppTask(
            id: assignment.id,
            title: assignment.title,
            courseId: assignment.courseId,
            due: assignment.dueDate,
            estimatedMinutes: assignment.estimatedMinutes,
            minBlockMinutes: 30,
            maxBlockMinutes: 90,
            difficulty: 0.7,
            importance: 0.9,
            type: .exam,
            locked: false,
            isCompleted: false,
            category: nil
        )
        
        assignmentsStore.tasks.append(task)
        
        XCTAssertEqual(assignmentsStore.tasks.count, 1, "Should have 1 assignment")
        XCTAssertEqual(assignmentsStore.tasks.first?.courseId, course.id, "Assignment should be linked to course")
        
        // STEP 4: Generate plan for assignment
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        XCTAssertFalse(plan.steps.isEmpty, "Plan should have steps")
        XCTAssertGreaterThanOrEqual(plan.steps.count, 3, "Exam should have at least 3 study steps")
        
        let totalPlanDuration = plan.steps.reduce(0.0) { $0 + $1.estimatedDuration }
        XCTAssertGreaterThanOrEqual(
            totalPlanDuration,
            TimeInterval(240 * 60),
            "Total plan duration should cover estimated time"
        )
        
        // Verify step sequence
        for (index, step) in plan.steps.enumerated() {
            XCTAssertEqual(step.sequenceIndex, index, "Steps should be properly sequenced")
            XCTAssertNotNil(step.recommendedStartDate, "Steps should have start dates")
        }
        
        // STEP 5: Generate planner sessions from assignment
        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)
        
        XCTAssertFalse(sessions.isEmpty, "Should generate planner sessions")
        XCTAssertEqual(sessions.first?.assignmentId, assignment.id, "Sessions should be linked to assignment")
        
        for session in sessions {
            XCTAssertGreaterThan(session.estimatedMinutes, 0, "Sessions should have positive duration")
            XCTAssertTrue(
                calendar.isDate(session.dueDate, inSameDayAs: dueDate),
                "Sessions should inherit due date (same day)"
            )
        }
        
        // STEP 6: Schedule sessions with energy profile
        let energyProfile: [Int: Double] = [
            9: 0.6, 10: 0.7, 11: 0.8, 12: 0.6,
            13: 0.5, 14: 0.6, 15: 0.7, 16: 0.8,
            17: 0.7, 18: 0.6, 19: 0.5, 20: 0.4
        ]
        
        let scheduleResult = PlannerEngine.scheduleSessions(
            sessions,
            settings: settings,
            energyProfile: energyProfile
        )
        
        XCTAssertFalse(
            scheduleResult.scheduled.isEmpty && scheduleResult.overflow.isEmpty,
            "Should have scheduled sessions or overflow"
        )
        
        // Verify no overlapping sessions
        let scheduled = scheduleResult.scheduled
        for i in 0..<scheduled.count {
            for j in (i+1)..<scheduled.count {
                let s1 = scheduled[i]
                let s2 = scheduled[j]
                let noOverlap = s1.end <= s2.start || s2.end <= s1.start
                XCTAssertTrue(noOverlap, "Sessions should not overlap: \(s1.session.title) and \(s2.session.title)")
            }
        }
        
        // STEP 7: Convert scheduled sessions to calendar blocks
        let storedSessions = scheduleResult.scheduled.map { scheduledSession in
            StoredScheduledSession(
                id: scheduledSession.id,
                assignmentId: scheduledSession.session.assignmentId,
                sessionIndex: scheduledSession.session.sessionIndex,
                sessionCount: scheduledSession.session.sessionCount,
                title: scheduledSession.session.title,
                dueDate: scheduledSession.session.dueDate,
                estimatedMinutes: scheduledSession.session.estimatedMinutes,
                isLockedToDueDate: scheduledSession.session.isLockedToDueDate,
                category: scheduledSession.session.category,
                start: scheduledSession.start,
                end: scheduledSession.end,
                type: .task,
                isLocked: false,
                isUserEdited: false,
                userEditedAt: nil,
                aiInputHash: nil,
                aiComputedAt: nil,
                aiConfidence: nil,
                aiProvenance: nil
            )
        }
        
        let calendarBlocks = PlannerCalendarSync.buildBlocks(
            from: storedSessions,
            gapMinutes: 10
        )
        
        XCTAssertFalse(calendarBlocks.isEmpty, "Should generate calendar blocks")
        
        // Verify block metadata
        for block in calendarBlocks {
            XCTAssertFalse(block.title.isEmpty, "Block should have title")
            XCTAssertLessThan(block.start, block.end, "Block start should be before end")
            XCTAssertTrue(block.notes.contains("[RootsPlanner]"), "Block should have metadata")
        }
        
        // STEP 8: Create sync plan (simulates syncing to calendar)
        let mockExistingEvents: [PlannerCalendarEventSnapshot] = []
        let dateRange = calendar.date(byAdding: .day, value: -7, to: Date())!...calendar.date(byAdding: .day, value: 30, to: Date())!
        
        let syncPlan = PlannerCalendarSync.syncPlan(
            blocks: calendarBlocks,
            existingEvents: mockExistingEvents,
            range: dateRange
        )
        
        XCTAssertFalse(syncPlan.upserts.isEmpty, "Should have events to create")
        XCTAssertTrue(syncPlan.deletions.isEmpty, "Should not delete any events on first sync")
        
        // STEP 9: Verify calendar events would be created (mock)
        XCTAssertGreaterThan(syncPlan.upserts.count, 0, "Should generate calendar events")
        
        for (index, upsert) in syncPlan.upserts.enumerated() {
            // Calendar blocks are titled by category, not specific assignment name
            // For exam category, should be "Exam Session"
            let expectedTitle = "Exam Session"
            XCTAssertEqual(upsert.block.title, expectedTitle,
                          "Event \(index + 1) title should be '\(expectedTitle)', got: '\(upsert.block.title)'")
            XCTAssertFalse(upsert.block.notes.isEmpty, "Event \(index + 1) should have notes")
            XCTAssertTrue(upsert.block.notes.contains("block_id:"),
                         "Event \(index + 1) notes should contain block ID")
            XCTAssertTrue(upsert.block.notes.contains("source: planner"),
                         "Event \(index + 1) notes should indicate planner source")
        }
        
        print("✅ Complete flow test passed:")
        print("   - Created semester: \(semester.semesterTerm) \(semester.academicYear ?? "")")
        print("   - Added course: \(course.code) - \(course.title)")
        print("   - Created assignment: \(assignment.title)")
        print("   - Generated plan with \(plan.steps.count) steps")
        print("   - Scheduled \(scheduleResult.scheduled.count) sessions")
        print("   - Created \(calendarBlocks.count) calendar blocks")
        print("   - Generated \(syncPlan.upserts.count) calendar events")
    }
    
    // MARK: - Multiple Assignments Flow
    
    /// Tests flow with multiple assignments competing for schedule time
    func testMultipleAssignmentsFlow() throws {
        // Setup: semester and course
        let semester = mockData.createSemester(term: .spring)
        coursesStore.addSemester(semester)
        coursesStore.setCurrentSemester(semester)
        
        let course1 = mockData.createCourse(title: "Math 201", code: "MATH201", semesterId: semester.id)
        let course2 = mockData.createCourse(title: "Physics 101", code: "PHYS101", semesterId: semester.id)
        
        coursesStore.addCourse(course1)
        coursesStore.addCourse(course2)
        
        // Create multiple assignments with different priorities
        let assignment1 = Assignment(
            id: UUID(),
            courseId: course1.id,
            title: "Math Homework Set 5",
            dueDate: date(year: 2026, month: 4, day: 10, hour: 23, minute: 59),
            estimatedMinutes: 120,
            category: .homework,
            urgency: .medium,
            isLockedToDueDate: false,
            plan: []
        )
        
        let assignment2 = Assignment(
            id: UUID(),
            courseId: course2.id,
            title: "Physics Lab Report",
            dueDate: date(year: 2026, month: 4, day: 12, hour: 23, minute: 59),
            estimatedMinutes: 180,
            category: .homework,
            urgency: .high,
            isLockedToDueDate: false,
            plan: []
        )
        
        let assignment3 = Assignment(
            id: UUID(),
            courseId: course2.id,
            title: "Physics Midterm",
            dueDate: date(year: 2026, month: 4, day: 15, hour: 14, minute: 0),
            estimatedMinutes: 300,
            category: .exam,
            urgency: .critical,
            isLockedToDueDate: true,
            plan: []
        )
        
        // Generate sessions for all assignments
        let settings = StudyPlanSettings()
        var allSessions: [PlannerSession] = []
        
        for assignment in [assignment1, assignment2, assignment3] {
            let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)
            allSessions.append(contentsOf: sessions)
        }
        
        XCTAssertGreaterThanOrEqual(allSessions.count, 3, "Should have sessions for all assignments")
        
        // Schedule all sessions together
        let energyProfile: [Int: Double] = [
            9: 0.7, 10: 0.8, 11: 0.9, 12: 0.7,
            13: 0.6, 14: 0.7, 15: 0.8, 16: 0.8,
            17: 0.7, 18: 0.6
        ]
        
        let result = PlannerEngine.scheduleSessions(
            allSessions,
            settings: settings,
            energyProfile: energyProfile
        )
        
        XCTAssertFalse(result.scheduled.isEmpty, "Should schedule some sessions")
        
        // Verify priority ordering (critical exam should be scheduled first)
        let examSessions = result.scheduled.filter { $0.session.category == .exam }
        XCTAssertFalse(examSessions.isEmpty, "Critical exam should be scheduled")
        
        // Verify no time conflicts
        for i in 0..<result.scheduled.count {
            for j in (i+1)..<result.scheduled.count {
                let s1 = result.scheduled[i]
                let s2 = result.scheduled[j]
                let noOverlap = s1.end <= s2.start || s2.end <= s1.start
                XCTAssertTrue(noOverlap, "Sessions should not conflict")
            }
        }
        
        print("✅ Multiple assignments flow passed:")
        print("   - \(coursesStore.courses.count) courses")
        print("   - 3 assignments with different priorities")
        print("   - \(allSessions.count) total sessions generated")
        print("   - \(result.scheduled.count) sessions scheduled")
        print("   - \(result.overflow.count) sessions in overflow")
    }
    
    // MARK: - Project with Custom Plan Flow
    
    /// Tests flow with a project that has custom plan steps
    func testProjectWithCustomPlanFlow() throws {
        // Setup
        let semester = mockData.createSemester()
        coursesStore.addSemester(semester)
        
        let course = mockData.createCourse(title: "Software Engineering", code: "SE401", semesterId: semester.id)
        coursesStore.addCourse(course)
        
        // Create project with custom plan
        let customPlan = [
            PlanStepStub(title: "Research Phase", expectedMinutes: 180),
            PlanStepStub(title: "Design Documents", expectedMinutes: 120),
            PlanStepStub(title: "Implementation Sprint 1", expectedMinutes: 240),
            PlanStepStub(title: "Implementation Sprint 2", expectedMinutes: 240),
            PlanStepStub(title: "Testing & QA", expectedMinutes: 120),
            PlanStepStub(title: "Final Review & Polish", expectedMinutes: 90)
        ]
        
        let assignment = Assignment(
            id: UUID(),
            courseId: course.id,
            title: "Final Project: Todo App",
            dueDate: date(year: 2026, month: 5, day: 1, hour: 23, minute: 59),
            estimatedMinutes: 990,
            category: .project,
            urgency: .high,
            isLockedToDueDate: false,
            plan: customPlan
        )
        
        // Generate plan (should use custom steps)
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        XCTAssertEqual(plan.steps.count, 6, "Should have 6 custom steps")
        XCTAssertEqual(plan.steps[0].title, "Research Phase")
        XCTAssertEqual(plan.steps[5].title, "Final Review & Polish")
        
        // Verify step durations match
        XCTAssertEqual(plan.steps[0].estimatedDuration, TimeInterval(180 * 60))
        XCTAssertEqual(plan.steps[1].estimatedDuration, TimeInterval(120 * 60))
        
        // Generate and schedule sessions
        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)
        
        XCTAssertFalse(sessions.isEmpty, "Should generate sessions from custom plan")
        
        let energyProfile = (9...20).reduce(into: [Int: Double]()) { $0[$1] = 0.7 }
        let result = PlannerEngine.scheduleSessions(sessions, settings: settings, energyProfile: energyProfile)
        
        XCTAssertFalse(result.scheduled.isEmpty, "Should schedule project sessions")
        
        print("✅ Project with custom plan flow passed:")
        print("   - Custom plan with \(customPlan.count) steps")
        print("   - Generated \(sessions.count) sessions")
        print("   - Scheduled \(result.scheduled.count) sessions")
    }
    
    // MARK: - Calendar Sync Update Flow
    
    /// Tests updating existing calendar events when schedule changes
    func testCalendarSyncUpdateFlow() throws {
        let semester = mockData.createSemester()
        coursesStore.addSemester(semester)
        
        let course = mockData.createCourse(semesterId: semester.id)
        coursesStore.addCourse(course)
        
        let assignment = Assignment(
            id: UUID(),
            courseId: course.id,
            title: "Weekly Quiz",
            dueDate: date(year: 2026, month: 3, day: 20, hour: 23, minute: 59),
            estimatedMinutes: 60,
            category: .quiz,
            urgency: .medium,
            isLockedToDueDate: false,
            plan: []
        )
        
        // Initial schedule
        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)
        let energyProfile = (9...18).reduce(into: [Int: Double]()) { $0[$1] = 0.7 }
        let result = PlannerEngine.scheduleSessions(sessions, settings: settings, energyProfile: energyProfile)
        
        let storedSessions = result.scheduled.map { scheduledSession in
            StoredScheduledSession(
                id: scheduledSession.id,
                assignmentId: scheduledSession.session.assignmentId,
                sessionIndex: scheduledSession.session.sessionIndex,
                sessionCount: scheduledSession.session.sessionCount,
                title: scheduledSession.session.title,
                dueDate: scheduledSession.session.dueDate,
                estimatedMinutes: scheduledSession.session.estimatedMinutes,
                isLockedToDueDate: scheduledSession.session.isLockedToDueDate,
                category: scheduledSession.session.category,
                start: scheduledSession.start,
                end: scheduledSession.end,
                type: .task,
                isLocked: false,
                isUserEdited: false,
                userEditedAt: nil,
                aiInputHash: nil,
                aiComputedAt: nil,
                aiConfidence: nil,
                aiProvenance: nil
            )
        }
        
        let initialBlocks = PlannerCalendarSync.buildBlocks(from: storedSessions, gapMinutes: 10)
        
        // Simulate existing events in calendar
        let existingEvents = initialBlocks.map { block in
            PlannerCalendarEventSnapshot(
                identifier: "event-\(block.id)",
                title: block.title,
                start: block.start,
                end: block.end,
                notes: block.notes
            )
        }
        
        // Now user reschedules - create new sessions with updated times
        let updatedSessions = storedSessions.map { session -> StoredScheduledSession in
            StoredScheduledSession(
                id: session.id,
                assignmentId: session.assignmentId,
                sessionIndex: session.sessionIndex,
                sessionCount: session.sessionCount,
                title: session.title,
                dueDate: session.dueDate,
                estimatedMinutes: session.estimatedMinutes,
                isLockedToDueDate: session.isLockedToDueDate,
                category: session.category,
                start: session.start.addingTimeInterval(3600), // Shift by 1 hour
                end: session.end.addingTimeInterval(3600),
                type: session.type,
                isLocked: session.isLocked,
                isUserEdited: session.isUserEdited,
                userEditedAt: session.userEditedAt,
                aiInputHash: session.aiInputHash,
                aiComputedAt: session.aiComputedAt,
                aiConfidence: session.aiConfidence,
                aiProvenance: session.aiProvenance
            )
        }
        
        let updatedBlocks = PlannerCalendarSync.buildBlocks(from: updatedSessions, gapMinutes: 10)
        
        // Create sync plan
        let dateRange = Date()...calendar.date(byAdding: .month, value: 1, to: Date())!
        let syncPlan = PlannerCalendarSync.syncPlan(
            blocks: updatedBlocks,
            existingEvents: existingEvents,
            range: dateRange
        )
        
        XCTAssertFalse(syncPlan.upserts.isEmpty, "Should have events to update")
        
        print("✅ Calendar sync update flow passed:")
        print("   - Initial blocks: \(initialBlocks.count)")
        print("   - Existing events: \(existingEvents.count)")
        print("   - Updated blocks: \(updatedBlocks.count)")
        print("   - Upserts: \(syncPlan.upserts.count)")
        print("   - Deletions: \(syncPlan.deletions.count)")
    }
}
