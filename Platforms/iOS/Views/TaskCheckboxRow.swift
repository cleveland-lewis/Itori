//
//  TaskCheckboxRow.swift
//  Itori (iOS)
//
//  Phase 4.3: Task checkbox row with alarm indicator
//

#if os(iOS)
import SwiftUI

struct TaskCheckboxRow: View {
    let task: AppTask
    let onToggle: (AppTask) -> Void
    @State private var showingAlarmPicker = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                onToggle(task)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                HStack(spacing: 8) {
                    // Due date/time
                    if let dueDate = task.due {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(formatDueDate(dueDate))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Alarm indicator
                    if task.alarmEnabled, let alarmDate = task.alarmDate {
                        HStack(spacing: 4) {
                            Image(systemName: "alarm")
                                .font(.caption2)
                            Text(formatAlarmTime(alarmDate))
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Alarm button
            Button {
                showingAlarmPicker = true
            } label: {
                Image(systemName: task.alarmEnabled ? "alarm.fill" : "alarm")
                    .font(.system(size: 16))
                    .foregroundColor(task.alarmEnabled ? .orange : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .cornerRadius(8)
        .sheet(isPresented: $showingAlarmPicker) {
            TaskAlarmPickerView(task: task)
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: date)
        
        if dueDay == today {
            if let dueTime = task.dueTimeMinutes {
                let hours = dueTime / 60
                let minutes = dueTime % 60
                return String(format: "Today %d:%02d", hours, minutes)
            }
            return NSLocalizedString("timer.tasks.today", comment: "Today")
        } else if dueDay == calendar.date(byAdding: .day, value: 1, to: today) {
            return NSLocalizedString("timer.tasks.tomorrow", comment: "Tomorrow")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    private func formatAlarmTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Task Alarm Picker View

struct TaskAlarmPickerView: View {
    let task: AppTask
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @StateObject private var alarmScheduler = NotificationTaskAlarmScheduler()
    
    @State private var alarmEnabled: Bool
    @State private var selectedDate: Date
    @State private var selectedSound: String?
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    init(task: AppTask) {
        self.task = task
        _alarmEnabled = State(initialValue: task.alarmEnabled)
        _selectedDate = State(initialValue: task.alarmDate ?? Self.defaultAlarmDate(for: task))
        _selectedSound = State(initialValue: task.alarmSound)
    }
    
    private static func defaultAlarmDate(for task: AppTask) -> Date {
        guard let dueDate = task.due else {
            return Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        }
        
        // Default to 1 hour before due time, or 9 AM if no time specified
        if let dueTimeMinutes = task.dueTimeMinutes {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
            let alarmMinutes = max(0, dueTimeMinutes - 60) // 1 hour before
            components.hour = alarmMinutes / 60
            components.minute = alarmMinutes % 60
            return calendar.date(from: components) ?? dueDate
        } else {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
            components.hour = 9
            components.minute = 0
            return Calendar.current.date(from: components) ?? dueDate
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(NSLocalizedString("timer.tasks.alarm.enabled", comment: "Set Alarm"), isOn: $alarmEnabled)
                }
                
                if alarmEnabled {
                    Section {
                        DatePicker(
                            NSLocalizedString("timer.tasks.alarm.time", comment: "Alarm Time"),
                            selection: $selectedDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        
                        // Quick actions
                        VStack(spacing: 8) {
                            HStack {
                                quickActionButton(title: NSLocalizedString("timer.tasks.alarm.quick.1hour", comment: "1 Hour Before"), offset: -3600)
                                quickActionButton(title: NSLocalizedString("timer.tasks.alarm.quick.morning", comment: "Morning of"), hour: 9)
                            }
                            HStack {
                                quickActionButton(title: NSLocalizedString("timer.tasks.alarm.quick.dayBefore", comment: "Day Before"), offset: -86400, hour: 18)
                                quickActionButton(title: NSLocalizedString("timer.tasks.alarm.quick.custom", comment: "Custom"), isCustom: true)
                            }
                        }
                        .buttonStyle(.bordered)
                    } header: {
                        Text(NSLocalizedString("timer.tasks.alarm.when", comment: "When"))
                    }
                    
                    Section {
                        Picker(NSLocalizedString("timer.tasks.alarm.sound", comment: "Sound"), selection: $selectedSound) {
                            Text(NSLocalizedString("timer.tasks.alarm.sound.default", comment: "Default")).tag(nil as String?)
                            Text("Chime").tag("chime" as String?)
                            Text("Bell").tag("bell" as String?)
                            Text("Alert").tag("alert" as String?)
                        }
                    }
                }
                
                Section {
                    if let dueDate = task.due {
                        HStack {
                            Text(NSLocalizedString("timer.tasks.due", comment: "Due"))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDueDate(dueDate))
                        }
                    }
                    
                    HStack {
                        Text(NSLocalizedString("timer.tasks.status", comment: "Status"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(alarmScheduler.alarmKitAvailable ? "AlarmKit" : "Notifications")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("timer.tasks.alarm.title", comment: "Task Reminder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "Save")) {
                        saveAlarm()
                    }
                }
            }
            .alert(NSLocalizedString("timer.tasks.alarm.error", comment: "Error"), isPresented: $showingError) {
                Button(NSLocalizedString("common.ok", comment: "OK"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func quickActionButton(title: String, offset: TimeInterval = 0, hour: Int? = nil, isCustom: Bool = false) -> some View {
        Button(title) {
            if isCustom {
                // Already custom - do nothing
            } else if let hour = hour, let dueDate = task.due {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
                if offset < 0 {
                    components.day! -= Int(-offset / 86400)
                }
                components.hour = hour
                components.minute = 0
                selectedDate = Calendar.current.date(from: components) ?? dueDate
            } else if let dueDate = task.due {
                selectedDate = dueDate.addingTimeInterval(offset)
            }
        }
        .font(.caption)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = task.dueTimeMinutes != nil ? .short : .none
        return formatter.string(from: date)
    }
    
    private func saveAlarm() {
        var updatedTask = task
        updatedTask.alarmEnabled = alarmEnabled
        updatedTask.alarmDate = alarmEnabled ? selectedDate : nil
        updatedTask.alarmSound = selectedSound
        
        // Update task in store
        assignmentsStore.updateTask(updatedTask)
        
        // Schedule/cancel alarm
        Task {
            do {
                if alarmEnabled {
                    try await alarmScheduler.scheduleAlarm(for: updatedTask, at: selectedDate, sound: selectedSound)
                } else {
                    try await alarmScheduler.cancelAlarm(for: updatedTask.id)
                }
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#endif
