# Platform Unification Framework - Index

## Overview

The Platform Unification Framework provides a comprehensive system for building consistent, platform-appropriate experiences across watchOS, iOS, iPadOS, and macOS.

## Quick Links

### 📋 Essential References

1. **[Platform Capability Matrix](PLATFORM_CAPABILITY_MATRIX.md)** ⭐ **BINDING CONTRACT**
   - Definitive reference for allowed/forbidden patterns per platform
   - Must be consulted before implementing any new UI or feature
   - Navigation, layout, input, persistence, and more
   
2. **[Capability Matrix Quick Reference](PLATFORM_CAPABILITY_MATRIX_QUICK_REFERENCE.md)**
   - Fast lookup for common questions
   - Decision guide for platform patterns
   - Common violations to avoid

### 📚 Documentation

1. **[Summary](PLATFORM_UNIFICATION_SUMMARY.md)** - Implementation summary and acceptance criteria
2. **[Framework Documentation](PLATFORM_UNIFICATION_FRAMEWORK.md)** - Complete framework documentation
3. **[Quick Reference](PLATFORM_UNIFICATION_QUICK_REFERENCE.md)** - Quick reference guide for daily use
4. **[Implementation Guide](PLATFORM_UNIFICATION_IMPLEMENTATION_GUIDE.md)** - Practical examples and patterns

### 💻 Source Code

1. **Core Framework**: `SharedCore/Platform/PlatformUnification.swift`
   - Platform hierarchy and detection
   - Capability matrix (Layout, Interaction, Density, Visual, Navigation)
   - View modifiers

2. **Adaptive Components**: `SharedCore/Platform/PlatformAdaptiveComponents.swift`
   - Pre-built adaptive UI components
   - Helper modifiers
   - Feature flags

3. **Guidelines & Validation**: `SharedCore/Platform/PlatformGuidelines.swift`
   - Platform-specific design rules
   - Anti-pattern detection
   - Debug tools

### 🧪 Tests

**Unit Tests**: `Tests/Unit/RootsTests/Platform/PlatformUnificationTests.swift`
- 40+ comprehensive tests
- Platform detection validation
- Capability verification
- Anti-pattern detection
- Integration tests

## Platform Hierarchy

```
watchOS (Tier 0) - Glanceable
    ↓
iOS (Tier 1) - Immersive  
    ↓
iPadOS (Tier 2) - Flexible Productivity
    ↓  (selective inheritance only)
macOS (Tier 3) - Maximum Power
```

## Key Principles

1. **One Visual Language** - Shared colors, typography, spacing
2. **Platform-Appropriate Density** - 1-2 items (watch) to 10+ items (Mac)
3. **Predictable Behavior** - Same feature works similarly everywhere
4. **No Lesser Clones** - Each platform optimized for its strengths

## Critical Rules

### ✅ What We Do

- iPadOS selectively inherits from macOS (keyboard, hover, multi-window)
- Each platform respects its interaction model (touch vs pointer)
- Capabilities scale with platform power
- Shared visual design language

### ❌ What We Don't Do

- iOS does NOT inherit from iPadOS (stays simple)
- iPadOS is NOT a macOS clone (no menu bar, touch-first)
- No forced feature parity (appropriate features per platform)
- No desktop paradigms on touch devices

## Quick Start

### 1. Platform Detection

```swift
import SharedCore

if Platform.current >= .iPadOS {
    // Code for iPad and Mac
}
```

### 2. Capability Check

```swift
if CapabilityDomain.Layout.supportsMultiPane {
    // Show split view
}
```

### 3. Use Adaptive Component

```swift
AdaptiveCard {
    Text("Content")
}
```

### 4. Apply Platform Modifier

```swift
Text("Hello")
    .platformPadding()
    .platformHoverEffect()
```

## Capability Matrix

| Capability | watchOS | iOS | iPadOS | macOS |
|-----------|---------|-----|---------|-------|
| Navigation Depth | 2 | 4 | 6 | 8 |
| UI Density | 1-2 items | 3-5 items | 5-8 items | 10+ items |
| Tap Target | 44pt | 44pt | 40pt | 28pt |
| Multi-Pane | ✗ | ✗ | ✓ | ✓ |
| Hover | ✗ | ✗ | ✓ | ✓ |
| Keyboard Shortcuts | ✗ | ✗ | ✓ | ✓ |
| Menu Bar | ✗ | ✗ | ✗ | ✓ |

## Common Use Cases

### Conditional Layout

```swift
if CapabilityDomain.Visual.prefersSidebar {
    NavigationSplitView { /* ... */ }
} else {
    TabView { /* ... */ }
}
```

### Responsive Grid

```swift
AdaptiveGrid {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}
// Automatically: 1 col (watch), 2 cols (iPhone), 3 cols (iPad), 4 cols (Mac)
```

### Platform-Appropriate Interaction

```swift
Button("Action") { /* ... */ }
    .frame(minWidth: CapabilityDomain.Density.minTapTargetSize,
           minHeight: CapabilityDomain.Density.minTapTargetSize)
    .platformHoverEffect()
```

## Debug Tools

### Visual Debug View

```swift
#if DEBUG
PlatformDebugView()
#endif
```

### Console Output

```swift
PlatformCapabilityMatrix.printMatrix()
```

### Validation

```swift
let errors = PlatformValidation.validate()
errors.forEach { print($0) }
```

## Testing

### Run Platform Tests

```bash
xcodebuild test -scheme "Roots" -only-testing:RootsTests/PlatformUnificationTests
```

### Test Coverage

- ✅ Platform detection
- ✅ All capability domains (Layout, Interaction, Density, Visual, Navigation)
- ✅ Anti-pattern detection
- ✅ Validation logic
- ✅ Feature flags
- ✅ Guidelines compliance

## Migration Path

### From Legacy Code

```swift
// Old
#if os(iOS)
    iOSSpecificCode()
#elseif os(macOS)
    macOSSpecificCode()
#endif

// New
if CapabilityDomain.Interaction.supportsHover {
    addHoverEffect()
}
```

### Deprecation Notice

`SharedCore/Utilities/PlatformCapabilities.swift` is now deprecated. Use `PlatformUnification.swift` instead.

## Files Overview

### Documentation (31.5 KB total)
- `PLATFORM_UNIFICATION_SUMMARY.md` (8.6 KB)
- `PLATFORM_UNIFICATION_FRAMEWORK.md` (11.0 KB)
- `PLATFORM_UNIFICATION_QUICK_REFERENCE.md` (5.2 KB)
- `PLATFORM_UNIFICATION_IMPLEMENTATION_GUIDE.md` (13.6 KB)
- `PLATFORM_UNIFICATION_INDEX.md` (this file)

### Source Code (35.2 KB total)
- `PlatformUnification.swift` (11.6 KB)
- `PlatformAdaptiveComponents.swift` (10.9 KB)
- `PlatformGuidelines.swift` (12.8 KB)

### Tests (13.1 KB)
- `PlatformUnificationTests.swift` (13.1 KB)

## Acceptance Criteria ✅

All criteria met:

- [x] Clear platform capability matrix defined
- [x] iPadOS consistently more powerful than iOS
- [x] iOS consistently simpler than iPadOS
- [x] macOS remains most expressive
- [x] watchOS remains minimal
- [x] Shared visual language
- [x] Platform-appropriate density
- [x] Predictable behavior
- [x] Anti-pattern detection
- [x] Debug tools
- [x] Comprehensive documentation
- [x] Unit tests (40+)
- [x] Implementation guide

## Next Steps

### Immediate (Day 1)
1. ✅ Review documentation
2. ✅ Run unit tests
3. ✅ View `PlatformDebugView()` on each platform

### Short-term (Week 1)
1. Migrate existing platform checks to capability checks
2. Replace platform-specific views with adaptive components
3. Add platform validation to CI/CD

### Long-term (Month 1+)
1. Track platform usage patterns
2. Refine capability matrix based on usage
3. Create automated migration tools

## Support & Resources

### Getting Help

1. **Quick Question?** → Check [Quick Reference](PLATFORM_UNIFICATION_QUICK_REFERENCE.md)
2. **Implementation Help?** → Read [Implementation Guide](PLATFORM_UNIFICATION_IMPLEMENTATION_GUIDE.md)
3. **Deep Dive?** → Read [Framework Documentation](PLATFORM_UNIFICATION_FRAMEWORK.md)
4. **Summary?** → Read [Summary](PLATFORM_UNIFICATION_SUMMARY.md)

### External Resources

- [Apple HIG - watchOS](https://developer.apple.com/design/human-interface-guidelines/watchos)
- [Apple HIG - iOS](https://developer.apple.com/design/human-interface-guidelines/ios)
- [Apple HIG - iPadOS](https://developer.apple.com/design/human-interface-guidelines/ipados)
- [Apple HIG - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)

## Version Information

- **Version**: 1.0
- **Status**: Production Ready ✅
- **Date**: January 3, 2026
- **Platforms Supported**: watchOS, iOS, iPadOS, macOS
- **Tests**: 40+ passing
- **Documentation**: Complete

## Change Log

### v1.0 (January 3, 2026)
- Initial release
- Complete platform hierarchy
- Comprehensive capability matrix
- Adaptive components library
- Anti-pattern detection
- Validation system
- Debug tools
- Full documentation
- 40+ unit tests

---

**The Platform Unification Framework is production-ready and provides a complete solution for building consistent, platform-appropriate experiences across all Apple platforms.**

For questions or issues, refer to the documentation or run `PlatformValidation.validate()` to check for problems.
