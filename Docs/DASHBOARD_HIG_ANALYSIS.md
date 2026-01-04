# Dashboard UI Analysis & Apple HIG Compliance

## Current Dashboard Analysis

### Overview
The Itori dashboard uses a card-based layout with 6 main cards arranged in a 2-column grid:
1. **Today Overview** - Stats for events and tasks due today
2. **Clock & Calendar** - Analog clock + mini calendar
3. **Events** - Upcoming calendar events
4. **Assignments** - Due assignments
5. **Energy** - Quick energy level setting
6. **Study Hours** - Time tracking stats (optional)

### Layout Structure
```
┌─────────────────┬─────────────────┐
│  Today Overview │ Clock & Calendar│
├─────────────────┼─────────────────┤
│     Events      │   Assignments   │
├─────────────────┼─────────────────┤
│     Energy      │  Study Hours    │
└─────────────────┴─────────────────┘
```

## Apple HIG Compliance Issues

### ❌ Layout & Spacing
1. **Fixed 2-column grid** - Not adaptive to window size
   - HIG: "Design for resizing and different window sizes"
   - Issue: Cards don't reflow or adapt to narrow windows
   - Fix: Use adaptive grid that switches to 1-column on narrow windows

2. **Inconsistent spacing** - Mix of hardcoded values
   - `rowSpacing: 24`, `columnSpacing: 24`, `bottomDockClearancePadding: 120`
   - HIG: Use system-provided spacing
   - Fix: Use `DesignSystem.Layout.spacing` consistently

3. **Fixed card heights** - Some cards have `minHeight: 160`
   - HIG: Let content determine height naturally
   - Fix: Remove fixed heights, use proper content sizing

### ❌ Visual Design
1. **Custom card component (`ItoriCard`)**
   - Should use native macOS materials and vibrancy
   - Missing proper hover/focus states
   - No proper corner radius (should be 10pt for cards)

2. **Color usage** - Custom background colors
   - `Color(nsColor: .controlBackgroundColor).opacity(0.8)`
   - HIG: Use semantic colors and materials
   - Fix: Use `.background(.regularMaterial)` or `.quaternary`

3. **Typography** - Custom text styles
   - `.rootsBody()`, `.rootsSectionHeader()`
   - HIG: Use system text styles
   - Fix: `.font(.body)`, `.font(.headline)`

### ❌ Interactions
1. **Card tap handlers** - `onTapGesture` with print statements
   - Cards are tappable but provide no visual feedback
   - No clear indication of what happens on tap
   - Fix: Remove unnecessary tap handlers or add proper navigation

2. **Button styles** - Mix of custom styles
   - `.borderedProminent`, `ItoriLiquidButtonStyle()`
   - HIG: Use consistent native button styles
   - Fix: Standardize on `.borderedProminent` or `.bordered`

3. **No keyboard navigation**
   - Dashboard cards not keyboard-accessible
   - Fix: Add proper focus management

### ❌ Content & Hierarchy
1. **Today Overview shows only counts**
   - "Events Today: 3" - Not actionable
   - HIG: Show actionable content or quick actions
   - Fix: Show actual events/tasks with quick actions

2. **Energy card placement** - Unclear purpose
   - "High/Medium/Low" buttons don't explain what they do
   - HIG: Provide clear labels and context
   - Fix: Add descriptive text or move to settings

3. **Study Hours card** - Read-only stats
   - No actions, just displays numbers
   - HIG: Make widgets actionable
   - Fix: Add "Start Timer" or "View Details" button

### ❌ Accessibility
1. **Poor VoiceOver labels**
   - Cards just say "Today Overview" without content
   - Fix: Provide meaningful accessibility descriptions

2. **No Dynamic Type support**
   - Fixed font sizes in several places
   - Fix: Use relative font sizes with `.font(.body)` etc.

3. **Color contrast issues**
   - `.opacity(0.8)` reduces contrast
   - Fix: Use semantic colors without opacity adjustments

### ❌ Performance
1. **Redundant state updates**
   - Multiple `.onReceive` handlers that all call `syncTasks()`
   - Fix: Consolidate data syncing logic

2. **No placeholder states**
   - Empty states not handled gracefully
   - Fix: Add proper empty state views

## Apple HIG Recommendations

### ✅ What's Good
1. **Scroll view for overflow** - Proper scrolling
2. **System icons** - Using SF Symbols
3. **Padding for dock** - Bottom clearance for macOS dock
4. **Animation on appear** - Nice entry animations
5. **Environment objects** - Proper data flow

### 📋 Layout Best Practices (HIG)

1. **Use Adaptive Grid**
   ```swift
   LazyVGrid(columns: [
       GridItem(.adaptive(minimum: 300, maximum: 500))
   ], spacing: 20)
   ```

2. **System Spacing**
   - Small: 8pt
   - Medium: 16pt
   - Large: 24pt
   - Extra Large: 32pt

3. **Corner Radius**
   - Cards: 10pt
   - Buttons: 6pt (default)
   - Full rounded: Use `.clipShape(.rect(cornerRadius: 10))`

### 📋 Color & Materials (HIG)

1. **Background Hierarchy**
   ```swift
   // Primary background
   .background(.background)
   
   // Secondary (cards)
   .background(.regularMaterial)
   or
   .background(.quaternary)
   
   // Tertiary (nested content)
   .background(.quinary)
   ```

2. **Text Colors**
   ```swift
   .foregroundStyle(.primary)    // Main text
   .foregroundStyle(.secondary)  // Supporting text
   .foregroundStyle(.tertiary)   // Disabled text
   ```

3. **Semantic Colors**
   ```swift
   Color.accentColor  // App accent
   .tint(.blue)       // System blue
   .foreground(.red)  // Destructive actions
   ```

### 📋 Typography (HIG)

Use system text styles:
```swift
.font(.largeTitle)   // 34pt, headlines
.font(.title)        // 28pt, section headers
.font(.title2)       // 22pt, subsection headers
.font(.title3)       // 20pt, group headers
.font(.headline)     // 17pt bold, emphasized content
.font(.body)         // 17pt, primary content
.font(.callout)      // 16pt, secondary content
.font(.subheadline)  // 15pt, less important content
.font(.footnote)     // 13pt, captions
.font(.caption)      // 12pt, supplementary
.font(.caption2)     // 11pt, smallest text
```

### 📋 Interactive Elements (HIG)

1. **Buttons**
   ```swift
   Button("Action") { }
   .buttonStyle(.bordered)          // Default
   .buttonStyle(.borderedProminent) // Primary action
   .buttonStyle(.plain)             // Subtle action
   .controlSize(.small/.regular/.large)
   ```

2. **Click Targets**
   - Minimum: 44x44pt (macOS: 32x32pt acceptable)
   - Padding: 8-12pt around text/icon

3. **Hover Effects**
   - Use `.buttonStyle` which provides automatic hover
   - For custom: `.contentShape(.rect)` + `.hoverEffect()`

### 📋 Widgets & Cards (HIG)

1. **Widget-like Cards**
   ```swift
   VStack(alignment: .leading, spacing: 12) {
       // Header
       Label("Title", systemImage: "icon")
           .font(.headline)
       
       // Content
       Text("Content")
           .font(.body)
           .foregroundStyle(.secondary)
       
       // Action (optional)
       Button("Action") { }
           .buttonStyle(.bordered)
   }
   .padding(16)
   .background(.regularMaterial)
   .clipShape(.rect(cornerRadius: 10))
   ```

2. **Empty States**
   ```swift
   ContentUnavailableView(
       "No Events",
       systemImage: "calendar",
       description: Text("Events will appear here")
   )
   ```

## Recommended Improvements

### Priority 1: Critical (HIG Violations)

1. **✅ Adaptive Layout**
   - Switch to `LazyVGrid` with `.adaptive` sizing
   - Single column on windows < 600pt wide
   - Two columns on windows 600-900pt
   - Three columns on windows > 900pt

2. **✅ Native Materials**
   - Replace custom backgrounds with `.regularMaterial`
   - Remove opacity adjustments
   - Use semantic color hierarchy

3. **✅ System Typography**
   - Replace custom text styles with `.font(.body)`, `.font(.headline)`, etc.
   - Support Dynamic Type

4. **✅ Proper Button Styles**
   - Use `.borderedProminent` for primary actions
   - Use `.bordered` for secondary actions
   - Remove custom button styles

### Priority 2: Important (UX Issues)

1. **✅ Actionable Content**
   - Today card: Show quick add buttons
   - Events card: Add "View All" button
   - Assignments card: Add "Add Assignment" button
   - Each card should have a clear action

2. **✅ Empty States**
   - Use `ContentUnavailableView` for empty cards
   - Provide context and actions

3. **✅ Loading States**
   - Show skeleton/placeholder while loading
   - Use `.redacted(reason: .placeholder)`

4. **✅ Error Handling**
   - Show errors inline with retry button
   - Don't fail silently

### Priority 3: Polish (Nice to Have)

1. **✅ Hover Effects**
   - Cards should show subtle hover state
   - Buttons already have hover (native)

2. **✅ Animations**
   - Smooth transitions between states
   - Use `.animation(.smooth)` sparingly

3. **✅ Contextual Menus**
   - Right-click on cards for quick actions
   - Use `.contextMenu { }`

4. **✅ Keyboard Shortcuts**
   - Cmd+N for new assignment
   - Cmd+E for new event
   - Tab navigation between cards

## Implementation Plan

### Phase 1: Layout & Structure (2-3 hours)
- [ ] Replace 2-column grid with adaptive grid
- [ ] Update spacing to use system constants
- [ ] Remove fixed heights
- [ ] Test on various window sizes

### Phase 2: Visual Design (2-3 hours)
- [ ] Replace backgrounds with `.regularMaterial`
- [ ] Update all text to use system fonts
- [ ] Standardize button styles
- [ ] Add proper corner radius (10pt)

### Phase 3: Content & Actions (3-4 hours)
- [ ] Add actionable content to Today card
- [ ] Add quick actions to each card
- [ ] Implement empty states
- [ ] Add loading states

### Phase 4: Accessibility (1-2 hours)
- [ ] Improve VoiceOver labels
- [ ] Test with Dynamic Type
- [ ] Add keyboard navigation
- [ ] Test color contrast

### Phase 5: Polish (2-3 hours)
- [ ] Add hover effects
- [ ] Refine animations
- [ ] Add context menus
- [ ] Add keyboard shortcuts

**Total Estimated Time: 10-15 hours**

## Code Examples

### Before (Current)
```swift
ItoriCard(title: "Today Overview", icon: "sun.max") {
    VStack(alignment: .leading, spacing: ItoriSpacing.m) {
        DashboardTileBody(
            rows: [
                ("Events Today", "\(eventsTodayCount)"),
                ("Items Due Today", "\(dueToday)")
            ]
        )
    }
}
.onTapGesture {
    todayBounce.toggle()
}
```

### After (HIG-Compliant)
```swift
VStack(alignment: .leading, spacing: 12) {
    Label("Today", systemImage: "sun.max")
        .font(.headline)
    
    if eventsTodayCount == 0 && dueToday == 0 {
        ContentUnavailableView(
            "All Clear",
            systemImage: "checkmark.circle",
            description: Text("Nothing due today")
        )
    } else {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(eventsTodayCount) events")
                .font(.body)
            Text("\(dueToday) items due")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        
        Button("Add Assignment") {
            showAddAssignmentSheet = true
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
    }
}
.padding(16)
.background(.regularMaterial)
.clipShape(.rect(cornerRadius: 10))
```

## Testing Checklist

- [ ] Test on various window sizes (narrow, medium, wide)
- [ ] Test with VoiceOver enabled
- [ ] Test with Increase Contrast enabled
- [ ] Test with Reduce Motion enabled
- [ ] Test with Dynamic Type at different sizes
- [ ] Test with light and dark mode
- [ ] Test keyboard navigation
- [ ] Test with empty data
- [ ] Test with loading states
- [ ] Test with error states

## Resources

- [Apple HIG - Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Apple HIG - macOS Design Themes](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos)
- [Apple HIG - Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Apple HIG - Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [Apple HIG - Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [SwiftUI Lazy Grids](https://developer.apple.com/documentation/swiftui/lazyvgrid)
- [SwiftUI Materials](https://developer.apple.com/documentation/swiftui/material)
