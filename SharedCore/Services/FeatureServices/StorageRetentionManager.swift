import Foundation

@MainActor
enum StorageRetentionManager {
    struct Result {
        let deletedCount: Int
        let deletedByType: [StorageEntityType: Int]
    }

    static func apply(
        policy: StorageRetentionPolicy,
        coursesStore: CoursesStore,
        assignmentsStore: AssignmentsStore,
        practiceStore: PracticeTestStore,
        gradesStore: GradesStore,
        focusManager: FocusManager,
        calendarManager: DeviceCalendarManager,
        aggregateStore: StorageAggregateStore,
        now: Date = Date()
    ) async -> Result {
        guard policy != .never else {
            return Result(deletedCount: 0, deletedByType: [:])
        }

        await computeAggregates(
            coursesStore: coursesStore,
            assignmentsStore: assignmentsStore,
            gradesStore: gradesStore,
            focusManager: focusManager,
            calendarManager: calendarManager,
            aggregateStore: aggregateStore,
            now: now
        )

        var deletedByType: [StorageEntityType: Int] = [:]

        func recordDeletion(type: StorageEntityType, date: Date) {
            aggregateStore.recordDeletion(type: type, date: date)
            deletedByType[type, default: 0] += 1
        }

        let semesterMap: [UUID: Semester] = Dictionary(uniqueKeysWithValues: coursesStore.semesters.map { ($0.id, $0) })
        let courseMap: [UUID: Course] = Dictionary(uniqueKeysWithValues: coursesStore.courses.map { ($0.id, $0) })

        let expiredSemesterIds: Set<UUID> = {
            if policy.isSemesterBased {
                return Set(
                    coursesStore.semesters
                        .filter { policy.isExpired(primaryDate: $0.endDate, semesterEnd: $0.endDate, now: now) }
                        .map(\.id)
                )
            }
            return []
        }()

        // Courses + related data
        let expiredCourses = coursesStore.courses.filter { course in
            let semesterEnd = semesterMap[course.semesterId]?.endDate
            let primaryDate = semesterEnd ?? now
            let isExpired = policy.isSemesterBased
                ? expiredSemesterIds.contains(course.semesterId)
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)

            return isExpired
        }
        for course in await batched(expiredCourses) {
            let semesterEnd = semesterMap[course.semesterId]?.endDate
            recordDeletion(type: .course, date: semesterEnd ?? now)
            coursesStore.deleteCourse(course)
            coursesStore.deleteCourseAssets(courseId: course.id)
        }

        // Semesters
        let expiredSemesters = coursesStore.semesters.filter { semester in
            let isExpired = policy.isSemesterBased
                ? expiredSemesterIds.contains(semester.id)
                : policy.isExpired(primaryDate: semester.endDate, semesterEnd: semester.endDate, now: now)
            return isExpired
        }
        for semester in await batched(expiredSemesters) {
            recordDeletion(type: .semester, date: semester.endDate)
            coursesStore.permanentlyDeleteSemester(semester.id)
        }

        // Assignments
        let expiredTasks = assignmentsStore.tasks.filter { task in
            let course = task.courseId.flatMap { courseMap[$0] }
            let semesterEnd = course.flatMap { semesterMap[$0.semesterId]?.endDate }
            let primaryDate = task.due ?? now
            let isExpired = policy.isSemesterBased
                ? (course?.semesterId).map { expiredSemesterIds.contains($0) } ?? false
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)
            return isExpired
        }
        for task in await batched(expiredTasks) {
            recordDeletion(type: .assignment, date: task.due ?? now)
            assignmentsStore.removeTask(id: task.id)
        }

        // Practice tests
        let expiredTests = practiceStore.tests.filter { test in
            let course = courseMap[test.courseId]
            let semesterEnd = course.flatMap { semesterMap[$0.semesterId]?.endDate }
            let primaryDate = test.createdAt
            let isExpired = policy.isSemesterBased
                ? (course?.semesterId).map { expiredSemesterIds.contains($0) } ?? false
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)
            return isExpired
        }
        for test in await batched(expiredTests) {
            recordDeletion(type: .practiceTest, date: test.createdAt)
            practiceStore.deleteTest(test.id)
        }

        // Course outline nodes
        let expiredNodes = coursesStore.outlineNodes.filter { node in
            let course = courseMap[node.courseId]
            let semesterEnd = course.flatMap { semesterMap[$0.semesterId]?.endDate }
            let primaryDate = node.createdAt
            let isExpired = policy.isSemesterBased
                ? (course?.semesterId).map { expiredSemesterIds.contains($0) } ?? false
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)
            return isExpired
        }
        for node in await batched(expiredNodes) {
            recordDeletion(type: .courseOutline, date: node.createdAt)
            coursesStore.deleteOutlineNode(node.id)
        }

        // Course files
        let expiredFiles = coursesStore.courseFiles.filter { file in
            let course = courseMap[file.courseId]
            let semesterEnd = course.flatMap { semesterMap[$0.semesterId]?.endDate }
            let primaryDate = file.createdAt
            let isExpired = policy.isSemesterBased
                ? (course?.semesterId).map { expiredSemesterIds.contains($0) } ?? false
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)
            return isExpired
        }
        for file in await batched(expiredFiles) {
            recordDeletion(type: .courseFile, date: file.createdAt)
            coursesStore.deleteFile(file.id)
        }

        let deletedCount = deletedByType.values.reduce(0, +)
        return Result(deletedCount: deletedCount, deletedByType: deletedByType)
    }

    static func estimate(
        policy: StorageRetentionPolicy,
        coursesStore: CoursesStore,
        assignmentsStore: AssignmentsStore,
        practiceStore: PracticeTestStore,
        now: Date = Date()
    ) -> [StorageEntityType: Int] {
        guard policy != .never else { return [:] }

        var counts: [StorageEntityType: Int] = [:]
        let semesterMap: [UUID: Semester] = Dictionary(uniqueKeysWithValues: coursesStore.semesters.map { ($0.id, $0) })
        let courseMap: [UUID: Course] = Dictionary(uniqueKeysWithValues: coursesStore.courses.map { ($0.id, $0) })

        let expiredSemesterIds: Set<UUID> = {
            if policy.isSemesterBased {
                return Set(
                    coursesStore.semesters
                        .filter { policy.isExpired(primaryDate: $0.endDate, semesterEnd: $0.endDate, now: now) }
                        .map(\.id)
                )
            }
            return []
        }()

        for course in coursesStore.courses {
            let semesterEnd = semesterMap[course.semesterId]?.endDate
            let primaryDate = semesterEnd ?? now
            let isExpired = policy.isSemesterBased
                ? expiredSemesterIds.contains(course.semesterId)
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)
            if isExpired { counts[.course, default: 0] += 1 }
        }

        for semester in coursesStore.semesters {
            let isExpired = policy.isSemesterBased
                ? expiredSemesterIds.contains(semester.id)
                : policy.isExpired(primaryDate: semester.endDate, semesterEnd: semester.endDate, now: now)
            if isExpired { counts[.semester, default: 0] += 1 }
        }

        for task in assignmentsStore.tasks {
            let course = task.courseId.flatMap { courseMap[$0] }
            let semesterEnd = course.flatMap { semesterMap[$0.semesterId]?.endDate }
            let primaryDate = task.due ?? now
            let isExpired = policy.isSemesterBased
                ? (course?.semesterId).map { expiredSemesterIds.contains($0) } ?? false
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)
            if isExpired { counts[.assignment, default: 0] += 1 }
        }

        for test in practiceStore.tests {
            let course = courseMap[test.courseId]
            let semesterEnd = course.flatMap { semesterMap[$0.semesterId]?.endDate }
            let primaryDate = test.createdAt
            let isExpired = policy.isSemesterBased
                ? (course?.semesterId).map { expiredSemesterIds.contains($0) } ?? false
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)
            if isExpired { counts[.practiceTest, default: 0] += 1 }
        }

        for node in coursesStore.outlineNodes {
            let course = courseMap[node.courseId]
            let semesterEnd = course.flatMap { semesterMap[$0.semesterId]?.endDate }
            let primaryDate = node.createdAt
            let isExpired = policy.isSemesterBased
                ? (course?.semesterId).map { expiredSemesterIds.contains($0) } ?? false
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)
            if isExpired { counts[.courseOutline, default: 0] += 1 }
        }

        for file in coursesStore.courseFiles {
            let course = courseMap[file.courseId]
            let semesterEnd = course.flatMap { semesterMap[$0.semesterId]?.endDate }
            let primaryDate = file.createdAt
            let isExpired = policy.isSemesterBased
                ? (course?.semesterId).map { expiredSemesterIds.contains($0) } ?? false
                : policy.isExpired(primaryDate: primaryDate, semesterEnd: semesterEnd, now: now)
            if isExpired { counts[.courseFile, default: 0] += 1 }
        }

        return counts
    }

    private static func batched<T>(_ items: [T], batchSize: Int = 25) async -> [T] {
        guard !items.isEmpty else { return [] }
        var result: [T] = []
        result.reserveCapacity(items.count)
        for (index, item) in items.enumerated() {
            result.append(item)
            if index % batchSize == 0 {
                await Task.yield()
            }
        }
        return result
    }

    private static func computeAggregates(
        coursesStore: CoursesStore,
        assignmentsStore: AssignmentsStore,
        gradesStore: GradesStore,
        focusManager: FocusManager,
        calendarManager: DeviceCalendarManager,
        aggregateStore: StorageAggregateStore,
        now: Date
    ) async {
        let calendar = Calendar.current
        let semesterMap = Dictionary(uniqueKeysWithValues: coursesStore.semesters.map { ($0.id, $0) })
        let courses = Dictionary(uniqueKeysWithValues: coursesStore.courses.map { ($0.id, $0) })

        for session in focusManager.sessions {
            let start = calendar.startOfDay(for: session.startDate)
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.startDate)?.start ?? start
            let monthStart = calendar.dateInterval(of: .month, for: session.startDate)?.start ?? start

            let activityId = session.activityID
            let courseId: UUID? = nil
            let semesterId: UUID? = nil

            let dayKey = AggregateKey(semesterId: semesterId, courseId: courseId, activityId: activityId, bucket: .day, bucketStart: start)
            let weekKey = AggregateKey(semesterId: semesterId, courseId: courseId, activityId: activityId, bucket: .week, bucketStart: weekStart)
            let monthKey = AggregateKey(semesterId: semesterId, courseId: courseId, activityId: activityId, bucket: .month, bucketStart: monthStart)

            aggregateStore.recordStudyTime(session.duration, key: dayKey)
            aggregateStore.recordStudyTime(session.duration, key: weekKey)
            aggregateStore.recordStudyTime(session.duration, key: monthKey)
        }

        for task in assignmentsStore.tasks where task.isCompleted {
            let courseId = task.courseId
            let semesterId = courseId.flatMap { courses[$0]?.semesterId }
            let endDate = semesterId.flatMap { semesterMap[$0]?.endDate } ?? now
            let dayKey = AggregateKey(semesterId: semesterId, courseId: courseId, activityId: nil, bucket: .day, bucketStart: calendar.startOfDay(for: endDate))
            let weekKey = AggregateKey(semesterId: semesterId, courseId: courseId, activityId: nil, bucket: .week, bucketStart: calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? endDate)
            let monthKey = AggregateKey(semesterId: semesterId, courseId: courseId, activityId: nil, bucket: .month, bucketStart: calendar.dateInterval(of: .month, for: endDate)?.start ?? endDate)
            let onTime = task.due.map { now <= $0 } ?? true
            aggregateStore.recordAssignmentCompletion(isOnTime: onTime, key: dayKey)
            aggregateStore.recordAssignmentCompletion(isOnTime: onTime, key: weekKey)
            aggregateStore.recordAssignmentCompletion(isOnTime: onTime, key: monthKey)
        }

        for grade in gradesStore.grades {
            guard let percent = grade.percent else { continue }
            let courseId = grade.courseId
            let semesterId = courses[courseId]?.semesterId
            let date = grade.updatedAt
            let dayKey = AggregateKey(semesterId: semesterId, courseId: courseId, activityId: nil, bucket: .day, bucketStart: calendar.startOfDay(for: date))
            let weekKey = AggregateKey(semesterId: semesterId, courseId: courseId, activityId: nil, bucket: .week, bucketStart: calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date)
            let monthKey = AggregateKey(semesterId: semesterId, courseId: courseId, activityId: nil, bucket: .month, bucketStart: calendar.dateInterval(of: .month, for: date)?.start ?? date)
            aggregateStore.recordGrade(percent, key: dayKey)
            aggregateStore.recordGrade(percent, key: weekKey)
            aggregateStore.recordGrade(percent, key: monthKey)
        }

        for event in calendarManager.events {
            let start = event.startDate
            let end = event.endDate
            let duration = end.timeIntervalSince(start)
            let dayKey = AggregateKey(semesterId: nil, courseId: nil, activityId: nil, bucket: .day, bucketStart: calendar.startOfDay(for: start))
            let weekKey = AggregateKey(semesterId: nil, courseId: nil, activityId: nil, bucket: .week, bucketStart: calendar.dateInterval(of: .weekOfYear, for: start)?.start ?? start)
            let monthKey = AggregateKey(semesterId: nil, courseId: nil, activityId: nil, bucket: .month, bucketStart: calendar.dateInterval(of: .month, for: start)?.start ?? start)
            aggregateStore.recordCalendarWorkload(events: 1, durationSeconds: duration, key: dayKey)
            aggregateStore.recordCalendarWorkload(events: 1, durationSeconds: duration, key: weekKey)
            aggregateStore.recordCalendarWorkload(events: 1, durationSeconds: duration, key: monthKey)
        }
    }
}
