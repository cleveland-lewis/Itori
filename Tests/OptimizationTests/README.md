# Optimization Tests

Automated performance, memory, and optimization testing framework.

## Directory Structure

```
OptimizationTests/
├── PerformanceTests/     # Execution time and CPU usage tests
├── MemoryTests/          # Memory leak and allocation tests
├── Seeds/                # Deterministic test data factories
└── Baselines/            # Performance baseline configurations
```

## Running Tests

### All Optimization Tests
```bash
xcodebuild test -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:ItoriTests/OptimizationTests
```

### Performance Tests Only
```bash
xcodebuild test -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:ItoriTests/OptimizationTests/PerformanceTests
```

### Memory Tests Only
```bash
xcodebuild test -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:ItoriTests/OptimizationTests/MemoryTests
```

### On Physical Device (Recommended)
```bash
xcodebuild test -scheme Itori -destination 'platform=iOS,id=<device-id>' -only-testing:ItoriTests/OptimizationTests
```

## Performance Baselines

Current baselines (update after optimization work):

### UI Performance
- Dashboard Load: **100ms**
- Assignment Filtering: **50ms**
- Chart Generation: **80ms**
- List Scrolling (100 items): **150ms**
- Search: **30ms**
- Task Creation: **20ms**
- Bulk Update (10 items): **100ms**

### Memory Usage
- AssignmentsStore (100 items): **5MB**
- CoursesStore (50 items): **3MB**
- PlannerStore (100 sessions): **6MB**
- FlashcardManager (200 cards): **4MB**
- Large Dataset (1000 items): **50MB**

## Test Data

Tests use deterministic seed-based data generation:
- **Small**: 10 courses, 50 assignments
- **Medium**: 50 courses, 200 assignments  
- **Large**: 100 courses, 1000 assignments
- **XLarge**: 200 courses, 5000 assignments

## CI Integration

### GitHub Actions (Recommended)
```yaml
- name: Run Optimization Tests
  run: |
    xcodebuild test \
      -scheme Itori \
      -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
      -only-testing:ItoriTests/OptimizationTests \
      -resultBundlePath TestResults.xcresult
    
- name: Upload Results
  uses: actions/upload-artifact@v4
  with:
    name: optimization-results
    path: TestResults.xcresult
```

### Performance Regression Detection
```yaml
- name: Check Performance Regression
  run: |
    # Compare against baseline
    swift test-results-compare \
      --baseline Baselines/performance-baseline.json \
      --current TestResults.xcresult \
      --threshold 1.2  # Fail if 20% slower
```

## Instruments Integration

For detailed profiling, use Instruments:

```bash
# Time Profiler
xcodebuild test -scheme Itori \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:ItoriTests/OptimizationTests/PerformanceTests \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# Open in Instruments
open TestResults.xcresult
```

### Memory Graph
```bash
# Generate memory graph during tests
xcodebuild test -scheme Itori \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:ItoriTests/OptimizationTests/MemoryTests \
  -enableAddressSanitizer YES \
  -enableThreadSanitizer NO
```

## Best Practices

1. **Always run on physical devices** for accurate performance measurements
2. **Use consistent test data** via TestDataFactory seeds
3. **Run tests multiple times** to account for variance
4. **Update baselines** after confirmed optimizations
5. **Monitor trends** over time, not just absolute values

## Debugging Slow Tests

### Identify Bottlenecks
```bash
xcodebuild test -scheme Itori \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:ItoriTests/OptimizationTests/PerformanceTests/UIPerformanceTests/testDashboardInitialLoad \
  -enableCodeCoverage YES
```

### Profile with Instruments
1. Run test in Xcode (⌘U)
2. Profile Test (⌘I)
3. Choose Time Profiler or Allocations
4. Analyze hot paths

## Continuous Improvement

### Weekly Tasks
- [ ] Review optimization test results
- [ ] Identify performance regressions
- [ ] Update baselines after optimizations
- [ ] Add tests for new features

### Monthly Tasks
- [ ] Run full optimization suite on physical devices
- [ ] Generate performance trend reports
- [ ] Review and update thresholds
- [ ] Archive baseline history

## Contact

For optimization test questions or baseline updates, contact the core team.
