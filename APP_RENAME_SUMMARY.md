# App Rename: Roots → Itori

## Summary
Successfully renamed the entire app from "Roots" to "Itori" on January 3, 2026.

## Changes Made

### 1. Bundle Identifiers & Display Names
- **Main App**: `clewisiii.Roots` → `clewisiii.Itori`
- **Watch App**: `clewisiii.Roots.watchkitapp` → `clewisiii.Itori.watchkitapp`
- **Tests**: `clewisiii.RootsTests` → `clewisiii.ItoriTests`
- **UI Tests**: `clewisiii.RootsUITests` → `clewisiii.ItoriUITests`
- **Display Name**: Changed from "Roots" to "Itori" in all Info.plist files

### 2. iCloud & CloudKit
- **CloudKit Container**: `iCloud.com.cwlewisiii.Roots` → `iCloud.com.cwlewisiii.Itori`
- Updated in:
  - `PersistenceController.swift`
  - `Config/Roots.entitlements`
  - `Config/Roots-iOS.entitlements`

### 3. Core Data Model
- Renamed: `Roots.xcdatamodeld` → `Itori.xcdatamodeld`
- Renamed: `Roots.xcdatamodel` → `Itori.xcdatamodel`
- Updated `.xccurrentversion` to reference new model name
- Updated `PersistenceController` to load "Itori" container

### 4. Xcode Schemes
- `Roots.xcscheme` → `Itori.xcscheme`
- `RootsTests.xcscheme` → `ItoriTests.xcscheme`
- `RootsUITests.xcscheme` → `ItoriUITests.xcscheme`
- `RootsWatch.xcscheme` → `ItoriWatch.xcscheme`

### 5. User-Facing Strings
- iOS navigation title: "Roots" → "Itori"
- macOS sidebar title: "Roots" → "Itori"

### 6. Watch App Configuration
- Updated `WKCompanionAppBundleIdentifier` in Watch Info.plist
- Updated display name in Watch Info.plist

## Files Modified

### Xcode Project
- `RootsApp.xcodeproj/project.pbxproj` - Bundle identifiers and display names

### Info.plist Files
- `Platforms/watchOS/App/Info.plist`

### Entitlements
- `Config/Roots.entitlements`
- `Config/Roots-iOS.entitlements`

### Swift Code
- `SharedCore/Persistence/PersistenceController.swift`
- `Platforms/iOS/Root/IOSRootView.swift`
- `Platforms/macOS/PlatformAdapters/RootsSidebarShell.swift`

### Core Data
- `SharedCore/Persistence/Itori.xcdatamodeld/` (renamed)
- `SharedCore/Persistence/Itori.xcdatamodeld/Itori.xcdatamodel/` (renamed)

### Schemes
- All scheme files in `RootsApp.xcodeproj/xcshareddata/xcschemes/`

## Next Steps

⚠️ **IMPORTANT**: The Xcode project file itself (`RootsApp.xcodeproj`) has NOT been renamed yet. This should be done carefully:

1. Close Xcode completely
2. Rename `RootsApp.xcodeproj` → `ItoriApp.xcodeproj`
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

- The project directory name is still `/Roots` - this can be renamed separately if desired
- Any CI/CD scripts or documentation referencing "Roots" will need manual updates
- App Store Connect will need a new app record for "Itori" with the new bundle identifier
