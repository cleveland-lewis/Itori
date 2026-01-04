# Multiwindow Detail

## Overview
- Itori registers four dedicated `WindowGroup` scenes (`assignmentDetail`, `courseDetail`, `plannerDay`, `timerSession`) that share the same stores as the main app window.
- Each scene has its own `SceneStorage` key (e.g., `roots.scene.assignmentDetail.assignmentId`) so the selected entity stays pinned to a given window.

## Purpose
- Assignment windows keep the detail view accessible while the main tab continues other work.
- Course windows surface course metadata plus assignments without collapsing navigational context.
- Planner windows focus on a single day, enabling simultaneous visibility of two different days in Split View or on Stage Manager.
- Timer windows host the existing timer module so productivity tracking can run in a side window.

## Behavior
- The iOS and macOS entry points add `WindowGroup(id: WindowIdentifier...)` blocks for each scene, wiring the same environment objects as the main window.
- Course and planner windows read their `SceneStorage` keys via the shared views in `SharedCore/Scenes/MultiWindowScenes.swift` and show descriptive placeholders when the target entity is missing.
- `SceneActivationHelper` builds a `WindowState` payload, encodes it as JSON, assigns a human-friendly title, and requests `UIScene` / `NSApplication` activation so the new window restores with the expected metadata.
- “Open in New Window” menus on assignment rows, course cards, and the planner header call the helper; the menu is only injected when the device supports multiple windows (iPad or macOS).
- Assignment detail windows update their context menu to show a “Close” button via the navigation stack’s toolbar, helping users dismiss autos created scenes.

## Data Flow
- The multiwindow infrastructure depends on the `AssignmentsStore`, `CoursesStore`, `PlannerStore`, and timer managers that already live in `@StateObject`s at the top level.
- Window activation flows from a menu action through `SceneActivationHelper.open*Window`, which encodes `WindowState` (window ID, entity UUID, optional display title) and calls `requestSceneSessionActivation`.
- Scene views capture the payload in `.onContinueUserActivity`, decode the `WindowState`, and update the relevant `@SceneStorage` string, which keeps the same identifier even after the scene is terminated and later restored.
- Planner and course scenes query the shared stores by UUID, so they stay synchronized with edits performed elsewhere.

## Limitations
- Multiwindow is disabled on iPhone because the relevant context menus and window APIs are not surfaced on compact devices; the same assignments/courses view continues to operate as a single scene.
- Timer windows run the same timer view but do not carry a `WindowState` payload beyond the window identifier, so restoring a timer window only resumes the view with its ephemeral state.

## Related Systems
- `WindowIdentifier` and `WindowState` in `SharedCore/Navigation` enumerate each scene and provide the schema for serialized state.
- `SceneActivationHelper` centralizes user activity creation, encodes the JSON blob, and exposes the `SceneStorage` keys referenced by each scene payload.
- Timer windows reuse `IOSTimerPageView` / `TimerPageView` and depend on `AppSettingsModel` plus `SettingsCoordinator` to maintain preferences inside the new scene.
