import SwiftUI

struct CourseSceneContent: View {
    @SceneStorage(SceneActivationHelper.courseSceneStorageKey) private var courseIdString: String?
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var assignmentsStore: AssignmentsStore

    private var course: Course? {
        guard let idString = courseIdString,
              let uuid = UUID(uuidString: idString) else {
            return nil
        }
        return coursesStore.courses.first(where: { $0.id == uuid })
    }

    private var semester: Semester? {
        guard let course = course else { return nil }
        return coursesStore.semesters.first(where: { $0.id == course.semesterId })
    }

    private var assignmentsForCourse: [AppTask] {
        guard let courseId = course?.id else { return [] }
        return assignmentsStore.tasks
            .filter { $0.courseId == courseId }
            .sorted { ($0.due ?? Date.distantFuture) < ($1.due ?? Date.distantFuture) }
    }

    var body: some View {
        NavigationStack {
            if let course = course {
                List {
                    Section(header: Text(NSLocalizedString("ui.course.details", value: "Course Details", comment: "Course Details"))) {
                        infoRow(label: "Code", value: course.code.isEmpty ? "Not set" : course.code)
                        infoRow(label: "Title", value: course.title)
                        infoRow(label: "Semester", value: semester?.name ?? "Not set")
                        if let location = course.location, !location.isEmpty {
                            infoRow(label: "Location", value: location)
                        }
                        if let instructor = course.instructor, !instructor.isEmpty {
                            infoRow(label: "Instructor", value: instructor)
                        }
                        if let meeting = course.meetingTimes, !meeting.isEmpty {
                            infoRow(label: "Meetings", value: meeting)
                        }
                    }

                    Section(header: Text(NSLocalizedString("ui.assignments", value: "Assignments", comment: "Assignments"))) {
                        if assignmentsForCourse.isEmpty {
                            Text(NSLocalizedString("ui.no.assignments.recorded.for.this.course", value: "No assignments recorded for this course.", comment: "No assignments recorded for this course."))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(assignmentsForCourse, id: \.id) { assignment in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(assignment.title)
                                        .font(.headline)
                                    Text(assignment.due.map { formattedDate($0) } ?? "No due date")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(course.title)
            } else {
                placeholder
            }
        }
        .onContinueUserActivity(SceneActivationHelper.windowActivityType) { activity in
            guard let state = SceneActivationHelper.decodeWindowState(from: activity),
                  state.windowId == WindowIdentifier.courseDetail.rawValue,
                  let identifier = state.entityId else {
                return
            }
            courseIdString = identifier
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body)
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("ui.open.a.course.in.a.new.window.to.see.details.here", value: "Open a course in a new window to see details here.", comment: "Open a course in a new window to see details here."))
                .font(.title3.weight(.medium))
            Text(NSLocalizedString("ui.use.open.in.new.window", value: "Use “Open in New Window” from the Courses list to inspect a course without losing your place.", comment: "Use “Open in New Window” from the Courses list to ..."))
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct PlannerSceneContent: View {
    @SceneStorage(SceneActivationHelper.plannerSceneStorageKey) private var dateId: String?
    @EnvironmentObject private var plannerStore: PlannerStore

    private var selectedDate: Date {
        if let stored = dateId,
           let date = SceneActivationHelper.date(from: stored) {
            return date
        }
        return Date()
    }

    private var sessions: [StoredScheduledSession] {
        let calendar = Calendar.current
        return plannerStore.scheduled
            .filter { calendar.isDate($0.start, inSameDayAs: selectedDate) }
            .sorted { $0.start < $1.start }
    }

    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    Text(verbatim: "No planner blocks on \(formattedDate(selectedDate)).")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.headline)
                                Text(timeRange(for: session))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(verbatim: "\(session.estimatedMinutes) min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Planner • \(formattedDate(selectedDate))")
        }
        .onContinueUserActivity(SceneActivationHelper.windowActivityType) { activity in
            guard let state = SceneActivationHelper.decodeWindowState(from: activity),
                  state.windowId == WindowIdentifier.plannerDay.rawValue,
                  let identifier = state.entityId else {
                return
            }
            dateId = identifier
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func timeRange(for session: StoredScheduledSession) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: session.start)) – \(formatter.string(from: session.end))"
    }
}
