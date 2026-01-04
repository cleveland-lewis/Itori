# Testing Notes

## Overview
- Automated coverage targets the transferable payloads and the helper routines that map drops into store/state changes.
- Manual scripts focus on the high-value workflows (multiwindow context menus and drag-to-planner interactions) that SwiftUI drag/drop and scene restoration govern.

## Purpose
- Ensure `TransferableAssignment` serializes as expected and supports both JSON and plaintext exports (`ItoriTests/DragDropTypesTests.swift`).
- Verify `DragDropHandler` updates the correct store/coordinator state so drag destinations are deterministic (`ItoriTests/DragDropHandlerTests.swift`).
- Validate multiwindow flows by opening course, assignment, planner, and timer scenes on iPad Stage Manager and macOS.
- Confirm drag/drop still works when dragging between in-app panes and into cross-app hosts such as Notes or Mail.

## Behavior
- Automatic tests run via `xcodebuild test -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15'` (adjust the destination as needed for macOS by adding `-destination 'platform=macOS'`).
  * `DragDropTypesTests` exercises `TransferableAssignment`/`TransferableCourse` constructors, text formatting, and `WindowState` encoding.
  * `DragDropHandlerTests` exercises reassignment and planner scheduling, verifying `AssignmentsStore` and `PlannerCoordinator` behave as expected.
- Manual verification steps:
  1. On iPad (Stage Manager or Split View), long-press an assignment row, tap “Open in New Window”, and confirm the assignment detail appears in a second window and restores after quitting the app.
  2. On macOS, right-click the same assignment and select “Open in New Window”; confirm multiple windows stay open and CMD-` cycles through them.
  3. Drag an assignment from the list into the planner’s unscheduled drop zone; verify the planner scrolls to the assignment’s due date, highlights the drop zone, and a toast appears.
  4. Drag the same assignment onto a course card; the drop target highlight should appear, and the task’s course assignment updates immediately (check the Courses view or a quick filter).
  5. Drag the assignment into Notes or Mail; confirm the exported text includes the title, due date (if set), and the estimated minutes line returned by `TransferableAssignment.plainTextRepresentation`.

## Data Flow
- Launching a window relies on `WindowIdentifier`/`WindowState`, so any change to those structures should be accompanied by updates to `SceneActivationHelper` and retriggering the tests above.
- Drag/drop routines rely on the transferable payloads defined in `SharedCore/Navigation/DragDropTypes.swift`, so multi-platform changes to those definitions should adapt the unit tests accordingly.
- `DragDropHandler` uses the `AssignmentTaskUpdating` protocol, which tests mock easily and keeps the view layer glue-free.

## Limitations
- Multiwindow and drag/drop manual testing require devices or simulators capable of Stage Manager / multiple macOS windows; the simulator needs to run on a host that supports Catalina or later to host multiple windows simultaneously.
- Automated tests cover store manipulations and serialization but do not exercise the UI preview or toast states shown to the user.

## Related Systems
- `ItoriTests/DragDropTypesTests.swift` and `ItoriTests/DragDropHandlerTests.swift` live alongside the main app tests to highlight the transferable payloads and drop mapping rules outlined in this wiki.
- `SceneActivationHelper`, `WindowIdentifier`, and `DragDropHandler` form the shared plumbing that these tests validate.
