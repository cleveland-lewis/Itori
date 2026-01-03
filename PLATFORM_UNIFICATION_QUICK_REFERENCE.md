# Platform Unification Quick Reference

## Platform Hierarchy
```
watchOS (T0) → iOS (T1) → iPadOS (T2) → macOS (T3)
```

## One-Line Rules

| Platform | Rule |
|----------|------|
| **watchOS** | Glanceable, 2-tap max, 1-2 items |
| **iOS** | Single-focus, immersive, simple |
| **iPadOS** | Flexible, selective macOS features, touch-first |
| **macOS** | Maximum power, pointer-first, keyboard everything |

## Capability Quick Check

```swift
// Platform detection
Platform.current  // .watchOS, .iOS, .iPadOS, or .macOS
Platform.isWatch  // Bool
Platform.isPhone  // Bool
Platform.isTablet // Bool
Platform.isDesktop // Bool

// Layout
CapabilityDomain.Layout.supportsMultiPane  // iPad+
CapabilityDomain.Layout.supportsPersistentSidebar  // iPad+
CapabilityDomain.Layout.supportsFloatingPanels  // macOS only
CapabilityDomain.Layout.maxNavigationDepth  // 2/4/6/8

// Interaction
CapabilityDomain.Interaction.supportsHover  // iPad+
CapabilityDomain.Interaction.supportsKeyboardShortcuts  // iPad+
CapabilityDomain.Interaction.supportsRichContextMenus  // iPad+
CapabilityDomain.Interaction.supportsMultipleWindows  // iPad+
CapabilityDomain.Interaction.hasPointerPrecision  // iPad+
CapabilityDomain.Interaction.isTouchFirst  // Up to iPad

// Density
CapabilityDomain.Density.uiDensity  // .minimal/.standard/.comfortable/.dense
CapabilityDomain.Density.minTapTargetSize  // 44/44/40/28 pt
CapabilityDomain.Density.paddingScale  // 0.8/1.0/1.2/1.0x

// Visual
CapabilityDomain.Visual.hasMenuBar  // macOS only
CapabilityDomain.Visual.supportsCustomWindowChrome  // macOS only
CapabilityDomain.Visual.prefersTabBar  // iOS & watch
CapabilityDomain.Visual.prefersSidebar  // iPad+

// Navigation
CapabilityDomain.Navigation.supportsBreadcrumbs  // macOS only
CapabilityDomain.Navigation.supportsSwipeBack  // Up to iPad
CapabilityDomain.Navigation.navigationStyle  // .stack/.splitView/.sidebar
```

## Common Modifiers

```swift
// Padding
.platformPadding()  // Auto-scales by platform

// Hover
.platformHoverEffect()  // Only on capable platforms

// Context menu
.platformContextMenu { /* items */ }  // Only on capable platforms

// Text size
.adaptiveTextSize(16)  // Scales by density

// Tap gesture
.adaptiveTapGesture { /* action */ }  // Platform-appropriate

// Long press
.adaptiveLongPress { /* action */ }  // Platform-appropriate duration
```

## Adaptive Components

```swift
// Card
AdaptiveCard {
    Text("Content")
}

// Button
AdaptiveButton(action: { }) {
    Text("Action")
}

// Grid
AdaptiveGrid {
    ForEach(items) { item in
        ItemView(item: item)
    }
}

// VStack with platform spacing
AdaptiveVStack {
    Text("Item 1")
    Text("Item 2")
}

// HStack with platform spacing
AdaptiveHStack {
    Text("Item 1")
    Text("Item 2")
}
```

## Feature Flags

```swift
if PlatformFeature.isEnabled(.multiWindow) {
    // Multiple windows supported
}

if PlatformFeature.isEnabled(.keyboardShortcuts) {
    // Add keyboard shortcuts
}

if PlatformFeature.isEnabled(.hoverEffects) {
    // Add hover states
}
```

## Quick Design Decisions

### Should I use a sidebar?
- watchOS: ❌ No
- iOS: ❌ No (use tab bar)
- iPadOS: ✅ Yes
- macOS: ✅ Yes

### Should I support hover?
- watchOS: ❌ No
- iOS: ❌ No
- iPadOS: ✅ Optional enhancement
- macOS: ✅ Required

### Should I add keyboard shortcuts?
- watchOS: ❌ No
- iOS: ❌ No
- iPadOS: ✅ Optional (power users)
- macOS: ✅ Required (every action)

### How many items per screen?
- watchOS: 1-2
- iOS: 3-5
- iPadOS: 5-8
- macOS: 10+

### How deep can navigation go?
- watchOS: 2 levels max
- iOS: 4 levels max
- iPadOS: 6 levels max
- macOS: 8 levels max

### What's my tap target size?
- watchOS: 44pt minimum
- iOS: 44pt minimum
- iPadOS: 40pt minimum
- macOS: 28pt minimum

### What corner radius should I use?
- watchOS: 8pt
- iOS: 12pt
- iPadOS: 16pt
- macOS: 12pt

## Common Anti-Patterns

| Anti-Pattern | Detection | Fix |
|-------------|-----------|-----|
| iPad as Mac clone | Menu bar on iPad | Use sidebar instead |
| iOS gets iPad complexity | Multi-pane on phone | Keep single-focus |
| Hover-required on touch | No touch alternative | Make touch primary |
| Watch deep navigation | Depth > 2 | Flatten hierarchy |

## Debug Command

```swift
#if DEBUG
// Show platform info
PlatformDebugView()

// Print capability matrix
PlatformCapabilityMatrix.printMatrix()

// Validate platform rules
let errors = PlatformValidation.validate()
errors.forEach { print($0) }
#endif
```

## Files

1. `SharedCore/Platform/PlatformUnification.swift` - Core framework
2. `SharedCore/Platform/PlatformAdaptiveComponents.swift` - UI components
3. `SharedCore/Platform/PlatformGuidelines.swift` - Design rules & validation
4. `PLATFORM_UNIFICATION_FRAMEWORK.md` - Full documentation

## Validation Checklist

- [ ] Platform tier correctly detected
- [ ] Capabilities match platform
- [ ] No iOS inheriting from iPad
- [ ] No iPad acting as Mac clone
- [ ] No hover-required on touch
- [ ] Navigation depth within limits
- [ ] Tap targets meet minimums
- [ ] Density appropriate for platform

---

**Quick Start**: Import `SharedCore`, use `Platform.current` to detect platform, use `CapabilityDomain.*` to check capabilities, use adaptive components for automatic adaptation.
