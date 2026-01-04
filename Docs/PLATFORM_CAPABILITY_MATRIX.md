# Platform Capability Matrix

**Version:** 1.0  
**Last Updated:** 2026-01-03  
**Status:** Binding Contract for UI/Feature Development

## Purpose

This document defines which UI patterns, interaction models, and feature classes are allowed, discouraged, or forbidden on each platform. All future UI and feature work must reference and comply with this matrix.

## Legend

| Symbol | Meaning | Description |
|--------|---------|-------------|
| ✅ | **Allowed** | Full support, encouraged for this platform |
| ⚠️ | **Allowed with Constraints** | Permitted but with specific limitations documented below |
| 🚫 | **Discouraged** | Technically possible but against platform guidelines |
| ❌ | **Forbidden** | Must not be implemented on this platform |

---

## 1. Navigation Patterns

| Pattern | watchOS | iOS | iPadOS | macOS | Notes |
|---------|---------|-----|--------|-------|-------|
| **Tab Bar Navigation** | ✅ | ✅ | ⚠️ | ❌ | iPadOS: Only for iPhone-sized classes. macOS: Use sidebar instead |
| **Sidebar Navigation** | ❌ | 🚫 | ✅ | ✅ | iOS: Avoid except for split view controllers. watchOS: Screen too small |
| **Stack-based Navigation** | ✅ | ✅ | ✅ | ⚠️ | macOS: Prefer windows/panels for deep navigation |
| **Modal Sheets** | ✅ | ✅ | ✅ | ✅ | Universal pattern across all platforms |
| **Popovers** | ❌ | ✅ | ✅ | ✅ | watchOS: No pointer, cannot anchor popovers |
| **Split View (2-pane)** | ❌ | ⚠️ | ✅ | ✅ | iOS: Only on larger devices (Plus/Max). watchOS: Insufficient space |
| **Split View (3-pane)** | ❌ | ❌ | ✅ | ✅ | Requires significant screen real estate |
| **Multiple Windows** | ❌ | ⚠️ | ✅ | ✅ | iOS: Limited multi-window on compatible devices. watchOS: Single-context only |
| **Page-based Navigation** | ✅ | ⚠️ | 🚫 | 🚫 | watchOS: Native pattern. iOS+: Use for onboarding only |
| **Drill-down Lists** | ✅ | ✅ | ✅ | ✅ | Universal hierarchical navigation |

**Platform-Specific Rules:**

- **watchOS:** Navigation must be shallow (max 2-3 levels deep). Prefer cards and pagination over deep stacks.
- **iOS:** Primary navigation via tab bar. Stack-based drill-down for hierarchy. Avoid persistent sidebars.
- **iPadOS:** Sidebar + split view is preferred. Tab bar only for compact size classes.
- **macOS:** Sidebar is primary navigation. Tabs for document/view switching within windows.

---

## 2. Layout Density & UI Complexity

| Capability | watchOS | iOS | iPadOS | macOS | Notes |
|------------|---------|-----|--------|-------|-------|
| **Single-pane Views** | ✅ | ✅ | ✅ | ⚠️ | macOS: Use for focused tasks only, prefer multi-pane |
| **Dual-pane Layouts** | ❌ | ⚠️ | ✅ | ✅ | iOS: Only landscape on larger devices |
| **Multi-pane Layouts (3+)** | ❌ | ❌ | ✅ | ✅ | Requires significant screen space |
| **Floating Panels** | ❌ | 🚫 | ⚠️ | ✅ | iOS: System alerts only. iPadOS: Sheets/popovers instead. macOS: Native |
| **Resizable Windows** | ❌ | ❌ | ⚠️ | ✅ | iPadOS: Slide Over/Split View only. macOS: Expected |
| **Fixed-width Sidebars** | ❌ | ❌ | ✅ | ✅ | Requires sufficient horizontal space |
| **Collapsible Sidebars** | ❌ | ❌ | ✅ | ✅ | iPadOS/macOS responsive pattern |
| **Toolbars** | ❌ | ✅ | ✅ | ✅ | watchOS: Use bottom buttons instead |
| **Dense Information Display** | ❌ | 🚫 | ⚠️ | ✅ | watchOS: Maximum 2-3 items. iOS: Optimized scrolling. iPadOS: Allowed. macOS: Expected |
| **Grid Layouts (dense)** | ❌ | ⚠️ | ✅ | ✅ | watchOS: List only. iOS: 2-3 columns max |

**Platform-Specific Rules:**

- **watchOS:** Extreme simplicity required. Single focus per screen. Large touch targets (44pt minimum).
- **iOS:** Optimized for single-handed use. Comfortable information density for scrolling.
- **iPadOS:** Increased density allowed. Multi-column layouts. Split view utilization.
- **macOS:** Maximum density. Multiple simultaneous contexts. Efficient use of screen space.

---

## 3. Persistence & State Management

| Capability | watchOS | iOS | iPadOS | macOS | Notes |
|------------|---------|-----|--------|-------|-------|
| **Scene State Restoration** | ✅ | ✅ | ✅ | ✅ | Required for all platforms |
| **Pinned UI Elements** | ❌ | ⚠️ | ✅ | ✅ | watchOS: Everything is temporary. iOS: Tab bar only. iPad/Mac: Sidebars |
| **Persistent Sidebars** | ❌ | ❌ | ✅ | ✅ | Always visible across sessions |
| **Background Refresh** | ✅ | ✅ | ✅ | ✅ | All platforms support with varying constraints |
| **Long-running Operations** | ❌ | ⚠️ | ⚠️ | ✅ | watchOS: 30s max. iOS/iPad: Background task limits. macOS: Full support |
| **Auto-save** | ✅ | ✅ | ✅ | ✅ | Universal expectation |
| **Undo/Redo Stack** | ❌ | ⚠️ | ✅ | ✅ | watchOS: Immediate confirmation only. iOS: Shake to undo. iPad/Mac: Full support |
| **Window State Persistence** | ❌ | ⚠️ | ✅ | ✅ | iOS: Scene-based. iPad/Mac: Full window restoration |
| **Workspace Persistence** | ❌ | ❌ | ⚠️ | ✅ | iPadOS: Limited to window arrangement. macOS: Full workspace |

**Platform-Specific Rules:**

- **watchOS:** Transient by design. State saved but UI resets between launches. No persistent chrome.
- **iOS:** Scene-based persistence. Tab selection saved. No persistent auxiliary UI.
- **iPadOS:** Full split view + sidebar state. Window arrangement per space.
- **macOS:** Complete workspace persistence. Window positions, sizes, states all saved.

---

## 4. Input Methods & Interaction

| Input Type | watchOS | iOS | iPadOS | macOS | Notes |
|------------|---------|-----|--------|-------|-------|
| **Touch (Primary)** | ✅ | ✅ | ✅ | 🚫 | macOS: Touch Bar only, not primary interaction |
| **Digital Crown** | ✅ | ❌ | ❌ | ❌ | watchOS exclusive |
| **Keyboard (Software)** | ⚠️ | ✅ | ✅ | ❌ | watchOS: Dictation/Scribble preferred. macOS: Hardware only |
| **Keyboard (Hardware)** | ❌ | ⚠️ | ✅ | ✅ | iOS: Optional accessory. iPad/Mac: Expected availability |
| **Mouse/Trackpad** | ❌ | ❌ | ✅ | ✅ | iPadOS: Optional. macOS: Primary |
| **Pointer Precision** | ❌ | ❌ | ⚠️ | ✅ | iPadOS: Adaptive cursor. macOS: Pixel-perfect |
| **Hover States** | ❌ | ❌ | ⚠️ | ✅ | iPadOS: With pointer only. macOS: Always available |
| **Context Menus (Long Press)** | ✅ | ✅ | ✅ | ✅ | Universal pattern |
| **Context Menus (Right Click)** | ❌ | ❌ | ✅ | ✅ | Requires pointer |
| **Drag and Drop** | ❌ | ⚠️ | ✅ | ✅ | watchOS: No support. iOS: Limited. iPad/Mac: Full support |
| **Multi-touch Gestures** | ❌ | ✅ | ✅ | ⚠️ | watchOS: Single finger only. macOS: Trackpad gestures |
| **Force Touch/3D Touch** | ⚠️ | 🚫 | 🚫 | ⚠️ | Deprecated on iOS. Optional on Watch/Mac |
| **Haptic Feedback** | ✅ | ✅ | ⚠️ | ⚠️ | iPad: Limited. Mac: Trackpad only |

**Platform-Specific Rules:**

- **watchOS:** Crown for scrolling is preferred. Large touch targets. Haptic feedback essential.
- **iOS:** Touch-first. Gestures for navigation. Keyboard shortcuts when hardware keyboard present.
- **iPadOS:** Touch + Pencil + Keyboard + Pointer. Adaptive to available inputs.
- **macOS:** Keyboard + Pointer primary. Touch secondary (Touch Bar). Precision interactions.

---

## 5. Keyboard Shortcuts & Accessibility

| Capability | watchOS | iOS | iPadOS | macOS | Notes |
|------------|---------|-----|--------|-------|-------|
| **Global Shortcuts** | ❌ | ❌ | ⚠️ | ✅ | iPadOS: Limited set. macOS: Expected |
| **Command Palette** | ❌ | ❌ | ⚠️ | ✅ | iPadOS: Cmd+Shift+? for discoverability. macOS: Encouraged |
| **Menu Bar Shortcuts** | ❌ | ❌ | ⚠️ | ✅ | iPadOS: Keyboard menu. macOS: Standard |
| **Toolbar Shortcuts** | ❌ | ❌ | ✅ | ✅ | Requires hardware keyboard |
| **Focus Navigation (Tab)** | ❌ | ⚠️ | ✅ | ✅ | iOS: Accessibility only. iPad/Mac: Expected |
| **VoiceOver Support** | ✅ | ✅ | ✅ | ✅ | Required for all platforms |
| **Dynamic Type** | ✅ | ✅ | ✅ | ✅ | Required for all platforms |
| **Reduce Motion** | ✅ | ✅ | ✅ | ✅ | Required for all platforms |
| **Keyboard-only Navigation** | ❌ | ⚠️ | ✅ | ✅ | iOS: Accessibility mode. iPad/Mac: Full support |

**Platform-Specific Rules:**

- **watchOS:** Accessibility via VoiceOver, large type, haptics. No keyboard.
- **iOS:** VoiceOver, Dynamic Type, Reduce Motion required. Hardware keyboard shortcuts optional.
- **iPadOS:** Full keyboard navigation expected when keyboard connected. Shortcuts discoverable.
- **macOS:** Complete keyboard accessibility required. Menu shortcuts standard. Cmd+? for help.

---

## 6. Content Editing vs Consumption

| Pattern | watchOS | iOS | iPadOS | macOS | Notes |
|---------|---------|-----|--------|-------|-------|
| **Read-only Views** | ✅ | ✅ | ✅ | ✅ | Universal |
| **Inline Text Editing** | ⚠️ | ✅ | ✅ | ✅ | watchOS: Dictation/Scribble only |
| **Rich Text Editing** | ❌ | ⚠️ | ✅ | ✅ | watchOS: Not supported. iOS: Basic only |
| **Multi-document Editing** | ❌ | ❌ | ⚠️ | ✅ | iPadOS: Split view only. macOS: Multiple windows |
| **Live Collaboration** | ❌ | ⚠️ | ✅ | ✅ | watchOS: View only. iOS: Limited. iPad/Mac: Full |
| **Extended Editing Sessions** | ❌ | ⚠️ | ✅ | ✅ | watchOS: Quick edits only. iOS: Short sessions. iPad/Mac: Sustained work |
| **Precision Selection** | ❌ | ⚠️ | ✅ | ✅ | watchOS: No precision. iOS: Touch-based. iPad/Mac: Pointer precision |
| **Copy/Paste** | ⚠️ | ✅ | ✅ | ✅ | watchOS: Limited support |
| **Find and Replace** | ❌ | ⚠️ | ✅ | ✅ | iOS: Find only. iPad/Mac: Full support |

**Platform-Specific Rules:**

- **watchOS:** Consumption-first. Minimal editing (dictation, scribble, quick replies).
- **iOS:** Balanced for quick edits and consumption. Extended editing acceptable but not optimal.
- **iPadOS:** Full editing capabilities. Designed for productivity workflows.
- **macOS:** Maximum editing power. Precision tools. Sustained productivity sessions.

---

## 7. Configuration & Settings Depth

| Pattern | watchOS | iOS | iPadOS | macOS | Notes |
|---------|---------|-----|--------|-------|-------|
| **App-level Settings** | ⚠️ | ✅ | ✅ | ✅ | watchOS: Minimal, defer to iPhone companion |
| **Per-document Settings** | ❌ | ⚠️ | ✅ | ✅ | watchOS: No complex documents. iOS: Limited |
| **Preference Panes** | ❌ | ⚠️ | ✅ | ✅ | iOS: System Settings integration. iPad/Mac: Full preferences |
| **Advanced/Developer Options** | ❌ | ⚠️ | ✅ | ✅ | watchOS: None. iOS: Hidden. iPad/Mac: Accessible |
| **Nested Settings (3+ levels)** | ❌ | 🚫 | ⚠️ | ✅ | Keep settings shallow except on macOS |
| **Search in Settings** | ❌ | ✅ | ✅ | ✅ | watchOS: Too minimal to require |
| **Presets/Profiles** | ❌ | ⚠️ | ✅ | ✅ | watchOS: Single config. iOS: Basic. iPad/Mac: Full profiles |
| **Import/Export Settings** | ❌ | ⚠️ | ✅ | ✅ | Increases with platform capability |

**Platform-Specific Rules:**

- **watchOS:** Minimal settings. Most configuration via companion iPhone app. Quick toggles only.
- **iOS:** Settings organized in System Settings. App settings shallow (2-3 levels max).
- **iPadOS:** More configuration options. Per-document and app-wide settings.
- **macOS:** Comprehensive preferences. Advanced options accessible. Import/export supported.

---

## 8. Background Execution & Processing

| Capability | watchOS | iOS | iPadOS | macOS | Notes |
|------------|---------|-----|--------|-------|-------|
| **Background Refresh** | ✅ | ✅ | ✅ | ✅ | All platforms with varying frequency |
| **Background App Refresh** | ⚠️ | ✅ | ✅ | ✅ | watchOS: Minimal budget |
| **Background Downloads** | ⚠️ | ✅ | ✅ | ✅ | watchOS: Small files only |
| **Long-running Tasks** | ❌ | ⚠️ | ⚠️ | ✅ | iOS/iPad: Background task API limits. macOS: Unlimited |
| **Background Audio** | ⚠️ | ✅ | ✅ | ✅ | watchOS: During workout only |
| **Background Location** | ⚠️ | ✅ | ✅ | ✅ | watchOS: Limited |
| **Push Notifications** | ✅ | ✅ | ✅ | ✅ | Universal |
| **Local Notifications** | ✅ | ✅ | ✅ | ✅ | Universal |
| **URLSession Background** | ⚠️ | ✅ | ✅ | ✅ | watchOS: Small payloads |
| **Continuous Processing** | ❌ | ❌ | ❌ | ✅ | macOS only (e.g., file watching, servers) |

**Platform-Specific Rules:**

- **watchOS:** Extremely limited background time. Quick refresh only. Rely on complications.
- **iOS:** Background execution restricted. Use URLSession background transfers. Limited CPU time.
- **iPadOS:** Same as iOS. No special background privileges despite larger form factor.
- **macOS:** Full background execution. Services can run continuously. Standard Unix process model.

---

## 9. Visual Density & Information Architecture

| Pattern | watchOS | iOS | iPadOS | macOS | Notes |
|---------|---------|-----|--------|-------|-------|
| **Cards per Screen** | 1-2 | 1-3 | 2-6 | 4-12+ | Scales with screen size |
| **List Item Density** | Low | Medium | Medium-High | High | Touch target vs information density |
| **Columns in Lists** | 1 | 1-2 | 2-4 | 2-8+ | Increases with resolution |
| **Sidebar + Content** | ❌ | ❌ | ✅ | ✅ | Requires horizontal space |
| **Inspector Panels** | ❌ | ⚠️ | ✅ | ✅ | iOS: Modal sheet. iPad/Mac: Persistent panel |
| **Status Bars/Breadcrumbs** | ❌ | ⚠️ | ✅ | ✅ | watchOS: Too small. iOS: Minimal |
| **Multiple Simultaneous Contexts** | ❌ | ❌ | ⚠️ | ✅ | iPadOS: Split view only. macOS: Multiple windows |

**Platform-Specific Rules:**

- **watchOS:** Single focus. One card/list at a time. Maximum 2-3 items visible without scrolling.
- **iOS:** Optimized for scrolling. Comfortable single-column layouts. Minimal chrome.
- **iPadOS:** Increased density. Multi-column layouts. Split view for multiple contexts.
- **macOS:** Maximum information density. Multiple windows. Complex layouts with many panels.

---

## 10. Platform-Specific Features

### watchOS Exclusive
| Feature | Status | Notes |
|---------|--------|-------|
| Complications | ✅ | Primary glanceable interface |
| Always-on Display | ✅ | Low-power mode with limited content |
| Workout Integration | ✅ | HealthKit integration required |
| Taptic Engine | ✅ | Haptic feedback essential for UX |
| Crown Scrolling | ✅ | Preferred over touch scrolling |

### iOS Exclusive
| Feature | Status | Notes |
|---------|--------|-------|
| Today Widgets | ✅ | Home screen and Today view |
| App Clips | ✅ | Lightweight app experiences |
| Siri Shortcuts | ✅ | Voice automation |
| Face ID / Touch ID | ✅ | Biometric authentication |
| Live Activities | ✅ | Dynamic Island + Lock Screen |

### iPadOS Enhancements
| Feature | Status | Notes |
|---------|--------|-------|
| Stage Manager | ✅ | Window management system |
| Pencil Integration | ✅ | Precision input for drawing/notes |
| Scribble | ✅ | Handwriting to text |
| External Display | ✅ | Extended desktop |
| Desktop-class Safari | ✅ | Full web capabilities |

### macOS Exclusive
| Feature | Status | Notes |
|---------|--------|-------|
| Menu Bar | ✅ | Primary command interface |
| Dock | ✅ | Application launcher |
| Finder Integration | ✅ | File system access |
| Services Menu | ✅ | Inter-app communication |
| AppleScript Support | ✅ | Automation |
| Full File System Access | ✅ | Unrestricted file operations |

---

## Implementation Rules

### Rule 1: Upward Capability Movement
- watchOS → iOS: Increased depth, editing, persistence
- iOS → iPadOS: Multi-pane layouts, precision input, keyboard
- iPadOS → macOS: Multiple windows, unlimited background, full file system

### Rule 2: No Downward Inheritance
- macOS patterns must not appear on iOS (e.g., menu bars, resizable windows)
- iOS patterns should not appear on watchOS (e.g., deep navigation stacks)
- Each platform respects its interaction paradigm

### Rule 3: Consistency Within Platform
- All features on a platform must follow the same capability matrix
- Exceptions require explicit documentation and approval
- No "desktop mode" on mobile platforms

### Rule 4: Accessibility Across All Platforms
- VoiceOver support: Required
- Dynamic Type: Required
- Keyboard navigation: Required where input method supports it
- Reduce Motion: Required
- High Contrast: Required

---

## Decision Tree for New Features

```
1. Which platforms should support this feature?
   └─> Consult capability matrix for each target platform

2. Does the feature require a capability marked ❌?
   └─> Feature cannot be implemented on that platform
   └─> Consider alternative approach or different platform

3. Does the feature require a capability marked 🚫?
   └─> Requires strong justification and approval
   └─> Must not violate platform paradigm

4. Does the feature require a capability marked ⚠️?
   └─> Review constraints documentation
   └─> Implement within documented limits

5. Feature uses only ✅ capabilities?
   └─> Proceed with implementation
   └─> Follow platform HIG guidelines
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-03 | Initial comprehensive matrix created |

---

## Related Documentation

- [PLATFORM_UNIFICATION_FRAMEWORK.md](./PLATFORM_UNIFICATION_FRAMEWORK.md)
- [MULTI_TARGET_ARCHITECTURE_GUIDE.md](./MULTI_TARGET_ARCHITECTURE_GUIDE.md)
- [PLATFORM_UNIFICATION_IMPLEMENTATION_GUIDE.md](./PLATFORM_UNIFICATION_IMPLEMENTATION_GUIDE.md)
- Apple Human Interface Guidelines (all platforms)

---

## Approval & Enforcement

This matrix is a **binding contract** for all UI and feature development. Any deviation requires:

1. Written justification
2. Architecture review
3. Documentation update
4. Explicit marking as exception

**Enforcement:** All pull requests introducing new UI patterns or features must reference this matrix and demonstrate compliance.

---

*This document defines the boundaries within which Itori operates on each Apple platform. It ensures platform-appropriate experiences while maintaining cross-platform data consistency and feature parity where appropriate.*
