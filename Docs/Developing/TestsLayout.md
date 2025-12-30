# Tests Layout

## Canonical Structure
- `Tests/Unit/` for unit tests
- `Tests/Integration/` for integration tests
- `Tests/RootsUITests/` for UI tests

## Notes
- UI tests must remain isolated from unit/integration test bundles.
- Do not add new test roots outside `Tests/`.
