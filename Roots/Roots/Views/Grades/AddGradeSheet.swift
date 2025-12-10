import SwiftUI

struct AddGradeSheet: View {
    let assignments: [AppTask]
    let courses: [GradeCourseSummary]
    var onSave: (AppTask) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCourse: GradeCourseSummary?
    @State private var selectedAssignment: AppTask?
    @State private var filterText: String = ""
    @State private var weightPercent: Double = 0
    @State private var possiblePoints: Double = 100
    @State private var earnedPoints: Double = 0

    private var gradePercent: Double {
        guard possiblePoints > 0 else { return 0 }
        return (earnedPoints / possiblePoints) * 100
    }

    private var filteredAssignments: [AppTask] {
        assignments.filter { task in
            let matchesCourse = selectedCourse == nil || task.courseId == selectedCourse?.id
            let matchesSearch = filterText.isEmpty || task.title.lowercased().contains(filterText.lowercased())
            return matchesCourse && matchesSearch
        }
        .sorted { ($0.due ?? Date.distantFuture) < ($1.due ?? Date.distantFuture) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Add Grade")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Picker("Course", selection: $selectedCourse) {
                    Text("All Courses").tag(GradeCourseSummary?.none)
                    ForEach(courses, id: \.id) { course in
                        Text(course.courseCode).tag(GradeCourseSummary?.some(course))
                    }
                }
                .pickerStyle(.menu)

                TextField("Filter assignments", text: $filterText)
                    .textFieldStyle(.roundedBorder)
            }

            Picker("Assignment", selection: $selectedAssignment) {
                Text("Select assignment").tag(AppTask?.none)
                ForEach(filteredAssignments, id: \.id) { task in
                    let title = task.title
                    let dueString = task.due?.formatted(date: .abbreviated, time: .omitted) ?? "No due date"
                    Text("\(title) — \(dueString)").tag(AppTask?.some(task))
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedAssignment) { _, task in
                weightPercent = task?.gradeWeightPercent ?? 0
                possiblePoints = task?.gradePossiblePoints ?? 100
                earnedPoints = task?.gradeEarnedPoints ?? 0
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weight (%)")
                    Spacer()
                    TextField("Weight", value: $weightPercent, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                HStack {
                    Text("Possible Points")
                    Spacer()
                    TextField("Possible", value: $possiblePoints, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                HStack {
                    Text("Earned Points")
                    Spacer()
                    TextField("Earned", value: $earnedPoints, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
            }

            Spacer(minLength: 8)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    if var task = selectedAssignment {
                        task.gradeWeightPercent = weightPercent
                        task.gradePossiblePoints = possiblePoints
                        task.gradeEarnedPoints = earnedPoints
                        onSave(task)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAssignment == nil)
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 420)
    }
}
