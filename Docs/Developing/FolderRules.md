# Folder Rules

These rules are enforceable and apply to all new work.

## Platform Trees
- Single canonical tree per OS.
- macOS lives in `Platforms/macOS/` (canonical).
- iOS lives in `Platforms/iOS/`.
- watchOS lives in `Platforms/watchOS/`.
- `_Deprecated_macOS/` is read-only and excluded from builds.

## SharedCore Layering
- `SharedCore/Services` contains side effects only and MUST NOT import SwiftUI.
- `SharedCore/State` contains ObservableObject stores/coordinators; no SwiftUI views.
- `SharedCore/Views` contains reusable cross-platform SwiftUI views.
- `SharedCore/Models` contains Codable/Equatable data types only.

## Design System
- New UI primitives go only in `SharedCore/DesignSystem/Components`.
- Legacy wrappers live in `SharedCore/DesignSystem/Compat`.
- Tokens live in `SharedCore/DesignSystem/Tokens`.

## Platform Adapters
- Platform shims live only in `Platforms/<OS>/PlatformAdapters/`.

## Feature-Based Scenes
- Scene + subviews live together under feature folders inside `Platforms/<OS>/Scenes/`.
