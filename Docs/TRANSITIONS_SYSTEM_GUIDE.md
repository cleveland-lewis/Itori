# Transitions System Implementation Guide

## Overview
Complete standardized transition system for Roots, ensuring uniform animations across all popups, text inputs, and loading states.

## Implementation Summary

### 1. Transition Tokens (DesignSystem+Transitions.swift)
**Location:** `SharedCore/DesignSystem/Components/DesignSystem+Transitions.swift`

#### Available Transitions:
- **Popups/Modals**
  - `popupPresentation` - Fade + subtle scale (95%)
  - `inlineOverlay` - Fade + slide up from bottom
  - `sheet` - Slide from bottom
  - `alert` - Scale + fade

- **Text Inputs**
  - `focusRing` - Simple opacity fade
  - `validationMessage` - Slide down + fade
  - `placeholder` - Opacity fade

- **Loading States**
  - `loadingOverlay` - Opacity fade
  - `loadingInline` - Opacity fade
  - `skeleton` - Opacity fade
  - `contentReplacement` - Asymmetric slide + fade

- **Lists/Cards**
  - `listItem` - Slide from top + fade
  - `card` - Scale + fade

- **Navigation**
  - `page` - Cross-fade
  - `sidebar` - Slide from leading + fade
  - `tab` - Cross-fade

#### Animation Durations:
All durations use `DesignSystem.Motion` tokens:
- Popup: `standard` (0.3s)
- Text focus: `fast` (0.2s)
- Validation: `fast` (0.2s)
- Loading: `standard` (0.3s)
- List item: `fast` (0.2s)
- Content swap: `moderate` (0.4s)

#### Animation Curves:
- `defaultCurve` - `.easeInOut` (standard duration)
- `emphasizedCurve` - Spring (response: 0.4, damping: 0.85)
- `popupCurve` - Spring (response: 0.35, damping: 0.8)
- `focusCurve` - `.easeOut` (fast duration)
- `loadingCurve` - `.easeInOut` (standard duration)
- `listCurve` - Spring (response: 0.3, damping: 0.75)

### 2. Loading Components (LoadingComponents.swift)
**Location:** `SharedCore/DesignSystem/Components/LoadingComponents.swift`

#### Components:
- **LoadingOverlay** - Full-page loading with glass background
  ```swift
  LoadingOverlay(message: "Loading...")
  ```

- **LoadingInlineRow** - Inline loading for list items
  ```swift
  LoadingInlineRow(message: "Fetching data...")
  ```

- **SkeletonCard** - Animated skeleton placeholder
  ```swift
  SkeletonCard(height: 100)
  ```

- **SkeletonTextLines** - Skeleton text placeholders
  ```swift
  SkeletonTextLines(lineCount: 3, lineHeight: 12)
  ```

- **LoadingStateContainer** - State-based container
  ```swift
  LoadingStateContainer(state: loadingState) {
      ContentView()
  }
  ```

- **ErrorStateView** - Standard error display with retry
  ```swift
  ErrorStateView(message: "Failed to load", onRetry: { retry() })
  ```

#### View Modifiers:
```swift
// Show overlay when loading
.loadingOverlay(isLoading: isLoading, message: "Loading...")

// Replace content with loading
.replaceWithLoading(isLoading, message: "Loading...")
```

### 3. Standard Text Inputs (StandardTextInputs.swift)
**Location:** `SharedCore/DesignSystem/Components/StandardTextInputs.swift`

#### Components:
- **StandardTextField** - Text field with focus animations and validation
  ```swift
  StandardTextField(
      "Email",
      text: $email,
      placeholder: "Enter email",
      validation: { ValidationResult.email($0) == .valid ? nil : "Invalid email" }
  )
  ```

- **StandardTextEditor** - Multi-line text with focus animations
  ```swift
  StandardTextEditor(
      "Notes",
      text: $notes,
      placeholder: "Enter notes...",
      minHeight: 100
  )
  ```

- **StandardSearchBar** - Search bar with animated focus and clear button
  ```swift
  StandardSearchBar(
      searchText: $searchText,
      placeholder: "Search...",
      onCommit: { performSearch() }
  )
  ```

- **ValidatedTextField** - Real-time validation with visual feedback
  ```swift
  ValidatedTextField(
      "Password",
      text: $password,
      placeholder: "Enter password",
      validator: { ValidationResult.minLength($0, minimum: 8) }
  )
  ```

#### Built-in Validators:
- `ValidationResult.email(text)` - Email format validation
- `ValidationResult.minLength(text, minimum: n)` - Minimum length check
- `ValidationResult.notEmpty(text)` - Required field check

### 4. View Modifier Enhancements

#### Popup Transitions:
```swift
.popupTransition()              // Standard popup
.inlineOverlayTransition()      // Inline overlay
```

#### Text Input Animations:
```swift
.focusAnimation(value: isFocused)       // Focus ring
.validationTransition()                  // Validation message
```

#### Loading Transitions:
```swift
.loadingTransition()                          // Loading overlay
.contentReplacementTransition(value: state)   // Content swap
```

#### List/Card Transitions:
```swift
.listItemTransition()           // List item
.cardTransition(value: isExpanded)  // Card
```

#### Adaptive Transitions (Reduce Motion):
```swift
.adaptiveTransition(.scale, animation: .easeInOut)
```

## Reduce Motion Support

All transitions automatically respect `accessibilityReduceMotion`:
- When enabled: Falls back to simple opacity fades
- When disabled: Uses full transition with animation

The `AdaptiveTransitionModifier` handles this automatically.

## Migration Guide

### Before (Ad-hoc animations):
```swift
// ❌ Inconsistent, hard-coded
.opacity(showModal ? 1 : 0)
.animation(.easeInOut(duration: 0.25), value: showModal)
```

### After (Tokenized system):
```swift
// ✅ Standardized, semantic
.popupTransition()
```

### Loading States Before:
```swift
// ❌ Custom, inconsistent
if isLoading {
    ProgressView()
        .transition(.opacity)
}
```

### Loading States After:
```swift
// ✅ Standardized component
LoadingInlineRow(message: "Loading...")
```

### Text Inputs Before:
```swift
// ❌ Manual focus handling
TextField("Email", text: $email)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(isFocused ? .blue : .clear)
    )
```

### Text Inputs After:
```swift
// ✅ Standardized with animations
StandardTextField("Email", text: $email, placeholder: "Enter email")
```

## Rules for New Code

### DO ✅
1. Use `DesignSystem.Transitions.*` for all transitions
2. Use `DesignSystem.AnimationCurves.*` for all animations
3. Use `LoadingOverlay`, `LoadingInlineRow`, or `SkeletonCard` for loading
4. Use `StandardTextField` or `StandardTextEditor` for text input
5. Test with Reduce Motion enabled

### DON'T ❌
1. Don't create custom transitions outside DesignSystem
2. Don't hard-code animation durations or curves
3. Don't create custom loading indicators
4. Don't animate layout constraints that cause reflow
5. Don't ignore Reduce Motion settings

## Performance Guidelines

### Fixed Height Placeholders:
```swift
// ✅ Good - no layout shift
SkeletonCard(height: 100)

// ❌ Bad - causes reflow
if isLoading {
    ProgressView()  // Variable height
}
```

### Transform vs Layout:
```swift
// ✅ Good - animates transform
.offset(y: isExpanded ? 0 : 20)
.opacity(isExpanded ? 1 : 0)

// ❌ Bad - forces layout recalc
.frame(height: isExpanded ? 200 : 0)
```

## Testing Checklist

- [ ] All popups use `popupTransition()` or `inlineOverlayTransition()`
- [ ] All text inputs use `StandardTextField` or equivalent
- [ ] All loading states use `LoadingOverlay`, `LoadingInlineRow`, or `SkeletonCard`
- [ ] No ad-hoc `withAnimation` calls outside DesignSystem tokens
- [ ] Reduce Motion produces simplified transitions
- [ ] No layout jumping when loading states appear/disappear
- [ ] All transitions feel consistent with rest of app

## Integration with Existing Code

### AnimationPolicy Integration:
The transitions system works alongside `AnimationPolicy.swift`:
- `AnimationPolicy` handles context-based animation decisions
- `DesignSystem.Transitions` provides the actual transition implementations
- Both respect `accessibilityReduceMotion`

### DesignSystem.Motion Integration:
The transitions system extends `DesignSystem.Motion`:
- Uses existing duration tokens (`fast`, `standard`, etc.)
- Uses existing spring definitions (`standardSpring`, etc.)
- Adds transition-specific timing and curves

## File Structure

```
SharedCore/
  DesignSystem/
    Components/
      DesignSystem+Motion.swift         # Existing: Duration/spring tokens
      DesignSystem+Transitions.swift    # NEW: Transition tokens
      LoadingComponents.swift           # NEW: Loading UI components
      StandardTextInputs.swift          # NEW: Text input components
  Utilities/
    AnimationPolicy.swift               # Existing: Context-based animation policy
```

## Completion Status

✅ Transition tokens defined
✅ Animation durations standardized
✅ Animation curves standardized
✅ Loading components created
✅ Text input components created
✅ Reduce Motion support implemented
✅ View modifiers created
✅ Documentation created

## Next Steps for Full Migration

1. Audit existing popup presentations → migrate to `popupTransition()`
2. Audit text inputs → migrate to `StandardTextField`/`StandardTextEditor`
3. Audit loading states → migrate to `LoadingOverlay`/`LoadingInlineRow`
4. Add linter rule to prevent ad-hoc transitions outside DesignSystem
5. Update PR template to require transition system usage
6. Add unit tests for Reduce Motion behavior

## Example Usage in Real Code

### Popup Presentation:
```swift
.sheet(isPresented: $showingSheet) {
    SheetContent()
}
.popupTransition()
```

### Validation Form:
```swift
VStack(spacing: 16) {
    StandardTextField(
        "Email",
        text: $email,
        placeholder: "you@example.com",
        validation: { text in
            ValidationResult.email(text) == .valid ? nil : "Invalid email"
        }
    )
    
    ValidatedTextField(
        "Password",
        text: $password,
        placeholder: "Minimum 8 characters",
        validator: { ValidationResult.minLength($0, minimum: 8) }
    )
}
```

### Loading State:
```swift
LoadingStateContainer(state: loadingState, onRetry: { fetchData() }) {
    ContentView()
}
```

## Accessibility Compliance

This system ensures WCAG 2.1 Level AA compliance:
- **Success Criterion 2.2.2** (Pause, Stop, Hide): Continuous animations respect Reduce Motion
- **Success Criterion 2.3.3** (Animation from Interactions): All animations can be disabled via system settings
- **Success Criterion 3.2.5** (Change on Request): Transitions only occur in response to user actions

