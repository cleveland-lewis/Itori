# Accessibility Testing Framework - Quick Reference

## 🚀 Quick Start

### 1. Open Debug Panel
```swift
#if DEBUG
import SwiftUI

// In your view
.sheet(isPresented: $showAccessibilityDebug) {
    AccessibilityDebugPanel()
}
#endif
```

### 2. Run Full Audit
```swift
Task {
    await AccessibilityAuditEngine.shared.runFullAudit()
    print("Found \(AccessibilityAuditEngine.shared.totalIssues) issues")
}
```

### 3. Check Results
```swift
let engine = AccessibilityAuditEngine.shared
print("Critical: \(engine.criticalCount)")
print("High: \(engine.highCount)")
print("Medium: \(engine.mediumCount)")
```

## 📊 Common Tests

### Contrast Ratio
```swift
let ratio = AccessibilityTestingHelpers.contrastRatio(
    foreground: .black,
    background: .white
)
// Result: ~21:1

let meetsAA = AccessibilityTestingHelpers.meetsWCAGAA(
    foreground: textColor,
    background: bgColor
)
// true if ratio >= 4.5:1
```

### Touch Target Size
```swift
let size = CGSize(width: 44, height: 44)
let passes = AccessibilityTestingHelpers.meetsTouchTargetSize(size)
// true on iOS (44pt min), true on macOS (24pt min)

let minSize = AccessibilityTestingHelpers.minimumTouchTarget
// iOS: 44x44pt, macOS: 24x24pt
```

### VoiceOver Status
```swift
if AccessibilityTestingHelpers.isVoiceOverRunning {
    // VoiceOver is active
    // Adjust UI accordingly
}
```

### Announce for Testing
```swift
AccessibilityTestingHelpers.announceForTesting(
    "Assignment completed successfully"
)
```

## 🔍 Audit Categories

| Category | Description | Examples |
|----------|-------------|----------|
| **Labels** | Accessibility labels & traits | Missing button labels, incorrect traits |
| **Contrast** | Color contrast ratios | Low contrast text, chart colors |
| **Touch Target** | Minimum interactive sizes | Small buttons, tight spacing |
| **Keyboard Nav** | Keyboard accessibility | Missing focus indicators, bad tab order |
| **Dynamic Type** | Text scaling | Fixed font sizes, layout breaks |
| **VoiceOver** | Screen reader support | Missing context, no state announcements |
| **Reduce Motion** | Motion preferences | Ignored animation settings |
| **Focus** | Focus management | No initial focus, lost focus on navigation |

## 🎯 Severity Levels

| Severity | Meaning | Action |
|----------|---------|--------|
| **Critical** | Blocks users | Fix immediately |
| **High** | Major accessibility barrier | Fix in current sprint |
| **Medium** | Usability issue | Fix soon |
| **Low** | Enhancement opportunity | Backlog |
| **Info** | Best practice suggestion | Consider |

## ✅ WCAG Standards

### Level AA (Standard)
- **1.4.3 Contrast:** 4.5:1 for normal text, 3:1 for large text
- **1.4.4 Resize:** Text scales to 200%
- **2.4.7 Focus:** Visible focus indicator
- **2.5.5 Target Size:** 44×44pt minimum (iOS)

### Level AAA (Enhanced)
- **1.4.6 Contrast:** 7:1 for normal text, 4.5:1 for large text
- **2.4.8 Location:** Clear navigation context

## 🛠️ Debug Tools

### Visual Overlay
```swift
#if DEBUG
MyView()
    .accessibilityDebugOverlay()
// Shows touch target grid
#endif
```

### Inspector Mode
```swift
MyView()
    .accessibilityInspectable()
// Long press (2s) to activate
// Tap elements to inspect properties
```

### Test Suite
```swift
var suite = AccessibilityTestSuite(viewName: "Login")

suite.addTest(
    name: "Username field has label",
    passed: true
)

suite.addTest(
    name: "Button meets 44pt minimum",
    passed: AccessibilityTestingHelpers.meetsTouchTargetSize(buttonSize)
)

suite.addTest(
    name: "Text contrast meets AA",
    passed: contrast >= 4.5
)

suite.printReport()
// Prints formatted report with pass/fail stats
```

## 📝 Common Patterns

### Button with Label
```swift
Button("") {
    // action
}
.accessibilityLabel("Add assignment")
.accessibilityHint("Opens form to create new assignment")
```

### Custom Control
```swift
CustomSlider(value: $volume)
    .accessibilityLabel("Volume")
    .accessibilityValue("\(Int(volume))%")
    .accessibilityAdjustableAction { direction in
        // Handle increment/decrement
    }
```

### Status Announcement
```swift
UIAccessibility.post(
    notification: .announcement,
    argument: "Timer started"
)
```

### Focus Management
```swift
@AccessibilityFocusState private var isFocused: Bool

TextField("Email", text: $email)
    .accessibilityFocused($isFocused)
    .onAppear {
        isFocused = true
    }
```

### Dynamic Type
```swift
Text("Title")
    .font(.headline)
    .minimumScaleFactor(0.8)
    .dynamicTypeSize(.medium...(.accessibility3))
```

### Reduce Motion
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion ? .none : .spring()
}
```

## 🧪 Running Tests

### All Accessibility Tests
```bash
xcodebuild test -scheme Roots \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:RootsTests/AccessibilityTests
```

### Specific Test
```bash
xcodebuild test -scheme Roots \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:RootsTests/AccessibilityTests/testContrastRatioCalculation
```

## 🎨 Preview Helpers

```swift
// VoiceOver simulation
MyView()
    .previewWithVoiceOver()

// Large text
MyView()
    .previewWithLargeText()

// Reduce Motion
MyView()
    .previewWithReduceMotion()

// High Contrast
MyView()
    .previewWithHighContrast()

// All features
MyView()
    .previewAccessibilityMaximum()
```

## 📋 Manual Testing Checklist

### VoiceOver (iOS)
- [ ] Settings → Accessibility → VoiceOver → Enable
- [ ] Navigate with single tap (focus) + double tap (activate)
- [ ] Swipe right/left to navigate
- [ ] Two-finger swipe to read all
- [ ] Use rotor (rotate two fingers) for navigation modes

### Dynamic Type
- [ ] Settings → Accessibility → Display & Text Size → Larger Text
- [ ] Test at largest size (Accessibility 3)
- [ ] Verify layout doesn't break
- [ ] Check text truncation

### Reduce Motion
- [ ] Settings → Accessibility → Motion → Reduce Motion
- [ ] Verify animations are removed/simplified
- [ ] Check transitions are instant

### Keyboard (macOS)
- [ ] Tab through all interactive elements
- [ ] Verify focus indicator visible
- [ ] Check logical tab order
- [ ] Test with Full Keyboard Access enabled

## 🐛 Common Issues & Fixes

### Issue: Button has no label
```swift
// ❌ Bad
Button(action: {}) {
    Image(systemName: "plus")
}

// ✅ Good
Button(action: {}) {
    Image(systemName: "plus")
}
.accessibilityLabel("Add item")
```

### Issue: Custom control not accessible
```swift
// ❌ Bad
CustomControl()

// ✅ Good
CustomControl()
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Timer")
    .accessibilityValue("5 minutes")
    .accessibilityAddTraits(.updatesFrequently)
```

### Issue: Low contrast text
```swift
// ❌ Bad
Text("Secondary info")
    .foregroundColor(.gray.opacity(0.3))

// ✅ Good
Text("Secondary info")
    .foregroundColor(.secondary) // System color, adapts
```

### Issue: Small touch target
```swift
// ❌ Bad (30x30pt)
Button(action: {}) {
    Image(systemName: "trash")
}

// ✅ Good (44x44pt minimum)
Button(action: {}) {
    Image(systemName: "trash")
        .frame(minWidth: 44, minHeight: 44)
}
```

### Issue: Missing state announcements
```swift
// ❌ Bad
isCompleted.toggle()

// ✅ Good
isCompleted.toggle()
UIAccessibility.post(
    notification: .announcement,
    argument: isCompleted ? "Completed" : "Incomplete"
)
```

## 📊 Audit Report Example

```
════════════════════════════════════════════════════════
Accessibility Test Report: Dashboard
════════════════════════════════════════════════════════

Total Tests: 10
Passed: 7 ✅
Failed: 3 ❌
Pass Rate: 70.0%

[1] ✅ PASS - All buttons have labels
[2] ✅ PASS - Text contrast meets AA
[3] ❌ FAIL - Touch target too small
    Button size: 32×32pt (minimum: 44×44pt)
[4] ✅ PASS - Dynamic Type supported
[5] ❌ FAIL - VoiceOver missing hints
[6] ✅ PASS - Focus order logical
[7] ✅ PASS - Reduce Motion respected
[8] ✅ PASS - Keyboard accessible
[9] ❌ FAIL - State changes not announced
[10] ✅ PASS - Semantic structure correct

════════════════════════════════════════════════════════
```

## 🔗 Quick Links

- **Full Documentation:** `ACCESSIBILITY_TESTING_FRAMEWORK.md`
- **Apple HIG:** https://developer.apple.com/design/human-interface-guidelines/accessibility
- **WCAG 2.1:** https://www.w3.org/WAI/WCAG21/quickref/
- **Xcode Inspector:** Xcode → Open Developer Tool → Accessibility Inspector

## 📱 Platform Differences

| Feature | iOS | macOS | watchOS |
|---------|-----|-------|---------|
| Min Touch Target | 44×44pt | 24×24pt | 44×44pt |
| VoiceOver | ✅ | ✅ | ✅ |
| Dynamic Type | ✅ | ✅ | ✅ |
| Reduce Motion | ✅ | ✅ | ✅ |
| Keyboard Nav | ⚠️ External | ✅ | ❌ |
| Focus Management | ✅ | ✅ | ⚠️ Limited |

## ⚡ Performance

- **Audit Time:** ~500ms for typical view
- **Memory:** ~2MB for audit engine
- **Production Impact:** None (DEBUG only)
- **Test Execution:** ~100ms per test

## 🎯 Success Criteria

### Minimum (Required)
- [ ] All interactive elements have labels
- [ ] Contrast ratio ≥ 4.5:1 for text
- [ ] Touch targets ≥ 44pt on iOS
- [ ] Keyboard accessible (macOS)
- [ ] VoiceOver navigation works

### Ideal (Recommended)
- [ ] All hints provided
- [ ] Contrast ratio ≥ 7:1 (AAA)
- [ ] State changes announced
- [ ] Dynamic Type supported
- [ ] Reduce Motion respected
- [ ] Focus management implemented

---

**Last Updated:** 2026-01-03  
**Framework Version:** 1.0  
**WCAG Target:** Level AA
