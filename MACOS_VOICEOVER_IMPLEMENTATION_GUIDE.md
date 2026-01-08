# macOS VoiceOver Implementation Guide

**Date:** January 8, 2026  
**Status:** In Progress  
**Target:** 80%+ VoiceOver Coverage

---

## Overview

This guide provides VoiceOver accessibility labels for macOS-specific views in the Itori app. macOS uses AppKit accessibility APIs which work similarly to iOS but with some platform-specific considerations.

---

## Implementation Status

### ✅ Completed (Session 1)
- [x] **DashboardView** - Energy button, event rows, add event button
- [x] **TimerPageView** - Focus window button, pause/stop controls (partial)

### 🔄 In Progress
- [ ] **TimerPageView** - Timer controls, activity selection
- [ ] **AssignmentsPageView** - Assignment rows, filters
- [ ] **CoursesPageView** - Course cards, semester selector
- [ ] **GradesPageView** - Grade cards, chart
- [ ] **PlannerPageView** - Planning cards, task rows
- [ ] **SettingsView** - All settings controls

### ⏳ Pending
- [ ] Calendar views
- [ ] Flashcards views
- [ ] Practice test views
- [ ] Supporting views and sheets

---

## macOS VoiceOver Patterns

### Pattern 1: Basic Button Labels

```swift
Button("Add") {
    showAddSheet = true
}
.accessibilityLabel("Add assignment")
.accessibilityHint("Opens form to create a new assignment")
```

### Pattern 2: Icon-Only Buttons

```swift
Button(action: openSettings) {
    Image(systemName: "gear")
}
.accessibilityLabel("Settings")
.accessibilityHint("Opens app settings")
```

### Pattern 3: List Items / Rows

```swift
HStack {
    Text(item.title)
    Spacer()
    Text(item.subtitle)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(item.title), \(item.subtitle)")
.accessibilityHint("Double-click for options")
```

### Pattern 4: Decorative Elements

```swift
Circle()
    .fill(.blue)
    .frame(width: 8, height: 8)
    .accessibilityHidden(true)
```

### Pattern 5: Timer/Counter Display

```swift
Text(timeRemaining)
    .font(.largeTitle)
    .accessibilityLabel("\(minutesRemaining) minutes, \(secondsRemaining) seconds remaining")
    .accessibilityAddTraits(.updatesFrequently)
```

### Pattern 6: Status Indicators

```swift
Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
    .accessibilityLabel(task.isCompleted ? "Completed" : "Not completed")
    .accessibilityAddTraits(.isButton)
```

---

## Key Files to Update

### 1. DashboardView.swift ✅ (Partial)

**Completed:**
- Energy level button
- Add event button  
- View all events button
- Event rows with contextual info

**Remaining:**
- Assignment rows
- Grade widgets
- Study trend chart
- Today's tasks card
- Calendar preview

**Example Implementation:**

```swift
// Assignment row
HStack {
    VStack(alignment: .leading) {
        Text(assignment.title)
        Text(assignment.courseName)
            .foregroundStyle(.secondary)
    }
    Spacer()
    Text(assignment.dueDate, style: .relative)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(assignment.title), \(assignment.courseName), due \(assignment.dueDate, style: .relative)")
.accessibilityHint("Double-click to view details")

// Study chart
Chart(data) { ... }
    .accessibilityLabel("Study hours chart")
    .accessibilityValue("\(totalHours) hours this week")
    .accessibilityHint("Shows study time trend")
```

---

### 2. TimerPageView.swift ✅ (Partial)

**Completed:**
- Focus window button
- Pause button
- Stop button

**Remaining:**
- Start button
- Activity selection
- Timer mode picker
- Pomodoro session indicators
- Time input controls

**Example Implementation:**

```swift
// Start button
Button(action: startTimer) {
    Label("Start", systemImage: "play.fill")
}
.accessibilityLabel("Start timer")
.accessibilityHint("Begins countdown timer")

// Activity picker
ForEach(activities) { activity in
    Button(activity.name) {
        selectedActivity = activity
    }
    .accessibilityLabel("\(activity.name) activity")
    .accessibilityAddTraits(selectedActivity == activity ? [.isSelected] : [])
}

// Pomodoro progress
HStack {
    ForEach(0..<totalSessions, id: \.self) { index in
        Circle()
            .fill(index < completed ? Color.accentColor : Color.secondary)
            .frame(width: 8, height: 8)
    }
}
.accessibilityElement(children: .ignore)
.accessibilityLabel("Pomodoro session progress")
.accessibilityValue("\(completed) of \(totalSessions) sessions complete")
```

---

### 3. AssignmentsPageView.swift

**Needs:**
- Assignment row labels
- Filter buttons
- Sort options
- Add assignment button
- Completion toggle

**Example Implementation:**

```swift
// Assignment row with all context
VStack(alignment: .leading) {
    Text(assignment.title)
    HStack {
        Text(course.code)
        Text(assignment.type.rawValue)
        Text(assignment.priority.label)
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(assignment.title), \(course.code) \(course.name), \(assignment.type.rawValue), \(assignment.priority.label), due \(assignment.dueDate)")
.accessibilityHint("Double-click to edit")

// Filter button
Button("Today") {
    filter = .today
}
.accessibilityLabel("Filter by today")
.accessibilityAddTraits(filter == .today ? [.isSelected] : [])

// Completion checkbox
Button(action: { toggleCompletion(assignment) }) {
    Image(systemName: assignment.isCompleted ? "checkmark.square.fill" : "square")
}
.accessibilityLabel(assignment.isCompleted ? "Mark incomplete" : "Mark complete")
.accessibilityHint("Toggles assignment completion status")
```

---

### 4. CoursesPageView.swift

**Needs:**
- Course card labels
- Semester picker
- Add course button
- Course actions (edit, delete, archive)
- Grade display in course card

**Example Implementation:**

```swift
// Course card
VStack(alignment: .leading) {
    HStack {
        Circle().fill(course.color)
        Text(course.code)
    }
    Text(course.title)
    if let grade = course.currentGrade {
        Text("\(grade.percent)% - \(grade.letter)")
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(course.code) \(course.title)\(course.currentGrade.map { ", current grade \($0.percent) percent, \($0.letter)" } ?? "")")
.accessibilityHint("Double-click for course details")

// Semester picker
Picker("Semester", selection: $selectedSemester) {
    ForEach(semesters) { semester in
        Text(semester.name).tag(semester.id)
    }
}
.accessibilityLabel("Select semester")
.accessibilityValue(selectedSemester?.name ?? "None")
```

---

### 5. GradesPageView.swift

**Needs:**
- Grade card labels
- GPA display
- Grade chart
- Course grade rows
- Grade calculator

**Example Implementation:**

```swift
// GPA card
VStack {
    Text("GPA")
    Text(String(format: "%.2f", gpa))
        .font(.largeTitle)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("GPA \(String(format: "%.2f", gpa))")

// Grade row
HStack {
    Text(course.code)
    Spacer()
    Text("\(grade.percent)%")
    Text(grade.letter)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(course.code), \(grade.percent) percent, \(grade.letter) grade")

// Grade chart
Chart(grades) { ... }
    .accessibilityLabel("Grades over time chart")
    .accessibilityValue("\(courses.count) courses, average \(averageGrade)%")
```

---

### 6. PlannerPageView.swift

**Needs:**
- Task card labels
- Date picker
- Time blocks
- Schedule view
- Planning suggestions

**Example Implementation:**

```swift
// Planned task block
VStack(alignment: .leading) {
    Text(task.title)
    Text("\(startTime) - \(endTime)")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(task.title), scheduled from \(startTime) to \(endTime)")
.accessibilityHint("Double-click to reschedule")

// Time block
Button(action: { scheduleTask(at: time) }) {
    Text(time.formatted(date: .omitted, time: .shortened))
}
.accessibilityLabel("Schedule at \(time.formatted(date: .omitted, time: .shortened))")
.accessibilityHint("Assigns task to this time slot")
```

---

### 7. SettingsView.swift

**Needs:**
- All toggle switches
- All pickers
- All text fields
- All sliders
- Navigation links

**Example Implementation:**

```swift
// Toggle
Toggle("Enable notifications", isOn: $enableNotifications)
    .accessibilityLabel("Enable notifications")
    .accessibilityValue(enableNotifications ? "On" : "Off")

// Picker
Picker("Theme", selection: $theme) {
    Text("Light").tag(Theme.light)
    Text("Dark").tag(Theme.dark)
    Text("Auto").tag(Theme.auto)
}
.accessibilityLabel("Theme")
.accessibilityValue(theme.rawValue)

// Slider
Slider(value: $volume, in: 0...100)
    .accessibilityLabel("Volume")
    .accessibilityValue("\(Int(volume)) percent")

// Navigation link
NavigationLink("About") {
    AboutView()
}
.accessibilityLabel("About")
.accessibilityHint("Navigate to about page")
```

---

## macOS-Specific Considerations

### 1. Menu Bar Integration
macOS apps often have menu bar actions. Ensure keyboard shortcuts are properly labeled:

```swift
.keyboardShortcut("n", modifiers: .command)
.accessibilityLabel("New item")
.accessibilityHint("Command-N")
```

### 2. Window Management
macOS apps can have multiple windows. Label window-related controls:

```swift
Button(action: openNewWindow) {
    Image(systemName: "plus.rectangle")
}
.accessibilityLabel("New window")
.accessibilityHint("Opens content in new window")
```

### 3. Toolbars
Toolbar items need labels:

```swift
ToolbarItem {
    Button(action: refresh) {
        Image(systemName: "arrow.clockwise")
    }
    .accessibilityLabel("Refresh")
}
```

### 4. Context Menus
Context menu items inherit system labels, but custom ones need attention:

```swift
.contextMenu {
    Button("Duplicate") { duplicate() }
        .accessibilityLabel("Duplicate item")
    Button("Delete") { delete() }
        .accessibilityLabel("Delete item")
}
```

---

## Testing macOS VoiceOver

### Enable VoiceOver
1. Press `Command + F5` to toggle VoiceOver
2. Or: System Settings > Accessibility > VoiceOver

### VoiceOver Commands
- `Control + Option + Arrow Keys` - Navigate
- `Control + Option + Space` - Activate
- `Control + Option + H` - Help menu
- `Control + Option + A` - Start reading

### Testing Checklist
- [ ] All buttons have labels
- [ ] All icons have labels
- [ ] Lists can be navigated item by item
- [ ] Forms can be filled with VoiceOver
- [ ] Dynamic content announces changes
- [ ] Charts/graphs have meaningful descriptions
- [ ] Decorative elements are hidden
- [ ] Keyboard navigation works

---

## Quick Wins

### High-Impact, Low-Effort Changes

1. **Add labels to all icon-only buttons** (5 min each view)
2. **Combine multi-element rows** (5 min each view)
3. **Hide decorative circles/dividers** (2 min each view)
4. **Label all charts** (10 min each chart)
5. **Add hints to primary actions** (5 min each view)

### Priority Order
1. **Dashboard** (most used)
2. **Timer** (core feature)
3. **Assignments** (daily use)
4. **Courses** (frequent use)
5. **Settings** (important but less frequent)
6. **Other views** (as needed)

---

## Common Patterns Reference

### Button with Icon
```swift
.accessibilityLabel("Action name")
.accessibilityHint("What it does")
```

### List Row
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("Combined text")
```

### Decorative
```swift
.accessibilityHidden(true)
```

### Dynamic Content
```swift
.accessibilityAddTraits(.updatesFrequently)
```

### Chart/Graph
```swift
.accessibilityLabel("Chart type")
.accessibilityValue("Summary")
```

---

## Next Steps

1. **Complete Timer page** - Add remaining labels
2. **Implement Assignments page** - Full coverage
3. **Implement Courses page** - Cards and actions
4. **Implement Grades page** - Charts and rows
5. **Implement Planner page** - Schedule blocks
6. **Implement Settings** - All controls
7. **Test with VoiceOver** - Full app walkthrough
8. **Document coverage** - Create audit report

---

## Resources

- [Apple: Accessibility on macOS](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [SwiftUI Accessibility](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [VoiceOver Testing Guide](https://developer.apple.com/library/archive/technotes/TestingAccessibilityOfiOSApps/TestAccessibilityonYourDevicewithVoiceOver/TestAccessibilityonYourDevicewithVoiceOver.html)

---

**Status:** Foundation laid, ~20% complete, ready for systematic implementation.
