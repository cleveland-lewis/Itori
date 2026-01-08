//
//  WatchAddTaskView.swift
//  Itori (watchOS)
//

#if os(watchOS)
import SwiftUI

struct WatchAddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var syncManager: WatchSyncManager
    
    @State private var title: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(86400) // Tomorrow
    @State private var isSaving: Bool = false
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }
    
    var body: some View {
        List {
            Section("Task") {
                TextField("Title", text: $title)
                    .autocorrectionDisabled()
            }
            
            Section("Due Date") {
                Toggle("Set due date", isOn: $hasDueDate)
                
                if hasDueDate {
                    DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }
            
            Section {
                Button(action: saveTask) {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(NSLocalizedString("Add Task", value: "Add Task", comment: ""))
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!canSave)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
    }
    
    private func saveTask() {
        guard canSave else { return }
        
        isSaving = true
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let dueISO = hasDueDate ? ISO8601DateFormatter().string(from: dueDate) : nil
        
        syncManager.addTask(title: trimmedTitle, dueISO: dueISO)
        
        // Dismiss after short delay to show feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

#endif
