# Assignment Editor - Quick Test Guide

## What Changed

The "New Assignment" screen now has:
- ✅ **Discrete Priority Selector** (5 levels: Lowest, Low, Medium, High, Urgent) instead of sliders
- ✅ **All fields persist correctly** and round-trip through save/load
- ✅ **Planner integration works** - priority affects scheduling

## Quick Test (5 minutes)

### Test 1: Create Assignment
1. Open Roots on iOS/iPad
2. Tap the **+** (quick add) button
3. Select **"Add Assignment"**
4. Fill in:
   - Title: "Math Homework"
   - Type: Homework
   - Course: (any course)
   - Due Date: Tomorrow
   - Estimated Time: 60 min (default is fine)
5. Tap **"Priority"** row
6. Select **"High"**
7. Tap **Save**

**Expected**: Assignment created, appears in Assignments list

### Test 2: Verify Persistence
1. Go to Assignments tab
2. Find "Math Homework"
3. Tap to open details
4. **Check**: Priority shows "High" ✅
5. **Check**: Time shows "60 minutes" ✅
6. Tap **"Edit"**
7. **Check**: Priority shows "High" in editor ✅

### Test 3: Edit & Round-Trip
1. While editing, change Priority to **"Urgent"**
2. Change Estimated Time to **90 min**
3. Tap **Save**
4. Reopen the assignment
5. **Check**: Priority now shows "Urgent" ✅
6. **Check**: Time now shows "90 minutes" ✅

### Test 4: Validation
1. Create new assignment
2. Leave Title empty
3. **Check**: Save button is disabled (grayed out) ✅
4. Type any title
5. **Check**: Save button is enabled ✅

### Test 5: Planner Integration
1. Go to Planner tab
2. Tap the **✨ Generate Plan** button
3. **Check**: "Math Homework" appears in schedule ✅
4. **Check**: High-priority items scheduled appropriately ✅

## What to Look For

### ✅ Good Signs
- Priority selector shows 5 clear options with checkmark
- All data persists after closing/reopening app
- No error messages or crashes
- Planner schedules assignments based on priority

### ❌ Red Flags
- Sliders still appear (old UI)
- Priority resets to "Medium" after save
- Save button stays disabled even with valid input
- Assignment not visible in planner after generation
- Crash when opening editor

## Comparison: Before vs After

| Feature | Before | After |
|---------|--------|-------|
| Priority UI | Two sliders (Importance, Difficulty) | Single discrete selector (5 levels) |
| Priority Labels | Hidden numeric values (0-1) | Clear labels (Lowest → Urgent) |
| Persistence | Importance persisted | Priority persisted as importance |
| Planner Access | Direct field access | Clean computed properties |
| Validation | Title only | Title + due date validity |
| Detail View | Showed Importance & Difficulty | Shows single Priority |

## Build Commands (if needed)

If you need to rebuild the app:

```bash
# iOS Simulator
xcodebuild -project RootsApp.xcodeproj \
  -scheme RootsiOS \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  clean build

# iPad Simulator  
xcodebuild -project RootsApp.xcodeproj \
  -scheme RootsiOS \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)' \
  clean build
```

## Files You Can Inspect

If you want to review the code:
1. **iOS/Scenes/IOSCorePages.swift** - Assignment editor UI (lines 933-1100)
2. **SharedCore/Models/SharedPlanningModels.swift** - Planner integration (bottom of file)
3. **ASSIGNMENT_EDITOR_COMPLETE.md** - Full implementation details

## Need Help?

If something isn't working:
1. Check Console.app for error messages
2. Verify you're running the latest build
3. Try deleting the app and reinstalling
4. Check the implementation doc for expected behavior

---
**Ready to test!** 🚀
