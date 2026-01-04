# Platform Unification Framework

## Overview

The Platform Unification Framework establishes a clear hierarchy and capability matrix for Itori across watchOS, iOS, iPadOS, and macOS. It ensures consistent visual language while respecting platform-specific strengths and interaction models.

## Platform Hierarchy

```
watchOS → iOS → iPadOS → macOS
(Tier 0)  (Tier 1) (Tier 2)  (Tier 3)
```

### Key Principle: Selective Inheritance

- **Lower platforms DO NOT inherit from higher tiers**
- **Higher platforms CAN selectively provide features to lower tiers**
- **Each platform is optimized for its unique strengths**

## Platform Characteristics

### watchOS (Tier 0) - Glanceable

**Focus**: Quick interactions, glanceable information

**Capabilities**:
- Navigation depth: Max 2 levels
- Layout: Single-focus, full-screen
- Interaction: Touch + Digital Crown
- Density: Minimal (1-2 key items per screen)
- Target size: 44pt minimum

**Design Rules**:
- ✓ Show 1-2 key items per screen
- ✓ Use large, clear typography
- ✓ Keep interactions to 2-3 taps maximum
- ✓ Design for wrist-up interactions (5-10 seconds)
- ✗ No multi-pane layouts
- ✗ No deep navigation hierarchies
- ✗ No text input when avoidable

### iOS (Tier 1) - Immersive

**Focus**: Single-task, immersive experiences

**Capabilities**:
- Navigation depth: Max 4 levels
- Layout: Single-pane, modal sheets
- Interaction: Touch-first, swipe gestures
- Density: Standard (3-5 key items per screen)
- Target size: 44pt minimum

**Design Rules**:
- ✓ Single focus per screen
- ✓ Full-screen immersive experiences
- ✓ Bottom tab bar (max 5 items)
- ✓ Swipe gestures for navigation
- ✓ Portrait-first design
- ✗ Does NOT inherit from iPadOS
- ✗ No multi-pane layouts
- ✗ No persistent sidebars
- ✗ No hover-dependent UI

**Important**: iOS remains simple and focused. It does not drift toward iPadOS complexity.

### iPadOS (Tier 2) - Flexible Productivity

**Focus**: Flexible, productive workflows with touch + pointer

**Capabilities**:
- Navigation depth: Max 6 levels
- Layout: Multi-pane, split views
- Interaction: Touch + Pencil + Keyboard + Trackpad
- Density: Comfortable (5-8 key items per screen)
- Target size: 40pt minimum

**Design Rules**:
- ✓ Multi-pane layouts (split views)
- ✓ Sidebar + detail view pattern
- ✓ Support keyboard shortcuts (optional)
- ✓ Support trackpad/mouse hover
- ✓ Support drag and drop
- ✓ Both portrait and landscape
- ✓ Adaptive layouts for multitasking

**Selective Inheritance from macOS**:
- ✓ Keyboard shortcuts (subset)
- ✓ Hover effects (optional enhancement)
- ✓ Context menus
- ✓ Multi-window support
- ✓ Drag and drop
- ✓ Pointer precision

**Restrictions (NOT inherited from macOS)**:
- ✗ No menu bar metaphors
- ✗ No mandatory hover-only UI
- ✗ No window chrome customization
- ✗ No toolbar as primary control surface

**Important**: iPadOS selectively inherits from macOS but remains touch-first. It is NOT a macOS clone.

### macOS (Tier 3) - Maximum Power

**Focus**: Maximum power, control, and expressiveness

**Capabilities**:
- Navigation depth: Max 8 levels
- Layout: Multi-window, multi-pane, floating panels
- Interaction: Pointer-first + Keyboard
- Density: Dense (10+ items with rich detail)
- Target size: 28pt minimum

**Design Rules**:
- ✓ Multi-window, multi-pane layouts
- ✓ Three-column navigation (sidebar + content + inspector)
- ✓ Menu bar for all commands
- ✓ Full keyboard control (every action accessible)
- ✓ Pointer-first interactions
- ✓ Hover states required
- ✓ Window management (resize, minimize, full-screen)
- ✓ Advanced features visible by default
- ✓ Toolbars with customization
- ✓ Extensive preference panes

**macOS-Exclusive Features**:
- Menu bar integration
- Window chrome customization
- Keyboard as primary input method
- Right-click context everywhere
- Command palette (⌘K)
- Multiple monitor support
- System-level keyboard shortcuts

## Capability Matrix

| Capability | watchOS | iOS | iPadOS | macOS |
|-----------|---------|-----|---------|-------|
| **Navigation Depth** | 2 | 4 | 6 | 8 |
| **Multi-pane Layouts** | ✗ | ✗ | ✓ | ✓ |
| **Persistent Sidebar** | ✗ | ✗ | ✓ | ✓ |
| **Floating Panels** | ✗ | ✗ | ✗ | ✓ |
| **Hover Effects** | ✗ | ✗ | ✓ | ✓ |
| **Keyboard Shortcuts** | ✗ | ✗ | ✓ | ✓ |
| **Rich Context Menus** | ✗ | ✗ | ✓ | ✓ |
| **Multiple Windows** | ✗ | ✗ | ✓ | ✓ |
| **Drag & Drop** | ✗ | Limited | ✓ | ✓ |
| **Menu Bar** | ✗ | ✗ | ✗ | ✓ |
| **Custom Window Chrome** | ✗ | ✗ | ✗ | ✓ |
| **Touch-First** | ✓ | ✓ | ✓ | ✗ |
| **Pointer Precision** | ✗ | ✗ | ✓ | ✓ |

## Design Principles

### 1. One Visual Language

All platforms share:
- ✓ Color palette
- ✓ Typography scale (with platform adjustments)
- ✓ Icon system
- ✓ Corner radius scale
- ✓ Spacing system
- ✓ Animation timing

### 2. Platform-Appropriate Density

Information density increases with platform capability:
- **Minimal** (watchOS): 1-2 key items
- **Standard** (iOS): 3-5 key items
- **Comfortable** (iPadOS): 5-8 key items
- **Dense** (macOS): 10+ items with rich detail

### 3. Predictable Behavior

The same feature should:
- ✓ Work similarly across platforms
- ✓ Use the same data model
- ✓ Show consistent sync state
- ✓ Handle errors consistently
- But respect platform idioms and capabilities

### 4. No Lesser Clones

Each platform is fully optimized:
- ✓ Respect platform strengths
- ✓ Use native interaction models
- ✓ Don't force feature parity
- ✗ Never make one platform a "lesser version" of another

## Anti-Patterns to Avoid

### ❌ iPadOS as macOS Clone

**Don't**:
- Add menu bar to iPadOS
- Require hover for primary interactions
- Use macOS window chrome
- Make toolbar the primary control surface

**Do**:
- Use sidebar + detail pattern
- Support hover as enhancement
- Keep touch as primary input
- Use split views, not windowed panels

### ❌ iOS Inheriting iPadOS Complexity

**Don't**:
- Add multi-pane layouts to iPhone
- Use persistent sidebars on iPhone
- Force complex navigation hierarchies
- Add hover-dependent UI

**Do**:
- Keep single-focus per screen
- Use tab bar for primary navigation
- Limit navigation depth to 4 levels
- Design for portrait-first

### ❌ Desktop Paradigms on Touch Devices

**Don't**:
- Require hover states on touch devices
- Use small click targets (<44pt on touch)
- Hide primary actions in menus
- Design keyboard-only interactions

**Do**:
- Make all interactions touch-accessible
- Use appropriate tap targets (44pt minimum)
- Show primary actions prominently
- Support keyboard as enhancement

### ❌ Forced Feature Parity

**Don't**:
- Make every feature available everywhere
- Port desktop complexity to mobile
- Dumb down desktop for mobile constraints
- Create one-size-fits-all UI

**Do**:
- Optimize features for each platform
- Allow platform-specific capabilities
- Design appropriate complexity for each tier
- Create platform-specific variations

### ❌ watchOS with Deep Navigation

**Don't**:
- Create navigation hierarchies > 2 levels
- Show more than 2 key items per screen
- Require complex input
- Design for long interaction sessions

**Do**:
- Keep navigation shallow (max 2 levels)
- Show 1-2 key items per screen
- Use Digital Crown for input
- Design for 5-10 second interactions

## Implementation

### Using Platform Detection

```swift
import SharedCore

// Check current platform tier
if Platform.current == .iPadOS {
    // iPadOS-specific code
}

// Check platform capabilities
if CapabilityDomain.Layout.supportsMultiPane {
    // Show split view
}

if CapabilityDomain.Interaction.supportsHover {
    // Add hover effects
}
```

### Using Adaptive Components

```swift
import SharedCore

// Automatically adapts to platform
AdaptiveCard {
    Text("Content")
}

// Platform-appropriate button
AdaptiveButton(action: { }) {
    Text("Action")
}

// Platform-appropriate grid
AdaptiveGrid {
    ForEach(items) { item in
        ItemView(item: item)
    }
}
```

### Using Platform Modifiers

```swift
import SharedCore

Text("Hello")
    .platformPadding()  // Scales padding by platform
    .adaptiveTextSize(16)  // Scales text by platform density
    .platformHoverEffect()  // Only on platforms that support hover
    .platformContextMenu {
        Button("Action") { }
    }  // Only on platforms with rich context menus
```

## Testing Platform Rules

### Debug View

In DEBUG builds, use `PlatformDebugView` to see:
- Current platform tier
- All platform capabilities
- Validation results (anti-pattern detection)

```swift
#if DEBUG
PlatformDebugView()
#endif
```

### Validation

```swift
let errors = PlatformValidation.validate()
if !errors.isEmpty {
    print("Platform validation errors:")
    errors.forEach { print($0) }
}
```

## Files in This Framework

1. **PlatformUnification.swift**
   - Platform tier definitions
   - Capability matrix
   - Platform detection
   - View modifiers

2. **PlatformAdaptiveComponents.swift**
   - Adaptive UI components
   - Platform-specific implementations
   - Helper modifiers

3. **PlatformGuidelines.swift**
   - Platform-specific design rules
   - Anti-pattern detection
   - Validation logic
   - Debug tools

## Acceptance Criteria

- [x] Clear platform capability matrix defined
- [x] iPadOS capabilities are consistently more powerful than iOS
- [x] iOS remains simpler than iPadOS (no upward inheritance)
- [x] macOS remains most expressive platform
- [x] watchOS remains minimal and glanceable
- [x] Shared visual language across platforms
- [x] Platform-appropriate interaction density
- [x] Predictable behavior across platforms
- [x] Anti-pattern detection implemented
- [x] Debug tools for validation

## Quick Reference

### Tap Targets
- watchOS: 44pt minimum
- iOS: 44pt minimum
- iPadOS: 40pt minimum (with pointer)
- macOS: 28pt minimum (pointer precision)

### Navigation Depth
- watchOS: Max 2 levels
- iOS: Max 4 levels
- iPadOS: Max 6 levels
- macOS: Max 8 levels

### UI Density
- watchOS: 1-2 key items
- iOS: 3-5 key items
- iPadOS: 5-8 key items
- macOS: 10+ items

### Corner Radius
- watchOS: 8pt
- iOS: 12pt
- iPadOS: 16pt
- macOS: 12pt

## Future Enhancements

1. **Platform-specific animations**: Different timing curves per platform
2. **Advanced layout adaptation**: Automatic layout switching based on screen size
3. **Capability-based feature flags**: Runtime feature enabling based on platform
4. **Telemetry**: Track platform-specific usage patterns
5. **Automated testing**: Validate platform rules in CI/CD

## Resources

- [Apple Human Interface Guidelines - watchOS](https://developer.apple.com/design/human-interface-guidelines/watchos)
- [Apple Human Interface Guidelines - iOS](https://developer.apple.com/design/human-interface-guidelines/ios)
- [Apple Human Interface Guidelines - iPadOS](https://developer.apple.com/design/human-interface-guidelines/ipados)
- [Apple Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)

---

**Last Updated**: January 3, 2026  
**Version**: 1.0  
**Status**: Production Ready
