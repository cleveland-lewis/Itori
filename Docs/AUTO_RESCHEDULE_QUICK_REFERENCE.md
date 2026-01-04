# Auto-Reschedule Quick Reference

## For Developers

### Key Files

**Core Engine**:
- `SharedCore/Services/FeatureServices/MissedEventDetectionService.swift` - Detection loop
- `SharedCore/Services/FeatureServices/AutoRescheduleEngine.swift` - Rescheduling logic

**UI**:
- `Platforms/iOS/Scenes/Settings/Categories/IOSPlannerSettingsView.swift` - iOS settings
- `Platforms/macOS/Views/GeneralSettingsView.swift` - macOS settings
- `Platforms/iOS/Scenes/Settings/AutoRescheduleHistoryView.swift` - History view
- `Platforms/macOS/Scenes/PlannerPageView.swift` - Visual indicators

**Settings**:
- `SharedCore/State/AppSettingsModel.swift` - Configuration storage

---

## API

### Enable/Disable
```swift
// Get current state
let enabled = AppSettingsModel.shared.enableAutoReschedule

// Toggle
AppSettingsModel.shared.enableAutoReschedule = false
AppSettingsModel.shared.save()

// Immediately stop monitoring
MissedEventDetectionService.shared.stopMonitoring()
```

### Manual Trigger (Testing)
```swift
// Force a check right now
MissedEventDetectionService.shared.triggerCheck()

// Check if monitoring is active
let active = MissedEventDetectionService.shared.isMonitoring
```

### Access History
```swift
// Get all operations
let history = AutoRescheduleEngine.shared.rescheduleHistory

// Filter by strategy
let sameDayOps = history.filter { $0.strategy == .sameDaySlot }

// Get recent operations
let recent = history.filter { $0.timestamp > Date().addingTimeInterval(-3600) }
```

### Custom Settings
```swift
let settings = AppSettingsModel.shared

// Check interval (1-60 minutes)
settings.autoRescheduleCheckInterval = 10

// Allow pushing
settings.autoReschedulePushLowerPriority = true

// Max push count (0-5)
settings.autoRescheduleMaxPushCount = 3

// Save changes
settings.save()

// Restart monitoring with new settings
if settings.enableAutoReschedule {
    MissedEventDetectionService.shared.stopMonitoring()
    MissedEventDetectionService.shared.startMonitoring()
}
```

---

## Safety Rules

### Hard Invariants
1. **Never reschedule if**:
   - `session.isUserEdited == true`
   - `session.isLocked == true`
   - `session.type == .breakTime`
   - `session.assignmentId == nil`

2. **Always check**:
   - `settings.enableAutoReschedule` before ANY work
   - `session.aiProvenance` to avoid duplicate reschedules

3. **Use atomic updates**:
   ```swift
   plannerStore.updateBulk(updatedSessions) // Not individual updates
   ```

### Idempotency
```swift
// Check if recently rescheduled
if let provenance = session.aiProvenance, 
   provenance.contains("auto-reschedule"),
   let computed = session.aiComputedAt {
    let minutesSince = Date().timeIntervalSince(computed) / 60
    if minutesSince < Double(interval * 2) {
        return // Skip this session
    }
}
```

---

## Testing

### Unit Tests
```bash
# Run auto-reschedule tests only
xcodebuild test -scheme Itori \
  -destination 'platform=macOS' \
  -only-testing:ItoriTests/AutoRescheduleTests

# All tests
xcodebuild test -scheme Itori -destination 'platform=macOS'
```

### Manual Testing
```swift
// 1. Create a missed session
let past = Date().addingTimeInterval(-3600) // 1 hour ago
let session = StoredScheduledSession(
    id: UUID(),
    assignmentId: UUID(),
    sessionIndex: 1,
    sessionCount: 1,
    title: "Test Task",
    dueDate: Date().addingTimeInterval(86400),
    estimatedMinutes: 60,
    isLockedToDueDate: false,
    category: .homework,
    start: past.addingTimeInterval(-3600),
    end: past,
    type: .task,
    isLocked: false,
    isUserEdited: false
)

// 2. Add to planner
PlannerStore.shared.updateBulk([session])

// 3. Trigger check
MissedEventDetectionService.shared.triggerCheck()

// 4. Verify rescheduled
let updated = PlannerStore.shared.scheduled.first { $0.id == session.id }
print("Original: \(session.start)")
print("New: \(updated?.start ?? Date())")
```

---

## Debugging

### Enable Logging
```swift
// Logs use LOG_UI with context
// Filter in Console.app:
// - "MissedEventDetection" for detection
// - "AutoReschedule" for rescheduling

// Example log messages:
// LOG_UI(.info, "MissedEventDetection", "Detected 3 missed sessions")
// LOG_UI(.info, "AutoReschedule", "Strategy: Same day slot for Math Study")
```

### Common Issues

**Timer not firing**:
```swift
// Check if enabled
print(AppSettingsModel.shared.enableAutoReschedule)

// Check if monitoring
print(MissedEventDetectionService.shared.isMonitoring)

// Restart manually
MissedEventDetectionService.shared.startMonitoring()
```

**Sessions not rescheduled**:
```swift
// Check filters
let session = plannerStore.scheduled.first!
print("User edited: \(session.isUserEdited)")
print("Locked: \(session.isLocked)")
print("Type: \(session.type)")
print("Assignment: \(session.assignmentId)")
print("Provenance: \(session.aiProvenance ?? "none")")
```

**Duplicate operations**:
```swift
// Check provenance timestamps
for session in plannerStore.scheduled {
    if let prov = session.aiProvenance, prov.contains("auto-reschedule") {
        print("\(session.title): \(session.aiComputedAt ?? Date())")
    }
}
```

---

## Performance

### Monitoring Overhead
```swift
// Measure check time
let start = Date()
await MissedEventDetectionService.shared.checkForMissedSessions()
let elapsed = Date().timeIntervalSince(start)
print("Check took: \(elapsed * 1000)ms") // Should be <50ms
```

### Optimize for Battery
```swift
// Increase interval
settings.autoRescheduleCheckInterval = 15 // Less frequent

// Disable pushing (simpler logic)
settings.autoReschedulePushLowerPriority = false
```

---

## Integration Points

### Called from:
1. **App Launch** (`ItoriIOSApp.swift`, `ItoriApp.swift`):
   ```swift
   MissedEventDetectionService.shared.startMonitoring()
   ```

2. **Settings Toggle** (`IOSPlannerSettingsView.swift`):
   ```swift
   if newValue {
       MissedEventDetectionService.shared.startMonitoring()
   } else {
       MissedEventDetectionService.shared.stopMonitoring()
   }
   ```

### Calls to:
- `PlannerStore.shared.updateBulk()` - Apply reschedules
- `PlannerStore.shared.addToOverflow()` - Handle unschedulable
- `NotificationManager.shared.scheduleLocalNotification()` - Notify user

---

## Maintenance

### Adding New Strategy
1. Add case to `RescheduleStrategy` enum
2. Implement strategy in `rescheduleSession()`
3. Update `notifyUserOfReschedule()` to handle new case
4. Add display name for history view
5. Add icon/color for visual indicator

### Modifying Priority
```swift
// In AutoRescheduleEngine.calculatePriority()
let categoryPriority: Double = {
    switch category {
    case .exam: return 1.0      // ← Adjust these
    case .quiz: return 0.9
    // ...
    }
}()
```

### Changing Check Interval
```swift
// Min/max bounds in settings
autoRescheduleCheckInterval: Int // 1...60

// Applied in MissedEventDetectionService
private var checkInterval: TimeInterval {
    TimeInterval(settings.autoRescheduleCheckInterval * 60)
}
```

---

## Troubleshooting

| Issue | Check | Fix |
|-------|-------|-----|
| Timer not starting | `enableAutoReschedule` | Toggle in settings |
| Sessions not detected | End time, type, locks | Review filters |
| Duplicate reschedules | Provenance timestamps | Check idempotency logic |
| Wrong priority | Category, due date | Review priority calculation |
| Notifications not showing | `notificationsEnabled` | Enable in settings |
| History not persisting | File permissions | Check app support dir |

---

## Code Patterns

### Always Use @MainActor
```swift
// Detection service
@MainActor
final class MissedEventDetectionService: ObservableObject {
    // ...
}

// Engine
@MainActor
final class AutoRescheduleEngine: ObservableObject {
    // ...
}
```

### Atomic Bulk Updates
```swift
// ✅ Good
var updatedSessions = plannerStore.scheduled
// ... modify sessions ...
plannerStore.updateBulk(updatedSessions)

// ❌ Bad (race conditions)
for session in sessions {
    plannerStore.updateScheduledSession(session)
}
```

### Safety Checks
```swift
// Always check toggle first
guard settings.enableAutoReschedule else { return }

// Always validate session
guard !session.isUserEdited else { return }
guard !session.isLocked else { return }
guard session.type != .breakTime else { return }
```

---

## Quick Commands

```bash
# Build
xcodebuild -scheme Itori -destination 'platform=macOS' build

# Test
xcodebuild test -scheme Itori -destination 'platform=macOS'

# Find usages
grep -r "MissedEventDetectionService" --include="*.swift"

# Find logs
log show --predicate 'subsystem contains "MissedEventDetection"' --last 1h

# Clear history (manual)
rm ~/Library/Application\ Support/ItoriPlanner/reschedule-history.json
```

---

**Version**: 1.0.0  
**Last Updated**: December 30, 2024
