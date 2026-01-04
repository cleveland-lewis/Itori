# Calendar UI/UX Analysis - Apple Calendar Comparison

**Date**: January 3, 2026  
**Platform**: macOS (Itori App)

---

## Executive Summary

The Itori calendar implementation has a solid foundation but deviates from Apple Calendar's design patterns in several key areas. This analysis identifies gaps and provides recommendations for achieving HIG compliance.

---

## 1. Month View Layout & Structure

### Current Implementation ✅ Strengths
- **Grid Layout**: Uses a 7-column grid matching Apple Calendar
- **Card-based design**: Clean material design with rounded corners
- **Responsive sizing**: Adapts to available space
- **Fixed cell height**: Prevents layout jumping (80px fixed)

### ❌ Gaps from Apple Calendar
1. **Date Number Position**: 
   - **Current**: Date is in a circle badge in top-trailing corner
   - **Apple**: Date is plain text, top-left, no background circle
   - **Impact**: Creates visual clutter, reduces usable event space

2. **Cell Aspect Ratio**:
   - **Current**: Fixed 80px height
   - **Apple**: Cells are more square (roughly 1:1 aspect ratio)
   - **Impact**: Less vertical space for event previews

3. **Grid Spacing**:
   - **Current**: 8px between cells
   - **Apple**: 1px hairline borders, no spacing
   - **Impact**: Less efficient use of space, feels more card-like than integrated

---

## 2. Date Number Styling

### Current Implementation
```swift
// CalendarDayCell.swift (lines 21-34)
Text(dayString)
    .font(DesignSystem.Typography.body)
    .frame(minWidth: 28, minHeight: 28)
    .padding(4)
    .foregroundColor(textColor(isToday: isToday))
    .background(
        Circle()
            .fill(backgroundFill(isToday: isToday))
    )
    .overlay(
        Circle()
            .strokeBorder(isToday && !isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
    )
    .padding(8)
```

### ❌ Issues
1. **Circle background**: Apple Calendar doesn't use circles for normal dates
2. **Size**: 28x28 minimum is too large, takes valuable space
3. **Padding**: Double padding (4px + 8px) excessive
4. **Position**: Top-right (just fixed) but should be top-left

### ✅ Apple Calendar Pattern
- **Plain text** for date numbers
- **Small, subtle** (appears to be ~12-14pt)
- **Top-left position** with minimal padding (~4-6px)
- **Today**: Red circle background with white text
- **Selected**: Blue/accent background for entire cell
- **Font weight**: Regular for normal days, bold for today

### 🔧 Recommended Fix
```swift
// Simplified date number (Apple Calendar style)
Text(dayString)
    .font(.caption)  // Smaller, subtler
    .fontWeight(isToday ? .semibold : .regular)
    .foregroundColor(
        isSelected ? .white :
        isToday ? .white :
        .primary
    )
    .padding(6)
    .background(
        // Only show background for today
        isToday && !isSelected ? 
            Circle()
                .fill(.red)
                .frame(width: 20, height: 20) :
            nil
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
```

---

## 3. Event Display in Cells

### Current Implementation (GridDayCell)
```swift
// CalendarGrid.swift (lines 127-149)
VStack(spacing: 2) {
    ForEach(events.prefix(3), id: \.eventIdentifier) { event in
        HStack(spacing: 4) {
            Circle()
                .fill(categoryColor(for: event))
                .frame(width: 4, height: 4)
            
            Text(event.title)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 14)  // Fixed height per event row
    }
    
    if events.count > 3 {
        Text("+\(events.count - 3) more")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(height: 14)
    }
}
```

### ✅ Strengths
- Shows event titles inline
- Color-coded dots for categories
- "+N more" overflow indicator
- Fixed height prevents jumping

### ❌ Gaps from Apple Calendar
1. **Event bars vs text**:
   - **Current**: Shows small dots + truncated text
   - **Apple**: Shows colored horizontal bars with text overlay
   - **Impact**: Less visual hierarchy, harder to scan

2. **All-day events**:
   - **Current**: Mixed with timed events
   - **Apple**: All-day events shown at top of cell as full-width bars
   - **Impact**: Reduced clarity of event types

3. **Time indicators**:
   - **Current**: No time shown in month view
   - **Apple**: Shows start time for timed events
   - **Impact**: Less information density

4. **Event density**:
   - **Current**: Shows 3 events + overflow
   - **Apple**: Dynamically shows as many as fit
   - **Impact**: Underutilizes vertical space

### 🔧 Recommended Implementation
```swift
VStack(alignment: .leading, spacing: 1) {
    // All-day events section
    ForEach(allDayEvents) { event in
        RoundedRectangle(cornerRadius: 2)
            .fill(event.color)
            .frame(height: 16)
            .overlay(
                Text(event.title)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            )
    }
    
    // Timed events section
    ForEach(timedEvents) { event in
        HStack(spacing: 4) {
            Text(event.startTime)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(event.color)
                .frame(height: 14)
                .overlay(
                    Text(event.title)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                )
        }
    }
}
```

---

## 4. Selection & Today Highlighting

### Current Implementation
- **Today**: Accent color circle background with stroke
- **Selected**: Accent color circle background + cell border
- **Both**: Selected takes precedence

### ❌ Issues
1. **Today styling conflicts** with selected state
2. **Circle background** inconsistent with Apple Calendar
3. **Border on selected cell** is subtle (2px accent @ 40% opacity)

### ✅ Apple Calendar Pattern
- **Today**: Red circle background on date number only
- **Selected**: Full cell gets blue/accent background
- **Weekends**: Slightly different background (very subtle)
- **Other months**: Grayed out date numbers

### 🔧 Recommended Fix
```swift
// Cell background
.background(
    RoundedRectangle(cornerRadius: 4)
        .fill(
            isSelected ? Color.accentColor.opacity(0.15) :
            !isInCurrentMonth ? Color.clear :
            Color.clear  // No background for normal cells
        )
)

// Date number
Text(dayString)
    .foregroundColor(
        !isInCurrentMonth ? .secondary.opacity(0.5) :
        isSelected ? .accentColor :
        isToday ? .white :
        isWeekend ? .secondary :
        .primary
    )
    .background(
        isToday && !isSelected ?
            Circle()
                .fill(.red)
                .frame(width: 20, height: 20) :
            nil
    )
```

---

## 5. Cell Borders & Separators

### Current Implementation
```swift
// CalendarGrid.swift (line 164)
.overlay(
    RoundedRectangle(cornerRadius: 8, style: .continuous)
        .strokeBorder(
            isSelected ? Color.accentColor.opacity(0.4) : 
            Color.primary.opacity(0.08), 
            lineWidth: isSelected ? 2 : 1
        )
)
```

### ❌ Issues
- **Rounded corners**: Each cell has 8px corner radius
- **Individual borders**: Creates card-like appearance
- **Spacing between cells**: 8px gaps

### ✅ Apple Calendar Pattern
- **Shared borders**: 1px hairline between cells
- **No corner radius**: Cells are rectangular
- **Continuous grid**: Feels like a unified calendar

### 🔧 Recommended Fix
```swift
// In CalendarGrid.swift
LazyVGrid(columns: columns, spacing: 0) {  // No spacing
    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
        if let day = day {
            GridDayCell(...)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.separator, lineWidth: 0.5)
                )
        }
    }
}
```

---

## 6. Header & Navigation

### Current Implementation ✅ Strengths
- Segmented picker for view modes (Day/Week/Month/Year)
- Previous/Next navigation buttons
- "Today" button
- Current month/year display
- "+ New Event" button

### ❌ Gaps from Apple Calendar
1. **Month title position**:
   - **Current**: Left side
   - **Apple**: Center
   
2. **Calendar picker**:
   - **Current**: Missing
   - **Apple**: Dropdown to switch calendars
   
3. **Search functionality**:
   - **Current**: Not visible in month view
   - **Apple**: Search bar in sidebar

---

## 7. Sidebar (Event List)

### Current Implementation
- Shows events for selected date
- "Today" section when no date selected
- Event categories with colored dots
- Fixed width (~280px)

### ✅ Strengths
- Good visual hierarchy
- Category organization
- Performance metrics (dev mode)

### ❌ Gaps from Apple Calendar
1. **Mini calendar**:
   - **Current**: Missing
   - **Apple**: Shows small month view for quick navigation
   
2. **Calendar list**:
   - **Current**: Missing
   - **Apple**: Shows toggleable calendar sources
   
3. **Event preview**:
   - **Current**: Basic list
   - **Apple**: Shows time, location, video call links prominently

---

## 8. Hover States & Interactions

### Current Implementation ✅ Good
```swift
.onHover { hovering in
    withAnimation(.easeInOut(duration: 0.15)) {
        isHovered = hovering
    }
}
```
- Subtle background change on hover
- Animated transition
- Press scale effect (0.92x)

### Minor Issues
- Hover effect could be more subtle (currently 5% opacity)
- Apple uses ~2-3% opacity change

---

## 9. Typography & Spacing

### Current Issues
| Element | Current | Apple Calendar | Fix |
|---------|---------|----------------|-----|
| Date number | Body weight | Caption, regular | Reduce size |
| Event title | Caption2 | Caption2 | ✅ Match |
| Weekday header | Caption bold | Caption2 semibold | Minor adjust |
| Cell padding | 8px | ~4-6px | Reduce |
| Grid spacing | 8px | 0px (borders) | Remove |

---

## 10. Color Scheme & Materials

### Current Implementation
- Uses `DesignSystem.Materials.card` for main grid
- Uses `DesignSystem.Materials.surface` for cells
- Accent color for selections
- Category colors for events

### ✅ Strengths
- Good light/dark mode support
- Semantic color naming
- Consistent with app design system

### ❌ Gaps
1. **Cell backgrounds**: Too much contrast between cells and grid
2. **Today indicator**: Should use system red, not accent color
3. **Weekend distinction**: Not visible

---

## Priority Recommendations

### 🔴 High Priority (Major UX Impact)
1. **Move date numbers to top-left** (partially done)
2. **Remove circle backgrounds** from normal dates
3. **Implement event bars** instead of dots + text
4. **Remove cell spacing**, add hairline borders
5. **Fix today indicator** to use red circle, top-left

### 🟡 Medium Priority (Nice to Have)
6. Add mini-calendar to sidebar
7. Show event times in month view
8. Distinguish all-day vs timed events
9. Add weekend background tint
10. Center-align month title

### 🟢 Low Priority (Polish)
11. Reduce cell padding from 8px to 4-6px
12. Make hover effect more subtle (2-3% vs 5%)
13. Add calendar source picker
14. Show travel time indicators

---

## Code Changes Required

### File: `CalendarDayCell.swift`
- Lines 14-46: Refactor date number layout
- Remove circle background for normal dates
- Move to top-left alignment
- Simplify styling

### File: `CalendarGrid.swift`
- Lines 14: Change spacing from 8 to 0
- Lines 91-179: Refactor GridDayCell
- Implement event bar rendering
- Add border system

### File: `CalendarPageView.swift`
- Lines 188-207: Consider sidebar layout
- Add mini-calendar component
- Add calendar source picker

---

## Accessibility Considerations ✅

The current implementation is strong on accessibility:
- VoiceOver labels for date cells
- Keyboard navigation support
- High contrast mode support
- Selected state traits

**Maintain these** while implementing visual changes.

---

## Performance Notes ✅

Current implementation shows good performance patterns:
- Event caching (lines 119-158 in CalendarPageView)
- Lazy loading
- Fixed heights prevent layout thrashing
- Filtered events optimization

**Preserve these** optimizations in refactored code.

---

## Testing Checklist

- [ ] Date numbers in top-left (not top-right)
- [ ] Today uses red circle (not accent)
- [ ] Selected cell has full background
- [ ] Event bars render correctly
- [ ] All-day events at top of cell
- [ ] Timed events show times
- [ ] No spacing between cells
- [ ] Hairline borders between cells
- [ ] Other month dates grayed out
- [ ] VoiceOver still works
- [ ] Dark mode looks correct
- [ ] High contrast mode works

---

## References

- Apple Human Interface Guidelines: Calendar
- macOS Calendar.app (System application)
- EventKit documentation
- SwiftUI Layout best practices

---

## Conclusion

The Itori calendar has a solid technical foundation with good performance and accessibility. The main gaps are visual/layout-related rather than functional. Implementing the high-priority recommendations will bring the calendar much closer to Apple Calendar's look and feel while maintaining the app's design system consistency.

**Estimated effort**: 2-3 days for high priority items, 1-2 days for medium priority items.
