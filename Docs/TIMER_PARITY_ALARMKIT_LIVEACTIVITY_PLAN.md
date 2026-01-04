# Timer/Pomodoro/Stopwatch Feature Parity + AlarmKit + Live Activity
**Epic Implementation Plan**

## Executive Summary
Bring iOS/iPadOS Timer apps to full feature parity with macOS, integrate AlarmKit for reliable timer completion alerts (iOS/iPadOS only), and implement Live Activity for Lock Screen/Dynamic Island/StandBy. Additionally, add per-task alarm setting capability in the task list.

## Current State Analysis

### ✅ Already Implemented
1. **Shared Engine** - `TimerPageViewModel` in SharedCore
2. **Basic Modes** - Timer, Pomodoro, Stopwatch, Focus
3. **Core Controls** - Start/Pause/Resume/Stop/Skip
4. **Live Activity Hook** - `IOSTimerLiveActivityManager` exists
5. **AlarmKit Stub** - `IOSTimerAlarmScheduler` stub exists (disabled)
6. **Task Integration** - Tasks Due Today/This Week sections added to Timer page

### ❌ Missing / Incomplete

#### A. Feature Parity (iOS ↔ macOS)
- [ ] Activity collections filter fully functional
- [ ] Activity search with live filtering
- [ ] Pinned activities section
- [ ] Per-activity notes editor
- [ ] Session history with detail view
- [ ] iPad split-view layout optimization
- [ ] Activity quick actions menu

#### B. AlarmKit Integration (iOS/iPadOS only)
- [ ] Enable AlarmKit scheduling (currently disabled with `#if false`)
- [ ] Request and handle authorization
- [ ] Schedule alarms on timer start
- [ ] Cancel alarms on pause/stop
- [ ] Fallback to notifications when unavailable
- [ ] User settings:
  - Enable/disable AlarmKit
  - Sound selection (v1: default)
  - Alarm presentation configuration

#### C. Live Activity Enhancement
- [ ] Verify Live Activity starts on session start
- [ ] Update throttling (avoid battery drain)
- [ ] Proper state updates (running/paused/completed)
- [ ] Clean teardown on session end
- [ ] Dynamic Island support
- [ ] StandBy mode optimization

#### D. Task Alarm Integration (NEW)
- [ ] Add "Set Reminder" option per task
- [ ] Due date/time picker for task alarms
- [ ] Integrate with iOS Reminders or local notifications
- [ ] Display alarm badge on tasks with reminders
- [ ] Manage task reminders (edit/delete)

## Implementation Phases

---

## Phase 1: Feature Parity Audit & Completion
**Goal**: iOS/iPadOS Timer UI matches macOS capabilities

### 1.1 Activity Management UI
**Files**: `Platforms/iOS/Views/IOSTimerPageView.swift`

- [x] Collections filter (already present)
- [x] Search bar (already present)
- [ ] Implement Pinned section in activity list
- [ ] Add activity detail panel (selected activity info)
- [ ] Match layout structure to macOS `rightPane`

**Acceptance**: 
- Activity list shows Pinned section at top
- Search filters activities in real-time
- Collections filter works correctly

### 1.2 Per-Activity Notes
**Files**: `Platforms/iOS/Views/IOSTimerPageView.swift`

- [ ] Add notes TextEditor in activity detail section
- [ ] Wire notes to `TimerActivity.note` property
- [ ] Auto-save on edit
- [ ] Sync with macOS via shared ViewModel

**Acceptance**:
- Notes editor visible when activity selected
- Changes persist across app restarts
- Notes sync between iOS and macOS

### 1.3 Session History Enhancement
**Files**: `Platforms/iOS/Scenes/Timer/RecentSessionsView.swift`

- [ ] Add session detail view (duration, activity, timestamps)
- [ ] Add filter by activity
- [ ] Add date range filter
- [ ] Display session statistics

**Acceptance**:
- Recent sessions list shows full details
- Can filter by activity or date
- Matches macOS history functionality

### 1.4 iPad Layout Optimization
**Files**: `Platforms/iOS/Views/IOSTimerPageView.swift`

- [ ] Detect iPad size class
- [ ] Use two-column layout on iPad (activities left, timer+details right)
- [ ] Responsive sizing for split view
- [ ] Match macOS three-column approach on larger iPads

**Acceptance**:
- iPad shows optimized layout
- Split view works correctly
- Maintains functionality in compact mode

---

## Phase 2: AlarmKit Integration (iOS/iPadOS Only)
**Goal**: Reliable, loud timer completion alerts

### 2.1 Enable AlarmKit Framework
**Files**: 
- `Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift`
- `ItoriApp.xcodeproj` (capabilities)

#### Changes:
1. Remove `#if false` disabling AlarmKit
2. Add proper availability checks
3. Request authorization on first use
4. Handle authorization states

```swift
// TimerAlarmScheduler.swift updates:
@available(iOS 17.0, *)
final class IOSTimerAlarmScheduler: TimerAlarmScheduling {
    private var authorizationStatus: AlarmAuthorizationStatus = .notDetermined
    
    // Add authorization request
    func requestAuthorizationIfNeeded() async -> Bool {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return false }
        
        do {
            authorizationStatus = try await AlarmManager.shared.requestAuthorization()
            return authorizationStatus == .authorized
        } catch {
            LOG_UI(.error, "AlarmKit", "Authorization failed: \(error)")
            return false
        }
        #else
        return false
        #endif
    }
    
    var isAuthorized: Bool {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return false }
        return authorizationStatus == .authorized
        #else
        return false
        #endif
    }
}
```

**Acceptance**:
- Authorization prompt appears on first timer start (if setting enabled)
- Authorization status tracked correctly
- Falls back gracefully when denied

### 2.2 Wire AlarmKit to Timer Lifecycle
**Files**: `SharedCore/State/TimerPageViewModel.swift`

#### Changes:
```swift
// In TimerPageViewModel
func startSession() {
    // ... existing start logic ...
    
    // Schedule alarm for timer end
    if let scheduler = alarmScheduler, currentMode != .stopwatch {
        let duration = currentMode == .pomodoro ? 
            (isOnBreak ? breakDuration : focusDuration) : timerDuration
        
        scheduler.scheduleTimerEnd(
            id: session.id.uuidString,
            fireIn: duration,
            title: "Timer Complete",
            body: currentMode == .pomodoro ? 
                (isOnBreak ? "Break finished" : "Work session finished") : 
                "Timer finished"
        )
    }
}

func pauseSession() {
    // ... existing pause logic ...
    
    // Cancel alarm when paused
    if let scheduler = alarmScheduler, let session = currentSession {
        scheduler.cancelTimer(id: session.id.uuidString)
    }
}

func resumeSession() {
    // ... existing resume logic ...
    
    // Reschedule with remaining time
    if let scheduler = alarmScheduler, currentMode != .stopwatch {
        scheduler.scheduleTimerEnd(
            id: session.id.uuidString,
            fireIn: sessionRemaining,
            title: "Timer Complete",
            body: "Timer resumed"
        )
    }
}

func endSession(completed: Bool) {
    // ... existing end logic ...
    
    // Cancel any pending alarms
    if let scheduler = alarmScheduler, let session = currentSession {
        scheduler.cancelTimer(id: session.id.uuidString)
    }
}
```

**Acceptance**:
- Alarm schedules when timer starts
- Alarm cancels when paused/stopped
- Alarm reschedules with correct remaining time on resume
- Stopwatch mode doesn't schedule alarms

### 2.3 AlarmKit Settings UI
**Files**: `Platforms/iOS/Scenes/Settings/Categories/IOSTimerSettingsView.swift`

#### Add Settings Section:
```swift
Section("Alarms") {
    Toggle("Enable AlarmKit", isOn: $settings.alarmKitTimersEnabled)
        .disabled(!alarmScheduler.isAuthorized)
    
    if !alarmScheduler.isAuthorized {
        Button("Request Authorization") {
            Task {
                await alarmScheduler.requestAuthorizationIfNeeded()
            }
        }
        .buttonStyle(.bordered)
    }
    
    // Future: Sound selection
    // Picker("Alarm Sound", selection: $settings.timerAlarmSound) { ... }
}
.listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
```

**Acceptance**:
- Settings toggle appears under Timer settings
- Authorization button shown when not authorized
- Disabled state shows when AlarmKit unavailable

### 2.4 Fallback to Notifications
**Files**: `SharedCore/State/TimerPageViewModel.swift`

#### Add Notification Fallback:
```swift
private func scheduleCompletionNotification() {
    // Only schedule if AlarmKit not available/enabled
    guard alarmScheduler?.isEnabled == false else { return }
    
    let content = UNMutableNotificationContent()
    content.title = "Timer Complete"
    content.body = "Your \(currentMode.displayName) session has finished"
    content.sound = .default
    content.categoryIdentifier = "TIMER_COMPLETE"
    
    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: sessionRemaining,
        repeats: false
    )
    
    let request = UNNotificationRequest(
        identifier: currentSession?.id.uuidString ?? UUID().uuidString,
        content: content,
        trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request)
}
```

**Acceptance**:
- Notification schedules when AlarmKit unavailable
- User sees clear message about notification vs alarm
- No duplicate alerts (alarm + notification)

---

## Phase 3: Live Activity Enhancement
**Goal**: Polish Live Activity presentation and updates

### 3.1 Live Activity Content Improvements
**Files**: 
- `ItoriTimerWidget/TimerLiveActivity.swift`
- `Shared/TimerLiveActivityAttributes.swift`

#### Enhance ContentState:
```swift
struct ContentState: Codable, Hashable {
    var mode: String
    var label: String
    var remainingSeconds: Int
    var elapsedSeconds: Int
    var isRunning: Bool
    var isOnBreak: Bool
    var activityName: String?  // NEW: Show activity name
    var completedCycles: Int?  // NEW: Pomodoro progress
    var maxCycles: Int?        // NEW: Pomodoro total
}
```

#### Enhanced Live Activity UI:
```swift
// TimerLiveActivity.swift
DynamicIsland {
    DynamicIslandExpandedRegion(.leading) {
        Text(context.state.mode)
            .font(.caption.weight(.medium))
    }
    
    DynamicIslandExpandedRegion(.trailing) {
        if let activity = context.state.activityName {
            Text(activity)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    DynamicIslandExpandedRegion(.center) {
        Text(timerDisplay(context.state))
            .font(.largeTitle.monospacedDigit())
    }
    
    DynamicIslandExpandedRegion(.bottom) {
        if let completed = context.state.completedCycles,
           let max = context.state.maxCycles {
            pomodoroProgress(completed: completed, max: max)
        }
    }
}
```

**Acceptance**:
- Live Activity shows mode, timer, and activity name
- Dynamic Island displays properly
- Lock Screen widget shows correct info
- StandBy mode works

### 3.2 Update Throttling
**Files**: `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift`

#### Optimize Update Frequency:
```swift
func sync(...) {
    // Check if enough time passed since last update
    if let last = lastUpdate, Date().timeIntervalSince(last) < minUpdateInterval {
        // Skip update unless state changed significantly
        guard hasSignificantChange(contentState) else { return }
    }
    
    lastUpdate = Date()
    
    // Only update if content actually changed
    guard contentState != lastContentState else { return }
    
    // Update activity
    // ...
}

private func hasSignificantChange(_ state: TimerLiveActivityAttributes.ContentState) -> Bool {
    guard let last = lastContentState else { return true }
    
    // Significant changes that warrant immediate update
    return state.isRunning != last.isRunning ||
           state.isOnBreak != last.isOnBreak ||
           state.mode != last.mode
}
```

**Acceptance**:
- Updates happen every 1 second during running
- No updates when paused (except state change)
- Battery impact minimized

### 3.3 Clean Teardown
**Files**: `Platforms/iOS/PlatformAdapters/TimerLiveActivityManager.swift`

#### Ensure Clean End:
```swift
func end() async {
    guard let activity else { return }
    
    // End with final state
    await activity.end(
        ActivityContent(
            state: lastContentState ?? defaultEndState,
            staleDate: nil
        ),
        dismissalPolicy: .immediate
    )
    
    self.activity = nil
    lastUpdate = nil
    lastContentState = nil
}
```

**Acceptance**:
- Live Activity ends immediately when session stops
- No orphaned activities
- Clean state reset

---

## Phase 4: Task Alarm Integration
**Goal**: Per-task reminder/alarm setting

### 4.1 Extend AppTask Model
**Files**: `SharedCore/Features/Scheduler/AIScheduler.swift`

#### Add Alarm Fields:
```swift
struct AppTask: Codable, Equatable, Hashable {
    // ... existing fields ...
    var reminderEnabled: Bool = false
    var reminderDate: Date?
    var reminderIdentifier: String?  // For cancellation
}
```

### 4.2 Task Alarm UI
**Files**: `Platforms/macOS/Scenes/TimerPageView.swift`, `Platforms/iOS/Views/IOSTimerPageView.swift`

#### Update Task Row:
```swift
private func taskCheckboxRow(_ task: AppTask) -> some View {
    Button(action: { toggleTaskCompletion(task) }) {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isCompleted ? .green : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                if let due = task.due {
                    HStack(spacing: 4) {
                        Text(due, style: .date)
                            .font(.caption2)
                        
                        // NEW: Alarm indicator
                        if task.reminderEnabled {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // NEW: Alarm button
            Button {
                showAlarmPicker(for: task)
            } label: {
                Image(systemName: task.reminderEnabled ? "bell.fill" : "bell")
                    .foregroundColor(task.reminderEnabled ? .orange : .secondary)
            }
            .buttonStyle(.plain)
        }
    }
}
```

### 4.3 Alarm Picker Sheet
**Files**: Create new file `Platforms/iOS/Views/TaskAlarmPickerView.swift`

```swift
struct TaskAlarmPickerView: View {
    @Binding var task: AppTask
    @Environment(\.dismiss) private var dismiss
    @State private var reminderDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Reminder", isOn: $task.reminderEnabled)
                    
                    if task.reminderEnabled {
                        DatePicker(
                            "Remind me",
                            selection: $reminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                
                if task.reminderEnabled {
                    Section {
                        Button("Test Reminder") {
                            testReminder()
                        }
                    }
                }
            }
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReminder()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveReminder() {
        guard task.reminderEnabled else {
            cancelExistingReminder()
            return
        }
        
        // Schedule notification
        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = task.title
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let identifier = task.reminderIdentifier ?? UUID().uuidString
        task.reminderIdentifier = identifier
        task.reminderDate = reminderDate
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelExistingReminder() {
        guard let identifier = task.reminderIdentifier else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
        task.reminderIdentifier = nil
        task.reminderDate = nil
    }
    
    private func testReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Test Reminder"
        content.body = task.title
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

**Acceptance**:
- Bell icon appears next to each task
- Tapping bell opens date/time picker
- Reminder schedules correctly
- Reminder cancels when disabled
- Bell icon shows filled when reminder active

---

## Phase 5: Testing & Verification

### 5.1 Unit Tests
**Files**: Create `Tests/Unit/ItoriTests/TimerAlarmSchedulerTests.swift`

```swift
@available(iOS 17.0, *)
final class TimerAlarmSchedulerTests: XCTestCase {
    func testAlarmScheduling() async {
        let scheduler = IOSTimerAlarmScheduler()
        // Mock AlarmKit if needed
        
        scheduler.scheduleTimerEnd(
            id: "test-1",
            fireIn: 60,
            title: "Test",
            body: "Test alarm"
        )
        
        // Verify alarm scheduled
    }
    
    func testAlarmCancellation() {
        let scheduler = IOSTimerAlarmScheduler()
        
        scheduler.scheduleTimerEnd(id: "test-2", fireIn: 60, title: "Test", body: "Test")
        scheduler.cancelTimer(id: "test-2")
        
        // Verify alarm canceled
    }
    
    func testFallbackWhenUnauthorized() {
        // Verify notification fallback when AlarmKit denied
    }
}
```

### 5.2 UI Tests
**Files**: `Tests/ItoriUITests/TimerLiveActivityUITests.swift`

```swift
final class TimerLiveActivityUITests: XCTestCase {
    func testLiveActivityAppearance() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to timer
        app.buttons["Timer"].tap()
        
        // Start a timer
        app.buttons["Start"].tap()
        
        // Background the app
        XCUIDevice.shared.press(.home)
        
        // Verify Live Activity appears (check Lock Screen)
        // Note: This requires device testing
    }
    
    func testTaskAlarmSetting() {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Timer"].tap()
        
        // Find a task
        let taskRow = app.buttons.matching(identifier: "TaskRow").firstMatch
        XCTAssertTrue(taskRow.exists)
        
        // Tap alarm button
        taskRow.buttons["bell"].tap()
        
        // Verify picker appears
        XCTAssertTrue(app.staticTexts["Set Reminder"].exists)
        
        // Enable and save
        app.switches["Enable Reminder"].tap()
        app.buttons["Save"].tap()
        
        // Verify bell icon filled
        XCTAssertTrue(taskRow.images["bell.fill"].exists)
    }
}
```

### 5.3 Device Smoke Tests

#### Test Checklist:
- [ ] iOS 17.0+ device: Basic timer without AlarmKit
- [ ] iOS 26.0+ device: Timer with AlarmKit enabled
- [ ] iPad: Split view layout works
- [ ] Start Pomodoro → verify Live Activity on Lock Screen
- [ ] Start Timer → background → verify alarm fires loudly
- [ ] Pause timer → verify alarm cancels
- [ ] Resume timer → verify alarm reschedules
- [ ] Stop timer → verify Live Activity ends
- [ ] Set task reminder → verify notification fires
- [ ] Dynamic Island shows timer in compact mode
- [ ] StandBy mode displays timer correctly

---

## Platform-Specific Guards

### Compilation Guards
All AlarmKit code must be wrapped:

```swift
#if os(iOS)
#if canImport(AlarmKit)
@available(iOS 26.0, *)
// AlarmKit code here
#endif
#endif
```

### Runtime Guards
```swift
var alarmKitAvailable: Bool {
    #if os(iOS)
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
        return true
    }
    #endif
    #endif
    return false
}
```

### Settings Visibility
```swift
// Only show AlarmKit settings on iOS/iPadOS
#if os(iOS)
if scheduler.alarmKitAvailable {
    Section("Alarms") {
        // AlarmKit settings
    }
}
#endif
```

---

## Acceptance Criteria Checklist

### Feature Parity
- [ ] iOS Timer UI matches macOS feature set (documented parity 100%)
- [ ] Activity management: list, search, filter, pinned, notes
- [ ] Session history with filtering
- [ ] iPad split-view layout optimized
- [ ] All controls functional: start/pause/resume/stop/skip

### AlarmKit
- [ ] AlarmKit schedules on timer start (iOS/iPadOS when authorized)
- [ ] Authorization request flow works
- [ ] Alarms cancel on pause/stop
- [ ] Alarms reschedule on resume with correct remaining time
- [ ] Fallback to notifications when unavailable
- [ ] Settings toggle present and functional
- [ ] No AlarmKit code on macOS/watchOS targets

### Live Activity
- [ ] Live Activity starts when session starts
- [ ] Updates every second during running state
- [ ] Paused state reflects correctly
- [ ] Ends immediately when session stops
- [ ] Dynamic Island shows timer info
- [ ] Lock Screen widget displays correctly
- [ ] StandBy mode works
- [ ] No orphaned activities

### Task Alarms
- [ ] Bell icon appears on task rows
- [ ] Alarm picker opens and saves correctly
- [ ] Notifications schedule for task reminders
- [ ] Reminders cancel when disabled
- [ ] Visual indicator when alarm active
- [ ] Works on both iOS and macOS

### Testing
- [ ] Unit tests pass for timer state machine
- [ ] UI tests verify Live Activity flow
- [ ] Device smoke tests complete successfully
- [ ] No crashes or memory leaks
- [ ] Battery impact acceptable

---

## Rollout Strategy

### Phase 1 (Week 1): Foundation
- Complete feature parity audit
- Implement missing UI components
- Add task alarm infrastructure

### Phase 2 (Week 2): AlarmKit
- Enable AlarmKit integration
- Wire to timer lifecycle
- Add settings and authorization

### Phase 3 (Week 3): Live Activity
- Polish Live Activity UI
- Optimize update frequency
- Test Dynamic Island

### Phase 4 (Week 4): Testing & Polish
- Complete all unit/UI tests
- Device testing on iOS 17+ and iOS 26+
- Bug fixes and optimization

### Phase 5 (Week 5): Documentation & Release
- Update user documentation
- Create release notes
- Submit to TestFlight

---

## Dependencies & Constraints

### System Requirements
- iOS/iPadOS 16.1+ for Live Activity
- iOS/iPadOS 17.0+ for timer features
- iOS/iPadOS 26.0+ for AlarmKit (beta)

### Framework Dependencies
- ActivityKit (iOS 16.1+)
- AlarmKit (iOS 26.0+, currently beta)
- UserNotifications (fallback)

### Known Limitations
- AlarmKit API may change (beta)
- Live Activity limited to one active at a time per app
- Dynamic Island requires iPhone 14 Pro or later
- StandBy requires iOS 17+

---

## Success Metrics

### Functional Metrics
- 100% feature parity between iOS and macOS Timer
- 95%+ AlarmKit authorization rate (when available)
- Zero orphaned Live Activities
- Zero timer completion misses (alarm + notification)

### User Experience Metrics
- Live Activity update latency < 1 second
- Alarm fires within 1 second of timer end
- Battery drain < 5% per hour with active timer
- UI response time < 100ms

### Code Quality Metrics
- Test coverage > 70% for new code
- Zero warnings in Xcode
- Zero SwiftLint violations
- All platform guards correct

---

## Future Enhancements (Post-MVP)

1. **Widget Support**: Home Screen widget for quick timer start
2. **Siri Shortcuts**: "Start a Pomodoro session"
3. **Apple Watch**: WatchOS timer sync
4. **Custom Alarm Sounds**: User-selectable sounds for AlarmKit
5. **Focus Mode Integration**: Auto-enable Focus during work sessions
6. **Analytics**: Track productivity patterns
7. **Team Timers**: Shared pomodoro sessions

---

## Contact & Resources

- **Lead**: [Your Name]
- **Epic Tracking**: GitHub Issue #[NUMBER]
- **Design Specs**: Figma link
- **AlarmKit Docs**: Apple Developer (when available)
- **ActivityKit Docs**: https://developer.apple.com/documentation/activitykit

---

## Status: READY FOR IMPLEMENTATION
**Last Updated**: 2026-01-03
**Next Review**: After Phase 1 completion
