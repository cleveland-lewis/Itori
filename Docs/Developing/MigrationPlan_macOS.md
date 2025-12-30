# macOS Migration Plan

## Goal
Move macOS to `Platforms/macOS/` and deprecate the legacy `macOS/` tree without changing behavior.

## Steps
1. Create `Platforms/` root with `Platforms/macOS`.
2. Move `macOSApp/` to `Platforms/macOS/`.
3. Update Xcode project root group path to `Platforms/macOS/`.
4. Rename legacy `macOS/` to `_Deprecated_macOS/` and exclude it from builds.
5. Stabilize, then remove `_Deprecated_macOS/` after the deprecation window.

## Guardrails
- CI check for duplicate scene/view filenames across `Platforms/macOS/` and `_Deprecated_macOS/`.
- CI check to prevent SwiftUI imports in `SharedCore/Services`.
