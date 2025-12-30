# Localization Keys Showing Instead of Translated Text

**Issue**: Planner page showing raw keys like "planner.timeline.title" instead of "Planner Timeline"

## Quick Fixes to Try

### 1. Clean Build Folder
```bash
cd /Users/clevelandlewis/Desktop/Roots
rm -rf ~/Library/Developer/Xcode/DerivedData/RootsApp*
xcodebuild clean -scheme Roots
xcodebuild -scheme Roots -destination 'platform=macOS' build
```

### 2. Verify System Language
Check if your Mac is set to English:
- System Settings → General → Language & Region
- Ensure "English" is the primary language

### 3. Check Xcode Scheme Language
1. Product → Scheme → Edit Scheme
2. Run → Options → App Language
3. Set to "System Language" or explicitly "English"

## Root Cause Analysis

The localization files ARE present and correct:
- ✅ `en.lproj/Localizable.strings` exists in project
- ✅ Strings are correctly defined
- ✅ Built app includes the .lproj bundle
- ✅ NSLocalizedString usage is correct

Possible causes:
1. **Bundle loading issue** - App can't find its own resources
2. **Language mismatch** - System language doesn't match available localizations
3. **Build cache** - Stale build artifacts
4. **Missing CFBundleDevelopmentRegion** in Info.plist

## Permanent Fix

Add explicit bundle specification to `NSLocalizedString` calls:

### Before:
```swift
Text(NSLocalizedString("planner.timeline.title", comment: ""))
```

### After:
```swift
Text(NSLocalizedString("planner.timeline.title", bundle: .main, comment: ""))
```

However, this shouldn't be necessary if the app is configured correctly.

## Check Bundle at Runtime

Add this debug code temporarily:

```swift
// Add to PlannerPageView
.onAppear {
    print("Main bundle path: \(Bundle.main.bundlePath)")
    print("Localized planner title: \(NSLocalizedString("planner.timeline.title", comment: ""))")
    print("Available localizations: \(Bundle.main.localizations)")
    print("Preferred localizations: \(Bundle.main.preferredLocalizations)")
}
```

Run the app and check Console for output.

## Expected Output

Should show:
```
Main bundle path: /path/to/Roots.app
Localized planner title: Planner Timeline
Available localizations: ["en", "zh-Hans", "zh-Hant"]
Preferred localizations: ["en"]
```

If it shows:
```
Localized planner title: planner.timeline.title
```

Then the bundle isn't finding the strings file.

## Most Likely Solution

**Clean build and restart Xcode:**

```bash
# 1. Close Xcode completely
# 2. Run these commands:
cd /Users/clevelandlewis/Desktop/Roots
rm -rf ~/Library/Developer/Xcode/DerivedData/RootsApp*
rm -rf ~/Library/Caches/com.apple.dt.Xcode
# 3. Reopen Xcode
# 4. Product → Clean Build Folder (Shift+Cmd+K)
# 5. Build and run
```

This resolves 90% of localization issues.

## If Still Not Working

Check Info.plist for development region:

```xml
<key>CFBundleDevelopmentRegion</key>
<string>en</string>
```

If missing, add it to the Roots target's Info.plist.

---

**Status**: Awaiting clean build test
