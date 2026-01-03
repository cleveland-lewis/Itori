# Assignment Editor UX Improvements - SPECIFICATION

## Overview
Comprehensive improvements to the assignment editor focusing on:
1. Better default duration estimates
2. Smart category-based suggestions
3. Course-type multipliers
4. Learning from user behavior
5. Improved layout and alignment

## 1. Duration Estimation System

### Base Defaults by Category
Default "first session" estimates when user selects category:

```swift
enum AssignmentCategory {
    var baseEstimateMinutes: Int {
        switch self {
        case .reading: return 45
        case .homework: return 75
        case .review: return 60
        case .project: return 120
        case .exam: return 180
        case .quiz: return 30  // Added
        }
    }
    
    var stepSize: Int {
        switch self {
        case .reading, .review, .quiz: return 5
        case .homework: return 10
        case .project, .exam: return 15
        }
    }
}
```

### Course-Type Multipliers
Apply subtle multipliers based on course type:

```swift
enum CourseType {
    var durationMultipliers: [AssignmentCategory: Double] {
        switch self {
        case .regular:
            return [:] // All 1.0
            
        case .honors, .ap, .ib:
            return [
                .reading: 1.2,
                .homework: 1.2,
                .review: 1.2,
                .project: 1.2,
                .exam: 1.2
            ]
            
        case .seminar:
            return [
                .reading: 1.4,
                .homework: 0.9,
                .review: 1.2,
                .project: 1.2,
                .exam: 1.0
            ]
            
        case .lab:
            return [
                .reading: 0.9,
                .homework: 1.1,
                .review: 1.0,
                .project: 1.2,
                .exam: 1.0
            ]
            
        case .independentStudy, .thesis:
            return [
                .reading: 1.2,
                .homework: 1.0,
                .review: 1.2,
                .project: 1.4,
                .exam: 0.8
            ]
            
        case .clinical, .practicum:
            return [
                .reading: 0.8,
                .homework: 0.8,
                .review: 0.8,
                .project: 0.8,
                .exam: 0.8
            ]
        }
    }
}
```

### Learning from Completions
After ≥3 completed tasks in same course+category:

```swift
struct CategoryLearningData {
    let courseId: UUID
    let category: AssignmentCategory
    var completedCount: Int = 0
    var averageMinutes: Double = 0
    
    // EWMA (Exponentially Weighted Moving Average)
    mutating func record(actualMinutes: Int) {
        let alpha = 0.3 // Weight for new data
        if completedCount == 0 {
            averageMinutes = Double(actualMinutes)
        } else {
            averageMinutes = alpha * Double(actualMinutes) + (1 - alpha) * averageMinutes
        }
        completedCount += 1
    }
    
    var hasEnoughData: Bool {
        completedCount >= 3
    }
}
```

### Estimation Logic
```swift
func estimatedDuration(
    category: AssignmentCategory,
    course: Course
) -> Int {
    // Check for learned data first
    if let learned = getLearningData(courseId: course.id, category: category),
       learned.hasEnoughData {
        return Int(learned.averageMinutes.rounded())
    }
    
    // Otherwise use base × multiplier
    let base = category.baseEstimateMinutes
    let multiplier = course.courseType.durationMultipliers[category] ?? 1.0
    let estimated = Double(base) * multiplier
    
    // Round to step size
    let stepSize = category.stepSize
    return Int((estimated / Double(stepSize)).rounded()) * stepSize
}
```

## 2. Decomposition Suggestions

### Hint Text Under Estimated Field
Show typical breakdown:

```swift
func decompositionHint(
    category: AssignmentCategory,
    estimatedMinutes: Int,
    dueDate: Date
) -> String {
    let now = Date()
    let daysUntilDue = Calendar.current.dateComponents([.day], from: now, to: dueDate).day ?? 0
    
    switch category {
    case .reading:
        return "Typically: 1 × \(estimatedMinutes)m same day"
        
    case .homework:
        return "Typically: 2 × \(estimatedMinutes)m over 2 days"
        
    case .review:
        if daysUntilDue >= 7 {
            let sessionTime = estimatedMinutes / 3
            return "Typically: 3 × \(sessionTime)m spaced (today +2d +5d)"
        } else {
            return "Typically: 2 × \(estimatedMinutes / 2)m over \(min(daysUntilDue, 2)) days"
        }
        
    case .project:
        if daysUntilDue >= 14 {
            let sessionTime = estimatedMinutes / 4
            return "Typically: 4 × \(sessionTime)m across weeks"
        } else {
            let sessions = max(2, daysUntilDue / 3)
            let sessionTime = estimatedMinutes / sessions
            return "Typically: \(sessions) × \(sessionTime)m compressed"
        }
        
    case .exam:
        if daysUntilDue >= 10 {
            let sessionTime = estimatedMinutes / 5
            return "Typically: 5 × \(sessionTime)m spaced, last within 24h of due"
        } else {
            let sessions = max(3, daysUntilDue / 2)
            let sessionTime = estimatedMinutes / sessions
            return "Typically: \(sessions) × \(sessionTime)m compressed"
        }
        
    case .quiz:
        return "Typically: 1 × \(estimatedMinutes)m within 24h of due"
    }
}
```

## 3. UI Layout Improvements

### Lock Toggle Alignment
```swift
// Before
Toggle("Lock to date", isOn: $lockToDueDate)

// After
HStack {
    VStack(alignment: .trailing, spacing: 2) {
        Text("Lock")
            .font(.body)
        Text("Lock work to due date")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    Toggle("", isOn: $lockToDueDate)
        .labelsHidden()
}
.frame(maxWidth: .infinity, alignment: .trailing)
```

### Right-Aligned Controls
All toggles and pickers should align right with labels left:

```swift
HStack {
    Text("Label")
        .frame(maxWidth: .infinity, alignment: .leading)
    
    Picker("", selection: $value) {
        // options
    }
    .labelsHidden()
    .frame(width: 120, alignment: .trailing)
}
```

### Duration Input with Hint
```swift
VStack(alignment: .leading, spacing: 4) {
    HStack {
        Text("Estimated")
            .font(.body)
        
        Spacer()
        
        Stepper(value: $estimatedMinutes, in: 15...240, step: stepSize) {
            Text("\(estimatedMinutes) min")
        }
    }
    
    Text(decompositionHint(category: type, estimatedMinutes: estimatedMinutes, dueDate: due))
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

## 4. Implementation Files

### New Files to Create
1. **DurationEstimator.swift** - Estimation logic
2. **CategoryLearningService.swift** - Track completions
3. **CourseTypeMultipliers.swift** - Multiplier definitions

### Files to Modify
1. **AddAssignmentView.swift** - Update UI layout
2. **AssignmentCategory extension** - Add baseEstimate, stepSize
3. **CourseType extension** - Add multipliers
4. **AppSettingsModel.swift** - Store learning data

## 5. Data Model

### Learning Data Storage
```swift
// In AppSettingsModel
@AppStorage("roots.learning.categoryDurations") 
private var categoryDurationsData: Data = Data()

var categoryLearningData: [String: CategoryLearningData] {
    get {
        guard let decoded = try? JSONDecoder().decode(
            [String: CategoryLearningData].self, 
            from: categoryDurationsData
        ) else { return [:] }
        return decoded
    }
    set {
        if let encoded = try? JSONEncoder().encode(newValue) {
            categoryDurationsData = encoded
        }
    }
}
```

### Key Format
```swift
func learningKey(courseId: UUID, category: AssignmentCategory) -> String {
    "\(courseId.uuidString)_\(category.rawValue)"
}
```

## 6. Integration Points

### On Category Change
```swift
.onChange(of: type) { oldValue, newValue in
    // Update estimate based on new category
    if let course = coursesStore.courses.first(where: { $0.id == selectedCourseId }) {
        estimatedMinutes = estimatedDuration(category: newValue, course: course)
    } else {
        estimatedMinutes = newValue.baseEstimateMinutes
    }
}
```

### On Course Change
```swift
.onChange(of: selectedCourseId) { oldValue, newValue in
    guard let courseId = newValue,
          let course = coursesStore.courses.first(where: { $0.id == courseId }) else {
        return
    }
    
    // Update estimate based on course type
    estimatedMinutes = estimatedDuration(category: type, course: course)
}
```

### On Task Completion
```swift
func recordCompletion(task: AppTask, actualMinutes: Int) {
    guard let courseId = task.courseId else { return }
    
    let key = learningKey(courseId: courseId, category: task.category)
    var data = settings.categoryLearningData
    var learning = data[key] ?? CategoryLearningData(
        courseId: courseId,
        category: task.category
    )
    
    learning.record(actualMinutes: actualMinutes)
    data[key] = learning
    settings.categoryLearningData = data
}
```

## 7. Design Constraints

### Never Change Data Model Based on Category
✅ **DO:**
- Change default estimate
- Change decomposition suggestion
- Provide analytics insights

❌ **DON'T:**
- Change underlying task structure
- Force specific plan layouts
- Lock behavior based on category

Category is a **hint for estimation**, not a constraint on behavior.

## Summary

This system provides:
1. **Smart defaults** - Based on category and course type
2. **Adaptive learning** - Gets better with user data
3. **Helpful guidance** - Clear decomposition hints
4. **Clean UI** - Right-aligned controls, better spacing
5. **Non-invasive** - Doesn't lock user into rigid structures

The key insight: **Category affects estimation, not enforcement.**
