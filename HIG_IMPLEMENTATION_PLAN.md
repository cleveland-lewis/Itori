# HIG Compliance Implementation Plan

## Immediate Actions (Following User's Design Intent)

The user has explicitly requested removal of sidebars and navigation titles. We'll implement maximum HIG compliance **within those constraints**.

---

## Phase 1: Native Styling (High Priority) ⚡

### 1.1 Semantic Colors Throughout App

**Replace all custom colors with semantic colors:**

```swift
// ❌ BEFORE
.background(Color(nsColor: .controlBackgroundColor))
.foregroundStyle(Color.secondary.opacity(0.7))
Color.blue.opacity(0.2)

// ✅ AFTER
.background(.background)
.foregroundStyle(.secondary)
Color.blue.quinary
```

**Files to Update:**
- FlashcardsView.swift
- DashboardView.swift
- CoursesPageView.swift
- All card components

### 1.2 Standard Button Styles

```swift
// Primary actions
.buttonStyle(.borderedProminent)

// Secondary actions
.buttonStyle(.bordered)

// Tertiary/toolbar actions
.buttonStyle(.plain)
```

### 1.3 Native Control Sizes

```swift
.controlSize(.large)   // For prominent actions
.controlSize(.regular) // Default
.controlSize(.small)   // For compact areas
```

---

## Phase 2: Layout & Spacing (Medium Priority)

### 2.1 Remove Hardcoded Padding

```swift
// ❌ BEFORE
.padding(20)
.padding(.horizontal, 16)

// ✅ AFTER
.padding()          // Automatic adaptive
.padding(.horizontal) // Standard horizontal
```

### 2.2 Adaptive Grid Columns

```swift
// ✅ Already correct in FlashcardsView
LazyVGrid(columns: [
    GridItem(.adaptive(minimum: 300))
])
```

---

## Phase 3: Typography (Low Priority)

### 3.1 Semantic Font Sizes

```swift
// ❌ BEFORE
.font(.system(size: 16))

// ✅ AFTER
.font(.body)
.font(.headline)
.font(.caption)
```

---

## Phase 4: Forms & Controls

### 4.1 Native Form Styling

```swift
Form {
    Section {
        // controls
    }
}
.formStyle(.grouped)
```

### 4.2 Native Pickers

```swift
Picker("", selection: $value) {
    // options
}
.pickerStyle(.menu)
```

---

## Implementation Order

### Day 1: Semantic Colors
1. Create color extension for semantic mappings
2. Replace all custom colors in:
   - FlashcardsView
   - DashboardView
   - Timer cards
   - All card components

### Day 2: Button Styles
1. Standardize all button styles
2. Add proper control sizes
3. Ensure keyboard shortcuts

### Day 3: Spacing & Layout
1. Remove hardcoded padding
2. Verify grid layouts
3. Check form layouts

### Day 4: Polish
1. Typography audit
2. Accessibility check
3. Final review

---

## Respecting User's Design Choices

**User requested:**
- ❌ No sidebars in Flashcards
- ❌ No "Roots" title at top

**We will:**
- ✅ Keep full-width card layouts
- ✅ Use native card styling (with semantic colors)
- ✅ Ensure buttons use standard styles
- ✅ Apply proper spacing automatically

---

## Success Metrics

- [ ] Zero custom color literals (all semantic)
- [ ] All buttons use standard styles
- [ ] No hardcoded padding >5 instances
- [ ] All text uses semantic fonts
- [ ] Passes macOS Accessibility Inspector
- [ ] Looks native at all system appearances
