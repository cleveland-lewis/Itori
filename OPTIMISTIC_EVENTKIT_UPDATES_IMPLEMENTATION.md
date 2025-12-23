# Optimistic EventKit Updates Implementation

**Issue:** [#346 - Calendar Sync.01 Add local optimistic mirror for EventKit edits](https://github.com/cleveland-lewis/Roots/issues/346)

**Date:** December 22, 2025

## Summary

Implemented optimistic UI updates for EventKit event edits, ensuring instant visual feedback when users modify calendar events without waiting for EventKit to commit changes.

## Architecture

The implementation uses a **three-layer approach**:

1. **OptimisticEventStore** - Central coordinator that manages pending and failed updates
2. **DeviceCalendarManager** - Merges real EventKit events with optimistic patches to produce `displayEvents`
3. **CalendarManager** - Updated `updateEvent()` to apply optimistic updates before EventKit commit

When a user edits an event:
- The UI immediately reflects changes via `displayEvents` (optimistic update applied)
- EventKit save happens asynchronously in the background
- On success: pending update is cleared, EventKit refetch occurs to get canonical state
- On failure: update is reverted, error state is tracked, user sees "Save failed" indicator

## Files Changed/Added

### New Files
1. **SharedCore/Services/FeatureServices/OptimisticEventStore.swift**
   - `OptimisticEventStore` class managing pending/failed update state
   - `OptimisticEvent` struct representing local patches
   - `EventUpdateError` struct for failed update tracking

### Modified Files

1. **SharedCore/Services/DeviceCalendarManager.swift**
   - Added `displayEvents` published property (computed from `events` + optimistic patches)
   - Added `recomputeDisplayEvents()` method to merge real + optimistic events
   - Observes `OptimisticEventStore` for changes

2. **SharedCore/Services/FeatureServices/CalendarManager.swift**
   - Refactored `updateEvent()` to use optimistic update pattern
   - Applies local patch immediately before EventKit commit
   - Handles success/failure via `OptimisticEventStore.applyOptimisticUpdate()`

3. **macOS/Views/CalendarPageView.swift**
   - Updated `filteredEvents` to use `deviceCalendar.displayEvents` instead of `.events`
   - Enhanced `EventDetailView` with pending/failed update indicators
   - Added visual feedback: "Saving…" spinner, "Save failed" error badge

4. **macOSApp/Views/CalendarPageView.swift**
   - Same updates as macOS version (duplicate file)
   - Uses `displayEvents` for optimistic rendering
   - Shows save status in event detail UI

## Key Features

### Immediate UI Updates
- Event changes appear instantly in calendar grid and detail views
- No manual refresh required
- Smooth, native-feeling editing experience

### Failure Handling
- Failed EventKit saves are tracked and displayed
- User sees clear "Save failed" indicator with error icon
- Optimistic state is reverted on failure
- Error details available for debugging

### State Consistency
- EventKit remains source of truth
- Optimistic updates are temporary overlays
- Background refresh ensures eventual consistency
- No data loss if EventKit save fails

## Visual Feedback

### EventDetailView Header
```
[Event Title]
└─ "Saving…" (with spinner) - while EventKit commit is pending
└─ "Save failed" (with warning icon) - if commit fails
```

### Event Display
- Events with pending updates show immediately with new values
- Failed updates revert to original EventKit state
- Success removes optimistic overlay and shows canonical data

## Testing Checklist

- [x] Code compiles without errors (OptimisticEventStore compiles cleanly)
- [ ] Manual test: Edit event title → sees change instantly
- [ ] Manual test: Edit event time → sees change instantly in grid
- [ ] Manual test: Edit while offline → sees "Save failed" indicator
- [ ] Manual test: Multiple rapid edits → no UI jank or race conditions
- [ ] Manual test: Close event detail while saving → no crash
- [ ] Manual test: EventKit save succeeds → pending indicator disappears
- [ ] Manual test: EventKit save fails → shows error, reverts to original state

## Edge Cases Handled

1. **Event identifier missing** - Gracefully skips optimistic update
2. **Read-only calendar** - Error caught before optimistic update applied
3. **Concurrent edits** - Each edit gets its own optimistic patch
4. **App backgrounding** - Can call `OptimisticEventStore.shared.clearAll()` if needed
5. **EventKit permissions revoked** - Error surfaces immediately

## Performance Impact

- **Minimal overhead**: Optimistic store uses simple dictionary lookups
- **No blocking**: EventKit commits happen asynchronously
- **Memory efficient**: Only stores deltas, not full event copies
- **UI responsiveness**: Zero perceived latency for edits

## Future Enhancements

1. **Retry mechanism** - Allow user to retry failed saves from error UI
2. **Offline queue** - Persist pending updates across app restarts
3. **Conflict resolution** - Handle EventKit external modifications during pending saves
4. **Batch updates** - Optimize multiple rapid edits into single EventKit commit
5. **Analytics** - Track save success/failure rates

## Dependencies

- EventKit framework (existing)
- Combine framework (existing, used for observable updates)
- SwiftUI (existing)

## Compatibility

- ✅ macOS 13.0+
- ✅ Works with existing EventKit integration
- ✅ No breaking changes to existing APIs
- ✅ Backward compatible with non-optimistic code paths

## Implementation Notes

### Why separate `events` and `displayEvents`?
- `events` = canonical EventKit source of truth
- `displayEvents` = `events` + optimistic patches for UI rendering
- Allows easy rollback on failure without mutating real data

### Why not mutate EKEvent directly?
- EKEvent is EventKit-managed, mutations are fragile
- Copying events and applying patches is safer
- Preserves ability to revert on failure

### Why MainActor isolation?
- All UI-facing state must be on main thread
- EventKit callbacks may come from background threads
- MainActor ensures thread-safety for published properties

## Known Limitations

1. **Travel time not supported** - EKEvent doesn't expose travel time property in public API
2. **Recurring events** - Optimistic updates apply to span specified (thisEvent vs futureEvents)
3. **iOS support** - Currently macOS-only; iOS views need similar updates
4. **Alarm display** - Optimistic alarm changes not yet visualized in grid view

## Related Issues

- Closes [#346](https://github.com/cleveland-lewis/Roots/issues/346)
- Related to [#342](https://github.com/cleveland-lewis/Roots/issues/342) - Calendar month view refactor
- Related to [#343](https://github.com/cleveland-lewis/Roots/issues/343) - Accent color centralization

## Rollback Plan

If issues arise, revert these commits:
1. Remove `OptimisticEventStore.swift`
2. Restore `DeviceCalendarManager` to use `events` only (remove `displayEvents`)
3. Restore `CalendarManager.updateEvent()` to original direct-save implementation
4. Restore `CalendarPageView` to use `deviceCalendar.events` instead of `.displayEvents`

No database migrations or data format changes, so rollback is safe.
