# App Rename: Itori → Itori

## Summary
Successfully renamed the entire app from "Itori" to "Itori" on January 3, 2026.

## Changes Made

### 1. Bundle Identifiers & Display Names
- **Main App**: `clewisiii.Itori` → `clewisiii.Itori`
- **Watch App**: `clewisiii.Itori.watchkitapp` → `clewisiii.Itori.watchkitapp`
- **Tests**: `clewisiii.ItoriTests` → `clewisiii.ItoriTests`
- **UI Tests**: `clewisiii.ItoriUITests` → `clewisiii.ItoriUITests`
- **Display Name**: Changed from "Itori" to "Itori" in all Info.plist files

### 2. iCloud & CloudKit
- **CloudKit Container**: `iCloud.com.cwlewisiii.Itori` → `iCloud.com.cwlewisiii.Itori`
- Updated in:
  - `PersistenceController.swift`
  - `Config/Itori.entitlements`
  - `Config/Itori-iOS.entitlements`

### 3. Core Data Model
- Renamed: `Itori.xcdatamodeld` → `Itori.xcdatamodeld`
- Renamed: `Itori.xcdatamodel` → `Itori.xcdatamodel`
- Updated `.xccurrentversion` to reference new model name
- Updated `PersistenceController` to load "Itori" container

### 4. Xcode Schemes
- `Itori.xcscheme` → `Itori.xcscheme`
- `ItoriTests.xcscheme` → `ItoriTests.xcscheme`
- `ItoriUITests.xcscheme` → `ItoriUITests.xcscheme`
- `ItoriWatch.xcscheme` → `ItoriWatch.xcscheme`

### 5. User-Facing Strings
- iOS navigation title: "Itori" → "Itori"
- macOS sidebar title: "Itori" → "Itori"

### 6. Watch App Configuration
- Updated `WKCompanionAppBundleIdentifier` in Watch Info.plist
- Updated display name in Watch Info.plist

## Files Modified

### Xcode Project
- `ItoriApp.xcodeproj/project.pbxproj` - Bundle identifiers and display names

### Info.plist Files
- `Platforms/watchOS/App/Info.plist`

### Entitlements
- `Config/Itori.entitlements`
- `Config/Itori-iOS.entitlements`

### Swift Code
- `SharedCore/Persistence/PersistenceController.swift`
- `Platforms/iOS/Root/IOSRootView.swift`
- `Platforms/macOS/PlatformAdapters/ItoriSidebarShell.swift`

### Core Data
- `SharedCore/Persistence/Itori.xcdatamodeld/` (renamed)
- `SharedCore/Persistence/Itori.xcdatamodeld/Itori.xcdatamodel/` (renamed)

### Schemes
- All scheme files in `ItoriApp.xcodeproj/xcshareddata/xcschemes/`

## Next Steps

⚠️ **IMPORTANT**: The Xcode project file itself (`ItoriApp.xcodeproj`) has NOT been renamed yet. This should be done carefully:

1. Close Xcode completely
2. Rename `ItoriApp.xcodeproj` → `ItoriApp.xcodeproj`
3. Update any workspace files if they exist
4. Reopen the project in Xcode
5. Verify all schemes and targets load correctly

## Testing Checklist

After renaming the .xcodeproj file:
- [ ] Project opens successfully in Xcode
- [ ] All targets build successfully (iOS, macOS, watchOS)
- [ ] App displays "Itori" in the title bar and navigation
- [ ] iCloud sync still works (uses new container)
- [ ] Core Data loads successfully with renamed model
- [ ] Watch companion app connects properly
- [ ] All tests run successfully

## Notes

- The project directory name is still `/Itori` - this can be renamed separately if desired
- Any CI/CD scripts or documentation referencing "Itori" will need manual updates
- App Store Connect will need a new app record for "Itori" with the new bundle identifier
