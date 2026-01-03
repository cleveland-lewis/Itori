# macOS Month Calendar Refactor - Fixed-Size LazyVGrid

## Date
December 22, 2025

## Summary
Refactored the macOS SwiftUI month calendar to use a fixed-size LazyVGrid with stable, predictable cell dimensions that never change based on content or window resizing.

## File Created
**macOS/Views/CalendarMonthGridRefactored.swift**

Complete rewrite of `MonthCalendarView` and `MonthDayCell` with fixed sizing constraints.

## Key Changes

### 1. LazyVGrid with Exactly 7 Fixed-Width Columns

```swift
private let cellWidth: CGFloat = 140
private let cellHeight: CGFloat = 120
private let gridSpacing: CGFloat = 12

private var columns: [GridItem] {
    Array(repeating: GridItem(.fixed(cellWidth), spacing: gridSpacing), count: 7)
}
```

**Before**: `.flexible()` columns that adapted to content  
**After**: `.fixed(140)` columns that never change

### 2. Day Number in Top-Trailing Overlay

```swift
ZStack(alignment: .topTrailing) {
    // Cell background + events
    
    // Day number overlay (always on top)
    Text(dayNumber)
        .frame(width: 32, height: 32)
        .background(Circle().fill(dayNumberBackground))
        .padding(6)
}
```

**Position**: Fixed in top-trailing corner via `ZStack` alignment  
**Independence**: Completely separate from event content

### 3. Reserved Space for Events

```swift
private let dayNumberHeight: CGFloat = 28

private var eventContentHeight: CGFloat {
    cellHeight - dayNumberHeight - (cellPadding * 2)
}

VStack(alignment: .leading, spacing: 0) {
    // Reserve space for day number
    Color.clear.frame(height: dayNumberHeight)
    
    // Events scrollable within remaining space
    ScrollView(.vertical, showsIndicators: false) {
        // Event pills
    }
    .frame(height: eventContentHeight)
    .clipped()
}
```

**Space Reservation**: 28pt at top prevents overlap  
**Clipping**: Events are clipped within their allocated space  
**Scrolling**: Long event lists scroll vertically within the cell

### 4. Fixed Cell Dimensions

```swift
.frame(width: cellWidth, height: cellHeight)
```

**Applied To**: Every cell  
**Result**: All cells are identical 140×120pt regardless of content

### 5. Event Pill Truncation

```swift
private struct EventPill: View {
    HStack(spacing: 4) {
        Circle().fill(event.category.color).frame(width: 6, height: 6)
        Text(event.title)
            .font(.caption2)
            .lineLimit(1)  // Single line, truncates with ellipsis
            .foregroundStyle(.primary)
        Spacer(minLength: 0)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 3)
}
```

**Behavior**: Long titles truncate with `...` instead of expanding cell

### 6. Blank Day Opacity

```swift
private var dayNumberColor: Color {
    if day.isToday { return .white }
    if !day.isCurrentMonth {
        return .secondary.opacity(0.4)  // Reduced opacity
    }
    return .primary
}
```

**Result**: Leading/trailing days (outside current month) render with 40% opacity but identical sizing

## Visual Stability Guarantees

✅ **Cell size never changes**  
- Fixed 140×120pt dimensions applied to every cell
- No adaptive or flexible sizing

✅ **Day number position never moves**  
- Always top-trailing via ZStack alignment
- Independent overlay, not affected by event content

✅ **Events cannot resize cells**  
- Event content is clipped within fixed bounds
- ScrollView enables vertical scrolling for overflow

✅ **Window resize has no effect**  
- Grid width is `7 * (140 + 12) = 1064pt` plus padding
- Resizing window does not change cell dimensions

✅ **Uniform blank days**  
- Leading/trailing days have identical dimensions
- Only difference is reduced opacity (0.4)

## Architecture Decisions

### Why Fixed Sizing?
- **Predictability**: Users can visually scan the grid without layout shifts
- **Performance**: SwiftUI doesn't recalculate layout on every content change
- **Consistency**: Every cell occupies the same visual space

### Why Top-Trailing Overlay?
- **Visibility**: Day number always visible regardless of event count
- **Independence**: Events can scroll without affecting day number position
- **Tradition**: Matches standard calendar layouts (day numbers in corners)

### Why ScrollView for Events?
- **Graceful Overflow**: Long event lists don't break layout
- **Clipping**: Content stays within cell bounds
- **User Control**: Scrolling is better than truncating all events

### Why 140×120pt?
- **Balance**: Large enough for 3-4 event pills + day number
- **Density**: 7 columns fit comfortably in 1200-1400pt width windows
- **Readability**: Text remains legible at this scale

## Implementation Notes

### No Data Model Changes
- Uses existing `CalendarEvent` model
- Uses existing `EventsCountStore`
- No new structs required (reuses `DayItem`)

### macOS-Native SwiftUI Only
- No UIKit/AppKit bridging
- Pure SwiftUI `LazyVGrid`
- Standard SwiftUI modifiers only

### Event Limit Display
```swift
if events.count > 3 {
    Text("+\(events.count - 3) more")
}
```

Shows "+N more" indicator when >3 events in a day

### Hover Interaction
```swift
@State private var hovering = false

.scaleEffect(hovering ? 1.02 : 1.0)
.animation(.easeInOut(duration: 0.15), value: hovering)
.onHover { hovering = $0 }
```

Subtle scale effect on hover for visual feedback

## Testing Recommendations

1. **Window Resizing**
   - Resize window from 800pt to 2000pt wide
   - Verify cells remain 140×120pt throughout
   - Verify day numbers stay in top-trailing corners

2. **Event Overflow**
   - Create day with 10+ events
   - Verify cell height stays 120pt
   - Verify ScrollView enables scrolling
   - Verify "+N more" appears after 3rd event

3. **Month Navigation**
   - Navigate between months
   - Verify layout doesn't shift
   - Verify blank leading/trailing days have reduced opacity

4. **Today Highlighting**
   - Verify today's cell has blue circle background on day number
   - Verify blue border around today's cell
   - Verify still maintains fixed dimensions

5. **Long Event Titles**
   - Create event with 100-character title
   - Verify title truncates with ellipsis
   - Verify cell doesn't expand

## Integration Steps

1. Replace `MonthCalendarView` in `CalendarPageView.swift` (lines 756-927)
2. Import the new view: `import CalendarMonthGridRefactored`
3. Ensure `CalendarEvent`, `EventsCountStore`, and `DesignSystem` are accessible
4. Test all month view interactions
5. Remove old flexible grid implementation

## Performance Impact

**Positive**:
- Fewer layout recalculations (fixed sizes)
- Predictable memory footprint (7×6 = 42 cells max)
- LazyVGrid only renders visible cells

**Neutral**:
- ScrollView adds minor overhead per cell (negligible)
- Fixed sizing may waste space on large monitors (acceptable trade-off)

## Backward Compatibility

- ✅ Works with existing `CalendarEvent` model
- ✅ Works with existing event store
- ✅ Maintains same user interactions (click day, click event)
- ✅ Same callback signatures (`onSelectDate`, `onSelectEvent`)
- ✅ No breaking changes to parent views

## Future Enhancements (Not Implemented)

1. **User-configurable cell size**: Add preference for compact/normal/spacious
2. **Multi-day event spans**: Visual bars spanning multiple cells
3. **Drag-and-drop**: Move events between days
4. **Event color customization**: Per-calendar color coding
5. **Week numbers**: Optional column showing ISO week numbers
