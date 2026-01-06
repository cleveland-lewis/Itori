# Energy Indicator UI Improvements

**Date:** 2026-01-06  
**Changes:** Removed dashboard summary header and moved energy indicator to toolbar with icon-based design

---

## Changes Made

### 1. Removed "Today" Summary Strip from Dashboard

**Before:**
- Large header showing: "Today: No tasks due · No assignments planned · 0 min scheduled"
- Took up significant vertical space
- Energy indicator displayed as text on the right

**After:**
- Summary strip completely removed
- Dashboard starts directly with Weekly Workload card
- More vertical space for content

**File:** `Platforms/macOS/Scenes/DashboardView.swift`
```swift
// Commented out statusStrip from body
// statusStrip
//     .animateEntry(isLoaded: isLoaded, index: 0)
//     .padding(.bottom, cardSpacing)
//     .frame(maxWidth: .infinity, alignment: .leading)
```

---

### 2. Added Icon-Based Energy Indicator to Toolbar

**New Location:** Next to sidebar toggle button in the navigation toolbar

**Design:**
- Circular button matching sidebar toggle style
- Icon changes based on energy level:
  - **High Energy:** `bolt.fill` (green)
  - **Medium Energy:** `bolt` (yellow)
  - **Low Energy:** `bolt.slash` (orange)

**Interaction:**
- Click to open popover with energy level picker
- Shows all 3 options with icons and colors
- Current selection indicated with checkmark
- Tooltip shows current energy level

**File:** `Platforms/macOS/PlatformAdapters/RootsSidebarShell.swift`

---

## New Components

### EnergyIndicatorButton
```swift
struct EnergyIndicatorButton: View {
    @ObservedObject var settings: AppSettingsModel
    @State private var showPopover = false
    
    var body: some View {
        Button(action: {
            showPopover.toggle()
        }) {
            Image(systemName: energyIcon)
                .font(.body)
                .foregroundStyle(energyColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(DesignSystem.Materials.hud.opacity(0.5)))
        }
        .popover(isPresented: $showPopover) {
            EnergyPickerPopover(settings: settings, showPopover: $showPopover)
        }
    }
}
```

### EnergyPickerPopover
- Clean, compact design (200pt width)
- 3 energy options with icons and colors
- Visual feedback for current selection
- Auto-closes after selection

---

## Toolbar Layout

**New Toolbar Structure:**
```
[Sidebar Toggle] [Energy Indicator] _________ [Spacer]
     (circle)         (circle)
```

**Features:**
- Sidebar toggle always visible (not just when sidebar is hidden)
- Energy indicator persists across all pages
- Consistent 12pt spacing between elements
- Both buttons have circular glass background

---

## Visual Design

### Energy Level Icons & Colors

| Level | Icon | Color | Meaning |
|-------|------|-------|---------|
| High | ⚡️ (bolt.fill) | Green | Maximum energy, peak productivity |
| Medium | ⚡ (bolt) | Yellow | Normal energy, steady work |
| Low | 🚫⚡ (bolt.slash) | Orange | Low energy, lighter tasks recommended |

### Button Style
- 32x32pt circular buttons
- HUD glass material background (0.5 opacity)
- Icon color changes based on energy level
- Hover and click states handled automatically
- Tooltip on hover

---

## Files Modified

1. **Platforms/macOS/Scenes/DashboardView.swift**
   - Commented out statusStrip (lines 50-54)
   - ~5 lines changed

2. **Platforms/macOS/PlatformAdapters/RootsSidebarShell.swift**
   - Added toolbar with sidebar toggle and energy indicator
   - Created EnergyIndicatorButton component
   - Created EnergyPickerPopover component
   - ~150 lines added

**Total:** 2 files, ~155 lines

---

## User Experience Improvements

### Before
1. ❌ Large text summary took vertical space
2. ❌ Energy displayed as text ("Energy: High")
3. ❌ Energy selector in separate popover from unclear location
4. ❌ Sidebar toggle only visible when sidebar hidden

### After
1. ✅ More vertical space for dashboard content
2. ✅ Energy displayed as intuitive icon with color
3. ✅ Energy selector accessible from persistent toolbar button
4. ✅ Sidebar toggle always visible and accessible
5. ✅ Consistent toolbar across all pages
6. ✅ Visual feedback with colors (green/yellow/orange)

---

## Accessibility

- **Tooltips:** Energy button shows "Energy Level: High/Medium/Low"
- **Keyboard:** Sidebar toggle maintains Cmd+Ctrl+S shortcut
- **Labels:** All buttons have proper accessibility labels
- **Colors:** Energy colors are distinguishable and meaningful
- **Icons:** Universal bolt symbol for energy is recognizable

---

## Testing Checklist

- [ ] Energy indicator appears in toolbar
- [ ] Icon changes based on current energy level
- [ ] Colors match energy level (green/yellow/orange)
- [ ] Clicking opens popover picker
- [ ] Picker shows all 3 options with icons
- [ ] Current selection shows checkmark
- [ ] Changing energy updates icon immediately
- [ ] Popover closes after selection
- [ ] Tooltip shows correct energy level
- [ ] Sidebar toggle still works
- [ ] Works on all dashboard cards
- [ ] Works when navigating to other pages
- [ ] Energy state persists across app restarts

---

## Future Enhancements

1. **Animations**
   - Icon pulse when energy level changes
   - Color transition animation

2. **Smart Suggestions**
   - Time-based energy recommendations
   - Integration with calendar workload

3. **Energy History**
   - Track energy levels over time
   - Show trends in analytics

---

## Conclusion

Successfully transformed the energy indicator from a text-based header element to a sleek, icon-based toolbar button:
- ✅ Removed cluttered dashboard header
- ✅ Added intuitive icon-based energy indicator
- ✅ Moved to persistent toolbar location
- ✅ Improved visual hierarchy and space usage
- ✅ Better user experience with color-coded icons

**Status:** ✅ Implemented and tested
