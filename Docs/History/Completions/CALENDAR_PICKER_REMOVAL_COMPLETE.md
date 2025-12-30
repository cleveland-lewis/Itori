# Calendar Picker Removal - COMPLETE ✅

## Summary
Successfully removed the calendar picker from the "Add Event" popup in the Dashboard. All events are now added to the calendar selected in Settings.

## Changes Made

### SharedCore/Services/FeatureServices/UIStubs.swift
- ✅ Removed calendar picker UI section (40+ lines)
- ✅ Removed `@State private var selectedCalendarID` variable
- ✅ Removed calendar initialization logic in `onAppear`
- ✅ Updated `createEvent()` to use `getSelectedSchoolCalendar()` instead of local picker state

### Build Fixes
- ✅ Removed duplicate `macOS/Views/GeneralSettingsView.swift`
- ✅ Renamed iOS version to `IOSGeneralSettingsView.swift` to avoid conflicts
- ✅ Created `SharedCore/Models/BYOProviderConfig.swift` stub for missing type
- ✅ Cleaned corrupted DerivedData

## New Behavior

### Before:
1. User clicks "Add Event" → popup shows calendar picker
2. User can select any calendar for each event
3. Inconsistent calendar usage

### After:
1. User clicks "Add Event" → **NO calendar picker shown**
2. Event automatically goes to calendar selected in Settings
3. Consistent calendar usage across all events
4. Control centralized in Settings → Calendar

## Technical Details

### Event Creation Flow:
```swift
// Old: Used local picker state
let targetCalendar = availableCalendars.first(where: { 
    $0.calendarIdentifier == selectedCalendarID 
})

// New: Uses settings
let targetCalendar = getSelectedSchoolCalendar()
```

### Calendar Selection Logic:
1. If school calendar is set in Settings → use it
2. If school calendar not set → fall back to system default calendar
3. Validates calendar exists and is writable
4. Logs diagnostic messages for debugging

## Build Status
✅ **BUILD SUCCEEDED** - macOS target
✅ App launches successfully
✅ No compilation errors
✅ No EventKit permission errors

## Testing Completed
- ✅ UIStubs.swift compiles
- ✅ Full project builds without errors
- ✅ App launches and runs
- ✅ No duplicate file conflicts
- ✅ No missing type errors

## Next Steps for User
1. Launch app
2. Go to Settings → Calendar
3. Select your school calendar
4. Open Dashboard → click "Add Event" (+)
5. Verify NO calendar picker appears
6. Create event and verify it goes to selected calendar

## Files Modified
- `SharedCore/Services/FeatureServices/UIStubs.swift` - Calendar picker removed
- `macOS/Views/GeneralSettingsView.swift` - Deleted (duplicate)
- `iOS/Scenes/Settings/Categories/IOSGeneralSettingsView.swift` - Renamed
- `SharedCore/Models/BYOProviderConfig.swift` - Created
- `SharedCore/Services/DeviceCalendarManager.swift` - EventKit auth guards (previous fix)
- `SharedCore/Services/FeatureServices/CalendarManager.swift` - EventKit auth guards (previous fix)
