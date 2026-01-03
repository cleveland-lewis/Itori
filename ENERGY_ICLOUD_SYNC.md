# Energy Level iCloud Sync Implementation

## Overview
Energy level selection is now automatically synced across all devices using iCloud Key-Value Store.

## Implementation Details

### 1. **NSUbiquitousKeyValueStore Integration**
- Energy settings are stored in both UserDefaults (local) and NSUbiquitousKeyValueStore (iCloud)
- Bidirectional sync: reads from iCloud on get, writes to iCloud on set

### 2. **Synced Properties**
```swift
- defaultEnergyLevel: String         // "High", "Medium", or "Low"
- energySelectionConfirmed: Bool     // Whether user has selected energy today
```

### 3. **Sync Keys**
```
roots.settings.defaultEnergyLevel
roots.settings.energySelectionConfirmed
```

### 4. **Sync Behavior**

#### On Write:
```swift
settings.defaultEnergyLevel = "High"
// ↓
// 1. Save to UserDefaults.standard (local cache)
// 2. Save to NSUbiquitousKeyValueStore.default (iCloud)
// 3. Call synchronize() to push to iCloud immediately
```

#### On Read:
```swift
let level = settings.defaultEnergyLevel
// ↓
// 1. Check if iCloud sync is enabled
// 2. Try to get value from iCloud
// 3. If found and different, update local cache
// 4. Return iCloud value (or fallback to local)
```

#### On iCloud Change (from another device):
```swift
// NotificationCenter observes NSUbiquitousKeyValueStore.didChangeExternallyNotification
// ↓
// 1. Receive notification with changed keys
// 2. Update local storage if value differs
// 3. Trigger objectWillChange.send() to refresh UI
// 4. Log sync event
```

### 5. **Enable/Disable Sync**
Sync respects the global iCloud sync setting:
```swift
if settings.enableICloudSync {
    // Use iCloud values
} else {
    // Use local values only
}
```

### 6. **User Experience**

**Scenario 1: User sets energy on iPhone**
1. Opens Dashboard → selects "Low" energy
2. Energy saved to iCloud automatically
3. Opens MacBook → energy is already "Low"
4. Schedule reflects low-energy filtering

**Scenario 2: User changes energy on Mac**
1. Sets energy to "High" on Mac
2. Returns to iPhone → receives iCloud notification
3. UI automatically updates to "High"
4. Planner recomputes with high-energy tasks

### 7. **Conflict Resolution**
- Last-write-wins strategy
- iCloud value takes precedence over local when both exist
- Local value used when iCloud unavailable or disabled

### 8. **Privacy & Control**
- Sync is opt-in via Settings → General → Enable iCloud Sync
- Energy data stored in user's private iCloud account
- No third-party servers involved
- Can disable sync to keep energy selection local-only

### 9. **Files Modified**
- `SharedCore/State/AppSettingsModel.swift`
  - Added iCloud read/write in computed properties
  - Added NotificationCenter observer for external changes
  - Added energy keys to Codable (encode/decode)
  - Added logging for sync events

### 10. **Testing Checklist**
- [ ] Set energy on Device A, verify syncs to Device B
- [ ] Change energy on Device B, verify syncs back to Device A  
- [ ] Disable iCloud sync, verify energy stays local
- [ ] Enable iCloud sync, verify existing energy pushes to cloud
- [ ] Verify schedule regenerates when energy syncs from iCloud
- [ ] Test with airplane mode (should use local cache)
- [ ] Test with multiple rapid changes (debouncing works)

## Technical Notes

### Why NSUbiquitousKeyValueStore?
- Perfect for small, frequently-changing values like energy level
- Automatic conflict resolution
- Works offline (queues changes)
- Maximum 1MB total storage (energy uses ~100 bytes)
- Syncs within seconds across devices

### Alternative Considered
CloudKit was considered but rejected because:
- Too heavy for simple key-value pairs
- Requires more complex conflict resolution
- Energy level doesn't need relational data structure
- NSUbiquitousKeyValueStore is simpler and faster

## Future Enhancements
- [ ] Sync energy history (past 7 days)
- [ ] Sync per-day energy overrides
- [ ] Energy patterns analytics across devices
- [ ] Suggest optimal energy based on time of day sync
