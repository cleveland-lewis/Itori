import SwiftUI

struct IOSIntelligentSchedulingSettingsView: View {
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    @StateObject private var gradeMonitor = GradeMonitoringService.shared
    @StateObject private var autoReschedule = EnhancedAutoRescheduleService.shared
    @StateObject private var settings = AppSettingsModel.shared
    
    @State private var showingNotifications = false
    
    var body: some View {
        List {
            // MARK: - System Status
            Section {
                HStack {
                    Image(systemName: coordinator.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(coordinator.isActive ? .green : .red)
                    
                    VStack(alignment: .leading) {
                        Text("Intelligent Scheduling")
                            .font(.headline)
                        Text(coordinator.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.enableIntelligentScheduling)
                        .labelsHidden()
                }
            } header: {
                Text("Status")
            }
            
            if coordinator.isActive {
                // MARK: - Grade Monitoring
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.blue)
                            Text("Grade Monitoring")
                                .font(.headline)
                            Spacer()
                            if gradeMonitor.isMonitoring {
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Text("Detects grade changes and suggests study time adjustments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text("Grade Change Threshold")
                        Spacer()
                        Text("\(Int(settings.gradeChangeThreshold))%")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $settings.gradeChangeThreshold,
                        in: 1...20,
                        step: 1
                    ) {
                        Text("Threshold")
                    } minimumValueLabel: {
                        Text("1%")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("20%")
                            .font(.caption)
                    }
                    
                    if !gradeMonitor.studyRecommendations.isEmpty {
                        NavigationLink {
                            StudyRecommendationsView()
                        } label: {
                            HStack {
                                Text("Active Recommendations")
                                Spacer()
                                Text("\(gradeMonitor.studyRecommendations.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Grade Monitoring")
                } footer: {
                    Text("Monitors your grades and suggests additional study time when grades decline by the threshold percentage.")
                }
                
                // MARK: - Auto-Reschedule
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                            Text("Auto-Reschedule")
                                .font(.headline)
                            Spacer()
                            if autoReschedule.isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        Text("Automatically reschedules overdue tasks based on priority and available time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if let lastCheck = autoReschedule.lastCheckTime {
                        HStack {
                            Text("Last Check")
                            Spacer()
                            Text(lastCheck, style: .relative)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                    
                    Picker("Work Hours Start", selection: Binding(
                        get: { autoReschedule.workHoursStart },
                        set: { newValue in
                            coordinator.setWorkHours(
                                start: newValue,
                                end: autoReschedule.workHoursEnd
                            )
                        }
                    )) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    
                    Picker("Work Hours End", selection: Binding(
                        get: { autoReschedule.workHoursEnd },
                        set: { newValue in
                            coordinator.setWorkHours(
                                start: autoReschedule.workHoursStart,
                                end: newValue
                            )
                        }
                    )) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    
                    Button {
                        Task {
                            await coordinator.checkOverdueTasks()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Check Now")
                        }
                    }
                    
                    if !autoReschedule.rescheduleNotifications.isEmpty {
                        NavigationLink {
                            RescheduleNotificationsView()
                        } label: {
                            HStack {
                                Text("Recent Reschedules")
                                Spacer()
                                Text("\(autoReschedule.rescheduleNotifications.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Auto-Reschedule")
                } footer: {
                    Text("Checks for overdue tasks hourly and automatically reschedules them to the next available time slot based on priority.")
                }
                
                // MARK: - All Notifications
                if !coordinator.allNotifications.isEmpty {
                    Section {
                        Button {
                            showingNotifications = true
                        } label: {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.red)
                                Text("View All Notifications")
                                Spacer()
                                Text("\(coordinator.allNotifications.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Notifications")
                    }
                }
            }
        }
        .navigationTitle("Intelligent Scheduling")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNotifications) {
            AllNotificationsView()
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

// MARK: - Study Recommendations View

struct StudyRecommendationsView: View {
    @StateObject private var gradeMonitor = GradeMonitoringService.shared
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        List {
            ForEach(gradeMonitor.studyRecommendations) { recommendation in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(recommendation.courseName)
                                .font(.headline)
                            Text(recommendation.reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            coordinator.dismissNotification(.studyTime(recommendation))
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Current")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", recommendation.currentWeeklyHours)) hrs/week")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading) {
                            Text("Suggested")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", recommendation.suggestedWeeklyHours)) hrs/week")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Additional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("+\(String(format: "%.1f", recommendation.additionalHours)) hrs")
                                .font(.callout)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("Recommended \(recommendation.timestamp, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Study Recommendations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reschedule Notifications View

struct RescheduleNotificationsView: View {
    @StateObject private var autoReschedule = EnhancedAutoRescheduleService.shared
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        List {
            ForEach(autoReschedule.rescheduleNotifications) { notification in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(notification.assignmentTitle)
                                .font(.headline)
                            if let courseName = notification.courseName {
                                Text(courseName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            coordinator.dismissNotification(.reschedule(notification))
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Label(notification.priority.rawValue.capitalized, systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundColor(priorityColor(notification.priority))
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Old deadline:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(notification.oldDueDate, style: .date)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("New deadline:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(notification.newDueDate, style: .date)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Start by:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(notification.suggestedStartTime, style: .date)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("Rescheduled \(notification.timestamp, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Recent Reschedules")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func priorityColor(_ priority: AssignmentUrgency) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - All Notifications View

struct AllNotificationsView: View {
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(coordinator.allNotifications) { notification in
                    switch notification {
                    case .studyTime(let rec):
                        StudyTimeNotificationRow(recommendation: rec)
                    case .reschedule(let not):
                        RescheduleNotificationRow(notification: not)
                    }
                }
            }
            .navigationTitle("All Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StudyTimeNotificationRow: View {
    let recommendation: StudyTimeRecommendation
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                Text("Study Time Recommendation")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    coordinator.dismissNotification(.studyTime(recommendation))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(recommendation.courseName)
                .font(.headline)
            
            Text("Increase study time by \(String(format: "%.1f", recommendation.additionalHours)) hours per week")
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

struct RescheduleNotificationRow: View {
    let notification: EnhancedAutoRescheduleService.RescheduleNotification
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                Text("Task Rescheduled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    coordinator.dismissNotification(.reschedule(notification))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(notification.assignmentTitle)
                .font(.headline)
            
            Text("New deadline: \(notification.newDueDate, style: .date)")
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        IOSIntelligentSchedulingSettingsView()
    }
}
