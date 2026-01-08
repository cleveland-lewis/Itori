# iOS Local Persistence - Summary

## Current State

**Architecture:** Hybrid persistence with CoreData + JSON stores

**Storage Technology:**
- ✅ **CoreData** (NSPersistentCloudKitContainer) - schema defined but underutilized
- ✅ **JSON Files** - primary storage used by all stores
- ✅ **iCloud CloudKit** - optional cross-device sync

**Entities with CoreData Support:**
- ✅ Semester
- ✅ Course  
- ✅ Assignment (partial)
- ✅ CourseOutlineNode
- ✅ CourseFile
- ✅ FileParseResult
- ✅ PlannerAnalysis

**Entities Missing from CoreData:**
- ❌ Event
- ❌ Grade
- ❌ Activity (TimerActivity)
- ❌ AppTask (complete definition)

## Problem

iOS and macOS use **different persistence paths:**
- macOS partially uses CoreData repositories
- iOS bypasses CoreData entirely, using only JSON stores
- Results in inconsistent behavior and wasted CoreData schema

## Solution: Dual-Write Pattern (Recommended)

**Keep JSON as primary, add CoreData as secondary for validation**

### Why This Approach?
1. ✅ Zero breaking changes - existing data keeps working
2. ✅ Low risk - can disable CoreData sync if issues occur
3. ✅ Gradual migration path
4. ✅ Easy rollback mechanism

### How It Works
```
User Action → Store Update
              ↓
         ┌─────────┬─────────┐
         ↓         ↓         ↓
    JSON Cache   CoreData  iCloud
    (Primary)   (Secondary) (Optional)
```

## Implementation Steps

### 1. Extend CoreData Schema (2h)
Add missing entities to `Itori.xcdatamodeld`:
- Event, Grade, Activity, Task (AppTask)

### 2. Create Repositories (4h)
Build repository pattern for each entity:
- `TaskRepository.swift`
- `GradeRepository.swift`
- `EventRepository.swift`
- `ActivityRepository.swift`

### 3. Integrate Stores (4h)
Update stores to dual-write:
```swift
@Published var tasks: [AppTask] = [] {
    didSet {
        saveCache()              // Primary (JSON)
        syncToCoreData()         // Secondary (CoreData)
        saveToiCloud()           // Optional (iCloud)
    }
}
```

### 4. Add Safety Features (2h)
- Backup JSON before enabling CoreData
- Validation checks
- Rollback mechanism

### 5. Test & Verify (2-4h)
- CRUD operations for all entities
- Data survives app relaunch
- Works on simulator and device

## Acceptance Criteria

✅ **CRUD works for:**
- Semester
- Course
- Assignment (AppTask)
- Event
- Grade
- Activity

✅ **Data persistence:**
- Survives app termination
- Survives device reboot
- Works in low memory conditions
- Works with/without iCloud

## Timeline

**Total:** 14-16 hours over 2-3 days

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Data loss | Automatic backup before first sync |
| Performance | Background contexts, batch writes |
| Sync conflicts | JSON remains primary during transition |
| User confusion | CoreData sync is opt-in with setting |

## Feature Flag

Add to Settings:
```swift
@Published var enableCoreDataSync: Bool = false
```

Initially off, can be enabled for testing.

## Rollout Strategy

1. **Week 1:** Internal TestFlight with CoreData opt-in
2. **Week 2:** External beta with monitoring
3. **Week 3:** Production release (opt-in)
4. **Month 2:** Enable by default after validation

## Files to Modify

**New Files:**
- `SharedCore/Persistence/Repositories/TaskRepository.swift`
- `SharedCore/Persistence/Repositories/GradeRepository.swift`
- `SharedCore/Persistence/Repositories/EventRepository.swift`
- `SharedCore/Persistence/Repositories/ActivityRepository.swift`
- `SharedCore/Persistence/PersistenceBatchWriter.swift`
- `Tests/Integration/PersistenceIntegrationTests.swift`

**Modified Files:**
- `SharedCore/Persistence/Itori.xcdatamodeld/Itori.xcdatamodel/contents`
- `SharedCore/State/AssignmentsStore.swift`
- `SharedCore/State/GradesStore.swift`
- `SharedCore/State/CoursesStore.swift`
- `SharedCore/State/PlannerStore.swift`
- `SharedCore/Models/AppSettingsModel.swift`
- `SharedCore/Persistence/PersistenceMigrationManager.swift`

## Success Metrics

- App launch time increase < 100ms
- Save latency < 50ms (p95)
- Memory increase < 10MB
- Test coverage > 80%
- Zero data loss incidents
- Zero persistence-related crashes

## Next Actions

1. Review implementation plan
2. Get approval to proceed
3. Create feature branch: `feature/ios-coredata-persistence`
4. Implement phases sequentially
5. Deploy to TestFlight for validation

---

**See:** [LOCAL_PERSISTENCE_IMPLEMENTATION_PLAN.md](./LOCAL_PERSISTENCE_IMPLEMENTATION_PLAN.md) for detailed technical specification.
