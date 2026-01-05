# Release Scope: v1.0
**Date:** 2026-01-05  
**Status:** DRAFT

This document defines what is IN and OUT of scope for v1.0. No ambiguity.

---

## In Scope (Must Ship)

### Core Features
- ✅ Dashboard with upcoming tasks and calendar events
- ✅ Course management (add/edit/delete with soft delete)
- ✅ Assignment tracking (homework, exams, tasks)
- ✅ Timer functionality with Pomodoro support
- ✅ Calendar integration (read device calendar)
- ✅ Study analytics (if trackStudyHours enabled)
- ✅ Planner with auto-scheduling (PlannerEngine)
- ✅ iCloud sync (basic, last-write-wins)
- ✅ Multi-platform (macOS, iOS, iPadOS)
- ✅ Localization (English + existing translations)

### Data Integrity
- ✅ Soft delete with cascade (Course → Tasks)
- ✅ Restore functionality
- ✅ Semester archiving

### UI/UX
- ✅ Design system with spacing tokens
- ✅ Dark mode support
- ✅ Basic accessibility (VoiceOver labels)
- ✅ Calendar access banner
- ✅ Empty states for major views

---

## Out of Scope (Explicitly Cut for v1.0)

### Incomplete Features (Cut List)
- ❌ **Multi-Semester Selection** (`activeSemesterIds`)
  - **Reason:** UI not complete, data model done but no user-facing controls
  - **Alternative:** Ship with single "current semester" model (existing behavior)
  - **Future:** v1.1 or v1.2
  
- ❌ **Task Alarm Scheduling** (`TaskAlarmScheduler`)
  - **Reason:** Marked with 5 TODOs, not production-ready
  - **Alternative:** Remove or hide behind `#if DEBUG`
  - **Future:** v1.1 with full notification system

- ❌ **Advanced iCloud Conflict Resolution**
  - **Reason:** Conflict strategy not documented
  - **Alternative:** Ship with last-write-wins + error logging
  - **Future:** v1.2 with conflict UI

### Deferred Features
- ❌ **Practice Test Generation** (if incomplete)
- ❌ **Flashcard Study Mode** (if incomplete)
- ❌ **Advanced LLM Features** (beyond basic PlannerEngine)
- ❌ **Widget Extensions** (if not fully tested)
- ❌ **Siri Shortcuts**
- ❌ **Export/Import**

---

## Feature Flags (Optional)

If features are partially complete but risky, hide behind flags:

```swift
#if DEBUG
// Task alarm scheduling
#endif
```

**Decision Required:** For each cut feature, choose:
- **Remove:** Delete code, ship without
- **Flag:** Keep code, hide behind `#if DEBUG` or `AppSettingsModel.devModeEnabled`
- **Finish:** Complete implementation (extends timeline)

---

## Cut List Actions

### activeSemesterIds
- **Action:** REMOVE (revert to single currentSemesterId)
- **Files to Revert:**
  - `SharedCore/State/CoursesStore.swift` (remove activeSemesterIds Set)
  - Any UI changes depending on activeCourses computed property
- **Reason:** UI not complete = phantom feature = user confusion

### TaskAlarmScheduler
- **Action:** REMOVE
- **Files to Delete:**
  - `Platforms/iOS/Services/TaskAlarmScheduler.swift`
  - `Platforms/iOS/Services/TaskAlarmScheduling.swift` (if exists)
  - `Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift` (if not used elsewhere)
- **Reason:** 5 TODOs = not production-ready

### iCloud Conflict Resolution
- **Action:** DOCUMENT MINIMAL STRATEGY
- **Strategy:** Last-write-wins, log conflicts, show generic error banner if sync fails
- **Files to Update:**
  - Create `docs/ICLOUD_SYNC_STRATEGY.md` documenting behavior
  - Ensure `SyncMonitor.swift` logs conflicts
  - Add banner to settings if sync fails

---

## Version Strategy

**v1.0:** Current scope (with cuts applied)  
**v1.1:** Add back multi-semester selection (if UI completed)  
**v1.2:** Add task alarms (if notification system mature)  
**v2.0:** Advanced features (conflict UI, LLM extensions, export/import)

---

## Testing Scope

### Must Test Before v1.0
- Add/edit/delete courses and assignments
- Soft delete cascade
- Timer start/stop/reset
- Calendar permission flow
- Dashboard rendering with/without data
- iCloud sync enable/disable
- Platform parity (macOS vs iOS basic flows)

### Can Defer Testing
- Edge cases in deleted/restored items
- LLM fallback paths
- Advanced calendar filtering
- Notification permission flows (if alarms removed)

---

## Success Criteria

**v1.0 is ready when:**
- All "In Scope" features work reliably
- All "Cut List" features are removed or flagged
- No half-built UI elements visible to users
- CI enforces hygiene rules
- Manual QA pass complete

---

**Next Action:** Apply cuts, update CoursesStore, delete TaskAlarmScheduler files.
