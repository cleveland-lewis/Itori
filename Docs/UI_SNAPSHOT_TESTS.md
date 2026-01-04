# UI Snapshot Tests

The UI test target now contains a lightweight snapshot harness to catch design drift (spacing, radii, typography, iconography, materials) across critical screens.

- Snapshots cover: Calendar (month/week/year), Planner, Timer/Focus, Settings (General/Calendar/Reminders), and modal/alert overlays.
- Variants: light + dark mode and standard + accessibility dynamic type (`UICTContentSizeCategoryAccessibilityXXXL`).
- Baselines live in `ItoriUITests/__Snapshots__/` and are compared byte-for-byte to new runs.

## Recording baselines locally

```bash
cd /Users/clevelandlewis/Desktop/Itori
RECORD_UI_SNAPSHOTS=1 xcodebuild \
  -scheme Itori \
  -destination 'platform=macOS' \
  -only-testing:ItoriUITests/UISnapshotTests
```

## Validating in CI

Run the same command without `RECORD_UI_SNAPSHOTS` to fail on regressions. The harness disables animations and applies the requested color scheme + dynamic type via environment so runs are deterministic. Commit the generated PNGs in `ItoriUITests/__Snapshots__/` so CI can compare them.
