# Timer Live Activity Widget - Setup Instructions

## Files Created ✅

The following files have been created for the Widget Extension:

### Widget Code
- ✅ `RootsTimerWidget/TimerLiveActivity.swift` - Live Activity UI (lock screen + Dynamic Island)
- ✅ `RootsTimerWidget/RootsTimerWidgetBundle.swift` - Widget bundle entry point
- ✅ `RootsTimerWidget/Info.plist` - Widget configuration
- ✅ `RootsTimerWidget/Assets.xcassets/` - Widget assets

### Shared Code
- ✅ `Shared/TimerLiveActivityAttributes.swift` - Shared data model

## Xcode Setup Required

### Step 1: Create Widget Extension Target

1. Open `RootsApp.xcodeproj` in Xcode
2. Select the project in the navigator
3. Click the "+" button at the bottom of the targets list
4. Search for "Widget Extension"
5. Click "Next"

**Configuration:**
- **Product Name**: `RootsTimerWidget`
- **Bundle Identifier**: `clewisiii.Roots.RootsTimerWidget`
- **Include Configuration Intent**: ❌ (uncheck)
- **Include Live Activity**: ✅ (check if available)
- Click "Finish"

**Important**: When prompted, click "Cancel" on the "Activate RootsTimerWidget scheme?" dialog. We'll configure manually.

### Step 2: Delete Default Files

Xcode creates default files. Delete these (Move to Trash):
- `RootsTimerWidget.swift` (if created)
- `RootsTimerWidgetLiveActivity.swift` (if created)
- Any other auto-generated files

### Step 3: Add Our Files to Target

For each file created above:

**RootsTimerWidget Target Members:**
1. Select the file in Xcode
2. Open File Inspector (⌘⌥1)
3. Under "Target Membership", check:
   - ✅ `RootsTimerWidget`

**Shared File (`Shared/TimerLiveActivityAttributes.swift`):**
1. Select this file
2. Check BOTH targets:
   - ✅ `Roots` (iOS app)
   - ✅ `RootsTimerWidget`

### Step 4: Configure Build Settings

Select `RootsTimerWidget` target → Build Settings:

**Deployment**:
- iOS Deployment Target: `16.1` (minimum for Live Activities)

**Signing & Capabilities**:
- Team: Select your development team
- Bundle Identifier: `clewisiii.Roots.RootsTimerWidget`
- Signing Certificate: Automatic

### Step 5: Add Capability to Main App

Select `Roots` target → Signing & Capabilities:
1. Click "+ Capability"
2. Add "Push Notifications" (if not already present)

### Step 6: Update Main App Info.plist

The main iOS app needs Live Activity support enabled.

**File**: `iOS/Resources/Info.plist` (or the main Info.plist)

Add these keys:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

**In Xcode**:
1. Select the file
2. Right-click → Open As → Property List
3. Add the keys above

### Step 7: Update TimerLiveActivityManager

**File**: `iOS/PlatformAdapters/TimerLiveActivityManager.swift`

Remove the inline `TimerLiveActivityAttributes` struct (lines 13-25) since it's now in the shared file.

Add import at top:
```swift
// Remove the struct definition (lines 13-25)
// It's now imported from Shared/TimerLiveActivityAttributes.swift
```

### Step 8: Build and Run

1. **Select Scheme**: "Roots" (not the widget scheme)
2. **Device**: Physical iPhone (iOS 16.1+)
   - ⚠️ Live Activities don't work in Simulator
3. **Build**: ⌘B
4. **Run**: ⌘R

## Testing

### Start Live Activity:
1. Open the app
2. Go to Timer tab
3. Start any timer (Timer, Stopwatch, or Pomodoro)
4. **Lock your device** → Live Activity appears on lock screen

### Dynamic Island (iPhone 14 Pro+):
1. Start timer
2. Go to home screen
3. Look at Dynamic Island → shows compact timer
4. Long-press Dynamic Island → expanded view

### Expected Behavior:
- ✅ Lock screen shows timer progress bar
- ✅ Updates every second
- ✅ Shows remaining time
- ✅ Different color for break time (orange)
- ✅ Dynamic Island compact view (iPhone 14 Pro+)
- ✅ Auto-dismisses when timer ends

## Troubleshooting

### Build Errors

**"Cannot find 'TimerLiveActivityAttributes' in scope"**
- Solution: Ensure `Shared/TimerLiveActivityAttributes.swift` is added to both targets

**"No such module 'ActivityKit'"**
- Solution: Check iOS Deployment Target is 16.1+ for widget target

**Signing errors**
- Solution: Select your development team in Signing & Capabilities

### Runtime Issues

**Live Activity doesn't appear**
1. Confirm you're on a physical device (not simulator)
2. Check iOS version is 16.1+
3. Go to Settings → [Your Name] → Notifications → Live Activities → ON
4. Check app permissions: Settings → Roots → Notifications → Allow

**Updates are slow**
- Live Activities update every 1-2 seconds (by design)
- For immediate updates, use push notifications (requires backend)

### Debug Tips

**Check if Live Activities are enabled:**
```swift
// Already in IOSTimerLiveActivityManager
var isAvailable: Bool {
    if #available(iOS 16.1, *) {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    return false
}
```

**Check Xcode Console:**
- Look for ActivityKit logs
- Check for permission errors

## Features

### Lock Screen View
- Shows timer mode (Timer/Stopwatch/Pomodoro)
- Progress bar with percentage
- Elapsed and remaining time
- Pause indicator
- Work/Break label (Pomodoro)

### Dynamic Island (iPhone 14 Pro+)

**Minimal** (pill shape):
- Timer icon

**Compact** (small expansion):
- Leading: Timer icon
- Trailing: Remaining time (e.g., "5m")

**Expanded** (long-press):
- Mode and label
- Large remaining time
- Progress bar with percentage
- Status text

## Files Reference

```
Roots/
├── Shared/
│   └── TimerLiveActivityAttributes.swift    [App + Widget]
├── iOS/
│   └── PlatformAdapters/
│       └── TimerLiveActivityManager.swift   [App only]
└── RootsTimerWidget/
    ├── RootsTimerWidgetBundle.swift         [Widget only]
    ├── TimerLiveActivity.swift              [Widget only]
    ├── Info.plist                           [Widget only]
    └── Assets.xcassets/                     [Widget only]
```

## Next Steps

After successful setup:
1. ✅ Test on physical device
2. ✅ Verify lock screen display
3. ✅ Test Dynamic Island (if available)
4. ✅ Test all timer modes (Timer, Stopwatch, Pomodoro)
5. ✅ Test pause/resume
6. ✅ Verify auto-dismiss when timer ends

## Advanced Configuration

### Custom Colors
Edit `TimerLiveActivity.swift`:
- Line 20: `.activityBackgroundTint()` - Lock screen background
- Lines 48, 74, 78: `.tint()` - Progress bar color

### Update Frequency
Edit `IOSTimerLiveActivityManager.swift`:
- Line 30: `minUpdateInterval` - Currently 1.0 second

### Custom Icons
Add to widget's Assets.xcassets and reference in `iconName(for:)` method

---

**Status**: Ready for Xcode integration
**Required iOS**: 16.1+
**Required Device**: Physical iPhone/iPad (no simulator support)
**Estimated Setup Time**: 10-15 minutes

Good luck! 🎉
