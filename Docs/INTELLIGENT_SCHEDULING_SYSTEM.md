# Intelligent Scheduling System

## Overview

The Intelligent Scheduling System for Itori provides automated grade monitoring and task rescheduling capabilities. It consists of three main components:

### 1. **GradeMonitoringService**
Monitors grade changes and suggests study time adjustments when grades decline.

### 2. **EnhancedAutoRescheduleService**
Automatically reschedules overdue tasks based on priority, available time, and work hours.

### 3. **IntelligentSchedulingCoordinator**
Unified coordinator that integrates both services and manages notifications.

## Features

### Grade Monitoring
- **Automatic Grade Tracking**: Monitors grades from the GradesStore
- **Trend Detection**: Identifies improving, declining, or stable grade trends
- **Configurable Threshold**: Trigger alerts when grades drop by a specified percentage (default: 5%)
- **Study Time Recommendations**: Calculates suggested additional study hours based on grade decline severity:
  - 15% increase for 5-10 point drops
  - 25% increase for 10-15 point drops
  - 35% increase for 15-20 point drops
  - 50% increase for 20+ point drops
- **Push Notifications**: Sends alerts with specific study time recommendations

### Auto-Rescheduling
- **Overdue Detection**: Automatically identifies tasks past their due date
- **Intelligent Slot Finding**: Finds optimal reschedule times based on:
  - Task priority (Critical, High, Medium, Low)
  - Estimated task duration
  - Available free time slots
  - Work hours configuration (default: 8 AM - 10 PM)
- **Priority-Based Scheduling**:
  - **Critical**: Schedules ASAP in next available slot
  - **High**: Schedules within 3 days
  - **Medium/Low**: Schedules at next convenient time
- **Conflict Avoidance**: Checks existing assignments to prevent overlaps
- **Hourly Checks**: Runs automatically every hour (configurable)
- **Detailed Notifications**: Includes old deadline, new deadline, priority, estimated hours, and suggested start time

## Installation

### Files Created

1. `SharedCore/Services/FeatureServices/GradeMonitoringService.swift`
2. `SharedCore/Services/FeatureServices/EnhancedAutoRescheduleService.swift`
3. `SharedCore/Services/FeatureServices/IntelligentSchedulingCoordinator.swift`
4. `Platforms/iOS/Scenes/Settings/Categories/IOSIntelligentSchedulingSettingsView.swift`

### Integration Steps

1. **Add files to Xcode project**: Add all four files to your Xcode project under the appropriate targets.

2. **Initialize the system** in your app startup (e.g., in `RootsIOSApp.swift`):

```swift
import SwiftUI

@main
struct RootsIOSApp: App {
    @StateObject private var schedulingCoordinator = IntelligentSchedulingCoordinator.shared
    
    init() {
        // Start intelligent scheduling if enabled
        Task { @MainActor in
            if AppSettingsModel.shared.enableIntelligentScheduling {
                IntelligentSchedulingCoordinator.shared.start()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            IOSRootView()
                .environmentObject(schedulingCoordinator)
        }
    }
}
```

3. **Add to Settings** - Add the settings view to your settings navigation:

In `SettingsRootView.swift` or similar:

```swift
NavigationLink {
    IOSIntelligentSchedulingSettingsView()
} label: {
    Label("Intelligent Scheduling", systemImage: "brain")
}
```

## Usage

### Programmatic Usage

#### Start/Stop the System

```swift
// Start intelligent scheduling
IntelligentSchedulingCoordinator.shared.start()

// Stop intelligent scheduling
IntelligentSchedulingCoordinator.shared.stop()
```

#### Add Grades for Monitoring

```swift
// Add a grade
IntelligentSchedulingCoordinator.shared.addGrade(
    courseId: courseUUID,
    score: 85.5,
    assignmentName: "Midterm Exam"
)

// Set weekly study hours for a course
IntelligentSchedulingCoordinator.shared.setStudyHours(
    courseId: courseUUID,
    weeklyHours: 6.0
)
```

#### Manual Task Check

```swift
// Manually trigger overdue task check
Task {
    await IntelligentSchedulingCoordinator.shared.checkOverdueTasks()
}
```

#### Access Notifications

```swift
// Get all notifications
let notifications = IntelligentSchedulingCoordinator.shared.allNotifications

// Dismiss a notification
IntelligentSchedulingCoordinator.shared.dismissNotification(notification)
```

### User Interface Usage

1. **Enable the System**:
   - Go to Settings → Intelligent Scheduling
   - Toggle "Intelligent Scheduling" on

2. **Configure Grade Monitoring**:
   - Adjust "Grade Change Threshold" slider (1-20%)
   - View active study recommendations

3. **Configure Auto-Rescheduling**:
   - Set "Work Hours Start" and "Work Hours End"
   - Click "Check Now" to manually trigger reschedule check
   - View recent reschedules

4. **View Notifications**:
   - Tap "View All Notifications" to see combined list
   - Dismiss individual notifications by tapping the X button

## Configuration

### App Settings

```swift
// Enable/disable the entire system
AppSettingsModel.shared.enableIntelligentScheduling = true

// Set grade change threshold
AppSettingsModel.shared.gradeChangeThreshold = 5.0
```

### Coordinator Configuration

```swift
let coordinator = IntelligentSchedulingCoordinator.shared

// Set grade threshold
coordinator.setGradeChangeThreshold(7.0) // Trigger at 7% drop

// Set work hours
coordinator.setWorkHours(start: 8, end: 22) // 8 AM - 10 PM

// Set check interval (in seconds)
coordinator.setCheckInterval(3600) // Check every hour
```

## Data Storage

### Grade History
- Location: `~/Library/Application Support/GradeMonitoring/grade_history.json`
- Contains: Historical grade snapshots and configured study hours
- Format: JSON

### Persistence
Both services automatically save their state to disk:
- Grade snapshots are saved after each new grade
- Study hours are saved when modified
- Data persists across app launches

## Notifications

### System Notifications

The system sends two types of user notifications:

1. **Study Time Recommendations**
   - Title: "📚 Study Time Recommendation"
   - Body: Course name, reason, current hours, suggested hours, additional hours needed
   - Category: `STUDY_TIME_RECOMMENDATION`

2. **Task Reschedule Notifications**
   - Title: "📅 Task Rescheduled"
   - Body: Assignment title, course, old/new deadlines, priority, estimated hours, suggested start time
   - Category: `TASK_RESCHEDULE`

3. **Reschedule Failed Notifications**
   - Title: "⚠️ Unable to Reschedule"
   - Body: Task name and manual action required
   - Category: `RESCHEDULE_FAILED`

### In-App Notifications

All notifications are also available in-app through:
- `IntelligentSchedulingCoordinator.shared.allNotifications`
- Settings → Intelligent Scheduling → View All Notifications

## Architecture

### Grade Monitoring Flow

```
GradesStore updates
    ↓
GradeMonitoringService detects change
    ↓
Analyze trend (improving/declining/stable)
    ↓
If declining by threshold → Calculate recommendation
    ↓
Send notification + Store in-app
```

### Auto-Reschedule Flow

```
Timer triggers (every hour)
    ↓
EnhancedAutoRescheduleService checks assignments
    ↓
Find overdue tasks (status != completed, dueDate < now)
    ↓
For each overdue task:
    - Get free time slots (next 14 days)
    - Filter by task duration
    - Select slot based on priority
    - Update assignment in store
    - Send notification
```

### Data Dependencies

```
IntelligentSchedulingCoordinator
    ├── GradeMonitoringService
    │   ├── GradesStore
    │   ├── CoursesStore
    │   └── NotificationManager
    └── EnhancedAutoRescheduleService
        ├── AssignmentsStore
        ├── CoursesStore
        ├── PlannerStore
        └── NotificationManager
```

## Testing

### Test Grade Monitoring

```swift
let coordinator = IntelligentSchedulingCoordinator.shared
coordinator.start()

// Add declining grades
coordinator.addGrade(courseId: testCourseId, score: 90.0)
coordinator.addGrade(courseId: testCourseId, score: 85.0)
coordinator.addGrade(courseId: testCourseId, score: 78.0) // Should trigger

// Check for recommendations
if let recommendation = coordinator.getStudyRecommendation(for: testCourseId) {
    print("Recommended additional hours: \(recommendation.additionalHours)")
}
```

### Test Auto-Reschedule

```swift
// Create an overdue assignment
var assignment = Assignment(
    title: "Test Assignment",
    dueDate: Date().addingTimeInterval(-86400), // Yesterday
    estimatedMinutes: 120,
    urgency: .high
)
AssignmentsStore.shared.addAssignment(assignment)

// Trigger manual check
Task {
    await IntelligentSchedulingCoordinator.shared.checkOverdueTasks()
}

// Check notifications
print(coordinator.allNotifications)
```

## Troubleshooting

### Notifications Not Appearing

1. Check notification permissions:
```swift
NotificationManager.shared.requestAuthorization()
```

2. Verify system is enabled:
```swift
AppSettingsModel.shared.enableIntelligentScheduling // Should be true
```

### Grades Not Being Monitored

1. Ensure monitoring is started:
```swift
IntelligentSchedulingCoordinator.shared.start()
```

2. Check threshold setting:
```swift
// Lower threshold for more sensitive detection
AppSettingsModel.shared.gradeChangeThreshold = 3.0
```

### Tasks Not Rescheduling

1. Verify auto-reschedule is enabled:
```swift
AppSettingsModel.shared.enableAutoReschedule // Should be true
```

2. Check work hours allow scheduling:
```swift
let service = EnhancedAutoRescheduleService.shared
print("Work hours: \(service.workHoursStart) - \(service.workHoursEnd)")
```

3. Ensure tasks are marked as overdue (check dueDate and status)

## Future Enhancements

Potential improvements:
- Machine learning for personalized study time recommendations
- Integration with calendar sync for external events
- Customizable notification preferences per course
- Batch rescheduling with dependency awareness
- Study session scheduling based on recommendations
- Analytics dashboard for grade trends and schedule effectiveness

## License

This code is part of the Itori application and follows the same license terms.
