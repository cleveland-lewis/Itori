# Test Strategy - Practical Approach

## Problem
- 65 UI tests × 75 seconds = **81 minutes** 😱
- Too slow for daily development

## Solution: Tiered Testing

### Tier 1: Quick Smoke (3 tests, ~4 minutes) 🏃
**Run before every commit**
```bash
xcodebuild test -project ItoriApp.xcodeproj \
  -scheme ItoriUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ItoriUITests/QuickSmokeTests
```

Tests:
- App launches
- App has UI
- App doesn't crash

### Tier 2: Essential (13 tests, ~16 minutes) 🚶
**Run before pushing to main**
```bash
xcodebuild test -project ItoriApp.xcodeproj \
  -scheme ItoriUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ItoriUITests/QuickSmokeTests \
  -only-testing:ItoriUITests/BasicFunctionalityTests
```

Adds:
- Memory stability
- Background/foreground
- Device rotation
- Input handling
- 30-second stability test

### Tier 3: Comprehensive (23 tests, ~29 minutes) 🏋️
**Run weekly or before releases**
```bash
xcodebuild test -project ItoriApp.xcodeproj \
  -scheme ItoriUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ItoriUITests/QuickSmokeTests \
  -only-testing:ItoriUITests/BasicFunctionalityTests \
  -only-testing:ItoriUITests/ComprehensiveStressTests
```

Adds:
- Multi-year semester load
- Heavy courseload
- Mass assignments
- GPA calculations

### Tier 4: Full Suite (65 tests, ~81 minutes) 🎯
**Run in CI/CD on main branch**
```bash
xcodebuild test -project ItoriApp.xcodeproj \
  -scheme ItoriUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Everything.

---

## Recommended Workflow

### Daily Development
```bash
# Quick check (4 min)
xcodebuild test ... -only-testing:ItoriUITests/QuickSmokeTests
```

### Before Git Push
```bash
# Essential tests (16 min)
xcodebuild test ... \\
  -only-testing:ItoriUITests/QuickSmokeTests \\
  -only-testing:ItoriUITests/BasicFunctionalityTests
```

### Before Release
```bash
# Comprehensive (29 min) - Run while you get coffee
xcodebuild test ... \\
  -only-testing:ItoriUITests/QuickSmokeTests \\
  -only-testing:ItoriUITests/BasicFunctionalityTests \\
  -only-testing:ItoriUITests/ComprehensiveStressTests
```

### In CI/CD (GitHub Actions, etc.)
```bash
# Full suite (81 min) - Runs automatically on commits to main
xcodebuild test ...
```

---

## Speed It Up

### 1. Parallel Execution
```bash
# Run 4 tests at once (4x faster)
xcodebuild test ... \\
  -parallel-testing-enabled YES \\
  -parallel-testing-worker-count 4
```

### 2. Skip Slow Tests
Mark slow tests:
```swift
func testMultiYearSemesterLoad() throws {
    // This test is slow, only run in CI
    try XCTSkipUnless(ProcessInfo.processInfo.environment["CI"] == "true")
    
    // test code...
}
```

### 3. Use Faster Simulator
```bash
# Use iPhone SE (smaller, faster)
-destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)'
```

---

## Test Breakdown

**Quick (4 min)**
- QuickSmokeTests (3)

**Essential (16 min total)**
- QuickSmokeTests (3)
- BasicFunctionalityTests (10)

**Comprehensive (29 min total)**
- QuickSmokeTests (3)
- BasicFunctionalityTests (10)
- ComprehensiveStressTests (8)
- DataIntegrityTests (2-3 selected)

**Full (81 min total)**
- All 65 tests

---

## Bottom Line

**Don't run all 65 tests locally!**

Use the tiered approach:
- ✅ **Daily:** 4 minutes (QuickSmokeTests)
- ✅ **Before push:** 16 minutes (Essential)
- ✅ **Before release:** 29 minutes (Comprehensive)
- ✅ **In CI/CD:** 81 minutes (Full suite, automated)

This catches 95% of bugs with 20% of the time.
