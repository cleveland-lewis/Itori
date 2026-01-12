#if os(macOS)
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
        @State private var color: Color = .accentColor
        @State private var attachments: [Attachment] = []

        init(mode: Mode, onSave: @escaping (Course) -> Void) {
            self.mode = mode
            self.onSave = onSave
        }

        private var isSaveDisabled: Bool {
            title.trimmingCharacters(in: .whitespaces).isEmpty
        }

        private var hasUnsavedChanges: Bool {
            !title.trimmingCharacters(in: .whitespaces).isEmpty ||
                !code.trimmingCharacters(in: .whitespaces).isEmpty ||
                !attachments.isEmpty
        }

        var body: some View {
            StandardSheetContainer(
                title: titleText,
                primaryActionTitle: "Save",
                primaryAction: saveCourse,
                primaryActionDisabled: isSaveDisabled,
                hasUnsavedChanges: hasUnsavedChanges,
                onDismiss: { dismiss() }
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Course Name")
                            .font(.system(size: 13, weight: .medium))
                        TextField("", text: $title, prompt: Text("Introduction to Computer Science"))
                            .textFieldStyle(.roundedBorder)
                    }

                    // Code
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Text("Course Code")
                                .font(.system(size: 13, weight: .medium))
                            InfoButton(text: "Optional short identifier like CS101")
                        }
                        TextField("", text: $code, prompt: Text("CS101"))
                            .textFieldStyle(.roundedBorder)
                    }

                    // Color
                    ColorPicker("Color", selection: $color)
                        .font(.system(size: 13))

                    // Materials (if any)
                    if !attachments.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Materials")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            AttachmentListView(attachments: $attachments, courseId: nil)
                        }
                    }
                }
            }
            .onAppear {
                if case let .edit(existing) = mode {
                    title = existing.title
                    code = existing.code
                    attachments = existing.attachments
                }
            }
        }

        private var titleText: String {
            switch mode {
            case .new: "New Course"
            case .edit: "Edit Course"
            }
        }

        private func saveCourse() {
            let trimmed = title.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }

            let course = switch mode {
            case .new:
                Course(title: trimmed, code: code, semesterId: UUID(), attachments: attachments)
            case let .edit(existing):
                Course(
                    id: existing.id,
                    title: trimmed,
                    code: code,
                    semesterId: existing.semesterId,
                    colorHex: existing.colorHex,
                    attachments: attachments
                )
            }

            onSave(course)
            dismiss()
        }
    }
#endif
