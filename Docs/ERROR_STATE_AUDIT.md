# Error State Audit
**Date:** 2026-01-05  
**Status:** NOT STARTED

This document audits error and empty states for production readiness.

---

## Empty States

### Screens with Dynamic Data

#### Dashboard
**Status:** ⬜ NOT AUDITED

**Scenarios:**
- [ ] No courses → What shows?
- [ ] No assignments → What shows?
- [ ] No calendar events → What shows?
- [ ] Calendar permission denied → Banner visible?

**Expected Behavior:** (TBD)

---

#### Courses List
**Status:** ⬜ NOT AUDITED

**Scenarios:**
- [ ] No semesters → What shows?
- [ ] No courses in current semester → What shows?
- [ ] All courses soft-deleted → What shows?

**Expected Behavior:** (TBD)

---

#### Assignment List
**Status:** ⬜ NOT AUDITED

**Scenarios:**
- [ ] No assignments → What shows?
- [ ] All assignments completed → What shows?
- [ ] All assignments soft-deleted → What shows?

**Expected Behavior:** (TBD)

---

#### Timer Page
**Status:** ⬜ NOT AUDITED

**Scenarios:**
- [ ] No tasks → What shows?
- [ ] No recent sessions → What shows?

**Expected Behavior:** (TBD)

---

## Error States

### Network-Dependent Features

#### LLM Features (PlannerEngine, AIEngine)
**Status:** ⬜ NOT AUDITED

**Failure Modes:**
- [ ] Network timeout → What happens?
- [ ] LLM API error → What shows to user?
- [ ] Feature disabled (devModeEnabled = false) → Silent fail?
- [ ] Invalid response format → What happens?

**Expected Behavior:**
- User sees friendly error message (not crash)
- Option to retry
- Graceful degradation (use fallback algorithm?)

---

#### Calendar Sync
**Status:** ⬜ NOT AUDITED

**Failure Modes:**
- [ ] Permission denied → Banner shown?
- [ ] Calendar API error → What shows?
- [ ] No calendars available → What shows?

**Expected Behavior:**
- CalendarAccessBanner visible when permission denied
- Generic error message on API failure
- Empty state when no calendars

---

#### iCloud Sync
**Status:** ⬜ NOT AUDITED

**Failure Modes:**
- [ ] iCloud disabled → What shows?
- [ ] Sync conflict detected → What happens?
- [ ] Network offline during sync → What happens?

**Expected Behavior:** (TBD - see `docs/ICLOUD_SYNC_STRATEGY.md`)

---

### Widget Failures
**Status:** ⬜ NOT AUDITED

**Failure Modes:**
- [ ] Widget data fetch fails → What shows in widget?
- [ ] Timer not running → Widget shows what?

**Expected Behavior:** (TBD)

---

## Polite Failure Rules

### Established Guidelines

#### Rule 1: No User-Facing Crashes
**All error paths must either:**
- Show user-friendly error message, OR
- Fail silently with logging (if non-critical)

Never: Crash, `fatalError()`, or show raw error description.

#### Rule 2: Empty States Are Not Blank Screens
**Every screen with dynamic data must have:**
- Explicit empty state UI (icon + message)
- Call-to-action if applicable (e.g., "Add your first course")

Never: Show blank screen with no explanation.

#### Rule 3: Errors Should Be Recoverable
**User-facing errors should offer:**
- Explanation of what went wrong (simple terms)
- Action to fix (e.g., "Check network", "Grant permission", "Retry")

Never: Dead-end error with no next step.

---

## Action Items

### CRITICAL (Must Do Before Ship)
1. Audit all empty state scenarios (1 day)
2. Audit all error state scenarios (1 day)
3. Fix any crashes or blank screens found
4. Document expected behavior for each

### HIGH (Should Do Before Ship)
5. Add empty state UI where missing (4-6 hours)
6. Add user-friendly error messages (4-6 hours)
7. Test error paths manually

### MEDIUM (Can Defer)
8. Add retry logic for network failures
9. Add error state unit tests

---

## Verification Checklist

**For Each Screen:**
- [ ] Empty state designed and implemented
- [ ] Error state designed and implemented
- [ ] No crashes on error
- [ ] User has clear next action

**For Each Network Feature:**
- [ ] Timeout handled gracefully
- [ ] API error shows user message
- [ ] Offline mode or fallback exists

---

## Sign-Off

**Error State Audit Complete When:**
- [ ] All screens have empty states
- [ ] All error paths show user-friendly messages
- [ ] Zero crashes in error scenarios
- [ ] Manual testing complete

**Auditor:** [NAME]  
**Date:** [DATE]
