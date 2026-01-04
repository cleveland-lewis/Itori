# Test Coverage Audit - Itori App

## Current Test Files (12)
1. AccessibilityInfrastructureTests.swift ✅
2. CalendarRecurrenceTests.swift ✅
3. DesignSystemConsistencyTests.swift ✅
4. DragDropHandlerTests.swift ⚠️
5. DragDropTypesTests.swift ✅
6. LocalizationValidationTests.swift ✅
7. PlannerEngineTests.swift ✅
8. ItoriTests.swift (empty placeholder)
9. StudyHoursTrackerTests.swift ✅
10. TabBarPreferencesStoreTests.swift
11. TimerPagePerformanceTests.swift ✅
12. TimerPageViewModelTests.swift ✅

## Coverage Analysis

### ✅ Well Covered Areas
- Timer functionality (ViewModel, Performance)
- Localization system
- Accessibility infrastructure
- Design system consistency
- Calendar recurrence
- Study hours tracking
- Drag & drop types

### ❌ Missing Critical Test Coverage

#### Core Business Logic (HIGH PRIORITY)
- [ ] **AssignmentsStore** - Task management, CRUD operations
- [ ] **PlannerStore** - Schedule generation, planning logic
- [ ] **CoursesStore** - Course management, semester handling
- [ ] **PracticeTestStore** - Test generation, scoring

#### AI/ML Features (HIGH PRIORITY)
- [ ] **AIEngine** - AI routing, fallback logic, error handling
- [ ] **AIScheduler** - Task scheduling algorithm
- [ ] **AIPrivacyGate** - Privacy enforcement
- [ ] **HealthMonitor** - AI health monitoring

#### Data Persistence (HIGH PRIORITY)
- [ ] **PersistenceController** - Core Data operations
- [ ] **iCloud sync** - Data synchronization
- [ ] **Migration logic** - Data model migrations

#### Critical Services (MEDIUM PRIORITY)
- [ ] **AudioFeedbackService** - Sound playback (recently fixed)
- [ ] **NotificationManager** - Notification scheduling
- [ ] **CalendarRefreshCoordinator** - Calendar sync
- [ ] **BackgroundRefreshManager** - Background tasks

#### Models (MEDIUM PRIORITY)
- [ ] **AppTask** - Task model operations
- [ ] **Course** - Course model
- [ ] **Semester** - Semester model
- [ ] **PlannerBlock** - Scheduling blocks

#### UI State Management (MEDIUM PRIORITY)
- [ ] **AppModel** - Global app state
- [ ] **AppSettingsModel** - Settings persistence
- [ ] **ModalRouter** - Navigation routing

#### Utilities (LOW PRIORITY)
- [ ] **DateFormatters** - Date formatting
- [ ] **LocalizationManager** - Already partially tested
- [ ] **DebugLogger** - Logging system

## Recommendations

### 1. Establish Test Architecture
Create test base classes and utilities:
- `BaseTestCase.swift` - Common setup/teardown
- `MockDataFactory.swift` - Consistent test data
- `TestHelpers.swift` - Shared assertions

### 2. Priority 1: Core Business Logic Tests
```swift
AssignmentsStoreTests.swift
- testCreateTask()
- testUpdateTask()
- testDeleteTask()
- testTaskCompletion()
- testRecurrenceHandling()
- testTaskDueDateCalculation()

CoursesStoreTests.swift
- testCreateCourse()
- testDeleteCourse()
- testSemesterManagement()
- testCourseArchival()

PlannerStoreTests.swift
- testScheduleGeneration()
- testBlockAllocation()
- testConflictResolution()
- testOverflowHandling()
```

### 3. Priority 2: AI Engine Tests
```swift
AIEngineTests.swift
- testAIRouting()
- testFallbackBehavior()
- testPrivacyEnforcement()
- testProviderSelection()
- testErrorHandling()

AISchedulerTests.swift
- testTaskPrioritization()
- testTimeAllocation()
- testBreakInsertion()
- testConstraintHandling()
```

### 4. Priority 3: Data Persistence Tests
```swift
PersistenceControllerTests.swift
- testCoreDataSetup()
- testCloudKitSync()
- testErrorRecovery()
- testMigration()
- testTimestampHandling() ✅ (partially covered)

iCloudSyncTests.swift
- testConflictResolution()
- testSyncScheduling()
- testOfflineMode()
```

### 5. Test Infrastructure Improvements

#### A. Test Data Builders
```swift
// MockDataFactory.swift
class MockDataFactory {
    static func createTask(
        title: String = "Test Task",
        due: Date = Date(),
        courseId: UUID? = nil
    ) -> AppTask { ... }
    
    static func createCourse(...) -> Course { ... }
    static func createSemester(...) -> Semester { ... }
}
```

#### B. Test Doubles
```swift
// Mocks/
- MockPersistenceController.swift
- MockAIProvider.swift
- MockNotificationCenter.swift
- MockUserDefaults.swift
```

#### C. Integration Test Suite
```swift
IntegrationTests/
- EndToEndSchedulingTests.swift
- DataSyncIntegrationTests.swift
- AIWorkflowTests.swift
```

### 6. Continuous Testing Strategy

#### Auto-generate test stubs for new code:
```swift
// Add to project: generate_test_stubs.sh
#!/bin/bash
# Scans for new Swift files without corresponding tests
# Generates test file templates automatically
```

#### Code coverage requirements:
- Critical paths: 80%+ coverage
- Business logic: 70%+ coverage
- UI components: 50%+ coverage
- Utilities: 60%+ coverage

#### Test execution:
- Run unit tests on every commit (pre-commit hook)
- Run integration tests on PR
- Run full suite nightly

### 7. Test Categories via @tags

```swift
// Fast unit tests
@Test(.tags(.unit, .fast))
func testSimpleCalculation() { }

// Integration tests  
@Test(.tags(.integration))
func testDatabaseOperations() { }

// Slow tests
@Test(.tags(.performance))
func testLargeDataset() { }
```

## Metrics to Track

1. **Code Coverage**: Currently unknown, target 70%+
2. **Test Execution Time**: < 30s for unit tests
3. **Flaky Test Rate**: < 1%
4. **Test-to-Code Ratio**: Target 1:3 (1 test file per 3 source files)

## Action Items

- [ ] Create test infrastructure (base classes, factories)
- [ ] Add AssignmentsStore tests (highest priority)
- [ ] Add PlannerStore tests
- [ ] Add AIEngine tests
- [ ] Add PersistenceController tests
- [ ] Set up code coverage reporting
- [ ] Configure pre-commit test hooks
- [ ] Document testing guidelines in CONTRIBUTING.md
