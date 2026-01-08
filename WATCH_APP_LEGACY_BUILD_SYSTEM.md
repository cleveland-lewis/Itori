# ✅ Watch App - Legacy Build System Fix

**Date**: January 8, 2026, 12:50 AM EST  
**Issue**: "Multiple commands produce" with new build system  
**Solution**: Use Legacy Build System

---

## 🎯 What I Did

Switched the project to use Xcode's **Legacy Build System**, which doesn't have the strict output file tracking that causes "Multiple commands produce" errors.

---

## ✅ Changes Made

1. Created `WorkspaceSettings.xcsettings` with `BuildSystemType = Original`
2. This tells Xcode to use the legacy build system
3. The legacy system is more forgiving with build configurations

---

## 🚀 What to Do Now

### 1. **Quit Xcode** (if open)
```
⌘Q or File → Quit
```

### 2. **Clear Build Folder**:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/ItoriApp-*
```

### 3. **Reopen Xcode**:
```
Double-click ItoriApp.xcodeproj
```

### 4. **Verify Legacy System**:
```
Xcode may show a message about build system
Should say "Using Legacy Build System"
```

### 5. **Clean & Build**:
```
Product → Clean Build Folder (⌘⇧K)
Product → Build (⌘B)
```

### 6. **Run**:
```
Select: Itori scheme
Click: Run (▶️)
```

---

## 📝 Why This Works

### New Build System (Apple's default since Xcode 10):
- Strict output file tracking
- Parallel builds
- Sometimes too strict → "Multiple commands produce" errors
- Hard to debug

### Legacy Build System:
- More forgiving
- Sequential builds (slightly slower)
- Doesn't track output files as strictly
- ✅ Works around the conflict

---

## ⚠️ Note

The legacy build system will eventually be removed by Apple, but for now it's a valid workaround. Once the app builds successfully, we can potentially switch back to the new build system later.

---

## 🧪 Expected Result

After reopening Xcode and building:
- ✅ No "Multiple commands produce" error
- ✅ Build succeeds
- ✅ Watch app binary created (500KB+)
- ✅ App runs on simulator/device

---

## 🔄 To Switch Back Later

If you want to use the new build system again:

1. Delete `ItoriApp.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`
2. Or change `Original` to `Default`
3. Quit and reopen Xcode

---

**Try building now with the legacy system!** 🎉
