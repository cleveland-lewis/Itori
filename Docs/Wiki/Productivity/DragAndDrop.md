# Drag & Drop Reference

## Overview
- Assignment row drag sources now expose `TransferableAssignment` (UTI `com.roots.assignment`) that contains `id`, `title`, `due`, `courseId`, and `estimatedMinutes`.
- Planner and course surfaces declare `dropDestination(for: TransferableAssignment.self)` so the same payload can schedule a block or reassign a task while staying within the new SwiftUI drag/drop APIs.
- Course rows and planner’s unscheduled card highlight when a valid assignment enters the drop zone, giving users immediate feedback.

## Purpose
- Let users drag assignments into the planner to focus on a specific day, reassign tasks by dropping onto a course, and carry assignment data into other apps with a plain-text fallback.
- Keep drop validation synchronous and lightweight so invalid drops fail quietly while valid drops invoke the shared `DragDropHandler`.

## Behavior
- Assignment rows call `.draggable(TransferableAssignment(from: task))`, which exports both the JSON payload (`com.roots.assignment`) and the `plainTextRepresentation`.
- Planner unscheduled and course sections declare `.dropDestination(for: TransferableAssignment.self)` with `isTargeted` bindings that fade in outlines while the drag is over a valid target.
- On a valid drop, `DragDropHandler.scheduleAssignment` opens the planner for the due date (or today when the assignment is undated) and `DragDropHandler.reassignAssignment` updates the task’s course reference.
- After a drop, the planner coordinator scrolls to the selected date, while a toast explains what happened (e.g., “Planner opened for …”).
- Invalid payloads (missing UUID, missing task in store) simply return `false` to the drop destination, keeping the UI in its idle state.

## Data Flow
- `TransferableAssignment` conforms to `Transferable`, exporting a `CodableRepresentation` for the custom UTI and a `StringRepresentation` for `plainText`.
- Drop handling uses `assignmentsStore.tasks` to locate the original record by UUID, avoiding reliance on the dragged view’s current state.
- Reassignment updates the store through `AssignmentsStore.updateTask`, which publishes changes to every window and view that observes the store.
- Planner scheduling sets `plannerCoordinator.requestedDate` so the planner view (shared across windows) reacts by scrolling to the correct day and highlighting the new date.
- Cross-app drags that land in Notes, Mail, or other text editors receive the plain-text fallback described in `TransferableAssignment.plainTextRepresentation`.

## Limitations
- Dragging scheduled planner blocks for reordering is not implemented; the planner UI does not expose deterministic reorder semantics yet, so drops are restricted to unscheduled assignments or course reassignments.
- Drops between multiple internal windows rely on the shared store; dropping from another app requires the receiving host to understand the `com.roots.assignment` UTI if it needs structured data.

## Related Systems
- `SharedCore/Navigation/DragDropTypes.swift` defines `UTType.rootsAssignment`, `TransferableAssignment`, and `TransferableCourse`.
- `SharedCore/DragDrop/DragDropHandlers.swift` exposes `DragDropHandler.reassignAssignment` and `.scheduleAssignment`, which the views use and the tests cover.
- `IOSCorePages.swift` wires `.droppable` surfaces and displays the toast/animation states described here.
