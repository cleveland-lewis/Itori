# Testing Quick Start Guide

## Run All Tests
```bash
xcodebuild test -project ItoriApp.xcodeproj -scheme ItoriUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Run Stress Tests Only
```bash
xcodebuild test -project ItoriApp.xcodeproj -scheme ItoriUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ItoriUITests/ComprehensiveStressTests
```

## Run Data Integrity Tests Only
```bash
xcodebuild test -project ItoriApp.xcodeproj -scheme ItoriUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ItoriUITests/DataIntegrityTests
```

## What Gets Tested

### ComprehensiveStressTests
- 8 years (16 semesters) of data
- 7-course heavy loads
- 50+ assignments
- GPA calculations
- Calendar/planner stress
- Memory pressure

### DataIntegrityTests  
- Data persistence across launches
- Unicode/special characters
- Edge cases (max length, duplicates)
- Complete workflows
- Empty states
- Search/filter performance

## Next Steps

1. **Update test selectors** in `ComprehensiveStressTests.swift` to match your UI
2. **Add accessibility IDs** to app UI elements
3. **Run tests** and fix any failures
4. **Integrate into CI/CD** pipeline

See `UI_TEST_RESTORATION_COMPLETE.md` for full details.
