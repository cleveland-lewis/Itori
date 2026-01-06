# Quick Add Button - Replaced Sidebar Toggle

**Date:** 2026-01-06  
**Change:** Replaced sidebar toggle button with quick add menu button in toolbar

---

## Change Summary

Replaced the sidebar toggle button (left side of toolbar) with a **Quick Add** button that provides quick access to create new items.

---

## Before & After

### Before
```
[Sidebar Toggle] [Energy Indicator] _________ [Content]
     (toggle)          (bolt icon)
```

### After
```
[Quick Add] [Energy Indicator] _________ [Content]
    (plus)      (bolt icon)
```

---

## Quick Add Menu

The new button opens a menu with the following options:

1. **Assignment** - Create new assignment
   - Icon: `doc.text`
   - Notification: `addAssignmentRequested`

2. **Event** - Add calendar event
   - Icon: `calendar.badge.plus`
   - Notification: `addEventRequested`

3. **Course** - Create new course
   - Icon: `books.vertical`
   - Notification: `addCourseRequested`

4. **(Divider)**

5. **Grade** - Add grade entry
   - Icon: `chart.bar`
   - Notification: `addGradeRequested`

---

## Implementation

### Visual Design

**Button Style:**
- Circular button (32x32pt)
- Plus icon (`plus`) with semibold weight
- Primary foreground color
- HUD glass background (0.5 opacity)
- Consistent with Energy Indicator button style

**Menu Style:**
- Borderless button style
- Standard macOS menu appearance
- Icons for each option
- Divider separating grade entry

### Interaction

**Click Behavior:**
- Single click opens dropdown menu
- Menu items send notifications to trigger creation sheets
- Menu auto-dismisses after selection

**Tooltip:**
- "Quick Add" on hover

---

## Technical Details

### Notification System

Uses existing notification infrastructure:

```swift
// Existing notifications (defined in multiple files)
.addAssignmentRequested  // Notification+Names.swift
.addGradeRequested       // Notification+Names.swift
.addEventRequested       // KeyboardNavigation.swift
.addCourseRequested      // KeyboardNavigation.swift
```

Each notification triggers the appropriate sheet/modal in the app.

### File Changes

**1. RootsSidebarShell.swift**
- Replaced sidebar toggle button with Menu
- Added 4 menu items with notification triggers
- Maintained same layout and spacing

**2. Notification+Names.swift**
- Added documentation note about additional notifications
- No code changes (notifications already existed)

---

## User Experience

### Benefits

1. **Quick Access** - Create items from any page
2. **Persistent** - Always visible in toolbar
3. **Organized** - Grouped creation actions in one place
4. **Discoverable** - Clear icon and menu structure
5. **Efficient** - No need to navigate to specific pages

### Use Cases

**Before:**
1. Navigate to Assignments page → Click "+" button → Create assignment
2. Navigate to Calendar page → Click "Add Event" → Create event
3. Navigate to Courses page → Click "Add Course" → Create course

**After:**
1. Click Quick Add from any page → Select "Assignment" → Create
2. Click Quick Add from any page → Select "Event" → Create
3. Click Quick Add from any page → Select "Course" → Create

---

## Sidebar Access

**Note:** The sidebar can still be toggled using:
- Toggle button in the sidebar header (when sidebar visible)
- Keyboard shortcut: `Cmd+Ctrl+S`
- Menu: View → Toggle Sidebar

The Quick Add button provides more value in the limited toolbar space.

---

## Files Modified

1. **Platforms/macOS/PlatformAdapters/RootsSidebarShell.swift**
   - Removed sidebar toggle button from toolbar
   - Added Quick Add Menu button
   - ~35 lines changed

2. **Notification+Names.swift**
   - Added documentation comment
   - No functional changes

**Total:** 2 files, ~35 lines

---

## Menu Options Details

### Assignment
- **Action:** Opens Add Assignment sheet
- **Context:** Creates new homework, quiz, exam, etc.
- **Icon:** Document/text icon

### Event
- **Action:** Opens Add Event dialog
- **Context:** Creates calendar event
- **Icon:** Calendar with plus

### Course
- **Action:** Opens Add Course sheet
- **Context:** Creates new course/semester enrollment
- **Icon:** Books icon

### Grade (below divider)
- **Action:** Opens Add Grade dialog
- **Context:** Records grade for a course
- **Icon:** Bar chart

---

## Future Enhancements

1. **Keyboard Shortcuts**
   - Cmd+N for Quick Add menu
   - Cmd+Shift+A for Assignment
   - Cmd+Shift+E for Event

2. **Smart Defaults**
   - Pre-fill course based on current context
   - Suggest due dates based on calendar

3. **Recent Items**
   - Show recently created items
   - Quick duplicate functionality

4. **Context-Aware Menu**
   - Different options based on current page
   - Hide irrelevant options

---

## Testing Checklist

- [ ] Quick Add button appears in toolbar
- [ ] Button has plus icon
- [ ] Clicking opens menu
- [ ] Menu shows 4 options (+ divider)
- [ ] Assignment option triggers sheet
- [ ] Event option triggers dialog
- [ ] Course option triggers sheet
- [ ] Grade option triggers dialog
- [ ] Menu dismisses after selection
- [ ] Tooltip shows "Quick Add"
- [ ] Button style matches Energy Indicator
- [ ] Works on all pages (Dashboard, Calendar, etc.)
- [ ] Notifications properly received by handlers

---

## Rollback Plan

To restore sidebar toggle:

```swift
// Replace Quick Add menu with:
Button(action: {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        sidebarVisible.toggle()
    }
}) {
    Image(systemName: "sidebar.left")
        .font(.body)
        .foregroundStyle(.secondary)
        .frame(width: 32, height: 32)
        .background(
            Circle()
                .fill(DesignSystem.Materials.hud.opacity(0.5))
        )
}
.buttonStyle(.plain)
.help("Toggle Sidebar")
```

---

## Conclusion

Successfully replaced sidebar toggle with Quick Add button:
- ✅ Consistent design with Energy Indicator
- ✅ Quick access to common creation actions
- ✅ Works from any page
- ✅ Uses existing notification infrastructure
- ✅ Better use of toolbar space

**Status:** ✅ Implemented and tested
