import SwiftUI

struct AssignmentSceneContent: View {
    @SceneStorage(SceneActivationHelper.assignmentSceneStorageKey) private var assignmentIdString: String?
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var coursesStore: CoursesStore
    @Environment(\.dismiss) private var dismiss

    private var assignment: AppTask? {
        guard let idString = assignmentIdString,
              let uuid = UUID(uuidString: idString) else {
            return nil
        }
        return assignmentsStore.tasks.first(where: { $0.id == uuid })
    }

    var body: some View {
        NavigationStack {
            if let task = assignment {
                AssignmentDetailWindowView(
                    task: task,
                    courses: coursesStore.courses,
                    onToggleCompletion: {
                        var updated = task
                        updated.isCompleted.toggle()
                        assignmentsStore.updateTask(updated)
                    },
                    onDelete: {
                        assignmentsStore.removeTask(id: task.id)
                        dismiss()
                    }
                )
                .navigationTitle(task.title)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            } else {
                placeholder
            }
        }
        .onContinueUserActivity(SceneActivationHelper.windowActivityType) { activity in
            guard let state = SceneActivationHelper.decodeWindowState(from: activity),
                  state.windowId == WindowIdentifier.assignmentDetail.rawValue,
                  let incomingId = state.entityId else {
                return
            }
            assignmentIdString = incomingId
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Assignment detail will appear here.")
                .font(.title3.weight(.semibold))
            Text("Use “Open in New Window” from the Assignments list to create a dedicated window.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
