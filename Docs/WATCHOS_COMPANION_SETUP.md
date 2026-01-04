# watchOS Companion App Setup Guide

## Current Status
✅ watchOS target exists: `ItoriWatch`  
✅ Bundle IDs configured correctly:
- iOS: `clewisiii.Itori`
- watchOS: `clewisiii.Itori.watchkitapp`
✅ `WKCompanionAppBundleIdentifier` set in watchOS Info.plist

## What's Missing
The watchOS app needs to be **embedded** in the iOS app so they install together.

---

## Manual Setup Steps (Recommended)

### Step 1: Open Project in Xcode
```bash
open ItoriApp.xcodeproj
```

### Step 2: Configure iOS Target to Embed watchOS App

1. **Select the Project** in the navigator (not the folder)
2. **Select the "Itori" target** (iOS app)
3. Go to **"General"** tab
4. Scroll down to **"Frameworks, Libraries, and Embedded Content"**
5. Click the **"+"** button
6. In the dialog, switch from "Frameworks" to **"Products"** in the top dropdown
7. You should see **"ItoriWatch.app"** in the list
8. Select it and click **"Add"**
9. In the "Embed" column, change from "Do Not Embed" to **"Embed & Sign"**

### Step 3: Add Target Dependency

1. Still on the **"Itori" target**
2. Go to **"Build Phases"** tab
3. Click **"+"** at the top left
4. Select **"New Copy Files Phase"**
5. Name it **"Embed Watch Content"**
6. Set **"Destination"** to **"Products Directory"** → **"Watch"**
7. Click **"+"** in the files section
8. Select **"ItoriWatch.app"**
9. Click **"Add"**

### Step 4: Verify Deployment Target

1. Select **"ItoriWatch" target**
2. Go to **"Build Settings"** tab
3. Search for **"watchOS Deployment Target"**
4. Set to **watchOS 10.0** or later (currently set to 26.1 which seems too high)
5. Repeat for iOS target - ensure it's **iOS 17.0** or later

---

## Alternative: Automated Script

If you prefer automation, run this script:

```bash
#!/bin/bash

# This script configures the watchOS companion app embedding
# Use at your own risk - Xcode project files are fragile

cd ItoriApp.xcodeproj

# Backup the project file
cp project.pbxproj project.pbxproj.backup.$(date +%Y%m%d_%H%M%S)

# Run Ruby script to modify project.pbxproj
ruby << 'RUBY'
require 'xcodeproj'

project_path = 'ItoriApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find targets
ios_target = project.targets.find { |t| t.name == 'Itori' }
watch_target = project.targets.find { |t| t.name == 'ItoriWatch' }

if ios_target.nil? || watch_target.nil?
  puts "❌ Could not find targets"
  exit 1
end

# Add dependency
ios_target.add_dependency(watch_target)

# Add Copy Files build phase to embed Watch app
copy_phase = ios_target.new_copy_files_build_phase('Embed Watch Content')
copy_phase.dst_subfolder_spec = '16' # Products Directory
copy_phase.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'

# Add watch app as file reference
watch_product_ref = watch_target.product_reference
copy_phase.add_file_reference(watch_product_ref)

# Save project
project.save

puts "✅ Successfully configured watchOS companion app"
RUBY

echo "✅ Configuration complete"
```

**Note**: This script requires the `xcodeproj` Ruby gem:
```bash
sudo gem install xcodeproj
```

---

## Verification Steps

### 1. Build Both Targets
```bash
# Build iOS app (should also build watchOS automatically)
xcodebuild -project ItoriApp.xcodeproj -scheme Itori -configuration Debug build

# Build watchOS directly (optional)
xcodebuild -project ItoriApp.xcodeproj -scheme ItoriWatch -configuration Debug build
```

### 2. Check if watchOS App is Embedded

In Xcode:
1. Select **"Itori" target** → **"Build Phases"**
2. You should see **"Embed Watch Content"** phase
3. It should contain **"ItoriWatch.app"**

Or via command line:
```bash
# After building, check if watchOS app exists in iOS bundle
ls -la ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug-iphonesimulator/Itori.app/Watch/
```

You should see `ItoriWatch.app` inside.

### 3. Run on Simulator

1. In Xcode, select **"Itori" scheme**
2. Choose **"iPhone 15 Pro"** (or similar)
3. Click **"Run"** (⌘R)
4. The iOS app should launch
5. Open the **Watch app** in the Watch simulator (it should auto-pair)

---

## Bundle Identifier Naming Convention

Your current setup follows Apple's convention:

| Platform | Bundle ID | ✅/❌ |
|----------|-----------|-------|
| iOS | `clewisiii.Itori` | ✅ |
| watchOS | `clewisiii.Itori.watchkitapp` | ✅ |
| macOS | `clewisiii.Itori` *(same as iOS)* | ⚠️ Should be different |

**Recommendation**: Change macOS to `clewisiii.Itori.mac` to avoid conflicts.

---

## Troubleshooting

### Error: "Unable to install 'ItoriWatch'"
**Solution**: Make sure the iOS app is installed first. The watch app cannot install independently.

### Error: "No devices available for 'ItoriWatch'"
**Solution**: Pair a watch simulator:
1. **Window** → **Devices and Simulators**
2. Select **"Simulators"** tab
3. Click **"+"** to add a watch simulator
4. Choose **"Apple Watch Series 9"** paired with an iPhone

### Build Error: "Missing required architecture"
**Solution**: Check deployment targets:
- iOS: 17.0+
- watchOS: 10.0+
- Don't set watchOS to 26.1 (that's not a real version)

### watchOS App Shows but Crashes
**Solution**: Check that both apps share the same App Group:
1. Select **"Itori" target** → **"Signing & Capabilities"**
2. Add **"App Groups"**
3. Create group: `group.clewisiii.Itori`
4. Repeat for **"ItoriWatch" target**

---

## Next Steps

After embedding the watchOS app:

1. **Test installation**: Build and run on simulator
2. **Share data**: Implement App Groups for data sharing
3. **Sync state**: Use WatchConnectivity framework
4. **Test handoff**: Implement Handoff between iOS and watchOS
5. **Prepare for App Store**: Ensure both targets have correct provisioning profiles

---

## References

- [Apple Docs: Adding a watchOS Target](https://developer.apple.com/documentation/xcode/adding-a-watch-target-to-your-ios-app)
- [WatchKit App Architecture](https://developer.apple.com/documentation/watchkit/creating-a-watchos-app)
- [WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)

