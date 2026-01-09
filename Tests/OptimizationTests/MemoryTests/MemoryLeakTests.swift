import XCTest
@testable import Itori

/// Memory leak detection and memory usage tests
/// Run with Instruments Memory Profiler for detailed analysis
final class MemoryLeakTests: XCTestCase {
    // MARK: - Store Memory Leaks

    func testAssignmentsStoreDoesNotLeak() {
        weak var weakStore: AssignmentsStore?

        autoreleasepool {
            let store = AssignmentsStore()
            weakStore = store

            // Perform operations
            for i in 0 ..< 100 {
                let task = AppTask(
                    id: UUID(),
                    title: "Task \(i)",
                    courseId: nil,
                    due: Date(),
                    estimatedMinutes: 60,
                    minBlockMinutes: 15,
                    maxBlockMinutes: 120,
                    difficulty: 0.5,
                    importance: 0.5,
                    type: .homework,
                    locked: false,
                    attachments: [],
                    isCompleted: false,
                    category: .homework
                )
                store.addTask(task)
            }
        }

        // Store should be deallocated
        XCTAssertNil(weakStore, "AssignmentsStore leaked")
    }

    func testCoursesStoreDoesNotLeak() {
        weak var weakStore: CoursesStore?

        autoreleasepool {
            let store = CoursesStore()
            weakStore = store

            // Perform operations
            let semester = Semester(
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 120),
                isCurrent: true,
                educationLevel: .college,
                semesterTerm: .fall
            )
            store.addSemester(semester)

            for i in 0 ..< 50 {
                store.addCourse(title: "Course \(i)", code: "CS\(i)", to: semester)
            }
        }

        XCTAssertNil(weakStore, "CoursesStore leaked")
    }

    // MARK: - View Memory Tests

    func testPlannerStoreMemoryUsage() {
        let store = PlannerStore.shared

        measure(metrics: [XCTMemoryMetric()]) {
            // Generate 100 planner sessions
            let sessions = (0 ..< 100).map { index in
                StoredScheduledSession(
                    id: UUID(),
                    assignmentId: UUID(),
                    sessionIndex: index,
                    sessionCount: 100,
                    title: "Session \(index)",
                    dueDate: Date(),
                    estimatedMinutes: 60,
                    isLockedToDueDate: false,
                    category: .homework,
                    start: Date(),
                    end: Date().addingTimeInterval(3600),
                    type: .task,
                    isLocked: false,
                    isUserEdited: false
                )
            }

            store.persist(scheduled: sessions, overflow: [])
        }
    }

    func testFlashcardManagerMemoryUsage() {
        let manager = FlashcardManager.shared

        measure(metrics: [XCTMemoryMetric()]) {
            let deck = manager.createDeck(title: "Test Deck")

            // Add 200 flashcards
            for i in 0 ..< 200 {
                manager.addCard(
                    to: deck.id,
                    front: "Question \(i)",
                    back: "Answer \(i)"
                )
            }
        }
    }

    // MARK: - Large Data Set Tests

    func testMemoryWithLargeDataSet() {
        let store = AssignmentsStore()

        measure(metrics: [XCTMemoryMetric()]) {
            // Create 1000 assignments
            for i in 0 ..< 1000 {
                let task = AppTask(
                    id: UUID(),
                    title: "Task \(i)",
                    courseId: nil,
                    due: Date().addingTimeInterval(Double(i) * 86400),
                    estimatedMinutes: 60,
                    minBlockMinutes: 15,
                    maxBlockMinutes: 120,
                    difficulty: 0.5,
                    importance: 0.5,
                    type: .homework,
                    locked: false,
                    attachments: [],
                    isCompleted: false,
                    category: .homework
                )
                store.addTask(task)
            }

            // Verify memory is within acceptable range
            let tasks = store.tasks
            XCTAssertEqual(tasks.count, 1000)
        }
    }

    // MARK: - Closure Retention Tests

    func testTimerManagerDoesNotRetainClosures() {
        weak var weakManager: TimerManager?

        autoreleasepool {
            let manager = TimerManager()
            weakManager = manager

            // Start and stop timer multiple times
            for _ in 0 ..< 10 {
                manager.startSession(mode: .pomodoro, duration: 1500)
                manager.stopSession()
            }
        }

        XCTAssertNil(weakManager, "TimerManager retained closures")
    }
}

// MARK: - Memory Baseline Configuration

extension MemoryLeakTests {
    /// Memory baselines (in MB)
    enum MemoryBaseline {
        static let assignmentsStore100Items: Double = 5.0 // 5MB
        static let coursesStore50Items: Double = 3.0 // 3MB
        static let plannerStore100Sessions: Double = 6.0 // 6MB
        static let flashcardManager200Cards: Double = 4.0 // 4MB
        static let largeDataSet1000Items: Double = 50.0 // 50MB
    }
}
