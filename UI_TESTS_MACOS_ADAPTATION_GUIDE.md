# macOS UI Tests Adaptation Guide

## Summary

The UI tests were originally written for iOS and need significant adaptation for macOS. The app uses different UI patterns on macOS (NavigationSplitView with sidebar instead of TabView with tab bar).

## What's Fixed

✅ **QuickSmokeTests** - All 3 tests passing:
- `testAppCanLaunch` - Verifies app launches
- `testAppDoesNotCrash` - Verifies 3-second stability  
- `testAppHasUI` - Verifies UI content exists

✅ **Accessibility Infrastructure** - Added identifiers to:
- Main window (`MainWindow`)
- Sidebar (`Sidebar`)
- Navigation items (`TabBar.{tab}`)
- Page views (`Page.{page}`)
- Toolbar buttons (`Overlay.QuickAdd`, `Overlay.Settings`)

## What Needs Adaptation

### Tests Assuming iOS Tab Bar

These tests try to tap `TabBar.{name}` buttons expecting a bottom tab bar:
- `ComprehensiveStressTests` (all 8 tests)
- `DataIntegrityTests` (all 15 tests)
- `EventEditRecurrenceUITests` (all 9 tests)
- `UISnapshotTests.testCriticalScreensAndOverlays`

**Fix**: In macOS, tabs are sidebar items. Use:
```swift
// Find and click sidebar navigation item
let calendarNav = app.buttons.matching(identifier: "TabBar.calendar").firstMatch
XCTAssertTrue(calendarNav.exists)
calendarNav.click()  // Use click() not tap() on macOS
```

### Tests Assuming iOS Gestures

These tests use mobile gestures (swipe, pinch) that don't work on macOS:
- `BasicFunctionalityTests.testRepeatedInteractions`
- `BasicFunctionalityTests.testMultipleGestures`
- `BasicFunctionalityTests.testLongRunningStability`
- `BasicFunctionalityTests.testRapidTapping`

**Fix**: Use macOS-appropriate interactions:
```swift
// Instead of swipe
scrollView.scroll(byDeltaX: 0, deltaY: 100)

// Instead of tap
element.click()

// Instead of longPress
element.click(forDuration: 1.0)
```

### Tests Assuming iOS UI Patterns

- `BasicFunctionalityTests.testBasicInteraction` - Tries to tap "Start" button with iOS menu traversal
- `BasicFunctionalityTests.testBackgroundForeground` - Uses `com.apple.springboard` (iOS only)

**Fix**: Adapt for macOS:
```swift
// Background/foreground testing on macOS
app.activate()  // Bring to foreground
// ... test ...
NSApp.hide(nil)  // Send to background
```

### Tests Checking Window Existence

Tests like `BasicFunctionalityTests.testMainUIElementsExist` checked for `app.windows.firstMatch`.

**Fix**: Check for actual content instead:
```swift
let hasSplitter = app.splitters.count > 0  // NavigationSplitView creates splitters
let hasButtons = app.buttons.count > 0
XCTAssertTrue(hasSplitter || hasButtons)
```

## Recommended Approach

### Option 1: Quick Skip (Fastest)

Add platform checks to skip iOS-specific tests:

```swift
#if os(macOS)
throw XCTSkip("This test requires iOS-specific UI patterns")
#else
// original test code
#endif
```

### Option 2: Conditional Logic (Better)

```swift
func testNavigation() throws {
    #if os(macOS)
    // Click sidebar item
    let item = app.buttons["TabBar.calendar"]
    item.click()
    #else
    // Tap tab bar button  
    let tab = app.tabBars.buttons["Calendar"]
    tab.tap()
    #endif
    
    // Common verification
    XCTAssertTrue(app.otherElements["Page.calendar"].exists)
}
```

### Option 3: Separate Test Files (Best)

Create platform-specific test files:
- `BasicFunctionalityTests_macOS.swift`
- `BasicFunctionalityTests_iOS.swift`

Each contains tests appropriate for its platform.

## Quick Wins - Specific Test Fixes

### Fix BasicFunctionalityTests.testMainUIElementsExist

```swift
func testMainUIElementsExist() throws {
    sleep(2)
    
    #if os(macOS)
    // Check for NavigationSplitView
    let hasSplitter = app.splitters.count > 0
    let hasButtons = app.buttons.count > 0
    XCTAssertTrue(hasSplitter || hasButtons, "App should have UI elements")
    #else
    // iOS check
    XCTAssertTrue(app.windows.firstMatch.exists)
    #endif
}
```

### Fix DataIntegrityTests Navigation

```swift
func testDataPersistenceAcrossLaunches() throws {
    #if os(macOS)
    // Navigate using sidebar
    let coursesButton = app.buttons.matching(identifier: "TabBar.courses").firstMatch
    XCTAssertTrue(coursesButton.waitForExistence(timeout: 5))
    coursesButton.click()
    #else
    // iOS tab bar
    app.tabBars.buttons["Courses"].tap()
    #endif
    
    // Rest of test...
}
```

### Skip SpringBoard Test on macOS

```swift
func testBackgroundForeground() throws {
    #if os(macOS)
    throw XCTSkip("SpringBoard is iOS-only")
    #else
    // iOS springboard test
    #endif
}
```

## Testing the Fixes

Run specific test suites:

```bash
# Run smoke tests (should all pass now)
xcodebuild test -scheme Itori -destination 'platform=macOS' \
  -only-testing:ItoriUITests/QuickSmokeTests

# Run after fixing a specific suite
xcodebuild test -scheme Itori -destination 'platform=macOS' \
  -only-testing:ItoriUITests/BasicFunctionalityTests
```

## Accessibility Best Practices

When adding new UI, always add accessibility identifiers:

```swift
Button("Add") {
    // action
}
.accessibilityIdentifier("AddButton")

NavigationLink("Settings") {
    SettingsView()
}
.accessibilityIdentifier("SettingsLink")

ScrollView {
    // content
}
.accessibilityIdentifier("ContentScrollView")
```

## Next Steps

1. **Immediate**: Skip or conditionally disable failing tests
2. **Short-term**: Add `#if os(macOS)` logic to critical tests  
3. **Long-term**: Create comprehensive macOS-specific test suite

## Files Modified

1. `Platforms/macOS/PlatformAdapters/RootsSidebarShell.swift` - Added accessibility IDs
2. `Platforms/macOS/Scenes/DashboardView.swift` - Added page identifier
3. `Tests/ItoriUITests/QuickSmokeTests.swift` - Fixed window detection
