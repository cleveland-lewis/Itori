# Event Deletion - Quick Reference

## Service Usage

```swift
import SharedCore

// Delete an event with confirmation
let result = await EventDeletionService.shared.deleteEvent(
    eventId: eventIdentifier,
    isReminder: false,
    presentConfirmation: { title, message in
        // Show native confirmation dialog
        return await showConfirmDialog(title, message)
    },
    presentScopeSelection: {
        // For recurring events, show scope selection
        return await showScopeDialog()
    }
)

// Handle result
switch result {
case .deleted:
    // Event deleted successfully
    dismissView()
case .cancelled:
    // User cancelled, do nothing
    break
case .failed(let error):
    // Show error to user
    showError(error.localizedDescription)
}
```

## Deletion Scopes

### Non-Recurring Event
- Single confirmation
- No scope selection needed

### Recurring Event - Three Options

**This Event**
```swift
.thisEvent  // Deletes only selected occurrence
```

**Future Events**
```swift
.futureEvents  // Deletes this + all future
```

**All Events**
```swift
.allEvents  // Deletes entire series
```

## UI Integration Example

```swift
struct EventDetailView: View {
    @State private var showScopeSelection = false
    @State private var showDeleteConfirm = false
    @State private var selectedScope: EventDeletionService.RecurringDeletionScope?
    
    var body: some View {
        VStack {
            // ... event details ...
            
            Button(role: .destructive) {
                handleDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        // Step 1: Scope selection (recurring only)
        .confirmationDialog(
            "event.delete.scope_selection_title".localized,
            isPresented: $showScopeSelection
        ) {
            Button("event.delete.scope.this_event".localized) {
                selectedScope = .thisEvent
                showDeleteConfirm = true
            }
            Button("event.delete.scope.future_events".localized) {
                selectedScope = .futureEvents
                showDeleteConfirm = true
            }
            Button("event.delete.scope.all_events".localized) {
                selectedScope = .allEvents
                showDeleteConfirm = true
            }
            Button("Cancel", role: .cancel) { }
        }
        // Step 2: Final confirmation
        .confirmationDialog(
            "event.delete.confirm_title".localized,
            isPresented: $showDeleteConfirm
        ) {
            Button("Delete", role: .destructive) {
                performDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(confirmationMessage)
        }
    }
    
    private func handleDelete() {
        if item.isRecurring {
            showScopeSelection = true
        } else {
            selectedScope = .thisEvent
            showDeleteConfirm = true
        }
    }
    
    private var confirmationMessage: String {
        guard item.isRecurring, let scope = selectedScope else {
            return "event.delete.confirm_message_single".localized
        }
        
        switch scope {
        case .thisEvent:
            return "event.delete.confirm_message_this".localized
        case .futureEvents:
            return "event.delete.confirm_message_future".localized
        case .allEvents:
            return "event.delete.confirm_message_all".localized
        }
    }
    
    private func performDelete() {
        Task {
            let result = await EventDeletionService.shared.deleteEvent(
                eventId: item.ekIdentifier!,
                isReminder: item.isReminder,
                presentConfirmation: { _, _ in true }, // Already confirmed
                presentScopeSelection: { selectedScope }
            )
            
            if case .deleted = result {
                dismiss()
            }
        }
    }
}
```

## Localization Keys

### Titles
- `event.delete.confirm_title` → "Delete Event?"
- `event.delete.scope_selection_title` → "Delete Recurring Event"

### Messages
- `event.delete.confirm_message_single` → Non-recurring event
- `event.delete.confirm_message_this` → This occurrence only
- `event.delete.confirm_message_future` → This and future
- `event.delete.confirm_message_all` → All occurrences
- `event.delete.confirm_message_reminder` → Reminder deletion
- `event.delete.scope_selection_message` → Scope selection prompt

### Scope Options
- `event.delete.scope.this_event` → "This Event"
- `event.delete.scope.future_events` → "Future Events"
- `event.delete.scope.all_events` → "All Events"

### Errors
- `event.delete.error.not_authorized` → No calendar access
- `event.delete.error.not_found` → Event not found
- `event.delete.error.type_mismatch` → Invalid type

## Error Handling

### Event Not Found
```swift
// Service handles gracefully
guard let event = store.event(withIdentifier: eventId) else {
    // Refresh cache and return appropriate error
    await deviceCalendar.refreshEventsForVisibleRange()
    return .failed(EventDeletionError.eventNotFound)
}
```

### External Deletion (EKCADErrorDomain 1010)
```swift
// Treat as success - goal achieved
if error.domain == "EKCADErrorDomain" && error.code == 1010 {
    await deviceCalendar.refreshEventsForVisibleRange()
    return .deleted
}
```

### No Authorization
```swift
guard authManager.isAuthorized else {
    return .failed(EventDeletionError.notAuthorized)
}
```

## Testing

### Unit Test Example
```swift
func testDeleteRecurringEvent_ThisEvent() async throws {
    let event = createRecurringEvent()
    
    let result = await sut.deleteEvent(
        eventId: event.eventIdentifier,
        isReminder: false,
        presentConfirmation: { _, message in
            XCTAssertEqual(message, "event.delete.confirm_message_this".localized)
            return true
        },
        presentScopeSelection: { .thisEvent }
    )
    
    XCTAssertEqual(result, .deleted)
}
```

### Manual Testing Checklist
- [ ] Non-recurring: Single confirmation shown
- [ ] Recurring: Scope selection shown first
- [ ] Cancel at scope selection prevents deletion
- [ ] Cancel at confirmation prevents deletion
- [ ] This Event: Only single occurrence deleted
- [ ] Future Events: This + future deleted
- [ ] All Events: Entire series deleted
- [ ] UI updates immediately
- [ ] Error handling works (missing event, no auth)

## Common Patterns

### Simple Deletion (Non-Recurring)
```swift
Button("Delete") {
    Task {
        let result = await EventDeletionService.shared.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: showConfirmAlert,
            presentScopeSelection: { .thisEvent }
        )
        handleResult(result)
    }
}
```

### Recurring Event Deletion
```swift
Button("Delete") {
    Task {
        var selectedScope: RecurringDeletionScope?
        
        let result = await EventDeletionService.shared.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: showConfirmAlert,
            presentScopeSelection: {
                selectedScope = await showScopeSelection()
                return selectedScope
            }
        )
        handleResult(result)
    }
}
```

### With SwiftUI State
```swift
@State private var showDeleteConfirm = false
@State private var showScopeSelection = false
@State private var selectedScope: RecurringDeletionScope?

// Trigger deletion
private func startDeletion() {
    if isRecurring {
        showScopeSelection = true
    } else {
        showDeleteConfirm = true
    }
}

// Perform deletion after confirmations
private func performDeletion() {
    Task {
        let result = await EventDeletionService.shared.deleteEvent(...)
        // Handle result
    }
}
```

## Best Practices

### ✅ Do
- Always use the service for event deletion
- Show scope selection before confirmation for recurring events
- Allow cancellation at any step
- Refresh UI after deletion
- Handle errors gracefully
- Use localized strings

### ❌ Don't
- Skip confirmation dialogs
- Delete events silently
- Assume event exists without checking
- Ignore authorization status
- Hard-code UI strings
- Block main thread

## Platform Differences

### macOS
- Uses `confirmationDialog`
- Larger tap targets
- Keyboard shortcuts supported

### iOS (future)
- Use `Alert` instead of `confirmationDialog`
- Smaller screens, consider sheet presentation
- Swipe gestures for quick actions

### watchOS (future)
- Simplified UI (one step)
- No scope selection on device
- Defer to iPhone for complex operations

## Performance Tips

1. **Service is lightweight** - No caching overhead
2. **Async/await** - Non-blocking deletion
3. **MainActor** - UI updates automatic
4. **Cache refresh** - Only when needed

## Troubleshooting

### Event won't delete
- Check authorization: `CalendarAuthorizationManager.shared.isAuthorized`
- Verify event exists: `store.event(withIdentifier:)`
- Check calendar permissions: Read-write required

### Wrong occurrences deleted
- Verify scope selection logic
- Check `EKSpan` usage
- Test with simple recurring event

### UI not updating
- Ensure cache refresh called
- Verify `@MainActor` usage
- Check state binding

## Related Documentation

- `EVENT_DELETION_CONFIRMATION_COMPLETE.md` - Full specification
- `EVENT_DELETION_IMPLEMENTATION_SUMMARY.md` - Implementation details
- `EVENTKIT_CONTRACT_TESTS_IMPLEMENTATION.md` - EventKit testing
- Apple EventKit Documentation

## Support

For issues or questions:
1. Check unit tests for examples
2. Review implementation summary
3. Verify authorization status
4. Check Xcode console for LOG_EVENTKIT messages
