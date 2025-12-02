import SwiftUI

struct ActivityListView: View {
    @ObservedObject var vm: TimerPageViewModel
    @State private var showEditor: Bool = false
    @State private var editingActivity: TimerActivity? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Activities").font(.headline)
                Spacer()
                Button(action: { editingActivity = nil; showEditor = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.glass)
            }

            List {
                ForEach(vm.filteredActivities) { activity in
                    HStack {
                        if let emoji = activity.emoji { Text(emoji) }
                        VStack(alignment: .leading) {
                            Text(activity.name)
                            HStack(spacing: 8) {
                                if let cat = activity.studyCategory { Text(cat.rawValue.capitalized).font(.caption).foregroundColor(.secondary) }
                                if activity.courseID != nil { Text("Course").font(.caption).foregroundColor(.secondary) }
                                if activity.assignmentID != nil { Text("Assignment").font(.caption).foregroundColor(.secondary) }
                            }
                        }
                        Spacer()
                        Button("Edit") { editingActivity = activity; showEditor = true }
                            .buttonStyle(.bordered)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { vm.selectActivity(activity.id) }
                }
                .onDelete { idx in
                    for i in idx { let id = vm.filteredActivities[i].id; vm.deleteActivity(id: id) }
                }
            }
            .frame(maxHeight: 340)
        }
        .sheet(isPresented: $showEditor) {
            ActivityEditorView(activity: $editingActivity, onSave: { act in
                if let existing = editingActivity { vm.updateActivity(act) } else { vm.addActivity(act) }
                showEditor = false
            }, onCancel: { showEditor = false })
        }
    }
}
