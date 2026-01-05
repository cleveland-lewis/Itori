# Backlog (Post-v1.0)

Features and improvements deferred from v1.0.

---

## v1.1 Candidates

### Multi-Semester Selection
- UI for selecting multiple active semesters
- Dashboard shows aggregated stats across semesters
- Course picker filters to active semesters
- Migration from single currentSemesterId

### Task Alarm Scheduling
- Notification-based task reminders
- TaskAlarmScheduler implementation
- UI for setting alarm times
- Permission flow for notifications

---

## v1.2+ Candidates

### Advanced iCloud Sync
- Conflict resolution UI (user chooses version)
- Field-level merge strategies
- Manual sync button
- Sync status indicator

### Export/Import
- Export data as JSON
- Import from other apps
- Backup/restore functionality

### Siri Shortcuts
- Add assignment via Siri
- Start timer via Siri
- Query upcoming tasks

### Widget Extensions
- Assignment widget
- Study hours widget
- Calendar widget

---

## Technical Debt

(Items to address when time permits)

### Migrate Legacy GCD
- Replace DispatchQueue.main with async/await
- Use @MainActor instead of manual main thread hops

### Consolidate State Management
- Clarify AppModel vs AppSettingsModel vs AppPreferences
- Reduce singleton count

### Snapshot Testing
- Add comprehensive UI snapshot tests
- Automate layout regression detection

---

**Note:** This file tracks deferred work, not bugs. File bugs as GitHub issues.

### Keyboard Shortcuts (macOS)
- Wire ⌘T to show new assignment sheet
- Wire ⌘⇧N to show new course sheet
- Wire ⌘⇧D to show new deck sheet
- Wire ⌘F to focus search field

### UI Polish
- Course outline deletion confirmation alerts
- Batch review sheet (restore after FileParsingService stabilization)

