# EventKit Permission Error Fix

## Issue
The app was generating error 1013 ("Access denied") when attempting to access EventKit calendar data after permissions were revoked or denied:

```
Error getting changed object IDs since timestamp
Error Domain=EKCADErrorDomain Code=1013 "Access denied"
Error (1013) in reply block for CADDatabaseFetchCalendarItemsWithPredicate attempt 1/3
```

## Root Cause
The `DeviceCalendarManager` and `CalendarManager` were attempting to fetch calendar data and access the event store **without checking authorization status first**. This caused the app to repeatedly attempt API calls even when the user had denied or revoked calendar access in System Settings.

## Solution
Added authorization checks before attempting any EventKit operations:

### DeviceCalendarManager.swift
1. **`refreshEventsForVisibleRange(reason:)`** - Now checks `isAuthorized` before fetching events
2. **`refreshEvents(from:to:reason:)`** - Now checks `isAuthorized` before fetching events  
3. **`refreshEventsForVisibleRange()`** - Now checks `isAuthorized` before fetching events
4. **`getAvailableCalendars()`** - Now returns empty array if not authorized

### CalendarManager.swift
1. **`refreshSources()`** - Now checks authorization before accessing calendars and reminder lists

## Changes Made

### DeviceCalendarManager.swift
- Added `guard isAuthorized` checks at the start of all event fetch methods
- Returns early with empty results when unauthorized
- Sets appropriate status messages for debugging

### CalendarManager.swift
- Added authorization check in `refreshSources()` to prevent accessing store when denied
- Returns empty arrays for calendars and reminder lists when unauthorized

## Result
- **No more error 1013 spam** in logs when calendar access is denied
- App gracefully handles denied/revoked permissions
- UI properly reflects unavailable calendar state
- Build succeeds without errors

## Testing Recommendations
1. Revoke calendar access in System Settings → Privacy & Security → Calendars
2. Launch the app - should not log error 1013
3. Grant calendar access - app should fetch events normally
4. Revoke access again while app is running - should gracefully stop fetching

## Build Status
✅ **BUILD SUCCEEDED** - macOS target builds cleanly with fixes applied
