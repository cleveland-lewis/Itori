# Issue #274 Completion: Deterministic Calendar Date Highlighting

## Summary
Fixed the calendar month view to properly separate "Today" indicator from "Selected Date" highlighting, eliminating phantom highlights and ensuring deterministic behavior.

## Changes Made

### 1. State Management (`macOS/Views/CalendarPageView.swift`)

**Before:**
- `selectedDate` defaulted to `Date()` on initialization
- Mixed use of `focusedDate` and `selectedDate` for highlighting logic
- Navigation automatically updated `selectedDate`, causing unwanted highlights

**After:**
- `selectedDate` is now `Date?` initialized to `nil` (no default selection)
- Added computed properties:
  - `todayDate`: Always returns current date normalized to start of day
  - `displayDate`: Returns `selectedDate ?? focusedDate` for sidebar display
- Separated navigation (`focusedDate`) from explicit selection (`selectedDate`)

### 2. Highlighting Logic

**MonthCalendarView.swift (lines ~773-784):**
```swift
// Before: Used focusedDate for isSelected
let isSelected = calendar.isDate(day.date, inSameDayAs: focusedDate)

// After: Separate today vs selected using full date equality
let isToday = calendar.isDate(day.date, inSameDayAs: Date())
let isSelected = selectedDate != nil && calendar.isDate(day.date, inSameDayAs: selectedDate!)
```

**Key principle:** Only highlight a date as "selected" when user explicitly clicks it.

### 3. Navigation Behavior

**shift(by:) method:**
- Removed automatic `selectedDate = newDate` when navigating between months/weeks
- User can now browse months without triggering selections
- Selection only happens on explicit day clicks or "Today" button

**jumpToToday():**
- Explicitly sets `selectedDate = today` when user clicks "Today" button
- This is intentional: clicking "Today" is an explicit selection action

### 4. Sidebar Display

Updated `sidebarDateTitle` and `sidebarDateSubtitle` to use `displayDate` computed property, which:
- Shows selected date when one exists
- Falls back to focused date (current month view) when nothing selected
- Ensures sidebar always shows relevant date without forcing selection

## Acceptance Criteria Met

✅ **Fresh launch does not highlight a non-today date**
- `selectedDate` initializes to `nil`
- No highlight appears until user clicks a date or "Today"

✅ **Selection highlight appears only on explicit user selection**
- `isSelected` check requires `selectedDate != nil` AND date match
- Navigation doesn't trigger selection

✅ **Today indicator is visually distinct from selection**
- `isToday` uses `calendar.isDate(_:inSameDayAs: Date())`
- `isSelected` uses `calendar.isDate(_:inSameDayAs: selectedDate!)`
- `MonthDayCell` applies different styling to each state

## Default Behavior

**Chosen approach:** No selection until explicit user click

**Rationale:**
- Prevents phantom highlights on arbitrary dates
- Clearer user mental model: selection only happens when I click
- Today indicator is always visible regardless of selection
- Sidebar defaults to showing focused month's first visible day

## Visual States

1. **Today (unselected):** Blue accent outline, no background fill
2. **Selected date (not today):** Accent color background, white text
3. **Today + selected:** Accent color background, white text (selection takes precedence)
4. **Normal date:** No special styling

## Testing Checklist

- [ ] Launch app fresh → no non-today dates highlighted ✅
- [ ] Navigate between months → no auto-selection ✅
- [ ] Click any date → that date gets selected ✅
- [ ] Click "Today" → today gets selected ✅
- [ ] Today indicator always visible regardless of selection ✅
- [ ] Sidebar updates correctly with selected date ✅

## Notes

This fix is part of the larger Calendar.01 initiative (issue #273) to create a deterministic, stable calendar month view with proper sidebar and fixed grid geometry.

## Related Issues

- Depends on: #273 (Calendar Month View full refactor)
- Resolves: #274 (This issue)
