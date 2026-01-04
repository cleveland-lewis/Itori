# Data and Storage

This page explains how Itori handles user data, including storage locations, synchronization, and backup options.

## Local Storage

All user data is stored locally on the device by default.

### Storage Location
- **macOS:** Application container within `~/Library/Application Support/Itori/`
- **iOS/iPadOS:** Sandboxed application container managed by the system
- **watchOS:** Limited local cache; relies on companion device for full data

### Data Persistence
- Data is written to disk immediately upon changes
- Application state is preserved between launches
- No network connection required for core functionality

### What Is Stored Locally
- Semesters, courses, and course metadata
- Assignments and scheduling data
- Generated sessions and planner state
- User preferences and settings
- Grade information and calculations
- Focus session history
- Practice test data and results

## Cloud Synchronization

Cloud synchronization is optional and requires explicit user enablement.

### Sync Provider
- iCloud (Apple platforms only)
- Synchronization operates via CloudKit

### Sync Behavior
- Changes are uploaded asynchronously in the background
- Devices signed into the same iCloud account receive updates automatically
- Sync requires active internet connection
- First sync may take several minutes depending on data volume

### Conflict Resolution
- Last-write-wins for most data types
- Deletions propagate across all devices
- Conflicts are resolved automatically without user intervention
- No manual merge tools are provided

### Sync Status
- Sync status indicator visible in settings
- Errors are logged and displayed with basic diagnostic information
- Sync can be paused or disabled at any time

### Limitations
- Large data sets (>10,000 assignments) may experience sync delays
- Network interruptions pause sync; it resumes when connectivity is restored
- No selective sync—all data syncs or none

## Backup and Export

### Backup Recommendations
- **macOS:** Include application support folder in Time Machine backups
- **iOS/iPadOS:** Enable iCloud Backup or encrypted iTunes/Finder backups
- Regular backups protect against data loss from device failure or uninstallation

### Export Options

**Data Export** (if implemented):
- Export semesters, courses, and assignments to structured formats (JSON, CSV)
- Export location: User-selected directory
- Export does not include application settings or internal state

**Calendar Export** (if implemented):
- Export scheduled sessions to `.ics` (iCalendar) format
- Imported into external calendar applications for read-only viewing

### Import Options

**Data Import** (if implemented):
- Import from previously exported data files
- Import validates structure before applying changes
- Duplicate detection prevents unintentional data replication

No import from third-party formats (e.g., Google Calendar events, Notion databases) is provided.

## Data Retention

- Data remains indefinitely until explicitly deleted by the user
- Archived semesters and courses are retained for historical reference
- Completed assignments are preserved unless explicitly deleted
- No automatic purging of old data occurs

## Privacy

### Data Collection
- No telemetry or analytics are collected by default
- Crash reports may be sent if user opts into diagnostic reporting (macOS/iOS system setting)
- No user data is transmitted to third-party services

### Third-Party Services
- iCloud sync (if enabled) operates via Apple's CloudKit; subject to Apple's privacy policies
- No advertising SDKs, tracking pixels, or behavioral analytics

### Local-Only Operation
- Application functions fully without internet connectivity
- No account creation or login required
- No server-side processing of user data

## Data Deletion

### Deleting Specific Data
- Deleting a semester removes all associated courses and assignments permanently
- Deleting a course removes all associated assignments permanently
- Deleting an assignment removes it from the schedule and archives
- No "undo" functionality; deletions are immediate and irreversible

### Complete Data Reset
- Available via settings: "Reset All Data"
- Deletes all semesters, courses, assignments, and settings
- Requires confirmation and cannot be undone
- Restores application to first-launch state

### Uninstallation
- Uninstalling the application removes all local data
- If iCloud sync is enabled, data remains in iCloud until manually deleted
- Reinstalling the application with the same iCloud account restores synced data

## Troubleshooting Storage Issues

### "Storage Full" Warnings
- Free disk space by deleting old files or applications
- Export and delete old semesters to reduce database size

### Sync Failures
- Verify iCloud account is signed in (Settings > iCloud)
- Check network connectivity
- Restart application and allow sync to retry
- Disable and re-enable iCloud sync to force re-synchronization

### Data Corruption
- Rare; typically caused by power loss during write operations
- Restore from backup if available
- Contact support if data cannot be recovered

---

**See Also:** [Settings and Configuration](Settings-and-Configuration), [FAQ](FAQ)
