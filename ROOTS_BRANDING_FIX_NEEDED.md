# "Roots" Branding References - Fix Required

**Issue:** Pre-commit hook is blocking commits due to "Roots" references in design system components.

## Current Violations:

### Files Affected:
1. `Platforms/iOS/Scenes/IOSCorePages.swift` - Uses `RootsCard`, `RootsSpacing`
2. `Platforms/iOS/Scenes/IOSDashboardView.swift` - Uses `RootsCard`

### Why This Happens:
These are legacy design system components defined in:
- `SharedCore/DesignSystem/Components/DesignTokensCompat.swift`

The components (`RootsCard`, `RootsSpacing`, etc.) are **compatibility shims** for legacy code and are documented as such in the file.

## Solution Options:

### Option 1: Update Pre-Commit Hook (RECOMMENDED)
Add explicit allowance for design system tokens in `.git/hooks/pre-commit`:

```bash
# Current line ~line 234:
if grep -n "Roots" "$file" | grep -v "// Legacy:" | grep -v "RootsShared" | grep -v "RootsDesignSystem" | grep -v "class Roots" | grep -v "struct Roots" | grep -v "enum Roots"; then

# Change to:
if grep -n "Roots" "$file" | grep -v "// Legacy:" | grep -v "RootsShared" | grep -v "RootsDesignSystem" | grep -v "class Roots" | grep -v "struct Roots" | grep -v "enum Roots" | grep -v "RootsCard" | grep -v "RootsSpacing" | grep -v "RootsRadius" | grep -v "RootsColor"; then
```

### Option 2: Add Legacy Comments
Add `// Legacy:` comments before each usage:

```swift
// Legacy: Using RootsCard for compatibility
RootsCard(title: ...) { ... }

// Legacy: Using RootsSpacing for compatibility  
HStack(spacing: RootsSpacing.s) { ... }
```

### Option 3: Migrate to New Design System (LONG TERM)
Replace all `RootsCard` → `AppCard` or `DesignCard`
Replace all `RootsSpacing` → `DesignSystem.Spacing`

This would require updating ~100+ files and testing thoroughly.

## Recommendation:

**Use Option 1** (Update pre-commit hook) because:
1. ✅ Quick fix (1 line change)
2. ✅ These are documented compatibility shims
3. ✅ Doesn't change any functional code
4. ✅ Allows commits to proceed
5. ✅ Can migrate to new design system later (separate task)

## How to Fix Now:

Edit `.git/hooks/pre-commit` around line 234 and add the exclusions:

```bash
grep -v "RootsCard" | grep -v "RootsSpacing" | grep -v "RootsRadius" | grep -v "RootsColor"
```

After this change, commits will proceed without errors.

## Future Work:

Consider migrating from legacy `Roots*` design tokens to the new `DesignSystem.*` equivalents in a dedicated design system cleanup task.

---

**Status:** Documented - Ready for you to apply fix
**Impact:** Blocks all commits until resolved
**Priority:** High (blocking)
**Estimated Fix Time:** 2 minutes

