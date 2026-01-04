# Phase 4 Task Alarms - Quick Reference

## 🎯 What Was Built

Task alarm/reminder system for iOS/iPadOS that allows users to set alarms for individual tasks.

## 📁 Key Files

### Data Model
- `SharedCore/Features/Scheduler/AIScheduler.swift`
  - Added: `alarmDate`, `alarmEnabled`, `alarmSound`

### Alarm Scheduler
- `Platforms/iOS/Services/TaskAlarmScheduling.swift` - Protocol
- `Platforms/iOS/Services/TaskAlarmScheduler.swift` - Implementations
  - `IOSTaskAlarmScheduler` (AlarmKit for iOS 26+)
  - `NotificationTaskAlarmScheduler` (UNNotifications fallback)

### UI Components
- `Platforms/iOS/Views/TaskCheckboxRow.swift` - Row + picker
- `Platforms/iOS/Views/IOSTimerPageView.swift` - Tasks section

## 🔧 How to Use

### As a Developer

**1. Schedule an alarm for a task:**
```swift
let scheduler = NotificationTaskAlarmScheduler()
try await scheduler.scheduleAlarm(
    for: task,
    at: alarmDate,
    sound: "chime"
)
```

**2. Cancel a task alarm:**
```swift
try await scheduler.cancelAlarm(for: taskID)
```

**3. Update a task alarm:**
```swift
try await scheduler.updateAlarm(
    for: updatedTask,
    at: newAlarmDate,
    sound: nil
)
```

**4. Access alarm scheduler:**
```swift
@StateObject private var alarmScheduler = NotificationTaskAlarmScheduler()

// Check if AlarmKit is available
if alarmScheduler.alarmKitAvailable {
    // Use AlarmKit features
}

// Check authorization
let authorized = await alarmScheduler.isAuthorized
if !authorized {
    let granted = await alarmScheduler.requestAuthorizationIfNeeded()
}
```

### As a User

**1. View tasks in Timer page:**
- Open Timer tab
- Scroll to "Tasks" section
- See "Due Today" and "Due This Week" sections

**2. Set an alarm for a task:**
- Tap the bell icon on any task
- Toggle "Set Alarm" ON
- Choose alarm time:
  - Use quick actions (1 Hour Before, Morning of, etc.)
  - Or pick custom date/time
- Optionally select a sound
- Tap "Save"

**3. Disable an alarm:**
- Tap the filled bell icon
- Toggle "Set Alarm" OFF
- Tap "Save"

**4. Complete a task:**
- Tap the circle checkbox
- Task becomes checked with strikethrough

## 🎨 UI Elements

### Task Sections
- **Due Today**: Tasks due today with badge count
- **Due This Week**: Tasks due this week with badge count
- Empty states when no tasks

### TaskCheckboxRow
```
┌─────────────────────────────────────┐
│ ○ Task Title                    🔔  │
│   📅 Today 2:00 PM  ⏰ 1:00 PM      │
└─────────────────────────────────────┘
  ↑        ↑            ↑         ↑
  Checkbox Due date   Alarm    Alarm
           & time     time     button
```

### Alarm Picker
```
Task Reminder
┌─────────────────────────────────────┐
│ Set Alarm                        ⚫ │
│                                     │
│ Alarm Time                          │
│ [ Jan 3, 2026  1:00 PM          ] │
│                                     │
│ [1 Hour Before] [Morning of]       │
│ [Day Before]    [Custom]           │
│                                     │
│ Sound              [Default ▼]     │
│                                     │
│ Due: Jan 3, 2026 2:00 PM           │
│ Status: Notifications               │
└─────────────────────────────────────┘
[Cancel]                         [Save]
```

## 🔔 Alarm Behavior

### Scheduling
- **Default time**: 1 hour before due time (or 9 AM if no time specified)
- **Sound**: System default or custom (chime/bell/alert)
- **Persistence**: Saved to task model and synced

### When Alarm Fires
- System notification appears
- Sound plays (respects Do Not Disturb)
- Tap notification → opens app (TODO: Phase 4.4)
- Actions available (TODO: Phase 4.4):
  - Mark Complete
  - Snooze

### AlarmKit vs Notifications
| Feature | AlarmKit (iOS 26+) | Notifications (iOS 17+) |
|---------|-------------------|------------------------|
| Loud alarm | ✅ Yes | ❌ No (respects DND) |
| Reliability | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Authorization | AlarmKit | Notification permissions |
| Availability | Placeholder ready | ✅ Production ready |

## 📊 Data Model

### AppTask Properties
```swift
struct AppTask {
    // ... existing properties ...
    
    // Phase 4.1: Alarm properties
    var alarmDate: Date?         // When to fire
    var alarmEnabled: Bool       // Is alarm active
    var alarmSound: String?      // Custom sound ID
}
```

### Codable & Backward Compatible
- All alarm properties are optional
- Default values provided
- Existing tasks work without modification
- No data migration required

## 🌍 Localization

All strings are localized in `Localizable.xcstrings`:
- `timer.tasks.*` - Section headers, empty states
- `timer.tasks.alarm.*` - Alarm picker UI
- `task.alarm.error.*` - Error messages

Add translations in Xcode String Catalog editor.

## 🧪 Testing

### Quick Smoke Test
1. Create task with due date today
2. Open Timer page → see task in "Due Today"
3. Tap alarm icon
4. Enable alarm, save
5. Verify bell icon is filled/orange
6. Background app
7. Wait for alarm time
8. Verify notification appears

### Unit Test Ideas (TODO)
- Task filtering logic
- Alarm date calculation
- Scheduler protocol conformance
- Error handling

## ⚠️ Known Limitations

### Current Phase (4.3)
- ✅ UI components complete
- ✅ Alarm scheduling works
- ⏳ Notification tap handling (Phase 4.4)
- ⏳ Snooze functionality (Phase 4.4)
- ⏳ Bulk operations (Phase 4.4)

### Platform
- iOS/iPadOS only (by design)
- iOS 17.0+ required
- AlarmKit placeholder (iOS 26.0+ when available)

### Future Enhancements
- Recurring task alarm patterns
- Smart alarm suggestions
- Integration with Focus modes
- Statistics/history

## 🔗 Related Documentation

- `PHASE_4_TASK_ALARMS_IMPLEMENTATION.md` - Full implementation details
- `TIMER_EPIC_QUICK_REFERENCE.md` - Timer/Pomodoro features
- `HYBRID_AI_QUICK_REFERENCE.md` - AI scheduling integration

## 🐛 Troubleshooting

### Alarm doesn't fire
1. Check notification permissions: Settings → Itori → Notifications
2. Verify alarm enabled on task
3. Check alarm date is in future
4. Ensure app isn't force-closed (iOS limitation)

### Tasks don't appear in section
- Verify task has due date set
- Check due date is today or this week
- Ensure task is not completed
- Check assignmentsStore has loaded

### Alarm picker doesn't save
- Check for error alert
- Verify notification authorization
- Check console logs for error details

### Build errors
- Ensure iOS target is selected
- Clean build folder (Cmd+Shift+K)
- All files properly added to target

## 📞 Support

For issues or questions:
1. Check console logs for error messages
2. Review implementation docs
3. Test with sample tasks
4. Verify iOS version compatibility

---

**Status**: Phase 4.3 Complete ✅ | Phase 4.4 Next 🎯  
**Last Updated**: January 3, 2026  
**iOS Version**: 17.0+  
