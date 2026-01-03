# Interface Preferences Quick Reference

## For Developers: How to Use

### 1. Reading Preferences in Views

```swift
struct MyView: View {
    @Environment(\.interfacePreferences) private var prefs
    
    var body: some View {
        VStack(spacing: prefs.spacing.md) {
            Text("Hello")
        }
    }
}
```

### 2. Apply Padding

```swift
// Card padding
.prefsCardPadding()

// Custom spacing
.prefsPadding(.horizontal, .lg)
.prefsPadding(.all, .md)

// List row insets
.prefsListRowInsets()
```

### 3. Apply Materials

```swift
// Card background
.prefsCardMaterial()

// HUD/overlay
.prefsHUDMaterial()

// Popup
.prefsPopupMaterial()

// With custom corner radius
.prefsCardMaterial(cornerRadius: 20)
```

### 4. Apply Borders

```swift
.prefsBorder()
.prefsBorder(cornerRadius: 16)
.prefsBorder(color: .blue)
```

### 5. Apply Animations

```swift
// Automatically nil if Reduce Motion is on
.prefsAnimation(.standard)
.prefsAnimation(.quick)
.prefsAnimation(.deliberate)
.prefsAnimation(.spring)
```

### 6. Apply Corner Radius

```swift
.prefsCornerRadius(.card)
.prefsCornerRadius(.button)
.prefsCornerRadius(.field)
```

### 7. Haptic Feedback (iOS)

```swift
@State private var counter = 0

var body: some View {
    Button("Tap") { counter += 1 }
        .prefsHapticFeedback(.light, trigger: counter)
}
```

### 8. Debug Preferences (Dev Only)

```swift
// Add debug overlay
.debugInterfacePreferences()
```

---

## Spacing Tokens

| Token | Standard | Compact | Large Tap |
|-------|----------|---------|-----------|
| xxs   | 4        | 2       | 6         |
| xs    | 8        | 4       | 12        |
| sm    | 12       | 8       | 16        |
| md    | 16       | 12      | 20        |
| lg    | 24       | 16      | 28        |
| xl    | 32       | 24      | 36        |
| xxl   | 40       | 32      | 44        |
| xxxl  | 56       | 40      | 60        |

---

## Material Behavior

| Setting             | Card Material | HUD Material | Effect |
|---------------------|---------------|--------------|--------|
| Default             | .regularMaterial | .ultraThinMaterial | Translucent |
| Reduce Transparency | Solid Color | Solid Color | Opaque |
| Increase Contrast   | .regularMaterial | .ultraThinMaterial | Stronger borders |

---

## Animation Behavior

| Setting       | Animation Result |
|---------------|------------------|
| Reduce Motion ON | All animations = nil |
| Show Animations OFF | Optional animations = nil (reduce motion still wins) |
| Both ON       | All animations enabled |

---

## Settings Keys (Persisted)

```swift
// AppSettingsModel
@AppStorage("roots.settings.reduceMotion")
@AppStorage("roots.settings.increaseContrast")
@AppStorage("roots.settings.reduceTransparency")
@AppStorage("roots.settings.glassIntensity")
@AppStorage("roots.settings.showAnimations")
@AppStorage("roots.settings.enableHaptics")
@AppStorage("roots.settings.showTooltips")
@AppStorage("roots.settings.compactMode")
@AppStorage("roots.settings.largeTapTargets")

// AppPreferences (legacy, also supported)
@AppStorage("preferences.reduceMotion")
@AppStorage("preferences.highContrast")
@AppStorage("preferences.reduceTransparency")
@AppStorage("preferences.glassIntensity")
@AppStorage("preferences.enableHaptics")
```

---

## Migration Patterns

### Before:
```swift
VStack(spacing: 16) {
    Text("Hello")
}
.padding(24)
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
.animation(.easeInOut, value: someValue)
```

### After:
```swift
VStack(spacing: prefs.spacing.md) {
    Text("Hello")
}
.prefsCardPadding()
.prefsCardMaterial()
.prefsAnimation(.standard)
```

---

## Common Gotchas

1. **Don't forget environment variable:**
   ```swift
   @Environment(\.interfacePreferences) private var prefs
   ```

2. **Animations must use prefsAnimation():**
   - Using `.animation()` directly won't respect Reduce Motion

3. **Materials need prefs modifiers:**
   - Using `.background(.regularMaterial)` won't respect Reduce Transparency

4. **Inject at root:**
   - Ensure `.interfacePreferences()` is called at ContentView/IOSAppShell/IOSRootView

---

## Testing Checklist

- [ ] Toggle Reduce Motion → animations stop
- [ ] Toggle Increase Contrast → borders/separators stronger
- [ ] Toggle Reduce Transparency → materials become solid
- [ ] Adjust Material Intensity → glass opacity changes
- [ ] Toggle Compact Mode → spacing decreases
- [ ] Toggle Large Tap Targets (iOS) → controls larger
- [ ] Toggle Show Animations → optional animations stop
- [ ] Toggle Haptics (iOS) → feedback stops
- [ ] Relaunch app → settings persist

---

## Files to Know

- `SharedCore/DesignSystem/Interface/InterfacePreferences.swift` — Runtime contract
- `SharedCore/DesignSystem/Interface/InterfaceViewModifiers.swift` — View modifiers
- `SharedCore/DesignSystem/Interface/InterfacePreferencesEnvironment.swift` — Environment key
- `iOS/Scenes/Settings/Categories/IOSInterfaceSettingsView.swift` — iOS settings UI
- `macOS/Views/InterfaceSettingsView.swift` — macOS settings UI

---

## Support

Questions? Check `INTERFACE_PREFERENCES_SYSTEM_COMPLETE.md` for full documentation.
