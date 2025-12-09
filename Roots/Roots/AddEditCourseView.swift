import SwiftUI

struct AddEditCourseView: View {
    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    var onSave: (Course) -> Void

    enum Mode {
        case new
        case edit(Course)
    }

    @State private var title: String = ""
    @State private var code: String = ""
    @State private var instructor: String = ""
    @State private var term: String = ""
    @State private var credits: Int = 3
    @State private var color: Color = .accentColor
    @State private var isArchived: Bool = false
    @State private var attachments: [Attachment] = []

    init(mode: Mode, onSave: @escaping (Course) -> Void) {
        self.mode = mode
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(DesignSystem.Typography.header)

            Form {
                TextField("Course Title", text: $title)
                TextField("Course Code", text: $code)
                // Instructor/term/credits not used in new Course model — omit

                ColorPicker("Color", selection: $color)

                Toggle("Archived (placeholder)", isOn: $isArchived)
            }
            .formStyle(.grouped)

            // Course Materials Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Course Materials")
                    .font(.headline)

                // Inline attachments fallback while AttachmentListView is not exposed to this target
                VStack(alignment: .leading, spacing: 8) {
                    if attachments.isEmpty {
                        Text("No materials added")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(attachments) { a in
                            HStack {
                                Image(systemName: a.tag.icon)
                                Text(a.name)
                                Spacer()
                            }
                        }
                    }
                    Button("Add Material") {}
                        .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    let trimmed = title.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }

                    let course: Course
                    switch mode {
                    case .new:
                        course = Course(title: trimmed, code: code, semesterId: UUID(), attachments: attachments)
                    case .edit(let existing):
                        course = Course(id: existing.id, title: trimmed, code: code, semesterId: existing.semesterId, colorHex: existing.colorHex, attachments: attachments)
                    }

                    onSave(course)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(DesignSystem.Layout.padding.card)
        .frame(minWidth: 420)
        .onAppear {
            if case .edit(let existing) = mode {
                title = existing.title
                code = existing.code
                attachments = existing.attachments
                // colorHex -> Color mapping not implemented; keep color default
                isArchived = false
            }
        }
    }

    private var titleText: String {
        switch mode {
        case .new: return "Add Course"
        case .edit: return "Edit Course"
        }
    }
}
