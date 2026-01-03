# Timer Epic Implementation Checklist

**Epic**: Timer/Pomodoro/Stopwatch Feature Parity + AlarmKit + Live Activity + Task Alarms  
**Status**: 🟡 In Planning  
**Started**: 2026-01-03  
**Target Completion**: Week 5

---

## Phase 1: Feature Parity ⏳ Not Started

### 1.1 Activity Management UI
- [ ] Collections filter fully functional
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Filter by collection works
- [ ] Activity search with live filtering
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Search updates list in real-time
- [ ] Pinned activities section
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Pinned section appears at top
- [ ] Activity detail panel
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Selected activity shows details
- [ ] Match macOS layout structure
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Visual parity with macOS

### 1.2 Per-Activity Notes
- [ ] Add notes TextEditor
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Editor appears when activity selected
- [ ] Wire to TimerActivity.note
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Notes save and load correctly
- [ ] Auto-save on edit
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Changes persist without manual save
- [ ] Verify sync with macOS
  - Test: Notes appear on both platforms

### 1.3 Session History Enhancement
- [ ] Add session detail view
  - File: `Platforms/iOS/Scenes/Timer/RecentSessionsView.swift`
  - Test: Tapping session shows details
- [ ] Add activity filter
  - File: `Platforms/iOS/Scenes/Timer/RecentSessionsView.swift`
  - Test: Can filter by activity
- [ ] Add date range filter
  - File: `Platforms/iOS/Scenes/Timer/RecentSessionsView.swift`
  - Test: Can filter by date
- [ ] Display statistics
  - File: `Platforms/iOS/Scenes/Timer/RecentSessionsView.swift`
  - Test: Shows duration, activity, timestamps

### 1.4 iPad Layout Optimization
- [ ] Detect iPad size class
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Layout changes on iPad
- [ ] Two-column layout
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Activities left, timer right on iPad
- [ ] Responsive sizing
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Works in split view
- [ ] Match macOS approach
  - Test: Visual similarity to macOS

---

## Phase 2: AlarmKit Integration ⏳ Not Started

### 2.1 Enable AlarmKit Framework
- [ ] Remove `#if false` guard
  - File: `Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift`
  - Line: ~8
- [ ] Add availability checks
  - File: `Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift`
  - Test: Compiles on iOS 17+ and 26+
- [ ] Implement authorization request
  - File: `Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift`
  - Method: `requestAuthorizationIfNeeded()`
  - Test: Authorization prompt appears
- [ ] Handle authorization states
  - File: `Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift`
  - Test: Tracks .authorized, .denied, .notDetermined
- [ ] Add isAuthorized property
  - File: `Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift`
  - Test: Returns correct status

### 2.2 Wire AlarmKit to Timer Lifecycle
- [ ] Schedule alarm on startSession()
  - File: `SharedCore/State/TimerPageViewModel.swift`
  - Method: `startSession()`
  - Test: Alarm schedules when timer starts
- [ ] Cancel alarm on pauseSession()
  - File: `SharedCore/State/TimerPageViewModel.swift`
  - Method: `pauseSession()`
  - Test: Alarm cancels when paused
- [ ] Reschedule alarm on resumeSession()
  - File: `SharedCore/State/TimerPageViewModel.swift`
  - Method: `resumeSession()`
  - Test: Alarm reschedules with remaining time
- [ ] Cancel alarm on endSession()
  - File: `SharedCore/State/TimerPageViewModel.swift`
  - Method: `endSession()`
  - Test: Alarm cancels when stopped
- [ ] Verify stopwatch doesn't schedule
  - Test: No alarm in stopwatch mode

### 2.3 AlarmKit Settings UI
- [ ] Add "Enable AlarmKit" toggle
  - File: `Platforms/iOS/Scenes/Settings/Categories/IOSTimerSettingsView.swift`
  - Setting: `settings.alarmKitTimersEnabled`
  - Test: Toggle appears and persists
- [ ] Add authorization button
  - File: `Platforms/iOS/Scenes/Settings/Categories/IOSTimerSettingsView.swift`
  - Test: Button appears when not authorized
- [ ] Disable toggle when unauthorized
  - File: `Platforms/iOS/Scenes/Settings/Categories/IOSTimerSettingsView.swift`
  - Test: Can't enable without authorization
- [ ] Show availability status
  - File: `Platforms/iOS/Scenes/Settings/Categories/IOSTimerSettingsView.swift`
  - Test: Shows "Not Available" on iOS < 26

### 2.4 Fallback to Notifications
- [ ] Add notification scheduling
  - File: `SharedCore/State/TimerPageViewModel.swift`
  - Method: `scheduleCompletionNotification()`
  - Test: Notification schedules when AlarmKit unavailable
- [ ] Check AlarmKit availability
  - File: `SharedCore/State/TimerPageViewModel.swift`
  - Test: Uses notification when AlarmKit disabled
- [ ] Request notification permission
  - File: `SharedCore/State/TimerPageViewModel.swift`
  - Test: Permission prompt appears
- [ ] Avoid duplicate alerts
  - Test: No alarm + notification at same time

---

## Phase 3: Live Activity Enhancement ⏳ Not Started

### 3.1 Live Activity Content Improvements
- [ ] Add activityName to ContentState
  - File: `Shared/TimerLiveActivityAttributes.swift`
  - Test: Activity name displays
- [ ] Add completedCycles to ContentState
  - File: `Shared/TimerLiveActivityAttributes.swift`
  - Test: Pomodoro progress shows
- [ ] Add maxCycles to ContentState
  - File: `Shared/TimerLiveActivityAttributes.swift`
  - Test: Total cycles display
- [ ] Update Live Activity UI
  - File: `RootsTimerWidget/TimerLiveActivity.swift`
  - Test: New fields render correctly
- [ ] Test Dynamic Island
  - File: `RootsTimerWidget/TimerLiveActivity.swift`
  - Device: iPhone 14 Pro or later
  - Test: Shows in Dynamic Island
- [ ] Test Lock Screen widget
  - Test: Appears on Lock Screen
- [ ] Test StandBy mode
  - Device: iOS 17+
  - Test: Displays in StandBy

### 3.2 Update Throttling
- [ ] Implement throttle check
  - File: `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift`
  - Method: `sync()`
  - Test: Updates max once per second
- [ ] Add significant change detection
  - File: `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift`
  - Method: `hasSignificantChange()`
  - Test: State changes force update
- [ ] Skip redundant updates
  - File: `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift`
  - Test: No update if content identical
- [ ] Measure battery impact
  - Device: Real device
  - Test: < 5% battery drain per hour

### 3.3 Clean Teardown
- [ ] Implement end() method
  - File: `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift`
  - Method: `end()`
  - Test: Activity dismisses immediately
- [ ] Clear activity reference
  - File: `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift`
  - Test: activity = nil after end
- [ ] Reset state variables
  - File: `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift`
  - Test: lastUpdate, lastContentState cleared
- [ ] Verify no orphaned activities
  - Test: No activities remain after session end

---

## Phase 4: Task Alarm Integration ⏳ Not Started

### 4.1 Extend AppTask Model
- [ ] Add reminderEnabled field
  - File: `SharedCore/Features/Scheduler/AIScheduler.swift`
  - Type: `Bool`
  - Default: `false`
- [ ] Add reminderDate field
  - File: `SharedCore/Features/Scheduler/AIScheduler.swift`
  - Type: `Date?`
- [ ] Add reminderIdentifier field
  - File: `SharedCore/Features/Scheduler/AIScheduler.swift`
  - Type: `String?`
  - Purpose: For notification cancellation
- [ ] Update CodingKeys
  - File: `SharedCore/Features/Scheduler/AIScheduler.swift`
  - Test: Model persists correctly
- [ ] Update init()
  - File: `SharedCore/Features/Scheduler/AIScheduler.swift`
  - Test: New fields initialize

### 4.2 Task Alarm UI (macOS)
- [ ] Add bell icon to task row
  - File: `Platforms/macOS/Scenes/TimerPageView.swift`
  - Method: `taskCheckboxRow()`
  - Test: Bell icon visible
- [ ] Wire bell button action
  - File: `Platforms/macOS/Scenes/TimerPageView.swift`
  - Test: Tapping opens picker
- [ ] Show filled bell when active
  - File: `Platforms/macOS/Scenes/TimerPageView.swift`
  - Test: Icon changes with reminderEnabled
- [ ] Add alarm indicator in due date
  - File: `Platforms/macOS/Scenes/TimerPageView.swift`
  - Test: Shows bell badge

### 4.3 Task Alarm UI (iOS)
- [ ] Add bell icon to task row
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Method: `taskCheckboxRow()`
  - Test: Bell icon visible
- [ ] Wire bell button action
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Tapping opens picker
- [ ] Show filled bell when active
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Icon changes with reminderEnabled
- [ ] Add alarm indicator in due date
  - File: `Platforms/iOS/Views/IOSTimerPageView.swift`
  - Test: Shows bell badge

### 4.4 Alarm Picker Sheet
- [ ] Create TaskAlarmPickerView.swift
  - File: NEW `Platforms/iOS/Views/TaskAlarmPickerView.swift`
  - Test: File compiles
- [ ] Add Enable Reminder toggle
  - File: `Platforms/iOS/Views/TaskAlarmPickerView.swift`
  - Test: Toggle works
- [ ] Add DatePicker
  - File: `Platforms/iOS/Views/TaskAlarmPickerView.swift`
  - Components: date + hourAndMinute
  - Test: Picker appears when enabled
- [ ] Implement saveReminder()
  - File: `Platforms/iOS/Views/TaskAlarmPickerView.swift`
  - Test: Schedules notification
- [ ] Implement cancelExistingReminder()
  - File: `Platforms/iOS/Views/TaskAlarmPickerView.swift`
  - Test: Cancels notification
- [ ] Add Test Reminder button
  - File: `Platforms/iOS/Views/TaskAlarmPickerView.swift`
  - Test: Fires test notification in 5s
- [ ] Add macOS version
  - File: NEW `Platforms/macOS/Views/TaskAlarmPickerView.swift`
  - Test: Same functionality on macOS

### 4.5 Notification Integration
- [ ] Request notification permission
  - Test: Permission prompt appears
- [ ] Schedule calendar notification
  - Test: Notification schedules at correct time
- [ ] Cancel notification on disable
  - Test: Notification removed
- [ ] Handle notification tap
  - Test: Opens app to task
- [ ] Test delivery
  - Device: Real device
  - Test: Notification fires at set time

---

## Phase 5: Testing & Verification ⏳ Not Started

### 5.1 Unit Tests
- [ ] Create TimerAlarmSchedulerTests.swift
  - File: NEW `Tests/Unit/RootsTests/TimerAlarmSchedulerTests.swift`
  - Test: File created
- [ ] Test alarm scheduling
  - Method: `testAlarmScheduling()`
  - Test: Passes
- [ ] Test alarm cancellation
  - Method: `testAlarmCancellation()`
  - Test: Passes
- [ ] Test authorization flow
  - Method: `testAuthorizationRequest()`
  - Test: Passes
- [ ] Test fallback to notifications
  - Method: `testFallbackWhenUnauthorized()`
  - Test: Passes
- [ ] Create LiveActivityManagerTests.swift
  - File: NEW `Tests/Unit/RootsTests/LiveActivityManagerTests.swift`
- [ ] Test activity start
  - Test: Passes
- [ ] Test activity update
  - Test: Passes
- [ ] Test activity end
  - Test: Passes
- [ ] Test update throttling
  - Test: Passes
- [ ] Create TaskReminderTests.swift
  - File: NEW `Tests/Unit/RootsTests/TaskReminderTests.swift`
- [ ] Test reminder scheduling
  - Test: Passes
- [ ] Test reminder cancellation
  - Test: Passes
- [ ] Test reminder persistence
  - Test: Passes

### 5.2 UI Tests
- [ ] Create TimerLiveActivityUITests.swift
  - File: NEW `Tests/RootsUITests/TimerLiveActivityUITests.swift`
- [ ] Test Live Activity appearance
  - Method: `testLiveActivityAppearance()`
  - Test: Passes
- [ ] Test Live Activity updates
  - Method: `testLiveActivityUpdates()`
  - Test: Passes
- [ ] Test Live Activity dismissal
  - Method: `testLiveActivityDismissal()`
  - Test: Passes
- [ ] Create TaskAlarmUITests.swift
  - File: NEW `Tests/RootsUITests/TaskAlarmUITests.swift`
- [ ] Test alarm setting
  - Method: `testTaskAlarmSetting()`
  - Test: Passes
- [ ] Test alarm indicator
  - Method: `testAlarmIndicator()`
  - Test: Passes
- [ ] Test alarm cancellation
  - Method: `testAlarmCancellation()`
  - Test: Passes

### 5.3 Device Smoke Tests

#### iOS 17.0 Device
- [ ] Basic timer without AlarmKit
  - Device: iPhone/iPad iOS 17.0-25.x
  - Test: Timer works, uses notifications
- [ ] Live Activity appears
  - Test: Shows on Lock Screen
- [ ] Activity notes sync
  - Test: Notes save and load

#### iOS 26.0+ Device
- [ ] Timer with AlarmKit enabled
  - Device: iPhone/iPad iOS 26.0+
  - Test: Alarm fires loudly
- [ ] AlarmKit authorization
  - Test: Authorization prompt works
- [ ] Alarm cancellation
  - Test: Pausing cancels alarm
- [ ] Alarm rescheduling
  - Test: Resuming reschedules correctly

#### iPad Tests
- [ ] Split view layout
  - Device: iPad any iOS version
  - Test: Activities left, timer right
- [ ] Responsive sizing
  - Test: Works in split view
- [ ] All features work
  - Test: Full functionality on iPad

#### iPhone 14 Pro+ Tests
- [ ] Dynamic Island
  - Device: iPhone 14 Pro or later
  - Test: Timer shows in Dynamic Island
- [ ] Compact mode
  - Test: Time displays correctly

#### iOS 17+ Tests
- [ ] StandBy mode
  - Device: iOS 17+
  - Test: Timer visible in StandBy

#### Task Reminder Tests
- [ ] Set task reminder
  - Test: Picker opens and saves
- [ ] Notification fires
  - Device: Real device
  - Test: Notification appears at set time
- [ ] Reminder cancellation
  - Test: Notification doesn't fire when disabled

---

## Acceptance Criteria Summary

### Must Have ✅
- [ ] iOS matches macOS feature set (100% parity)
- [ ] AlarmKit fires reliably on iOS 26+ (when authorized)
- [ ] Live Activity appears and updates correctly
- [ ] Task reminders schedule and fire
- [ ] No AlarmKit code on macOS/watchOS
- [ ] Clean fallback when unavailable

### Should Have 🟡
- [ ] Dynamic Island support
- [ ] StandBy optimization
- [ ] iPad split-view optimized
- [ ] Update throttling (< 5% battery/hour)

### Nice to Have 🔵
- [ ] Custom alarm sounds
- [ ] Session analytics
- [ ] Siri shortcuts

---

## Progress Tracking

### Phase 1: Feature Parity
- **Status**: ⏳ Not Started
- **Progress**: 0/16 tasks complete (0%)
- **Blockers**: None
- **Est. Completion**: Week 1

### Phase 2: AlarmKit
- **Status**: ⏳ Not Started
- **Progress**: 0/16 tasks complete (0%)
- **Blockers**: AlarmKit beta API availability
- **Est. Completion**: Week 2

### Phase 3: Live Activity
- **Status**: ⏳ Not Started
- **Progress**: 0/14 tasks complete (0%)
- **Blockers**: None
- **Est. Completion**: Week 3

### Phase 4: Task Alarms
- **Status**: ⏳ Not Started
- **Progress**: 0/24 tasks complete (0%)
- **Blockers**: None
- **Est. Completion**: Week 4

### Phase 5: Testing
- **Status**: ⏳ Not Started
- **Progress**: 0/33 tasks complete (0%)
- **Blockers**: Phases 1-4 completion
- **Est. Completion**: Week 5

### Overall Progress
- **Total Tasks**: 103
- **Completed**: 0
- **In Progress**: 0
- **Blocked**: 0
- **Not Started**: 103
- **Overall**: 0% complete

---

## Notes & Decisions

### 2026-01-03
- ✅ Created epic plan
- ✅ Created architecture diagrams
- ✅ Created quick reference
- ✅ Created implementation checklist
- 📝 Next: Begin Phase 1 implementation

---

## Quick Links

- [Full Epic Plan](./TIMER_PARITY_ALARMKIT_LIVEACTIVITY_PLAN.md)
- [Quick Reference](./TIMER_EPIC_QUICK_REFERENCE.md)
- [Architecture Diagrams](./TIMER_ARCHITECTURE_DIAGRAMS.md)
- [Current Parity Audit](./Docs/Issues/ISSUE_401_PARITY_AUDIT.md)

---

**Last Updated**: 2026-01-03  
**Status**: 🟡 Planning Complete, Ready for Phase 1
