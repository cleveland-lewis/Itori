# 🚀 Complete Setup Guide - 3 Simple Steps

## Overview

Follow these 3 steps to complete the Intelligent Scheduling integration. Total time: ~8 minutes.

---

## Step 1: Add to Info.plist (2 minutes) 📝

### Option A: Using Source Code (Recommended)

1. **Open Xcode project:**
   - Open `ItoriApp.xcodeproj`

2. **Find Info.plist:**
   - In Project Navigator (left sidebar)
   - Look for `Info.plist` under your iOS target

3. **Open as Source Code:**
   - Right-click `Info.plist`
   - Select: **Open As → Source Code**

4. **Find the closing tag:**
   - Scroll to bottom of file
   - Find this line: `</dict>`

5. **Paste this BEFORE `</dict>`:**

```xml
<!-- Intelligent Scheduling Background Execution -->
<key>UIBackgroundModes</key>
<array>
<string>fetch</string>
<string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
<string>com.clevelandlewis.Itori.intelligentScheduling</string>
</array>
```

6. **Save:** Cmd+S

### Option B: Using Property List Editor

1. Open `Info.plist` normally (double-click)
2. Click **+** button at root level
3. Add key: `UIBackgroundModes`, Type: Array
4. Expand array, add two String items:
   - Item 0: `fetch`
   - Item 1: `processing`
5. Click **+** again at root level
6. Add key: `BGTaskSchedulerPermittedIdentifiers`, Type: Array
7. Expand array, add String item:
   - Item 0: `com.clevelandlewis.Itori.intelligentScheduling`
8. Save

✅ **Verify:** You should see both keys in Info.plist

---

## Step 2: Enable Background Modes Capability (1 minute) ⚙️

1. **Select project:**
   - Click on project name at top of Project Navigator

2. **Select target:**
   - In main editor area, select **Itori iOS** target

3. **Go to Capabilities tab:**
   - Click **Signing & Capabilities** at the top

4. **Add capability:**
   - Click **+ Capability** button (top left)
   - Search for: `Background Modes`
   - Double-click to add

5. **Check boxes:**
   - ☑️ **Background fetch**
   - ☑️ **Background processing**

6. **Verify:**
   - You should see "Background Modes" section with 2 checkboxes checked

✅ **Done!** Background modes enabled.

---

## Step 3: Add Swift Files to Xcode (5 minutes) 📁

### Files to Add

You need to add these 4 files to your Xcode project:

**Location on disk:**
```
/Users/clevelandlewis/Desktop/Itori/

SharedCore/Services/FeatureServices/
  ├── GradeMonitoringService.swift
  ├── EnhancedAutoRescheduleService.swift
  └── IntelligentSchedulingCoordinator.swift

Platforms/iOS/Scenes/Settings/Categories/
  └── IOSIntelligentSchedulingSettingsView.swift
```

### Method 1: Drag & Drop (Easiest) 🎯

#### For Services (3 files):

1. **Open Finder:**
   - Navigate to: `/Users/clevelandlewis/Desktop/Itori/SharedCore/Services/FeatureServices/`

2. **Select files:**
   - Hold Cmd and click these 3 files:
     - `GradeMonitoringService.swift`
     - `EnhancedAutoRescheduleService.swift`
     - `IntelligentSchedulingCoordinator.swift`

3. **Drag to Xcode:**
   - In Xcode Project Navigator, find: `SharedCore/Services/FeatureServices/`
   - If folder doesn't exist: Right-click `SharedCore` → New Group → name it `Services/FeatureServices`
   - Drag the 3 files from Finder into this folder in Xcode

4. **Configure dialog:**
   When dialog appears:
   - ☐ **UNCHECK** "Copy items if needed"
   - ☑ **CHECK** "Create groups"
   - ☑ **CHECK** Target: **SharedCore** (or main target)
   - Click **Add**

#### For Settings View (1 file):

1. **Open Finder:**
   - Navigate to: `/Users/clevelandlewis/Desktop/Itori/Platforms/iOS/Scenes/Settings/Categories/`

2. **Select file:**
   - `IOSIntelligentSchedulingSettingsView.swift`

3. **Drag to Xcode:**
   - In Xcode Project Navigator, find: `Platforms/iOS/Scenes/Settings/Categories/`
   - Drag the file from Finder into this folder in Xcode

4. **Configure dialog:**
   - ☐ **UNCHECK** "Copy items if needed"
   - ☑ **CHECK** "Create groups"
   - ☑ **CHECK** Target: **iOS** (or main target)
   - Click **Add**

### Method 2: Add Files Menu (Alternative)

1. **In Xcode:**
   - Right-click appropriate folder
   - Select **Add Files to "ItoriApp"...**

2. **Navigate to file location**

3. **Select files**

4. **Configure options:**
   - Uncheck "Copy items if needed"
   - Check "Create groups"
   - Select correct target
   - Click **Add**

### Verify Files Added ✅

In Xcode Project Navigator, you should see:

```
SharedCore
└── Services
    └── FeatureServices
        ├── GradeMonitoringService.swift ✓
        ├── EnhancedAutoRescheduleService.swift ✓
        └── IntelligentSchedulingCoordinator.swift ✓

Platforms
└── iOS
    └── Scenes
        └── Settings
            └── Categories
                └── IOSIntelligentSchedulingSettingsView.swift ✓
```

---

## Step 4: Build & Test 🔨

### Build

1. **Clean Build Folder:**
   - Menu: Product → Clean Build Folder
   - Or: Cmd+Shift+K

2. **Build:**
   - Menu: Product → Build
   - Or: Cmd+B

3. **Check for errors:**
   - If build succeeds: ✅ Ready!
   - If errors: Check target membership for files

### Run

1. **Select simulator/device**

2. **Run:**
   - Menu: Product → Run
   - Or: Cmd+R

3. **App should launch successfully**

### Test Features

#### Test 1: Settings Available
1. Launch app
2. Go to **Settings**
3. Scroll down
4. You should see: **🧠 Intelligent Scheduling**
5. Tap it
6. Should see status "Always Active" ✅

#### Test 2: Grade Monitoring
1. Go to Grades
2. Add 3 grades for a course:
   - 90%
   - 85%
   - 77%
3. Go to Settings → Intelligent Scheduling
4. Should see recommendation under "Active Recommendations" ✅

#### Test 3: Auto-Reschedule (Simulator)
1. Create assignment with due date = yesterday
2. Mark status as NOT completed
3. Go to Settings → Intelligent Scheduling
4. Tap "Check Now" button
5. Assignment should be rescheduled ✅
6. Should see notification

#### Test 4: Background Execution (Simulator)
1. Run app
2. Create overdue assignment
3. Background app: Cmd+Shift+H
4. In Terminal, run:
```bash
xcrun simctl spawn booted launchctl debug system/com.clevelandlewis.Itori \
  --background-task-identifier com.clevelandlewis.Itori.intelligentScheduling
```
5. Check Xcode console for: "Running intelligent scheduling background task" ✅

---

## Troubleshooting 🔧

### Build Errors

**Error: "Cannot find type 'IntelligentSchedulingCoordinator'"**
- Solution: Check file was added to correct target
- Right-click file → Show File Inspector → Check target membership

**Error: "Duplicate symbol"**
- Solution: File added twice - remove duplicate

**Error: Import errors**
- Solution: Clean build folder (Cmd+Shift+K) and rebuild

### Settings Not Showing

**"Intelligent Scheduling" not in Settings list**
- Check: `SettingsCategory.swift` was modified correctly
- Rebuild project

**Settings view crashes**
- Check: `IOSIntelligentSchedulingSettingsView.swift` was added to iOS target
- Check console for specific error

### Background Task Not Running

**"Failed to schedule background task"**
- Check: Info.plist has both keys
- Check: Background Modes capability enabled
- Check: Correct identifier in Info.plist

**No background execution**
- Check: Settings → General → Background App Refresh → ON
- Check: Device (not simulator) for real-world test
- Wait 15+ minutes for system to schedule

---

## Quick Verification Checklist ✓

After completing all steps:

- [ ] Info.plist has `UIBackgroundModes` key
- [ ] Info.plist has `BGTaskSchedulerPermittedIdentifiers` key
- [ ] Background Modes capability enabled in Xcode
- [ ] Background fetch checkbox checked
- [ ] Background processing checkbox checked
- [ ] All 4 Swift files added to Xcode project
- [ ] Files show in Project Navigator
- [ ] Project builds successfully (Cmd+B)
- [ ] App runs without crashing (Cmd+R)
- [ ] "Intelligent Scheduling" appears in Settings
- [ ] Status shows "Always Active"
- [ ] Can configure threshold and work hours
- [ ] "Check Now" button works
- [ ] Console shows "Scheduled intelligent scheduling background task"

---

## Success! 🎉

If all checks pass, your Intelligent Scheduling System is:

✅ **Fully integrated**
✅ **Always active**
✅ **Running in background**
✅ **Ready to use**

Users will now get:
- 24/7 grade monitoring
- Automatic task rescheduling
- Background notifications
- Continuous intelligent scheduling

---

## Files Reference

**Created Files (already exist):**
- `SharedCore/Services/FeatureServices/GradeMonitoringService.swift`
- `SharedCore/Services/FeatureServices/EnhancedAutoRescheduleService.swift`
- `SharedCore/Services/FeatureServices/IntelligentSchedulingCoordinator.swift`
- `Platforms/iOS/Scenes/Settings/Categories/IOSIntelligentSchedulingSettingsView.swift`

**Modified Files (already saved):**
- `Platforms/iOS/App/RootsIOSApp.swift`
- `Platforms/iOS/Scenes/Settings/SettingsCategory.swift`

**Documentation:**
- `Docs/BACKGROUND_EXECUTION_SETUP.md`
- `Docs/INFO_PLIST_QUICK_REF.md`
- `Docs/INTELLIGENT_SCHEDULING_SYSTEM.md`

---

## Need Help?

**Console Logs:**
Filter for: `"intelligentScheduling"` or `"Background"` or `"GradeMonitoring"`

**Common Issues:**
- Build errors → Check target membership
- Missing in Settings → Rebuild project
- Background not working → Check Info.plist + Capabilities

**Still stuck?**
Review: `BACKGROUND_EXECUTION_SETUP.md` for detailed troubleshooting

---

**You're all set!** 🚀
