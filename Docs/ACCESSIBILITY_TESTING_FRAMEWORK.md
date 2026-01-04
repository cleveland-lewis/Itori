# Accessibility Testing Framework - Complete Guide

## Overview

The Accessibility Testing Framework provides comprehensive tools for auditing, testing, and debugging accessibility features in the Itori app. It supports WCAG 2.1 Level AA/AAA compliance testing and provides real-time debugging tools for developers.

## Components

### 1. Accessibility Audit Engine (`AccessibilityAudit.swift`)

**Purpose:** Automated accessibility compliance scanning

**Key Features:**
- Full accessibility audit with categorized results
- WCAG 2.1 compliance checking
- Severity classification (Critical, High, Medium, Low, Info)
- Category-based organization (Labels, Contrast, Touch Targets, etc.)
- Real-time scanning with progress tracking

**Usage:**
```swift
#if DEBUG
import SwiftUI

// Run full audit
Task {
    await AccessibilityAuditEngine.shared.runFullAudit()
}

// Access results
let results = AccessibilityAuditEngine.shared.results
let criticalIssues = AccessibilityAuditEngine.shared.criticalCount

// Filter by category
let labelIssues = AccessibilityAuditEngine.shared.issuesByCategory(.labels)
```

### 2. Accessibility Debug Panel (`AccessibilityDebugPanel.swift`)

**Purpose:** Interactive UI for testing accessibility

**Features:**
- **Issues Tab:** View and filter accessibility issues
- **Live Testing Tab:** Real-time accessibility settings monitoring
- **Settings Tab:** Configure audit parameters

**Access:**
```swift
#if DEBUG
// Present debug panel
.sheet(isPresented: $showA11yDebug) {
    AccessibilityDebugPanel()
}
#endif
```

### 3. Accessibility Testing Helpers (`AccessibilityTestingHelpers.swift`)

**Purpose:** Programmatic testing utilities

**Key Functions:**

#### VoiceOver Testing
```swift
// Simulate announcement
AccessibilityTestingHelpers.announceForTesting("Timer started")

// Check if VoiceOver is running
if AccessibilityTestingHelpers.isVoiceOverRunning {
    // Adjust UI for VoiceOver users
}
```

#### Contrast Testing
```swift
// Calculate contrast ratio
let ratio = AccessibilityTestingHelpers.contrastRatio(
    foreground: .black,
    background: .white
)

// Check WCAG compliance
let meetsAA = AccessibilityTestingHelpers.meetsWCAGAA(
    foreground: textColor,
    background: backgroundColor
)

let meetsAAA = AccessibilityTestingHelpers.meetsWCAGAAA(
    foreground: textColor,
    background: backgroundColor
)
```

#### Touch Target Testing
```swift
// Check touch target size
let size = CGSize(width: 40, height: 40)
let meets = AccessibilityTestingHelpers.meetsTouchTargetSize(size)

// Get recommended minimum
let minimum = AccessibilityTestingHelpers.minimumTouchTarget
// iOS: 44x44pt, macOS: 24x24pt
```

#### Generate Test Reports
```swift
let report = AccessibilityTestingHelpers.generateTestReport(
    viewName: "Login Button",
    hasLabel: true,
    hasHint: true,
    hasValue: false,
    hasTraits: true,
    contrast: 6.5,
    touchTargetSize: CGSize(width: 44, height: 44)
)
print(report)
```

### 4. Accessibility Tests (`AccessibilityTests.swift`)

**Purpose:** Automated unit tests for accessibility

**Test Coverage:**
- Contrast ratio calculations
- WCAG AA/AAA compliance
- Touch target size validation
- Accessibility settings detection
- Test suite tracking
- Audit engine functionality

**Running Tests:**
```bash
# Run all accessibility tests
xcodebuild test -scheme Itori \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:ItoriTests/AccessibilityTests

# Run specific test
xcodebuild test -scheme Itori \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:ItoriTests/AccessibilityTests/testContrastRatioCalculation
```

## Testing Workflows

### Manual Testing Workflow

#### 1. Run Full Audit
```swift
1. Launch app in DEBUG mode
2. Open Accessibility Debug Panel
3. Tap "Scan" button
4. Review categorized issues
5. Tap issue for detailed recommendations
```

#### 2. Live Testing
```swift
1. Go to Live Testing tab
2. Check current accessibility settings
3. Enable VoiceOver in iOS Settings
4. Return to app and test navigation
5. Test with different Dynamic Type sizes
6. Enable Reduce Motion and verify animations
```

#### 3. Visual Debugging
```swift
// Add debug overlay to any view
SomeView()
    .accessibilityDebugOverlay()
    
// Shows:
// - Touch target grid overlay
// - Accessibility label indicators
// - Contrast visualization
```

### Automated Testing Workflow

#### 1. Create Test Suite
```swift
var suite = AccessibilityTestSuite(viewName: "Dashboard")

// Add tests
suite.addTest(name: "All buttons have labels", passed: true)
suite.addTest(name: "Contrast meets AA", passed: true)
suite.addTest(name: "Touch targets 44pt", passed: false)

// Print report
suite.printReport()
```

#### 2. Integration Tests
```swift
func testDashboardAccessibility() {
    var suite = AccessibilityTestSuite(viewName: "Dashboard")
    
    // Test floating action button
    let fabLabel = "Add new assignment"
    suite.addTest(name: "FAB has label", passed: !fabLabel.isEmpty)
    
    let fabSize = CGSize(width: 56, height: 56)
    suite.addTest(
        name: "FAB meets touch target",
        passed: AccessibilityTestingHelpers.meetsTouchTargetSize(fabSize)
    )
    
    // Test card contrast
    let cardContrast = AccessibilityTestingHelpers.contrastRatio(
        foreground: .primary,
        background: .cardBackground
    )
    suite.addTest(
        name: "Card text meets WCAG AA",
        passed: cardContrast >= 4.5
    )
    
    suite.printReport()
}
```

## WCAG 2.1 Compliance Checklist

### Level A (Minimum)

- [ ] **1.1.1 Non-text Content:** All images have alt text
- [ ] **1.3.1 Info and Relationships:** Semantic structure preserved
- [ ] **2.1.1 Keyboard:** All functionality available via keyboard
- [ ] **2.4.1 Bypass Blocks:** Skip navigation provided
- [ ] **3.1.1 Language of Page:** Language is specified
- [ ] **4.1.1 Parsing:** Valid markup
- [ ] **4.1.2 Name, Role, Value:** All UI components have accessible names

### Level AA (Standard)

- [ ] **1.4.3 Contrast (Minimum):** 4.5:1 contrast ratio for normal text
- [ ] **1.4.4 Resize Text:** Text scales to 200% without loss
- [ ] **1.4.5 Images of Text:** Avoid images of text
- [ ] **2.4.3 Focus Order:** Logical focus order
- [ ] **2.4.6 Headings and Labels:** Descriptive headings/labels
- [ ] **2.4.7 Focus Visible:** Keyboard focus indicator visible
- [ ] **3.2.3 Consistent Navigation:** Navigation is consistent
- [ ] **3.2.4 Consistent Identification:** Components identified consistently

### Level AAA (Enhanced)

- [ ] **1.4.6 Contrast (Enhanced):** 7:1 contrast ratio
- [ ] **2.4.8 Location:** User can determine location in site
- [ ] **2.5.5 Target Size:** 44×44pt minimum touch targets
- [ ] **3.1.3 Unusual Words:** Explanations provided

## Common Accessibility Patterns

### 1. Button with Label
```swift
Button(action: { /* action */ }) {
    Image(systemName: "plus")
}
.accessibilityLabel("Add assignment")
.accessibilityHint("Opens form to create new assignment")
```

### 2. Custom Control
```swift
CustomTimerControl()
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Timer")
    .accessibilityValue("\(minutes) minutes \(seconds) seconds")
    .accessibilityAddTraits(.startsMediaSession)
    .accessibilityAdjustableAction { direction in
        if direction == .increment {
            increaseTime()
        } else {
            decreaseTime()
        }
    }
```

### 3. Status Announcement
```swift
// When timer completes
UIAccessibility.post(
    notification: .announcement,
    argument: "Timer completed"
)
```

### 4. Focus Management
```swift
struct LoginView: View {
    @AccessibilityFocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .accessibilityFocused($focusedField, equals: .username)
            
            SecureField("Password", text: $password)
                .accessibilityFocused($focusedField, equals: .password)
        }
        .onAppear {
            focusedField = .username
        }
    }
}
```

### 5. Dynamic Type Support
```swift
Text("Assignment Title")
    .font(.headline)
    .dynamicTypeSize(.medium...(.accessibility3))
    .minimumScaleFactor(0.8)
    .lineLimit(2)
```

### 6. Reduce Motion
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion ? .none : .spring()
}

SomeView()
    .animation(animation, value: isPresented)
```

## Debugging Tips

### 1. Xcode Accessibility Inspector
```
Xcode → Open Developer Tool → Accessibility Inspector
- Inspection Mode: Hover over elements
- Audit: Run automated tests
- Settings: Simulate accessibility features
```

### 2. VoiceOver Testing (iOS)
```
Settings → Accessibility → VoiceOver → On
- Triple-click side button for quick toggle
- Two-finger swipe to read all
- Rotate two fingers for rotor navigation
- Three-finger swipe to scroll
```

### 3. Console Logging
```swift
#if DEBUG
AccessibilityTestingHelpers.inspectAccessibility(
    label: "Add",
    value: nil,
    hint: "Creates new item",
    traits: .isButton
)
#endif
```

### 4. Visual Debugging Overlay
```swift
#if DEBUG
ContentView()
    .accessibilityDebugOverlay()
// Shows touch target grid and element boundaries
#endif
```

## Performance Considerations

### Audit Performance
- Full audit: ~500ms for typical view hierarchy
- Runs on background thread
- Results cached until next scan
- No performance impact in production (DEBUG only)

### Best Practices
1. Run audits during development, not runtime
2. Use in-memory testing for unit tests
3. Enable debug overlays only when needed
4. Remove debug code before production builds

## Integration with CI/CD

### Automated Testing Script
```bash
#!/bin/bash
# run_accessibility_tests.sh

echo "Running accessibility tests..."

xcodebuild test \
    -scheme Itori \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:ItoriTests/AccessibilityTests \
    -quiet

if [ $? -eq 0 ]; then
    echo "✅ All accessibility tests passed"
    exit 0
else
    echo "❌ Accessibility tests failed"
    exit 1
fi
```

### GitHub Actions
```yaml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  accessibility:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Accessibility Tests
        run: ./run_accessibility_tests.sh
```

## Troubleshooting

### Issue: Audit finds no issues but UI inaccessible

**Solution:** The audit is heuristic-based. Always perform manual VoiceOver testing.

### Issue: Contrast tests failing for dynamic colors

**Solution:** Test in both light and dark modes. Use semantic colors that adapt.

### Issue: Touch target tests unreliable

**Solution:** Ensure GeometryReader measurements are accurate. Test on actual devices.

### Issue: Tests pass but VoiceOver still broken

**Solution:** Tests verify API usage, not runtime behavior. Manual testing essential.

## Resources

### Apple Documentation
- [Accessibility Programming Guide](https://developer.apple.com/accessibility/)
- [Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [SwiftUI Accessibility](https://developer.apple.com/documentation/swiftui/view-accessibility)

### WCAG Resources
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [WAVE Accessibility Evaluation Tool](https://wave.webaim.org/)

### Testing Tools
- Xcode Accessibility Inspector
- Color Contrast Analyzer (CCA)
- VoiceOver (iOS/macOS)
- Sim Daltonism (Color blindness simulator)

## File Structure

```
SharedCore/
├── Utilities/
│   ├── AccessibilityAudit.swift              # Audit engine
│   └── AccessibilityTestingHelpers.swift     # Testing utilities
└── Views/
    └── AccessibilityDebugPanel.swift         # Debug UI

Tests/
└── AccessibilityTests/
    └── AccessibilityTests.swift              # Unit tests
```

## Quick Reference

### Open Debug Panel
```swift
#if DEBUG
.sheet(isPresented: $showDebug) {
    AccessibilityDebugPanel()
}
#endif
```

### Run Audit
```swift
await AccessibilityAuditEngine.shared.runFullAudit()
```

### Check Contrast
```swift
let ratio = AccessibilityTestingHelpers.contrastRatio(
    foreground: fg, background: bg
)
let passesAA = ratio >= 4.5
```

### Test Touch Target
```swift
let size = CGSize(width: w, height: h)
let passes = AccessibilityTestingHelpers.meetsTouchTargetSize(size)
```

### Create Test Suite
```swift
var suite = AccessibilityTestSuite(viewName: "View")
suite.addTest(name: "Test", passed: true)
suite.printReport()
```

---

**Version:** 1.0  
**Last Updated:** 2026-01-03  
**Status:** Production Ready (DEBUG builds only)  
**WCAG Target:** Level AA
