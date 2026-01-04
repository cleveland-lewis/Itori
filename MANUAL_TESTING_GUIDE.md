# Manual Testing Guide: Active Semesters + Personal Tasks

## Date
2026-01-04

## Branch
`feature/active-semesters-personal-tasks`

---

## Pre-Testing Setup

### 1. Build the app
```bash
cd /Users/clevelandlewis/Desktop/Itori
xcodebuild -project ItoriApp.xcodeproj -scheme "Itori" -configuration Debug -destination 'platform=macOS' build
```

### 2. Launch the app
- Open Xcode
- Select "Itori" scheme
- Run on macOS

---

## Test Suite 1: Active Semesters (Single to Multiple)

### Test 1.1: Fresh Install (Default Behavior)
**Expected**: Single semester support works as before

**Steps:**
1. Launch app (fresh install or after reset)
2. Navigate to Courses tab
3. Click "Add Semester"
4. Create "Fall 2025", mark as current → Save

**Verify:**
- ✅ Fall 2025 appears in semester picker
- ✅ "1 Semesters" or "Fall 2025" shown in picker
- ✅ Can add courses to this semester
- ✅ Courses appear in Courses tab

---

### Test 1.2: Add Second Semester (Multi-Semester Activation)
**Expected**: Can activate multiple semesters simultaneously

**Steps:**
1. Add "Spring 2026" semester (not marked as current)
2. Click semester picker menu
3. Select both "Fall 2025" and "Spring 2026" (checkmarks on both)

**Verify:**
- ✅ Semester picker shows "2 Semesters"
- ✅ Both semesters have checkmarks in menu
- ✅ Courses from BOTH semesters appear in Courses tab
- ✅ activeSemesterIds contains both IDs

**Screenshot locations:**
- Semester picker with 2 selected
- Courses tab showing courses from both semesters

---

### Test 1.3: Toggle Semester On/Off
**Expected**: Toggling affects what courses are shown

**Steps:**
1. In semester picker menu, uncheck "Spring 2026"
2. Observe Courses tab
3. Re-check "Spring 2026"
4. Observe again

**Verify:**
- ✅ Unchecking Spring removes its courses from view
- ✅ Re-checking Spring brings them back
- ✅ activeSemesterIds updates correctly
- ✅ Picker label updates (e.g., "1 Semesters" → "2 Semesters")

---

### Test 1.4: Clear All / Select All
**Expected**: Bulk actions work

**Steps:**
1. Open semester picker menu
2. Click "Clear All"
3. Observe: "No Active Semester" message
4. Click picker again, select "Select All"

**Verify:**
- ✅ Clear All: activeSemesterIds becomes empty
- ✅ Courses tab shows "No active semesters selected"
- ✅ Select All: activeSemesterIds contains all semester IDs
- ✅ All courses visible again

---

### Test 1.5: Active Semesters with Archived Semester
**Expected**: Archived semesters don't appear in activeCourses

**Steps:**
1. Create "Summer 2024" semester
2. Add 1 course to it
3. Archive Summer 2024 (Settings → Semesters → Archive)
4. Select all semesters in picker

**Verify:**
- ✅ Summer 2024 not in semester picker menu
- ✅ Summer 2024's course NOT in Courses tab (even if in activeSemesterIds)
- ✅ activeSemesters computed property excludes archived

---

## Test Suite 2: Personal Tasks

### Test 2.1: Create Personal Task
**Expected**: Can create task without selecting a course

**Steps:**
1. Click + to add assignment
2. Enter title: "Dentist appointment"
3. Set due date: Tomorrow
4. In course picker, select "Personal (No Course)"
5. Save

**Verify:**
- ✅ Task saves successfully (no validation error)
- ✅ task.courseId == nil
- ✅ task.isPersonal == true
- ✅ Appears in Assignments tab

**Screenshot:**
- Course picker showing "Personal (No Course)" option

---

### Test 2.2: Personal Tasks Filter
**Expected**: Personal filter shows only personal tasks

**Steps:**
1. Create 2 personal tasks:
   - "Gym" (no course)
   - "Groceries" (no course)
2. Create 2 course tasks:
   - "Math HW" (Math 101)
   - "CS Project" (CS 101)
3. Navigate to Assignments tab
4. Select filter: "Personal"

**Verify:**
- ✅ Only "Gym" and "Groceries" visible
- ✅ Course tasks hidden
- ✅ Personal Tasks section exists
- ✅ Section shows person icon

---

### Test 2.3: Personal Tasks in Dashboard "Due Today"
**Expected**: Personal tasks appear alongside course tasks

**Steps:**
1. Create personal task "Call Mom" due today
2. Create course task "Essay Draft" due today
3. Navigate to Dashboard

**Verify:**
- ✅ Dashboard shows both tasks in "Due Today"
- ✅ Personal task labeled as "Personal"
- ✅ Course task shows course code
- ✅ No crashes or missing data

---

### Test 2.4: Personal Task Editing
**Expected**: Can edit personal task and keep it personal

**Steps:**
1. Edit existing personal task "Gym"
2. Change title to "Gym - Upper Body"
3. Keep course as "Personal (No Course)"
4. Save

**Verify:**
- ✅ Task updates correctly
- ✅ Still personal (courseId == nil)
- ✅ Changes persist after app restart

---

### Test 2.5: Convert Task: Personal ↔ Course
**Expected**: Can change task association

**Steps:**
1. Create personal task "Read Book"
2. Edit task
3. Change course from "Personal (No Course)" to "English 101"
4. Save
5. Verify task now shows under English 101 course

Then:
6. Edit same task again
7. Change back to "Personal (No Course)"
8. Save

**Verify:**
- ✅ Task moves from personal to course correctly
- ✅ Task moves from course back to personal correctly
- ✅ No data loss during conversion

---

## Test Suite 3: Integration Tests

### Test 3.1: Multi-Semester + Personal Tasks
**Expected**: All features work together

**Setup:**
- 2 active semesters: Fall 2025, Spring 2026
- Fall 2025: Math 101, CS 101 courses
- Spring 2026: Physics 101 course
- 2 personal tasks
- 4 course tasks (2 per semester)

**Verify:**
- ✅ Dashboard shows mix of personal + course tasks
- ✅ Courses tab shows all courses from both semesters
- ✅ Assignments "Personal" filter works
- ✅ Planner includes personal tasks
- ✅ No performance issues with mixed data

---

### Test 3.2: Data Persistence
**Expected**: State persists across app restarts

**Steps:**
1. Set Fall 2025 + Spring 2026 as active
2. Create 2 personal tasks
3. Create 3 course tasks
4. Quit app completely (Cmd+Q)
5. Relaunch app

**Verify:**
- ✅ activeSemesterIds preserved
- ✅ Semester picker shows "2 Semesters"
- ✅ All personal tasks still present
- ✅ All course tasks still present
- ✅ No duplicate data

---

### Test 3.3: iCloud Sync (If Enabled)
**Expected**: Multi-semester + personal tasks sync correctly

**Steps:**
1. Enable iCloud sync in Settings
2. Create data on Device A:
   - 2 active semesters
   - 1 personal task
   - 2 course tasks
3. Wait for sync
4. Open app on Device B

**Verify:**
- ✅ activeSemesterIds syncs
- ✅ Semester picker shows correct active semesters
- ✅ Personal task appears
- ✅ Course tasks appear
- ✅ No conflicts or data loss

---

## Test Suite 4: Edge Cases

### Test 4.1: Empty States
**Expected**: Helpful empty state messages

**Test Cases:**
- No semesters created
- No active semesters selected
- No courses in active semesters
- No personal tasks
- Filter shows no results

**Verify:**
- ✅ All empty states show helpful messages
- ✅ No crashes with empty data
- ✅ Clear guidance on what to do next

---

### Test 4.2: Delete Active Semester
**Expected**: Handles deletion gracefully

**Steps:**
1. Have 2 active semesters with courses
2. Delete one active semester
3. Observe activeSemesterIds and UI

**Verify:**
- ✅ Deleted semester removed from activeSemesterIds
- ✅ Its courses no longer visible
- ✅ Other semester still active
- ✅ No crashes

---

### Test 4.3: Maximum Semesters (Scalability)
**Expected**: UI scales beyond 3-4 semesters

**Steps:**
1. Create 10 semesters
2. Activate all 10
3. Open semester picker menu

**Verify:**
- ✅ Menu scrolls if needed
- ✅ No layout issues
- ✅ "10 Semesters" label
- ✅ Performance acceptable

---

### Test 4.4: Personal Task Due Date Edge Cases
**Expected**: Works with various due date scenarios

**Test Cases:**
- Personal task with no due date
- Personal task due today
- Personal task overdue
- Personal task far in future

**Verify:**
- ✅ All cases handled correctly
- ✅ Sorting works
- ✅ Filters work (Due Soon, Overdue)
- ✅ Dashboard shows today's personal tasks

---

## Test Suite 5: Migration Testing

### Test 5.1: Upgrade from Old Version
**Expected**: Seamless migration from currentSemesterId to activeSemesterIds

**Simulation:**
1. Manually edit courses.json to only have currentSemesterId
2. Remove activeSemesterIds field
3. Relaunch app

**Verify:**
- ✅ currentSemesterId migrates to activeSemesterIds
- ✅ Single semester becomes single active semester
- ✅ No data loss
- ✅ App functions normally

---

### Test 5.2: Downgrade Compatibility
**Expected**: Old version ignores new field

**Note**: This test requires access to older build
- Old version should ignore activeSemesterIds
- Use currentSemesterId as fallback
- Should not crash

---

## Test Suite 6: Performance & Stress Tests

### Test 6.1: Large Dataset
**Expected**: Performs well with realistic data volume

**Setup:**
- 6 semesters (3 active)
- 30 courses across semesters
- 50 personal tasks
- 150 course tasks

**Verify:**
- ✅ Semester picker responsive
- ✅ Courses tab loads quickly
- ✅ Assignments tab filters fast
- ✅ No memory leaks

---

### Test 6.2: Rapid Toggle
**Expected**: Handles rapid UI interactions

**Steps:**
1. Rapidly toggle semesters on/off (click 20 times)
2. Rapidly switch assignment filters
3. Rapidly add/remove personal tasks

**Verify:**
- ✅ No crashes
- ✅ UI remains responsive
- ✅ State updates correctly
- ✅ No visual glitches

---

## Regression Tests

### Must Not Break:
- ✅ Course-scoped views (CourseDetailView) still filter correctly
- ✅ Planner still generates sessions for personal tasks
- ✅ Calendar sync works with personal tasks
- ✅ GPA calculation unaffected
- ✅ Search works for personal tasks
- ✅ Notifications work for personal tasks
- ✅ Export/import includes personal tasks

---

## Known Limitations

### Current Scope:
- Personal tasks don't have semester association
- Can't group personal tasks by category (future enhancement)
- No "bulk convert to personal" action yet
- Semester picker menu doesn't show course count per semester

### Out of Scope:
- Semester groups (Academic Year 2024-2025)
- Personal task tags/categories
- Separate "Work" vs "Personal" task types

---

## Success Criteria

### Core Functionality:
- [ ] Can activate multiple semesters
- [ ] activeCourses shows courses from all active semesters
- [ ] Can create personal tasks (courseId == nil)
- [ ] Personal tasks appear in all relevant views
- [ ] Personal filter works in Assignments tab
- [ ] Migration from single to multi-semester works

### User Experience:
- [ ] Semester picker scales beyond 3-4 semesters
- [ ] Personal tasks clearly labeled/distinguished
- [ ] Empty states helpful
- [ ] No confusing UI states

### Technical:
- [ ] No data loss during migration
- [ ] Persistence works correctly
- [ ] iCloud sync works (if enabled)
- [ ] No crashes in any test scenario
- [ ] Performance acceptable with large datasets

---

## Bug Reporting Template

**If you find a bug, report with:**

```
Title: [Brief description]

Steps to Reproduce:
1. ...
2. ...
3. ...

Expected Behavior:
...

Actual Behavior:
...

Data State:
- Active semesters: X
- Total courses: Y
- Personal tasks: Z
- Course tasks: W

Console Errors:
[Paste any errors]

Screenshots:
[Attach if relevant]
```

---

## Testing Sign-Off

**Tester:** ___________________  
**Date:** ___________________  
**Version:** feature/active-semesters-personal-tasks  
**Result:** PASS / FAIL / NEEDS_FIXES  

**Notes:**
_____________________________________
_____________________________________
_____________________________________
