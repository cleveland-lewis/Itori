# Merge Conflict Resolution: fix/calendar-month-grid-visual-corrections → main

## Date
2026-01-03

## Branches Involved
- **Source**: `fix/calendar-month-grid-visual-corrections`
- **Target**: `main`

## Conflict Location
`Platforms/macOS/Views/CalendarGrid.swift`

## Conflict Details

### 1. Cell Height Change
- **main**: `.frame(height: 80)`
- **fix branch**: `.frame(height: 90)`
- **Resolution**: Accepted fix branch (90) for better cell aspect ratio

### 2. Comment Improvements
Multiple comment conflicts where the fix branch had more descriptive/precise comments:
- "Day number at top-left with only today getting a red circle" → "Day number at top-left with ONLY today getting a small red circle"
- "ONLY today gets a circle - small red circle" → "CRITICAL: ONLY today gets a circle - small red circle behind date number"
- "Event bars (horizontal colored bars, not dots)" → "Event bars (horizontal colored bars, not dots+text)"
- "Helper view for event bars" → "Helper view for horizontal event bars"
- "Time for timed events" → "Time for timed events (all-day events show no time)"
- "Colored bar with event title" → "Colored horizontal bar with event title"
- "Color indicator bar" → "Left color indicator bar"

### 3. Environment Variable Location
- **main**: Had `@Environment(\.colorScheme)` at top of `GridDayCell` (line 99)
- **fix branch**: Also at top, but had removed a duplicate declaration that was after the body
- **Resolution**: Accepted fix branch version (single declaration at top)

## Resolution Strategy
Used `git checkout --theirs` to accept the fix branch version entirely, as all changes were improvements:
- Better visual spacing (height 90)
- More precise documentation
- Cleaner code organization (no duplicate declarations)

## Additional Files Changed in Merge
- `CALENDAR_GRID_FIXES.md` (new)
- `ItoriApp.xcodeproj/project.pbxproj`
- `Platforms/iOS/Scenes/Settings/Categories/IOSIntelligentSchedulingSettingsView.swift`
- `Roots-Info.plist` (new)
- `SharedCore/Services/FeatureServices/EnhancedAutoRescheduleService.swift`

## Build Status
Merge completed successfully. Note: There are unrelated build errors in `AIEngine.swift` related to missing `LOG_DEV` symbol, but these exist on both branches and are not caused by this merge.

## Commit Hash
`3cc178bc`
