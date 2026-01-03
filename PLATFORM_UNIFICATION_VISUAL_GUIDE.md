# Platform Unification Framework - Visual Guide

## Platform Hierarchy Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    PLATFORM HIERARCHY                            │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │   watchOS    │  Tier 0 - Glanceable
    │  (Minimal)   │  • 1-2 items per screen
    └──────┬───────┘  • Max 2 navigation levels
           │          • 44pt tap targets
           ↓          • Touch + Digital Crown
    ┌──────────────┐
    │     iOS      │  Tier 1 - Immersive
    │  (Standard)  │  • 3-5 items per screen
    └──────┬───────┘  • Max 4 navigation levels
           │          • 44pt tap targets
           │          • Touch + Gestures
           ↓
    ┌──────────────┐
    │   iPadOS     │  Tier 2 - Flexible
    │(Comfortable) │  • 5-8 items per screen
    └──────┬───────┘  • Max 6 navigation levels
           │          • 40pt tap targets
           │ ↖        • Touch + Pencil + Keyboard + Trackpad
           │   ╲      • Selective inheritance from macOS →
           ↓     ╲
    ┌──────────────┐
    │    macOS     │  Tier 3 - Maximum Power
    │   (Dense)    │  • 10+ items per screen
    └──────────────┘  • Max 8 navigation levels
                      • 28pt click targets
                      • Pointer + Keyboard (primary)
```

## Inheritance Rules

```
┌─────────────────────────────────────────────────────────────────┐
│                    INHERITANCE FLOW                              │
└─────────────────────────────────────────────────────────────────┘

watchOS → [ISOLATED]
  • Does not inherit from any platform
  • Fully custom for wrist interaction

iOS → [ISOLATED FROM iPadOS]
  • Does not inherit from iPadOS
  • Stays simple and focused
  • No upward complexity drift

iPadOS → [SELECTIVE FROM macOS]
  • ✓ Inherits: Keyboard shortcuts (subset)
  • ✓ Inherits: Hover effects (enhancement)
  • ✓ Inherits: Multi-window support
  • ✓ Inherits: Drag & drop
  • ✗ Does NOT inherit: Menu bar
  • ✗ Does NOT inherit: Window chrome
  • ✗ Does NOT inherit: Hover-required UI

macOS → [SOURCE OF TRUTH]
  • Maximum capability platform
  • Can provide features to lower tiers
  • Does not inherit (highest tier)
```

## Capability Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                  CAPABILITY DISTRIBUTION                         │
└─────────────────────────────────────────────────────────────────┘

Feature            watchOS    iOS    iPadOS    macOS
─────────────────  ───────    ───    ──────    ─────
Touch Input          ████     ████    ████      ░░░░
Pointer              ░░░░     ░░░░    ████      ████
Multi-Pane           ░░░░     ░░░░    ████      ████
Sidebar              ░░░░     ░░░░    ████      ████
Tab Bar              ████     ████    ░░░░      ░░░░
Hover Effects        ░░░░     ░░░░    ████      ████
Keyboard Shortcuts   ░░░░     ░░░░    ████      ████
Context Menus        ░░░░     ░░░░    ████      ████
Multi-Window         ░░░░     ░░░░    ████      ████
Menu Bar             ░░░░     ░░░░    ░░░░      ████
Window Chrome        ░░░░     ░░░░    ░░░░      ████
Drag & Drop          ░░░░     ▓▓▓▓    ████      ████

Legend: ████ Full Support  ▓▓▓▓ Limited Support  ░░░░ Not Supported
```

## Navigation Depth Comparison

```
┌─────────────────────────────────────────────────────────────────┐
│                  NAVIGATION DEPTH LIMITS                         │
└─────────────────────────────────────────────────────────────────┘

watchOS (Max 2)      iOS (Max 4)       iPadOS (Max 6)     macOS (Max 8)
───────────────      ───────────       ──────────────     ─────────────
[Root]               [Root]            [Root]              [Root]
  └─ [L1]              └─ [L1]           └─ [L1]             └─ [L1]
                         └─ [L2]           └─ [L2]             └─ [L2]
                           └─ [L3]           └─ [L3]             └─ [L3]
                                               └─ [L4]             └─ [L4]
                                                 └─ [L5]             └─ [L5]
                                                                       └─ [L6]
                                                                         └─ [L7]
```

## UI Density Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                     UI DENSITY SCALE                             │
└─────────────────────────────────────────────────────────────────┘

watchOS (Minimal)          iOS (Standard)
┌──────────────────┐      ┌──────────────────┐
│                  │      │  [Item 1]        │
│    [Item 1]      │      │  [Item 2]        │
│                  │      │  [Item 3]        │
│    [Item 2]      │      │  [Item 4]        │
│                  │      │  [Item 5]        │
└──────────────────┘      └──────────────────┘

iPadOS (Comfortable)       macOS (Dense)
┌──────────────────┐      ┌──────────────────┐
│ [1] [2] [3]      │      │[1][2][3][4][5]   │
│ [4] [5] [6]      │      │[6][7][8][9][10]  │
│ [7] [8]          │      │[11][12][13][14]  │
│                  │      │[15][16][17][18]  │
│                  │      │[Details panel]   │
└──────────────────┘      └──────────────────┘
```

## Tap/Click Target Sizes

```
┌─────────────────────────────────────────────────────────────────┐
│                   TAP TARGET COMPARISON                          │
└─────────────────────────────────────────────────────────────────┘

watchOS (44pt)             iOS (44pt)
┌───────────────────────┐  ┌───────────────────────┐
│                       │  │                       │
│       ┌─────────┐     │  │       ┌─────────┐     │
│       │  Tap    │     │  │       │  Tap    │     │
│       └─────────┘     │  │       └─────────┘     │
│                       │  │                       │
└───────────────────────┘  └───────────────────────┘

iPadOS (40pt)              macOS (28pt)
┌───────────────────────┐  ┌───────────────────────┐
│                       │  │                       │
│      ┌────────┐       │  │     ┌──────┐         │
│      │  Tap   │       │  │     │Click │         │
│      └────────┘       │  │     └──────┘         │
│                       │  │                       │
└───────────────────────┘  └───────────────────────┘
```

## Capability Decision Tree

```
┌─────────────────────────────────────────────────────────────────┐
│              CAPABILITY DECISION FLOWCHART                       │
└─────────────────────────────────────────────────────────────────┘

Need Multi-Pane Layout?
        │
        ├─ Yes ──→ Platform >= iPadOS? ──→ Yes ──→ Use Split View
        │                │
        │                └─ No ──→ Use Alternative (Stack)
        │
        └─ No ──→ Continue

Need Hover Effects?
        │
        ├─ Yes ──→ Platform >= iPadOS? ──→ Yes ──→ Add Hover
        │                │
        │                └─ No ──→ Skip (Touch-only)
        │
        └─ No ──→ Continue

Need Keyboard Shortcuts?
        │
        ├─ Yes ──→ Platform >= iPadOS? ──→ Yes ──→ Add Shortcuts
        │                │
        │                └─ No ──→ Skip (Touch-only)
        │
        └─ No ──→ Continue

Need Menu Bar Integration?
        │
        ├─ Yes ──→ Platform == macOS? ──→ Yes ──→ Use Menu Bar
        │               │
        │               └─ No ──→ Use Alternative (Toolbar)
        │
        └─ No ──→ Done
```

## Component Adaptation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│             ADAPTIVE COMPONENT FLOW                              │
└─────────────────────────────────────────────────────────────────┘

        AdaptiveCard { content }
                │
                ├─ Detect Platform
                │
                ├─ watchOS ──→ 8pt radius, thick material
                │
                ├─ iOS ────→ 12pt radius, regular material
                │
                ├─ iPadOS ──→ 16pt radius, regular material
                │
                └─ macOS ───→ 12pt radius, thin material


        AdaptiveGrid { items }
                │
                ├─ Check Density
                │
                ├─ Minimal ──→ 1 column (watchOS)
                │
                ├─ Standard ──→ 2 columns (iOS)
                │
                ├─ Comfortable ──→ 3 columns (iPadOS)
                │
                └─ Dense ────→ 4 columns (macOS)
```

## Anti-Pattern Detection

```
┌─────────────────────────────────────────────────────────────────┐
│                  ANTI-PATTERN CHECKS                             │
└─────────────────────────────────────────────────────────────────┘

Check: iPadOS as macOS Clone
        │
        ├─ Has Menu Bar? ──→ ❌ FAIL
        ├─ Has Window Chrome? ──→ ❌ FAIL
        └─ Touch-first? ──→ ✅ PASS

Check: iOS Inheriting iPadOS
        │
        ├─ Has Multi-Pane? ──→ ❌ FAIL
        ├─ Has Sidebar? ──→ ❌ FAIL
        └─ Single-focus? ──→ ✅ PASS

Check: Hover-Required on Touch
        │
        ├─ Touch Device? ──→ Yes
        │       │
        │       └─ Requires Hover? ──→ ❌ FAIL
        │
        └─ Touch Alternative? ──→ ✅ PASS

Check: watchOS Navigation Depth
        │
        └─ Depth > 2? ──→ ❌ FAIL
        └─ Depth ≤ 2? ──→ ✅ PASS
```

## Platform Validation Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                 VALIDATION PIPELINE                              │
└─────────────────────────────────────────────────────────────────┘

App Launch
    │
    ├─ Detect Platform ──→ [Platform.current]
    │
    ├─ Load Capabilities ──→ [CapabilityDomain.*]
    │
    ├─ Run Validation ──→ [PlatformValidation.validate()]
    │         │
    │         ├─ Check Anti-Patterns
    │         ├─ Verify Capability Coherence
    │         └─ Validate Guidelines
    │
    ├─ Errors Found? ──→ Yes ──→ Log Errors (Debug)
    │         │
    │         └─ No ──→ Continue
    │
    └─ App Ready ✅
```

## Usage Pattern

```
┌─────────────────────────────────────────────────────────────────┐
│                  TYPICAL USAGE FLOW                              │
└─────────────────────────────────────────────────────────────────┘

1. Import Framework
   ↓
   import SharedCore

2. Check Capability
   ↓
   if CapabilityDomain.Layout.supportsMultiPane { }

3. Use Adaptive Component
   ↓
   AdaptiveCard { content }

4. Apply Platform Modifier
   ↓
   .platformPadding()
   .platformHoverEffect()

5. Test Validation
   ↓
   #if DEBUG
   PlatformDebugView()
   #endif
```

---

## Quick Reference Cards

### watchOS Card
```
┌──────────────────────┐
│      watchOS         │
├──────────────────────┤
│ Tier: 0              │
│ Nav: 2 levels        │
│ Items: 1-2           │
│ Target: 44pt         │
│ Input: Touch+Crown   │
│ Style: Glanceable    │
└──────────────────────┘
```

### iOS Card
```
┌──────────────────────┐
│        iOS           │
├──────────────────────┤
│ Tier: 1              │
│ Nav: 4 levels        │
│ Items: 3-5           │
│ Target: 44pt         │
│ Input: Touch+Gesture │
│ Style: Immersive     │
└──────────────────────┘
```

### iPadOS Card
```
┌──────────────────────┐
│      iPadOS          │
├──────────────────────┤
│ Tier: 2              │
│ Nav: 6 levels        │
│ Items: 5-8           │
│ Target: 40pt         │
│ Input: Multi-modal   │
│ Style: Flexible      │
└──────────────────────┘
```

### macOS Card
```
┌──────────────────────┐
│       macOS          │
├──────────────────────┤
│ Tier: 3              │
│ Nav: 8 levels        │
│ Items: 10+           │
│ Target: 28pt         │
│ Input: Pointer+Kbd   │
│ Style: Maximum Power │
└──────────────────────┘
```

---

**This visual guide provides a high-level overview of the Platform Unification Framework architecture and relationships.**
