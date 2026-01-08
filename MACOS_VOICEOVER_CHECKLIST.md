# macOS VoiceOver Quick Implementation Checklist

**Target:** Add 50+ accessibility labels across 6 main macOS views  
**Time Estimate:** 2-3 hours for complete implementation  
**Current Status:** ~20% complete

---

## ✅ Completed

### DashboardView.swift (3/20 items)
- [x] Energy level button
- [x] Add event button  
- [x] Event rows

---

## 🔄 High Priority - Core User Flows

### TimerPageView.swift (3/15 items) - **30 min remaining**

**What to add:**
1. Start timer button label
2. Activity selection buttons
3. Timer mode picker
4. Pomodoro progress circles
5. Time remaining display
6. Session history items
7. Add activity button
8. Settings gear button
9. Timer duration controls
10. Break/work mode indicator
11. Current activity display
12. Notification toggle

**Code locations:**
- Line ~585: Focus window button ✅
- Line ~615: Pause button ✅
- Line ~626: Stop button ✅
- Line ~XXX: Start button (need to add)
- Line ~444: Activity buttons (need to add)
- Line ~XXX: Mode picker (need to add)

---

### AssignmentsPageView.swift (0/18 items) - **45 min**

**What to add:**
1. Assignment row labels (title, course, due date)
2. Completion toggle buttons
3. Priority indicator labels
4. Filter buttons (Today, Week, Month, All)
5. Sort dropdown
6. Add assignment button
7. Search field
8. Assignment type badges
9. Due date badges
10. Course name labels
11. Edit button
12. Delete button
13. View details action
14. Calendar integration button
15. Bulk actions
16. Empty state message
17. Assignment count summary
18. Quick add button

**Code locations:**
- Line ~XXX: Assignment rows
- Line ~XXX: Filter buttons
- Line ~XXX: Add button

---

### CoursesPageView.swift (1/16 items) - **40 min**

**What to add:**
1. Course card labels (code, title, grade)
2. Semester picker
3. Add course button
4. Edit course button
5. Delete course button
6. Archive course button
7. Course color indicator
8. Current grade display
9. Credits display
10. Professor name
11. Schedule display
12. Course actions menu
13. Semester filter
14. Active/Archived toggle
15. Sort options
16. Empty state

**Code locations:**
- Line ~XXX: Course cards
- Line ~XXX: Semester picker
- Line ~XXX: Add button

---

### GradesPageView.swift (0/12 items) - **30 min**

**What to add:**
1. GPA display label
2. Grade chart accessibility
3. Course grade rows (course, percent, letter)
4. Grade calculator button
5. Semester filter
6. Grade trend indicator
7. Target grade display
8. Grade distribution chart
9. Add grade button
10. Edit grade button
11. Grade history
12. Analytics summary

**Code locations:**
- Line ~XXX: GPA card
- Line ~XXX: Grade chart
- Line ~XXX: Grade rows

---

## 🟡 Medium Priority - Important but Less Frequent

### PlannerPageView.swift (1/14 items) - **35 min**

**What to add:**
1. Planned task blocks
2. Time slot buttons
3. Date picker
4. Calendar grid cells
5. Drag handles
6. Duration indicators
7. Task priority badges
8. Scheduling suggestions
9. Conflicts warning
10. Auto-schedule button
11. Clear schedule button
12. View mode toggle
13. Time range selector
14. Schedule summary

---

### SettingsView.swift (0/25 items) - **50 min**

**What to add:**
1. All toggle switches
2. All pickers (theme, language, etc.)
3. All text fields
4. All sliders
5. Navigation links
6. Account section
7. Notifications section
8. Appearance section
9. General section
10. Timer section
11. Planner section
12. Courses section
13. Grades section
14. Calendar section
15. Flashcards section
16. Practice tests section
17. Storage section
18. Privacy section
19. About section
20. Help button
21. Feedback button
22. Sign out button
23. Delete account button
24. Export data button
25. Import data button

---

## Implementation Strategy

### Phase 1: Critical Path (2 hours)
1. ✅ Dashboard - Energy/events (10 min) ✅ DONE
2. Timer - All controls (30 min)
3. Assignments - List and actions (45 min)
4. Courses - Cards and navigation (40 min)

**Result:** Core workflows 80% accessible

### Phase 2: Secondary Views (1 hour)
5. Grades - Display and chart (30 min)
6. Planner - Schedule view (35 min)

**Result:** Main features 75% accessible

### Phase 3: Settings & Polish (30 min)
7. Settings - All controls (25 min)
8. Testing & fixes (15 min)

**Result:** Full app 80%+ accessible

---

## Quick Copy-Paste Patterns

### Pattern 1: Button with Icon
```swift
.accessibilityLabel("Action name")
.accessibilityHint("What happens when activated")
```

### Pattern 2: List Row
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("All relevant info combined")
.accessibilityHint("Double-click for options")
```

### Pattern 3: Hide Decorative
```swift
.accessibilityHidden(true)
```

### Pattern 4: Chart
```swift
.accessibilityLabel("Chart name")
.accessibilityValue("Data summary")
.accessibilityHint("Shows trend information")
```

### Pattern 5: Toggle/Checkbox
```swift
.accessibilityLabel("Setting name")
.accessibilityValue(isOn ? "On" : "Off")
.accessibilityAddTraits(.isButton)
```

---

## File-by-File Action Plan

### DashboardView.swift
**Remaining work:** 17 items
- [ ] Assignment rows (lines ~850-900)
- [ ] Grade widgets (lines ~950-1000)
- [ ] Study chart (lines ~1100-1150)
- [ ] Today's tasks (lines ~600-650)
- [ ] Calendar preview (lines ~700-750)
- [ ] Add assignment button
- [ ] Add grade button
- [ ] Quick actions
- [ ] Status strip items
- [ ] Energy card decorative elements

### TimerPageView.swift
**Remaining work:** 12 items
- [ ] Start button (line ~XXX)
- [ ] Activity list (lines ~444-500)
- [ ] Mode picker (lines ~650-700)
- [ ] Pomodoro circles (lines ~600-610)
- [ ] Timer display (lines ~XXX)
- [ ] Session history
- [ ] Settings
- [ ] Add activity
- [ ] Time controls

### AssignmentsPageView.swift
**Remaining work:** 18 items
- [ ] All assignment rows
- [ ] All filter buttons
- [ ] Add button
- [ ] Search
- [ ] Actions

### CoursesPageView.swift  
**Remaining work:** 15 items
- [ ] Course cards
- [ ] Semester picker
- [ ] Actions

### GradesPageView.swift
**Remaining work:** 12 items
- [ ] GPA display
- [ ] Chart
- [ ] Grade rows

### PlannerPageView.swift
**Remaining work:** 13 items
- [ ] Task blocks
- [ ] Time slots
- [ ] Actions

### SettingsView.swift
**Remaining work:** 25 items
- [ ] All controls
- [ ] All navigation

---

## Testing Checklist

After implementation, test with VoiceOver:
- [ ] Dashboard navigation
- [ ] Start and stop timer
- [ ] Browse assignments
- [ ] View courses
- [ ] Check grades
- [ ] Plan schedule
- [ ] Change settings
- [ ] All keyboard shortcuts work
- [ ] No missed buttons
- [ ] No confusing labels

---

## Progress Tracking

| View | Items | Done | % | Time Left |
|------|-------|------|---|-----------|
| Dashboard | 20 | 3 | 15% | 25 min |
| Timer | 15 | 3 | 20% | 30 min |
| Assignments | 18 | 0 | 0% | 45 min |
| Courses | 16 | 1 | 6% | 40 min |
| Grades | 12 | 0 | 0% | 30 min |
| Planner | 14 | 1 | 7% | 35 min |
| Settings | 25 | 0 | 0% | 50 min |
| **Total** | **120** | **8** | **7%** | **~4 hrs** |

---

## Success Metrics

**Minimum Viable:** 50+ labels (40% coverage) - **1.5 hours**
**Target:** 80+ labels (65% coverage) - **2.5 hours**  
**Excellent:** 100+ labels (80% coverage) - **3.5 hours**

Current: 8 labels (~7%)

---

**Next Action:** Continue with TimerPageView.swift remaining items (30 min work)
