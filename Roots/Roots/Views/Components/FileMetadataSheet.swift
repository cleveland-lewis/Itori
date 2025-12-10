import SwiftUI

struct FileMetadataSheet: View {
    @Binding var attachment: Attachment
    let courses: [Course]?
    let onSave: () -> Void

    @State private var selectedCourseId: UUID?
    @State private var moduleNumber: Int
    @State private var taskType: CourseTaskType

    init(attachment: Binding<Attachment>, courses: [Course]?, onSave: @escaping () -> Void) {
        _attachment = attachment
        self.courses = courses
        self.onSave = onSave
        _selectedCourseId = State(initialValue: attachment.wrappedValue.associatedCourseID)
        _moduleNumber = State(initialValue: attachment.wrappedValue.moduleNumber ?? 1)
        _taskType = State(initialValue: attachment.wrappedValue.taskType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tag File")
                .font(DesignSystem.Typography.header)

            HStack(spacing: 10) {
                Image(systemName: attachment.tag.icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(attachment.name)
                        .font(DesignSystem.Typography.body)
                    Text(attachment.tag.rawValue)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let courses {
                Picker("Course", selection: $selectedCourseId) {
                    Text("None").tag(Optional<UUID>(nil))
                    ForEach(courses) { course in
                        Text(course.title).tag(Optional(course.id))
                    }
                }
                .labelsHidden()
            }

            Stepper("Module \(moduleNumber)", value: $moduleNumber, in: 1...50)

            Picker("Type", selection: $taskType) {
                ForEach(CourseTaskType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Spacer()
                Button {
                    attachment.moduleNumber = moduleNumber
                    attachment.taskType = taskType
                    attachment.associatedCourseID = selectedCourseId
                    onSave()
                } label: {
                    Text("Save File")
                        .font(DesignSystem.Typography.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 320)
    }
}
