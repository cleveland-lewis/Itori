# Two Types of Tests - VERY Different!

## You Have TWO Test Schemes

### 1. ItoriTests (Unit Tests) ⚡
**315 tests - FAST!**
- Test individual functions/classes
- No app launch required
- Run in **seconds** not minutes
- **Total time: 2-5 minutes** for all 315!

```bash
# Run all 315 unit tests (fast!)
xcodebuild test -project ItoriApp.xcodeproj \
  -scheme ItoriTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**What they test:**
- Business logic
- Data models
- Calculations (GPA, etc.)
- Utilities
- Managers

### 2. ItoriUITests (UI Tests) 🐌
**65 tests - SLOW!**
- Launch full app in simulator
- Test actual UI interactions
- Run in **75+ seconds each**
- **Total time: 81 minutes** for all 65

```bash
# Run all 65 UI tests (slow!)
xcodebuild test -project ItoriApp.xcodeproj \
  -scheme ItoriUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**What they test:**
- App launching
- UI interactions
- Navigation
- User workflows

---

## Recommended Workflow

### Daily Development
```bash
# Run unit tests (2-5 min) - Do this all the time!
xcodebuild test -scheme ItoriTests ...

# Run quick UI smoke tests (4 min) - Do before commits
./run-quick-tests.sh
```

### Before Release
```bash
# Run all unit tests (5 min)
xcodebuild test -scheme ItoriTests ...

# Run essential UI tests (16 min)
xcodebuild test -scheme ItoriUITests ... \
  -only-testing:ItoriUITests/QuickSmokeTests \
  -only-testing:ItoriUITests/BasicFunctionalityTests
```

### In CI/CD
```bash
# Run everything (90 min total)
xcodebuild test -scheme ItoriTests ...  # 5 min
xcodebuild test -scheme ItoriUITests ... # 81 min
```

---

## Bottom Line

**You were looking at the FAST tests (315 unit tests)!**

- ✅ **ItoriTests (315 unit tests):** 2-5 minutes total - Run all the time!
- ⏱️ **ItoriUITests (65 UI tests):** 81 minutes total - Run selectively

**The 315 unit tests are fine to run regularly - they're fast!**
