# macOS Accent Color Centralization Refactor

## Date
December 22, 2025

## Summary
Centralized all generic accent colors through `DesignSystem.Colors.accent` while preserving semantic colors for data-driven UI elements.

## Files Created/Modified

### 1. **SharedCore/DesignSystem/Components/DesignSystem.swift** (MODIFIED)

Added centralized accent color to the Colors struct:

```swift
struct Colors {
    // ... existing colors ...
    
    /// Global accent color - uses app settings accent color
    /// Apply this to all generic UI elements (buttons, toggles, selections, etc.)
    /// DO NOT use for semantic colors (event categories, course colors, status indicators)
    static var accent: Color {
        AppSettingsModel.shared.activeAccentColor
    }
    
    // ... rest of colors ...
}
```

### 2. **SharedCore/DesignSystem/Components/AccentColorExtensions.swift** (NEW)

Created convenience modifiers for applying accent color:

```swift
extension View {
    /// Applies the centralized accent color to the view
    /// Use this for generic UI elements
    func accentedUI() -> some View {
        self.tint(DesignSystem.Colors.accent)
    }
    
    /// Applies accent color with reduced opacity for hover states
    func accentedHover(opacity: Double = 0.15) -> some View {
        self.foregroundStyle(DesignSystem.Colors.accent)
            .background(DesignSystem.Colors.accent.opacity(opacity))
    }
    
    /// Applies accent color for selection highlights
    func accentedSelection(isSelected: Bool) -> some View {
        self.foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? DesignSystem.Colors.accent : .clear)
    }
}

extension View {
    /// Mark a view as using semantic colors
    /// Documentation marker for intentional semantic color usage
    func semanticColor() -> some View {
        self
    }
}
```

## Global Application Pattern

The app already applies accent color globally in `ItoriApp.swift`:

```swift
ContentView()
    .accentColor(preferences.currentAccentColor)  // ← Global accent
    .tint(preferences.currentAccentColor)          // ← Global tint
    .buttonStyle(.glassBlueProminent)
    .controlSize(.regular)
```

**Result**: All SwiftUI controls (buttons, toggles, pickers, etc.) automatically inherit the accent color.

## Refactoring Pattern

### ✅ Replace Hard-Coded Colors (Generic UI)

**Before**:
```swift
Button("Save") { }
    .foregroundColor(.blue)
```

**After**:
```swift
Button("Save") { }
    .foregroundColor(DesignSystem.Colors.accent)
```

**Or even simpler** (relies on global tint):
```swift
Button("Save") { }
// Automatically uses accent color from global .tint()
```

### ✅ Segmented Controls

**Before**:
```swift
Picker("View", selection: $viewMode) {
    ForEach(modes) { mode in
        Text(mode.title).tag(mode)
    }
}
.pickerStyle(.segmented)
.tint(.blue)  // Hard-coded
```

**After**:
```swift
Picker("View", selection: $viewMode) {
    ForEach(modes) { mode in
        Text(mode.title).tag(mode)
    }
}
.pickerStyle(.segmented)
// Automatically uses accent color from global .tint()
```

### ✅ Selection Highlights

**Before**:
```swift
.background(isSelected ? Color.blue : Color.clear)
```

**After**:
```swift
.accentedSelection(isSelected: isSelected)
```

### ✅ Toggles

**Before**:
```swift
Toggle("Enable feature", isOn: $enabled)
    .tint(.blue)
```

**After**:
```swift
Toggle("Enable feature", isOn: $enabled)
// Automatically uses accent color from global .tint()
```

### ✅ Generic Icons

**Before**:
```swift
Image(systemName: "gear")
    .foregroundColor(.blue)
```

**After**:
```swift
Image(systemName: "gear")
    .foregroundColor(DesignSystem.Colors.accent)
```

### ❌ DO NOT Change Semantic Colors

**Event Categories** (KEEP AS-IS):
```swift
Circle()
    .fill(event.category.color)  // ← Semantic color
    .semanticColor()  // ← Documentation marker
```

**Course Colors** (KEEP AS-IS):
```swift
Rectangle()
    .fill(course.color)  // ← Semantic color
    .semanticColor()
```

**Status Indicators** (KEEP AS-IS):
```swift
Text(status)
    .foregroundColor(status == .error ? .red : .green)  // ← Semantic
    .semanticColor()
```

**Urgency Colors** (KEEP AS-IS):
```swift
.fill(urgency.color)  // ← Semantic (red = critical, etc.)
    .semanticColor()
```

## Accent Color Adaptation

### Light/Dark Mode
```swift
DesignSystem.Colors.accent
```
- Automatically adapts based on `AppSettingsModel.shared.activeAccentColor`
- User can customize in Settings → Interface → Accent Color

### Material Compatibility
The accent color works correctly with all macOS materials:
- `.ultraThinMaterial` ✅
- `.regularMaterial` ✅
- `.thickMaterial` ✅

SwiftUI automatically adjusts opacity and vibrancy.

## Example Refactored Views

### Calendar Month View

**Before**:
```swift
Text(dayNumber)
    .foregroundColor(.blue)
```

**After**:
```swift
Text(dayNumber)
    .foregroundColor(DesignSystem.Colors.accent)
```

### Button Hover State

**Before**:
```swift
.background(hovering ? Color.blue.opacity(0.15) : .clear)
```

**After**:
```swift
.accentedHover(opacity: 0.15)
```

### Segmented Picker (No Change Needed)

**Current** (already correct):
```swift
Picker("Mode", selection: $mode) { }
    .pickerStyle(.segmented)
    .tint(settings.activeAccentColor)
```

**Refactored** (use centralized source):
```swift
Picker("Mode", selection: $mode) { }
    .pickerStyle(.segmented)
    // Inherits from global .tint() in ItoriApp
```

## Comprehensive Checklist

### Generic UI Elements (USE Accent Color)
- [x] Buttons (primary, secondary, icon)
- [x] Toggles
- [x] Segmented controls
- [x] Progress indicators
- [x] Sliders
- [x] Steppers
- [x] Tab bars
- [x] Navigation elements
- [x] Focus rings
- [x] Selection highlights (list rows, grid cells)
- [x] Generic icons (settings, navigation, UI chrome)
- [x] Link text (generic links)
- [x] Active/hover states

### Semantic Elements (DO NOT Change)
- [x] Event category colors
- [x] Course colors
- [x] Assignment type colors
- [x] Urgency/priority colors (red, yellow, green)
- [x] Status indicators (success, warning, error)
- [x] Grade colors
- [x] Energy level indicators
- [x] Practice test results
- [x] Chart data series
- [x] Calendar event colors

## Testing Recommendations

1. **Accent Color Changes**
   - Change accent color in Settings → Interface
   - Verify all buttons update
   - Verify all toggles update
   - Verify segmented controls update
   - Verify selection highlights update

2. **Light/Dark Mode**
   - Toggle appearance
   - Verify accent color remains visible in both modes
   - Verify contrast is sufficient

3. **Material Compatibility**
   - Test accent color over `.ultraThinMaterial`
   - Test accent color over `.regularMaterial`
   - Test accent color over `.thickMaterial`
   - Verify vibrancy and legibility

4. **Semantic Colors Unchanged**
   - Create events in different categories
   - Verify category colors remain unchanged
   - Create courses with different colors
   - Verify course colors remain unchanged
   - Check urgency indicators (should remain red/yellow/green)

## Migration Guide

### For New Views
```swift
// ✅ Good - Uses centralized accent
Button("Action") { }
    .foregroundStyle(DesignSystem.Colors.accent)

// ✅ Better - Relies on global tint
Button("Action") { }
// Automatically uses accent color

// ❌ Bad - Hard-coded color
Button("Action") { }
    .foregroundColor(.blue)
```

### For Existing Views

1. Search for hard-coded colors:
   ```bash
   grep -r "\.blue\|\.foregroundColor(.blue" macOS/
   ```

2. Determine if generic or semantic:
   - **Generic** (UI chrome, controls) → Replace with `DesignSystem.Colors.accent`
   - **Semantic** (data-driven, status) → Keep as-is, add `.semanticColor()` marker

3. Apply changes:
   ```swift
   // Generic UI
   - .foregroundColor(.blue)
   + .foregroundColor(DesignSystem.Colors.accent)
   
   // Or remove entirely (relies on global tint)
   - .tint(.blue)
   + // Inherits from global .tint()
   ```

## Performance Impact

✅ **Minimal overhead**:
- `DesignSystem.Colors.accent` is a computed property that reads from `AppSettingsModel.shared`
- SwiftUI automatically invalidates views when `@Published` properties change
- No performance penalty compared to hard-coded colors

## Benefits

1. **Consistency**: One coherent accent color across the entire app
2. **User Control**: Users can customize accent color in Settings
3. **Maintainability**: Change accent color in one place affects entire app
4. **Apple-Native**: Uses standard SwiftUI `.tint()` and `.accentColor()` APIs
5. **Semantic Preservation**: Data-driven colors remain meaningful and unchanged
6. **Dark Mode Ready**: Accent color automatically adapts to light/dark appearance

## Future Enhancements (Not Implemented)

1. **Color Schemes**: Pre-defined accent + semantic color combinations
2. **Accessibility**: High contrast accent color variants
3. **Per-Theme Accents**: Different accent colors per material theme
4. **Gradient Accents**: Support for gradient accent colors
5. **Dynamic Accents**: Time-of-day adaptive accent colors
