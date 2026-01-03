# Xcode Build Button Missing - Troubleshooting Guide

## Issue
Build button (▶️ Play button) is not showing in Xcode toolbar.

## Common Causes & Solutions

### 1. No Scheme Selected
**Most Common Issue**

Look at the toolbar near the top-left. You should see:
```
[Scheme Name] > [Destination]
```

If it says "No Scheme" or is empty:

**Solution:**
1. Click on the scheme selector (next to the stop button)
2. Select a scheme from the dropdown:
   - **Itori** (for macOS)
   - **Itori** (for iOS/iPad)
   - **ItoriWatch** (for watchOS)

### 2. Project/Workspace Not Loaded Properly

**Check if:**
- The project navigator (left sidebar) shows your files
- You see "ItoriApp.xcodeproj" in the navigator

**Solution:**
1. Close Xcode completely (Cmd+Q)
2. In Finder, navigate to `/Desktop/Itori/`
3. Double-click `ItoriApp.xcodeproj` to open it
4. Wait for Xcode to fully index the project

### 3. Wrong File/Tab Open

If you're viewing a file outside the project:

**Solution:**
- Make sure you opened the `.xcodeproj` file, not just individual files
- Check that the file navigator shows your project structure

### 4. Toolbar Customization

The toolbar might be customized or hidden:

**Solution:**
1. Right-click on the toolbar area
2. Select "Customize Toolbar..."
3. Drag the "Run" button back if missing
4. Or reset to defaults

### 5. Schemes Not Visible

**Solution:**
1. Go to Menu: **Product > Scheme > Manage Schemes...**
2. Make sure these schemes are checked as "Shared":
   - Itori
   - ItoriTests
   - ItoriUITests
   - ItoriWatch
3. Close and reopen the project

### 6. Clean and Rebuild Project Database

**Solution:**
```
1. Close Xcode
2. Delete derived data manually or via:
   Xcode > Settings > Locations > Click arrow next to DerivedData
   Delete the Itori folder
3. Reopen project
```

## Quick Fix Steps

Try these in order:

1. **Restart Xcode** (Cmd+Q, then reopen)
2. **Select a Scheme**: Click scheme selector → Choose "Itori"
3. **Select a Destination**: Click destination selector → Choose "My Mac" or a simulator
4. **Clean Build Folder**: Menu → Product → Clean Build Folder (Cmd+Shift+K)
5. **Close & Reopen Project**

## What You Should See

When working correctly, the toolbar should show:
```
[▶️] [⏹] [Itori ▾] > [My Mac ▾]
      ^            ^
   Build/Run    Scheme   Destination
```

## Still Not Working?

Check if:
- The scheme selector shows "No Scheme" - means schemes weren't loaded
- The navigator shows files - means project loaded successfully
- You see the project name in window title - confirms correct project opened

## Screenshot Your Xcode Window

If none of these work, take a screenshot of your entire Xcode window so I can see:
- Top toolbar
- Left navigator
- Scheme selector area
- Any error messages
