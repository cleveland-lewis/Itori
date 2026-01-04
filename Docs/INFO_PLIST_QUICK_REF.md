# Quick Reference: Info.plist Configuration

## Add This to Your Info.plist

Copy and paste this into your Info.plist file (before the closing `</dict>`):

```xml
<!-- Intelligent Scheduling Background Execution -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.clevelandlewis.Itori.intelligentScheduling</string>
</array>
```

## How to Add in Xcode

### Method 1: Property List Editor (Easier)

1. Open Info.plist in Xcode
2. Click the **+** button at the root level
3. Add key: `UIBackgroundModes`
4. Type: Array
5. Click the disclosure arrow to expand
6. Click the **+** inside the array
7. Add item 0: `fetch` (String)
8. Add item 1: `processing` (String)

9. Click the **+** button at root level again
10. Add key: `BGTaskSchedulerPermittedIdentifiers`
11. Type: Array
12. Add item 0: `com.clevelandlewis.Itori.intelligentScheduling` (String)

### Method 2: Source Code (Faster)

1. Right-click Info.plist → Open As → Source Code
2. Find the closing `</dict>` tag (near the end)
3. Paste the XML above BEFORE that closing tag
4. Save

## Verify It's Correct

Your Info.plist should look like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... existing keys ... -->
    
    <!-- ADD THIS -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>processing</string>
    </array>
    
    <key>BGTaskSchedulerPermittedIdentifiers</key>
    <array>
        <string>com.clevelandlewis.Itori.intelligentScheduling</string>
    </array>
    <!-- END ADD -->
    
</dict>
</plist>
```

## Also Enable in Xcode UI

1. Select **Itori iOS** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Background Modes**
5. Check boxes:
   - ☑️ Background fetch
   - ☑️ Background processing

## Test It Works

```bash
# Run app
# Create overdue task
# Background app
# In Terminal, run:

xcrun simctl spawn booted launchctl debug system/com.apple.itori \
  --background-task-identifier com.clevelandlewis.Itori.intelligentScheduling

# Check console for "Running intelligent scheduling background task"
```

## That's It!

After adding these, your app will run intelligent scheduling in the background.

✅ Continuous grade monitoring
✅ Automatic task rescheduling
✅ Background notifications
✅ Works even when app is closed
