# Reset All Data (Production)

## Scope
This document describes what "Reset All Data" wipes and how the global reset hook behaves across macOS + iOS/iPadOS.

## Single Entry Point
- All reset actions route through `AppModel.shared.requestReset()`.
- `ResetCoordinator` subscribes to `AppModel.resetPublisher` and performs the reset sequence.

## Reset Sequence (High Level)
1. Disable iCloud sync + suppress iCloud restore until the user re-enables sync.
2. Reset planner sync coordinator internal hashes.
3. Clear domain stores and delete their persisted files.
4. Reset Core Data persistent store (remove store + recreate).
5. Reset app settings to defaults (while keeping iCloud suppression + disabled sync).

## What Gets Wiped
- Assignments + conflict files + iCloud files
- Assignment plans (cache + persisted store)
- Planner schedule + iCloud planner file
- Courses + semesters + course files metadata
- Grades
- Study hours totals
- Scheduler preferences
- Syllabus parsing jobs + parsed assignments
- Practice tests + scheduled tests + attempts
- Storage aggregate analytics
- Core Data persistent store (SQLite + WAL/SHM)
- App settings reset to defaults (permissions are OS-managed)

## iCloud Behavior After Reset
- `suppressICloudRestore` is set to true to prevent auto-reimport.
- iCloud sync toggle is forced off.
- Suppression clears only when the user explicitly re-enables iCloud sync.

## Idempotency
- Reset operations are safe to run multiple times.
- Clearing already-empty stores is a no-op.

## Notes / Gaps
- CloudKit server-side records are not explicitly deleted (server-side wipe is outside app scope).
- UI smoke coverage is manual; see test checklist for manual steps.
