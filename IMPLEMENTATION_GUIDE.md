# UI/UX Enhancement Implementation Plan

## Phase 1: Quick Wins (Week 1)

### ✅ 1. Haptic Feedback Implementation

**Files Created:**
- `SharedCore/Services/FeedbackManager.swift`
- `Tests/Unit/SharedCore/FeedbackManagerTests.swift`

**Integration Points:**
```swift
// In IOSAssignmentsView.swift (line ~395)
Button {
    toggleCompletion(task)
    FeedbackManager.shared.trigger(event: .taskCompleted) // ADD THIS
} label: {
    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
}

// In IOSDashboardView.swift - Add to any button actions
// In IOSTimerView.swift - Add to timer start/stop
```

**Testing:**
```bash
xcodebuild test -scheme Itori \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:ItoriTests/Unit/SharedCore/FeedbackManagerTests
```

---

### ✅ 2. Pull-to-Refresh

**Implementation:**
```swift
// In IOSAssignmentsView.swift (line ~377)
List {
    // existing content
}
.listStyle(.insetGrouped)
.refreshable {
    await refreshData()
}

// Add method
private func refreshData() async {
    await assignmentsStore.sync()
    FeedbackManager.shared.trigger(event: .dataRefreshed)
}
```

**Testing:**
- Manual: Pull down on list
- UI Test: Simulate pull gesture

---

### ✅ 3. Urgency-Based Colors

**Implementation:**
```swift
// In IOSAssignmentsView.swift, add helper method
private func urgencyColor(for task: AppTask) -> Color {
    guard let due = task.effectiveDueDateTime else { return .secondary }
    let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
    
    switch days {
    case ..<0: return .red.opacity(0.8)
    case 0: return .orange.opacity(0.9)
    case 1...2: return .yellow.opacity(0.8)
    case 3...7: return .blue.opacity(0.7)
    default: return .secondary.opacity(0.6)
    }
}

// In task row (line ~391), add:
Circle()
    .fill(urgencyColor(for: task))
    .frame(width: 8, height: 8)
```

**Testing:**
```swift
func testUrgencyColors() {
    let overdueTask = createTask(daysFromNow: -1)
    let todayTask = createTask(daysFromNow: 0)
    let soonTask = createTask(daysFromNow: 2)
    
    XCTAssertEqual(urgencyColor(for: overdueTask), .red.opacity(0.8))
    XCTAssertEqual(urgencyColor(for: todayTask), .orange.opacity(0.9))
    XCTAssertEqual(urgencyColor(for: soonTask), .yellow.opacity(0.8))
}
```

---

### ✅ 4. Enhanced Empty States

**Implementation:**
```swift
// Replace IOSInlineEmptyState with ContentUnavailableView
// In IOSAssignmentsView.swift (line ~383)
if assignmentsStore.tasks.isEmpty {
    ContentUnavailableView {
        Label("No Tasks Yet", systemImage: "checkmark.circle")
    } description: {
        Text("Capture tasks and due dates here")
    } actions: {
        Button("Add First Task") {
            showingEditor = true
        }
        .buttonStyle(.borderedProminent)
    }
}
```

**Apply to:**
- `IOSCoursesView.swift`
- `IOSFlashcardsView.swift`
- `IOSDashboardView.swift`

---

### ✅ 5. Micro-Animations

**Implementation:**
```swift
// In IOSAssignmentsView.swift
@State private var pressedTaskId: UUID?

// Modify task row (line ~389)
HStack(spacing: 12) {
    // content
}
.scaleEffect(pressedTaskId == task.id ? 0.98 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressedTaskId)
.onLongPressGesture(minimumDuration: 0.0, maximumDistance: 0) {
    pressedTaskId = task.id
} onPressingChanged: { isPressing in
    if !isPressing {
        pressedTaskId = nil
    }
}
```

---

## Phase 2: Medium Effort (Week 2-3)

### 6. Interactive Charts

**Implementation:**
```swift
// In IOSDashboardView.swift (line ~658)
Chart(items) { item in
    SectorMark(/* ... */)
}
.chartLegend(.hidden)
.chartAngleSelection(value: $selectedSlice) // ADD iOS 17+
.chartBackground { chartProxy in
    GeometryReader { geometry in
        // Add selection overlay
    }
}
```

---

### 7. Scoped Search

**Implementation:**
```swift
// In IOSAssignmentsView.swift
@State private var searchScope: SearchScope = .all

enum SearchScope: String, CaseIterable {
    case all, overdue, thisWeek, completed
}

// Add to body
.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
.searchScopes($searchScope) {
    ForEach(SearchScope.allCases, id: \.self) { scope in
        Text(scope.rawValue.capitalized).tag(scope)
    }
}

// Filter logic
private var filteredTasks: [AppTask] {
    let base = assignmentsStore.tasks
    let searched = searchText.isEmpty ? base : base.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    
    switch searchScope {
    case .all: return searched
    case .overdue: return searched.filter { ($0.effectiveDueDateTime ?? Date.distantFuture) < Date() }
    case .thisWeek: /* filter logic */
    case .completed: return searched.filter { $0.isCompleted }
    }
}
```

---

### 8. Collapsible Sections

**Implementation:**
```swift
// In IOSDashboardView.swift
@AppStorage("dashboard.sections.collapsed") 
private var collapsedSections: Set<String> = []

DisclosureGroup(
    isExpanded: .init(
        get: { !collapsedSections.contains("upcoming") },
        set: { if !$0 { collapsedSections.insert("upcoming") } else { collapsedSections.remove("upcoming") }}
    )
) {
    upcomingAssignmentsContent
} label: {
    Label("Upcoming Assignments", systemImage: "calendar")
}
```

---

## Optimization Tests

**Created Files:**
- `Tests/OptimizationTests/PerformanceTests/UIPerformanceTests.swift`
- `Tests/OptimizationTests/MemoryTests/MemoryLeakTests.swift`
- `Tests/OptimizationTests/Seeds/TestDataFactory.swift`
- `Tests/OptimizationTests/README.md`

**Running Tests:**
```bash
# All optimization tests
xcodebuild test -scheme Itori \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:ItoriTests/OptimizationTests

# Performance only
xcodebuild test -scheme Itori \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:ItoriTests/OptimizationTests/PerformanceTests

# Memory only
xcodebuild test -scheme Itori \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:ItoriTests/OptimizationTests/MemoryTests \
  -enableAddressSanitizer YES
```

---

## CI/CD Integration

**Created:**
- `.github/workflows/optimization-tests.yml`

**Features:**
- Runs on every PR and push to main/develop
- Nightly full suite at 2 AM UTC
- Uploads test results as artifacts
- Comments performance results on PRs
- Slack notifications for failures

**Setup Required:**
1. Add `SLACK_WEBHOOK` secret to GitHub repo (optional)
2. Ensure Xcode 15.2+ is available on runners
3. Review and adjust baseline thresholds in tests

---

## Next Steps

1. **Week 1 (Quick Wins):**
   - [ ] Integrate FeedbackManager into all button actions
   - [ ] Add pull-to-refresh to all List views
   - [ ] Implement urgency colors in task rows
   - [ ] Replace all empty states with ContentUnavailableView
   - [ ] Add micro-animations to interactive elements

2. **Week 2-3 (Medium Effort):**
   - [ ] Implement interactive charts with selection
   - [ ] Add scoped search to assignments, courses, flashcards
   - [ ] Make dashboard sections collapsible
   - [ ] Add smart notifications with context awareness
   - [ ] Implement loading states for async operations

3. **Continuous:**
   - [ ] Run optimization tests on every PR
   - [ ] Review performance baselines weekly
   - [ ] Update baselines after confirmed optimizations
   - [ ] Monitor memory usage trends

---

## Success Metrics

Track these weekly:
- **Performance:** Dashboard load time, list scroll fps, search latency
- **Memory:** Peak allocation, leak count, avg memory footprint
- **User Engagement:** Session duration, feature usage, retention
- **Quality:** Crash rate, bug reports, user feedback

---

## Resources

- **Tests:** `/Tests/OptimizationTests/`
- **CI:** `/.github/workflows/optimization-tests.yml`
- **Documentation:** `/Tests/OptimizationTests/README.md`
- **Baseline Config:** See test files for `Baseline` enums
