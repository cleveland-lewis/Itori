# Animation Guidelines for Roots

## Overview
This document defines the standardized animation system for Roots, ensuring consistent, smooth, and accessible transitions throughout the app.

## Standardized Animation Tokens

### Durations
Use these semantic duration tokens instead of hard-coded values:

```swift
DesignSystem.Motion.instant     // 0.1s - hover states, instant feedback
DesignSystem.Motion.fast        // 0.2s - quick transitions, toggles
DesignSystem.Motion.standard    // 0.3s - default UI transitions
DesignSystem.Motion.moderate    // 0.4s - smooth animations
DesignSystem.Motion.slow        // 0.5s - deliberate, flowing
DesignSystem.Motion.deliberate  // 0.6s - page transitions, major changes
```

### Easing Curves
```swift
DesignSystem.Motion.snappyEase   // Fast, responsive (.easeInOut + fast)
DesignSystem.Motion.standardEase // Default smooth (.easeInOut + standard)
DesignSystem.Motion.smoothEase   // Gentle, flowing (.easeInOut + moderate)
DesignSystem.Motion.gentleEase   // Slow, deliberate (.easeOut + slow)
```

### Spring Animations
Use semantic spring tokens for natural, physics-based motion:

```swift
DesignSystem.Motion.interactiveSpring  // Button presses, toggles
                                       // response: 0.3, damping: 0.7

DesignSystem.Motion.standardSpring     // Modals, overlays, pickers
                                       // response: 0.3, damping: 0.85

DesignSystem.Motion.layoutSpring       // Resizing, reflow, layout changes
                                       // response: 0.5, damping: 0.8

DesignSystem.Motion.fluidSpring        // Page transitions, smooth flows
                                       // response: 0.4, damping: 0.9

DesignSystem.Motion.wobblySpring       // Playful bounce, success states
                                       // response: 0.4, damping: 0.5
```

### Common Animation Patterns
Shortcuts for typical use cases:

```swift
DesignSystem.Motion.pageTransition     // standardSpring
DesignSystem.Motion.modalTransition    // fluidSpring
DesignSystem.Motion.overlayTransition  // snappyEase
DesignSystem.Motion.cardTransition     // smoothEase
DesignSystem.Motion.sidebarTransition  // standardSpring
```

## Transitions

### Available Transitions
```swift
DesignSystem.Motion.fadeTransition           // .opacity
DesignSystem.Motion.slideUpTransition        // .move(edge: .bottom) + .opacity
DesignSystem.Motion.slideDownTransition      // .move(edge: .top) + .opacity
DesignSystem.Motion.slideLeadingTransition   // .move(edge: .leading) + .opacity
DesignSystem.Motion.slideTrailingTransition  // .move(edge: .trailing) + .opacity
DesignSystem.Motion.scaleTransition          // .scale(0.95) + .opacity
```

## View Modifiers

### Convenience Modifiers
Instead of manually calling `.animation(...)`, use semantic modifiers:

```swift
// Interactive feedback (buttons, toggles)
.interactiveAnimation(value: isPressed)

// Standard transitions (modals, overlays)
.standardTransition(value: showingModal)

// Smooth, flowing transitions
.smoothTransition(value: expandedState)

// Staggered list entry
.staggeredEntry(isLoaded: isLoaded, index: itemIndex)
```

### Example Usage
```swift
// ❌ Old way - inconsistent, hard-coded
Button("Save") { }
    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPressed)

// ✅ New way - semantic, standardized
Button("Save") { }
    .interactiveAnimation(value: isPressed)

// ❌ Old way - hard-coded values
withAnimation(.easeInOut(duration: 0.3)) {
    showModal = true
}

// ✅ New way - semantic token
withAnimation(DesignSystem.Motion.modalTransition) {
    showModal = true
}
```

## Accessibility: Reduce Motion

### Automatic Support
The app automatically detects the Reduce Motion system setting via:
```swift
.detectReduceMotion() // Added to root ContentView
```

### Manual Checks
If you need to customize behavior based on Reduce Motion:
```swift
@Environment(\.reduceMotion) var reduceMotion

var body: some View {
    if reduceMotion {
        // Use fade-only or minimal animation
        content.transition(.opacity)
    } else {
        // Use full animation
        content.transition(DesignSystem.Motion.slideUpTransition)
    }
}
```

### Helper Methods
```swift
// Get animation that respects Reduce Motion
DesignSystem.Motion.animation(
    DesignSystem.Motion.standardSpring, 
    reduceMotion: reduceMotion
)

// Get transition that respects Reduce Motion
DesignSystem.Motion.transition(
    DesignSystem.Motion.slideUpTransition, 
    reduceMotion: reduceMotion
)
```

## Best Practices

### DO ✅
- Use semantic animation tokens instead of hard-coded values
- Prefer `.animation(_, value:)` over implicit animations
- Use spring animations for natural, physics-based feel
- Test with Reduce Motion enabled
- Keep animations under 0.6s for responsiveness
- Combine `.opacity` with movement for smooth transitions

### DON'T ❌
- Don't animate layout constraints that cause full reflow
- Don't use `withAnimation` without a specific value change
- Don't create custom springs with arbitrary values
- Don't animate heavy computations or large image/blur layers
- Don't stack multiple animations on the same property
- Don't ignore Reduce Motion preferences

## Performance Tips

### Prefer Transform Over Layout
```swift
// ✅ Good - animates transform, not layout
.offset(y: isExpanded ? 0 : 20)
.opacity(isExpanded ? 1 : 0)

// ❌ Bad - forces layout recalculation
.frame(height: isExpanded ? 200 : 0)
```

### Avoid Expensive Redraws
```swift
// ✅ Good - animate container, not blur
ZStack {
    content
}
.background(.ultraThinMaterial)
.opacity(isVisible ? 1 : 0)

// ❌ Bad - redraws blur every frame
.background(isVisible ? .ultraThinMaterial : .clear)
```

### Stagger List Entries
Use built-in helper for staggered animations:
```swift
ForEach(items.indices, id: \.self) { index in
    ItemView(item: items[index])
        .staggeredEntry(isLoaded: isLoaded, index: index)
}
```

## Migration Checklist

When updating existing animations:

1. ✅ Replace hard-coded durations with semantic tokens
2. ✅ Replace custom springs with standardized springs
3. ✅ Use view modifiers where appropriate
4. ✅ Test with Reduce Motion enabled
5. ✅ Verify no layout thrashing (use Instruments if needed)
6. ✅ Check that animations feel consistent with rest of app

## Common Use Cases

### Modal Presentation
```swift
.sheet(isPresented: $showModal) {
    ModalContent()
}
.animation(DesignSystem.Motion.modalTransition, value: showModal)
```

### Card Expansion
```swift
CardView(isExpanded: $isExpanded)
    .smoothTransition(value: isExpanded)
```

### Button Press
```swift
Button("Action") { }
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .interactiveAnimation(value: isPressed)
```

### Page Transition
```swift
withAnimation(DesignSystem.Motion.pageTransition) {
    currentPage = nextPage
}
```

### Sidebar Toggle
```swift
withAnimation(DesignSystem.Motion.sidebarTransition) {
    showSidebar.toggle()
}
```

## Testing

### Manual Testing
1. Navigate through all major transitions
2. Test with Reduce Motion enabled in System Preferences
3. Verify smooth 60fps on target hardware
4. Check for visual stuttering or jank
5. Ensure animations feel consistent app-wide

### Performance Testing
Use Instruments (Time Profiler) to identify:
- Heavy body recalculations during animations
- Expensive view computations
- Blur/material layer redraws
- Layout thrashing

## Support

For questions or suggestions about the animation system, please refer to:
- DesignSystem+Motion.swift (implementation)
- AccessibilityPreferences.swift (Reduce Motion detection)
- This document (guidelines)
