# Subscription Settings Window Skew Fix

## Issue
The Subscription settings page was causing the settings window to skew/overlap with the calendar view in the background. The window appeared transparent and improperly sized.

## Root Cause
The `MacOSSubscriptionView` had two problems:
1. **Double ScrollView**: It contained its own `ScrollView` while being embedded in another `ScrollView` from `RootsSettingsWindow`
2. **No background**: Missing background color caused transparency issues
3. **Wrong frame constraints**: Used `minWidth/minHeight` instead of proper expansion

## File Modified
`Platforms/macOS/Views/MacOSSubscriptionView.swift` (lines 14-34)

## Changes Made

**Before:**
```swift
var body: some View {
    ScrollView {
        VStack(spacing: 32) {
            // ... content
        }
        .frame(maxWidth: 600)
        .padding(40)
    }
    .frame(minWidth: 700, minHeight: 600)
    .alert(...)
}
```

**After:**
```swift
var body: some View {
    VStack(spacing: 32) {
        // ... content
    }
    .frame(maxWidth: 600)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .alert(...)
}
```

## What Was Fixed

1. ✅ **Removed inner ScrollView** - RootsSettingsWindow already provides scrolling
2. ✅ **Added proper background** - Uses `.windowBackgroundColor` for native look
3. ✅ **Fixed frame expansion** - Now properly fills available space
4. ✅ **Removed padding** - Parent view handles padding via ScrollView

## Why This Works

The settings window architecture is:
```
RootsSettingsWindow
  └─ ScrollView (outer)
       └─ VStack
            └─ switch selection {
                 case .subscription:
                   MacOSSubscriptionView (inner - NO SCROLLVIEW NEEDED)
               }
```

By removing the inner ScrollView:
- Prevents scroll view nesting conflicts
- Allows proper layout within parent container
- Maintains consistent scroll behavior with other settings pages

## Testing
Verify on macOS:
1. Open Settings (⌘,)
2. Click "Subscription" in sidebar
3. Confirm content displays properly without skewing
4. Verify background is opaque (no calendar bleed-through)
5. Test scrolling works smoothly
6. Check other settings pages still work correctly

## Date
2026-01-06
