import Foundation
@testable import Itori

/// Deterministic test data factory for optimization tests
/// Ensures reproducible performance measurements
enum TestDataFactory {
    // MARK: - Deterministic Seeds

    static func generateCourses(count: Int, seed: Int = 42) -> [Course] {
        var courses: [Course] = []
        var rng = SeededRandomNumberGenerator(seed: seed)

        let semester = Semester(
            startDate: Date(timeIntervalSince1970: 1_704_067_200), // 2024-01-01
            endDate: Date(timeIntervalSince1970: 1_717_200_000), // 2024-06-01
            isCurrent: true,
            educationLevel: .college,
            semesterTerm: .spring
        )

        for i in 0 ..< count {
            let course = Course(
                title: "Course \(i)",
                code: "CS\(100 + i)",
                instructor: "Professor \(i % 10)",
                location: "Room \(100 + (i % 50))",
                credits: Double([3, 4].randomElement(using: &rng)!),
                colorHex: ColorPreset.allCases.randomElement(using: &rng)!.hexValue,
                semesterId: semester.id
            )
            courses.append(course)
        }

        return courses
    }

    static func generateAssignments(count: Int, courses: [Course], seed: Int = 42) -> [AppTask] {
        var tasks: [AppTask] = []
        var rng = SeededRandomNumberGenerator(seed: seed)

        let now = Date(timeIntervalSince1970: 1_704_067_200) // Fixed timestamp
        let types: [TaskType] = [.homework, .quiz, .exam, .project, .reading, .review]

        for i in 0 ..< count {
            let daysOffset = Int.random(in: -30 ... 60, using: &rng)
            let dueDate = now.addingTimeInterval(Double(daysOffset) * 86400)

            let task = AppTask(
                id: UUID(),
                title: "Assignment \(i): \(types.randomElement(using: &rng)!.rawValue)",
                courseId: courses.randomElement(using: &rng)?.id,
                due: dueDate,
                estimatedMinutes: [30, 45, 60, 90, 120].randomElement(using: &rng)!,
                minBlockMinutes: 15,
                maxBlockMinutes: 120,
                difficulty: Double.random(in: 0.3 ... 0.9, using: &rng),
                importance: Double.random(in: 0.3 ... 0.9, using: &rng),
                type: types.randomElement(using: &rng)!,
                locked: Bool.random(using: &rng),
                attachments: [],
                isCompleted: daysOffset < -7 ? Bool.random(using: &rng) : false,
                category: [.homework, .quiz, .exam, .project].randomElement(using: &rng)!
            )

            tasks.append(task)
        }

        return tasks
    }

    static func generatePlannerSessions(count: Int, seed: Int = 42) -> [StoredScheduledSession] {
        var sessions: [StoredScheduledSession] = []
        var rng = SeededRandomNumberGenerator(seed: seed)

        let baseDate = Date(timeIntervalSince1970: 1_704_067_200)

        for i in 0 ..< count {
            let startOffset = Double(i) * 3600 // 1 hour apart
            let start = baseDate.addingTimeInterval(startOffset)
            let duration = [30, 60, 90].randomElement(using: &rng)!
            let end = start.addingTimeInterval(Double(duration) * 60)

            let session = StoredScheduledSession(
                id: UUID(),
                assignmentId: UUID(),
                sessionIndex: i,
                sessionCount: count,
                title: "Study Session \(i)",
                dueDate: end.addingTimeInterval(86400 * 7),
                estimatedMinutes: duration,
                isLockedToDueDate: false,
                category: [.homework, .quiz, .exam, .project].randomElement(using: &rng)!,
                start: start,
                end: end,
                type: .task,
                isLocked: false,
                isUserEdited: false
            )

            sessions.append(session)
        }

        return sessions
    }

    static func generateFlashcardDeck(cardCount: Int, seed: Int = 42) -> FlashcardDeck {
        var rng = SeededRandomNumberGenerator(seed: seed)

        var deck = FlashcardDeck(title: "Test Deck \(seed)", courseID: nil)

        for i in 0 ..< cardCount {
            let difficulty: FlashcardDifficulty = [.easy, .medium, .hard].randomElement(using: &rng)!
            let card = Flashcard(
                frontText: "Question \(i)",
                backText: "Answer \(i)",
                difficulty: difficulty,
                dueDate: Date().addingTimeInterval(Double(i) * 86400)
            )
            deck.cards.append(card)
        }

        return deck
    }

    // MARK: - Preset Data Sets

    enum Preset {
        case small // 10 courses, 50 assignments
        case medium // 50 courses, 200 assignments
        case large // 100 courses, 1000 assignments
        case xlarge // 200 courses, 5000 assignments

        var courseCount: Int {
            switch self {
            case .small: 10
            case .medium: 50
            case .large: 100
            case .xlarge: 200
            }
        }

        var assignmentCount: Int {
            switch self {
            case .small: 50
            case .medium: 200
            case .large: 1000
            case .xlarge: 5000
            }
        }
    }

    static func generateDataSet(_ preset: Preset, seed: Int = 42) -> (courses: [Course], assignments: [AppTask]) {
        let courses = generateCourses(count: preset.courseCount, seed: seed)
        let assignments = generateAssignments(count: preset.assignmentCount, courses: courses, seed: seed + 1)
        return (courses, assignments)
    }
}

// MARK: - Seeded Random Number Generator

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(seed)
    }

    mutating func next() -> UInt64 {
        // Linear congruential generator
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

// MARK: - Color Preset Extension

extension ColorPreset {
    var hexValue: String {
        switch self {
        case .blue: "#007AFF"
        case .green: "#34C759"
        case .indigo: "#5856D6"
        case .orange: "#FF9500"
        case .pink: "#FF2D55"
        case .purple: "#AF52DE"
        case .red: "#FF3B30"
        case .teal: "#5AC8FA"
        case .yellow: "#FFCC00"
        case .gray: "#8E8E93"
        case .brown: "#A2845E"
        case .cyan: "#32ADE6"
        case .mint: "#00C7BE"
        }
    }
}

// MARK: - Random Extension

extension RandomNumberGenerator {
    mutating func random<T>(in range: ClosedRange<T>) -> T where T: FixedWidthInteger {
        let delta = range.upperBound - range.lowerBound
        let random = T(next() % UInt64(delta + 1))
        return range.lowerBound + random
    }

    mutating func random(in range: ClosedRange<Double>) -> Double {
        let random = Double(next()) / Double(UInt64.max)
        return range.lowerBound + (random * (range.upperBound - range.lowerBound))
    }
}
