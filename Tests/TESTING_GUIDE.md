# Roots Testing Guide

## Overview

This guide ensures Roots maintains high test coverage and quality as the codebase evolves.

## Test Architecture

### Directory Structure

```
Tests/
├── Unit/
│   └── RootsTests/
│       ├── Infrastructure/          # Test base classes and utilities
│       │   ├── BaseTestCase.swift
│       │   └── MockDataFactory.swift
│       ├── Mocks/                   # Mock implementations
│       ├── [Feature]Tests.swift     # Feature-specific tests
│       └── TestCoverageAudit.md
└── RootsUITests/                    # UI automation tests
```

### Test Categories

**Unit Tests** (Tests/Unit/RootsTests/)
- Fast, isolated tests
- No external dependencies
- Test individual functions/methods
- Target: Run in < 30 seconds

**Integration Tests** (Tests/Unit/RootsTests/Integration/)
- Test multiple components together
- May use real Core Data, UserDefaults
- Test data flow between components
- Target: Run in < 2 minutes

**UI Tests** (Tests/RootsUITests/)
- End-to-end user workflows
- Real app instance
- Test user interactions
- Target: Run in < 10 minutes

## Writing Tests

### 1. Use BaseTestCase

All tests should inherit from `BaseTestCase` for common utilities:

```swift
@MainActor
final class MyFeatureTests: BaseTestCase {
    var subject: MyFeature!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        subject = MyFeature()
    }
    
    override func tearDownWithError() throws {
        subject = nil
        try super.tearDownWithError()
    }
}
```

### 2. Use MockDataFactory

Create test data consistently:

```swift
func testTaskCreation() {
    // Given
    let task = mockData.createTask(
        title: "Test Task",
        estimatedMinutes: 60
    )
    
    // When
    store.addTask(task)
    
    // Then
    XCTAssertEqual(store.tasks.count, 1)
}
```

### 3. Follow Given-When-Then

Structure tests clearly:

```swift
func testUserAction() {
    // Given - Set up the test state
    let initialState = setupInitialState()
    
    // When - Perform the action
    subject.performAction()
    
    // Then - Verify the result
    XCTAssertEqual(subject.state, expectedState)
}
```

### 4. Test Edge Cases

Always test:
- Nil/empty values
- Boundary conditions (0, max, negative)
- Invalid input
- Error conditions
- Concurrent operations

```swift
func testEdgeCases() {
    // Test nil
    let nilResult = subject.process(nil)
    XCTAssertNil(nilResult)
    
    // Test empty
    let emptyResult = subject.process([])
    XCTAssertEqual(emptyResult.count, 0)
    
    // Test boundary
    let maxResult = subject.process(Int.max)
    XCTAssertNotNil(maxResult)
}
```

## Code Coverage Requirements

### Minimum Coverage Targets

- **Critical Business Logic**: 80%+
  - AssignmentsStore, PlannerStore, CoursesStore
  - AI scheduling algorithms
  - Data persistence layer

- **Services**: 70%+
  - AudioFeedbackService, NotificationManager
  - CalendarRefreshCoordinator

- **Models**: 60%+
  - AppTask, Course, Semester
  - Validation logic

- **UI ViewModels**: 60%+
  - TimerPageViewModel, etc.

- **Utilities**: 60%+
  - Date formatters, helpers

### Measuring Coverage

```bash
# Run tests with coverage
xcodebuild test \
  -scheme Roots \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# View coverage report
xcrun xccov view --report TestResults.xcresult
```

## Automated Test Generation

### Generate Test Stubs

For any new Swift file without tests:

```bash
./Scripts/generate_test_stub.sh SharedCore/State/NewFeature.swift
```

This creates `Tests/Unit/RootsTests/NewFeatureTests.swift` with:
- Proper structure
- Test method stubs
- TODO comments

### Pre-Commit Hook

Install to run tests before commits:

```bash
cp Scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

The hook:
1. Runs unit tests
2. Checks for untested files
3. Validates test naming conventions
4. Blocks commit if tests fail

## Test Naming Conventions

### File Names
- Test file: `[SourceFile]Tests.swift`
- Example: `AssignmentsStore.swift` → `AssignmentsStoreTests.swift`

### Test Method Names
- Pattern: `test[MethodName][Scenario][ExpectedResult]`
- Examples:
  - `testCreateTaskWithValidData()`
  - `testUpdateTaskThrowsErrorWhenNotFound()`
  - `testDeleteTaskRemovesFromStore()`

### Test Class Names
- Pattern: `[SourceClass]Tests`
- Example: `final class AssignmentsStoreTests: BaseTestCase`

## Mocking Guidelines

### When to Mock

Mock external dependencies:
- Network calls
- File system operations
- Core Data (for unit tests)
- UserDefaults
- Notification center
- Date/time (for consistency)

### How to Mock

Create protocol-based mocks:

```swift
// Protocol
protocol TaskRepository {
    func fetchTasks() async throws -> [AppTask]
}

// Mock implementation
class MockTaskRepository: TaskRepository {
    var tasksToReturn: [AppTask] = []
    var shouldThrowError = false
    
    func fetchTasks() async throws -> [AppTask] {
        if shouldThrowError {
            throw NSError(domain: "test", code: 1)
        }
        return tasksToReturn
    }
}

// Use in test
func testFetchTasks() async throws {
    // Given
    let mock = MockTaskRepository()
    mock.tasksToReturn = [mockData.createTask()]
    let subject = ViewModel(repository: mock)
    
    // When
    try await subject.loadTasks()
    
    // Then
    XCTAssertEqual(subject.tasks.count, 1)
}
```

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -scheme Roots \
            -destination 'platform=macOS' \
            -only-testing:RootsTests
      - name: Check Coverage
        run: |
          xcrun xccov view --report TestResults.xcresult \
            | grep "Coverage: " \
            | awk '{if ($2 < 70.0) exit 1}'
```

## Testing Checklist

When adding a new feature:

- [ ] Create test file using `generate_test_stub.sh`
- [ ] Write tests for happy path
- [ ] Write tests for edge cases
- [ ] Write tests for error conditions
- [ ] Add integration tests if multiple components involved
- [ ] Update TestCoverageAudit.md
- [ ] Run tests locally: `xcodebuild test -scheme Roots -only-testing:RootsTests`
- [ ] Check coverage meets minimum requirements
- [ ] Add UI tests for user-facing features

## Common Testing Patterns

### Testing Async Code

```swift
func testAsyncOperation() async throws {
    // Given
    let subject = MyAsyncService()
    
    // When
    let result = try await subject.performOperation()
    
    // Then
    XCTAssertEqual(result, expectedValue)
}
```

### Testing Published Properties

```swift
func testPublishedPropertyChanges() throws {
    // Given
    let subject = MyViewModel()
    let expectation = XCTestExpectation(description: "Property changed")
    
    let cancellable = subject.$property
        .dropFirst()
        .sink { value in
            XCTAssertEqual(value, expectedValue)
            expectation.fulfill()
        }
    
    // When
    subject.changeProperty()
    
    // Then
    wait(for: [expectation], timeout: 1.0)
}
```

### Testing Date-Dependent Code

```swift
func testDateCalculation() {
    // Given - Use fixed date for consistency
    let fixedDate = date(year: 2024, month: 1, day: 15)
    
    // When
    let result = subject.calculateDueDate(from: fixedDate)
    
    // Then
    assertDatesEqual(result, date(year: 2024, month: 1, day: 22))
}
```

## Troubleshooting

### Tests Hang
- Check for unresolved expectations
- Look for infinite loops or deadlocks
- Add timeout to async operations

### Flaky Tests
- Eliminate timing dependencies
- Use fixed dates instead of `Date()`
- Mock random number generators
- Avoid testing implementation details

### Slow Tests
- Check for unnecessary `sleep()` calls
- Use in-memory Core Data for tests
- Mock slow dependencies
- Consider moving to integration tests

## Resources

- **Test Files**: `Tests/Unit/RootsTests/`
- **Coverage Report**: `TestResults.xcresult`
- **CI Logs**: GitHub Actions
- **Coverage Audit**: `TestCoverageAudit.md`

## Questions?

See existing tests for examples or contact the team.
