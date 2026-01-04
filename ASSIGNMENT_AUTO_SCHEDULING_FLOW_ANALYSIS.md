# Assignment Auto-Scheduling Flow Analysis
**Assignment Creation → Auto-Scheduling → Calendar Integration**

## Executive Summary

The Itori app features an intelligent auto-scheduling system that:
1. Takes user-created assignments with due dates
2. Fetches existing events from Apple Calendar (EventKit)
3. Generates study sessions broken into manageable chunks
4. Finds free time slots between existing events
5. Proposes a schedule as a diff (never auto-applies)
6. Requires explicit user approval before adding to calendar
7. Continuously adapts to calendar changes

**Key Principle**: AI/auto-scheduling **never directly modifies** the calendar. All changes go through a "propose → review → apply" workflow with user approval.

---

## Architecture Overview

### Core Components

```
┌─────────────────────────────────────────────────────┐
│ 1. USER CREATES ASSIGNMENT                          │
│    - AddAssignmentView                              │
│    - AssignmentsStore.addTask()                     │
└────────────────┬────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────┐
│ 2. PLAN GENERATION (Automatic)                      │
│    - AssignmentPlansStore.generatePlan()            │
│    - PlannerEngine.generateSessions()               │
│    → Breaks assignment into study sessions          │
└────────────────┬────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────┐
│ 3. CALENDAR EVENT FETCH (Background)                │
│    - DeviceCalendarManager.refreshEvents()          │
│    - EventKit: EKEventStore.events(matching:)       │
│    → Fetches existing events from Apple Calendar    │
└────────────────┬────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────┐
│ 4. AUTO-SCHEDULING (User-Triggered)                 │
│    - CalendarRefreshCoordinator.refresh()           │
│    - AutoScheduler.generateSchedule()               │
│    → Finds free slots around existing events        │
│    → Produces ScheduleDiff (proposed changes)       │
└────────────────┬────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────┐
│ 5. USER REVIEW & APPROVAL (Required)                │
│    - PendingScheduleSuggestionStrip (UI)            │
│    - Shows diff: added/moved/resized blocks         │
│    - User chooses: Apply All / Apply Non-Conflicting│
└────────────────┬────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────┐
│ 6. CALENDAR INTEGRATION (After Approval)            │
│    - CalendarRefreshCoordinator.applyScheduleDiff() │
│    - Creates EKEvents in selected calendar          │
│    - Tags events with [ItoriAutoSchedule:UUID]      │
└─────────────────────────────────────────────────────┘
```

---

## Data Models

### Assignment (Input)
```swift
struct Assignment {
    let id: UUID
    let courseId: UUID
    let title: String
    let dueDate: Date
    let estimatedMinutes: Int
    let category: AssignmentCategory  // exam, quiz, homework, project, reading, review
    let urgency: AssignmentUrgency
    let isLockedToDueDate: Bool
    let plan: [PlanStep]  // Optional breakdown
}
```

### PlannerSession (Generated)
```swift
struct PlannerSession {
    let id: UUID
    let assignmentId: UUID
    let sessionIndex: Int         // e.g., 1 of 4
    let sessionCount: Int
    let title: String            // "CS 101 Final – Study Session 1/4"
    let dueDate: Date
    let category: AssignmentCategory
    let estimatedMinutes: Int    // per session
    let kind: PlannerSessionKind // .study, .shortBreak, .longBreak
}
```

### AutoScheduleTask (Scheduler Input)
```swift
struct AutoScheduleTask {
    let id: UUID
    let title: String
    let estimatedDurationMinutes: Int
    let dueDate: Date
    let priority: Int  // Computed from urgency
}
```

### ScheduleDiff (Output)
```swift
struct ScheduleDiff {
    let addedBlocks: [ProposedBlock]
    let movedBlocks: [MovedBlock]
    let resizedBlocks: [ResizedBlock]
    let removedBlocks: [RemovedBlock]
    let conflicts: [ScheduleConflict]
    let reason: String
    let confidence: AIConfidence
}

struct ProposedBlock {
    let tempID: String           // Tag: "[ItoriAutoSchedule:UUID-chunkIndex]"
    let title: String
    let startDate: Date
    let duration: TimeInterval
    let reason: String
}
```

### EventKit Integration
```swift
// Apple Calendar Event
EKEvent {
    var title: String
    var startDate: Date
    var endDate: Date
    var calendar: EKCalendar
    var notes: String?  // Contains [ItoriAutoSchedule:...] tag
}
```

---

## Detailed Flow Walkthrough

### Phase 1: Assignment Creation

**User Action**: Add assignment via `AddAssignmentView`

**File**: `Platforms/macOS/Views/AddAssignmentView.swift`

```swift
// User fills form
@State private var title: String = ""
@State private var due: Date = Date()
@State private var estimatedMinutes: Int = 60
@State private var selectedCourseId: UUID?
@State private var type: TaskType  // .project, .exam, etc.

// On Save button
onSave: (AppTask) -> Void
```

**Validation**:
- Title must not be empty
- Course must be selected (courseId required)
- Due date set (for scheduling)

**Callback Flow**:
1. User clicks Save
2. `AddAssignmentView` creates `AppTask`
3. Calls `onSave(task)` callback
4. Callback invokes `AssignmentsStore.addTask(task)`

---

### Phase 2: Automatic Plan Generation

**File**: `SharedCore/State/AssignmentsStore.swift`

```swift
func addTask(_ task: AppTask) {
    // ... normalize and validate ...
    
    tasks.append(normalized)
    
    // ✅ AUTOMATIC: Generate plan immediately
    Task { @MainActor in
        generatePlanForNewTask(normalized)
    }
}

private func generatePlanForNewTask(_ task: AppTask) {
    guard let assignment = convertTaskToAssignment(task) else { return }
    AssignmentPlansStore.shared.generatePlan(for: assignment, force: false)
}
```

**Plan Generation Logic** (`AssignmentPlansStore.swift`):

```swift
func generatePlan(for assignment: Assignment, force: Bool = false) {
    // Check if plan already exists (unless forced)
    if !force && hasPlan(for: assignment.id) {
        return
    }
    
    // Generate breakdown plan
    let plan = AssignmentPlanEngine.generatePlan(for: assignment, settings: settings)
    plans[assignment.id] = plan
    save()
    
    // Schedule sessions
    Task { @MainActor in
        scheduleAssignmentSessions(for: assignment)
    }
}
```

**Session Generation** (`PlannerEngine.swift`):

```swift
static func generateSessions(for assignment: Assignment) -> [PlannerSession] {
    var sessions: [PlannerSession] = []
    
    switch assignment.category {
    case .exam:
        // Split into 3-4 study sessions of 60 minutes each
        let perSession = 60
        let sessionCount = max(3, min(4, totalMinutes / perSession))
        
        for i in 1...sessionCount {
            sessions.append(PlannerSession(
                title: "\(assignment.title) – Study Session \(i)/\(sessionCount)",
                sessionIndex: i,
                sessionCount: sessionCount,
                estimatedMinutes: perSession,
                kind: .study
            ))
        }
        
    case .homework:
        // Single session if < 60 min, otherwise split into 45-min chunks
        if totalMinutes <= 60 {
            sessions.append(singleSession)
        } else {
            let chunks = Int(ceil(totalMinutes / 45.0))
            for i in 1...chunks {
                sessions.append(chunk(i, of: chunks, duration: 45))
            }
        }
        
    case .project:
        // Use custom plan steps if provided, otherwise 3+ sessions
        if !assignment.plan.isEmpty {
            for step in assignment.plan {
                sessions.append(sessionForStep(step))
            }
        } else {
            let sessionCount = max(3, totalMinutes / 75)
            for i in 1...sessionCount {
                sessions.append(session(i, duration: 75))
            }
        }
        
    // ... similar logic for quiz, reading, review
    }
    
    return sessions
}
```

**Result**: Assignment broken into multiple study sessions (e.g., "CS 101 Final – Study Session 1/4")

---

### Phase 3: Calendar Event Fetching

**Background Service**: `DeviceCalendarManager`

**File**: `SharedCore/Services/DeviceCalendarManager.swift`

```swift
@MainActor
final class DeviceCalendarManager: ObservableObject {
    static let shared = DeviceCalendarManager()
    
    let store = EKEventStore()
    @Published private(set) var events: [EKEvent] = []
    @Published private(set) var isAuthorized: Bool = false
    
    func bootstrapOnLaunch() async {
        // Request calendar access
        authManager.refreshStatus()
        isAuthorized = authManager.isAuthorized
        
        guard isAuthorized else { return }
        
        // Start observing calendar changes
        startObservingStoreChanges()
        
        // Fetch initial events
        await refreshEventsForVisibleRange(reason: "launch")
    }
    
    func refreshEventsForVisibleRange() async {
        guard authManager.isAuthorized else { return }
        
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -30, to: .now)!
        let end   = cal.date(byAdding: .day, value:  90, to: .now)!
        
        // Filter by selected school calendar if configured
        let calendarsToFetch: [EKCalendar]?
        if let calendarID = AppSettingsModel.shared.selectedSchoolCalendarID,
           !calendarID.isEmpty {
            calendarsToFetch = [store.calendar(withIdentifier: calendarID)].compactMap { $0 }
        } else {
            calendarsToFetch = nil  // All calendars
        }
        
        // Fetch from EventKit
        let predicate = store.predicateForEvents(
            withStart: start, 
            end: end, 
            calendars: calendarsToFetch
        )
        let fetched = store.events(matching: predicate)
        
        await MainActor.run {
            self.events = fetched
            self.lastRefreshAt = Date()
        }
    }
    
    func startObservingStoreChanges() {
        // Listen to EKEventStoreChanged notifications
        storeChangedObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.refreshEventsForVisibleRange(reason: "storeChange") }
        }
        
        isObservingStoreChanges = true
    }
}
```

**Triggers for Refresh**:
1. App launch
2. EKEventStoreChanged notification (calendar modified externally)
3. Manual refresh by user
4. After scheduling changes applied

**Result**: `DeviceCalendarManager.events` contains all existing calendar events in date range

---

### Phase 4: Auto-Scheduling (Finding Free Slots)

**User Trigger**: User clicks "Generate Plan" button in Planner view

**File**: `Platforms/iOS/Scenes/IOSCorePages.swift`

```swift
private func generatePlan() {
    let assignments = assignmentsForPlanning()
    guard !assignments.isEmpty else { return }
    
    let settings = StudyPlanSettings()
    
    // Generate sessions for all pending assignments
    let sessions = assignments.flatMap { 
        PlannerEngine.generateSessions(for: $0, settings: settings) 
    }
    
    // Schedule with energy profile and constraints
    let result = PlannerEngine.scheduleSessionsWithStrategy(
        sessions, 
        settings: settings, 
        energyProfile: defaultEnergyProfile()
    )
    
    // Persist to planner store
    plannerStore.persist(
        scheduled: result.scheduled, 
        overflow: result.overflow
    )
}
```

**Alternative Trigger**: Automatic on calendar refresh

**File**: `SharedCore/State/CalendarRefreshCoordinator.swift`

```swift
func runRefresh() async -> CalendarRefreshError? {
    guard authManager.isAuthorized else { return .permissionDenied }
    
    // Refresh calendar events from EventKit
    await calendarManager.refreshAuthStatus()
    await deviceCalendar.refreshEvents(from: now, to: endDate, reason: "manualRefresh")
    
    // Run auto-scheduling
    try await scheduleAssignments(from: now, to: endDate)
    
    return nil
}
```

**Core Scheduling Algorithm** (`AutoScheduler.swift`):

```swift
static func generateSchedule(
    tasks: [AutoScheduleTask],
    existingEvents: [EKEvent],
    startDate: Date,
    daysToPlan: Int = 7,
    workDayStart: Int = 9,    // 9 AM
    workDayEnd: Int = 17,     // 5 PM
    maxStudyMinutesPerDay: Int = 360  // 6 hours max
) -> ScheduleDiff {
    
    var proposedBlocks: [ProposedBlock] = []
    
    // 1. Sort tasks by priority and due date
    let sortedTasks = tasks.sorted { 
        if $0.priority != $1.priority { return $0.priority > $1.priority }
        return $0.dueDate < $1.dueDate
    }
    
    // 2. Find all free time slots
    var freeSlots = findFreeSlots(
        existingEvents: existingEvents,
        startDate: startDate,
        days: daysToPlan,
        startHour: workDayStart,
        endHour: workDayEnd
    )
    
    // 3. Track daily study minutes to enforce max
    var minutesScheduledPerDay: [Date: Int] = [:]
    let minBlockMinutes = 60  // Minimum contiguous block
    
    // 4. Greedy allocation: assign tasks to slots
    for task in sortedTasks {
        var minutesNeeded = task.estimatedDurationMinutes
        var scheduledChunks = 0
        
        for slotIndex in freeSlots.indices {
            guard minutesNeeded > 0 else { break }
            
            let slot = freeSlots[slotIndex]
            let dayStart = calendar.startOfDay(for: slot.startDate)
            let alreadyScheduled = minutesScheduledPerDay[dayStart] ?? 0
            
            // Check daily limit
            if alreadyScheduled >= maxStudyMinutesPerDay { continue }
            
            // Calculate allocatable minutes
            let slotMinutes = Int(slot.duration / 60)
            let allocatableMinutes = min(
                slotMinutes, 
                maxStudyMinutesPerDay - alreadyScheduled
            )
            let chunk = min(minutesNeeded, allocatableMinutes)
            
            // Enforce minimum block size (avoid tiny fragments)
            if chunk < minBlockMinutes { continue }
            
            // Create proposed block
            let block = ProposedBlock(
                tempID: "[ItoriAutoSchedule:\(task.id)-\(scheduledChunks)]",
                title: task.title,
                startDate: slot.startDate,
                duration: TimeInterval(chunk * 60),
                reason: "Auto-scheduled study block"
            )
            proposedBlocks.append(block)
            scheduledChunks += 1
            
            // Consume slot (reduce available time)
            let consumedSeconds = TimeInterval(chunk * 60)
            freeSlots[slotIndex].startDate = slot.startDate.addingTimeInterval(consumedSeconds)
            freeSlots[slotIndex].duration = max(0, slot.duration - consumedSeconds)
            
            // Update counters
            minutesScheduledPerDay[dayStart] = alreadyScheduled + chunk
            minutesNeeded -= chunk
        }
    }
    
    return ScheduleDiff(
        addedBlocks: proposedBlocks,
        movedBlocks: [],
        resizedBlocks: [],
        conflicts: [],
        reason: "autoSchedule",
        confidence: AIConfidence(0.6)
    )
}
```

**Free Slot Finding Logic**:

```swift
private static func findFreeSlots(
    existingEvents: [EKEvent],
    startDate: Date,
    days: Int,
    startHour: Int,
    endHour: Int
) -> [TimeSlot] {
    var slots: [TimeSlot] = []
    
    for offset in 0..<days {
        let day = calendar.date(byAdding: .day, value: offset, to: startDate)!
        let windowStart = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: day)!
        let windowEnd = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: day)!
        
        // Start with full day as one slot
        var daySlots = [TimeSlot(
            startDate: windowStart, 
            duration: windowEnd.timeIntervalSince(windowStart)
        )]
        
        // Find busy periods (existing events)
        let busyEvents = existingEvents.compactMap { event -> (Date, Date)? in
            guard let start = event.startDate, let end = event.endDate else { return nil }
            
            // Skip events outside work window
            if end <= windowStart || start >= windowEnd { return nil }
            
            // Clamp to work window
            let clampedStart = max(start, windowStart)
            let clampedEnd = min(end, windowEnd)
            return (clampedStart, clampedEnd)
        }.sorted { $0.0 < $1.0 }
        
        // Subtract busy intervals from free slots
        for busyInterval in busyEvents {
            daySlots = subtract(interval: busyInterval, from: daySlots)
        }
        
        slots.append(contentsOf: daySlots.filter { $0.duration > 0 })
    }
    
    return slots.sorted { $0.startDate < $1.startDate }
}

private static func subtract(
    interval: (Date, Date), 
    from slots: [TimeSlot]
) -> [TimeSlot] {
    var result: [TimeSlot] = []
    
    for slot in slots {
        // No overlap: keep slot
        if interval.1 <= slot.startDate || interval.0 >= slot.endDate {
            result.append(slot)
            continue
        }
        
        // Overlap: split into left and right remainders
        if interval.0 > slot.startDate {
            // Left remainder (before busy period)
            let duration = interval.0.timeIntervalSince(slot.startDate)
            result.append(TimeSlot(startDate: slot.startDate, duration: duration))
        }
        
        if interval.1 < slot.endDate {
            // Right remainder (after busy period)
            let duration = slot.endDate.timeIntervalSince(interval.1)
            result.append(TimeSlot(startDate: interval.1, duration: duration))
        }
    }
    
    return result
}
```

**Example**:
```
Day: Monday, Jan 6, 2025
Work window: 9 AM - 5 PM (480 minutes)

Existing Events (from Apple Calendar):
  - 10:00 AM - 11:00 AM: Team Meeting
  - 1:00 PM - 2:00 PM: Lunch

Free Slots After Subtraction:
  - 9:00 AM - 10:00 AM   (60 min)
  - 11:00 AM - 1:00 PM   (120 min)
  - 2:00 PM - 5:00 PM    (180 min)

Tasks to Schedule:
  - CS 101 Final Prep (Session 1): 60 min, priority 90
  - Math Homework: 45 min, priority 50

Allocation:
  1. CS 101 Final → 11:00 AM - 12:00 PM (uses 60 min of 120-min slot)
  2. Math Homework → 12:00 PM - 12:45 PM (uses 45 min of remaining 60 min)

Remaining Free:
  - 9:00 AM - 10:00 AM   (60 min) - unused
  - 12:45 PM - 1:00 PM   (15 min) - too short (< 60 min min block)
  - 2:00 PM - 5:00 PM    (180 min) - available for next tasks
```

**Result**: `ScheduleDiff` with proposed blocks and their time slots

---

### Phase 5: User Review & Approval (CRITICAL)

**UI Component**: `PendingScheduleSuggestionStrip`

**File**: `SharedCore/Views/ScheduleSuggestionsView.swift`

```swift
struct PendingScheduleSuggestionStrip: View {
    let pending: PendingScheduleSuggestion
    let onApply: () -> Void
    let onApplyNonConflicting: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        let diff = pending.diff
        let totalChanges = diff.changeCount
        let hasConflicts = !diff.conflicts.isEmpty
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Schedule suggestions ready")
                        .font(.headline)
                    
                    Text(pending.summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    // e.g., "3 study sessions added, 1 conflict"
                }
                
                Spacer()
                
                // Preview button
                Button("Preview") { isExpanded.toggle() }
                
                // Apply buttons
                if hasConflicts {
                    Button("Apply Non-Conflicting") { 
                        onApplyNonConflicting() 
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Apply (\(totalChanges) changes)") { 
                        onApply() 
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Expanded preview
            if isExpanded {
                ScheduleDiffPreview(diff: pending.diff)
                // Shows:
                // ✅ Add: "CS 101 Final – Session 1" @ Mon 11:00 AM (60 min)
                // ⚠️ Conflict: "Math HW" overlaps with "Office Hours"
            }
            
            // Conflicts list
            if hasConflicts {
                ForEach(diff.conflicts) { conflict in
                    Text("⚠️ \(conflict.description)")
                }
            }
            
            Button("Dismiss") { onDismiss() }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
```

**Display in Planner View** (`IOSCorePages.swift`):

```swift
var body: some View {
    ScrollView {
        VStack {
            // Show suggestion strip if available
            if let pending = calendarCoordinator.pendingScheduleSuggestion {
                PendingScheduleSuggestionStrip(
                    pending: pending,
                    onApply: { calendarCoordinator.applyPendingScheduleSuggestion() },
                    onApplyNonConflicting: { calendarCoordinator.applyPendingScheduleSuggestionNonConflicting() },
                    onDismiss: { calendarCoordinator.discardPendingScheduleSuggestion() }
                )
            }
            
            // Rest of planner UI...
        }
    }
}
```

**User Options**:
1. **Preview**: Expand to see detailed list of changes
2. **Apply All**: Accept all proposed blocks (if no conflicts)
3. **Apply Non-Conflicting**: Accept only blocks without conflicts
4. **Dismiss**: Reject suggestions

**Key Safety Feature**: User must explicitly approve. No automatic calendar writes.

---

### Phase 6: Calendar Integration (After Approval)

**Coordinator**: `CalendarRefreshCoordinator`

**File**: `SharedCore/State/CalendarRefreshCoordinator.swift`

```swift
func applyPendingScheduleSuggestion() {
    Task { @MainActor in
        do {
            try await applyPendingScheduleSuggestionInternal()
        } catch {
            self.error = .schedulingFailed
        }
    }
}

private func applyPendingScheduleSuggestionInternal() async throws {
    guard let suggestion = pendingScheduleSuggestion else { return }
    guard authManager.isAuthorized else { return }
    
    // Get target calendar (user-selected or default)
    guard let targetCalendar = calendar(with: suggestion.targetCalendarID) else {
        throw ScheduleError.noCalendar
    }
    
    // Apply the diff
    try applyScheduleDiff(
        suggestion.diff, 
        targetCalendar: targetCalendar, 
        within: suggestion.range
    )
    
    // Sync planner sessions to calendar
    await calendarManager.syncPlannerSessionsToCalendar(in: suggestion.range)
    
    // Clear pending suggestion
    pendingScheduleSuggestion = nil
    
    // Refresh to reflect changes
    await deviceCalendar.refreshEvents(
        from: suggestion.range.lowerBound, 
        to: suggestion.range.upperBound, 
        reason: "autoScheduleApply"
    )
}
```

**Schedule Diff Application**:

```swift
private func applyScheduleDiff(
    _ diff: ScheduleDiff,
    targetCalendar: EKCalendar,
    within range: ClosedRange<Date>
) throws {
    
    // 1. Add new blocks
    for block in diff.addedBlocks {
        let event = EKEvent(eventStore: deviceCalendar.store)
        event.title = block.title
        event.startDate = block.startDate
        event.endDate = block.startDate.addingTimeInterval(block.duration)
        event.calendar = targetCalendar
        event.notes = block.tempID  // Tag: "[ItoriAutoSchedule:UUID-0]"
        
        try deviceCalendar.store.save(event, span: .thisEvent)
    }
    
    // 2. Move existing blocks
    for movedBlock in diff.movedBlocks {
        guard let event = findEvent(by: movedBlock.blockID) else { continue }
        
        let duration = event.endDate.timeIntervalSince(event.startDate)
        event.startDate = movedBlock.newStartDate
        event.endDate = movedBlock.newStartDate.addingTimeInterval(duration)
        
        try deviceCalendar.store.save(event, span: .thisEvent)
    }
    
    // 3. Resize blocks
    for resizedBlock in diff.resizedBlocks {
        guard let event = findEvent(by: resizedBlock.blockID) else { continue }
        
        event.endDate = event.startDate.addingTimeInterval(resizedBlock.newDuration)
        
        try deviceCalendar.store.save(event, span: .thisEvent)
    }
    
    // 4. Remove blocks
    for removedBlock in diff.removedBlocks {
        guard let event = findEvent(by: removedBlock.blockID) else { continue }
        
        try deviceCalendar.store.remove(event, span: .thisEvent)
    }
}

private func findEvent(by tag: String) -> EKEvent? {
    deviceCalendar.events.first { event in
        event.notes?.contains(tag) ?? false
    }
}
```

**Event Tagging System**:
- Each auto-scheduled event has a unique tag in `notes` field
- Format: `[ItoriAutoSchedule:UUID-chunkIndex]`
- Example: `[ItoriAutoSchedule:A1B2C3D4-5678-90AB-CDEF-123456789012-0]`
- Enables:
  - Finding auto-scheduled events later
  - Moving/resizing specific blocks
  - Distinguishing from manual events

**Result**: EKEvents created in Apple Calendar, visible in Calendar.app

---

## Key Constraints & Safety Features

### 1. Work Window Constraints
```swift
// Settings (customizable by user)
workDayStart: Int = 9      // 9 AM
workDayEnd: Int = 17        // 5 PM
maxStudyMinutesPerDay: Int = 360  // 6 hours max
```

**Enforcement**:
- Only schedules within work hours
- Never exceeds daily study limit
- Respects user's energy profile (optional: higher capacity in mornings)

### 2. Minimum Block Size
```swift
let minBlockMinutes = 60  // Enforce 60-minute minimum
```

**Rationale**:
- Avoids fragmented 10-15 minute slots
- Ensures contiguous focus time
- Prevents calendar clutter

### 3. Priority-Based Allocation
```swift
// Sort tasks before scheduling
let sortedTasks = tasks.sorted {
    if $0.priority != $1.priority { 
        return $0.priority > $1.priority  // Higher priority first
    }
    return $0.dueDate < $1.dueDate        // Earlier due date next
}
```

**Effect**:
- Critical exam prep gets best time slots
- Low-priority homework fills remaining gaps

### 4. Conflict Detection
```swift
struct ScheduleConflict {
    let blockID: String
    let conflictingEventTitle: String
    let conflictingEventStart: Date
    let reason: String
}
```

**Types of Conflicts**:
- **Overlap**: Proposed block collides with existing event
- **Over-capacity**: Daily study limit would be exceeded
- **Deadline Violation**: Session scheduled after due date

**Handling**:
- User shown conflict details
- Option to apply only non-conflicting blocks
- Manual resolution required

### 5. Never Auto-Apply Philosophy
```swift
// ❌ NEVER ALLOWED
AutoScheduler.generateSchedule().apply()  // Direct calendar write

// ✅ ALWAYS REQUIRED
let diff = AutoScheduler.generateSchedule()
await userReview(diff)
if userApproved {
    applyScheduleDiff(diff)
}
```

**Enforced by Architecture**:
- `AutoScheduler` returns `ScheduleDiff` (read-only proposal)
- `CalendarRefreshCoordinator` holds pending suggestion
- UI requires explicit button press
- No automatic persistence to EventKit

---

## User Flows (End-to-End)

### Flow A: First-Time User (Happy Path)

```
1. User launches app
   → DeviceCalendarManager.bootstrapOnLaunch()
   → Requests calendar permission
   → User grants access

2. User creates first assignment
   → "CS 101 Final Exam" due Dec 15, 240 min estimated
   → AddAssignmentView → AssignmentsStore.addTask()
   
3. Automatic plan generation
   → AssignmentPlansStore.generatePlan()
   → PlannerEngine.generateSessions()
   → Creates 4 sessions × 60 min each:
      • "CS 101 Final – Study Session 1/4" (60 min)
      • "CS 101 Final – Study Session 2/4" (60 min)
      • "CS 101 Final – Study Session 3/4" (60 min)
      • "CS 101 Final – Study Session 4/4" (60 min)

4. User opens Planner tab
   → Sees 4 unscheduled sessions in "Unscheduled" section

5. User clicks "Generate Plan" button
   → CalendarRefreshCoordinator.refresh()
   → Fetches calendar events (e.g., existing classes)
   → AutoScheduler.generateSchedule()
   → Finds free slots between classes
   → Proposes schedule:
      • Session 1: Mon Dec 8, 2:00 PM - 3:00 PM
      • Session 2: Tue Dec 9, 10:00 AM - 11:00 AM
      • Session 3: Wed Dec 10, 3:00 PM - 4:00 PM
      • Session 4: Thu Dec 11, 1:00 PM - 2:00 PM

6. UI shows suggestion strip
   → "Schedule suggestions ready"
   → "4 study sessions added, 0 conflicts"
   → Preview shows each session with time

7. User clicks "Apply (4 changes)"
   → CalendarRefreshCoordinator.applyPendingScheduleSuggestion()
   → Creates 4 EKEvents in Apple Calendar
   → Tags each with [ItoriAutoSchedule:UUID-index]
   → Success toast: "4 sessions added to calendar"

8. User opens Calendar.app
   → Sees 4 "CS 101 Final" events on schedule
   → Can view/edit in native Calendar app
```

### Flow B: Conflict Resolution

```
1. User has existing appointment
   → "Doctor's Appointment" on Mon 2:00 PM - 3:00 PM

2. Auto-scheduler proposes
   → "Math Homework" on Mon 2:00 PM - 3:00 PM

3. Conflict detected
   → ScheduleConflict(
        blockID: "[ItoriAutoSchedule:...]",
        conflictingEventTitle: "Doctor's Appointment",
        reason: "Time slot unavailable"
     )

4. UI shows
   → "Schedule suggestions ready"
   → "2 study sessions added, 1 conflict"
   → "⚠️ Math Homework overlaps with Doctor's Appointment"

5. User options:
   Option A: Apply Non-Conflicting
   → Only schedules the 2 non-conflicting sessions
   → User must manually reschedule Math Homework
   
   Option B: Dismiss
   → Reject all suggestions
   → User rearranges assignments manually
```

### Flow C: Daily Limit Reached

```
1. User already has 6 hours of study scheduled for Tuesday
   → Reaches maxStudyMinutesPerDay (360 minutes)

2. Auto-scheduler tries to add more
   → 7th assignment: "Reading Chapter 5" (45 min)

3. No slot available on Tuesday
   → Scheduler moves to Wednesday
   → Proposes: Wed 9:00 AM - 9:45 AM

4. User approves
   → Session spreads to next available day
```

### Flow D: Calendar Sync (External Changes)

```
1. User adds event in Calendar.app
   → "Dentist Appointment" on Thu 3:00 PM - 4:00 PM

2. EventKit fires notification
   → .EKEventStoreChanged

3. DeviceCalendarManager receives
   → Triggers refreshEventsForVisibleRange()
   → Re-fetches all events

4. Planner detects conflict
   → Previously scheduled "Math Study" now overlaps
   → Optional: Auto-reschedule feature (if enabled)
   → Shows notification: "Schedule conflict detected"

5. User reviews
   → Opens planner
   → Sees conflicting session highlighted
   → Can manually move or regenerate plan
```

---

## Settings & Customization

### Calendar Settings
**File**: `Platforms/macOS/Views/CalendarSettingsView.swift`

```swift
struct CalendarSettingsView: View {
    @AppStorage("selectedSchoolCalendarID") var selectedSchoolCalendarID = ""
    @AppStorage("workdayStartHourStorage") var workdayStartHour = 9
    @AppStorage("workdayEndHourStorage") var workdayEndHour = 17
    @AppStorage("plannerHorizon") var plannerHorizon = 7  // days ahead
    
    var body: some View {
        Form {
            Picker("School Calendar", selection: $selectedSchoolCalendarID) {
                Text("All Calendars").tag("")
                ForEach(availableCalendars) { calendar in
                    Text(calendar.title).tag(calendar.calendarIdentifier)
                }
            }
            
            Stepper("Work Day Start: \(workdayStartHour):00", value: $workdayStartHour, in: 0...23)
            Stepper("Work Day End: \(workdayEndHour):00", value: $workdayEndHour, in: 0...23)
            Stepper("Plan Ahead: \(plannerHorizon) days", value: $plannerHorizon, in: 1...30)
        }
    }
}
```

**Effect**:
- `selectedSchoolCalendarID`: Filter which calendar to read events from
- `workdayStartHour`/`workdayEndHour`: Adjust available scheduling window
- `plannerHorizon`: How many days ahead to schedule

### Study Plan Settings
```swift
struct StudyPlanSettings {
    var examDefaultTotalMinutes: Int = 240        // 4 hours total
    var examDefaultSessionMinutes: Int = 60       // 1-hour sessions
    var examStartDaysBeforeDue: Int = 5           // Start 5 days early
    
    var quizDefaultTotalMinutes: Int = 90         // 1.5 hours
    var quizDefaultSessionMinutes: Int = 60
    var quizStartDaysBeforeDue: Int = 3
    
    var homeworkSingleSessionThreshold: Int = 60  // Single session if < 1 hour
    var longHomeworkSplitSessionMinutes: Int = 45 // Split into 45-min chunks
    
    var projectSessionMinutes: Int = 75           // Default project session
    var projectMinSessions: Int = 3               // At least 3 sessions
}
```

**Customization**: User can adjust per-category defaults in Settings

---

## Error Handling

### Permission Denied
```swift
enum CalendarRefreshError: Error {
    case permissionDenied
    case schedulingFailed
    case noCalendar
}

// Handle in coordinator
func runRefresh() async -> CalendarRefreshError? {
    guard authManager.isAuthorized else {
        error = .permissionDenied
        return .permissionDenied
    }
    // ... proceed ...
}

// Show in UI
if let error = calendarCoordinator.error {
    switch error {
    case .permissionDenied:
        Text("Calendar access denied. Enable in Settings.")
    case .schedulingFailed:
        Text("Failed to schedule sessions. Try again.")
    case .noCalendar:
        Text("No calendar selected. Choose one in Settings.")
    }
}
```

### Scheduling Failures
```swift
// If AutoScheduler can't find enough free time
if proposedBlocks.isEmpty {
    return ScheduleDiff(
        addedBlocks: [],
        conflicts: [],
        reason: "No available time slots",
        confidence: AIConfidence(0.0)
    )
}

// User sees
Text("⚠️ Could not find enough free time. Try:")
Text("• Extending work hours")
Text("• Reducing assignment estimates")
Text("• Scheduling over more days")
```

### EventKit Errors
```swift
do {
    try deviceCalendar.store.save(event, span: .thisEvent)
} catch {
    // Log and surface to user
    DebugLogger.log("Failed to save event: \(error)")
    throw ScheduleError.calendarWriteFailed
}
```

---

## Performance Optimizations

### 1. Incremental Refresh
```swift
// Only fetch changed date range
await deviceCalendar.refreshEvents(
    from: modifiedStart, 
    to: modifiedEnd, 
    reason: "incrementalUpdate"
)
```

### 2. Debounced Store Changes
```swift
// Don't refresh on every EKEventStoreChanged
private var refreshDebouncer: DispatchWorkItem?

func onStoreChanged() {
    refreshDebouncer?.cancel()
    refreshDebouncer = DispatchWorkItem { [weak self] in
        Task { await self?.refreshEventsForVisibleRange(reason: "debouncedStoreChange") }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: refreshDebouncer!)
}
```

### 3. Cached Free Slots
```swift
// Cache computed free slots per day
private var freeSlotCache: [Date: [TimeSlot]] = [:]

func findFreeSlots(for date: Date) -> [TimeSlot] {
    if let cached = freeSlotCache[date] {
        return cached
    }
    
    let computed = computeFreeSlots(for: date)
    freeSlotCache[date] = computed
    return computed
}
```

### 4. Background Fetching
```swift
// Fetch calendar events in background
Task.detached(priority: .background) {
    let events = await fetchEvents()
    await MainActor.run {
        self.events = events
    }
}
```

---

## Testing Scenarios

### Unit Tests
```swift
// Test free slot calculation
func testFindFreeSlots() {
    let existingEvents = [
        mockEvent(start: "10:00", end: "11:00"),
        mockEvent(start: "13:00", end: "14:00")
    ]
    
    let freeSlots = AutoScheduler.findFreeSlots(
        existingEvents: existingEvents,
        startDate: today,
        days: 1,
        startHour: 9,
        endHour: 17
    )
    
    XCTAssertEqual(freeSlots.count, 3)
    XCTAssertEqual(freeSlots[0].duration, 3600)  // 9-10 AM
    XCTAssertEqual(freeSlots[1].duration, 7200)  // 11 AM-1 PM
    XCTAssertEqual(freeSlots[2].duration, 10800) // 2-5 PM
}
```

### Integration Tests
```swift
// Test end-to-end scheduling
func testAutoScheduleWithConflicts() async {
    // Setup
    let assignment = Assignment(title: "Math HW", dueDate: tomorrow, estimatedMinutes: 120)
    assignmentsStore.addTask(assignment)
    
    // Add conflicting calendar event
    let conflict = mockCalendarEvent(start: tomorrow.addingTimeInterval(3600), duration: 3600)
    deviceCalendar.events = [conflict]
    
    // Run scheduler
    await coordinator.runRefresh()
    
    // Verify
    XCTAssertNotNil(coordinator.pendingScheduleSuggestion)
    XCTAssertEqual(coordinator.pendingScheduleSuggestion?.diff.conflicts.count, 1)
}
```

---

## Summary

### Key Characteristics

1. **User-Centric**: All scheduling requires explicit approval
2. **Non-Destructive**: Never auto-writes to calendar
3. **Conflict-Aware**: Detects and surfaces overlaps
4. **Adaptive**: Responds to external calendar changes
5. **Intelligent**: Prioritizes tasks, respects daily limits, finds optimal slots
6. **Transparent**: Shows exactly what will be added/changed

### Flow Diagram (Simplified)

```
User Creates Assignment
         ↓
  [Auto-Generate Sessions]
         ↓
  Fetch Calendar Events ← Apple Calendar (EventKit)
         ↓
  Find Free Time Slots
         ↓
  Generate Schedule Proposal (ScheduleDiff)
         ↓
  [USER REVIEWS]
     ↙       ↘
  Approve   Reject
     ↓         ↓
  Write to   Dismiss
  Calendar
     ↓
  Sync Complete
```

### Architecture Principles

- **Separation of Concerns**: Scheduling logic separate from calendar access
- **Immutable Proposals**: ScheduleDiff is read-only until applied
- **Explicit Approval**: UI layer enforces user consent
- **Observable State**: @Published properties drive reactive UI
- **Error Recovery**: Graceful handling of permission/API failures

### Future Enhancements

1. **Machine Learning**: Learn user preferences (preferred study times, session lengths)
2. **Smart Rescheduling**: Automatically propose reschedules when conflicts arise
3. **Cross-Device Sync**: Coordinate scheduling across iPhone/iPad/Mac
4. **Break Insertion**: Auto-add break sessions between long study blocks
5. **Deadline Warnings**: Alert if assignment can't fit in available time

---

**Status**: Fully implemented and operational as of January 2026 ✅
