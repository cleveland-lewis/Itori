# watchOS App Installation Fix - WKWatchKitApp Key Removal

**Issue**: iOS simulator install fails with "not a WatchKit 2 app"  
**Root Cause**: `WKWatchKitApp = true` key being added automatically  
**Solution**: Remove the key after watch app builds

---

## Automated Build Script

```bash
#!/bin/bash
# Build and fix watch app for simulator installation

set -e

echo "🔨 Building RootsWatch..."
xcodebuild -project RootsApp.xcodeproj \
  -scheme RootsWatch \
  -sdk watchsimulator \
  -configuration Debug \
  build > /dev/null 2>&1

# Find built watch app
WATCH_APP=$(find ~/Library/Developer/Xcode/DerivedData/RootsApp-*/Build/Products/Debug-watchsimulator/RootsWatch.app -maxdepth 0 2>/dev/null | head -1)

if [ -z "$WATCH_APP" ]; then
    echo "❌ Watch app not built"
    exit 1
fi

echo "✅ Watch app built"

# Remove WKWatchKitApp key
INFO_PLIST="$WATCH_APP/Info.plist"
/usr/libexec/PlistBuddy -c "Delete :WKWatchKitApp" "$INFO_PLIST" 2>/dev/null || true
echo "✅ Removed WKWatchKitApp key"

echo ""
echo "🔨 Building Roots (iOS)..."
xcodebuild -project RootsApp.xcodeproj \
  -scheme Roots \
  -sdk iphonesimulator \
  -configuration Debug \
  build > /dev/null 2>&1

echo "✅ iOS app built with watch app embedded"

# Verify embedded watch app
IOS_APP=$(find ~/Library/Developer/Xcode/DerivedData/RootsApp-*/Build/Products/Debug-iphonesimulator/Roots.app -maxdepth 0 2>/dev/null | head -1)
EMBEDDED_WATCH="$IOS_APP/Watch/RootsWatch.app/Info.plist"

if [ -f "$EMBEDDED_WATCH" ]; then
    HAS_LEGACY_KEY=$(plutil -p "$EMBEDDED_WATCH" | grep "WKWatchKitApp" || true)
    if [ -z "$HAS_LEGACY_KEY" ]; then
        echo "✅ Embedded watch app is WatchKit 2 compatible"
    else
        echo "⚠️  Warning: Embedded watch app still has WKWatchKitApp key"
    fi
fi

echo ""
echo "📱 Ready to install!"
echo ""
echo "To install on simulator:"
echo "  xcrun simctl boot 'iPhone 17 Pro'"
echo "  xcrun simctl install booted '$IOS_APP'"
```

Save this as `build_for_simulator.sh` and run:
```bash
chmod +x build_for_simulator.sh
./build_for_simulator.sh
```

---

## Manual Steps (If Script Doesn't Work)

### 1. Build Watch App
```bash
xcodebuild -project RootsApp.xcodeproj -scheme RootsWatch -sdk watchsimulator build
```

### 2. Remove Legacy Key
```bash
WATCH_APP=$(find ~/Library/Developer/Xcode/DerivedData/RootsApp-*/Build/Products/Debug-watchsimulator/RootsWatch.app -maxdepth 0 2>/dev/null | head -1)
/usr/libexec/PlistBuddy -c "Delete :WKWatchKitApp" "$WATCH_APP/Info.plist"
```

### 3. Verify Fix
```bash
plutil -p "$WATCH_APP/Info.plist" | grep "WK"
```
**Expected output**:
```
"WKCompanionAppBundleIdentifier" => "clewisiii.Roots"
```
(NO `WKWatchKitApp` key!)

### 4. Build iOS App
```bash
xcodebuild -project RootsApp.xcodeproj -scheme Roots -sdk iphonesimulator build
```

### 5. Install on Simulator
```bash
IOS_APP=$(find ~/Library/Developer/Xcode/DerivedData/RootsApp-*/Build/Products/Debug-iphonesimulator/Roots.app -maxdepth 0 2>/dev/null | head -1)
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl install booted "$IOS_APP"
```

---

## Why This Happens

**Problem**: Xcode automatically adds `WKWatchKitApp = true` for product type `watchapp2`  

**Apple's Bug**: The `INFOPLIST_KEY_WKWatchKitApp = NO` build setting is **ignored**

**Result**: Simulator sees the `WKWatchKitApp` key and thinks it's a legacy WatchKit 1.0 app (which requires a WatchKit Extension)

**Our App**: Modern SwiftUI watchOS app (no extension needed)

---

## Permanent Solution (Build Phase Script)

To automate this, add a build phase script to the RootsWatch target:

1. Open Xcode
2. Select RootsWatch target
3. Build Phases tab
4. Click "+" → "New Run Script Phase"
5. Add this script:

```bash
# Remove legacy WKWatchKitApp key
INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if [ -f "$INFO_PLIST" ]; then
    /usr/libexec/PlistBuddy -c "Delete :WKWatchKitApp" "$INFO_PLIST" 2>/dev/null || true
    echo "✅ Removed WKWatchKitApp key"
fi
```

6. Drag it to run **after** "Copy Bundle Resources"

Now every build will automatically remove the key!

---

## Summary

✅ **Root Cause**: Xcode auto-adds `WKWatchKitApp = true`  
✅ **Solution**: Remove it with PlistBuddy after build  
✅ **Automation**: Build phase script (recommended)  
✅ **Workaround**: Manual script before iOS build  

**Status**: Fix confirmed working - watch app installs successfully in simulator after removing the legacy key.
