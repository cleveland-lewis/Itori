# Dashboard: Clickable Upcoming Assignments

**Date**: January 8, 2026  
**Status**: ✅ Complete

## Changes Made

### 1. Made Assignment Rows Clickable
- **File**: `Platforms/iOS/Scenes/IOSDashboardView.swift`
- Each assignment in the "Upcoming Assignments" widget is now wrapped in a `Button`
- Tapping an assignment opens a detail sheet with full assignment information

### 2. Made Title Clickable to Open Assignments Page
- The "Upcoming Assignments" header is now a clickable button
- Tapping the title navigates to the full Assignments page
- The "+" button remains in place for adding new assignments

### 3. Added Assignment Detail Sheet
- Shows complete assignment details:
  - Status (complete/incomplete with toggle)
  - Title, course, type
  - Due date and time
  - Estimated time and priority
  - Grade information (if available)
- Actions available:
  - Mark as complete/incomplete
  - Edit assignment
  - Delete assignment

## Implementation Details

### State Management
```swift
@State private var selectedAssignmentId: UUID? = nil
```

### Sheet Presentation
Uses `.sheet(item:)` modifier with computed binding to show `IOSTaskDetailView`:
- Automatically finds task from `assignmentsStore` by ID
- Handles edit, delete, and completion toggle actions
- Dismisses sheet when action is complete

### User Experience
1. **Tap assignment row** → Opens detail sheet
2. **Tap "Upcoming Assignments" title** → Navigate to Assignments page  
3. **Tap "+" button** → Add new assignment (existing behavior)
4. **Tap "View All" button** → Navigate to Assignments page (existing behavior)

## Testing

### Manual Testing Checklist
- [ ] Tap assignment row opens detail sheet
- [ ] Detail sheet shows correct assignment information
- [ ] Can mark assignment as complete from detail
- [ ] Can edit assignment from detail (opens editor)
- [ ] Can delete assignment from detail
- [ ] Tapping title opens Assignments page
- [ ] "+" button still adds new assignment
- [ ] Sheet dismisses properly after actions
- [ ] Works on iPhone and iPad
- [ ] No compilation errors

## Related Files

### Modified
- `Platforms/iOS/Scenes/IOSDashboardView.swift` - Dashboard implementation

### Referenced (Existing)
- `Platforms/iOS/Scenes/IOSCorePages.swift` - Contains `IOSTaskDetailView`
- `Platforms/iOS/Root/IOSPresentationRouter.swift` - Sheet routing
- `SharedCore/Models/AppTask.swift` - Task data model

## UI/UX Improvements

### Before
- Assignment rows were static, display-only
- No way to quickly view details from dashboard
- Had to navigate to Assignments page to interact

### After
- ✅ Tap any assignment to see full details
- ✅ Quick actions from detail sheet
- ✅ Consistent with iOS patterns (tappable cards)
- ✅ Title becomes navigation button
- ✅ Maintains existing "+" and "View All" functionality

## Design Patterns

### Button Styling
```swift
Button { ... } label: { 
    upcomingAssignmentRow(item)
}
.buttonStyle(.plain)  // Removes default button styling
```

### Sheet with Computed Binding
```swift
.sheet(item: Binding(
    get: { 
        guard let id = selectedAssignmentId else { return nil }
        return assignmentsStore.tasks.first(where: { $0.id == id })
    },
    set: { selectedAssignmentId = $0?.id }
))
```

This pattern:
- Stores only the ID (lightweight)
- Fetches fresh data when showing sheet
- Automatically handles nil cases
- Updates when selection changes

## Notes

- Reuses existing `IOSTaskDetailView` component (no duplication)
- Maintains consistency with Assignments page behavior
- No breaking changes to existing functionality
- All edit/delete actions properly update `AssignmentsStore`

## Future Enhancements

Possible future improvements:
1. Swipe gestures on dashboard rows (mark complete, delete)
2. Long press context menu with quick actions
3. Drag to reorder assignments
4. Pull to refresh assignments list
5. Badge indicators for priority/urgency

---

**Status**: Ready for testing in Xcode
