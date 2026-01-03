# Global Layout Consistency - Quick Reference

## 🎯 One-Minute Summary

**What:** Canonical top spacing system ensuring every page starts content at the same Y-position.

**How:** Environment-driven `AppLayout` contract with platform-specific defaults.

**Why:** Impossible to create misaligned pages. Spacing is automatic.

---

## 📏 Canonical Spacing Values

| Platform | Overlay Top | Header Height | Bottom Spacing | **Total** |
|----------|-------------|---------------|----------------|-----------|
| macOS    | 16pt        | 56pt          | 12pt           | **84pt**  |
| iOS      | 10pt        | 52pt          | 12pt           | **74pt**  |

---

## 🔑 Key Types

### `AppLayout` (Environment Value)

```swift
@Environment(\.appLayout) var layout

// Access canonical values
layout.overlayTopInset       // Top padding for floating buttons
layout.overlayTrailingInset  // Trailing padding for floating buttons
layout.headerHeight          // Height of page title bar
layout.headerBottomSpacing   // Space below title before content
layout.topContentInset       // 👈 TOTAL: Where content should begin
```

---

## ✅ Correct Usage Patterns

### Pattern 1: Default (Most Common)
**For pages wrapped in `AppPageScaffold` or `IOSAppShell`:**

```swift
struct MyPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Your content - no padding needed!
            }
            .padding(.horizontal, 20)
            // ✅ NO .padding(.top) needed - inherited automatically
        }
    }
}
```

### Pattern 2: Custom Layout with Manual Spacing

```swift
struct CustomLayout: View {
    @Environment(\.appLayout) var layout
    
    var body: some View {
        VStack(spacing: 0) {
            // Your custom layout
        }
        .padding(.top, layout.topContentInset)  // ✅ Use canonical value
    }
}
```

### Pattern 3: Using contentSafeInsetsForOverlay()

```swift
struct WrappedContent: View {
    var body: some View {
        myContent
            .contentSafeInsetsForOverlay()  // ✅ Applies canonical spacing
    }
}
```

---

## ❌ Incorrect Usage (Avoid)

### ❌ Don't hardcode magic numbers
```swift
.padding(.top, 12)  // ❌ Where did 12 come from?
.padding(.top, 24)  // ❌ Inconsistent
```

### ❌ Don't duplicate constants
```swift
private let topSpacing: CGFloat = 16  // ❌ Now you have two sources of truth
```

### ❌ Don't calculate manually
```swift
let spacing = headerHeight + someInset + 10  // ❌ Let the system do this
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────┐
│  AppLayout (Environment)            │
│  ├─ overlayTopInset: 16/10          │
│  ├─ headerHeight: 56/52             │
│  ├─ headerBottomSpacing: 12         │
│  └─ topContentInset: 84/74 ← TOTAL │
└─────────────────────────────────────┘
                ↓
    Automatically injected into:
                ↓
┌─────────────────────────────────────┐
│  Root Scaffolds                     │
│  ├─ AppPageScaffold (macOS)         │
│  └─ IOSAppShell (iOS)               │
└─────────────────────────────────────┘
                ↓
    Content receives spacing via:
                ↓
┌─────────────────────────────────────┐
│  contentSafeInsetsForOverlay()      │
│  Uses appLayout.topContentInset     │
└─────────────────────────────────────┘
```

---

## 🐛 Debug Tools

### Visual Debug Overlay

**Enable in Xcode console:**
```lldb
po UserDefaults.standard.set(true, forKey: "debug.showLayoutGuide")
```

**Disable:**
```lldb
po UserDefaults.standard.set(false, forKey: "debug.showLayoutGuide")
```

**Add to your view:**
```swift
#if DEBUG
.debugLayoutAlignment()  // Shows red line at content start position
#endif
```

### Manual Verification

```swift
struct TestView: View {
    @Environment(\.appLayout) var layout
    
    var body: some View {
        Text("Top content inset: \(layout.topContentInset)")
            .onAppear {
                print("📏 Platform spacing: \(layout.topContentInset)pt")
            }
    }
}
```

---

## 📦 Core Files

| File | Purpose |
|------|---------|
| `SharedCore/Utilities/LayoutMetrics.swift` | Defines `AppLayout` struct |
| `SharedCore/Views/OverlayInsets.swift` | Applies spacing via modifier |
| `SharedCore/Views/AppPageScaffold.swift` | macOS root scaffold |
| `Platforms/iOS/Root/IOSAppShell.swift` | iOS root shell |

---

## 🚀 Adding a New Page

### Step 1: Create Your View
```swift
struct NewFeaturePage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("My Feature")
                // ... more content
            }
            .padding(.horizontal, 20)
            // ✅ Do NOT add .padding(.top) here
        }
    }
}
```

### Step 2: Wrap in Scaffold (if needed)

**macOS:**
```swift
AppPageScaffold(
    title: "My Feature",
    quickActions: [],
    onQuickAction: { _ in },
    onSettings: { }
) {
    NewFeaturePage()
}
```

**iOS:**
```swift
IOSAppShell(title: "My Feature") {
    NewFeaturePage()
}
```

### Step 3: Done!
Spacing is automatic. No manual calculations needed.

---

## 🎨 Platform Differences

### Why Different Values?

| Platform | Context | Reasoning |
|----------|---------|-----------|
| macOS | Desktop, more screen space | Larger header (56pt), more top padding (16pt) |
| iOS | Mobile, touch targets | Smaller header (52pt), less top padding (10pt) |

Both maintain **12pt** bottom spacing for visual rhythm.

---

## ✅ Checklist for Code Reviews

When reviewing new pages:

- [ ] No hardcoded `.padding(.top, X)` on first content element
- [ ] Either wrapped in scaffold OR uses `@Environment(\.appLayout)`
- [ ] If custom spacing needed, uses `layout.topContentInset`
- [ ] No duplicate spacing constants defined in view
- [ ] Spacing behavior consistent across device sizes

---

## 🔧 Troubleshooting

### "Content is too close to the header"
- ✅ Check if view is wrapped in scaffold
- ✅ Verify `.contentSafeInsetsForOverlay()` is applied
- ✅ Ensure no negative padding offsetting canonical spacing

### "Content starts too low"
- ❌ Check for duplicate `.padding(.top)` calls
- ❌ Verify you're not adding custom padding on top of scaffold padding

### "Spacing differs between pages"
- 🐛 Use debug overlay to visualize alignment
- 🐛 Check for conditional padding logic
- 🐛 Verify both pages use same scaffold/shell

---

## 📚 Related Documentation

- Full implementation details: `GLOBAL_LAYOUT_CONSISTENCY_IMPLEMENTATION.md`
- HIG compliance: `DASHBOARD_HIG_IMPLEMENTATION_COMPLETE.md`
- Interface preferences: `INTERFACE_PREFERENCES_QUICK_REFERENCE.md`

---

## 💡 Remember

**The spacing is now automatic and impossible to get wrong.**

New pages inherit canonical spacing through the environment. No documentation needed. The compiler enforces it.
