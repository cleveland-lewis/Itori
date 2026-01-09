#if os(macOS)
    import SwiftUI

    struct AssignmentRow: View {
        let task: AppTask

        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(task.title)
                        .font(DesignSystem.Typography.body)
                    if let due = task.due {
                        // Use app-wide time formatting via shared settings
                        Text(AppSettingsModel.shared.formattedTime(due))
                            .font(DesignSystem.Typography.caption)
                    }
                }
                Spacer()
                Text(verbatim: "\(task.estimatedMinutes) min")
                    .font(DesignSystem.Typography.caption)
            }
            .padding(.vertical, DesignSystem.Spacing.small)
            .draggable(TransferableAssignment(from: task))
            .contextMenu {
                Button {
                    SceneActivationHelper.openAssignmentWindow(for: task)
                } label: {
                    Label(
                        NSLocalizedString(
                            "ui.label.open.in.new.window",
                            value: "Open in New Window",
                            comment: "Open in New Window"
                        ),
                        systemImage: "doc.on.doc"
                    )
                }
                Button(NSLocalizedString("ui.button.edit", value: "Edit", comment: "Edit")) {
                    SceneActivationHelper.openAssignmentWindow(for: task)
                }
                Button(NSLocalizedString("ui.button.delete", value: "Delete", comment: "Delete")) {
                    AssignmentsStore.shared.removeTask(id: task.id)
                }
            }
        }
    }#endif
