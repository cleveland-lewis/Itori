# Transitions System Quick Reference

## When to Use What

### Popups & Modals
```swift
// ✅ Standard popup/modal
.popupTransition()

// ✅ Inline overlay (dropdown, tooltip)
.inlineOverlayTransition()
```

### Text Inputs
```swift
// ✅ Simple text field
StandardTextField("Title", text: $text, placeholder: "Enter text")

// ✅ With validation
StandardTextField("Email", text: $email, validation: { 
    ValidationResult.email($0) == .valid ? nil : "Invalid" 
})

// ✅ Multi-line text
StandardTextEditor("Notes", text: $notes, minHeight: 100)

// ✅ Search bar
StandardSearchBar(searchText: $query)

// ✅ Real-time validation
ValidatedTextField("Password", text: $password, validator: {
    ValidationResult.minLength($0, minimum: 8)
})
```

### Loading States
```swift
// ✅ Full-page loading
LoadingOverlay(message: "Loading...")

// ✅ Inline loading (list)
LoadingInlineRow(message: "Fetching...")

// ✅ Skeleton placeholder
SkeletonCard(height: 100)
SkeletonTextLines(lineCount: 3)

// ✅ State-based loading
LoadingStateContainer(state: loadingState, onRetry: retry) {
    ContentView()
}

// ✅ Conditional overlay
.loadingOverlay(isLoading: isLoading)

// ✅ Replace content with loading
.replaceWithLoading(isLoading)
```

### Lists & Cards
```swift
// ✅ List item insertion
.listItemTransition()

// ✅ Card expansion
.cardTransition(value: isExpanded)
```

### Animations
```swift
// ✅ Use semantic curves
withAnimation(DesignSystem.AnimationCurves.popupCurve) {
    showModal = true
}

// ✅ Use semantic transitions
.transition(DesignSystem.Transitions.popupPresentation)

// ✅ Reduce Motion support
.adaptiveTransition(.scale, animation: .easeInOut)
```

## Cheat Sheet

| UI Element | Component | Transition |
|------------|-----------|------------|
| Modal/Sheet | `.sheet(...)` | `.popupTransition()` |
| Dropdown | Custom view | `.inlineOverlayTransition()` |
| Text Field | `StandardTextField` | Auto-handled |
| Search Bar | `StandardSearchBar` | Auto-handled |
| Page Loading | `LoadingOverlay` | Auto-handled |
| List Loading | `LoadingInlineRow` | Auto-handled |
| Skeleton | `SkeletonCard` | Auto-handled |
| List Item | List row | `.listItemTransition()` |
| Card | Card view | `.cardTransition(value:)` |

## Quick Validators

```swift
// Email
validation: { ValidationResult.email($0) == .valid ? nil : "Invalid email" }

// Min length
validation: { text in
    text.count >= 8 ? nil : "Must be 8+ characters"
}

// Required
validation: { text in
    text.isEmpty ? "Required" : nil
}

// Real-time validation
validator: { ValidationResult.minLength($0, minimum: 8) }
```

## Common Patterns

### Modal with Loading
```swift
.sheet(isPresented: $showModal) {
    ContentView()
        .loadingOverlay(isLoading: isLoading)
}
.popupTransition()
```

### Form with Validation
```swift
Form {
    StandardTextField("Name", text: $name, validation: {
        $0.isEmpty ? "Required" : nil
    })
    
    ValidatedTextField("Email", text: $email, validator: {
        ValidationResult.email($0)
    })
}
```

### List with Loading
```swift
List {
    if isLoading {
        LoadingInlineRow(message: "Loading...")
    } else {
        ForEach(items) { item in
            ItemRow(item: item)
                .listItemTransition()
        }
    }
}
```

### Content State Management
```swift
LoadingStateContainer(state: state, onRetry: { load() }) {
    ContentView()
}
```

## Don't Do This ❌

```swift
// ❌ Hard-coded animations
.animation(.easeInOut(duration: 0.3), value: show)

// ❌ Custom transitions
.transition(.move(edge: .bottom).combined(with: .opacity))

// ❌ Custom loading indicators
if isLoading { ProgressView() }

// ❌ Manual focus rings
.overlay(RoundedRectangle(...).stroke(isFocused ? .blue : .clear))
```

## Do This Instead ✅

```swift
// ✅ Semantic animations
.animation(DesignSystem.AnimationCurves.popupCurve, value: show)

// ✅ Tokenized transitions
.inlineOverlayTransition()

// ✅ Standard loading components
LoadingInlineRow()

// ✅ Standard text inputs
StandardTextField("Title", text: $text)
```

## Performance Tips

- Use fixed heights for loading states
- Prefer transform animations (offset, scale, opacity)
- Avoid animating layout constraints
- Test with Reduce Motion enabled
- Keep animations under 0.6s

## Testing

1. Navigate through all transitions
2. Enable Reduce Motion (System Preferences → Accessibility → Display)
3. Verify smooth 60fps
4. Check for layout jumping
5. Test all loading states
