# Backlog (Post-v1.0)

Features and improvements deferred from v1.0.

---

## v1.1 Candidates

### Practice Test Enhancements
- Better distractor quality using common misconceptions
- Question templates mapped to Bloom's taxonomy (20-30 templates)
- Show research sources (Wikipedia URLs) in explanations
- Comprehensive test suite for generation pipeline
- Better error handling and retry logic

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

## v1.2 Candidates

### Practice Test - Personalization
- Assignment-aware question generation
- Reference specific assignment titles in questions
- Scenario-based questions (3-4 sentence contexts)
- Question caching (7-day TTL)
- Performance optimization

### Practice Test - Adaptive Learning
- Adaptive difficulty system (tracks performance)
- Student analytics dashboard
- Mastery visualization by topic
- Weak area targeting
- Study recommendations

---

## v1.3+ Candidates

### Practice Test - Advanced Features
- Spaced repetition integration (SM-2 algorithm)
- AI tutor explanations for wrong answers
- Difficulty calibration from real student data
- Multi-language support (Spanish, French, German)
- Collaborative question bank with ratings
- Visual questions (diagrams, charts)
- Voice-based practice tests
- LMS integration (Canvas, Blackboard)

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

