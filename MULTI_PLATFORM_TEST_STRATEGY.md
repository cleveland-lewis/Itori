# Multi-Platform Test Strategy
**Goal**: Extend test coverage to macOS, iPadOS, and watchOS platforms

## Current Status
- ✅ iOS tests well-established (~70% coverage target)
- ❌ macOS-specific features untested
- ❌ iPadOS adaptations untested  
- ❌ watchOS connectivity/sync untested

## Platform-Specific Testing Plan

### Phase 1: macOS App Testing (High ROI)
**Target**: Test macOS-specific UI and features

#### A. macOS Window Management
- [x] Multiple windows (assignment detail, settings)
- [x] Window restoration state
- [x] Menu bar integration
- [ ] Keyboard shortcuts

**Files to test**:
- `Platforms/macOS/Scenes/Shared/MultiWindowScenes.swift`
- `Platforms/macOS/ViewModels/MenuBarViewModel.swift`

**Test file**: `Tests/Unit/RootsTests/Platform/macOSWindowManagementTests.swift`

#### B. macOS-Specific Views
- [ ] MenuBarViewModel behavior
- [ ] macOS settings adaptations
- [ ] Toolbar customization

**Files to test**:
- `Platforms/macOS/Scenes/SettingsView.swift`
- `Platforms/macOS/Scenes/PlannerSettingsView.swift`

**Test file**: `Tests/Unit/RootsTests/Platform/macOSViewTests.swift`

### Phase 2: iPadOS Adaptations (Medium ROI)
**Target**: Test iPad-specific layouts and features

#### A. Split View / Multitasking
- [ ] Split view layout adaptations
- [ ] Drag & drop between apps
- [ ] Slide over compatibility

#### B. Pencil Support
- [ ] Drawing/annotation features (if any)
- [ ] Scribble input handling

**Test file**: `Tests/Unit/RootsTests/Platform/iPadOSAdaptationTests.swift`

### Phase 3: watchOS Connectivity (Targeted ROI)
**Target**: Test basic watch sync and connectivity

#### A. Watch Connectivity
- [ ] Session activation/deactivation
- [ ] Message sending/receiving
- [ ] Context transfer
- [ ] Error handling

**Files to test**:
- `Platforms/watchOS/` connectivity code
- Watch-iPhone data sync

**Test file**: `Tests/Unit/RootsTests/Platform/watchOSConnectivityTests.swift`

#### B. Watch Complications (Optional)
- [ ] Complication data updates
- [ ] Timeline generation

## Implementation Strategy

### 1. Create Platform Test Infrastructure
```swift
// Tests/Unit/RootsTests/Platform/PlatformTestBase.swift
class PlatformTestBase: XCTestCase {
    #if os(macOS)
    // macOS-specific setup
    #elseif os(iOS)
    // iOS/iPadOS-specific setup
    #elseif os(watchOS)
    // watchOS-specific setup
    #endif
}
```

### 2. Conditional Compilation for Platform Tests
Use `#if os(...)` to separate platform-specific tests

### 3. Mock Platform Services
- Mock NSWindow for macOS
- Mock UIScene for iPadOS
- Mock WCSession for watchOS

## ROI Assessment

### High Value (Do First)
1. **macOS window management** - Critical for multi-window app
2. **macOS menu bar** - Key differentiator feature
3. **watchOS connectivity basics** - Core watch functionality

### Medium Value (Do If Time)
4. **iPadOS split view** - Nice to have, fewer users
5. **macOS keyboard shortcuts** - Already tested via unit tests
6. **Watch complications** - Low usage feature

### Low Value (Skip for Now)
7. **Platform-specific animations** - Visual testing not critical
8. **Hardware-specific features** - Require physical devices

## Test Execution Plan

### Step 1: Audit Platform Files (30 min)
- Identify all platform-specific Swift files
- Categorize by testability
- Prioritize by user impact

### Step 2: Create Platform Test Structure (1 hour)
- Create `Tests/Unit/RootsTests/Platform/` directory
- Set up base classes with conditional compilation
- Create mock infrastructure

### Step 3: Implement macOS Tests (2-3 hours)
- Window management tests
- Menu bar tests
- Settings view tests

### Step 4: Implement watchOS Tests (1-2 hours)
- Connectivity mock tests
- Data sync tests
- Error handling tests

### Step 5: Implement iPadOS Tests (1 hour)
- Layout adaptation tests
- Multitasking tests

## Success Metrics
- ✅ 50%+ coverage of macOS-specific code
- ✅ 40%+ coverage of watchOS connectivity
- ✅ 30%+ coverage of iPadOS adaptations
- ✅ All platform tests passing on CI

## Next Steps
1. Review this plan
2. Run audit of platform-specific files
3. Start with Phase 1A (macOS Window Management)
