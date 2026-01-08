# Accessibility Settings Audit & Fix Plan

**Date:** January 8, 2025  
**Status:** 🔴 Critical - Settings exist but aren't fully wired up

---

## Executive Summary

**Problem:** Itori has accessibility toggles in Settings, but they're not consistently applied throughout the app. Users toggle these settings expecting changes that don't happen.

**Impact:** Neurodivergent users who need these accommodations can't actually use them. The app appears to have accessibility features but they're mostly non-functional.

**Priority:** 🔴 **CRITICAL** - This directly undermines the neurodivergence-first mission.

---

## Current Accessibility Settings

### 1. Show Animations (`showAnimations`)
**Location:** Settings > Interface > Animations  
**Storage:** `@AppStorage("roots.settings.showAnimations")`  
**Default:** `true`

#### Current Implementation:
- ✅ **iOS:** Applied globally via `.transaction` in `IOSRootView.swift` (line 80)
  ```swift
  .transaction { transaction in
      if !settings.showAnimations {
          transaction.disablesAnimations = true
      }
  }
  ```
- ❌ **macOS:** NOT applied at all
- ❌ **Hardcoded animations bypass this:**
  - `IOSCorePages.swift:52` - `.animation(.easeInOut(duration: 0.35), value: focusPulse)`
  - `IOSCorePages.swift:432` - `.animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressedTaskId)`
  - Many more throughout the codebase

#### Problems:
1. Only works on iOS
2. Explicit `.animation()` modifiers override the transaction
3. `withAnimation {}` blocks still animate
4. Sheet presentations still animate

---

### 2. Large Tap Targets (`largeTapTargets`)
**Location:** Settings > Interface > Layout > Large Tap Targets  
**Storage:** `@AppStorage("roots.settings.largeTapTargets")`  
**Default:** `false`

#### Current Implementation:
- ✅ Passed to `LayoutMetrics` environment object
- ✅ Defines sizing in `LayoutMetrics.swift`:
  - `minimumTapTarget: 48 vs 36`
  - `floatingButtonSize: 64 vs 52`
  - `iconButtonSize: 44 vs 36`

#### Usage Count: **Only 3 places use it!**
1. `FloatingControls.swift:17` - Floating button size
2. `IOSAppShell.swift:190` - Quick add button font size
3. `IOSAppShell.swift:196` - Settings button font size (duplicate)

#### Problems:
1. **Only 3 buttons in the entire app respond to this setting**
2. Dashboard buttons - don't use it
3. Assignment list items - don't use it
4. Timer controls - don't use it
5. Course list - doesn't use it
6. Calendar items - don't use it
7. Settings toggles themselves - don't use it

**99% of tap targets ignore this setting.**

---

### 3. Compact Mode (`compactMode`)
**Location:** Settings > Interface > Layout > Compact Mode  
**Storage:** `@AppStorage("roots.settings.compactMode")`  
**Default:** `false`

#### Current Implementation:
- ✅ Passed to `LayoutMetrics` environment object
- ✅ Defines spacing in `LayoutMetrics.swift`:
  - `listRowVerticalPadding: 6 vs 12`
  - `sectionSpacing: 12 vs 20`
  - `cardPadding: 12 vs 16`
  - `listRowMinHeight: 36 vs 44`

#### Usage Count: **ZERO direct usages found!**

#### Problems:
**The metrics are defined but NEVER USED.**

Views use hardcoded values instead:
- `.padding(20)` everywhere
- `.padding(.vertical, 12)` hardcoded
- `.spacing(16)` hardcoded
- No views actually read `layoutMetrics.cardPadding` or similar

---

### 4. Reduce Motion (`reduceMotion`)
**Location:** Settings > Accessibility > Reduce Motion  
**Storage:** `@AppStorage("roots.settings.reduceMotion")`  
**Default:** `false`

#### Current Implementation:
- ❌ **COMPLETELY UNUSED**
- Setting exists in AppSettingsModel
- Toggle exists in settings UI
- **Nothing checks this value**

#### Problems:
1. Redundant with `showAnimations` (unclear what the difference should be)
2. Not wired to anything
3. Should probably be consolidated with `showAnimations`

---

## Missing Accessibility Features

### Features That Should Exist:
1. **Haptic Feedback Intensity** - (Off / Light / Medium / Strong)
2. **Font Size Override** - Beyond system accessibility
3. **Color Contrast Mode** - High contrast option
4. **Gentle Mode Bundle** - One toggle for sensory relief
5. **Notification Pressure Level** - (Off / Gentle / Normal)

---

## Fix Plan

### Phase 1: Wire Up Existing Settings (IMMEDIATE)

#### 1.1 Fix `largeTapTargets` (1-2 hours)
Apply to ALL interactive elements:

**Files to modify:**
- `IOSCorePages.swift` - All list items and buttons
- `IOSDashboardView.swift` - All cards and buttons  
- `IOSTimerPageView.swift` - Timer controls
- `IOSGradesView.swift` - Grade items

**Pattern:**
```swift
// Before:
.frame(width: 40, height: 40)

// After:
@Environment(\.layoutMetrics) private var metrics
.frame(width: metrics.iconButtonSize, height: metrics.iconButtonSize)
```

**Estimated Impact:** ~50+ files to update

---

#### 1.2 Fix `compactMode` (2-3 hours)
Replace hardcoded spacing with metrics:

**Files to modify:** ALL view files

**Pattern:**
```swift
// Before:
.padding(20)
.padding(.vertical, 12)
VStack(spacing: 16)

// After:
@Environment(\.layoutMetrics) private var metrics
.padding(metrics.cardPadding)
.padding(.vertical, metrics.listRowVerticalPadding)
VStack(spacing: metrics.sectionSpacing)
```

**Search targets:**
- `.padding(20)` → `.padding(metrics.cardPadding)`
- `.padding(16)` → `.padding(metrics.cardPadding)`
- `.padding(.vertical, 12)` → `.padding(.vertical, metrics.listRowVerticalPadding)`
- `VStack(spacing: 16)` → `VStack(spacing: metrics.sectionSpacing)`

**Estimated Impact:** ~200+ instances

---

#### 1.3 Fix `showAnimations` (1-2 hours)

**Problem:** Explicit animations override the transaction

**Solution:** Conditional animation helper:

```swift
// Add to SharedCore/Utilities/
extension View {
    @ViewBuilder
    func conditionalAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V,
        isEnabled: Bool
    ) -> some View {
        if isEnabled {
            self.animation(animation, value: value)
        } else {
            self
        }
    }
}
```

**Usage:**
```swift
// Before:
.animation(.spring(response: 0.3), value: pressed)

// After:
@EnvironmentObject var settings: AppSettingsModel
.conditionalAnimation(.spring(response: 0.3), value: pressed, isEnabled: settings.showAnimations)
```

**Apply to:**
- All `.animation()` modifiers
- All `withAnimation {}` blocks
- Sheet/navigation transitions

---

#### 1.4 Remove or Consolidate `reduceMotion` (30 mins)

**Option A:** Remove it (it's unused)
**Option B:** Make it the master toggle:
```swift
var effectiveShowAnimations: Bool {
    showAnimations && !reduceMotion
}
```

**Recommendation:** Option A - Remove to reduce confusion

---

### Phase 2: Add Missing Features (MEDIUM PRIORITY)

#### 2.1 Haptic Feedback Control
```swift
enum HapticIntensity: String, CaseIterable {
    case off, light, medium, strong
}

@AppStorage("accessibility.hapticIntensity") var hapticIntensity: String = "medium"
```

Update `FeedbackManager` to respect this.

---

#### 2.2 Gentle Mode Bundle
Single toggle that sets:
- `showAnimations = false`
- `hapticIntensity = "light"`
- `notificationStyle = "gentle"`
- Custom color palette (softer)

---

### Phase 3: Testing & Validation

#### 3.1 Manual Testing Checklist
- [ ] Toggle `largeTapTargets` - all buttons should resize
- [ ] Toggle `compactMode` - all spacing should tighten
- [ ] Toggle `showAnimations` - no animations should play
- [ ] Test on iPad (different size class)
- [ ] Test on iPhone SE (small screen)
- [ ] Test with VoiceOver enabled
- [ ] Test with system text size at 150%

#### 3.2 Automated Tests
Create UI tests that verify:
- Button sizes change with `largeTapTargets`
- Spacing changes with `compactMode`
- Animations don't play with `showAnimations = false`

---

## Implementation Priority

### 🔴 Critical (Do First):
1. **Fix `largeTapTargets`** - Users with motor control issues can't tap buttons
2. **Fix `compactMode`** - Users with sensory overwhelm need this
3. **Fix `showAnimations`** - Users with motion sensitivity need this

### 🟡 Important (Do Second):
4. Remove/consolidate `reduceMotion`
5. Add haptic intensity control
6. Add gentle mode bundle

### 🟢 Nice to Have (Do Later):
7. Font size overrides
8. Color contrast modes
9. Notification pressure levels

---

## Code Audit Script

Run this to find hardcoded values:

```bash
# Find hardcoded padding
grep -rn "\.padding(2[0-9])" Platforms/iOS --include="*.swift"
grep -rn "\.padding(1[6-9])" Platforms/iOS --include="*.swift"

# Find hardcoded spacing
grep -rn "VStack(spacing: [0-9]" Platforms/iOS --include="*.swift"
grep -rn "HStack(spacing: [0-9]" Platforms/iOS --include="*.swift"

# Find hardcoded animations
grep -rn "\.animation(" Platforms/iOS --include="*.swift"
grep -rn "withAnimation" Platforms/iOS --include="*.swift"

# Find hardcoded sizes
grep -rn "\.frame(width: [0-9]" Platforms/iOS --include="*.swift"
```

---

## Success Criteria

### Before:
- User toggles "Large Tap Targets" → Only 3 buttons change
- User toggles "Compact Mode" → Nothing changes
- User toggles "Reduce Motion" → Nothing changes

### After:
- User toggles "Large Tap Targets" → ALL interactive elements resize (100% coverage)
- User toggles "Compact Mode" → ALL spacing tightens (100% coverage)
- User toggles "Show Animations" → NO animations play (100% coverage)
- "Reduce Motion" → Removed or merged
- New "Gentle Mode" → Everything softens at once

---

## Estimated Effort

### Developer Time:
- Phase 1.1 (largeTapTargets): **2 hours**
- Phase 1.2 (compactMode): **3 hours**
- Phase 1.3 (showAnimations): **2 hours**
- Phase 1.4 (reduceMotion cleanup): **0.5 hours**
- **Total Phase 1: 7.5 hours**

### Testing Time:
- Manual testing: **2 hours**
- Automated tests: **3 hours**
- **Total Testing: 5 hours**

### **Grand Total: 12.5 hours** (1.5 days of focused work)

---

## Next Steps

1. **Immediate:** Create helper extension for conditional animations
2. **Day 1 Morning:** Fix `largeTapTargets` across all buttons
3. **Day 1 Afternoon:** Fix `compactMode` spacing
4. **Day 2 Morning:** Fix remaining animation issues
5. **Day 2 Afternoon:** Test everything thoroughly

---

## Notes for Implementation

### Environment Object Pattern:
All views should have:
```swift
@Environment(\.layoutMetrics) private var metrics
@EnvironmentObject private var settings: AppSettingsModel
```

### Migration Strategy:
1. Start with high-traffic views (Dashboard, Assignments, Planner)
2. Create a tracking doc of files modified
3. Use search/replace carefully with regex
4. Test after each section of files

### Don't Break:
- Existing layouts (changes should be opt-in via toggles)
- Animation timings when animations are enabled
- Visual hierarchy and design

---

## Conclusion

The accessibility infrastructure EXISTS but isn't CONNECTED. This is a 1-2 day fix that will make the neurodivergence mission statement actually true.

**Current State:** "We say we support accessibility but mostly don't"  
**Target State:** "Accessibility settings actually work throughout the entire app"

This is foundational work that must be done before adding new features. Otherwise we're building on sand.
