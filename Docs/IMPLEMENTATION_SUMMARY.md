# Intelligent Scheduling System - Implementation Summary

## Overview
I've implemented a comprehensive intelligent scheduling system for the Itori app that includes:
1. **Grade monitoring** with automatic study time recommendations
2. **Automatic task rescheduling** for overdue assignments
3. **Push notifications** for both features
4. **Settings UI** for iOS to configure and manage the system

## Files Created

### Core Services (4 files)

1. **SharedCore/Services/FeatureServices/GradeMonitoringService.swift**
   - Monitors grade changes across courses
   - Detects trends (improving/declining/stable)
   - Calculates study time recommendations based on grade decline severity
   - Sends push notifications for recommendations
   - Persists grade history to disk

2. **SharedCore/Services/FeatureServices/EnhancedAutoRescheduleService.swift**
   - Automatically detects overdue assignments
   - Finds optimal reschedule slots based on priority and free time
   - Respects work hours configuration
   - Sends detailed reschedule notifications
   - Runs automatic checks every hour

3. **SharedCore/Services/FeatureServices/IntelligentSchedulingCoordinator.swift**
   - Unified coordinator integrating both services
   - Manages all notifications in one place
   - Provides simple API for start/stop
   - Extends AppSettingsModel with configuration options

4. **Platforms/iOS/Scenes/Settings/Categories/IOSIntelligentSchedulingSettingsView.swift**
   - Complete settings UI for iOS
   - Enable/disable system toggle
   - Configure grade threshold (1-20%)
   - Set work hours for rescheduling
   - View study recommendations
   - View reschedule history
   - Manual check trigger button

### Documentation (2 files)

5. **Docs/INTELLIGENT_SCHEDULING_SYSTEM.md**
   - Complete documentation
   - Installation steps
   - Usage examples
   - Architecture diagrams
   - Configuration options
   - Troubleshooting guide

6. **Docs/INTELLIGENT_SCHEDULING_INTEGRATION_EXAMPLES.swift**
   - Practical integration examples
   - App initialization code
   - Dashboard widgets
   - Course detail integration
   - Settings integration
   - Notification handling

## Key Features

### Grade Monitoring
- ✅ Automatic grade tracking from GradesStore
- ✅ Trend analysis (3 most recent grades)
- ✅ Configurable threshold (default: 5% drop)
- ✅ Smart study time calculations:
  - 15% increase for 5-10 point drops
  - 25% increase for 10-15 point drops  
  - 35% increase for 15-20 point drops
  - 50% increase for 20+ point drops
- ✅ Push notifications with specific recommendations
- ✅ In-app notification list
- ✅ Per-course study hour tracking

### Auto-Rescheduling
- ✅ Automatic hourly checks for overdue tasks
- ✅ Priority-based scheduling:
  - Critical: ASAP
  - High: Within 3 days
  - Medium/Low: Next available
- ✅ Free time slot detection (14 days ahead)
- ✅ Work hours configuration (default: 8 AM - 10 PM)
- ✅ Conflict avoidance with existing assignments
- ✅ Detailed notifications with:
  - Old vs new deadline
  - Priority level
  - Estimated hours
  - Suggested start time
- ✅ Manual check trigger option

### User Interface
- ✅ Complete iOS settings screen
- ✅ System enable/disable toggle
- ✅ Grade threshold slider
- ✅ Work hours pickers
- ✅ Active recommendations list
- ✅ Recent reschedules list
- ✅ Unified notifications view
- ✅ Individual notification dismissal

## Integration Steps

### 1. Add Files to Xcode Project
Add all 4 Swift files to your Xcode project with proper target membership:
- GradeMonitoringService.swift → Shared Core target
- EnhancedAutoRescheduleService.swift → Shared Core target
- IntelligentSchedulingCoordinator.swift → Shared Core target
- IOSIntelligentSchedulingSettingsView.swift → iOS target

### 2. Initialize in App Startup
Add to `RootsIOSApp.swift` or equivalent:

```swift
@main
struct RootsIOSApp: App {
    @StateObject private var schedulingCoordinator = IntelligentSchedulingCoordinator.shared
    
    init() {
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

### 3. Add Settings Link
Add to your settings navigation:

```swift
NavigationLink {
    IOSIntelligentSchedulingSettingsView()
} label: {
    Label("Intelligent Scheduling", systemImage: "brain")
}
```

### 4. Add Grade Tracking
When saving grades, also track them:

```swift
// Save to GradesStore
GradesStore.shared.upsert(courseId: courseId, percent: score, letter: nil)

// Track for monitoring
IntelligentSchedulingCoordinator.shared.addGrade(
    courseId: courseId,
    score: score,
    assignmentName: "Assignment Name"
)
```

## Usage Example

```swift
// Start the system
IntelligentSchedulingCoordinator.shared.start()

// Add a grade
coordinator.addGrade(courseId: courseUUID, score: 78.5)

// Set study hours
coordinator.setStudyHours(courseId: courseUUID, weeklyHours: 6.0)

// Check overdue tasks manually
await coordinator.checkOverdueTasks()

// Get all notifications
let notifications = coordinator.allNotifications

// Dismiss a notification
coordinator.dismissNotification(notification)
```

## Data Flow

```
User enters grade
    ↓
GradesStore updated
    ↓
GradeMonitoringService observes change
    ↓
Analyzes trend (last 3 grades)
    ↓
If declining ≥ threshold → Calculate recommendation
    ↓
Send push notification + store in-app
    ↓
User sees notification in Settings or as banner
```

```
Hourly timer triggers
    ↓
EnhancedAutoRescheduleService checks assignments
    ↓
Find tasks where: dueDate < now && status != completed
    ↓
For each overdue task:
    - Calculate free time slots (next 14 days)
    - Filter by estimated duration
    - Select based on priority
    - Update assignment in store
    - Send notification
    ↓
User receives reschedule notification
```

## Configuration Options

### App Settings
```swift
// System toggle
AppSettingsModel.shared.enableIntelligentScheduling = true

// Grade threshold
AppSettingsModel.shared.gradeChangeThreshold = 5.0
```

### Coordinator Settings
```swift
// Grade threshold (1-20%)
coordinator.setGradeChangeThreshold(7.0)

// Work hours (0-23)
coordinator.setWorkHours(start: 8, end: 22)

// Check interval (seconds)
coordinator.setCheckInterval(3600)
```

### Service-Level Settings
```swift
// Grade monitoring
GradeMonitoringService.shared.gradeChangeThreshold = 5.0
GradeMonitoringService.shared.lookbackPeriod = 3

// Auto-reschedule
EnhancedAutoRescheduleService.shared.workHoursStart = 8
EnhancedAutoRescheduleService.shared.workHoursEnd = 22
EnhancedAutoRescheduleService.shared.checkInterval = 3600
```

## Testing Checklist

- [ ] Add files to Xcode project
- [ ] Build project successfully
- [ ] Initialize in app startup
- [ ] Add settings navigation link
- [ ] Test enabling/disabling system
- [ ] Add test grades to trigger recommendation
- [ ] Create overdue assignment to test rescheduling
- [ ] Verify push notifications appear
- [ ] Test manual check button
- [ ] Test notification dismissal
- [ ] Verify data persists across app restarts

## Dependencies

The system integrates with existing Itori stores:
- `GradesStore.shared` - For grade data
- `AssignmentsStore.shared` - For task data
- `CoursesStore.shared` - For course information
- `PlannerStore.shared` - For schedule coordination
- `NotificationManager.shared` - For push notifications
- `AppSettingsModel.shared` - For settings

## Notification Categories

Register these notification categories in your app:
- `STUDY_TIME_RECOMMENDATION` - Study time suggestions
- `TASK_RESCHEDULE` - Task rescheduled successfully
- `RESCHEDULE_FAILED` - Unable to reschedule task

## Storage Locations

- Grade history: `~/Library/Application Support/GradeMonitoring/grade_history.json`
- Study hours: Saved within grade history
- Settings: UserDefaults

## Architecture Highlights

✅ **Reactive** - Uses Combine for real-time updates
✅ **MainActor** - All operations on main thread for UI safety
✅ **Persistent** - Saves state to disk automatically
✅ **Observable** - Published properties for SwiftUI
✅ **Singleton** - Shared instances for app-wide access
✅ **Async/Await** - Modern Swift concurrency
✅ **Type-Safe** - Strong typing for all models
✅ **Testable** - Modular design for easy testing

## Next Steps

1. Add files to Xcode project
2. Update app initialization code
3. Add settings navigation link
4. Test with sample data
5. Customize thresholds and work hours as needed
6. Deploy to TestFlight for user testing

## Future Enhancements

- Machine learning for personalized recommendations
- Calendar integration for external events
- Batch rescheduling with dependencies
- Analytics dashboard
- Custom notification preferences per course
- Study session auto-scheduling

## Support

For questions or issues:
1. Check the documentation in `INTELLIGENT_SCHEDULING_SYSTEM.md`
2. Review integration examples in `INTELLIGENT_SCHEDULING_INTEGRATION_EXAMPLES.swift`
3. Verify all dependencies are properly connected
4. Check console logs with filter: "GradeMonitoring" or "EnhancedAutoReschedule"
