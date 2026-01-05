# Layout Stress Test Results
**Date:** 2026-01-05  
**Status:** NOT STARTED

This document records layout stress testing for production readiness.

---

## Test Matrix

### iOS Tests

#### Test 1: Dynamic Type AX5 (200% Scale)
**Status:** ⬜ NOT TESTED

**Steps:**
1. Settings → Accessibility → Display & Text Size → Larger Text → Max slider
2. Launch Itori
3. Navigate through each screen

**Screens to Check:**
- [ ] Dashboard
- [ ] Courses list
- [ ] Assignment list
- [ ] Timer page
- [ ] Settings

**Pass Criteria:**
- Text doesn't truncate unexpectedly
- Buttons remain tappable
- No overlapping elements
- Scrolling works

**Issues Found:** (none yet)

---

#### Test 2: Reduce Transparency
**Status:** ⬜ NOT TESTED

**Steps:**
1. Settings → Accessibility → Display & Text Size → Reduce Transparency → ON
2. Launch Itori
3. Check material backgrounds

**Pass Criteria:**
- Cards still visible against background
- No loss of visual hierarchy
- No color contrast issues

**Issues Found:** (none yet)

---

### iPadOS Tests

#### Test 3: Split View Resize
**Status:** ⬜ NOT TESTED

**Steps:**
1. Open Itori in Split View
2. Drag divider from narrow → wide → narrow
3. Do this while interacting (e.g., scrolling, editing)

**Screens to Check:**
- [ ] Dashboard (narrow vs wide layout)
- [ ] Courses (list vs grid)
- [ ] Assignment detail view

**Pass Criteria:**
- Layout adapts smoothly
- No layout explosion or overlap
- Horizontal size class changes respected
- GeometryReader constraints hold

**Issues Found:** (none yet)

---

#### Test 4: Rotation Mid-Interaction
**Status:** ⬜ NOT TESTED

**Steps:**
1. Open assignment edit sheet
2. Rotate device portrait → landscape
3. Continue editing
4. Rotate back

**Pass Criteria:**
- Sheet stays visible
- Input focus maintained
- No keyboard layout bugs
- Data not lost

**Issues Found:** (none yet)

---

### macOS Tests

#### Test 5: Window Resize Tiny → Huge
**Status:** ⬜ NOT TESTED

**Steps:**
1. Resize window to minimum size (500x400 or smallest allowed)
2. Check each page
3. Resize to maximum (full screen)
4. Check layout again

**Screens to Check:**
- [ ] Dashboard
- [ ] Courses
- [ ] Assignments
- [ ] Timer
- [ ] Settings

**Pass Criteria:**
- Minimum size enforced (or graceful degradation)
- No horizontal scroll at minimum
- Full screen uses space well
- Sidebar collapses/expands correctly

**Issues Found:** (none yet)

---

## Automated Tests (Future)

### Snapshot Tests
**Status:** ⬜ NOT IMPLEMENTED

**Required:**
- Snapshot baseline for each screen at:
  - Default size
  - Dynamic Type AX5
  - Narrow width (iPhone SE)
  - Wide width (iPad Pro)

**Implementation:** `Tests/ItoriUITests/LayoutStressTests.swift`

---

## Debug Harness (Optional)

**Create:** `SharedCore/Views/LayoutDebugPanel.swift` (if useful)

**Features:**
- Toggle Dynamic Type scales
- Toggle Reduce Transparency
- Simulate size class changes
- Show layout constraints (SwiftUI debug)

---

## Known Issues (To Fix)

### From Audit
1. **Dashboard GeometryReader** → Max-width constraint may break on extreme sizes
2. **Calendar grid merge conflicts** → Unresolved, may have layout bugs
3. **Backup files in Views** → Indicates recent layout churn

---

## Action Items

### CRITICAL (Must Do Before Ship)
1. Run full test matrix manually (3-4 hours)
2. Fix any layout explosions found
3. Document pass/fail for each test

### HIGH (Should Do Before Ship)
4. Test on real devices (iPhone SE, iPad Pro, Mac)
5. Add at least one snapshot test for regression catching

### MEDIUM (Can Defer)
6. Create layout debug harness
7. Automate full stress matrix

---

## Sign-Off

**Layout Stress Testing Complete When:**
- [ ] All test matrix items marked ✅
- [ ] Zero layout explosions on extreme sizes
- [ ] At least one snapshot test exists
- [ ] Results documented

**Tester:** [NAME]  
**Date:** [DATE]
