# Task Status Sync Fix

## Issue
Task completion status (completed/not started/in progress) was not syncing properly between devices via iCloud.

## ✅ Platform Coverage
This fix applies to **ALL platforms** - iOS, iPadOS, and macOS - because:
- `AssignmentsStore` is in `SharedCore/State/` (shared by all platforms)
- All platforms use `AssignmentsStore.shared` singleton
- No platform-specific overrides exist
- Conflict resolution logic is centralized in SharedCore

## Root Cause
The conflict resolution logic in `AssignmentsStore.swift` had a one-way bias:
- ✅ Completing a task on Device A → synced to Device B
- ❌ Un-completing a task → did NOT sync
- ❌ Status changes in general were not bidirectional

The buggy code (lines 954-959):
```swift
if let localTask = mergedDict[cloudTask.id] {
    // If both exist, take the "most complete" one
    if cloudTask.isCompleted && !localTask.isCompleted {
        mergedDict[cloudTask.id] = cloudTask
    }
    // Keep local if both completed or both not completed
}
```

This logic only updated when `cloudTask.isCompleted && !localTask.isCompleted`, meaning:
- Cloud completed + Local not completed = Use cloud ✅
- Cloud not completed + Local completed = Use local ❌ (doesn't sync un-complete action)
- Both same status = Use local ❌ (misses other field changes)

## Solution
Changed conflict resolution to always prefer cloud version when there's ANY difference, treating iCloud as source of truth during merges.

### File Modified
`SharedCore/State/AssignmentsStore.swift` (lines 952-968)

### Changes
```swift
// Add/update with cloud tasks (keeping unique IDs from both)
for cloudTask in cloudTasks {
    if let localTask = mergedDict[cloudTask.id] {
        // BUGFIX: Always prefer cloud version when there's any difference
        // This ensures completion status changes sync properly in both directions
        // Without timestamps, we treat iCloud as source of truth during merge
        if cloudTask.isCompleted != localTask.isCompleted ||
           cloudTask.title != localTask.title ||
           cloudTask.due != localTask.due {
            mergedDict[cloudTask.id] = cloudTask
        }
        // Keep local only if completely identical
    } else {
        mergedDict[cloudTask.id] = cloudTask
    }
}
```

## How It Works Now

1. **Device A changes completion status** → Saves to iCloud
2. **Device B receives iCloud update** → Detects difference in `isCompleted`
3. **Conflict resolution** → Prefers cloud version (Device A's change)
4. **Result** → Status syncs bidirectionally ✅

## Why This Works

Without timestamp tracking (`updatedAt`), we can't determine which change is "newer". The safest approach is to treat iCloud as the authoritative source during conflict resolution, since:

1. iCloud sync happens after local save
2. Multiple devices pulling from iCloud get consistent state
3. "Last writer wins" semantics via iCloud's natural ordering

## Testing
To verify the fix works:

1. **Setup**: Two devices with same iCloud account and sync enabled
2. **Test 1 - Complete task**:
   - Device A: Mark task as completed
   - Device B: Should show as completed after sync
3. **Test 2 - Uncomplete task**:
   - Device A: Unmark completed task
   - Device B: Should show as not completed after sync  
4. **Test 3 - Toggle multiple times**:
   - Rapidly toggle status on Device A
   - Device B should eventually match final state

## Future Improvement
For proper "last write wins" semantics, we should:

1. Add `updatedAt: Date` field to `AppTask` struct
2. Update timestamp on every modification
3. Use timestamp comparison in conflict resolution:
   ```swift
   if cloudTask.updatedAt > localTask.updatedAt {
       mergedDict[cloudTask.id] = cloudTask
   }
   ```

This would provide true temporal ordering instead of treating iCloud as always authoritative.

## Related Code
- **AppTask model**: `SharedCore/Features/Scheduler/AIScheduler.swift` (line 50)
- **Core Data entity**: `Assignment.isCompleted` attribute (marked syncable)
- **Sync monitoring**: `SharedCore/Persistence/SyncMonitor.swift`

## Date
2026-01-06
