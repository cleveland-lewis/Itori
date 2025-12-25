# Drag & Drop Reference

## Payload definitions
- `AssignmentDragPayload` (SharedCore/DragDrop/DragDropTypes.swift) serializes `id`, `title`, optional `dueDate`, and optional `courseId`. This JSON blob travels over the custom `UTType` and is decoded by incoming drops. The `fallbackDescription` property also provides a human-readable string for cross-app transfers.
- The assignment provider registers the custom type `UTType(exportedAs: "com.roots.assignment")` plus a plaintext object so that arbitrary drop targets see the title (and due date when available).

## UTType mapping
- `DragDropType.assignment` = `com.roots.assignment` (document-level). The drop handler invokes `AssignmentDragPayload.load(from:providers:completion:)` before returning success, so invalid payloads are skipped gracefully.

## In-app drop behaviors
- **Course rows** (iOS/IOSCorePages.swift) call `handleAssignmentDrop(_:into:)` to assign the dropped payload’s task to the target course. The handler mutates the `AssignmentsStore` task and persists it immediately.
- **Planner unscheduled section** accepts assignment drops and routes to `PlannerCoordinator.openPlanner`, using the payload’s due date (or `Date()`) to focus the correct day while also showing a toast.
- Assignment rows are drag sources because each row now calls `task.itemProvider()`, which wraps `AssignmentDragPayload` into an `NSItemProvider` for both internal drag sessions and cross-app share operations.

## Accessibility & feedback
- Drop targets update their stroke opacity when a drag is over them, giving users visual confirmation that the course or planner section will accept the assignment.
- Invalid drops simply return `false`, so the UI shows no change and the drag can be aborted.
