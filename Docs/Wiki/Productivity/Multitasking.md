# Multitasking Overview

## Overview
- Multiwindow and drag/drop make Roots more productive on iPad and macOS by letting users open assignment, course, planner, and timer surfaces without disrupting the main workspace.
- SceneStorage keys and `WindowState` keep each window tied to its entity while `SceneActivationHelper` centralizes the short-lived `NSUserActivity` payload that drives window activation.
- Drag/drop uses a custom transferable payload (`TransferableAssignment`) backed by exported UTIs so assignments move fluidly inside Roots and to other apps.

## Purpose
- Keep each screen self-contained so a user can open multiple assignment or course details side by side, work across planner days, and monitor the timer in a dedicated window.
- Surface “Open in New Window” actions on assignments, courses, and the planner header so multiwindow workflows are discoverable and scoped to devices that support them.
- Let assignment drags carry both structured data (`com.roots.assignment`) and a plain-text summary to satisfy in-app scheduling and cross-app sharing.

## Behavior
- Main app scene (`IOSRootView` / `ContentView`) loads with the usual stores. Assignment, course, planner, and timer windows register as separate `WindowGroup` scenes tied to `WindowIdentifier` values.
- Course and planner scene contents live in `SharedCore/Scenes/MultiWindowScenes.swift` and read `SceneStorage` using keys such as `roots.scene.courseDetail.courseId` and `roots.scene.plannerDay.dateId`.
- Assignment detail windows reuse `AssignmentSceneContent`, which decodes the `WindowState` embedded in the continuing `NSUserActivity` and populates `@SceneStorage` with the assignment UUID.
- `SceneActivationHelper` serializes `WindowState` JSON, assigns friendly titles, and launches scenes so each window remembers the entity it displayed even after a full shutdown.
- Planner and course lists add context menus on iPad and macOS to call the helper, whereas iPhone omits “Open in New Window” to avoid unsupported configurations.
- Dragging an assignment from the list now uses `.draggable(TransferableAssignment(from: task))`; planner and course panes accept `.dropDestination(for: TransferableAssignment.self)` to trigger scheduling or reassignment.

## Data Flow
- Window activation flows from a context menu through `SceneActivationHelper.openAssignmentWindow` / `.openCourseWindow` / `.openPlannerWindow`, setting the serialized `WindowState` in `NSUserActivity`.
- Scenes decode the state via `SceneActivationHelper.decodeWindowState`, update the matching `SceneStorage` key, and rebuild the view model tied to the requested entity.
- Drag payloads serialize `AppTask` fields and also expose `plainTextRepresentation` so the system can fall back to a human-readable string when crossing into Notes or Mail.
- Drop handlers (`DragDropHandler`) mutate `AssignmentsStore` and `PlannerCoordinator` directly to keep stores synchronized across windows without manual notification wiring.

## Limitations
- Picture-in-picture is intentionally out of scope because Roots has no AVPlayer or call surface; the app relies on multiwindow + floating planner blocks to maintain visibility instead.
- “Open in New Window” is gated by device type (iPad or macOS) and size class; iPhone still uses the single-window experience to preserve stability.
- Timer windows reuse the existing timer view (`IOSTimerPageView` / `TimerPageView`), so any timer-specific state lives locally to that instance rather than being shared via `WindowState`.

## Related Systems
- `WindowIdentifier` / `WindowState` in `SharedCore/Navigation` enumerate the available scenes and describe how codes and titles persist.
- `SceneActivationHelper` packs and unpacks window metadata, requests new `SceneSession`s, and exposes the `SceneStorage` keys referenced by each scene content view.
- `AssignmentsStore`, `CoursesStore`, `PlannerStore`, and `PlannerCoordinator` form the shared state surface exposed through each window’s environment.
