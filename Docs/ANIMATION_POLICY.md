# Animation Policy Guide

## Overview

Itori uses a centralized `AnimationPolicy` to ensure all animations respect the system's Reduce Motion accessibility setting. This guide explains how to use the animation policy correctly.

## Why Use AnimationPolicy?

1. **Accessibility**: Respects system Reduce Motion preferences
2. **Consistency**: Standardized animation durations and styles
3. **Maintainability**: Single source of truth for animation behavior
4. **Performance**: Disabled animations when not needed

## Animation Contexts

The `AnimationPolicy.AnimationContext` enum defines different types of animations:

### `.essential`
**Purpose:** Critical UI state changes that must be visible
**Examples:** Selection states, focus indicators, modal presentations
**Reduce Motion Behavior:** Very short linear animation (0.1s)

```swift
DesignSystem.Motion.withAnimation(.essential) {
    isSelected = true
}
```

### `.decorative`
**Purpose:** Non-essential embellishments
**Examples:** Hover effects, spring animations, micro-interactions
**Reduce Motion Behavior:** Disabled (instant change)

```swift
Text("Hover me")
    .scaleEffect(isHovered ? 1.05 : 1.0)
    .animationPolicy(.decorative, value: isHovered)
```

### `.chart`
**Purpose:** Chart rendering and data visualizations
**Examples:** Line drawing, bar animations, pie chart segments
**Reduce Motion Behavior:** Disabled (show final state)

```swift
if DesignSystem.Motion.animation(for: .chart) != nil {
    // Animate chart drawing
    chartPath.trim(from: 0, to: progress)
        .animationPolicy(.chart, value: progress)
} else {
    // Show final state immediately
    chartPath
}
```

### `.continuous`
**Purpose:** Ongoing animations that loop
**Examples:** Shimmer effects, pulsing indicators, floating animations
**Reduce Motion Behavior:** Disabled completely

```swift
if AnimationPolicy.shared.shouldAnimate(for: .continuous) {
    Circle()
        .scaleEffect(isPulsing ? 1.2 : 1.0)
        .animationPolicy(.continuous, value: isPulsing)
} else {
    Circle()
}
```

### `.navigation`
**Purpose:** View transitions and navigation
**Examples:** Page transitions, sheet presentations
**Reduce Motion Behavior:** Disabled (instant transition)

```swift
DesignSystem.Motion.withAnimation(.navigation) {
    showDetailView = true
}
```

### `.listTransition`
**Purpose:** List item insertions and deletions
**Examples:** Adding/removing rows, reordering
**Reduce Motion Behavior:** Disabled (instant)

```swift
ForEach(items) { item in
    ItemRow(item: item)
}
.transitionPolicy(.listTransition)
```

## Usage Patterns

### 1. View Modifiers

Use `.animationPolicy()` instead of `.animation()`:

```swift
// ❌ DON'T DO THIS
Text("Hello")
    .opacity(isVisible ? 1 : 0)
    .animation(.easeInOut, value: isVisible)

// ✅ DO THIS
Text("Hello")
    .opacity(isVisible ? 1 : 0)
    .animationPolicy(.essential, value: isVisible)
```

### 2. State Changes

Use `DesignSystem.Motion.withAnimation()` instead of `withAnimation()`:

```swift
// ❌ DON'T DO THIS
withAnimation {
    count += 1
}

// ✅ DO THIS
DesignSystem.Motion.withAnimation(.essential) {
    count += 1
}
```

### 3. Transitions

Use `.transitionPolicy()` for view transitions:

```swift
// ✅ GOOD
if showContent {
    ContentView()
        .transitionPolicy(.navigation)
}
```

### 4. Conditional Animation

Check if animation should occur:

```swift
let policy = AnimationPolicy.shared

if policy.shouldAnimate(for: .chart) {
    // Perform animation
    animateChartDrawing()
} else {
    // Show final state
    showFinalChartState()
}
```

### 5. Custom Animation Duration

Get duration for custom animations:

```swift
let duration = AnimationPolicy.shared.duration(for: .decorative)
// duration will be 0.35 normally, 0 with reduce motion
```

## Migration Guide

### Before (Direct Animation)

```swift
struct ContentView: View {
    @State private var isHovered = false
    
    var body: some View {
        Button("Click me") {
            // action
        }
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.spring(), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
```

### After (With AnimationPolicy)

```swift
struct ContentView: View {
    @State private var isHovered = false
    
    var body: some View {
        Button("Click me") {
            // action
        }
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animationPolicy(.decorative, value: isHovered)
        .onHover { hovering in
            DesignSystem.Motion.withAnimation(.decorative) {
                isHovered = hovering
            }
        }
    }
}
```

## Best Practices

### 1. Choose the Right Context

- Use `.essential` sparingly - only for critical feedback
- Use `.decorative` for most hover/interaction effects
- Use `.continuous` only when the animation adds real value
- Disable continuous animations in List/ScrollView for performance

### 2. Provide Non-Animated Alternatives

Always ensure your UI is functional without animations:

```swift
// ✅ GOOD - Works with or without animation
if AnimationPolicy.shared.shouldAnimate(for: .chart) {
    AnimatedChart(data: data)
} else {
    StaticChart(data: data)
}

// ❌ BAD - Might look broken without animation
AnimatedChart(data: data)
    .animationPolicy(.chart, value: data)
```

### 3. Test With Reduce Motion

Enable Reduce Motion in System Preferences to test:
1. Open System Settings
2. Go to Accessibility → Display
3. Enable "Reduce motion"
4. Verify your UI still works correctly

### 4. Chart Animations

For charts, always provide instant rendering option:

```swift
struct Chart: View {
    let data: [DataPoint]
    @State private var progress: CGFloat = 0
    
    var body: some View {
        ChartPath(data: data)
            .trim(from: 0, to: shouldAnimate ? progress : 1.0)
            .animationPolicy(.chart, value: progress)
            .onAppear {
                if shouldAnimate {
                    progress = 1.0
                } else {
                    progress = 1.0 // Instant
                }
            }
    }
    
    private var shouldAnimate: Bool {
        AnimationPolicy.shared.shouldAnimate(for: .chart)
    }
}
```

## Common Mistakes

### ❌ Mistake 1: Using `.animation()` directly

```swift
// DON'T
.animation(.default, value: someValue)
```

Use `.animationPolicy()` instead:

```swift
// DO
.animationPolicy(.essential, value: someValue)
```

### ❌ Mistake 2: Not checking `shouldAnimate` for continuous animations

```swift
// DON'T - Animation continues even with reduce motion
Circle()
    .scaleEffect(isPulsing ? 1.2 : 1.0)
    .animation(.linear.repeatForever(), value: isPulsing)
```

Check first:

```swift
// DO
if AnimationPolicy.shared.shouldAnimate(for: .continuous) {
    Circle()
        .scaleEffect(isPulsing ? 1.2 : 1.0)
        .animationPolicy(.continuous, value: isPulsing)
}
```

### ❌ Mistake 3: Using wrong context

```swift
// DON'T - Essential should only be for critical feedback
Button("Delete") { }
    .animationPolicy(.essential, value: isPressed)
```

Use appropriate context:

```swift
// DO
Button("Delete") { }
    .animationPolicy(.decorative, value: isPressed)
```

## Environment Integration

AnimationPolicy is available in the SwiftUI environment:

```swift
struct CustomView: View {
    @Environment(\.animationPolicy) var animationPolicy
    
    var body: some View {
        Text("Hello")
            .opacity(animationPolicy.isReduceMotionEnabled ? 1.0 : 0.5)
    }
}
```

## Monitoring Changes

The AnimationPolicy is an `ObservableObject` that publishes changes:

```swift
struct MonitorView: View {
    @ObservedObject var policy = AnimationPolicy.shared
    
    var body: some View {
        VStack {
            Text("Reduce Motion: \(policy.isReduceMotionEnabled ? "ON" : "OFF")")
            
            if policy.isReduceMotionEnabled {
                Text("Animations are minimized")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

## Performance Considerations

1. **Continuous animations** have the highest performance impact - use sparingly
2. **Chart animations** can be expensive for large datasets - always provide instant option
3. **Spring animations** are more expensive than linear - use appropriate context
4. When Reduce Motion is enabled, performance improves significantly as most animations are disabled

## Testing Checklist

Before merging animation changes:

- [ ] Test with Reduce Motion enabled
- [ ] Verify critical feedback is still visible
- [ ] Ensure no UI functionality depends on animations
- [ ] Check that continuous animations stop completely
- [ ] Verify charts render correctly (instant mode)
- [ ] Test on slower hardware if available
- [ ] Verify transitions don't cause layout issues

## Additional Resources

- Apple HIG: [Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
- WCAG 2.1: [Animation from Interactions](https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html)
- AppKit: [NSWorkspace.accessibilityDisplayShouldReduceMotion](https://developer.apple.com/documentation/appkit/nsworkspace/1644404-accessibilitydisplayshouldreduce)
