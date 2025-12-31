# watchOS App - Quick Start Guide

**Everything you need to know to use the watch app**

---

## ✅ What's Implemented

### Timer
- ⏱️  Start/stop timer from watch
- 📊 Real-time countdown display
- 🔄 Syncs with iPhone timer
- 🎯 Multiple modes: Pomodoro, Timer, Focus, Stopwatch

### Tasks
- ✅ View all your tasks
- ✓ Check off completed tasks
- ➕ Add new tasks
- 📅 See due dates
- 🔄 Everything syncs to iPhone

---

## 🚀 Quick Setup (iOS App)

Add this ONE line to your iOS app:

```swift
// In IOSRootView.swift or IOSAppShell.swift
.onAppear {
    IOSWatchSyncCoordinator.shared.configure(
        timerManager: yourTimerManager,
        assignmentsStore: yourAssignmentsStore
    )
}
```

Done! The watch app now syncs automatically.

---

## 📱 Using the Watch App

### Timer Tab

1. **Select mode**: Pomodoro, Timer, Focus, or Stopwatch
2. **Set duration** (if Focus mode): Use stepper to set minutes
3. **Tap Start**: Timer begins on both watch and phone
4. **Tap Stop**: Timer stops on both devices

### Tasks Tab

1. **View tasks**: Scroll through To Do and Completed
2. **Complete task**: Tap checkbox → syncs to phone
3. **Add task**: 
   - Tap "Add Task"
   - Enter title
   - Optionally set due date
   - Tap "Add Task" button
   - New task appears on phone

---

## 🔧 Testing

### Simulator
```bash
# 1. Build watch app (removes WKWatchKitApp key)
./build_watch_fixed.sh

# 2. Run watch app in Xcode on watch simulator
# 3. Run iPhone app on paired iPhone simulator
# 4. Test sync!
```

### Real Devices
- Use Xcode GUI to build and run
- Or use TestFlight (see TESTFLIGHT_SETUP_GUIDE.md)

---

## 🐛 Troubleshooting

**Watch app not syncing?**
- Check iPhone and watch are paired
- Verify both apps are running
- Look for sync logs in console (🔗, 📤, 📥 emojis)

**Timer not updating on watch?**
- Make sure timer is running on phone
- Check WatchConnectivity is active
- Try stopping and restarting timer

**Tasks not appearing?**
- Verify IOSWatchSyncCoordinator is configured
- Check assignmentsStore has tasks
- Pull to refresh on watch

---

## 📚 Documentation

- **WATCHOS_APP_IMPLEMENTATION.md** - Complete technical docs
- **WATCHOS_COMPANION_IMPLEMENTATION.md** - Setup guide
- **TESTFLIGHT_SETUP_GUIDE.md** - Distribution guide

---

## ✨ That's It!

Your watch app is ready to use. Timer and tasks sync seamlessly between iPhone and Apple Watch!
