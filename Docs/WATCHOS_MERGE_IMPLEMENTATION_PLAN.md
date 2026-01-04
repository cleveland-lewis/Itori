# watchOS Integration into Multi-Platform Target — Implementation Plan

## Current State

### Existing Targets
1. **Itori** — Multi-platform target (macOS + iOS)
2. **ItoriWatch** — Separate watchOS target
3. **ItoriTests** — Test target
4. **ItoriUITests** — UI test target

### Current App Entry Points
- **macOS:** `Platforms/macOS/App/ItoriApp.swift` with `#if os(macOS)`
- **iOS:** `Platforms/iOS/App/ItoriIOSApp.swift` with `#if os(iOS)`
- **watchOS:** `Platforms/watchOS/App/ItoriWatchApp.swift` with `#if os(watchOS)` (separate target)

---

## Goal

Merge `ItoriWatch` target into the main `Itori` target so all three platforms share:
- Dependencies
- Build settings (where appropriate)
- Deployment workflow
- Unified versioning

---

## Implementation Strategy

### Option 1: Merge Targets in Xcode (Recommended)

**Pros:**
- Clean, supported by Xcode
- Maintains project structure integrity
- Easy to configure per-platform settings

**Cons:**
- Requires careful Xcode GUI work or project.pbxproj editing

**Steps:**
1. Add watchOS as a supported destination to the `Itori` target
2. Migrate all `ItoriWatch` source files to `Itori` target membership
3. Configure watchOS-specific build settings in `Itori` target
4. Remove `ItoriWatch` target
5. Update schemes

---

### Option 2: Keep Separate Watch Target (Current State)

**Pros:**
- Already working
- Isolated build configuration
- No risk of breaking existing builds

**Cons:**
- Duplicate build settings management
- Separate versioning
- Cannot share as much code

**Recommendation:** Only if Option 1 proves too risky

---

## Detailed Steps (Option 1 — Merge Targets)

### Phase 1: Backup & Preparation

```bash
# Backup current state
git stash push -m "Pre-watch-merge state"
git branch backup/before-watch-merge

# Ensure clean build
xcodebuild clean -scheme Itori
xcodebuild clean -scheme ItoriWatch
```

### Phase 2: Add watchOS Support to Itori Target

**In Xcode:**
1. Open `ItoriApp.xcodeproj`
2. Select `Itori` target
3. Go to "Build Settings"
4. Search for "Supported Platforms"
5. Add `watchOS` to supported platforms
6. Set `Supported Destinations` to include watchOS

**Project Settings to Configure:**
- `SUPPORTED_PLATFORMS = macosx iphoneos iphonesimulator watchos watchsimulator`
- `TARGETED_DEVICE_FAMILY = 1,2,4` (iPhone, iPad, Apple Watch)
- `IPHONEOS_DEPLOYMENT_TARGET = 17.0`
- `WATCHOS_DEPLOYMENT_TARGET = 10.0`
- `MACOSX_DEPLOYMENT_TARGET = 14.0`

### Phase 3: Migrate Source Files

**Files to Add to Itori Target:**
1. `Platforms/watchOS/App/ItoriWatchApp.swift`
2. `Platforms/watchOS/Root/WatchRootView.swift`
3. Any other watchOS-specific files

**In Xcode:**
1. Select each file in Project Navigator
2. In File Inspector (right sidebar)
3. Check the box for `Itori` target membership
4. Uncheck the box for `ItoriWatch` target (if present)

### Phase 4: Configure Conditional Compilation

**Ensure all entry points use platform guards:**

```swift
// Platforms/macOS/App/ItoriApp.swift
#if os(macOS)
@main
struct ItoriApp: App { ... }
#endif

// Platforms/iOS/App/ItoriIOSApp.swift
#if os(iOS)
@main
struct ItoriIOSApp: App { ... }
#endif

// Platforms/watchOS/App/ItoriWatchApp.swift
#if os(watchOS)
@main
struct ItoriWatchApp: App { ... }
#endif
```

### Phase 5: Update Info.plist Configuration

**Create platform-specific Info.plist if needed:**

```
Config/
  ├─ Info-iOS.plist
  ├─ Info-macOS.plist
  └─ Info-watchOS.plist
```

**Or use conditional settings in build settings:**
- `INFOPLIST_FILE[sdk=watchos*] = Config/Info-watchOS.plist`
- `INFOPLIST_FILE[sdk=iphoneos*] = Config/Info-iOS.plist`
- `INFOPLIST_FILE[sdk=macosx*] = Config/Info-macOS.plist`

### Phase 6: Configure watchOS-Specific Build Settings

**In Itori target build settings:**

```
// Watch App Bundle Identifier
PRODUCT_BUNDLE_IDENTIFIER[sdk=watchos*] = clewisiii.Itori.watchkitapp

// Product Name
PRODUCT_NAME[sdk=watchos*] = Itori Watch

// Skip Install (for watch)
SKIP_INSTALL[sdk=watchos*] = NO

// Asset Catalog
ASSETCATALOG_COMPILER_APPICON_NAME[sdk=watchos*] = AppIcon

// Watch App
WATCH_APPLICATION_BUNDLE_IDENTIFIER = clewisiii.Itori.watchkitapp
```

### Phase 7: Update Schemes

**Modify "Itori" Scheme:**
1. Product → Scheme → Edit Scheme
2. Add watchOS destinations:
   - Apple Watch (build for active architecture)
   - Apple Watch Simulator

**Remove "ItoriWatch" Scheme:**
- Product → Scheme → Manage Schemes
- Delete `ItoriWatch` scheme

### Phase 8: Remove Old ItoriWatch Target

**In Xcode:**
1. Select `ItoriWatch` target in project navigator
2. Press Delete
3. Confirm deletion

**Cleanup:**
- Remove any ItoriWatch-specific build products
- Remove ItoriWatch from target dependencies

### Phase 9: Test Build

```bash
# Build for all platforms
xcodebuild build -scheme Itori -destination 'platform=macOS'
xcodebuild build -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15'
xcodebuild build -scheme Itori -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'
```

### Phase 10: Verify SharedCore Compatibility

**Ensure SharedCore code compiles for watchOS:**

```swift
// Check for watchOS-incompatible APIs
// Common issues:
// - AppKit (macOS only)
// - UIKit (iOS/tvOS only)
// - WatchKit APIs (watchOS only)

// Use conditional compilation:
#if os(watchOS)
import WatchKit
#elseif os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
```

---

## Files Requiring Changes

### Xcode Project File
- `ItoriApp.xcodeproj/project.pbxproj` (extensive changes)

### Build Configuration (Optional)
- `Config/Info-watchOS.plist` (if creating separate plists)

### Schemes
- `ItoriApp.xcodeproj/xcshareddata/xcschemes/Itori.xcscheme`

### Source Files (Minimal Changes)
- All platform-specific app entry points already have `#if os(...)` guards ✅
- May need to add guards to any shared code that uses platform-specific APIs

---

## Potential Issues & Solutions

### Issue 1: Incompatible APIs in SharedCore

**Problem:** SharedCore code uses APIs not available on watchOS

**Solution:**
```swift
// Wrap platform-specific code
#if !os(watchOS)
// Code that uses UIKit/AppKit
#endif

// Or provide watchOS-specific implementation
#if os(watchOS)
// watchOS implementation
#else
// iOS/macOS implementation
#endif
```

### Issue 2: Asset Catalog Conflicts

**Problem:** Different platforms need different asset sizes

**Solution:**
- Use platform-specific asset catalogs
- Or use universal assets with proper size variants

### Issue 3: Entitlements

**Problem:** watchOS requires different entitlements

**Solution:**
```
ENTITLEMENTS_FILE[sdk=watchos*] = Config/Entitlements-watchOS.entitlements
ENTITLEMENTS_FILE[sdk=iphoneos*] = Config/Entitlements-iOS.entitlements
ENTITLEMENTS_FILE[sdk=macosx*] = Config/Entitlements-macOS.entitlements
```

### Issue 4: Code Signing

**Problem:** Different bundle IDs per platform

**Solution:**
- Use conditional `PRODUCT_BUNDLE_IDENTIFIER` settings (see Phase 6)
- Ensure proper provisioning profiles for each platform

---

## Verification Checklist

- [ ] Xcode shows all three destinations in scheme selector
- [ ] Build succeeds for macOS
- [ ] Build succeeds for iOS Simulator
- [ ] Build succeeds for watchOS Simulator
- [ ] App launches on macOS
- [ ] App launches on iOS Simulator
- [ ] App launches on watchOS Simulator
- [ ] SharedCore compiles for all platforms
- [ ] No duplicate symbols or linking errors
- [ ] Version/build numbers consistent across platforms
- [ ] No orphaned build products from old ItoriWatch target

---

## Rollback Plan

If merge fails:

```bash
# Restore backup
git checkout backup/before-watch-merge

# Or restore stash
git stash pop

# Rebuild with separate targets
xcodebuild clean -alltargets
xcodebuild build -scheme Itori
xcodebuild build -scheme ItoriWatch
```

---

## Alternative: Script-Based Approach

If manual Xcode editing is too error-prone, create a script:

```bash
#!/bin/bash
# merge_watch_target.sh

PROJECT="ItoriApp.xcodeproj/project.pbxproj"

# Backup
cp "$PROJECT" "$PROJECT.backup"

# Use PlistBuddy or direct text editing to:
# 1. Add watchOS to Itori target supported platforms
# 2. Update target membership for watchOS files
# 3. Remove ItoriWatch target

# Example (simplified):
sed -i '' 's/SUPPORTED_PLATFORMS = macosx iphoneos iphonesimulator/SUPPORTED_PLATFORMS = macosx iphoneos iphonesimulator watchos watchsimulator/' "$PROJECT"
```

**Warning:** Direct project.pbxproj editing is fragile. Only use if confident.

---

## Recommended Approach

**Safest Path:**
1. Use Xcode GUI for all changes (no manual pbxproj editing)
2. Make incremental changes with git commits after each phase
3. Test build after each phase before proceeding
4. Keep ItoriWatch target until Itori target fully works with watchOS
5. Only delete ItoriWatch after successful verification

**Fastest Path (Higher Risk):**
1. Duplicate ItoriWatch target as "Itori (watchOS)"
2. Merge settings manually in project.pbxproj
3. Delete both old targets
4. Verify in one shot

**Recommended:** Safest Path

---

## Success Criteria

After completion:
- Single `Itori` target builds for macOS, iOS, and watchOS
- No `ItoriWatch` target exists
- Single scheme with multiple destinations
- Shared versioning and build configuration
- Platform-specific code properly guarded with `#if os(...)`

---

## Time Estimate

- **Preparation:** 10 minutes
- **Xcode Configuration:** 30-60 minutes
- **Source Migration:** 15 minutes
- **Testing:** 30 minutes
- **Troubleshooting:** 30-60 minutes (buffer)
- **Total:** 2-3 hours

---

## Next Steps

1. **Confirm approach:** Should I proceed with Option 1 (merge targets)?
2. **Choose method:** Xcode GUI or script-based?
3. **Verify current state:** Does ItoriWatch currently build successfully?
4. **Begin implementation:** Start with Phase 1 (backup)

Would you like me to proceed with the implementation, or would you prefer to review the plan first?
