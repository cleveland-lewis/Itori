# Test Coverage Status - Itori App

**Date**: December 31, 2024  
**Current Coverage**: 8.33% (8,457 of 101,543 lines)  
**Target**: 70%

---

## Summary

Tests compile and run successfully, but **coverage is only 8.33%** because the app architecture prevents effective unit testing.

### What's Working
- ✅ 19 test files execute without errors
- ✅ Test infrastructure (BaseTestCase, MockDataFactory) in place
- ✅ Tests themselves have 92% coverage
- ✅ AttachmentTests, CalendarRecurrenceTests, TimerTests passing

### Root Cause: Architecture Not Test-Friendly

**Problem**: Core stores use singleton pattern with private initializers
```swift
// AssignmentsStore.swift
final class AssignmentsStore: ObservableObject {
    static let shared = AssignmentsStore()
    private init() { ... }  // ❌ Can't create test instances
}
```

**Impact**: 
- Can't inject test doubles
- Can't isolate units under test
- Tests exercise test code, not app code
- Coverage stuck at ~8%

---

## Options to Reach 70% Coverage

### Option A: Refactor for Testability ⭐ **Recommended**
**Approach**: Add dependency injection without breaking existing code

**Changes needed**:
1. Add protocols for stores (`AssignmentsStoring`, `CoursesStoring`)
2. Add test-only initializers: `init(forTesting: Bool)`
3. Inject dependencies via initializers
4. Keep `.shared` for production use

**Pros**:
- Achieves 70%+ coverage
- Improves code quality
- Enables proper unit testing

**Cons**:
- 2-3 days of refactoring
- Risk of introducing bugs
- Requires careful migration

**Estimated effort**: 16-24 hours

---

### Option B: Integration Testing 🔶 **Faster Alternative**
**Approach**: Test through the UI layer using existing singletons

**Changes needed**:
1. Use `.shared` instances in tests
2. Reset state between tests
3. Test end-to-end flows
4. Focus on critical paths

**Pros**:
- Works with current architecture
- Tests real scenarios
- 1-2 days of work

**Cons**:
- Only reaches ~30-40% coverage
- Tests are slower
- Harder to debug failures

**Estimated effort**: 8-16 hours

---

### Option C: Pragmatic Approach 🟢 **Current Reality**
**Approach**: Keep current 8% coverage, add tests incrementally

**Strategy**:
- Add tests when fixing bugs
- Test new features as they're built
- Focus on business-critical code
- Don't refactor solely for testing

**Pros**:
- No disruption
- Low risk
- Steady improvement

**Cons**:
- Coverage stays low (~10-20%)
- Harder to catch regressions
- Less confidence in changes

**Estimated effort**: Ongoing

---

## Recommendation

**Choose Option A** if:
- You need 70%+ coverage (compliance, quality gates)
- You plan long-term maintenance
- Team has time for refactoring

**Choose Option B** if:
- You need better coverage quickly
- Integration tests are acceptable
- 30-40% coverage is enough

**Choose Option C** if:
- Current quality is acceptable
- No coverage requirements
- Limited time/resources

---

## Next Steps

1. **Decide on approach** (A, B, or C)
2. **If Option A**: Start with protocol extraction for AssignmentsStore
3. **If Option B**: Write integration tests for critical user flows
4. **If Option C**: Document testing strategy in CONTRIBUTING.md

## Files to Review

- `/SharedCore/State/AssignmentsStore.swift` - Singleton pattern
- `/SharedCore/State/CoursesStore.swift` - Singleton pattern  
- `/Tests/Unit/ItoriTests/Infrastructure/BaseTestCase.swift` - Test infrastructure
- `/Tests/Unit/ItoriTests/Infrastructure/MockDataFactory.swift` - Test data factory

---

**Questions?** See the test failures and architectural issues above.
