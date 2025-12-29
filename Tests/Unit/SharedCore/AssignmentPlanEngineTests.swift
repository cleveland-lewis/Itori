import Testing
import Foundation
@testable import Roots

@MainActor
struct AssignmentPlanEngineTests {
    
    // MARK: - Determinism Tests
    
    @Test func testDeterministicPlanGeneration() async throws {
        let assignmentId = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        let dueDate = Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 31))!
        
        let assignment = Assignment(
            id: assignmentId,
            courseId: nil,
            title: "Math Final",
            dueDate: dueDate,
            estimatedMinutes: 240,
            category: .exam,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan1 = AssignmentPlanEngine.generatePlan(for: assignment)
        let plan2 = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan1.steps.count == plan2.steps.count)
        
        for (step1, step2) in zip(plan1.steps, plan2.steps) {
            #expect(step1.title == step2.title)
            #expect(step1.estimatedDuration == step2.estimatedDuration)
            #expect(step1.sequenceIndex == step2.sequenceIndex)
            #expect(step1.stepType == step2.stepType)
        }
    }
    
    @Test func testDeterministicExamPlan() async throws {
        let dueDate = Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 25))!
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Physics Exam",
            dueDate: dueDate,
            estimatedMinutes: 240,
            category: .exam,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count >= 3)
        #expect(plan.steps.count <= 6)
        
        for step in plan.steps {
            #expect(step.estimatedDuration > 0)
            #expect(step.recommendedStartDate != nil)
        }
        
        let sortedSteps = plan.steps.sorted { $0.sequenceIndex < $1.sequenceIndex }
        for (index, step) in sortedSteps.enumerated() {
            #expect(step.sequenceIndex == index)
        }
    }
    
    // MARK: - Category-Specific Tests
    
    @Test func testExamPlanGeneration() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Calculus Final",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 240,
            urgency: .critical,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count >= 3)
        #expect(plan.steps.first?.stepType == .review)
        #expect(plan.steps.last?.stepType == .review)
        
        let totalDuration = plan.steps.reduce(0.0) { $0 + $1.estimatedDuration }
        #expect(totalDuration >= TimeInterval(240 * 60))
    }
    
    @Test func testQuizPlanGeneration() async throws {
        let dueDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Chemistry Quiz",
            courseId: nil,
            category: .quiz,
            dueDate: dueDate,
            estimatedMinutes: 90,
            urgency: .medium,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count >= 1)
        #expect(plan.steps.count <= 3)
        
        for step in plan.steps {
            #expect(step.estimatedDuration <= TimeInterval(90 * 60))
        }
    }
    
    @Test func testHomeworkShortSession() async throws {
        let dueDate = Date().addingTimeInterval(2 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Math Problem Set",
            courseId: nil,
            category: .homework,
            dueDate: dueDate,
            estimatedMinutes: 45,
            urgency: .medium,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count == 1)
        #expect(plan.steps.first?.stepType == .task)
        #expect(plan.steps.first?.estimatedDuration == TimeInterval(45 * 60))
    }
    
    @Test func testHomeworkLongSessionSplit() async throws {
        let dueDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Biology Lab Report",
            courseId: nil,
            category: .homework,
            dueDate: dueDate,
            estimatedMinutes: 150,
            urgency: .medium,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count > 1)
        
        let totalDuration = plan.steps.reduce(0.0) { $0 + $1.estimatedDuration }
        #expect(abs(totalDuration - TimeInterval(150 * 60)) < 60)
    }
    
    @Test func testReadingPlanGeneration() async throws {
        let dueDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Chapter 5-7",
            courseId: nil,
            category: .reading,
            dueDate: dueDate,
            estimatedMinutes: 90,
            urgency: .low,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count >= 1)
        
        for step in plan.steps {
            #expect(step.stepType == .reading)
        }
    }
    
    @Test func testProjectPlanGeneration() async throws {
        let dueDate = Date().addingTimeInterval(14 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Final Project",
            courseId: nil,
            category: .project,
            dueDate: dueDate,
            estimatedMinutes: 400,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count >= 4)
        #expect(plan.steps.first?.stepType == .research)
        #expect(plan.steps.last?.stepType == .review)
    }
    
    @Test func testProjectWithExistingPlan() async throws {
        let dueDate = Date().addingTimeInterval(14 * 24 * 60 * 60)
        let customPlan = [
            PlanStepStub(title: "Research Phase", expectedMinutes: 120),
            PlanStepStub(title: "Design Phase", expectedMinutes: 90),
            PlanStepStub(title: "Implementation", expectedMinutes: 180),
            PlanStepStub(title: "Testing", expectedMinutes: 60)
        ]
        
        let assignment = Assignment(
            id: UUID(),
            title: "Custom Project",
            courseId: nil,
            category: .project,
            dueDate: dueDate,
            estimatedMinutes: 450,
            urgency: .high,
            plan: customPlan,
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count == 4)
        #expect(plan.steps[0].title == "Research Phase")
        #expect(plan.steps[1].title == "Design Phase")
        #expect(plan.steps[2].title == "Implementation")
        #expect(plan.steps[3].title == "Testing")
    }
    
    // MARK: - Edge Cases
    
    @Test func testMinimalDuration() async throws {
        let dueDate = Date().addingTimeInterval(24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Quick Task",
            courseId: nil,
            category: .homework,
            dueDate: dueDate,
            estimatedMinutes: 5,
            urgency: .low,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count == 1)
        #expect(plan.steps.first?.estimatedDuration >= TimeInterval(15 * 60))
    }
    
    @Test func testVeryLongExam() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Comprehensive Final",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 600,
            urgency: .critical,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(plan.steps.count >= 3)
        #expect(plan.steps.count <= 6)
    }
    
    @Test func testNearDueDate() async throws {
        let dueDate = Date().addingTimeInterval(12 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Urgent Task",
            courseId: nil,
            category: .quiz,
            dueDate: dueDate,
            estimatedMinutes: 60,
            urgency: .critical,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        #expect(!plan.steps.isEmpty)
        
        for step in plan.steps {
            if let dueBy = step.dueBy {
                #expect(dueBy <= dueDate)
            }
        }
    }
    
    // MARK: - Timing Tests
    
    @Test func testStepTimingConsistency() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "History Exam",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 240,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        for i in 0..<(plan.steps.count - 1) {
            let currentStep = plan.steps[i]
            let nextStep = plan.steps[i + 1]
            
            if let currentStart = currentStep.recommendedStartDate,
               let nextStart = nextStep.recommendedStartDate {
                #expect(nextStart >= currentStart)
            }
        }
        
        if let lastStep = plan.steps.last,
           let lastDue = lastStep.dueBy {
            #expect(lastDue <= dueDate || abs(lastDue.timeIntervalSince(dueDate)) < 60)
        }
    }
    
    @Test func testCustomSettings() async throws {
        var settings = PlanGenerationSettings.default
        settings.examLeadDays = 10
        settings.examSessionMinutes = 90
        
        let dueDate = Date().addingTimeInterval(10 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Advanced Math",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 360,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment, settings: settings)
        
        #expect(!plan.steps.isEmpty)
        
        if let firstStep = plan.steps.first,
           let startDate = firstStep.recommendedStartDate {
            let daysDifference = Calendar.current.dateComponents([.day], from: startDate, to: dueDate).day ?? 0
            #expect(daysDifference >= 9)
        }
    }
    
    // MARK: - Step Type Tests
    
    @Test func testExamStepTypes() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Test",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 240,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        var hasReview = false
        var hasPractice = false
        
        for step in plan.steps {
            switch step.stepType {
            case .review:
                hasReview = true
            case .practice:
                hasPractice = true
            default:
                break
            }
        }
        
        #expect(hasReview)
    }
    
    @Test func testProjectStepTypes() async throws {
        let dueDate = Date().addingTimeInterval(14 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Project",
            courseId: nil,
            category: .project,
            dueDate: dueDate,
            estimatedMinutes: 400,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )
        
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
        
        var hasResearch = false
        var hasPreparation = false
        var hasReview = false
        
        for step in plan.steps {
            switch step.stepType {
            case .research:
                hasResearch = true
            case .preparation:
                hasPreparation = true
            case .review:
                hasReview = true
            default:
                break
            }
        }
        
        #expect(hasResearch)
        #expect(hasPreparation)
        #expect(hasReview)
    }
}
