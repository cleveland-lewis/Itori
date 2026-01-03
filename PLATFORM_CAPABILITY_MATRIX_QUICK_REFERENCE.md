# Platform Capability Matrix - Quick Reference

**⚡ Fast lookup for platform capabilities**  
**See [PLATFORM_CAPABILITY_MATRIX.md](./PLATFORM_CAPABILITY_MATRIX.md) for complete documentation**

## Quick Decision Guide

### "Can I use a sidebar?"
- ❌ watchOS
- 🚫 iOS (avoid except split view)
- ✅ iPadOS
- ✅ macOS

### "Can I use tabs?"
- ✅ watchOS
- ✅ iOS
- ⚠️ iPadOS (compact size only)
- ❌ macOS (use sidebar)

### "Can I have multiple windows?"
- ❌ watchOS
- ⚠️ iOS (limited)
- ✅ iPadOS
- ✅ macOS

### "Can I use keyboard shortcuts?"
- ❌ watchOS
- ⚠️ iOS (optional)
- ✅ iPadOS (when keyboard present)
- ✅ macOS (required)

### "Can I run long background tasks?"
- ❌ watchOS
- ⚠️ iOS (limited)
- ⚠️ iPadOS (limited)
- ✅ macOS

### "Can I have dense information layout?"
- ❌ watchOS (1-2 items)
- 🚫 iOS (optimized scrolling)
- ⚠️ iPadOS (medium-high)
- ✅ macOS (maximum density)

### "Can I do precision editing?"
- ❌ watchOS
- ⚠️ iOS (touch-based)
- ✅ iPadOS (with pointer)
- ✅ macOS

---

## Platform Patterns at a Glance

### watchOS: Glanceable & Quick
- ✅ Single-focus cards
- ✅ Crown scrolling
- ✅ Haptic feedback
- ✅ Complications
- ❌ Complex editing
- ❌ Deep navigation
- ❌ Persistent UI

### iOS: Touch-First & Portable
- ✅ Tab bar navigation
- ✅ Stack-based drill-down
- ✅ Modal sheets
- ✅ Swipe gestures
- ❌ Sidebars (use split view only)
- ❌ Dense layouts
- ⚠️ Keyboard shortcuts (optional)

### iPadOS: Productivity & Flexibility
- ✅ Sidebar + split view
- ✅ Multi-pane layouts
- ✅ Keyboard + Pointer + Touch
- ✅ Drag and drop
- ✅ Pencil integration
- ✅ Desktop-class browsing
- ⚠️ Tab bar (compact only)

### macOS: Power & Precision
- ✅ Menu bar
- ✅ Sidebar navigation
- ✅ Multiple windows
- ✅ Full keyboard support
- ✅ Pointer precision
- ✅ Maximum density
- ❌ Touch as primary input
- ❌ Tab bar navigation

---

## Navigation Pattern Reference

| Pattern | Watch | iOS | iPad | Mac |
|---------|-------|-----|------|-----|
| Tab Bar | ✅ | ✅ | ⚠️ | ❌ |
| Sidebar | ❌ | 🚫 | ✅ | ✅ |
| Stack Nav | ✅ | ✅ | ✅ | ⚠️ |
| Split View | ❌ | ⚠️ | ✅ | ✅ |
| Windows | ❌ | ⚠️ | ✅ | ✅ |

---

## Input Method Reference

| Input | Watch | iOS | iPad | Mac |
|-------|-------|-----|------|-----|
| Touch | ✅ | ✅ | ✅ | 🚫 |
| Crown | ✅ | ❌ | ❌ | ❌ |
| Keyboard | ❌ | ⚠️ | ✅ | ✅ |
| Pointer | ❌ | ❌ | ✅ | ✅ |
| Pencil | ❌ | ❌ | ✅ | ❌ |

---

## Complexity Allowance

| Metric | watchOS | iOS | iPadOS | macOS |
|--------|---------|-----|--------|-------|
| **Nav Depth** | 2-3 | 3-5 | 4-7 | Unlimited |
| **Simultaneous Panes** | 1 | 1 | 2-3 | 4+ |
| **Settings Depth** | 1-2 | 2-3 | 3-4 | Unlimited |
| **List Columns** | 1 | 1-2 | 2-4 | 2-8+ |
| **Background Time** | 30s | Minutes | Minutes | Unlimited |

---

## Common Violations to Avoid

### ❌ DON'T: iOS with macOS patterns
```swift
// ❌ Menu bar on iOS
.navigationBarItems(leading: Menu { ... })

// ❌ Resizable windows on iOS  
window.setFrame(newFrame)

// ❌ Persistent sidebar on iPhone
NavigationView {
    Sidebar() // Don't force on iPhone
    Content()
}
```

### ✅ DO: Platform-appropriate patterns
```swift
// ✅ iOS: Tab bar
TabView {
    DashboardView().tabItem { ... }
    CalendarView().tabItem { ... }
}

// ✅ macOS: Sidebar
NavigationView {
    Sidebar()
    Content()
}

// ✅ Adaptive: Use size classes
if horizontalSizeClass == .regular {
    // iPad: Sidebar
} else {
    // iPhone: Tab bar
}
```

---

## Feature Capability Checklist

Before implementing a feature, verify:

- [ ] ✅ Navigation pattern allowed on target platform?
- [ ] ✅ Input method available on target platform?
- [ ] ✅ Layout density appropriate for platform?
- [ ] ✅ Background execution within platform limits?
- [ ] ✅ Settings complexity matches platform?
- [ ] ✅ Editing capability aligned with platform?
- [ ] ✅ No forbidden patterns used?
- [ ] ✅ Accessibility requirements met?

---

## When in Doubt

1. **Check the full matrix:** [PLATFORM_CAPABILITY_MATRIX.md](./PLATFORM_CAPABILITY_MATRIX.md)
2. **Consult Apple HIG** for the target platform
3. **Ask:** "Does this pattern feel native to this platform?"
4. **Test** on actual devices, not just simulators
5. **Get approval** for any ⚠️ or 🚫 capabilities

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Allowed - Go ahead |
| ⚠️ | Allowed with constraints - Check docs |
| 🚫 | Discouraged - Strong reason required |
| ❌ | Forbidden - Do not implement |

---

*Quick reference only. See full matrix for detailed constraints and rationale.*
