# Planner and Scheduler

The planner transforms assignments into scheduled work sessions distributed across available time blocks.

## Overview

The scheduler operates on a time-blocked model:
- Daily schedule divided into 30-minute blocks
- Default time window: 09:00–21:00 (configurable in settings)
- Sessions are assigned to specific blocks based on priority, due dates, and energy requirements

## Session Generation

When an assignment is created, the planner analyzes its properties and generates one or more work sessions.

### Exam and Quiz Assignments
- Generate multiple **Study Sessions** spaced over time
- Number of sessions depends on estimated study time and days remaining until the exam
- Earlier sessions focus on initial review; later sessions on final preparation
- Sessions are distributed to avoid cramming immediately before the due date

### Homework and Reading Assignments
- Generate one or more work sessions based on estimated duration
- Short assignments: single session
- Long assignments: split into multiple sessions across available days
- Sessions scheduled working backward from the due date

### Project Assignments
- Generate **Work Sessions** for incremental progress
- User can specify desired number of sessions or allow automatic splitting
- Sessions distributed across time until deadline
- Session duration adjusted based on total estimated work time

## Scheduling Priority

Sessions are ordered using multiple factors:
- **Due date urgency** – Closer deadlines receive higher priority
- **Assignment priority level** – User-defined High/Medium/Low
- **Category weight** – Exams prioritized over homework, etc.

Sessions with higher computed priority are placed into earlier available time slots.

## Energy-Aware Placement

If user configures an energy profile:
- High-energy time blocks (e.g., morning) are preferred for high-difficulty tasks
- Low-energy blocks (e.g., evening) are used for low-difficulty tasks
- Sessions are placed into time blocks with matching energy levels when possible

Energy profiles are optional. Without configuration, all time blocks are treated equally.

## Overflow Queue

When the planner cannot fit a session into available time blocks before its due date, the session is placed into the **Overflow Queue**.

### Causes of Overflow
- Schedule fully booked with higher-priority sessions
- Insufficient time remaining before due date
- User-blocked time slots conflicting with optimal placement

### Resolving Overflow
- Review overflow queue in planner interface
- Manually assign overflow sessions to available slots
- Reduce estimated duration of existing sessions to free time blocks
- Extend due dates for lower-priority assignments
- Delete or archive completed sessions to create space

## Manual Adjustments

Users can override automatic scheduling:
- Drag sessions to different time blocks
- Extend or shorten session duration
- Mark sessions as complete before their scheduled time
- Delete sessions that are no longer needed

Manual changes persist until the next regeneration event (e.g., creating a new assignment or changing priorities).

## Regeneration Triggers

The planner recalculates and redistributes sessions when:
- A new assignment is added
- An existing assignment's due date or priority changes
- User requests manual regeneration via planner controls

Regeneration respects manually pinned or locked sessions if that feature is available.

## Session Completion

Marking a session complete:
- Removes it from the active schedule
- Updates assignment progress tracking
- May trigger rescheduling of remaining sessions
- Does not delete session history (visible in completion logs)

Completing all sessions for an assignment marks the assignment as complete.

## Time Block Conflicts

If multiple sessions compete for the same time block:
- Higher-priority session takes precedence
- Conflicting sessions are rescheduled to the next available block
- If rescheduling is not possible, sessions move to overflow

## Filtering and Views

Planner view can be filtered by:
- Course (show only sessions for a specific course)
- Category (show only exams, projects, etc.)
- Date range (today, this week, custom range)

Filters do not affect scheduling logic, only display.

---

**Next:** [Calendar and Timeline Views](Calendar-and-Timeline)  
**See Also:** [Assignment Management](Assignment-Management), [Settings](Settings-and-Configuration)
