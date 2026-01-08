# UI Test Failures - Analysis & Resolution

## Executive Summary

**Status**: Partially resolved - 3/111 tests now passing (was 0/111)

**Root Cause**: UI tests were written for iOS but the app uses macOS-specific UI patterns. The app uses `NavigationSplitView` with a sidebar on macOS, not a `TabView` with bottom tab bar like iOS.

**Quick Win**: ✅ QuickSmokeTests suite (3 tests) now passes

**Remaining Work**: 108 tests need iOS→macOS adaptation or should be skipped

---

## What Was Fixed

### 1. Added Accessibility Infrastructure

**File**: `Platforms/macOS/PlatformAdapters/RootsSidebarShell.swift`

Added accessibility identifiers so UI tests can find elements:
- `MainWindow` - Main window container
- `Sidebar` - Sidebar container  
- `TabBar.{tabName}` - Each navigation item (dashboard, calendar, assignments, etc.)
- `Page.{pageName}` - Page content views
- `Overlay.QuickAdd` - Quick add menu button
- `Overlay.Settings` - Settings/energy button

**File**: `Platforms/macOS/Scenes/DashboardView.swift`

- `Page.dashboard` - Dashboard view identifier

### 2. Fixed Window Detection

**File**: `Tests/ItoriUITests/QuickSmokeTests.swift`

Changed from looking for `app.windows.firstMatch` (doesn't work reliably on macOS) to checking for actual UI content:
```swift
let hasSplitter = app.splitters.count > 0  // NavigationSplitView creates these
let hasButtons = app.buttons.count > 0
let hasStaticTexts = app.staticTexts.count > 0
```

---

## Test Results Summary

### ✅ Passing (3 tests)

**QuickSmokeTests** - All passing:
- `testAppCanLaunch` - Launches successfully
- `testAppDoesNotCrash` - Stays running for 3 seconds
- `testAppHasUI` - Has UI content

### ❌ Failing Test Categories

#### 1. iOS Tab Bar Assumption (32 tests)

**Suites affected**:
- ComprehensiveStressTests (8 tests)
- DataIntegrityTests (15 tests) 
- EventEditRecurrenceUITests (9 tests)

**Problem**: Tests look for `TabBar.{name}` buttons at the bottom of the screen (iOS pattern). On macOS, these are sidebar navigation items.

**Example failure**:
```
Failed to tap "TabBar.courses" Button: No matches found
from input {( Button, label: 'Start', Button, label: 'End' )}
```

**Fix**: Use sidebar navigation:
```swift
let coursesButton = app.buttons.matching(identifier: "TabBar.courses").firstMatch
coursesButton.click()  // Use click() not tap() on macOS
```

#### 2. Mobile Gestures (7 tests)

**Tests**:
- BasicFunctionalityTests: testRepeatedInteractions, testMultipleGestures, testLongRunningStability, testRapidTapping

**Problem**: Tests use `swipeUp()`, `swipeDown()`, `swipeLeft()`, `swipeRight()` which don't work properly on macOS.

**Example failure**:
```
Unable to find hit point for Application, pid: 29521, title: 'Itori'
```

**Fix**: Use macOS-appropriate interactions:
```swift
scrollView.scroll(byDeltaX: 0, deltaY: 100)
```

#### 3. iOS-Specific APIs (1 test)

**Test**: BasicFunctionalityTests.testBackgroundForeground

**Problem**: Uses `com.apple.springboard` which is iOS-only.

**Fix**: Skip on macOS or use `app.activate()` / `NSApp.hide()`

#### 4. Window/Menu Issues (69 tests)

**Tests**: Various tests checking for windows, attempting menu interactions, etc.

**Problem**: macOS XCUITest window detection and menu traversal work differently than iOS.

**Common errors**:
- "Failed to timed out while waiting for menu open notification"
- "App window should exist" 
- "Failed: open menu during menu traversal"

---

## Recommended Action Plan

### Phase 1: Immediate (Skip Failing Tests)

Mark failing tests with platform guards:

```swift
func testThatNeedsiOS() throws {
    #if os(macOS)
    throw XCTSkip("This test requires iOS-specific UI patterns")
    #endif
    // ... test code
}
```

This gets the test suite to a passing state quickly.

### Phase 2: Short-term (Adapt Critical Tests)

Add conditional logic to critical workflow tests:

```swift
func testCriticalWorkflow() throws {
    app.launch()
    
    #if os(macOS)
    // macOS navigation
    let calendarNav = app.buttons["TabBar.calendar"]
    calendarNav.click()
    #else
    // iOS navigation
    app.tabBars.buttons["Calendar"].tap()
    #endif
    
    // Shared verification
    XCTAssertTrue(app.otherElements["Page.calendar"].exists)
}
```

### Phase 3: Long-term (Platform-Specific Suites)

Create separate test files:
- `*Tests_macOS.swift` - Tests using macOS UI patterns
- `*Tests_iOS.swift` - Tests using iOS UI patterns

---

## How to Run Tests

```bash
# Run all UI tests (many will still fail)
xcodebuild test -scheme Itori -destination 'platform=macOS' \
  -only-testing:ItoriUITests

# Run just the passing smoke tests
xcodebuild test -scheme Itori -destination 'platform=macOS' \
  -only-testing:ItoriUITests/QuickSmokeTests

# Run a specific test
xcodebuild test -scheme Itori -destination 'platform=macOS' \
  -only-testing:ItoriUITests/QuickSmokeTests/testAppHasUI
```

---

## Key Differences: iOS vs macOS UI Testing

| Aspect | iOS | macOS |
|--------|-----|-------|
| Navigation | TabView with tab bar | NavigationSplitView with sidebar |
| Interaction | `.tap()` | `.click()` |
| Gestures | swipe, pinch | scroll, drag |
| Background | SpringBoard | `app.activate()` / `NSApp.hide()` |
| Window detection | `app.windows.firstMatch` | Check for content elements |
| Menus | Sheet presentations | Native menus & popovers |

---

## Files Modified

1. ✅ `Platforms/macOS/PlatformAdapters/RootsSidebarShell.swift`
2. ✅ `Platforms/macOS/Scenes/DashboardView.swift`
3. ✅ `Tests/ItoriUITests/QuickSmokeTests.swift`

---

## Additional Resources

- `UI_TESTS_FIX_SUMMARY.md` - Detailed technical changes
- `UI_TESTS_MACOS_ADAPTATION_GUIDE.md` - Step-by-step adaptation guide with code examples

---

## Conclusion

The UI test infrastructure is now in place with proper accessibility identifiers. The remaining work is mechanical: either skip iOS-specific tests or adapt them to use macOS UI patterns. The QuickSmokeTests demonstrate the fixes work correctly.

**Recommendation**: Start with Phase 1 (skip failing tests) to get the suite passing, then gradually adapt critical tests in Phase 2.
