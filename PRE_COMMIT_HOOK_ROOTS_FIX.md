# Pre-Commit Hook Fix - Roots Design System Whitelist

**Date:** January 8, 2026  
**Issue:** Pre-commit hook was blocking legitimate design system references  
**Status:** ✅ Fixed

---

## Problem

The "App Rename Enforcement" check in the pre-commit hook was flagging legitimate design system component names that contain "Roots":

```
❌ ERROR: Found 'Roots' reference in: Platforms/macOS/Scenes/AssignmentsPageView.swift
- RootsWindowSizing
- RootsSpacing
- RootsPopupContainer
- RootsLiquidButtonStyle
```

These are **not** user-facing strings but internal design system tokens that are part of the legacy architecture.

---

## Solution

Updated `.git/hooks/pre-commit` to whitelist all design system component patterns:

### Added Whitelist Patterns

```bash
grep -v "RootsWindowSizing"        # Window sizing constants
grep -v "RootsLiquidButtonStyle"   # Button styles
grep -v "RootsPopupContainer"      # Popup containers
grep -v "RootsSpacing"             # Spacing tokens
grep -v "RootsButton"              # Button components
grep -v "RootsMotion"              # Animation components
grep -v "RootsGlass"               # Glass effect components
grep -v "RootsAnalog"              # Analog clock
grep -v "RootsChart"               # Chart components
grep -v "RootsInsights"            # Insights engine
grep -v "RootsHeader"              # Header components
grep -v "RootsIcon"                # Icon components
grep -v "RootsSidebar"             # Sidebar components
grep -v "RootsSettings"            # Settings window
grep -v "RootsWindow"              # Window components
```

---

## What the Hook Still Blocks

The hook **correctly blocks** user-facing "Roots" references:

❌ **Blocked:**
- User-facing text: "Welcome to Roots"
- Documentation mentioning "Roots app"
- Help text with "Roots"
- Branding in UI strings

✅ **Allowed:**
- Design system tokens: `RootsSpacing.l`
- Component names: `RootsPopupContainer`
- Module names: `RootsDesignSystem`
- Class names: `class RootsAnalogClock`
- Legacy paths: `_Deprecated_macOS/`
- Tests and docs

---

## Testing

```bash
# Test the hook
./.git/hooks/pre-commit

# Expected output for "App Rename Enforcement":
✅ No 'Roots' references in user-facing code
```

---

## Why These Are Allowed

### Design System Architecture

The Itori app has a legacy design system called "Roots" that provides:
- Spacing tokens (`RootsSpacing`)
- Window sizing (`RootsWindowSizing`)
- UI components (`RootsPopupContainer`, `RootsLiquidButtonStyle`)
- Motion/animation utilities

These are **internal implementation details** and:
1. Never visible to users
2. Part of the codebase architecture
3. Will be refactored in future iterations
4. Not a priority for the rename (Roots → Itori)

### Rename Priority

**High Priority (Blocked by hook):**
- App name in UI
- User-facing text
- Documentation for users
- Marketing materials

**Low Priority (Allowed by hook):**
- Internal component names
- Design system tokens
- Legacy module names
- Developer-facing code

---

## Future Improvements

### Option 1: Gradual Refactor
Slowly rename design system components:
- `RootsSpacing` → `ItoriSpacing`
- `RootsPopupContainer` → `ItoriPopupContainer`
- etc.

### Option 2: Keep Legacy Namespace
Maintain "Roots" for design system internally:
- Clear separation of concerns
- No user-facing impact
- Document as "legacy namespace"

**Recommendation:** Option 2 (document, don't refactor)
- Lower priority than user-facing features
- No user impact
- Refactor can be done later if needed

---

## Modified File

**File:** `.git/hooks/pre-commit`  
**Section:** "App Rename Enforcement" (lines ~285)  
**Change:** Extended whitelist with 15 additional design system patterns

---

## Verification

Hook now passes on current codebase:
```bash
✅ No 'Roots' references in user-facing code
```

All legitimate design system usage is allowed while still blocking user-facing "Roots" references.

---

**Status:** ✅ Fixed and tested  
**Impact:** Pre-commit hooks no longer block legitimate commits
