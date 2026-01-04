# iCloud Sync Configuration

## Overview
The Itori app now supports full iCloud sync across macOS, iOS, and iPadOS devices.

## What Gets Synced
- **Assignments/Tasks**: All assignments are synced via iCloud Documents
- **Settings**: App settings use NSUbiquitousKeyValueStore (future enhancement)

## Configuration

### Entitlements
Both iOS and macOS have been configured with:
- **iCloud Container**: `iCloud.com.cwlewisiii.Itori`
- **CloudKit** service enabled
- **CloudDocuments** service enabled for file-based sync
- **Ubiquity Key-Value Store** for settings sync
- **Ubiquity Containers** for document storage

### Files Updated
1. `Config/Itori-iOS.entitlements` - iOS/iPadOS entitlements
2. `Config/Itori.entitlements` - macOS entitlements
3. `SharedCore/State/AssignmentsStore.swift` - Explicit container identifier

## How It Works

### Automatic Sync
- Changes are automatically saved to local cache first (instant)
- If iCloud sync is enabled and online, changes are synced to iCloud
- Other devices poll for changes every 30 seconds
- Changes are merged intelligently to avoid data loss

### Conflict Resolution
- If significant conflicts are detected (>5 tasks or >20% different), both versions are saved
- User is notified via `AssignmentsSyncConflict` notification
- Conflict files are saved in: `~/Library/Application Support/ItoriAssignments/Conflicts/`

### Toggle Sync
Users can enable/disable iCloud sync in Settings:
- Settings → Storage → iCloud Sync toggle
- Controlled by `AppSettingsModel.shared.enableICloudSync`

## Testing iCloud Sync

### Prerequisites
1. Sign in to iCloud on both devices with the same Apple ID
2. Ensure iCloud Drive is enabled in System Settings/Settings
3. Enable iCloud sync in Itori app settings

### Test Steps
1. **Device A**: Create an assignment
2. **Device B**: Wait up to 30 seconds, assignment should appear
3. **Device B**: Modify the assignment
4. **Device A**: Wait up to 30 seconds, changes should sync

### Debugging
If sync isn't working:
1. Check iCloud Drive is enabled in system settings
2. Check network connectivity
3. Check that "iCloud Sync" is enabled in Itori settings
4. Check Console.app for sync messages (search for "iCloud")

## Network Resilience
- App uses `NWPathMonitor` to detect online/offline status
- Changes made offline are queued and synced when back online
- Local cache ensures data is never lost

## Container Identifier
The app uses the explicit container identifier:
```
iCloud.com.cwlewisiii.Itori
```

This ensures consistent access across all platforms.

## Future Enhancements
- [ ] Real-time sync using NSMetadataQuery for instant updates
- [ ] Settings sync via NSUbiquitousKeyValueStore
- [ ] Course data sync
- [ ] Conflict resolution UI
- [ ] Sync status indicator in UI

## Developer Notes

### Xcode Setup
When running on a new development machine:
1. Configure automatic signing with your Team ID
2. Xcode will automatically provision the iCloud container
3. May need to wait a few minutes for iCloud container to activate

### Simulator Testing
- iCloud sync works in Simulator if signed into iCloud
- Go to Settings app in Simulator and sign in with Apple ID
- iCloud Drive must be enabled

### Production
- Ensure App ID has iCloud capability enabled in Apple Developer portal
- Container identifier must match across all configurations
- Users must be signed into iCloud for sync to work
