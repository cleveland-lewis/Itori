# EventEditSheet UI Tests Implementation Notes

## Issue #28: Add UI tests for EventEditSheet recurrence + alerts round-trip

### Current Status
✅ Test framework created with test method stubs  
⚠️ **Requires EventEditSheet accessibility identifiers before implementation**  
⚠️ **Requires EventKit permissions setup for integration tests**

### Prerequisites

#### 1. Add Accessibility Identifiers to EventEditSheet
The following UI elements in `EventEditSheet` need accessibility identifiers:

**Required identifiers in CalendarPageView.swift:**
```swift
// In EventEditSheet body
TextField("Title", text: $title)
    .accessibilityIdentifier("EventEdit.titleField")

Picker("Category", selection: $category)
    .accessibilityIdentifier("EventEdit.categoryPicker")

Toggle("All Day", isOn: $isAllDay)
    .accessibilityIdentifier("EventEdit.allDayToggle")

DatePicker("Start", selection: $startDate, ...)
    .accessibilityIdentifier("EventEdit.startDatePicker")

DatePicker("End", selection: $endDate, ...)
    .accessibilityIdentifier("EventEdit.endDatePicker")

TextField("Location", text: $location)
    .accessibilityIdentifier("EventEdit.locationField")

// Recurrence controls
Picker("Recurrence", selection: $recurrence)
    .accessibilityIdentifier("EventEdit.recurrencePicker")

// Alert controls  
Picker("Primary Alert", selection: $primaryAlert)
    .accessibilityIdentifier("EventEdit.primaryAlertPicker")

Picker("Secondary Alert", selection: $secondaryAlert)
    .accessibilityIdentifier("EventEdit.secondaryAlertPicker")

// Action buttons
Button("Cancel", action: ...)
    .accessibilityIdentifier("EventEdit.cancelButton")

Button("Save", action: ...)
    .accessibilityIdentifier("EventEdit.saveButton")

// Add Event button in CalendarPageView
Button(action: addEvent) { ... }
    .accessibilityIdentifier("Calendar.addEventButton")
```

#### 2. Test Data Setup
Need ability to:
- Create test events programmatically
- Clear test data between tests
- Mock or stub EventKit interactions for CI

#### 3. EventKit Permissions
For integration tests that interact with system calendar:
- Tests need calendar access
- CI environment may not grant permissions
- Mark these tests as manual or conditional

### Implementation Steps

#### Phase 1: Add Accessibility Identifiers (1-2 hours)
1. Add identifiers to all EventEditSheet UI elements
2. Add identifier to "Add Event" button in CalendarPageView
3. Build and verify identifiers are accessible in UI tests

#### Phase 2: Implement Basic Event Creation Test (2-3 hours)
1. Implement `testCreateWeeklyRecurringEvent()`
2. Add helper methods for:
   - Opening event creation sheet
   - Filling in basic event details
   - Saving event
   - Verifying event appears in calendar

#### Phase 3: Implement Recurrence Tests (4-6 hours)
1. `testRecurrenceEndAfterNOccurrences()`
2. `testRecurrenceEndByDate()`
3. `testWeeklyRecurrenceMultipleDays()`
4. Add helper methods for:
   - Setting recurrence options
   - Verifying recurrence settings
   - Reopening saved events

#### Phase 4: Implement Alert Tests (3-4 hours)
1. `testEventWithSingleAlert()`
2. `testEventWithTwoAlerts()`
3. `testRemoveAlerts()`
4. Add helper methods for alert configuration

#### Phase 5: EventKit Integration Tests (4-6 hours)
1. Create EventKit test harness
2. Implement `testRoundTripCreateInRoots()`
3. Add permission handling
4. Mark as conditional/manual if needed
5. Document manual test procedures

#### Phase 6: Documentation (1-2 hours)
1. Create manual test checklist (TESTING.md or similar)
2. Document EventKit permission requirements
3. Add CI skip conditions if needed

### Total Estimated Time: 15-23 hours

### Test Execution

#### Automated Tests (CI-friendly)
Run with: `xcodebuild test -scheme Roots -destination 'platform=macOS'`

#### Manual Tests (EventKit integration)
1. Run with calendar permissions granted
2. Follow manual test checklist for Apple Calendar integration
3. Verify changes sync between Roots and System Calendar

### Notes
- Tests use `XCTFail("Test not yet implemented...")` to mark incomplete tests
- All test methods are structured and documented
- Helper methods are stubbed for consistent implementation
- Integration tests are marked with `XCTSkip` for EventKit dependencies

### Related Issues
- Issue #29: Unit tests for recurrence/alerts round-trip
- Consider extracting EventEditSheet to separate file for better testability
