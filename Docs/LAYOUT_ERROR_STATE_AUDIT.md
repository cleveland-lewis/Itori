# Phase 3: Layout + Error State Audit

**Date:** 2026-01-05  
**Status:** In Progress

---

## Part 1: Empty State Audit

### Core Screens to Check

#### Dashboard
**Location:** `Shared/Views/DashboardView.swift`  
**Empty Conditions:**
- No active semester
- No courses in current semester
- No assignments
- No upcoming tasks

**Current Status:** [ ] NOT CHECKED  
**Action Required:** Verify explicit empty states exist

---

#### Courses Screen
**Location:** `SharedCore/Views/CoursesView.swift`  
**Empty Conditions:**
- No semesters created
- No courses in current semester

**Current Status:** [ ] NOT CHECKED  
**Action Required:** Verify explicit empty states exist

---

#### Assignments Screen  
**Location:** `SharedCore/Views/AssignmentsView.swift`  
**Empty Conditions:**
- No assignments exist
- All assignments completed

**Current Status:** [ ] NOT CHECKED  
**Action Required:** Verify explicit empty states exist

---

#### Planner Screen
**Location:** `SharedCore/Views/PlannerView.swift`  
**Empty Conditions:**
- No scheduled blocks
- No assignments to schedule

**Current Status:** [ ] NOT CHECKED  
**Action Required:** Verify explicit empty states exist

---

#### Timer Screen
**Location:** `SharedCore/Views/TimerView.swift`  
**Empty Conditions:**
- No active timer
- No recent sessions

**Current Status:** [ ] NOT CHECKED  
**Action Required:** Verify explicit empty states exist

---

## Part 2: Error State Audit

### Critical Failure Modes

#### 1. Calendar Permissions Denied
**Locations:**
- CalendarStore initialization
- Event creation/edit flows

**Required Behavior:**
- Inline message explaining why permission is needed
- Button to open Settings
- Graceful degradation (app remains usable)

**Current Status:** [ ] NOT CHECKED

---

#### 2. Network Failure (LLM Requests)
**Locations:**
- AIEngine request methods
- Study guide generation
- Test generation

**Required Behavior:**
- Clear error message
- Retry button
- Offline indication if applicable

**Current Status:** [ ] NOT CHECKED

---

#### 3. iCloud Sync Disabled/Conflict
**Locations:**
- CoursesStore iCloud methods
- AssignmentsStore iCloud methods

**Required Behavior:**
- Banner or inline message
- Option to enable (if disabled)
- Conflict resolution strategy documented

**Current Status:** [ ] NOT CHECKED

---

#### 4. File Import Failure
**Locations:**
- Course file upload
- Syllabus parsing

**Required Behavior:**
- Clear error message (file format, size, etc.)
- Fallback options

**Current Status:** [ ] NOT CHECKED

---

## Part 3: Layout Stress Testing Protocol

### Test Matrix

#### Device Configurations
- [x] iPhone (standard size)
- [ ] iPhone (Pro Max size)
- [ ] iPad (portrait)
- [ ] iPad (landscape)
- [ ] iPad (split view narrow)
- [ ] iPad (split view wide)
- [ ] macOS (small window)
- [ ] macOS (large window)

#### Accessibility
- [ ] Dynamic Type AX5 (200%)
- [ ] Reduce Transparency ON
- [ ] Voice Over enabled

#### Stress Scenarios
- [ ] Rotation mid-interaction (iPad)
- [ ] Window resize mid-interaction (macOS)
- [ ] Long text content
- [ ] Many items in lists

---

## Findings Log

### Empty States

**[Screen Name] - [Date]**  
Status: ✅ PASS / ❌ FAIL / ⚠️ NEEDS FIX  
Details: ...

---

### Error States

**[Error Type] - [Date]**  
Status: ✅ PASS / ❌ FAIL / ⚠️ NEEDS FIX  
Details: ...

---

### Layout Issues

**[Screen/Component] - [Date]**  
Configuration: [Device/Setting]  
Issue: ...  
Fix Applied: ...

---

## Completion Criteria

Phase 3 is complete when:
- [ ] All core screens have explicit empty states
- [ ] All critical failure modes have user-facing error UI
- [ ] Layout stress tests pass on target configurations
- [ ] Findings documented and fixes committed

**Estimated Completion:** [TBD based on findings]

