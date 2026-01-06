# Calendar View Selector Removal (macOS)

## Change
Removed the view mode selector from the macOS Calendar page. The calendar now only displays the month view.

## File Modified
`Platforms/macOS/Views/CalendarPageView.swift` (lines 275-282)

## What Was Removed
```swift
Picker("View", selection: $currentViewMode) {
    ForEach(CalendarViewMode.allCases) { mode in
        Text(mode.title).tag(mode)
    }
}
.pickerStyle(.segmented)
.frame(width: 280)
.tint(.accentColor)
```

## Why This Works
- `currentViewMode` state variable is initialized to `.month` (line 88)
- With no UI to change it, the view remains locked to month view
- All switch statements still work correctly (they just always hit the `.month` case)
- Navigation controls (prev/next month) still function properly

## UI Changes
**Before:**
```
[Title]  [Spacer]  [Day|Week|Month|Year Picker]  [Navigation]
```

**After:**
```
[Title]  [Spacer]  [Navigation]
```

## Technical Details
The following code paths continue to work:
- `headerTitle` - Returns month title format
- `gridContent` - Renders `MonthCalendarView`
- `shift(by:)` - Navigates by month intervals
- `visibleInterval()` - Returns monthly date interval
- Event loading and caching - Optimized for monthly ranges

## Alternative Implementation Considered
Could have removed the `CalendarViewMode` enum entirely, but keeping it:
- Maintains code compatibility
- Allows easy re-enabling of other views if needed
- Minimal impact on existing logic

## Testing
Verify on macOS:
1. Open Calendar page
2. Confirm view selector is no longer visible
3. Verify month view is displayed
4. Test prev/next navigation buttons work
5. Verify events display correctly in month grid

## Date
2026-01-06
