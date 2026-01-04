# Deterministic Planning Engine - Technical Documentation

## Overview

The Deterministic Planning Engine is a core component of Itori that generates predictable, algorithmic study plans for assignments. Unlike AI-based approaches, this engine uses strict rules and calculations to ensure consistent, testable, and instantaneous plan generation.

## Architecture

### Components

1. **AssignmentPlanEngine** (`SharedCore/Services/FeatureServices/AssignmentPlanEngine.swift`)
   - Generates structured plans with steps
   - Calculates timing and sequencing
   - Handles all assignment categories

2. **PlannerEngine** (`SharedCore/Services/FeatureServices/PlannerEngine.swift`)
   - Converts plans into schedulable sessions
   - Performs time slot allocation
   - Manages energy profile matching

3. **AssignmentPlansStore** (`SharedCore/State/AssignmentPlansStore.swift`)
   - Persists generated plans
   - Triggers automatic scheduling
   - Manages plan lifecycle

4. **PlannerStore** (`SharedCore/State/PlannerStore.swift`)
   - Stores scheduled sessions
   - Handles overflow sessions
   - Preserves user edits

## Key Principles

### 1. Determinism

**Definition**: Same input always produces same output.

**Implementation**:
- No random number generation
- No timestamps in logic (except for calculations relative to due dates)
- Stable sorting algorithms
- Consistent settings across runs

**Testing**:
```swift
func testDeterministicPlanGeneration() {
    let assignment = makeTestAssignment()
    let plan1 = AssignmentPlanEngine.generatePlan(for: assignment)
    let plan2 = AssignmentPlanEngine.generatePlan(for: assignment)
    
    XCTAssertEqual(plan1.steps.count, plan2.steps.count)
    // All properties should match exactly
}
```

### 2. Performance

**Target Metrics**:
- Plan generation: < 10ms
- Session generation: < 20ms  
- Scheduling: < 50ms
- Total end-to-end: < 100ms

**Optimization Techniques**:
- Algorithmic complexity: O(n log n) worst case
- No network calls
- Minimal allocations
- Lazy evaluation where possible

### 3. Correctness

**Validation**:
- Sequence indices must be consecutive (0, 1, 2, ...)
- Total step duration ≥ assignment estimated time
- All steps must fit within time window
- No dependency cycles
- Realistic session durations (15 min - 8 hours)

## Assignment Categories

### Exam

**Strategy**: Spaced repetition with multiple review sessions

**Parameters**:
- Lead time: 7 days default
- Session duration: 60 minutes
- Session count: 3-6 sessions
- Types: Review → Practice → Practice → Final Review

**Algorithm**:
```
1. Calculate lead days before due date
2. Determine session count based on total minutes
3. Space sessions evenly across lead period
4. First session: Initial review
5. Middle sessions: Practice
6. Last session: Final review
```

**Example**:
- Assignment: 240 minutes, due in 7 days
- Plan: 4 sessions × 60 minutes
- Days: -7, -5, -3, -1 before due
- Types: Review, Practice, Practice, Final Review

### Quiz

**Strategy**: Condensed review period

**Parameters**:
- Lead time: 3 days default
- Session duration: 45 minutes
- Session count: 1-3 sessions
- Types: Study sessions with final review

**Algorithm**:
```
1. Calculate shorter lead period (3 days)
2. Limit to maximum 3 sessions
3. Distribute evenly
4. Final session is always review type
```

### Homework (Practice/General)

**Strategy**: Single session if short, split if long

**Parameters**:
- Threshold: 60 minutes
- Split session size: 45 minutes
- Lead time: 3 days for long homework

**Algorithm**:
```
if estimatedMinutes <= 60:
    Single session, due day before deadline
else:
    Split into 45-minute chunks
    Space across 3 days before deadline
```

### Reading

**Strategy**: Section-based splitting

**Parameters**:
- Threshold: 45 minutes
- Session size: 30 minutes
- Lead time: 3 days

**Algorithm**:
```
if estimatedMinutes <= 45:
    Single reading session
else:
    Split into 30-minute sections
    Label as "Section 1/N", "Section 2/N", etc.
```

### Review

**Strategy**: Regular review intervals

**Parameters**:
- Session size: 30 minutes
- Lead time: 3 days
- Evenly distributed

### Project

**Strategy**: Phase-based approach

**Parameters**:
- Lead time: 14 days
- Session size: 75 minutes
- Minimum sessions: 4
- Phases: Research → Planning → Implementation → Review

**Algorithm**:
```
if project.plan is not empty:
    Use custom plan steps
else:
    Generate default phases:
    1. Research
    2. Planning  
    3. Implementation
    4. Review
    5. Polish (if time allows)
    6. Final check (if time allows)
```

## Scheduling Algorithm

### Phase 1: Session Generation

```swift
PlannerEngine.generateSessions(for: assignment, settings: settings)
```

Converts assignment into schedulable sessions with metadata:
- Session title
- Estimated duration
- Category
- Importance/difficulty
- Due date

### Phase 2: Priority Scoring

```swift
scheduleIndex = 0.5 * priorityFactor + 0.4 * dueFactor + 0.1 * categoryFactor
```

**Factors**:
- **Priority**: Based on urgency (0.4 - 1.0)
- **Due Date**: Closer = higher (0.0 - 1.0 over 14-day horizon)
- **Category**: Exam > Project > Quiz > Homework > Reading

**Adjustments**:
- Exams and quizzes get +0.05 boost

### Phase 3: Time Slot Allocation

**Schedule Grid**:
- Day range: Today → Due date window
- Hour range: 9 AM - 9 PM (configurable)
- Slot size: 30 minutes
- Total slots per day: 24 (12 hours × 2)

**Algorithm**:
```
1. Sort sessions by scheduleIndex (descending)
2. For each session (highest priority first):
   a. Determine scheduling window based on category
   b. For each day in window:
      i. For each possible start slot:
         - Check if enough contiguous slots available
         - Calculate energy profile match
         - Compute placement score
         - Track best placement
   c. If placement found:
      - Mark slots as occupied
      - Create ScheduledSession
   d. Else:
      - Add to overflow
```

**Energy Profile Matching**:
```
energyMatch = 1 - |difficultyRequirement - slotEnergy|
placementScore = 0.8 * scheduleIndex + 0.2 * energyMatch
```

### Phase 4: Conflict Resolution

**Guarantees**:
- No overlapping sessions
- All sessions within working hours
- Respects fixed events
- Maintains time gaps between sessions

**Overflow Handling**:
- Sessions that can't be scheduled go to overflow list
- User can manually schedule overflow sessions
- UI shows overflow count as alert

## Data Flow

### Adding an Assignment

```
User adds assignment
    ↓
AssignmentsStore.addTask()
    ↓
generatePlanForNewTask()
    ↓
AssignmentPlanEngine.generatePlan()
    ├─ Generate steps
    ├─ Calculate timing
    └─ Return AssignmentPlan
    ↓
AssignmentPlansStore.generatePlan()
    ├─ Save plan to disk
    └─ scheduleAssignmentSessions()
        ↓
        PlannerEngine.generateSessions()
        ↓
        PlannerEngine.scheduleSessions()
        ↓
        PlannerStore.persist()
        ↓
    Planner UI updates (ObservableObject)
```

### Updating an Assignment

```
User edits assignment
    ↓
AssignmentsStore.updateTask()
    ↓
Check if key fields changed:
    - Due date?
    - Estimated minutes?
    - Category?
    - Importance?
    ↓
If yes:
    Regenerate plan (same flow as add)
If no:
    Skip regeneration (performance optimization)
```

## Settings & Configuration

### PlanGenerationSettings

```swift
struct PlanGenerationSettings {
    // Exam
    var examLeadDays: Int = 7
    var examSessionMinutes: Int = 60
    
    // Quiz
    var quizLeadDays: Int = 3
    var quizSessionMinutes: Int = 45
    
    // Homework
    var homeworkLeadDays: Int = 3
    var homeworkSessionMinutes: Int = 45
    var homeworkSingleSessionThreshold: Int = 60
    
    // Reading
    var readingLeadDays: Int = 3
    var readingSessionMinutes: Int = 30
    var readingSingleSessionThreshold: Int = 45
    
    // Review
    var reviewLeadDays: Int = 3
    var reviewSessionMinutes: Int = 30
    
    // Project
    var projectLeadDays: Int = 14
    var projectSessionMinutes: Int = 75
    var projectMinSessions: Int = 4
}
```

### StudyPlanSettings

```swift
struct StudyPlanSettings {
    var examDefaultSessionMinutes: Int = 60
    var examStartDaysBeforeDue: Int = 5
    var quizDefaultSessionMinutes: Int = 60
    var quizStartDaysBeforeDue: Int = 3
    // ... etc
}
```

### Energy Profile

Default profile (can be customized per user):
```swift
[
    9: 0.55,  10: 0.65,  11: 0.7,  12: 0.6,
    13: 0.5,  14: 0.55,  15: 0.65, 16: 0.7,
    17: 0.6,  18: 0.5,   19: 0.45, 20: 0.4
]
```

## Testing Strategy

### Unit Tests

**AssignmentPlanEngineTests**:
- Determinism validation
- Category-specific generation
- Edge cases (minimal duration, very long, near due date)
- Custom settings
- Step type verification

**PlannerEngineDeterminismTests**:
- Session generation determinism
- Scheduling determinism
- Schedule index calculation
- Constraint enforcement
- Overflow detection

**AssignmentPlanDependencyTests**:
- Linear chain setup
- Blocked steps
- Cycle detection
- Topological sorting

### Performance Tests

```swift
func testPlanningPerformance() {
    measure {
        let plan = AssignmentPlanEngine.generatePlan(for: assignment)
    }
    // Should complete in < 10ms
}
```

### Integration Tests

```swift
func testEndToEndPlanning() {
    let assignment = createAssignment()
    addAssignment(assignment)
    
    // Verify plan created
    let plan = AssignmentPlansStore.shared.plan(for: assignment.id)
    XCTAssertNotNil(plan)
    
    // Verify sessions scheduled
    let sessions = PlannerStore.shared.scheduled
    XCTAssertGreaterThan(sessions.count, 0)
}
```

## Performance Monitoring

### Metrics Collection

```swift
let (plan, metrics) = PlanningPerformanceMonitor.generateFullPlanMetrics(
    for: assignment,
    energyProfile: profile
)

print("Plan generation: \(metrics.planGenerationTime)ms")
print("Session generation: \(metrics.sessionGenerationTime)ms")
print("Scheduling: \(metrics.schedulingTime)ms")
print("Efficiency: \(metrics.efficiency)")
```

### Quality Validation

```swift
let issues = AssignmentPlanEngine.validatePlan(plan)
if !issues.isEmpty {
    for issue in issues {
        print("Warning: \(issue.description)")
    }
}

let quality = plan.qualityScore
print("Plan quality: \(quality)/100")
```

## Best Practices

### For Developers

1. **Always test determinism**: Any change to planning logic must pass determinism tests
2. **Measure performance**: Use PlanningPerformanceMonitor for new features
3. **Validate output**: Run validatePlan() on generated plans
4. **Consider edge cases**: Very short/long durations, near due dates, many assignments

### For Users

1. **Trust the algorithm**: Plans are optimized based on research-backed study techniques
2. **Customize settings**: Adjust lead times and session lengths in preferences
3. **Review overflow**: Check overflow list if assignments can't be scheduled
4. **Lock critical dates**: Use isLockedToDueDate for immovable deadlines

## Troubleshooting

### High Overflow Count

**Cause**: Too many assignments in limited time window

**Solutions**:
- Extend due dates
- Reduce estimated times
- Increase working hours (adjust energy profile)
- Mark some assignments as lower priority

### Inconsistent Plans

**Cause**: Settings changed between generations

**Solution**: Use consistent settings or regenerate all plans

### Poor Energy Matching

**Cause**: Default profile doesn't match user patterns

**Solution**: Customize energy profile in preferences

## Future Enhancements

### Short Term
- [ ] User-customizable energy profiles
- [ ] "Quick win" detection (schedule easy tasks first)
- [ ] Deadline clustering detection
- [ ] Smart gap filling

### Medium Term
- [ ] Multi-day session spanning
- [ ] Break time integration
- [ ] Workload balancing across days
- [ ] Prerequisite course awareness

### Long Term
- [ ] Machine learning for duration estimation
- [ ] Adaptive scheduling based on completion patterns
- [ ] Collaborative study session suggestions
- [ ] Calendar integration for automatic blocking

## References

- [AUTO_PLAN_IMPLEMENTATION.md](../../AUTO_PLAN_IMPLEMENTATION.md) - Implementation summary
- [AssignmentPlanEngine.swift](../../SharedCore/Services/FeatureServices/AssignmentPlanEngine.swift) - Plan generation
- [PlannerEngine.swift](../../SharedCore/Services/FeatureServices/PlannerEngine.swift) - Session scheduling
- [AssignmentPlan.swift](../../SharedCore/Models/AssignmentPlan.swift) - Data models

---

**Last Updated**: December 22, 2024  
**Version**: 1.0  
**Status**: Production Ready
