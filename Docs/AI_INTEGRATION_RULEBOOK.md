AI Integration Rulebook

Allowed callers
- ViewModels (not Views).
- Reducers (if using TCA).
- Background jobs / import pipeline.
- AIEngine orchestrators.

Not allowed
- SwiftUI Views.
- Arbitrary helpers in feature folders.
- Anything reachable from `body`.

Enforcement
- Use `@MainActor` boundaries for UI-facing orchestration.
- CI: no provider imports outside AIEngine.
- CI: grep test for AIEngine calls outside allowed layers.
