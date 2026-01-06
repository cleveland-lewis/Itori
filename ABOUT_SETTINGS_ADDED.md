# About Settings Section Added

## Overview
Created a new "About" section in the macOS Settings that displays app information, version details, and contact links. Positioned at the bottom of the settings navigation stack.

## Changes Made

### 1. Added About Case to Settings Enum
**File:** `Platforms/macOS/PlatformAdapters/SettingsToolbarIdentifiers.swift`

Added new `about` case:
- Position: Last in enum (after `subscription`)
- Label: "About"
- Icon: `info.circle`

```swift
enum SettingsToolbarIdentifier: String, CaseIterable, Identifiable {
    // ... other cases
    case subscription
    case about  // New case
}
```

### 2. Created About Settings View
**File:** `Platforms/macOS/Views/AboutSettingsView.swift` (New)

A comprehensive About view featuring:

**App Information:**
- App icon display (128x128pt with rounded corners and shadow)
- App name and tagline
- Version number (from bundle info)
- Build date

**Description:**
- Brief overview of app functionality
- Centered, multi-line text

**Action Buttons:**
- "Visit Website" - Opens https://itori.app
- "Contact Support" - Opens mailto:support@itori.app

**Footer:**
- Copyright notice: "© 2026 Itori. All rights reserved."

**Layout:**
- Max width: 500pt
- Centered content
- 40pt padding
- Proper spacing hierarchy (32/16/12/8pt)

### 3. Wired Up in Settings Window
**Files Modified:**
- `Platforms/macOS/PlatformAdapters/RootsSettingsWindow.swift`
- `Platforms/macOS/PlatformAdapters/SettingsWindowController.swift`

Added `case .about: AboutSettingsView()` to both switch statements.

## Features

### Dynamic Version Display
```swift
private let appVersion: String = {
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
        return "\(version) (\(build))"
    }
    return "1.0.0"
}()
```

### External Links
Uses `@Environment(\.openURL)` for:
- Website navigation
- Email client integration

### Responsive Layout
- Uses `.fixedSize(horizontal: false, vertical: true)` for text wrapping
- Spacer pushes footer to bottom
- Max width constraint keeps content readable

## Settings Navigation Order

The final settings order:
1. General
2. Calendar
3. Reminders
4. Planner
5. Courses
6. Semesters
7. Interface
8. Profile
9. Timer
10. Flashcards
11. Practice
12. LLM
13. Integrations
14. Notifications
15. Privacy
16. Storage
17. Developer
18. Subscription
19. **About** ← New

## Design Decisions

### Why "About" at the Bottom?
- Standard convention (macOS apps typically have About last)
- Informational, not frequently accessed
- Follows Settings > Subscription placement pattern

### Why info.circle Icon?
- Standard macOS symbol for informational content
- Consistent with system design language
- Recognizable and accessible

### Why No Analytics/Privacy Info?
- Keep it simple and focused
- Privacy info already exists in Privacy settings
- Can be expanded later if needed

## Testing

Verify on macOS:
1. Open Settings (⌘,)
2. Scroll to bottom of sidebar
3. Click "About"
4. Verify all information displays correctly
5. Test "Visit Website" button (should open browser)
6. Test "Contact Support" button (should open mail app)
7. Verify app icon shows if available
8. Check version number is correct

## Future Enhancements

Potential additions:
- Acknowledgements section (open source libraries)
- Release notes/changelog viewer
- System requirements display
- License information
- Credits/team information
- Debug information (for support)

## Date
2026-01-06
