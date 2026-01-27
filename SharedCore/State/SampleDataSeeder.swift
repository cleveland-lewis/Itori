import Foundation

@MainActor
enum SampleDataSeeder {
    private enum SampleIds {
        static let fallSemester = UUID(uuidString: "E4B0F2C5-0F4C-4D5A-9F5B-3E57A2D1F101")!
        static let springSemester = UUID(uuidString: "A0C7F676-0B56-4E9D-9E08-2F4D6F4B9A02")!

        static let courseAlgorithms = UUID(uuidString: "8B4CFE5B-CC6B-4D47-8E40-0A7B2E6D2401")!
        static let coursePsych = UUID(uuidString: "37A23F5A-9A92-4F0B-8F61-5A7B9A1D2402")!
        static let courseBio = UUID(uuidString: "5D6E4F2B-3B5A-4BB5-9C10-8C7D6B1F2403")!

        static let taskProblemSet = UUID(uuidString: "7F32F57A-8A61-4F7A-A4AD-67E9A1D12401")!
        static let taskMidterm = UUID(uuidString: "C0B5E4B4-6C1B-4F0B-A9B2-0F9D8E2F2402")!
        static let taskLabReport = UUID(uuidString: "1B9E6D33-54B0-4F7B-8D8C-7E2C0A5D2403")!
        static let taskQuiz = UUID(uuidString: "4C2E9A77-1B2C-4C63-A36C-1F9E8B6D2404")!
        static let taskEssay = UUID(uuidString: "D2E8B1E0-2F1C-4A7A-9B6D-3C2E8F1D2405")!
        static let taskProject = UUID(uuidString: "2F6A9C6B-3A2D-4C2E-9A8B-6E2F1D0C2406")!
    }

    static func apply(
        enabled: Bool,
        coursesStore: CoursesStore,
        assignmentsStore: AssignmentsStore,
        gradesStore: GradesStore
    ) {
        _ = gradesStore
        if enabled {
            seed(coursesStore: coursesStore, assignmentsStore: assignmentsStore, gradesStore: gradesStore)
        } else {
            remove(coursesStore: coursesStore, assignmentsStore: assignmentsStore, gradesStore: gradesStore)
        }
    }

    private static func seed(
        coursesStore: CoursesStore,
        assignmentsStore: AssignmentsStore,
        gradesStore: GradesStore
    ) {
        _ = gradesStore
        let now = Date()
        let calendar = Calendar.current

        let currentSemester = makeSemester(
            reference: now,
            id: SampleIds.fallSemester,
            isCurrent: true
        )
        let nextSemesterStart = calendar.date(byAdding: .day, value: 1, to: currentSemester.endDate) ?? now
        let nextSemester = makeSemester(
            reference: nextSemesterStart,
            id: SampleIds.springSemester,
            isCurrent: false
        )

        if !coursesStore.semesters.contains(where: { $0.id == currentSemester.id }) {
            coursesStore.addSemester(currentSemester)
        }
        if !coursesStore.semesters.contains(where: { $0.id == nextSemester.id }) {
            coursesStore.addSemester(nextSemester)
        }

        let courses = [
            Course(
                id: SampleIds.courseAlgorithms,
                title: "Algorithms & Data Structures",
                code: "CS 301",
                semesterId: currentSemester.id,
                colorHex: "#3B82F6",
                courseType: .regular,
                instructor: "Dr. Maya Patel",
                location: "Engineering Hall 210",
                credits: 3,
                creditType: .credits,
                meetingTimes: "MWF 10:00–10:50 AM",
                notes: "Weekly problem sets + labs"
            ),
            Course(
                id: SampleIds.coursePsych,
                title: "Cognitive Psychology",
                code: "PSY 242",
                semesterId: currentSemester.id,
                colorHex: "#F97316",
                courseType: .seminar,
                instructor: "Prof. Daniel Kim",
                location: "Social Sciences 114",
                credits: 3,
                creditType: .credits,
                meetingTimes: "T/Th 1:30–2:45 PM",
                notes: "Weekly readings + reflections"
            ),
            Course(
                id: SampleIds.courseBio,
                title: "Human Biology Lab",
                code: "BIO 118L",
                semesterId: currentSemester.id,
                colorHex: "#10B981",
                courseType: .lab,
                instructor: "Dr. Elise Romero",
                location: "Science Annex 32",
                credits: 1,
                creditType: .credits,
                meetingTimes: "W 2:00–4:50 PM",
                notes: "Lab reports due Fridays"
            )
        ]

        for course in courses where !coursesStore.courses.contains(where: { $0.id == course.id }) {
            coursesStore.addCourse(course)
        }

        let tasks = makeSampleTasks(now: now)
        let existingTaskIds = Set(assignmentsStore.tasks.map(\.id))
        for task in tasks where !existingTaskIds.contains(task.id) {
            assignmentsStore.addTask(task)
        }

        coursesStore.recalcGPA(tasks: assignmentsStore.tasks)
    }

    private static func remove(
        coursesStore: CoursesStore,
        assignmentsStore: AssignmentsStore,
        gradesStore: GradesStore
    ) {
        _ = gradesStore
        let sampleTaskIds: Set<UUID> = [
            SampleIds.taskProblemSet,
            SampleIds.taskMidterm,
            SampleIds.taskLabReport,
            SampleIds.taskQuiz,
            SampleIds.taskEssay,
            SampleIds.taskProject
        ]
        let sampleCourseIds: [UUID] = [
            SampleIds.courseAlgorithms,
            SampleIds.coursePsych,
            SampleIds.courseBio
        ]
        let sampleSemesterIds: [UUID] = [
            SampleIds.fallSemester,
            SampleIds.springSemester
        ]

        assignmentsStore.tasks = assignmentsStore.tasks.filter { !sampleTaskIds.contains($0.id) }

        for courseId in sampleCourseIds {
            if let course = coursesStore.courses.first(where: { $0.id == courseId }) {
                coursesStore.deleteCourse(course)
            }
        }

        for semesterId in sampleSemesterIds {
            coursesStore.permanentlyDeleteSemester(semesterId)
        }

        coursesStore.recalcGPA(tasks: assignmentsStore.tasks)
    }

    private static func makeSemester(
        reference: Date,
        id: UUID,
        isCurrent: Bool
    ) -> Semester {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: reference)

        let term: SemesterType = switch month {
        case 1 ... 3:
            .spring
        case 4 ... 6:
            .summerI
        case 7 ... 8:
            .summerII
        default:
            .fall
        }

        let startDate = calendar.date(byAdding: .month, value: -2, to: reference) ?? reference
        let endDate = calendar.date(byAdding: .month, value: 4, to: reference) ?? reference
        let year = calendar.component(.year, from: startDate)
        let nextYear = year + 1
        let academicYear = "\(year)-\(nextYear)"

        return Semester(
            id: id,
            startDate: startDate,
            endDate: endDate,
            isCurrent: isCurrent,
            educationLevel: .college,
            semesterTerm: term,
            academicYear: academicYear,
            notes: "Sample semester data"
        )
    }

    private static func makeSampleTasks(now: Date) -> [AppTask] {
        let calendar = Calendar.current
        let dueInDays: (Int) -> Date? = { days in
            calendar.date(byAdding: .day, value: days, to: now)
        }

        return [
            AppTask(
                id: SampleIds.taskProblemSet,
                title: "Problem Set 3",
                courseId: SampleIds.courseAlgorithms,
                due: dueInDays(3),
                estimatedMinutes: 120,
                minBlockMinutes: 30,
                maxBlockMinutes: 90,
                difficulty: 0.7,
                importance: 0.7,
                type: .homework,
                locked: false,
                gradeWeightPercent: 5,
                category: .homework,
                dueTimeMinutes: 1020,
                sourceUniqueKey: "SAMPLE_DATA_DO_NOT_SYNC",
                notes: "Focus on recursion + memoization"
            ),
            AppTask(
                id: SampleIds.taskMidterm,
                title: "Midterm 1 Review",
                courseId: SampleIds.courseAlgorithms,
                due: dueInDays(10),
                estimatedMinutes: 240,
                minBlockMinutes: 60,
                maxBlockMinutes: 120,
                difficulty: 0.85,
                importance: 0.9,
                type: .exam,
                locked: false,
                gradeWeightPercent: 20,
                category: .exam,
                dueTimeMinutes: 1080,
                sourceUniqueKey: "SAMPLE_DATA_DO_NOT_SYNC",
                notes: "Practice sets + past exams"
            ),
            AppTask(
                id: SampleIds.taskLabReport,
                title: "Lab Report: Cardiovascular System",
                courseId: SampleIds.courseBio,
                due: dueInDays(5),
                estimatedMinutes: 150,
                minBlockMinutes: 45,
                maxBlockMinutes: 90,
                difficulty: 0.6,
                importance: 0.8,
                type: .project,
                locked: false,
                gradeWeightPercent: 10,
                category: .project,
                dueTimeMinutes: 900,
                sourceUniqueKey: "SAMPLE_DATA_DO_NOT_SYNC",
                notes: "Include annotated graphs + summary"
            ),
            AppTask(
                id: SampleIds.taskQuiz,
                title: "Quiz 2: Memory Systems",
                courseId: SampleIds.coursePsych,
                due: dueInDays(-4),
                estimatedMinutes: 45,
                minBlockMinutes: 20,
                maxBlockMinutes: 45,
                difficulty: 0.4,
                importance: 0.6,
                type: .quiz,
                locked: false,
                isCompleted: true,
                gradeWeightPercent: 8,
                gradePossiblePoints: 20,
                gradeEarnedPoints: 18,
                category: .quiz,
                dueTimeMinutes: 780,
                sourceUniqueKey: "SAMPLE_DATA_DO_NOT_SYNC",
                notes: "Completed in-class"
            ),
            AppTask(
                id: SampleIds.taskEssay,
                title: "Reading Reflection: Attention",
                courseId: SampleIds.coursePsych,
                due: dueInDays(-2),
                estimatedMinutes: 90,
                minBlockMinutes: 30,
                maxBlockMinutes: 60,
                difficulty: 0.5,
                importance: 0.5,
                type: .reading,
                locked: false,
                isCompleted: true,
                gradeWeightPercent: 6,
                gradePossiblePoints: 100,
                gradeEarnedPoints: 92,
                category: .reading,
                dueTimeMinutes: 1140,
                sourceUniqueKey: "SAMPLE_DATA_DO_NOT_SYNC",
                notes: "Submit with citations"
            ),
            AppTask(
                id: SampleIds.taskProject,
                title: "Group Presentation: Neural Imaging",
                courseId: SampleIds.courseBio,
                due: dueInDays(14),
                estimatedMinutes: 180,
                minBlockMinutes: 60,
                maxBlockMinutes: 120,
                difficulty: 0.75,
                importance: 0.85,
                type: .project,
                locked: false,
                gradeWeightPercent: 15,
                category: .project,
                dueTimeMinutes: 960,
                sourceUniqueKey: "SAMPLE_DATA_DO_NOT_SYNC",
                notes: "Coordinate slides + speaking roles"
            )
        ]
    }
}
