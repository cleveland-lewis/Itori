# "Roots" Design System Components - Migration Recommendation

## Current State Analysis

### What are these components?

`RootsCard`, `RootsSpacing`, etc. are **legacy compatibility shims** defined in:
- `SharedCore/DesignSystem/Components/DesignTokensCompat.swift`

They are **NOT Apple native** - they're custom components wrapping Apple's SwiftUI.

### Usage Statistics:
- `RootsCard`: 15 usages (vs `AppCard`: 27 usages) 
- `RootsSpacing`: 48 usages (vs `DesignSystem.Layout.spacing`: 97 usages)

**The codebase is already 60-70% migrated to the new design system!**

### What `RootsCard` Actually Is:
```swift
struct RootsCard<Content: View>: View {
    // Custom card with:
    // - Title, subtitle, icon
    // - Design system materials
    // - Rounded corners
    // - Shadow and border
    
    var body: some View {
        VStack {
            // Header if provided
            content
        }
        .background(DesignSystem.Materials.card)
        .clipShape(RoundedRectangle(...))
        .overlay(border...)
        .shadow(...)
    }
}
```

**It's a thin wrapper around SwiftUI views with your design tokens.**

---

## Recommendation: MIGRATE (But Not Urgent)

### Short Term (Right Now): ✅ **Update Pre-Commit Hook**
Allow `RootsCard`, `RootsSpacing`, etc. in the pre-commit hook so commits aren't blocked.

**Why:** 
- Blocks all work unnecessarily
- Quick 2-minute fix
- Safe (these are documented compatibility shims)
- Can migrate properly later

**How:**
```bash
# Edit .git/hooks/pre-commit line ~234
# Add: | grep -v "RootsCard" | grep -v "RootsSpacing" | grep -v "RootsRadius" | grep -v "RootsColor"
```

---

### Medium Term (Next Sprint): Migrate Remaining Usage

**Why Migrate:**
1. ✅ Consistency - Most code already uses new system
2. ✅ Maintainability - One design language
3. ✅ Features - `AppCard` has more capabilities
4. ✅ Branding - Remove "Roots" references completely

**Migration Map:**

| Legacy | Modern Replacement |
|--------|-------------------|
| `RootsCard` | `AppCard` (already exists!) |
| `RootsSpacing.s` | `DesignSystem.Layout.spacing.small` |
| `RootsSpacing.m` | `DesignSystem.Layout.spacing.medium` |
| `RootsSpacing.l` | `DesignSystem.Layout.spacing.large` |
| `RootsRadius.card` | `DesignSystem.Layout.cornerRadiusStandard` |
| `RootsColor.textPrimary` | `.primary` (native SwiftUI) |

**Estimated Effort:**
- 15 RootsCard → AppCard: ~30 minutes
- 48 RootsSpacing references: ~45 minutes  
- **Total: ~1.5 hours** (not much!)

**Risk:** Low
- `AppCard` already tested and in use (27 places)
- Design tokens well-established (97+ usages)
- Can do incrementally, file by file

---

### Long Term: Delete Compatibility Shims

After migration is complete:
1. Delete `DesignTokensCompat.swift`
2. Remove pre-commit hook exceptions
3. Clean codebase

---

## Comparison: RootsCard vs AppCard

### RootsCard (Legacy):
```swift
RootsCard(
    title: "Study Time",
    subtitle: "Your progress",
    icon: nil
) {
    VStack { /* content */ }
}
```

### AppCard (Modern):
```swift
AppCard(
    title: "Study Time",
    icon: Image(systemName: "clock")
) {
    VStack { /* content */ }
}
```

**Differences:**
- AppCard integrates with `@EnvironmentObject private var settings: AppSettingsModel`
- AppCard uses `@Environment(\.interfacePreferences)` for dynamic spacing
- AppCard has icon bounce effects
- AppCard has better popup support
- **AppCard is the future** ✅

---

## Why Not "Just Use Native SwiftUI"?

SwiftUI doesn't have a "Card" component - you'd have to recreate:
- Consistent padding
- Background materials
- Rounded corners  
- Borders
- Shadows
- Headers
- Theming

Both `RootsCard` and `AppCard` are **custom components** that give you:
- Consistent design language
- Less code duplication
- Easy theme changes
- Reusable patterns

**This is standard practice** - almost every SwiftUI app has custom card components.

---

## Action Plan

### Immediate (2 minutes):
```bash
# Update .git/hooks/pre-commit to allow legacy tokens
# This unblocks all commits
```

### This Week (Optional, 1.5 hours):
1. Create migration script or manual list
2. Replace `RootsCard` → `AppCard` (15 files)
3. Replace `RootsSpacing` → `DesignSystem.Layout.spacing` (48 occurrences)
4. Test affected screens
5. Commit migration

### Future:
- Delete `DesignTokensCompat.swift`
- Remove pre-commit exceptions
- Full design system modernization complete

---

## Final Recommendation

**For Right Now (Unblock Accessibility Work):**
✅ **Update pre-commit hook** to allow `Roots*` design tokens

**For Next Sprint:**
✅ **Migrate remaining usage** to modern design system (1.5 hours)

**Not Recommended:**
❌ Don't try to use "native only" SwiftUI - you'd lose your design system
❌ Don't block current work over this - it's technical debt, not urgent

---

## Summary

- `RootsCard` = Your custom component (not Apple native)
- `AppCard` = Your newer custom component (also not Apple native)
- **Both are fine** - `AppCard` is just better/newer
- Already 60-70% migrated to new system
- Finishing migration = 1.5 hours work
- **Current blocker:** Pre-commit hook being too strict

**Unblock now, migrate later.** ✅

