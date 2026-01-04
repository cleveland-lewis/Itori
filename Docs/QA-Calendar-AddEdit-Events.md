# QA Checklist: Calendar Add/Edit Event Sheets

**Version:** 1.0  
**Last Updated:** 2025-12-13  
**Component:** Calendar Event Management (Add/Edit)

## Overview
This checklist covers manual testing of the Add Event and Edit Event sheets, including all field persistence, recurrence rules, alerts, and round-trip compatibility with Apple Calendar.

---

## Prerequisites

- [ ] Itori app installed and running on macOS
- [ ] Calendar permissions granted to Itori
- [ ] Apple Calendar app available for round-trip testing
- [ ] At least one calendar available in the system

---

## Test Suite 1: Create Event via Calendar Cell

### 1.1 Basic Event Creation
**Steps:**
1. Open Itori app and navigate to Calendar page
2. Click on any empty date cell in the month view
3. Click "Add Event" or use quick-add button
4. Fill in the following fields:
   - **Title:** "Test Event 1"
   - **Category:** Select "Class"
   - **Start Date:** Today at 2:00 PM
   - **End Date:** Today at 3:00 PM
   - **Location:** "Room 101"
   - **Notes:** "This is a test event"
5. Click "Create"

**Expected Results:**
- [ ] Event appears in the selected date cell
- [ ] Event shows in the left sidebar for that date
- [ ] Event displays correct title "Test Event 1" (no category prefix in title)
- [ ] Event shows blue color indicator (Class category)
- [ ] Event shows time "2:00 PM - 3:00 PM"
- [ ] Location "Room 101" is visible in event details

### 1.2 All-Day Event Creation
**Steps:**
1. Click "Add Event" from any date cell
2. Fill in:
   - **Title:** "All Day Test"
   - **All-day toggle:** ON
   - **Start Date:** Tomorrow
3. Click "Create"

**Expected Results:**
- [ ] Event appears at the top of the date cell
- [ ] No time is displayed for the event
- [ ] Event spans the full day in calendar views
- [ ] Start and end times are set to midnight boundaries

---

## Test Suite 2: Edit Existing Event

### 2.1 Field Rehydration
**Steps:**
1. Create an event with all fields filled:
   - Title: "Edit Test Event"
   - Category: "Study"
   - Start: Today 10:00 AM
   - End: Today 11:30 AM
   - Location: "Library"
   - Notes: "Study for exam"
   - URL: "https://example.com"
2. Click the event to view details
3. Click "Edit" button

**Expected Results:**
- [ ] Title field shows "Edit Test Event"
- [ ] Category selector shows "Study"
- [ ] Start date/time shows today 10:00 AM
- [ ] End date/time shows today 11:30 AM
- [ ] Location field shows "Library"
- [ ] Notes field shows "Study for exam"
- [ ] URL field shows "https://example.com"
- [ ] All fields are editable

### 2.2 Edit and Save Changes
**Steps:**
1. Open the event created in 2.1 for editing
2. Modify:
   - Title: "Edited Study Session"
   - Location: "Coffee Shop"
   - End time: 12:00 PM (extend by 30 min)
3. Click "Save"
4. Close and reopen the event

**Expected Results:**
- [ ] Title updated to "Edited Study Session"
- [ ] Location updated to "Coffee Shop"
- [ ] End time shows 12:00 PM
- [ ] All other fields remain unchanged
- [ ] Event position in calendar updates if time changed
- [ ] Changes persist after app restart

---

## Test Suite 3: All-Day Toggle Behavior

### 3.1 Toggle All-Day On
**Steps:**
1. Create event with specific times (e.g., 2:00 PM - 4:00 PM)
2. Edit the event
3. Toggle "All-day" to ON
4. Save

**Expected Results:**
- [ ] Time pickers become disabled/hidden
- [ ] Event time changes to full day (midnight to midnight)
- [ ] Event moves to top of day in calendar view
- [ ] No time is displayed in event label

### 3.2 Toggle All-Day Off
**Steps:**
1. Create an all-day event
2. Edit the event
3. Toggle "All-day" to OFF
4. Set times: 9:00 AM - 10:00 AM
5. Save

**Expected Results:**
- [ ] Time pickers become enabled/visible
- [ ] Event shows specific time range
- [ ] Event position updates to time-based slot
- [ ] Time is displayed in event label "9:00 AM - 10:00 AM"

---

## Test Suite 4: Recurrence Rules

### 4.1 Daily Recurrence
**Steps:**
1. Create event "Daily Standup"
2. Set recurrence to "Daily"
3. Set interval to "Every 1 day"
4. Set end condition: "After 5 occurrences"
5. Save

**Expected Results:**
- [ ] Event appears on 5 consecutive days
- [ ] Each occurrence shows in calendar
- [ ] Editing one occurrence offers "This event" vs "All events" option
- [ ] Deleting one occurrence removes only that instance

### 4.2 Weekly Recurrence with Weekday Selection
**Steps:**
1. Create event "Team Meeting"
2. Set recurrence to "Weekly"
3. Set interval to "Every 1 week"
4. Select weekdays: Monday, Wednesday, Friday
5. Set end: "None" (infinite)
6. Save

**Expected Results:**
- [ ] Event appears only on Mon, Wed, Fri
- [ ] Pattern continues for future weeks
- [ ] No events appear on Tue, Thu, Sat, Sun
- [ ] Weekday selection persists when editing

### 4.3 Monthly Recurrence
**Steps:**
1. Create event "Monthly Review"
2. Set recurrence to "Monthly"
3. Set interval to "Every 1 month"
4. Set end date: 3 months from now
5. Save

**Expected Results:**
- [ ] Event appears on same day of each month
- [ ] Total of 3 occurrences (including initial)
- [ ] Last occurrence on specified end date
- [ ] Series stops after end date

### 4.4 Edit Recurrence Rule
**Steps:**
1. Create weekly recurring event
2. Edit the event
3. Change from "Weekly" to "Daily"
4. Save

**Expected Results:**
- [ ] Prompt appears: "Change this event or all events?"
- [ ] Choosing "All events" updates the entire series
- [ ] Choosing "This event" breaks this instance from series
- [ ] Updated recurrence rule persists

---

## Test Suite 5: Alerts (Reminders)

### 5.1 Single Alert
**Steps:**
1. Create event "Important Meeting"
2. Set primary alert: "15 minutes before"
3. Save
4. Wait for alert time (or manually set event to near-future time)

**Expected Results:**
- [ ] Alert field shows "15 minutes before"
- [ ] System notification appears 15 minutes before event
- [ ] Notification includes event title and time
- [ ] Alert can be dismissed or snoozed

### 5.2 Multiple Alerts
**Steps:**
1. Create event "Exam"
2. Set primary alert: "1 day before"
3. Set secondary alert: "1 hour before"
4. Save

**Expected Results:**
- [ ] Both alerts are saved
- [ ] First notification appears 1 day before
- [ ] Second notification appears 1 hour before
- [ ] Both alerts persist when editing event

### 5.3 Edit Alerts
**Steps:**
1. Open event with existing alerts
2. Change primary alert from "15 minutes" to "30 minutes"
3. Remove secondary alert
4. Save

**Expected Results:**
- [ ] Primary alert updates to 30 minutes
- [ ] Secondary alert is removed
- [ ] Changes persist after save
- [ ] Only one alert notification will fire (30 min before)

---

## Test Suite 6: Apple Calendar Round-Trip

### 6.1 Create in Itori → Verify in Apple Calendar
**Steps:**
1. Create event in Itori:
   - Title: "Itori to Apple Test"
   - Category: "Meeting"
   - Date: Tomorrow 3:00 PM - 4:00 PM
   - Location: "Conference Room"
   - Notes: "Created in Itori app"
   - Recurrence: Weekly, every 1 week, for 3 occurrences
   - Alert: 30 minutes before
2. Save
3. Open Apple Calendar app
4. Navigate to tomorrow's date

**Expected Results:**
- [ ] Event appears in Apple Calendar
- [ ] Title is "Itori to Apple Test" (no category prefix)
- [ ] Time shows 3:00 PM - 4:00 PM
- [ ] Location shows "Conference Room"
- [ ] Notes show "Created in Itori app"
- [ ] Recurrence pattern shows "Weekly, every 1 week"
- [ ] Alert shows "30 minutes before"
- [ ] Total of 3 occurrences visible

### 6.2 Edit in Apple Calendar → Verify in Itori
**Steps:**
1. In Apple Calendar, find the event "Itori to Apple Test"
2. Double-click to edit
3. Modify:
   - Title: "Apple Edited Event"
   - Time: 4:00 PM - 5:00 PM
   - Location: "Board Room"
   - Add second alert: 1 hour before
4. Save in Apple Calendar
5. Return to Itori app
6. Refresh calendar view (or wait for auto-sync)
7. Find and open the event

**Expected Results:**
- [ ] Itori shows updated title "Apple Edited Event"
- [ ] Time shows 4:00 PM - 5:00 PM
- [ ] Location shows "Board Room"
- [ ] Original notes preserved
- [ ] Both alerts present (30 min and 1 hour)
- [ ] Recurrence pattern unchanged
- [ ] Category preserved (if stored separately)

### 6.3 Create in Apple Calendar → Verify in Itori
**Steps:**
1. In Apple Calendar, create new event:
   - Title: "Apple Native Event"
   - Date: Next week, 10:00 AM - 11:00 AM
   - Location: "Home Office"
   - Recurrence: Daily, for 5 occurrences
2. Save
3. Switch to Itori app
4. Navigate to next week's date

**Expected Results:**
- [ ] Event appears in Itori calendar
- [ ] Title shows "Apple Native Event"
- [ ] Time shows 10:00 AM - 11:00 AM
- [ ] Location shows "Home Office"
- [ ] Recurrence shows daily pattern
- [ ] All 5 occurrences visible
- [ ] Category auto-detected as "Other" or parsed from title

### 6.4 Delete in Itori → Verify in Apple Calendar
**Steps:**
1. In Itori, find a recurring event
2. Click to open event details
3. Click "Delete"
4. Select "All events" (delete entire series)
5. Confirm deletion
6. Open Apple Calendar

**Expected Results:**
- [ ] Event series no longer appears in Apple Calendar
- [ ] No orphaned occurrences remain
- [ ] Deletion syncs within reasonable time (~1-2 min)

### 6.5 Delete in Apple Calendar → Verify in Itori
**Steps:**
1. In Apple Calendar, delete an event
2. Return to Itori
3. Refresh calendar view

**Expected Results:**
- [ ] Event removed from Itori calendar
- [ ] Left sidebar no longer shows the event
- [ ] Month view cell no longer displays the event
- [ ] Deletion syncs within reasonable time

---

## Test Suite 7: Edge Cases

### 7.1 Very Long Title
**Steps:**
1. Create event with title: "This is a very long event title that should test the truncation and display behavior of the calendar system when showing events in month view cells"
2. Save

**Expected Results:**
- [ ] Title is saved completely (no truncation in data)
- [ ] Month cell shows truncated title with ellipsis (...)
- [ ] Full title visible in event details popup
- [ ] Full title visible in sidebar event list
- [ ] No layout breaking or overflow

### 7.2 Special Characters in Title
**Steps:**
1. Create events with titles:
   - "Event [Brackets] & Symbols"
   - "Test: Colons :: And More"
   - "Emoji Test 📚 📝 ✅"
2. Save each

**Expected Results:**
- [ ] All special characters preserved exactly
- [ ] No encoding/escaping issues
- [ ] Round-trip to Apple Calendar preserves characters
- [ ] Emoji display correctly in all views

### 7.3 Overlapping Events (Same Time)
**Steps:**
1. Create 3 events all on the same day, same time slot (2:00 PM - 3:00 PM)
2. Observe calendar display

**Expected Results:**
- [ ] All 3 events visible in month cell (stacked or "3 events" count)
- [ ] Sidebar shows all 3 events
- [ ] Clicking cell shows all events
- [ ] No events hidden or lost

### 7.4 Past Event Creation
**Steps:**
1. Create event in the past (e.g., last month)
2. Save

**Expected Results:**
- [ ] Event is created successfully
- [ ] No warning about past dates (or appropriate warning if policy exists)
- [ ] Event appears when navigating to that past date
- [ ] Event editable and deletable like any other event

### 7.5 Midnight Boundary Event
**Steps:**
1. Create event: 11:00 PM - 1:00 AM (crosses midnight)
2. Save

**Expected Results:**
- [ ] Event spans two days correctly
- [ ] Shows on both dates in calendar
- [ ] Time display shows correctly in both cells
- [ ] Editing preserves the overnight span

---

## Test Suite 8: Category Behavior

### 8.1 Auto-Category Detection from Title
**Steps:**
1. Create event with title "Exam Prep Session"
2. Observe category auto-selection

**Expected Results:**
- [ ] Category auto-detects as "Exam" or "Study"
- [ ] User can override by manually selecting different category
- [ ] Manual selection persists even if title changes

### 8.2 Category Preservation
**Steps:**
1. Create event with category "Lab"
2. Edit title to something unrelated to labs
3. Save
4. Reopen for editing

**Expected Results:**
- [ ] Category remains "Lab" despite title change
- [ ] Category color preserved in calendar display
- [ ] Round-trip to Apple Calendar doesn't lose category metadata

---

## Test Suite 9: URL Field

### 9.1 Valid URL
**Steps:**
1. Create event with URL: "https://zoom.us/j/123456789"
2. Save
3. View event details

**Expected Results:**
- [ ] URL is saved
- [ ] URL is clickable in event details
- [ ] Clicking opens in default browser
- [ ] URL persists through edits

### 9.2 Invalid URL Handling
**Steps:**
1. Create event with URL: "not a valid url"
2. Attempt to save

**Expected Results:**
- [ ] Validation error shown OR
- [ ] URL saved as-is but not clickable OR
- [ ] Auto-corrects to valid URL format
- [ ] User is informed of URL format expectations

---

## Test Suite 10: Accessibility & Keyboard Navigation

### 10.1 Tab Navigation
**Steps:**
1. Open Add Event sheet
2. Press Tab key repeatedly
3. Observe focus movement

**Expected Results:**
- [ ] Focus moves through all fields in logical order
- [ ] Focus visible with clear indicator
- [ ] Can reach all buttons and controls via keyboard
- [ ] Shift+Tab moves focus backward

### 10.2 Keyboard Shortcuts
**Steps:**
1. Open Add Event sheet
2. Press Cmd+Enter (or other save shortcut)

**Expected Results:**
- [ ] Event is created/saved
- [ ] Sheet dismisses
- [ ] Shortcut documented or discoverable

---

## Regression Checklist

Run this subset after any changes to event management code:

- [ ] Create basic event → appears in calendar
- [ ] Edit event → changes persist
- [ ] All-day toggle → works both ways
- [ ] Weekly recurrence with weekdays → correct days only
- [ ] One alert → notification fires
- [ ] Create in Itori → appears in Apple Calendar
- [ ] Edit in Apple Calendar → updates in Itori
- [ ] Delete in either app → syncs correctly

---

## Known Issues / Notes

(Document any known limitations or expected failures here)

- None at this time

---

## Sign-Off

**Tester:** ___________________________  
**Date:** ___________________________  
**Build Version:** ___________________________  
**Pass/Fail:** ___________________________  
**Notes:**

---

## Appendix: Test Data Templates

### Sample Event 1 (Minimal)
```
Title: Quick Test
Category: Other
Start: Today 1:00 PM
End: Today 2:00 PM
```

### Sample Event 2 (Full Fields)
```
Title: Comprehensive Test Event
Category: Class
Start: Tomorrow 10:00 AM
End: Tomorrow 11:30 AM
Location: Science Building Room 305
Notes: This event tests all available fields
URL: https://example.com/class
All-day: No
Recurrence: Weekly, every 1 week, Mon/Wed/Fri, after 6 occurrences
Primary Alert: 1 day before
Secondary Alert: 15 minutes before
```

### Sample Event 3 (Recurring All-Day)
```
Title: Holiday
Category: Other
Date: Next Monday
All-day: Yes
Recurrence: Yearly, every 1 year, no end
Alert: 1 day before
```
