# Intelligent Scheduling System - Quick Start Guide

## What You Get

🎯 **Automatic grade monitoring** that suggests more study time when grades drop
📅 **Automatic task rescheduling** for overdue assignments based on priority and free time
🔔 **Smart notifications** for both features

## 5-Minute Setup

### Step 1: Add Files to Xcode (2 min)

Drag these files into your Xcode project:

**Shared Core Target:**
- `SharedCore/Services/FeatureServices/GradeMonitoringService.swift`
- `SharedCore/Services/FeatureServices/EnhancedAutoRescheduleService.swift`
- `SharedCore/Services/FeatureServices/IntelligentSchedulingCoordinator.swift`

**iOS Target:**
- `Platforms/iOS/Scenes/Settings/Categories/IOSIntelligentSchedulingSettingsView.swift`

### Step 2: Initialize in App (1 min)

Add to `RootsIOSApp.swift` (or your main app file):

```swift
@main
struct RootsIOSApp: App {
    init() {
        // Add this
        Task { @MainActor in
            if AppSettingsModel.shared.enableIntelligentScheduling {
                IntelligentSchedulingCoordinator.shared.start()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            IOSRootView()
        }
    }
}
```

### Step 3: Add Settings Link (1 min)

In your settings file (e.g., `SettingsRootView.swift`), add:

```swift
NavigationLink {
    IOSIntelligentSchedulingSettingsView()
} label: {
    Label("Intelligent Scheduling", systemImage: "brain")
}
```

### Step 4: Enable in App (1 min)

1. Build and run the app
2. Go to Settings → Intelligent Scheduling
3. Toggle "Intelligent Scheduling" ON
4. Done! ✅

## How to Use

### For Grade Monitoring

**When you enter grades:**
```swift
// In your grades input view, after saving to GradesStore:
IntelligentSchedulingCoordinator.shared.addGrade(
    courseId: courseUUID,
    score: gradeScore,
    assignmentName: "Midterm Exam"  // Optional
)
```

**What happens automatically:**
- Tracks grade trends (improving/declining/stable)
- When grades drop ≥5%, calculates recommended study time increase
- Sends push notification with specific recommendation
- Shows in-app notification in Settings

**Example notification:**
> 📚 Study Time Recommendation
> 
> Mathematics: Your grades have declined. Consider increasing study time from 5.0 to 7.5 hours per week (+2.5 hours).

### For Auto-Rescheduling

**No code needed!** The system:
- Checks every hour for overdue assignments
- Finds the best available time slot
- Updates the assignment automatically
- Sends notification with new deadline

**Example notification:**
> 📅 Task Rescheduled: 'Physics Lab Report'
> 
> Original deadline: Jan 2, 2026 8:00 PM
> New deadline: Jan 4, 2026 2:00 PM
> Priority: High
> Estimated time needed: 3.0 hours
> Suggested start: Jan 4, 2026 11:00 AM

## Quick Tips

### Adjust Grade Sensitivity
Settings → Intelligent Scheduling → Grade Change Threshold slider (1-20%)
- Lower = more sensitive (triggers at smaller drops)
- Higher = less sensitive (only major drops)

### Set Your Work Hours
Settings → Intelligent Scheduling → Work Hours Start/End
- Tasks will only be rescheduled within these hours
- Default: 8 AM - 10 PM

### Manual Check
Settings → Intelligent Scheduling → Check Now button
- Manually trigger overdue task check
- Useful after adding many assignments

### View Notifications
Settings → Intelligent Scheduling → View All Notifications
- See all study recommendations
- See all task reschedules
- Dismiss individual notifications

## Common Scenarios

### Scenario 1: Grades Dropping
```
You: Enter grade 78% (down from 85%)
System: Detects 7% drop
System: Calculates +25% study time needed
System: Sends notification: "Increase study time from 6 to 7.5 hrs/week"
You: See notification in Settings → Intelligent Scheduling
```

### Scenario 2: Assignment Overdue
```
11:00 PM: Assignment was due at 6:00 PM today
Next hour: System detects overdue assignment
System: Finds next free 2-hour slot (tomorrow 2 PM)
System: Updates assignment due date to tomorrow 2 PM
System: Sends notification with new deadline
You: See notification and updated assignment
```

### Scenario 3: Multiple Overdue Tasks
```
System: Finds 3 overdue tasks (Critical, High, Medium priority)
System: Schedules Critical task ASAP (tomorrow 9 AM)
System: Schedules High task within 3 days (Jan 5)
System: Schedules Medium task next available (Jan 8)
System: Sends 3 separate notifications
```

## Testing It Out

### Test Grade Monitoring:

1. Go to Settings → Intelligent Scheduling → Enable it
2. Set threshold to 5%
3. In Grades, add these for a test course:
   - First: 90%
   - Second: 85%
   - Third: 78% ← This should trigger!
4. Check Settings → Intelligent Scheduling → Active Recommendations

### Test Auto-Rescheduling:

1. Enable system in Settings
2. Create an assignment with due date = yesterday
3. Wait 1 hour OR tap "Check Now" button
4. See the reschedule notification
5. Check the assignment - due date updated!

## Troubleshooting

### "No notifications appearing"
✅ Check: Settings → Notifications → Allow notifications
✅ Check: Settings → Intelligent Scheduling → System is enabled
✅ Try: Settings → Intelligent Scheduling → Check Now

### "Grades not being monitored"
✅ Check: You called `coordinator.addGrade()` after saving grade
✅ Check: Grade threshold isn't set too high
✅ Check: You have at least 3 grades entered for the course

### "Tasks not rescheduling"
✅ Check: Task status is not "Completed"
✅ Check: Due date is actually in the past
✅ Check: Work hours allow scheduling (not all outside work hours)
✅ Try: Manual "Check Now" button

## What Gets Stored

### Grade History
- Location: `~/Library/Application Support/GradeMonitoring/`
- Contains: Grade snapshots, study hours per course
- Persists: Across app launches

### Settings
- Stored in: UserDefaults
- Contains: Enabled state, thresholds, work hours
- Persists: Across app launches

## Configuration Cheat Sheet

```swift
// Enable/disable entire system
AppSettingsModel.shared.enableIntelligentScheduling = true/false

// Grade threshold (1-20%)
AppSettingsModel.shared.gradeChangeThreshold = 5.0

// Work hours (0-23)
coordinator.setWorkHours(start: 8, end: 22)

// Check interval (seconds)
coordinator.setCheckInterval(3600) // 1 hour
```

## Advanced Usage

### Set Study Hours per Course
```swift
IntelligentSchedulingCoordinator.shared.setStudyHours(
    courseId: courseUUID,
    weeklyHours: 8.0
)
```

### Get Recommendation for Specific Course
```swift
if let rec = coordinator.getStudyRecommendation(for: courseId) {
    print("Need \(rec.additionalHours) more hours per week")
}
```

### Dismiss Notification
```swift
coordinator.dismissNotification(notification)
```

### Check All Notifications
```swift
let count = coordinator.allNotifications.count
for notification in coordinator.allNotifications {
    // Handle notification
}
```

## Dashboard Integration (Optional)

Want to show notifications on your dashboard? See `INTELLIGENT_SCHEDULING_INTEGRATION_EXAMPLES.swift` for:
- Dashboard widget code
- Course detail integration
- Notification row components
- Complete UI examples

## Performance Notes

- ✅ All operations on main thread (UI safe)
- ✅ Minimal battery impact (hourly checks only)
- ✅ Efficient data structures (indexed lookups)
- ✅ Saves to disk asynchronously
- ✅ No network requests needed

## Privacy

- ✅ All data stored locally
- ✅ No data sent to servers
- ✅ No analytics tracking
- ✅ User has full control

## Next Steps

1. ✅ Complete 5-minute setup
2. ✅ Test with sample data
3. ✅ Customize thresholds to your preference
4. ✅ (Optional) Add dashboard widgets
5. ✅ (Optional) Customize notification handling

## Need Help?

📖 Full documentation: `INTELLIGENT_SCHEDULING_SYSTEM.md`
💻 Code examples: `INTELLIGENT_SCHEDULING_INTEGRATION_EXAMPLES.swift`
📋 Implementation details: `IMPLEMENTATION_SUMMARY.md`

---

**That's it! You now have intelligent grade monitoring and auto-rescheduling in your app.** 🎉
