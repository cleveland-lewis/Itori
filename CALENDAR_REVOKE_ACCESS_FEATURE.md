# Calendar Revoke Access Feature

## Summary
Added a "Revoke Calendar Access" feature to the iOS/iPadOS Calendar Settings section, allowing users to clear all synced calendar data and reset calendar authorization.

## Implementation

### 1. DeviceCalendarManager Enhancement
**File:** `SharedCore/Services/DeviceCalendarManager.swift`

Added `revokeAccess()` method that:
- Clears all cached calendar events
- Resets authorization status
- Stops observing calendar store changes
- Removes the selected school calendar preference
- Prepares the app for fresh calendar authorization

```swift
func revokeAccess() {
    events = []
    lastRefreshAt = nil
    lastRefreshReason = nil
    isAuthorized = false
    
    if let observer = storeChangedObserver {
        NotificationCenter.default.removeObserver(observer)
        storeChangedObserver = nil
        isObservingStoreChanges = false
    }
    
    AppSettingsModel.shared.selectedSchoolCalendarID = nil
}
```

### 2. Calendar Settings UI
**File:** `iOS/Scenes/Settings/Categories/CalendarSettingsView.swift`

Added new section with:
- **Destructive button** to trigger revoke action
- **Confirmation dialog** with clear warning message
- **Footer text** explaining the action and iOS Settings requirement

The revoke button only appears when calendar access is already granted, displayed in a separate section below the scheduling options.

### 3. Localization
**File:** `en.lproj/Localizable.strings`

Added localization keys:
```
"settings.calendar.revoke_access" = "Revoke Calendar Access";
"settings.calendar.revoke_access.footer" = "Remove calendar access and clear all synced events. You'll need to manually revoke permission in iOS Settings.";
"settings.calendar.revoke_access.confirm.title" = "Revoke Calendar Access?";
"settings.calendar.revoke_access.confirm.message" = "This will clear all synced calendar data. You'll need to manually revoke permission in iOS Settings > Roots > Calendars.";
"settings.calendar.revoke_access.confirm.button" = "Revoke Access";
```

## User Flow

1. User navigates to **Settings → Calendar**
2. If calendar access is granted, scrolls to bottom section
3. Taps **"Revoke Calendar Access"** (red text)
4. Confirmation dialog appears with warning message
5. User confirms by tapping **"Revoke Access"** or cancels
6. If confirmed:
   - All calendar events are cleared from app
   - Selected calendar preference is removed
   - App stops syncing calendar changes
   - Authorization status resets to unauthorized
7. User sees the "Request Access" screen in Calendar Settings
8. To fully revoke, user must manually disable permission in iOS Settings app

## Technical Notes

- **Platform:** iOS/iPadOS only (uses iOS-specific calendar settings UI)
- **Shared Code:** DeviceCalendarManager is in SharedCore but revoke method is safe for macOS (macOS uses different settings UI)
- **Permission System:** iOS doesn't allow apps to programmatically revoke calendar permissions; users must do this manually in Settings > Roots > Calendars
- **Data Clearing:** The revoke action clears all in-memory and cached calendar data immediately
- **Re-authorization:** After revoke, user can tap "Request Access" again to grant permission

## Testing Checklist

- [x] iOS build succeeds
- [ ] Revoke button appears when calendar access is granted
- [ ] Revoke button does NOT appear when calendar access is denied/not determined
- [ ] Confirmation dialog shows correct warning message
- [ ] Tapping "Cancel" dismisses dialog without changes
- [ ] Tapping "Revoke Access" clears all calendar data
- [ ] After revoke, Calendar Settings shows "Request Access" UI
- [ ] Selected calendar preference is cleared
- [ ] App stops syncing calendar changes after revoke
- [ ] User can re-grant access and it works normally

## Build Status
✅ iOS build succeeded with warnings only (unrelated to this feature)

