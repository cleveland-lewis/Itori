# Integration Checklist

Use this checklist to integrate the Intelligent Scheduling System into Itori.

## Pre-Integration

- [ ] Backup your project
- [ ] Commit current changes to git
- [ ] Ensure project builds successfully

## File Integration

### Core Services (SharedCore Target)

- [ ] Add `SharedCore/Services/FeatureServices/GradeMonitoringService.swift`
- [ ] Add `SharedCore/Services/FeatureServices/EnhancedAutoRescheduleService.swift`
- [ ] Add `SharedCore/Services/FeatureServices/IntelligentSchedulingCoordinator.swift`
- [ ] Verify files are in SharedCore target membership

### iOS UI (iOS Target)

- [ ] Add `Platforms/iOS/Scenes/Settings/Categories/IOSIntelligentSchedulingSettingsView.swift`
- [ ] Verify file is in iOS target membership

## Code Changes

### App Initialization

- [ ] Open `Platforms/iOS/App/RootsIOSApp.swift`
- [ ] Add coordinator initialization:
```swift
@StateObject private var schedulingCoordinator = IntelligentSchedulingCoordinator.shared

init() {
    Task { @MainActor in
        if AppSettingsModel.shared.enableIntelligentScheduling {
            IntelligentSchedulingCoordinator.shared.start()
        }
    }
}
```

### Settings Navigation

- [ ] Locate settings navigation view (e.g., `SettingsRootView.swift`)
- [ ] Add navigation link:
```swift
NavigationLink {
    IOSIntelligentSchedulingSettingsView()
} label: {
    Label("Intelligent Scheduling", systemImage: "brain")
}
```

### Grade Tracking Integration (Optional but Recommended)

- [ ] Locate grade input view (e.g., `IOSGradesView.swift` or similar)
- [ ] After saving grade to `GradesStore`, add tracking:
```swift
IntelligentSchedulingCoordinator.shared.addGrade(
    courseId: courseId,
    score: score,
    assignmentName: assignmentName
)
```

## Build & Test

### Build Phase

- [ ] Clean build folder (Cmd+Shift+K)
- [ ] Build project (Cmd+B)
- [ ] Resolve any compilation errors
- [ ] Run on simulator or device

### Basic Testing

- [ ] Launch app successfully
- [ ] Navigate to Settings → Intelligent Scheduling
- [ ] Toggle system ON
- [ ] Verify no crashes

### Grade Monitoring Test

- [ ] Enable Intelligent Scheduling in Settings
- [ ] Set grade threshold to 5%
- [ ] Go to Grades view
- [ ] Add 3 grades for a test course:
  - First: 90%
  - Second: 85%
  - Third: 77% (should trigger)
- [ ] Check Settings → Intelligent Scheduling → Active Recommendations
- [ ] Verify recommendation appears
- [ ] Check for notification banner

### Auto-Rescheduling Test

- [ ] Ensure system is enabled
- [ ] Create test assignment with due date = yesterday
- [ ] Mark status as NOT completed
- [ ] Wait 1 hour OR tap "Check Now" in Settings
- [ ] Verify assignment due date is updated
- [ ] Check for reschedule notification
- [ ] View in Settings → Intelligent Scheduling → Recent Reschedules

## Configuration

### Settings Verification

- [ ] Settings → Intelligent Scheduling exists
- [ ] System can be toggled on/off
- [ ] Grade threshold slider works (1-20%)
- [ ] Work hours pickers work
- [ ] "Check Now" button works
- [ ] Notification views accessible

### UserDefaults Keys

Verify these keys work:
- [ ] `enableIntelligentScheduling` (Bool)
- [ ] `gradeChangeThreshold` (Double)
- [ ] `enableAutoReschedule` (Bool)

## Documentation Review

- [ ] Read `QUICK_START_GUIDE.md`
- [ ] Review `IMPLEMENTATION_SUMMARY.md`
- [ ] Bookmark `INTELLIGENT_SCHEDULING_SYSTEM.md` for reference
- [ ] Review `INTELLIGENT_SCHEDULING_INTEGRATION_EXAMPLES.swift` for ideas

## Optional Enhancements

### Dashboard Integration

- [ ] Add `SchedulingNotificationsWidget` to dashboard
- [ ] Display notification count badge
- [ ] Add quick navigation to Settings

### Course Detail Integration

- [ ] Add study hours configuration to course detail
- [ ] Show active recommendations in course view
- [ ] Display grade trend visualization

### Custom Notification Handling

- [ ] Register notification categories
- [ ] Handle notification taps
- [ ] Navigate to relevant screens

## Production Checklist

### Before Release

- [ ] Test with real user data
- [ ] Verify notifications don't spam users
- [ ] Test with various grade thresholds
- [ ] Test with different work hours
- [ ] Verify data persistence across app restarts
- [ ] Test on multiple iOS versions
- [ ] Test on iPhone and iPad

### Performance

- [ ] Check CPU usage during hourly checks
- [ ] Verify memory usage is reasonable
- [ ] Test with large assignment lists (100+ items)
- [ ] Test with many courses (20+ courses)
- [ ] Monitor battery drain

### Privacy & Permissions

- [ ] Verify notification permissions requested properly
- [ ] Ensure data stays local (no network calls)
- [ ] Test with notifications disabled
- [ ] Verify system still works without notification permission

## Troubleshooting

### Build Errors

- [ ] Check target membership for all files
- [ ] Verify import statements
- [ ] Check Swift version compatibility
- [ ] Clean derived data if needed

### Runtime Issues

- [ ] Check console for errors (filter: "GradeMonitoring" or "EnhancedAutoReschedule")
- [ ] Verify stores are initialized
- [ ] Check notification permissions
- [ ] Verify system is enabled in settings

### No Notifications

- [ ] System Settings → Notifications → Itori → Allow
- [ ] App Settings → Intelligent Scheduling → Enabled
- [ ] Verify grade threshold isn't too high
- [ ] Verify overdue tasks exist and aren't completed

## Documentation

### For Team

- [ ] Share `QUICK_START_GUIDE.md` with team
- [ ] Add to project README
- [ ] Update architecture docs
- [ ] Add to onboarding materials

### For Users

- [ ] Add to in-app help/tutorial
- [ ] Update App Store description (optional)
- [ ] Create user guide (optional)
- [ ] Add to support articles (optional)

## Rollout Strategy

### Phase 1: Beta Testing

- [ ] Enable for beta testers only
- [ ] Collect feedback
- [ ] Monitor crash reports
- [ ] Adjust thresholds based on usage

### Phase 2: Gradual Rollout

- [ ] Release to 10% of users
- [ ] Monitor metrics
- [ ] Increase to 50%
- [ ] Full release

### Phase 3: Optimization

- [ ] Analyze usage patterns
- [ ] Optimize check frequency
- [ ] Fine-tune default thresholds
- [ ] Add requested features

## Success Metrics

### Track These

- [ ] % of users with feature enabled
- [ ] Number of study recommendations sent
- [ ] Number of tasks auto-rescheduled
- [ ] User retention with feature enabled
- [ ] Crash rate
- [ ] User feedback ratings

## Future Enhancements

### Consider Adding

- [ ] Machine learning for personalized recommendations
- [ ] Integration with calendar for external events
- [ ] Study session auto-scheduling
- [ ] Analytics dashboard
- [ ] Custom notification preferences per course
- [ ] Batch rescheduling with dependencies
- [ ] Grade prediction algorithms
- [ ] Study efficiency tracking

## Sign-Off

- [ ] Code reviewed by: _______________
- [ ] Tested by: _______________
- [ ] Approved by: _______________
- [ ] Merged to main: _______________
- [ ] Released to TestFlight: _______________
- [ ] Released to App Store: _______________

## Notes

Add any notes, issues, or observations here:

```
[Your notes here]
```

---

✅ **Checklist Complete?** You're ready to ship intelligent scheduling! 🚀
