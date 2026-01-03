import SwiftUI

// MARK: - Integration Example for Itori App

/*
 This file demonstrates how to integrate the Intelligent Scheduling System
 into various parts of the Itori app.
 */

// MARK: - Example 1: App Initialization

/*
 Add this to your main app file (e.g., RootsIOSApp.swift)
 */

/*
@main
struct RootsIOSApp: App {
    @StateObject private var appModel = AppModel.shared
    @StateObject private var schedulingCoordinator = IntelligentSchedulingCoordinator.shared
    
    init() {
        // Configure logging
        setupLogging()
        
        // Initialize intelligent scheduling
        Task { @MainActor in
            let settings = AppSettingsModel.shared
            
            // Start if enabled in settings
            if settings.enableIntelligentScheduling {
                IntelligentSchedulingCoordinator.shared.start()
            }
            
            // Configure thresholds if needed
            IntelligentSchedulingCoordinator.shared.setGradeChangeThreshold(
                settings.gradeChangeThreshold
            )
        }
    }
    
    var body: some Scene {
        WindowGroup {
            IOSRootView()
                .environmentObject(appModel)
                .environmentObject(schedulingCoordinator)
        }
    }
}
*/

// MARK: - Example 2: Grades View Integration

/*
 Add grade monitoring to your grades input view
 */

struct ExampleGradesView: View {
    @State private var courseId: UUID = UUID()
    @State private var gradeScore: String = ""
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        VStack {
            TextField("Grade (0-100)", text: $gradeScore)
                .keyboardType(.decimalPad)
            
            Button("Save Grade") {
                if let score = Double(gradeScore) {
                    // Save to GradesStore (existing functionality)
                    GradesStore.shared.upsert(
                        courseId: courseId,
                        percent: score,
                        letter: nil
                    )
                    
                    // Also track in grade monitoring
                    coordinator.addGrade(
                        courseId: courseId,
                        score: score,
                        assignmentName: "Current Grade"
                    )
                }
            }
            
            // Display study recommendations if any
            if let recommendation = coordinator.getStudyRecommendation(for: courseId) {
                StudyRecommendationBanner(recommendation: recommendation)
            }
        }
        .padding()
    }
}

struct StudyRecommendationBanner: View {
    let recommendation: StudyTimeRecommendation
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Grade Alert")
                    .font(.headline)
                Spacer()
                Button {
                    coordinator.dismissNotification(.studyTime(recommendation))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(recommendation.reason)
                .font(.subheadline)
            
            Text("Increase study time by \(String(format: "%.1f", recommendation.additionalHours)) hours/week")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Example 3: Assignment Creation Integration

/*
 Automatically check for overdue tasks when creating assignments
 */

struct ExampleAddAssignmentView: View {
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var estimatedMinutes: Int = 60
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        Form {
            TextField("Title", text: $title)
            DatePicker("Due Date", selection: $dueDate)
            Stepper("Estimated: \(estimatedMinutes) min", value: $estimatedMinutes, in: 15...480, step: 15)
            
            Button("Save Assignment") {
                let assignment = Assignment(
                    title: title,
                    dueDate: dueDate,
                    estimatedMinutes: estimatedMinutes,
                    urgency: .medium
                )
                
                // Save to store
                AssignmentsStore.shared.addAssignment(assignment)
                
                // Trigger reschedule check for any overdue tasks
                Task {
                    await coordinator.checkOverdueTasks()
                }
            }
        }
    }
}

// MARK: - Example 4: Dashboard Widget

/*
 Show scheduling notifications on dashboard
 */

struct SchedulingNotificationsWidget: View {
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(.red)
                Text("Scheduling Alerts")
                    .font(.headline)
                Spacer()
                if !coordinator.allNotifications.isEmpty {
                    Text("\(coordinator.allNotifications.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            
            if coordinator.allNotifications.isEmpty {
                Text("No alerts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(coordinator.allNotifications.prefix(3)) { notification in
                    NotificationRow(notification: notification)
                }
                
                if coordinator.allNotifications.count > 3 {
                    NavigationLink {
                        AllNotificationsView()
                    } label: {
                        Text("View all \(coordinator.allNotifications.count) notifications")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct NotificationRow: View {
    let notification: IntelligentSchedulingCoordinator.SchedulingNotification
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var icon: String {
        switch notification {
        case .studyTime: return "book.fill"
        case .reschedule: return "calendar.badge.clock"
        }
    }
    
    private var color: Color {
        switch notification {
        case .studyTime: return .blue
        case .reschedule: return .orange
        }
    }
    
    private var title: String {
        switch notification {
        case .studyTime(let rec): return rec.courseName
        case .reschedule(let not): return not.assignmentTitle
        }
    }
    
    private var subtitle: String {
        switch notification {
        case .studyTime(let rec):
            return "Increase study time by \(String(format: "%.1f", rec.additionalHours))h"
        case .reschedule(let not):
            return "Rescheduled to \(not.newDueDate, style: .date)"
        }
    }
}

// MARK: - Example 5: Settings Integration

/*
 Add to SettingsRootView.swift or similar
 */

/*
struct SettingsRootView: View {
    var body: some View {
        List {
            // ... existing settings sections ...
            
            Section("Scheduling") {
                NavigationLink {
                    IOSIntelligentSchedulingSettingsView()
                } label: {
                    Label("Intelligent Scheduling", systemImage: "brain")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
*/

// MARK: - Example 6: Course Detail Integration

/*
 Show study recommendations in course detail view
 */

struct ExampleCourseDetailView: View {
    let course: Course
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Course info...
                
                // Study time configuration
                StudyHoursSection(courseId: course.id)
                
                // Study recommendation if any
                if let recommendation = coordinator.getStudyRecommendation(for: course.id) {
                    StudyRecommendationCard(recommendation: recommendation)
                }
            }
            .padding()
        }
    }
}

struct StudyHoursSection: View {
    let courseId: UUID
    @State private var weeklyHours: Double = 5.0
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Study Hours")
                .font(.headline)
            
            HStack {
                Slider(value: $weeklyHours, in: 1...20, step: 0.5)
                Text("\(String(format: "%.1f", weeklyHours))h")
                    .frame(width: 50)
            }
            
            Button("Save") {
                coordinator.setStudyHours(
                    courseId: courseId,
                    weeklyHours: weeklyHours
                )
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StudyRecommendationCard: View {
    let recommendation: StudyTimeRecommendation
    @StateObject private var coordinator = IntelligentSchedulingCoordinator.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Study Time Recommendation")
                    .font(.headline)
                Spacer()
                Button {
                    coordinator.dismissNotification(.studyTime(recommendation))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(recommendation.reason)
                .font(.subheadline)
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", recommendation.currentWeeklyHours))h")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading) {
                    Text("Suggested")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", recommendation.suggestedWeeklyHours))h")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("+\(String(format: "%.1f", recommendation.additionalHours))h")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("additional")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Example 7: Notification Handling

/*
 Handle notification taps to navigate to relevant screens
 */

/*
extension AppDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        
        if identifier.hasPrefix("study-recommendation-") {
            // Navigate to course detail or grades view
            let idString = identifier.replacingOccurrences(of: "study-recommendation-", with: "")
            if let uuid = UUID(uuidString: idString) {
                // Navigate to recommendation
            }
        } else if identifier.hasPrefix("reschedule-") {
            // Navigate to assignment detail
            let idString = identifier.replacingOccurrences(of: "reschedule-", with: "")
            if let uuid = UUID(uuidString: idString) {
                // Navigate to rescheduled assignment
            }
        }
        
        completionHandler()
    }
}
*/

#Preview("Dashboard Widget") {
    SchedulingNotificationsWidget()
        .padding()
}

#Preview("Notification Row") {
    VStack {
        NotificationRow(notification: .studyTime(
            StudyTimeRecommendation(
                id: UUID(),
                courseId: UUID(),
                courseName: "Mathematics",
                currentWeeklyHours: 5.0,
                suggestedWeeklyHours: 7.5,
                additionalHours: 2.5,
                reason: "Grade declined by 8.5 points",
                trend: .declining,
                timestamp: Date()
            )
        ))
    }
    .padding()
}
