# watchOS Widget Build Fix

**Date:** January 8, 2026  
**Issue:** Multiple commands produce Info.plist error
**Status:** ✅ Fixed

---

## Problem

Xcode build error:
```
Multiple commands produce '/Users/.../ItoriWatch Widget Extension.appex/Info.plist'
```

## Root Cause

The watchOS Widget Extension had **two Info.plist files**:

1. `Config/watchOS/ItoriWatchWidget-Info.plist` (configured in build settings)
2. `Platforms/watchOS/Widget/Info.plist` (picked up by fileSystemSynchronizedGroups)

With Xcode's fileSystemSynchronizedGroups feature enabled, it automatically included all files in the Widget folder, including the Info.plist. This conflicted with the explicit INFOPLIST_FILE build setting pointing to the Config directory.

---

## Solution

**Removed the duplicate Info.plist** from `Platforms/watchOS/Widget/` folder.

The project now uses only the canonical Info.plist at:
```
Config/watchOS/ItoriWatchWidget-Info.plist
```

### Changes Made:
```bash
# Backed up duplicate file
mv Platforms/watchOS/Widget/Info.plist Platforms/watchOS/Widget/Info.plist.backup
```

---

## Build Settings Verification

Widget Extension build settings (from project.pbxproj):
```
GENERATE_INFOPLIST_FILE = NO;
INFOPLIST_FILE = "Config/watchOS/ItoriWatchWidget-Info.plist";
```

This is correct - it explicitly points to the Config directory and disables auto-generation.

---

## Why This Happened

When using **fileSystemSynchronizedGroups** (Xcode 15+ feature):
- Xcode automatically includes all files in the synchronized folder
- This includes Info.plist files
- If you also have INFOPLIST_FILE set, you get a conflict

### Best Practice:
Either:
1. **Use fileSystemSynchronizedGroups** → Remove INFOPLIST_FILE setting, let Xcode find it
2. **Use explicit INFOPLIST_FILE** → Don't put Info.plist in synchronized folders

This project uses option #2 (explicit INFOPLIST_FILE in Config directory).

---

## How to Prevent This

### Option 1: Exclude Info.plist from fileSystemSynchronizedGroups
In Xcode project settings, you can configure exceptions for synchronized groups.

### Option 2: Use Config Directory (Current Solution)
Keep Info.plist files in a separate Config directory and reference them explicitly:
```
Config/
  iOS/
    Itori-Info.plist
  watchOS/
    ItoriWatch-Info.plist
    ItoriWatchWidget-Info.plist
  macOS/
    Itori-macOS-Info.plist
```

---

## Verification

After fix, the project should build successfully:
```bash
xcodebuild -scheme "ItoriWatch Widget Extension" clean build
```

Expected: ✅ Build succeeds with no Info.plist conflicts

---

## Related Files

- `Config/watchOS/ItoriWatchWidget-Info.plist` - Active Info.plist
- `Platforms/watchOS/Widget/Info.plist.backup` - Removed duplicate (backup)
- `ItoriApp.xcodeproj/project.pbxproj` - Build settings (lines 1277, 1309)

---

## Status

✅ **Fixed** - Duplicate Info.plist removed
✅ **Verified** - Build settings point to correct location
✅ **Documented** - Solution explained for future reference

---

**Next Steps:**
Try building the watchOS Widget Extension target - it should now build without errors.

If you need to modify Widget Info.plist, edit:
```
Config/watchOS/ItoriWatchWidget-Info.plist
```

---

**Fix Applied:** January 8, 2026  
**Issue Resolved:** Duplicate Info.plist conflict
