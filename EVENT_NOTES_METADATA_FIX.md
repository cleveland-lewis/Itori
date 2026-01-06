# Event Notes - Planner Metadata Fix

**Date:** 2026-01-06  
**Issue:** Planner-generated events showing raw metadata in Notes field

---

## Problem

When viewing calendar events created by the planner, the Notes field was displaying raw internal metadata:

```
[RootsPlanner]
block_id: 7631d9d33e6f6756bc1b3d8627dcc9d7c1e0e3d23d9e6276ff09d-d29aa2c787
source: planner
day_key: 2026-01-06T05:00:00.000-05:00
kind: Homework Session
start: 2026-01-06T14:00:00.000-05:00
end: 2026-01-06T15:00:00.000-05:00
items: 8524E9E2-3120-4F85-88EB-977B3794BF9A:17999E6B-F86A-4132-8770-4AA2585E8795
[/RootsPlanner]
```

This metadata is for internal tracking and shouldn't be visible to users.

---

## Solution

Updated `CalendarManager.decodeNotesWithCategory()` to strip planner metadata blocks.

**File:** `SharedCore/State/CalendarManager.swift`

### Key Changes

1. **Added planner metadata removal** using regex pattern:
   ```swift
   let plannerPattern = #"\[RootsPlanner\][\s\S]*?\[/RootsPlanner\]"#
   workingNotes = workingNotes.replacingOccurrences(of: plannerPattern, with: "", options: .regularExpression)
   ```

2. **Two-pass cleaning:**
   - First: Extract category marker
   - Second: Remove planner metadata
   - Final: Trim whitespace

3. **Maintains category extraction** while hiding metadata

---

## User Experience

### Before
```
Notes:
[RootsPlanner]
block_id: 7631d9d33e6f6756bc1b3d8627dcc9d7c1e0e3d23d9e6276ff09d...
source: planner
kind: Homework Session
...
[/RootsPlanner]
```

### After
```
Notes:
(empty or user notes only)
```

---

## Benefits

- ✅ Clean, professional event display
- ✅ No technical metadata visible
- ✅ Metadata preserved for internal tracking
- ✅ User notes still displayed correctly

**Status:** ✅ Fixed
