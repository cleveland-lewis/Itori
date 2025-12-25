# Multiwindow and Drag/Drop Reference

## Multiwindow overview
- **Assignment detail windows** now exist as a dedicated `WindowGroup` (`AssignmentSceneContent`). Each window is activated through `SceneActivationHelper.openAssignmentWindow(for:)`, invoked by the Assignments list context menu, and has the same environment objects (`AssignmentsStore.shared`, `CoursesStore`). Mac and iPad share the scene so the same window experience is available on both platforms.
- Windows are driven by SwiftUI scenes (`WindowGroup`), which makes them available to Split View, Stage Manager, and native macOS multiple-window workflows.

## Per-window state
- Each assignment scene keys its state with `SceneStorage` using `SceneActivationHelper.assignmentSceneStorageKey`. The assignment UUID is preserved per window, so closing and reopening restores the same assignment detail when the scene is reactivated.
- Assignment selection comes from the `NSUserActivity` payload (`com.roots.scene.assignmentDetail`), so requesting a new window with any assignment ID initializes the scene state before the view appears.
- A placeholder view explains how to open a new window when the stored identifier no longer resolves to an existing task.

## Drag & drop summary
- Assignment rows expose `AppTask.itemProvider()` which produces an `NSItemProvider` backing a `AssignmentDragPayload`. This provider supplies both a custom `UTType(exportedAs: "com.roots.assignment")` payload and plaintext fallback so cross-app drops work.
- Courses accept assignment drops on their rows to reassign tasks immediately; a drop target highlight reveals the course that will receive the assignment.
- The planner’s unscheduled section can accept assignment drops and will open the planner for the dragged assignment, setting the view to the payload’s due date (or today if the payload is undated).
