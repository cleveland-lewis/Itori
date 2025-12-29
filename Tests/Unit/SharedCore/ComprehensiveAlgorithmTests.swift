import Testing
import Foundation
@testable import Roots

/// Comprehensive algorithm test suite covering all major algorithms in Roots
/// Tests determinism, correctness, edge cases, and performance
@MainActor
struct ComprehensiveAlgorithmTests {
    
    // MARK: - Assignment Plan Engine Tests
    
    @Test func testAssignmentPlanEngine_Determinism() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            courseId: nil,
            title: "Test Assignment",
            dueDate: dueDate,
            estimatedMinutes: 240,
            category: .exam,
            urgency: .high,
            plan: []
        )
        
        let plan1 = AssignmentPlanEngine.generatePlan(for: assignment)
        let plan2 = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan1.steps.count == plan2.steps.count)
        for (s1, s2) in zip(plan1.steps, plan2.steps) {
            #expect(s1.title == s2.title)
            #expect(s1.estimatedDuration == s2.estimatedDuration)
            #expect(s1.sequenceIndex == s2.sequenceIndex)
        }
    }
    
    @Test func testAssignmentPlanEngine_AllCategories() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let categories: [AssignmentCategory] = [.exam, .quiz, .homework, .reading, .review, .project]
        
        for category in categories {
            let assignment = Assignment(
                id: UUID(),
                courseId: nil,
                title: "Test \(category)",
                dueDate: dueDate,
                estimatedMinutes: 120,
                category: category,
                urgency: .medium,
                plan: []
            )
            
            let plan = AssignmentPlanEngine.generatePlan(for: assignment)
            #expect(!plan.steps.isEmpty, "Category \(category) should generate steps")
            #expect(plan.steps.allSatisfy { $0.estimatedDuration > 0 }, "All steps should have positive duration")
        }
    }
    
    // MARK: - Planner Engine Tests
    
    @Test func testPlannerEngine_SessionGeneration() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Test",
            dueDate: dueDate,
            estimatedMinutes: 180,
            category: .exam,
            urgency: .high,
            plan: []
        )
        
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        
        #expect(!sessions.isEmpty)
        #expect(sessions.allSatisfy { $0.estimatedMinutes > 0 })
        #expect(sessions.allSatisfy { $0.dueDate == dueDate })
    }
    
    @Test func testPlannerEngine_ScheduleIndexCalculation() async throws {
        let today = Date()
        
        let urgentSession = PlannerSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "Urgent",
            dueDate: today.addingTimeInterval(24 * 60 * 60),
            category: .exam,
            importance: .critical,
            difficulty: .high,
            estimatedMinutes: 60,
            isLockedToDueDate: false
        )
        
        let normalSession = PlannerSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "Normal",
            dueDate: today.addingTimeInterval(7 * 24 * 60 * 60),
            category: .homework,
            importance: .medium,
            difficulty: .medium,
            estimatedMinutes: 60,
            isLockedToDueDate: false
        )
        
        let urgentIndex = PlannerEngine.computeScheduleIndex(for: urgentSession, today: today)
        let normalIndex = PlannerEngine.computeScheduleIndex(for: normalSession, today: today)
        
        #expect(urgentIndex > normalIndex, "Urgent tasks should have higher schedule index")
        #expect(urgentIndex >= 0.0 && urgentIndex <= 1.0)
        #expect(normalIndex >= 0.0 && normalIndex <= 1.0)
    }
    
    @Test func testPlannerEngine_NoOverlappingSessions() async throws {
        let today = Date()
        let dueDate = today.addingTimeInterval(7 * 24 * 60 * 60)
        
        let assignments = [
            Assignment(id: UUID(), courseId: nil, title: "A1", dueDate: dueDate, estimatedMinutes: 120, category: .exam, urgency: .high, plan: []),
            Assignment(id: UUID(), courseId: nil, title: "A2", dueDate: dueDate, estimatedMinutes: 120, category: .exam, urgency: .high, plan: [])
        ]
        
        var allSessions: [PlannerSession] = []
        for assignment in assignments {
            allSessions.append(contentsOf: PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings()))
        }
        
        let energyProfile = [9: 0.7, 10: 0.8, 11: 0.9, 12: 0.7, 13: 0.6,
                            14: 0.7, 15: 0.8, 16: 0.9, 17: 0.7, 18: 0.6]
        
        let result = PlannerEngine.scheduleSessions(allSessions, settings: StudyPlanSettings(), energyProfile: energyProfile)
        
        for i in 0..<result.scheduled.count {
            for j in (i+1)..<result.scheduled.count {
                let s1 = result.scheduled[i]
                let s2 = result.scheduled[j]
                let noOverlap = s1.end <= s2.start || s2.end <= s1.start
                #expect(noOverlap, "Sessions should not overlap")
            }
        }
    }
    
    // MARK: - Test Blueprint Generator Tests
    
    @Test func testTestBlueprintGenerator_Determinism() async throws {
        let request = PracticeTestRequest(
            courseName: "Math",
            topics: ["Algebra", "Calculus"],
            questionCount: 10,
            difficulty: .medium,
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        )
        
        let blueprint1 = TestBlueprintGenerator.generateBlueprint(from: request)
        let blueprint2 = TestBlueprintGenerator.generateBlueprint(from: request)
        
        #expect(blueprint1.questionCount == blueprint2.questionCount)
        #expect(blueprint1.topics == blueprint2.topics)
        #expect(blueprint1.slots.count == blueprint2.slots.count)
        #expect(blueprint1.estimatedTimeMinutes == blueprint2.estimatedTimeMinutes)
    }
    
    @Test func testTestBlueprintGenerator_QuestionDistribution() async throws {
        let request = PracticeTestRequest(
            courseName: "Science",
            topics: ["Physics", "Chemistry", "Biology"],
            questionCount: 15,
            difficulty: .medium,
            id: UUID()
        )
        
        let blueprint = TestBlueprintGenerator.generateBlueprint(from: request)
        
        #expect(blueprint.questionCount == 15)
        #expect(blueprint.topics.count == 3)
        
        let totalQuota = blueprint.topicQuotas.values.reduce(0, +)
        #expect(totalQuota == 15, "Questions should be distributed across topics")
    }
    
    @Test func testTestBlueprintGenerator_DifficultyLevels() async throws {
        let difficulties: [TestDifficulty] = [.easy, .medium, .hard]
        
        for difficulty in difficulties {
            let request = PracticeTestRequest(
                courseName: "Test",
                topics: ["Topic"],
                questionCount: 10,
                difficulty: difficulty,
                id: UUID()
            )
            
            let blueprint = TestBlueprintGenerator.generateBlueprint(from: request)
            
            #expect(blueprint.difficultyTarget == difficulty)
            #expect(!blueprint.slots.isEmpty)
            #expect(blueprint.estimatedTimeMinutes > 0)
        }
    }
    
    // MARK: - Grade Calculator Tests
    
    @Test func testGradeCalculator_WeightedAverage() async throws {
        let courseId = UUID()
        let tasks = [
            createGradedTask(courseId: courseId, earned: 90, possible: 100, weight: 30),
            createGradedTask(courseId: courseId, earned: 85, possible: 100, weight: 30),
            createGradedTask(courseId: courseId, earned: 95, possible: 100, weight: 40)
        ]
        
        let grade = GradeCalculator.calculateCourseGrade(courseID: courseId, tasks: tasks)
        
        #expect(grade != nil)
        let expectedGrade = (90 * 30 + 85 * 30 + 95 * 40) / 100.0
        #expect(abs(grade! - expectedGrade) < 0.01, "Weighted average should be calculated correctly")
    }
    
    @Test func testGradeCalculator_NoGradedWork() async throws {
        let courseId = UUID()
        let tasks: [AppTask] = []
        
        let grade = GradeCalculator.calculateCourseGrade(courseID: courseId, tasks: tasks)
        
        #expect(grade == nil, "Should return nil when no graded work exists")
    }
    
    @Test func testGradeCalculator_GPACalculation() async throws {
        let course1 = Course(id: UUID(), code: "CS101", name: "Intro", credits: 3)
        let course2 = Course(id: UUID(), code: "MATH200", name: "Calculus", credits: 4)
        
        let tasks = [
            createGradedTask(courseId: course1.id, earned: 90, possible: 100, weight: 100),
            createGradedTask(courseId: course2.id, earned: 85, possible: 100, weight: 100)
        ]
        
        let gpa = GradeCalculator.calculateGPA(courses: [course1, course2], tasks: tasks)
        
        #expect(gpa > 0, "GPA should be calculated")
        #expect(gpa <= 4.0, "GPA should not exceed 4.0")
    }
    
    // MARK: - Assignment Plan Dependency Tests
    
    @Test func testAssignmentPlan_LinearChainSetup() async throws {
        var plan = AssignmentPlan(assignmentId: UUID(), sequenceEnforcementEnabled: true)
        
        let step1 = PlanStep(id: UUID(), planId: plan.id, title: "Step 1", estimatedDuration: 3600, sequenceIndex: 0)
        let step2 = PlanStep(id: UUID(), planId: plan.id, title: "Step 2", estimatedDuration: 3600, sequenceIndex: 1)
        let step3 = PlanStep(id: UUID(), planId: plan.id, title: "Step 3", estimatedDuration: 3600, sequenceIndex: 2)
        
        plan.steps = [step1, step2, step3]
        plan.setupLinearChain()
        
        #expect(plan.steps[0].prerequisiteIds.isEmpty)
        #expect(plan.steps[1].prerequisiteIds == [step1.id])
        #expect(plan.steps[2].prerequisiteIds == [step2.id])
    }
    
    @Test func testAssignmentPlan_CycleDetection() async throws {
        var plan = AssignmentPlan(assignmentId: UUID(), sequenceEnforcementEnabled: true)
        
        let step1 = PlanStep(id: UUID(), planId: plan.id, title: "Step 1", estimatedDuration: 3600, sequenceIndex: 0)
        var step2 = PlanStep(id: UUID(), planId: plan.id, title: "Step 2", estimatedDuration: 3600, sequenceIndex: 1)
        var step3 = PlanStep(id: UUID(), planId: plan.id, title: "Step 3", estimatedDuration: 3600, sequenceIndex: 2)
        
        step2.prerequisiteIds = [step1.id]
        step3.prerequisiteIds = [step2.id]
        var cycleStep1 = step1
        cycleStep1.prerequisiteIds = [step3.id]
        
        plan.steps = [cycleStep1, step2, step3]
        
        let cycle = plan.detectCycle()
        #expect(cycle != nil, "Cycle should be detected")
        #expect(cycle!.count > 0, "Cycle path should contain step IDs")
    }
    
    @Test func testAssignmentPlan_TopologicalSort() async throws {
        var plan = AssignmentPlan(assignmentId: UUID(), sequenceEnforcementEnabled: true)
        
        let step1 = PlanStep(id: UUID(), planId: plan.id, title: "Step 1", estimatedDuration: 3600, sequenceIndex: 0)
        var step2 = PlanStep(id: UUID(), planId: plan.id, title: "Step 2", estimatedDuration: 3600, sequenceIndex: 1)
        var step3 = PlanStep(id: UUID(), planId: plan.id, title: "Step 3", estimatedDuration: 3600, sequenceIndex: 2)
        
        step2.prerequisiteIds = [step1.id]
        step3.prerequisiteIds = [step1.id, step2.id]
        
        plan.steps = [step3, step2, step1]  // Random order
        
        let sorted = plan.topologicalSort()
        #expect(sorted != nil)
        
        if let sorted = sorted {
            #expect(sorted[0].id == step1.id)
            #expect(sorted[1].id == step2.id)
            #expect(sorted[2].id == step3.id)
        }
    }
    
    // MARK: - Plan Quality Tests
    
    @Test func testAssignmentPlan_QualityScore() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Test",
            dueDate: dueDate,
            estimatedMinutes: 240,
            category: .exam,
            urgency: .high,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        let quality = plan.qualityScore
        
        #expect(quality >= 0.0)
        #expect(quality <= 100.0)
        #expect(quality > 50.0, "Well-formed plans should have quality > 50")
    }
    
    @Test func testAssignmentPlan_ComplexityScore() async throws {
        let simplePlan = AssignmentPlan(assignmentId: UUID())
        let simpleComplexity = simplePlan.complexityScore
        
        var complexPlan = AssignmentPlan(assignmentId: UUID(), sequenceEnforcementEnabled: true)
        for i in 0..<10 {
            var step = PlanStep(id: UUID(), planId: complexPlan.id, title: "Step \(i)", estimatedDuration: 3600, sequenceIndex: i)
            if i > 0 {
                step.prerequisiteIds = [complexPlan.steps[i-1].id]
            }
            complexPlan.steps.append(step)
        }
        let complexComplexity = complexPlan.complexityScore
        
        #expect(complexComplexity > simpleComplexity, "Complex plans should have higher complexity score")
    }
    
    // MARK: - Plan Validation Tests
    
    @Test func testPlanValidation_ValidPlan() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Test",
            dueDate: dueDate,
            estimatedMinutes: 180,
            category: .exam,
            urgency: .high,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        let issues = AssignmentPlanEngine.validatePlan(plan)
        
        #expect(issues.isEmpty, "Valid plan should have no issues")
    }
    
    @Test func testPlanValidation_EmptyPlan() async throws {
        let plan = AssignmentPlan(assignmentId: UUID())
        let issues = AssignmentPlanEngine.validatePlan(plan)
        
        #expect(issues.contains(.emptyPlan), "Empty plan should be flagged")
    }
    
    @Test func testPlanValidation_InvalidSequence() async throws {
        var plan = AssignmentPlan(assignmentId: UUID())
        plan.steps = [
            PlanStep(id: UUID(), planId: plan.id, title: "Step 1", estimatedDuration: 3600, sequenceIndex: 0),
            PlanStep(id: UUID(), planId: plan.id, title: "Step 2", estimatedDuration: 3600, sequenceIndex: 2) // Skip 1
        ]
        
        let issues = AssignmentPlanEngine.validatePlan(plan)
        let hasSequenceIssue = issues.contains { issue in
            if case .invalidSequenceIndex = issue { return true }
            return false
        }
        
        #expect(hasSequenceIssue, "Invalid sequence should be detected")
    }
    
    // MARK: - Performance Tests
    
    @Test func testPerformance_PlanGeneration() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Performance Test",
            dueDate: dueDate,
            estimatedMinutes: 240,
            category: .exam,
            urgency: .high,
            plan: []
        )
        
        let start = CFAbsoluteTimeGetCurrent()
        _ = AssignmentPlanEngine.generatePlan(for: assignment)
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        #expect(duration < 0.010, "Plan generation should complete in < 10ms")
    }
    
    @Test func testPerformance_SessionGeneration() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Performance Test",
            dueDate: dueDate,
            estimatedMinutes: 180,
            category: .exam,
            urgency: .high,
            plan: []
        )
        
        let start = CFAbsoluteTimeGetCurrent()
        _ = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        #expect(duration < 0.020, "Session generation should complete in < 20ms")
    }
    
    @Test func testPerformance_Scheduling() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Performance Test",
            dueDate: dueDate,
            estimatedMinutes: 180,
            category: .exam,
            urgency: .high,
            plan: []
        )
        
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        let energyProfile = [9: 0.7, 10: 0.8, 11: 0.9, 12: 0.7, 13: 0.6,
                            14: 0.7, 15: 0.8, 16: 0.9, 17: 0.7, 18: 0.6]
        
        let start = CFAbsoluteTimeGetCurrent()
        _ = PlannerEngine.scheduleSessions(sessions, settings: StudyPlanSettings(), energyProfile: energyProfile)
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        #expect(duration < 0.050, "Scheduling should complete in < 50ms")
    }
    
    // MARK: - Edge Case Tests
    
    // MARK: Duration Edge Cases
    
    @Test func testEdgeCase_MinimalDuration() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Quick Task",
            dueDate: Date().addingTimeInterval(24 * 60 * 60),
            estimatedMinutes: 5,
            category: .homework,
            urgency: .low,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(!plan.steps.isEmpty, "Should handle minimal duration")
        #expect(plan.steps.allSatisfy { $0.estimatedDuration >= 900 }, "Steps should be at least 15 minutes")
    }
    
    @Test func testEdgeCase_ZeroDuration() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Zero Task",
            dueDate: Date().addingTimeInterval(24 * 60 * 60),
            estimatedMinutes: 0,
            category: .homework,
            urgency: .low,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(!plan.steps.isEmpty, "Should handle zero duration with minimum")
        #expect(plan.steps.allSatisfy { $0.estimatedDuration >= 900 }, "Should enforce 15-minute minimum")
    }
    
    @Test func testEdgeCase_VeryLongDuration() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Long Project",
            dueDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            estimatedMinutes: 2000,
            category: .project,
            urgency: .high,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(!plan.steps.isEmpty, "Should handle long duration")
        #expect(plan.steps.count >= 4, "Long projects should be split into multiple steps")
    }
    
    @Test func testEdgeCase_ExtremeLongDuration() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Massive Project",
            dueDate: Date().addingTimeInterval(90 * 24 * 60 * 60),
            estimatedMinutes: 10000,
            category: .project,
            urgency: .medium,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(!plan.steps.isEmpty, "Should handle extreme duration")
        let totalDuration = plan.steps.reduce(0.0) { $0 + $1.estimatedDuration }
        #expect(totalDuration >= TimeInterval(10000 * 60), "Should account for all time")
    }
    
    // MARK: Time Window Edge Cases
    
    @Test func testEdgeCase_NearDueDate() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Urgent Task",
            dueDate: Date().addingTimeInterval(2 * 60 * 60),
            estimatedMinutes: 60,
            category: .quiz,
            urgency: .critical,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(!plan.steps.isEmpty, "Should handle near due dates")
        
        for step in plan.steps {
            if let dueBy = step.dueBy {
                #expect(dueBy <= assignment.dueDate, "Steps should not be scheduled after due date")
            }
        }
    }
    
    @Test func testEdgeCase_PastDueDate() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Overdue Task",
            dueDate: Date().addingTimeInterval(-24 * 60 * 60),
            estimatedMinutes: 60,
            category: .homework,
            urgency: .critical,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(!plan.steps.isEmpty, "Should handle past due dates")
    }
    
    @Test func testEdgeCase_VeryFarFuture() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Far Future Task",
            dueDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            estimatedMinutes: 240,
            category: .exam,
            urgency: .low,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(!plan.steps.isEmpty, "Should handle far future dates")
        #expect(plan.steps.count >= 3, "Should still create reasonable plan")
    }
    
    @Test func testEdgeCase_SameSecondDueDate() async throws {
        let now = Date()
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Immediate Task",
            dueDate: now,
            estimatedMinutes: 30,
            category: .homework,
            urgency: .critical,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(!plan.steps.isEmpty, "Should handle immediate due date")
    }
    
    // MARK: Multiple Assignments Edge Cases
    
    @Test func testEdgeCase_TooManyAssignments() async throws {
        let today = Date()
        let tomorrow = today.addingTimeInterval(24 * 60 * 60)
        
        let assignments = (0..<50).map { i in
            Assignment(
                id: UUID(),
                courseId: nil,
                title: "Task \(i)",
                dueDate: tomorrow,
                estimatedMinutes: 60,
                category: .homework,
                urgency: .high,
                plan: []
            )
        }
        
        var allSessions: [PlannerSession] = []
        for assignment in assignments {
            allSessions.append(contentsOf: PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings()))
        }
        
        let energyProfile = [9: 0.7, 10: 0.8, 11: 0.9, 12: 0.7, 13: 0.6,
                            14: 0.7, 15: 0.8, 16: 0.9, 17: 0.7, 18: 0.6]
        
        let result = PlannerEngine.scheduleSessions(allSessions, settings: StudyPlanSettings(), energyProfile: energyProfile)
        
        #expect(result.overflow.count > 0, "Should overflow when too many assignments")
        #expect(result.scheduled.count > 0, "Should schedule as many as possible")
    }
    
    @Test func testEdgeCase_NoAssignments() async throws {
        let energyProfile = [9: 0.7, 10: 0.8]
        let result = PlannerEngine.scheduleSessions([], settings: StudyPlanSettings(), energyProfile: energyProfile)
        
        #expect(result.scheduled.isEmpty, "Should handle empty assignment list")
        #expect(result.overflow.isEmpty, "Should have no overflow")
    }
    
    @Test func testEdgeCase_AllSameDueDate() async throws {
        let dueDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
        
        let assignments = (0..<10).map { i in
            Assignment(
                id: UUID(),
                courseId: nil,
                title: "Task \(i)",
                dueDate: dueDate,
                estimatedMinutes: 90,
                category: .exam,
                urgency: .critical,
                plan: []
            )
        }
        
        var allSessions: [PlannerSession] = []
        for assignment in assignments {
            allSessions.append(contentsOf: PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings()))
        }
        
        #expect(allSessions.allSatisfy { $0.dueDate == dueDate }, "All should have same due date")
        #expect(allSessions.count >= 30, "Should generate multiple sessions per assignment")
    }
    
    // MARK: Scheduling Constraint Edge Cases
    
    @Test func testEdgeCase_NoAvailableTime() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Test",
            dueDate: Date().addingTimeInterval(60 * 60),
            estimatedMinutes: 500,
            category: .exam,
            urgency: .critical,
            plan: []
        )
        
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        let energyProfile = [9: 0.7, 10: 0.8]
        
        let result = PlannerEngine.scheduleSessions(sessions, settings: StudyPlanSettings(), energyProfile: energyProfile)
        
        #expect(result.overflow.count > 0, "Should overflow when insufficient time")
    }
    
    @Test func testEdgeCase_AllLowEnergyTime() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Test",
            dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            estimatedMinutes: 120,
            category: .exam,
            urgency: .high,
            plan: []
        )
        
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        let lowEnergyProfile = [9: 0.2, 10: 0.2, 11: 0.2, 12: 0.2, 13: 0.2,
                               14: 0.2, 15: 0.2, 16: 0.2, 17: 0.2, 18: 0.2]
        
        let result = PlannerEngine.scheduleSessions(sessions, settings: lowEnergyProfile, energyProfile: lowEnergyProfile)
        
        #expect(result.scheduled.count > 0, "Should still schedule even with low energy")
    }
    
    // MARK: Grade Calculator Edge Cases
    
    @Test func testEdgeCase_PerfectGrades() async throws {
        let courseId = UUID()
        let tasks = [
            createGradedTask(courseId: courseId, earned: 100, possible: 100, weight: 50),
            createGradedTask(courseId: courseId, earned: 100, possible: 100, weight: 50)
        ]
        
        let grade = GradeCalculator.calculateCourseGrade(courseID: courseId, tasks: tasks)
        
        #expect(grade == 100.0, "Perfect scores should yield 100%")
    }
    
    @Test func testEdgeCase_FailingGrades() async throws {
        let courseId = UUID()
        let tasks = [
            createGradedTask(courseId: courseId, earned: 0, possible: 100, weight: 100)
        ]
        
        let grade = GradeCalculator.calculateCourseGrade(courseID: courseId, tasks: tasks)
        
        #expect(grade == 0.0, "Zero score should yield 0%")
    }
    
    @Test func testEdgeCase_UnequalWeights() async throws {
        let courseId = UUID()
        let tasks = [
            createGradedTask(courseId: courseId, earned: 100, possible: 100, weight: 90),
            createGradedTask(courseId: courseId, earned: 0, possible: 100, weight: 10)
        ]
        
        let grade = GradeCalculator.calculateCourseGrade(courseID: courseId, tasks: tasks)
        
        #expect(grade! > 85.0, "Should weight heavily toward 90% weight task")
    }
    
    @Test func testEdgeCase_ZeroWeight() async throws {
        let courseId = UUID()
        let tasks = [
            createGradedTask(courseId: courseId, earned: 100, possible: 100, weight: 0),
            createGradedTask(courseId: courseId, earned: 80, possible: 100, weight: 100)
        ]
        
        let grade = GradeCalculator.calculateCourseGrade(courseID: courseId, tasks: tasks)
        
        #expect(grade == 80.0, "Should ignore zero-weight tasks")
    }
    
    @Test func testEdgeCase_ExtraCredit() async throws {
        let courseId = UUID()
        let tasks = [
            createGradedTask(courseId: courseId, earned: 110, possible: 100, weight: 100)
        ]
        
        let grade = GradeCalculator.calculateCourseGrade(courseID: courseId, tasks: tasks)
        
        #expect(grade! >= 100.0, "Should handle extra credit")
    }
    
    // MARK: Dependency Edge Cases
    
    @Test func testEdgeCase_SelfReferencingDependency() async throws {
        var plan = AssignmentPlan(assignmentId: UUID(), sequenceEnforcementEnabled: true)
        
        var step = PlanStep(id: UUID(), planId: plan.id, title: "Step", estimatedDuration: 3600, sequenceIndex: 0)
        step.prerequisiteIds = [step.id]  // Self-reference
        
        plan.steps = [step]
        
        let cycle = plan.detectCycle()
        #expect(cycle != nil, "Should detect self-referencing as cycle")
    }
    
    @Test func testEdgeCase_LongDependencyChain() async throws {
        var plan = AssignmentPlan(assignmentId: UUID(), sequenceEnforcementEnabled: true)
        
        var steps: [PlanStep] = []
        for i in 0..<100 {
            let step = PlanStep(id: UUID(), planId: plan.id, title: "Step \(i)", estimatedDuration: 600, sequenceIndex: i)
            steps.append(step)
        }
        
        plan.steps = steps
        plan.setupLinearChain()
        
        #expect(plan.steps.count == 100, "Should handle long chains")
        #expect(plan.steps[99].prerequisiteIds.count == 1, "Last step should depend on second-to-last")
    }
    
    @Test func testEdgeCase_ComplexDependencyGraph() async throws {
        var plan = AssignmentPlan(assignmentId: UUID(), sequenceEnforcementEnabled: true)
        
        let step1 = PlanStep(id: UUID(), planId: plan.id, title: "Step 1", estimatedDuration: 3600, sequenceIndex: 0)
        var step2 = PlanStep(id: UUID(), planId: plan.id, title: "Step 2", estimatedDuration: 3600, sequenceIndex: 1)
        var step3 = PlanStep(id: UUID(), planId: plan.id, title: "Step 3", estimatedDuration: 3600, sequenceIndex: 2)
        var step4 = PlanStep(id: UUID(), planId: plan.id, title: "Step 4", estimatedDuration: 3600, sequenceIndex: 3)
        
        step2.prerequisiteIds = [step1.id]
        step3.prerequisiteIds = [step1.id]
        step4.prerequisiteIds = [step2.id, step3.id]
        
        plan.steps = [step1, step2, step3, step4]
        
        let sorted = plan.topologicalSort()
        #expect(sorted != nil, "Should handle complex dependencies")
        
        if let sorted = sorted {
            #expect(sorted[0].id == step1.id, "Step 1 should be first")
            #expect(sorted[3].id == step4.id, "Step 4 should be last")
        }
    }
    
    @Test func testEdgeCase_MultipleDependencyCycles() async throws {
        var plan = AssignmentPlan(assignmentId: UUID(), sequenceEnforcementEnabled: true)
        
        var step1 = PlanStep(id: UUID(), planId: plan.id, title: "Step 1", estimatedDuration: 3600, sequenceIndex: 0)
        var step2 = PlanStep(id: UUID(), planId: plan.id, title: "Step 2", estimatedDuration: 3600, sequenceIndex: 1)
        var step3 = PlanStep(id: UUID(), planId: plan.id, title: "Step 3", estimatedDuration: 3600, sequenceIndex: 2)
        var step4 = PlanStep(id: UUID(), planId: plan.id, title: "Step 4", estimatedDuration: 3600, sequenceIndex: 3)
        
        step1.prerequisiteIds = [step2.id]
        step2.prerequisiteIds = [step1.id]
        step3.prerequisiteIds = [step4.id]
        step4.prerequisiteIds = [step3.id]
        
        plan.steps = [step1, step2, step3, step4]
        
        let cycle = plan.detectCycle()
        #expect(cycle != nil, "Should detect at least one cycle")
    }
    
    // MARK: Category-Specific Edge Cases
    
    @Test func testEdgeCase_ExamWithMinimalLeadTime() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Last Minute Exam",
            dueDate: Date().addingTimeInterval(24 * 60 * 60),
            estimatedMinutes: 240,
            category: .exam,
            urgency: .critical,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(!plan.steps.isEmpty, "Should handle short lead time for exams")
    }
    
    @Test func testEdgeCase_ProjectWithoutCustomPlan() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Generic Project",
            dueDate: Date().addingTimeInterval(14 * 24 * 60 * 60),
            estimatedMinutes: 300,
            category: .project,
            urgency: .medium,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(plan.steps.count >= 4, "Should generate default project phases")
    }
    
    @Test func testEdgeCase_ReadingWithSinglePage() async throws {
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "One Page Reading",
            dueDate: Date().addingTimeInterval(24 * 60 * 60),
            estimatedMinutes: 10,
            category: .reading,
            urgency: .low,
            plan: []
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        #expect(plan.steps.count == 1, "Short reading should be single session")
    }
    
    // MARK: - Helper Methods
    
    private func createGradedTask(courseId: UUID, earned: Double, possible: Double, weight: Double) -> AppTask {
        var task = AppTask()
        task.id = UUID()
        task.courseId = courseId
        task.isCompleted = true
        task.gradeEarnedPoints = earned
        task.gradePossiblePoints = possible
        task.gradeWeightPercent = weight
        return task
    }
}
