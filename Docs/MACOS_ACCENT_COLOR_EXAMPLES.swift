// MARK: - Accent Color Refactoring Examples
// Practical before/after examples for common macOS views

import SwiftUI

// MARK: - Example 1: Calendar Day Cell

// BEFORE (Hard-coded accent colors)
struct CalendarDayCell_Before: View {
    let day: CalendarDay
    
    var body: some View {
        Text("\(day.number)")
            .foregroundColor(day.isToday ? .white : .primary)
            .background(
                Circle()
                    .fill(day.isSelected ? Color.accentColor : Color.clear)  // ← Hard-coded
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        day.isToday ? Color.accentColor.opacity(0.4) : .clear,  // ← Hard-coded
                        lineWidth: 2
                    )
            )
    }
}

// AFTER (Centralized accent color)
struct CalendarDayCell_After: View {
    let day: CalendarDay
    
    var body: some View {
        Text("\(day.number)")
            .foregroundColor(day.isToday ? .white : .primary)
            .background(
                Circle()
                    .fill(day.isSelected ? DesignSystem.Colors.accent : Color.clear)  // ✅
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        day.isToday ? DesignSystem.Colors.accent.opacity(0.4) : .clear,  // ✅
                        lineWidth: 2
                    )
            )
    }
}

// MARK: - Example 2: Segmented Picker

// BEFORE
struct ViewModePicker_Before: View {
    @Binding var mode: CalendarViewMode
    
    var body: some View {
        Picker("View", selection: $mode) {
            ForEach(CalendarViewMode.allCases) { m in
                Text(m.title).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .tint(.blue)  // ← Hard-coded
    }
}

// AFTER (Option 1: Use DesignSystem)
struct ViewModePicker_After1: View {
    @Binding var mode: CalendarViewMode
    
    var body: some View {
        Picker("View", selection: $mode) {
            ForEach(CalendarViewMode.allCases) { m in
                Text(m.title).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .tint(DesignSystem.Colors.accent)  // ✅ Explicit
    }
}

// AFTER (Option 2: Rely on global tint - PREFERRED)
struct ViewModePicker_After2: View {
    @Binding var mode: CalendarViewMode
    
    var body: some View {
        Picker("View", selection: $mode) {
            ForEach(CalendarViewMode.allCases) { m in
                Text(m.title).tag(m)
            }
        }
        .pickerStyle(.segmented)
        // ✅ No .tint() needed - inherits from ItoriApp global tint
    }
}

// MARK: - Example 3: Button with Hover State

// BEFORE
struct ActionButton_Before: View {
    let action: () -> Void
    @State private var hovering = false
    
    var body: some View {
        Button(action: action) {
            Label("Action", systemImage: "star")
        }
        .foregroundColor(.blue)  // ← Hard-coded
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hovering ? Color.blue.opacity(0.15) : .clear)  // ← Hard-coded
        )
        .onHover { hovering = $0 }
    }
}

// AFTER (Using convenience modifier)
struct ActionButton_After: View {
    let action: () -> Void
    @State private var hovering = false
    
    var body: some View {
        Button(action: action) {
            Label("Action", systemImage: "star")
        }
        .foregroundColor(DesignSystem.Colors.accent)  // ✅
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hovering ? DesignSystem.Colors.accent.opacity(0.15) : .clear)  // ✅
        )
        .onHover { hovering = $0 }
    }
}

// AFTER (Using extension - PREFERRED)
struct ActionButton_AfterBest: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Action", systemImage: "star")
                .accentedHover()  // ✅ Convenience modifier
        }
    }
}

// MARK: - Example 4: Selection Highlight

// BEFORE
struct ListRow_Before: View {
    let item: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(item)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.2) : .clear)  // ← Hard-coded
        )
        .foregroundColor(isSelected ? .blue : .primary)  // ← Hard-coded
    }
}

// AFTER
struct ListRow_After: View {
    let item: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(item)
            Spacer()
        }
        .padding()
        .accentedSelection(isSelected: isSelected)  // ✅ Convenience modifier
    }
}

// MARK: - Example 5: Toggle (No Change Needed)

// BEFORE & AFTER (Already correct)
struct SettingsToggle: View {
    @Binding var enabled: Bool
    
    var body: some View {
        Toggle("Feature enabled", isOn: $enabled)
        // ✅ Automatically uses accent color from global .tint() in ItoriApp
        // No explicit .tint() needed
    }
}

// MARK: - Example 6: Semantic Colors (Do NOT Change)

// BEFORE & AFTER (Intentionally unchanged)
struct EventPill_Semantic: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack {
            Circle()
                .fill(event.category.color)  // ✅ Semantic color - DO NOT change
                .frame(width: 8, height: 8)
            
            Text(event.title)
        }
        .semanticColor()  // ✅ Documentation marker
    }
}

// MARK: - Example 7: Course Color (Do NOT Change)

// BEFORE & AFTER (Intentionally unchanged)
struct CourseCard_Semantic: View {
    let course: Course
    
    var body: some View {
        VStack {
            Text(course.title)
        }
        .background(course.color)  // ✅ Semantic color - DO NOT change
        .semanticColor()  // ✅ Documentation marker
    }
}

// MARK: - Example 8: Navigation Chevron

// BEFORE
struct NavigationButton_Before: View {
    let direction: Direction
    let action: () -> Void
    @State private var hovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: direction.icon)
                .foregroundColor(hovering ? .blue : .primary)  // ← Hard-coded
        }
        .onHover { hovering = $0 }
    }
}

// AFTER
struct NavigationButton_After: View {
    let direction: Direction
    let action: () -> Void
    @State private var hovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: direction.icon)
                .foregroundColor(hovering ? DesignSystem.Colors.accent : .primary)  // ✅
        }
        .onHover { hovering = $0 }
    }
}

// MARK: - Example 9: Progress Indicator

// BEFORE
struct ProgressView_Before: View {
    let progress: Double
    
    var body: some View {
        ProgressView(value: progress)
            .tint(.blue)  // ← Hard-coded
    }
}

// AFTER
struct ProgressView_After: View {
    let progress: Double
    
    var body: some View {
        ProgressView(value: progress)
            // ✅ No .tint() needed - inherits from global tint
    }
}

// MARK: - Example 10: Status Indicator (Do NOT Change)

// BEFORE & AFTER (Intentionally unchanged)
struct StatusBadge_Semantic: View {
    let status: TaskStatus
    
    var body: some View {
        Text(status.label)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor(for: status))  // ✅ Semantic color
            )
            .semanticColor()  // ✅ Documentation marker
    }
    
    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .notStarted: return .gray
        case .inProgress: return .blue  // ✅ Semantic blue (not accent)
        case .completed: return .green  // ✅ Semantic green
        case .overdue: return .red      // ✅ Semantic red
        }
    }
}

// MARK: - Supporting Types

struct CalendarDay {
    let number: Int
    let isToday: Bool
    let isSelected: Bool
}

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case day, week, month
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum Direction {
    case left, right
    var icon: String {
        switch self {
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        }
    }
}

struct CalendarEvent {
    let title: String
    let category: EventCategory
}

enum EventCategory {
    case study, homework, exam, lab, class, reading, review, other
    
    var color: Color {
        switch self {
        case .study: return .blue
        case .homework: return .purple
        case .exam: return .red
        case .lab: return .green
        case .class: return .orange
        case .reading: return .cyan
        case .review: return .yellow
        case .other: return .gray
        }
    }
}

struct Course {
    let title: String
    let color: Color
}

enum TaskStatus {
    case notStarted, inProgress, completed, overdue
    var label: String { String(describing: self) }
}
