# Timer Epic - Quick Reference

## 🎯 Goal
Full iOS/iPadOS ↔ macOS timer parity + AlarmKit loud alarms + Live Activity + Per-task reminders

## 📋 Implementation Phases

### Phase 1: Feature Parity (Week 1)
- [ ] Collections filter fully functional
- [ ] Activity search with live filtering  
- [ ] Pinned activities section
- [ ] Per-activity notes editor
- [ ] Session history detail view
- [ ] iPad split-view layout

**Key Files:**
- `Platforms/iOS/Views/IOSTimerPageView.swift`
- `Platforms/iOS/Scenes/Timer/RecentSessionsView.swift`

### Phase 2: AlarmKit (Week 2)
- [ ] Remove `#if false` from `TimerAlarmScheduler.swift`
- [ ] Add authorization request flow
- [ ] Wire to timer start/pause/resume/stop
- [ ] Add settings toggle
- [ ] Implement notification fallback

**Key Files:**
- `Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift`
- `SharedCore/State/TimerPageViewModel.swift`
- `Platforms/iOS/Scenes/Settings/Categories/IOSTimerSettingsView.swift`

**Platform Guards:**
```swift
#if os(iOS)
#if canImport(AlarmKit)
@available(iOS 26.0, *)
// AlarmKit code
#endif
#endif
```

### Phase 3: Live Activity (Week 3)
- [ ] Add activity name to ContentState
- [ ] Add pomodoro progress indicators
- [ ] Implement update throttling
- [ ] Ensure clean teardown
- [ ] Test Dynamic Island
- [ ] Test StandBy mode

**Key Files:**
- `RootsTimerWidget/TimerLiveActivity.swift`
- `Shared/TimerLiveActivityAttributes.swift`
- `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift`

### Phase 4: Task Alarms (Week 4)
- [ ] Add `reminderEnabled`, `reminderDate` to `AppTask`
- [ ] Add bell icon to task rows
- [ ] Create alarm picker sheet
- [ ] Schedule notifications
- [ ] Handle reminder cancellation

**Key Files:**
- `SharedCore/Features/Scheduler/AIScheduler.swift` (model)
- `Platforms/macOS/Scenes/TimerPageView.swift` (macOS UI)
- `Platforms/iOS/Views/IOSTimerPageView.swift` (iOS UI)
- Create: `Platforms/iOS/Views/TaskAlarmPickerView.swift`

### Phase 5: Testing (Week 5)
- [ ] Unit tests for AlarmKit scheduler
- [ ] UI tests for Live Activity
- [ ] Device smoke tests (iOS 17+, iOS 26+)
- [ ] iPad layout testing
- [ ] Task reminder testing

---

## 🔑 Key Integration Points

### Timer Lifecycle → AlarmKit
```swift
// startSession()
alarmScheduler.scheduleTimerEnd(id: session.id, fireIn: duration, ...)

// pauseSession()  
alarmScheduler.cancelTimer(id: session.id)

// resumeSession()
alarmScheduler.scheduleTimerEnd(id: session.id, fireIn: remaining, ...)

// endSession()
alarmScheduler.cancelTimer(id: session.id)
```

### Timer State → Live Activity
```swift
// Sync on every state change
liveActivityManager.sync(
    currentMode: mode,
    session: currentSession,
    elapsed: sessionElapsed,
    remaining: sessionRemaining,
    isOnBreak: isOnBreak
)

// End when session ends
if session.state == .completed || session.state == .cancelled {
    await liveActivityManager.end()
}
```

### Task → Reminder
```swift
// Schedule
let content = UNMutableNotificationContent()
content.title = "Task Due Soon"
content.body = task.title

let trigger = UNCalendarNotificationTrigger(dateMatching: components)
let request = UNNotificationRequest(identifier: task.reminderIdentifier, ...)

UNUserNotificationCenter.current().add(request)

// Cancel
UNUserNotificationCenter.current().removePendingNotificationRequests(
    withIdentifiers: [task.reminderIdentifier]
)
```

---

## ✅ Acceptance Criteria

### Must Have
- [x] iOS matches macOS feature set (100% parity)
- [ ] AlarmKit fires reliably on iOS 26+ (when authorized)
- [ ] Live Activity appears and updates correctly
- [ ] Task reminders schedule and fire
- [ ] No AlarmKit code on macOS/watchOS
- [ ] Clean fallback when unavailable

### Should Have
- [ ] Dynamic Island support
- [ ] StandBy optimization
- [ ] iPad split-view optimized
- [ ] Update throttling (< 5% battery/hour)

### Nice to Have
- [ ] Custom alarm sounds
- [ ] Session analytics
- [ ] Siri shortcuts

---

## 🧪 Test Plan Summary

### Unit Tests
- `TimerAlarmSchedulerTests`: Authorization, scheduling, cancellation
- `LiveActivityManagerTests`: Start, update, end, throttling
- `TaskReminderTests`: Schedule, cancel, persistence

### UI Tests  
- Timer flow: start → background → alarm fires
- Live Activity: appears → updates → ends
- Task alarm: set → notification fires

### Device Tests
- iOS 17.0: Basic timer, no AlarmKit
- iOS 26.0+: Full AlarmKit integration
- iPad: Split view layout
- iPhone 14 Pro+: Dynamic Island
- StandBy mode display

---

## 🐛 Common Issues & Solutions

### AlarmKit not available
**Problem**: `#if canImport(AlarmKit)` returns false  
**Solution**: Ensure iOS deployment target is 26.0+, check Xcode beta

### Live Activity doesn't appear
**Problem**: Activity not showing on Lock Screen  
**Solution**: Check `ActivityAuthorizationInfo().areActivitiesEnabled`, verify entitlements

### Alarm doesn't fire
**Problem**: Alarm scheduled but no sound  
**Solution**: Check authorization status, verify alarm not canceled, check Do Not Disturb

### Task reminder not scheduling
**Problem**: Notification doesn't schedule  
**Solution**: Request notification authorization first, check date is in future

---

## 📊 Progress Tracking

### Current Status: ✅ PLANNED
- [x] Epic plan created
- [x] Architecture designed
- [ ] Phase 1 started
- [ ] Phase 2 started
- [ ] Phase 3 started
- [ ] Phase 4 started
- [ ] Phase 5 started

### Blockers
- None currently

### Dependencies
- AlarmKit public API availability (iOS 26.0 beta)
- ActivityKit authorization
- UserNotifications authorization

---

## 📚 Resources

- **Full Plan**: `TIMER_PARITY_ALARMKIT_LIVEACTIVITY_PLAN.md`
- **Current Parity Audit**: `Docs/Issues/ISSUE_401_PARITY_AUDIT.md`
- **ActivityKit Docs**: https://developer.apple.com/documentation/activitykit
- **AlarmKit**: Apple Developer (when available)
- **Existing Code**:
  - `SharedCore/State/TimerPageViewModel.swift` (engine)
  - `Platforms/iOS/Views/IOSTimerPageView.swift` (iOS UI)
  - `Platforms/macOS/Scenes/TimerPageView.swift` (macOS UI)
  - `Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift` (stub)
  - `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift` (partial)

---

## 🚀 Quick Start Commands

### Build iOS
```bash
xcodebuild -scheme Roots -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### Run iOS Tests
```bash
xcodebuild -scheme Roots -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```

### Check AlarmKit Availability
```swift
#if os(iOS)
#if canImport(AlarmKit)
print("AlarmKit available")
#else
print("AlarmKit NOT available")
#endif
#endif
```

---

**Last Updated**: 2026-01-03  
**Status**: Ready for Phase 1 implementation
