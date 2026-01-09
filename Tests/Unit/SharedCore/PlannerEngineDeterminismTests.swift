import Foundation
import Testing
@testable import Itori

@MainActor
struct PlannerEngineDeterminismTests {
    // MARK: - Determinism Tests

    @Test func deterministicSessionGeneration() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            title: "Test Assignment",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 240,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )

        let settings = StudyPlanSettings()

        let sessions1 = PlannerEngine.generateSessions(for: assignment, settings: settings)
        let sessions2 = PlannerEngine.generateSessions(for: assignment, settings: settings)

        #expect(sessions1.count == sessions2.count)

        for (s1, s2) in zip(sessions1, sessions2) {
            #expect(s1.title == s2.title)
            #expect(s1.estimatedMinutes == s2.estimatedMinutes)
            #expect(s1.sessionIndex == s2.sessionIndex)
            #expect(s1.sessionCount == s2.sessionCount)
            #expect(s1.category == s2.category)
        }
    }

    @Test func deterministicScheduling() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Math Final",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 240,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        let energyProfile = [
            9: 0.7,
            10: 0.8,
            11: 0.9,
            12: 0.7,
            13: 0.6,
            14: 0.7,
            15: 0.8,
            16: 0.9,
            17: 0.7,
            18: 0.6,
            19: 0.5,
            20: 0.4
        ]

        let result1 = PlannerEngine.scheduleSessions(sessions, settings: settings, energyProfile: energyProfile)
        let result2 = PlannerEngine.scheduleSessions(sessions, settings: settings, energyProfile: energyProfile)

        #expect(result1.scheduled.count == result2.scheduled.count)
        #expect(result1.overflow.count == result2.overflow.count)

        for (sched1, sched2) in zip(result1.scheduled, result2.scheduled) {
            #expect(sched1.start == sched2.start)
            #expect(sched1.end == sched2.end)
            #expect(sched1.session.title == sched2.session.title)
        }
    }

    // MARK: - Session Generation Tests

    @Test func examSessionGeneration() async throws {
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Physics Exam",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 240,
            urgency: .critical,
            plan: [],
            isLockedToDueDate: false
        )

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        #expect(sessions.count >= 3)
        #expect(sessions.count <= 4)

        let totalMinutes = sessions.reduce(0) { $0 + $1.estimatedMinutes }
        #expect(totalMinutes >= 240)

        for (index, session) in sessions.enumerated() {
            #expect(session.sessionIndex == index + 1)
            #expect(session.sessionCount == sessions.count)
        }
    }

    @Test func quizSessionGeneration() async throws {
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

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        #expect(sessions.count >= 1)
        #expect(sessions.count <= 2)
    }

    @Test func homeworkShortSession() async throws {
        let dueDate = Date().addingTimeInterval(2 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Problem Set",
            courseId: nil,
            category: .homework,
            dueDate: dueDate,
            estimatedMinutes: 45,
            urgency: .medium,
            plan: [],
            isLockedToDueDate: false
        )

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        #expect(sessions.count == 1)
        #expect(sessions.first?.estimatedMinutes == 45)
    }

    @Test func homeworkLongSessionSplit() async throws {
        let dueDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Lab Report",
            courseId: nil,
            category: .homework,
            dueDate: dueDate,
            estimatedMinutes: 150,
            urgency: .medium,
            plan: [],
            isLockedToDueDate: false
        )

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        #expect(sessions.count > 1)

        let totalMinutes = sessions.reduce(0) { $0 + $1.estimatedMinutes }
        #expect(totalMinutes >= 150)
    }

    @Test func projectWithCustomPlan() async throws {
        let dueDate = Date().addingTimeInterval(14 * 24 * 60 * 60)
        let customPlan = [
            PlanStepStub(title: "Research", expectedMinutes: 60),
            PlanStepStub(title: "Design", expectedMinutes: 90),
            PlanStepStub(title: "Build", expectedMinutes: 120)
        ]

        let assignment = Assignment(
            id: UUID(),
            title: "Final Project",
            courseId: nil,
            category: .project,
            dueDate: dueDate,
            estimatedMinutes: 270,
            urgency: .high,
            plan: customPlan,
            isLockedToDueDate: false
        )

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        #expect(sessions.count == 3)
        #expect(sessions[0].title.contains("Research"))
        #expect(sessions[1].title.contains("Design"))
        #expect(sessions[2].title.contains("Build"))
    }

    // MARK: - Schedule Index Tests

    @Test func scheduleIndexCalculation() async throws {
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

        #expect(urgentIndex > normalIndex)
    }

    @Test func scheduleIndexConsistency() async throws {
        let today = Date()
        let session = PlannerSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "Test",
            dueDate: today.addingTimeInterval(5 * 24 * 60 * 60),
            category: .exam,
            importance: .high,
            difficulty: .high,
            estimatedMinutes: 60,
            isLockedToDueDate: false
        )

        let index1 = PlannerEngine.computeScheduleIndex(for: session, today: today)
        let index2 = PlannerEngine.computeScheduleIndex(for: session, today: today)

        #expect(index1 == index2)
        #expect(index1 >= 0.0)
        #expect(index1 <= 1.0)
    }

    // MARK: - Scheduling Constraint Tests

    @Test func schedulingWithinTimeWindow() async throws {
        let today = Date()
        let dueDate = today.addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Test",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 180,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        let energyProfile = [
            9: 0.7,
            10: 0.8,
            11: 0.9,
            12: 0.7,
            13: 0.6,
            14: 0.7,
            15: 0.8,
            16: 0.9,
            17: 0.7,
            18: 0.6,
            19: 0.5,
            20: 0.4
        ]

        let result = PlannerEngine.scheduleSessions(sessions, settings: settings, energyProfile: energyProfile)

        for scheduled in result.scheduled {
            #expect(scheduled.start <= scheduled.end)
            #expect(scheduled.start <= dueDate)

            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: scheduled.start)
            #expect(hour >= 9)
            #expect(hour <= 21)
        }
    }

    @Test func noOverlappingSessions() async throws {
        let today = Date()
        let dueDate = today.addingTimeInterval(7 * 24 * 60 * 60)

        let assignments = [
            Assignment(
                id: UUID(),
                title: "Math",
                courseId: nil,
                category: .exam,
                dueDate: dueDate,
                estimatedMinutes: 120,
                urgency: .high,
                plan: [],
                isLockedToDueDate: false
            ),
            Assignment(
                id: UUID(),
                title: "Physics",
                courseId: nil,
                category: .exam,
                dueDate: dueDate,
                estimatedMinutes: 120,
                urgency: .high,
                plan: [],
                isLockedToDueDate: false
            )
        ]

        let settings = StudyPlanSettings()
        var allSessions: [PlannerSession] = []

        for assignment in assignments {
            allSessions.append(contentsOf: PlannerEngine.generateSessions(for: assignment, settings: settings))
        }

        let energyProfile = [
            9: 0.7,
            10: 0.8,
            11: 0.9,
            12: 0.7,
            13: 0.6,
            14: 0.7,
            15: 0.8,
            16: 0.9,
            17: 0.7,
            18: 0.6,
            19: 0.5,
            20: 0.4
        ]

        let result = PlannerEngine.scheduleSessions(allSessions, settings: settings, energyProfile: energyProfile)

        for i in 0 ..< result.scheduled.count {
            for j in (i + 1) ..< result.scheduled.count {
                let s1 = result.scheduled[i]
                let s2 = result.scheduled[j]

                let noOverlap = s1.end <= s2.start || s2.end <= s1.start
                #expect(noOverlap)
            }
        }
    }

    @Test func energyProfileMatching() async throws {
        let today = Date()
        let dueDate = today.addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Difficult Task",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 60,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        let highEnergyProfile = [
            9: 0.9,
            10: 1.0,
            11: 1.0,
            12: 0.8,
            13: 0.6,
            14: 0.7,
            15: 0.8,
            16: 0.7,
            17: 0.5,
            18: 0.4,
            19: 0.3,
            20: 0.2
        ]

        let result = PlannerEngine.scheduleSessions(sessions, settings: settings, energyProfile: highEnergyProfile)

        for scheduled in result.scheduled {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: scheduled.start)

            if hour == 10 || hour == 11 {
                continue
            }
        }
    }

    @Test func energyLevelAdjustsTodayLoad() async throws {
        let originalEnergy = AppSettingsModel.shared.defaultEnergyLevel
        defer { AppSettingsModel.shared.defaultEnergyLevel = originalEnergy }

        let today = Date()
        let assignment = Assignment(
            id: UUID(),
            title: "Energy Load",
            courseId: nil,
            category: .homework,
            dueDate: today,
            estimatedMinutes: 600,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        let energyProfile = SchedulerPreferencesStore.shared.energyProfileForPlanning()

        AppSettingsModel.shared.defaultEnergyLevel = "Low"
        let lowResult = PlannerEngine.scheduleSessions(
            sessions,
            settings: StudyPlanSettings(),
            energyProfile: energyProfile
        )

        AppSettingsModel.shared.defaultEnergyLevel = "High"
        let highResult = PlannerEngine.scheduleSessions(
            sessions,
            settings: StudyPlanSettings(),
            energyProfile: energyProfile
        )

        #expect(highResult.scheduled.count >= lowResult.scheduled.count)
    }

    @Test func noSchedulingBeforeNow() async throws {
        let today = Date()
        let assignment = Assignment(
            id: UUID(),
            title: "No Past Slots",
            courseId: nil,
            category: .reading,
            dueDate: today,
            estimatedMinutes: 60,
            urgency: .high,
            plan: [],
            isLockedToDueDate: false
        )
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        let energyProfile = SchedulerPreferencesStore.shared.energyProfileForPlanning()
        let result = PlannerEngine.scheduleSessions(
            sessions,
            settings: StudyPlanSettings(),
            energyProfile: energyProfile
        )

        let now = Date()
        for scheduled in result.scheduled {
            if Calendar.current.isDate(scheduled.start, inSameDayAs: now) {
                #expect(scheduled.start >= now)
            }
        }
    }

    // MARK: - Overflow Tests

    @Test func overflowDetection() async throws {
        let today = Date()
        let tomorrow = today.addingTimeInterval(24 * 60 * 60)

        let assignments = (0 ..< 20).map { i in
            Assignment(
                id: UUID(),
                title: "Task \(i)",
                courseId: nil,
                category: .homework,
                dueDate: tomorrow,
                estimatedMinutes: 120,
                urgency: .high,
                plan: [],
                isLockedToDueDate: false
            )
        }

        let settings = StudyPlanSettings()
        var allSessions: [PlannerSession] = []

        for assignment in assignments {
            allSessions.append(contentsOf: PlannerEngine.generateSessions(for: assignment, settings: settings))
        }

        let energyProfile = [
            9: 0.7,
            10: 0.8,
            11: 0.9,
            12: 0.7,
            13: 0.6,
            14: 0.7,
            15: 0.8,
            16: 0.9,
            17: 0.7,
            18: 0.6,
            19: 0.5,
            20: 0.4
        ]

        let result = PlannerEngine.scheduleSessions(allSessions, settings: settings, energyProfile: energyProfile)

        #expect(!result.overflow.isEmpty)
    }

    // MARK: - Edge Cases

    @Test func emptySessionList() async throws {
        let settings = StudyPlanSettings()
        let energyProfile = [9: 0.7, 10: 0.8]

        let result = PlannerEngine.scheduleSessions([], settings: settings, energyProfile: energyProfile)

        #expect(result.scheduled.isEmpty)
        #expect(result.overflow.isEmpty)
    }

    @Test func singleSession() async throws {
        let today = Date()
        let dueDate = today.addingTimeInterval(2 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Quick Task",
            courseId: nil,
            category: .homework,
            dueDate: dueDate,
            estimatedMinutes: 30,
            urgency: .low,
            plan: [],
            isLockedToDueDate: false
        )

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        let energyProfile = [
            9: 0.7,
            10: 0.8,
            11: 0.9,
            12: 0.7,
            13: 0.6,
            14: 0.7,
            15: 0.8,
            16: 0.9,
            17: 0.7,
            18: 0.6,
            19: 0.5,
            20: 0.4
        ]

        let result = PlannerEngine.scheduleSessions(sessions, settings: settings, energyProfile: energyProfile)

        #expect(result.scheduled.count == 1)
        #expect(result.overflow.isEmpty)
    }

    @Test func lockedToDueDate() async throws {
        let today = Date()
        let dueDate = today.addingTimeInterval(7 * 24 * 60 * 60)
        let assignment = Assignment(
            id: UUID(),
            title: "Locked Task",
            courseId: nil,
            category: .exam,
            dueDate: dueDate,
            estimatedMinutes: 120,
            urgency: .critical,
            plan: [],
            isLockedToDueDate: true
        )

        let settings = StudyPlanSettings()
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: settings)

        for session in sessions {
            #expect(session.isLockedToDueDate == true)
        }
    }
}
