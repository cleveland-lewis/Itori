# Advanced Testing Strategy: System Services & Complex Patterns

**Goal**: Test untestable system services and complex patterns through mocking, protocols, and integration tests to push coverage beyond 70%.

---

## Phase 6: System Service Mocking (Target: +5-8% coverage)

### 6.1 iCloud Sync Testing
**Strategy**: Mock CloudKit operations

**Files to Test**:
- `Shared/Models/Persistence/PersistenceController.swift`
- `Shared/Models/Persistence/CloudKitManager.swift`

**Approach**:
```swift
protocol CloudKitSyncable {
    func syncToCloud(data: Data) async throws
    func fetchFromCloud() async throws -> Data
}

// Mock implementation for tests
class MockCloudKitManager: CloudKitSyncable {
    var shouldFail = false
    var syncedData: Data?
    
    func syncToCloud(data: Data) async throws {
        if shouldFail { throw TestError.cloudKitFailed }
        syncedData = data
    }
}
```

**Test Coverage**:
- ✅ Successful sync scenarios
- ✅ Network failure handling
- ✅ Conflict resolution
- ✅ Background sync triggers
- ✅ Quota exceeded scenarios

**Implementation**: Create `CloudKitManagerTests.swift`

---

### 6.2 EventKit Integration Testing
**Strategy**: Mock EKEventStore

**Files to Test**:
- `Shared/Services/CalendarIntegrationService.swift`
- `Shared/Models/Calendar/EventKitBridge.swift`

**Approach**:
```swift
protocol EventStorable {
    func requestAccess() async -> Bool
    func fetchEvents(from: Date, to: Date) -> [EKEvent]
    func save(event: EKEvent) throws
}

class MockEventStore: EventStorable {
    var hasAccess = true
    var events: [EKEvent] = []
}
```

**Test Coverage**:
- ✅ Permission request flows
- ✅ Event creation/update/deletion
- ✅ Recurrence rule handling
- ✅ Calendar selection
- ✅ Access denied scenarios

**Implementation**: Create `EventKitBridgeTests.swift`

---

### 6.3 Biometric Auth Testing
**Strategy**: Mock LAContext

**Files to Test**:
- `Shared/Services/BiometricAuthService.swift`

**Approach**:
```swift
protocol BiometricAuthenticatable {
    func canEvaluatePolicy() -> Bool
    func evaluatePolicy(reason: String) async throws -> Bool
}

class MockBiometricAuth: BiometricAuthenticatable {
    var isAvailable = true
    var shouldSucceed = true
}
```

**Test Coverage**:
- ✅ Face ID available/unavailable
- ✅ Touch ID scenarios
- ✅ Auth success/failure
- ✅ Fallback to passcode
- ✅ Policy evaluation errors

**Implementation**: Create `BiometricAuthServiceTests.swift`

---

### 6.4 Push Notifications Testing
**Strategy**: Mock UNUserNotificationCenter

**Files to Test**:
- `Shared/Services/NotificationManager.swift`

**Approach**:
```swift
protocol NotificationSchedulable {
    func requestAuthorization() async throws -> Bool
    func schedule(notification: UNNotificationRequest) async throws
    func getPendingNotifications() async -> [UNNotificationRequest]
}

class MockNotificationCenter: NotificationSchedulable {
    var authorized = true
    var scheduled: [UNNotificationRequest] = []
}
```

**Test Coverage**:
- ✅ Permission requests
- ✅ Notification scheduling
- ✅ Delivery timing
- ✅ Custom sounds/badges
- ✅ Notification categories/actions

**Implementation**: Create `NotificationManagerTests.swift`

---

### 6.5 Network Monitoring Testing
**Strategy**: Mock NWPathMonitor

**Files to Test**:
- `Shared/Services/NetworkMonitor.swift`

**Approach**:
```swift
protocol NetworkMonitorable {
    var isConnected: Bool { get }
    var connectionType: NWInterface.InterfaceType? { get }
}

class MockNetworkMonitor: NetworkMonitorable {
    var isConnected = true
    var connectionType: NWInterface.InterfaceType? = .wifi
}
```

**Test Coverage**:
- ✅ WiFi/Cellular transitions
- ✅ Offline scenarios
- ✅ Connection quality changes
- ✅ VPN detection

**Implementation**: Create `NetworkMonitorTests.swift`

---

### 6.6 File System Watchers Testing
**Strategy**: Mock FileManager operations

**Files to Test**:
- `Shared/Services/FileWatcherService.swift`
- `Shared/Utilities/FileSystemMonitor.swift`

**Approach**:
```swift
protocol FileSystemWatchable {
    func startWatching(path: URL)
    func stopWatching()
}

class MockFileWatcher: FileSystemWatchable {
    var isWatching = false
    var watchedPath: URL?
}
```

**Test Coverage**:
- ✅ File creation/modification/deletion
- ✅ Directory monitoring
- ✅ Batch change detection
- ✅ Performance with many files

**Implementation**: Create `FileSystemMonitorTests.swift`

---

## Phase 7: Complex Coordinator Patterns (Target: +5% coverage)

### 7.1 PlannerCoordinator Testing
**Files to Test**:
- `Shared/ViewModels/PlannerCoordinator.swift`

**Test Coverage**:
- ✅ Multi-view navigation flows
- ✅ State preservation across views
- ✅ Deep linking
- ✅ Tab coordination
- ✅ Modal presentation

**Implementation**: Create `PlannerCoordinatorTests.swift`

---

### 7.2 AppCoordinator Testing
**Files to Test**:
- `Shared/ViewModels/AppCoordinator.swift`

**Test Coverage**:
- ✅ App lifecycle transitions
- ✅ Scene management
- ✅ Window restoration
- ✅ Multi-window coordination (iPad)

**Implementation**: Create `AppCoordinatorTests.swift`

---

### 7.3 NavigationCoordinator Testing
**Files to Test**:
- `Shared/Coordinators/NavigationCoordinator.swift`

**Test Coverage**:
- ✅ Push/pop navigation
- ✅ Sheet presentation
- ✅ Full screen covers
- ✅ Navigation stack management

**Implementation**: Create `NavigationCoordinatorTests.swift`

---

## Phase 8: Integration Tests (Target: +3-5% coverage)

### 8.1 End-to-End Workflow Tests
**Test Scenarios**:

1. **Assignment Creation → Scheduling → Completion Flow**
   - Create assignment
   - Auto-schedule in planner
   - Mark complete
   - Verify database state

2. **Course Enrollment → Assignment → Grade Calculation**
   - Add course
   - Add assignments
   - Enter grades
   - Verify GPA calculation

3. **Timer Session → Study Hours → Analytics**
   - Start Pomodoro session
   - Complete session
   - Verify study hours updated
   - Check analytics data

4. **Event Creation → Calendar Sync → Notification**
   - Create event in app
   - Mock EventKit sync
   - Schedule notification
   - Verify all systems updated

**Implementation**: Create `IntegrationTests/` directory

---

## Phase 9: Edge Case & Error Recovery (Target: +2-3% coverage)

### 9.1 Error Handling Tests
**Focus Areas**:
- Database corruption recovery
- Network timeout handling
- Concurrent access conflicts
- Memory pressure scenarios
- Disk space exhaustion

### 9.2 Boundary Condition Tests
**Focus Areas**:
- Maximum data limits
- Empty state handling
- Invalid input validation
- Date boundary conditions (year 2038, etc.)

**Implementation**: Add to existing test files or create `EdgeCaseTests.swift`

---

## Implementation Timeline

### Week 1: System Service Mocking
- Day 1-2: iCloud & EventKit mocks
- Day 3-4: Biometric & Notifications
- Day 5: Network & File System

### Week 2: Coordinators & Integration
- Day 1-2: Coordinator pattern tests
- Day 3-4: Integration tests
- Day 5: Edge cases & cleanup

---

## Measurement Strategy

### Coverage Tracking
```bash
# Run with coverage
xcodebuild test \
  -scheme Roots \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# Generate report
xcrun xccov view --report TestResults.xcresult
```

### Target Metrics
- **Phase 6**: 60% → 68%
- **Phase 7**: 68% → 73%
- **Phase 8**: 73% → 78%
- **Phase 9**: 78% → 80%+

---

## Testing Best Practices

### 1. Mock Protocol Design
```swift
// ✅ Good: Protocol-based
protocol DataSyncable {
    func sync() async throws
}

// ❌ Bad: Concrete implementation
class CloudKitManager {
    func sync() async throws { ... }
}
```

### 2. Dependency Injection
```swift
// ✅ Good: Injected dependencies
class ViewModel {
    let syncService: DataSyncable
    init(syncService: DataSyncable) {
        self.syncService = syncService
    }
}

// ❌ Bad: Hard-coded dependencies
class ViewModel {
    let syncService = CloudKitManager()
}
```

### 3. Test Isolation
```swift
override func setUp() {
    super.setUp()
    // Create fresh mocks for each test
    mockSync = MockSyncService()
    viewModel = ViewModel(syncService: mockSync)
}

override func tearDown() {
    // Clean up
    mockSync = nil
    viewModel = nil
    super.tearDown()
}
```

---

## Success Criteria

✅ **Phase 6 Complete**: All system services have mock implementations and tests
✅ **Phase 7 Complete**: All coordinator patterns tested with navigation flows
✅ **Phase 8 Complete**: 5+ end-to-end integration tests passing
✅ **Phase 9 Complete**: Edge cases documented and tested
✅ **Overall Goal**: 70%+ code coverage achieved

---

## Progress Update (2026-01-01)

### ✅ Phase 6 Mocks & Tests Created
- MockCloudKitManager.swift - iCloud sync mocking (45 tests potential)
- MockEventStore.swift - EventKit mocking 
- MockBiometricAuth.swift - Biometric auth  
- MockNetworkMonitor.swift - Network monitoring
- MockFileWatcher.swift - File system watching
- CloudKitManagerTests.swift - 12 tests for iCloud sync ✅
- BiometricAuthServiceTests.swift - 16 tests for biometric auth ✅
- NetworkMonitorTests.swift - 18 tests for network states ✅
- FileWatcherTests.swift - 15 tests for file monitoring ✅
- **Total New Tests: 61 tests**

### 🔄 Next Priority (Complete Phase 6)
- EventKitBridgeTests.swift - Need to create
- NotificationManagerTests.swift - Need to create (MockNotificationCenter exists)
- Run full test suite to verify all new tests pass
- Measure code coverage improvement

### ⏳ Remaining Phases
- Phase 7: Coordinator patterns (PlannerCoordinator, AppCoordinator, NavigationCoordinator)
- Phase 8: Integration tests (5+ end-to-end workflows)
- Phase 9: Edge cases & error recovery

### 📊 ROI Assessment
**High ROI**: Phase 6 system services - These mocks enable testing of previously untestable code paths
**Medium ROI**: Phase 7 coordinators - Complex but critical navigation logic
**Lower ROI**: Phase 8-9 - Diminishing returns after 70% coverage

## Next Actions
1. Create EventKitBridgeTests.swift & NotificationManagerTests.swift
2. Run complete test suite and fix any issues
3. Generate coverage report
4. Decide: Continue to Phase 7 if coverage < 70%
