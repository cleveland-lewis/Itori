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
                    Text(formattedDueDisplay(for: task, fallbackDate: due))
                        .font(DesignSystem.Typography.caption)
                }
            }
            Spacer()
            Text("\(task.estimatedMinutes) min")
                .font(DesignSystem.Typography.caption)
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .draggable(TransferableAssignment(from: task))
        .contextMenu {
            Button {
                SceneActivationHelper.openAssignmentWindow(for: task)
            } label: {
                Label("Open in New Window", systemImage: "doc.on.doc")
            }
            Button("Edit") {
                // TODO: wire edit
            }
            Button("Delete") {
                AssignmentsStore.shared.removeTask(id: task.id)
            }
        }
    }

    private func formattedDueDisplay(for task: AppTask, fallbackDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = task.hasExplicitDueTime ? .short : .none
        let date = task.hasExplicitDueTime ? (task.effectiveDueDateTime ?? fallbackDate) : fallbackDate
        return formatter.string(from: date)
    }
}#endif
