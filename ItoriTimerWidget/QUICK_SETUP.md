# Quick Setup Checklist

## ✅ Files Created
- [x] Widget code files
- [x] Shared attributes
- [x] Info.plist
- [x] Assets

## 📋 Xcode Steps

### 1. Add Widget Target
```
File → New → Target → Widget Extension
Name: RootsTimerWidget
Bundle ID: clewisiii.Roots.RootsTimerWidget
```

### 2. Add Files to Targets
- [ ] `TimerLiveActivity.swift` → RootsTimerWidget ✅
- [ ] `RootsTimerWidgetBundle.swift` → RootsTimerWidget ✅
- [ ] `Info.plist` → RootsTimerWidget ✅
- [ ] `Shared/TimerLiveActivityAttributes.swift` → Roots ✅ + RootsTimerWidget ✅

### 3. Update Main App Info.plist
Add:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

### 4. Update TimerLiveActivityManager
Remove inline struct (lines 13-25) - now in shared file

### 5. Build
- Scheme: Roots
- Device: Physical iPhone (iOS 16.1+)
- Build: ⌘B

### 6. Test
1. Start timer
2. Lock device
3. See Live Activity! 🎉

## Common Issues

**"Cannot find type"** → Check target membership
**"No module ActivityKit"** → Check deployment target 16.1+
**Not showing** → Physical device required (no simulator)

## Done!
Live Activity will now show when timer is active.
