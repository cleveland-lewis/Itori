# iCloud Sync Strategy (v1.0)
**Date:** 2026-01-05  
**Status:** DOCUMENTED

This document defines the iCloud sync behavior for v1.0. No ambiguity.

---

## Conflict Resolution Strategy

### v1.0 Policy: Last-Write-Wins

**Rule:** When a conflict is detected, the most recent modification wins.

**Rationale:**
- Simple to implement
- Avoids complex merge UI
- Acceptable for single-user academic app (unlikely to have true conflicts)

**Trade-off:**
- If user edits on two devices simultaneously, one edit may be lost
- This is acceptable for v1.0 (user is rarely editing same data on two devices at once)

---

## Sync Triggers

### When Sync Happens
1. **App Launch:** Bootstrap sync on first appearance
2. **App Backgrounding:** Flush pending changes
3. **Data Mutation:** Automatic save triggers sync
4. **Periodic:** Every N minutes while app is active (if implemented)

### When Sync Does NOT Happen
- App is offline (no network)
- iCloud is disabled in settings
- User is logged out of iCloud

---

## Error Handling

### Scenarios

#### 1. iCloud Disabled
**Behavior:** App functions normally with local-only data.

**User Feedback:**
- Settings screen shows "iCloud Sync: Off"
- Optional banner: "Enable iCloud to sync across devices"

**No Blocker:** User can still use app.

---

#### 2. Network Offline During Sync
**Behavior:** Changes queue locally, sync retries when online.

**User Feedback:**
- No visible error (background retry)
- Optional status indicator: "Sync pending..."

**No Blocker:** User continues working.

---

#### 3. Sync Conflict Detected
**Behavior:** Last-write-wins (most recent timestamp).

**User Feedback:**
- Log conflict to console (dev mode)
- No user-facing error (silent resolution)

**Trade-off Accepted:** Rare edge case, acceptable data loss for v1.0.

---

#### 4. iCloud API Error (Persistent)
**Behavior:** Retry with exponential backoff. If fails after N retries, show banner.

**User Feedback:**
- Banner: "Unable to sync with iCloud. Check your connection."
- Dismiss button
- Retry button

**No Blocker:** User can continue with local data.

---

## Monitoring & Logging

### What Gets Logged
- Conflict detection (timestamp, entity type)
- Sync failures (error code, retry count)
- Merge decisions (which version won)

### Where It's Logged
- `SyncMonitor.swift` handles logging
- Console output (dev mode)
- Optional analytics (anonymized)

---

## Implementation Status

### Existing Components
- ✅ `SyncMonitor.swift` exists in `SharedCore/Persistence/`
- ✅ `PersistenceController.swift` handles CloudKit integration
- ⚠️ Conflict resolution strategy not explicitly coded (verify)

### Required Updates
- [ ] Verify `SyncMonitor` implements last-write-wins
- [ ] Add conflict logging
- [ ] Add error banner to Settings screen
- [ ] Test offline → online sync

---

## Testing Checklist

### Manual Tests
- [ ] Disable iCloud → app works locally
- [ ] Enable iCloud → data syncs to cloud
- [ ] Edit on Device A, check Device B (same user)
- [ ] Go offline, make changes, come online → syncs
- [ ] Force conflict (edit same item on 2 devices) → last-write-wins

### Edge Cases
- [ ] What if iCloud quota is full?
- [ ] What if CloudKit is down?
- [ ] What if user switches iCloud accounts?

---

## Future Improvements (v1.1+)

### Possible Enhancements
- Conflict UI (show user both versions, let them choose)
- Merge strategies (field-level instead of entity-level)
- Offline-first architecture (sync is truly transparent)
- Manual sync button (user-triggered)

**Not in v1.0 scope.**

---

## Sign-Off

**iCloud Sync Strategy Complete When:**
- [ ] Last-write-wins verified in code
- [ ] Conflict logging implemented
- [ ] Error banner added to Settings
- [ ] Manual testing complete

**Owner:** [NAME]  
**Date:** [DATE]
