//
//  WatchTasksView.swift
//  Itori (watchOS)
//

#if os(watchOS)
import SwiftUI

struct WatchTasksView: View {
    @EnvironmentObject var syncManager: WatchSyncManager
    @State private var showingAddTask = false
    
    private var incompleteTasks: [TaskSummary] {
        syncManager.tasks.filter { !$0.isComplete }
    }
    
    private var completedTasks: [TaskSummary] {
        syncManager.tasks.filter { $0.isComplete }
    }
    
    var body: some View {
        List {
            // Add Task Button
            Section {
                NavigationLink(destination: WatchAddTaskView()) {
                    Label(NSLocalizedString("Add Task", value: "Add Task", comment: ""), systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
            
            // Incomplete Tasks
            if !incompleteTasks.isEmpty {
                Section("To Do") {
                    ForEach(incompleteTasks) { task in
                        TaskRow(task: task)
                    }
                }
            }
            
            // Completed Tasks
            if !completedTasks.isEmpty {
                Section("Completed") {
                    ForEach(completedTasks) { task in
                        TaskRow(task: task)
                    }
                }
            }
            
            // Empty State
            if syncManager.tasks.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text(NSLocalizedString("No tasks", value: "No tasks", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
    }
}

private struct TaskRow: View {
    @EnvironmentObject var syncManager: WatchSyncManager
    let task: TaskSummary
    
    private var dueText: String? {
        guard let dueISO = task.dueISO,
              let dueDate = ISO8601DateFormatter().date(from: dueISO) else {
            return nil
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dueDate, relativeTo: Date())
    }
    
    var body: some View {
        Button(action: toggleComplete) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isComplete ? .green : .gray)
                
                // Task Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isComplete)
                        .foregroundColor(task.isComplete ? .secondary : .primary)
                    
                    if let due = dueText {
                        Text(due)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func toggleComplete() {
        syncManager.toggleTaskCompletion(taskId: task.id)
    }
}

#endif
