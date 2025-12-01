import SwiftUI

struct AddAssignmentView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var title: String = ""
    @State var due: Date? = nil
    @State var estimatedMinutes: Int = 60
    @State var courseText: String = ""
    @State var type: TaskType = .reading

    var onSave: (Task) -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            TextField("Title", text: $title)
            DatePicker("Due (optional)", selection: Binding(get: { due ?? Date() }, set: { due = $0 }), displayedComponents: [.date, .hourAndMinute])
            Stepper("Estimated: \(estimatedMinutes) min", value: $estimatedMinutes, in: 15...480, step: 5)
            TextField("Course (optional)", text: $courseText)
            Picker("Type", selection: $type) {
                ForEach(TaskType.allCases, id: \.self) { t in
                    Text(t.rawValue.capitalized).tag(t)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                Spacer()
                Button("Save") {
                    let courseId = UUID() // placeholder for course linking; real app would lookup course
                    let task = Task(id: UUID(), title: title, courseId: courseText.isEmpty ? nil : courseId, due: due, estimatedMinutes: estimatedMinutes, minBlockMinutes: 20, maxBlockMinutes: 180, difficulty: 0.5, importance: 0.5, type: type, locked: false)
                    onSave(task)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(DesignSystem.Spacing.large)
        .frame(minWidth: 400)
    }
}
