# watchOS Companion App Setup Guide

## Current Status
✅ watchOS target exists: `RootsWatch`  
✅ Bundle IDs configured correctly:
- iOS: `clewisiii.Roots`
- watchOS: `clewisiii.Roots.watchkitapp`
✅ `WKCompanionAppBundleIdentifier` set in watchOS Info.plist

## What's Missing
The watchOS app needs to be **embedded** in the iOS app so they install together.

---

## Manual Setup Steps (Recommended)

### Step 1: Open Project in Xcode
```bash
open RootsApp.xcodeproj
```

### Step 2: Configure iOS Target to Embed watchOS App

1. **Select the Project** in the navigator (not the folder)
2. **Select the "Roots" target** (iOS app)
3. Go to **"General"** tab
4. Scroll down to **"Frameworks, Libraries, and Embedded Content"**
5. Click the **"+"** button
6. In the dialog, switch from "Frameworks" to **"Products"** in the top dropdown
7. You should see **"RootsWatch.app"** in the list
8. Select it and click **"Add"**
9. In the "Embed" column, change from "Do Not Embed" to **"Embed & Sign"**

### Step 3: Add Target Dependency

1. Still on the **"Roots" target**
2. Go to **"Build Phases"** tab
3. Click **"+"** at the top left
4. Select **"New Copy Files Phase"**
5. Name it **"Embed Watch Content"**
6. Set **"Destination"** to **"Products Directory"** → **"Watch"**
7. Click **"+"** in the files section
8. Select **"RootsWatch.app"**
9. Click **"Add"**

### Step 4: Verify Deployment Target

1. Select **"RootsWatch" target**
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

cd RootsApp.xcodeproj

# Backup the project file
cp project.pbxproj project.pbxproj.backup.$(date +%Y%m%d_%H%M%S)

# Run Ruby script to modify project.pbxproj
ruby << 'RUBY'
require 'xcodeproj'

project_path = 'RootsApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find targets
ios_target = project.targets.find { |t| t.name == 'Roots' }
watch_target = project.targets.find { |t| t.name == 'RootsWatch' }

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
xcodebuild -project RootsApp.xcodeproj -scheme Roots -configuration Debug build

# Build watchOS directly (optional)
xcodebuild -project RootsApp.xcodeproj -scheme RootsWatch -configuration Debug build
```

### 2. Check if watchOS App is Embedded

In Xcode:
1. Select **"Roots" target** → **"Build Phases"**
2. You should see **"Embed Watch Content"** phase
3. It should contain **"RootsWatch.app"**

Or via command line:
```bash
# After building, check if watchOS app exists in iOS bundle
ls -la ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug-iphonesimulator/Roots.app/Watch/
```

You should see `RootsWatch.app` inside.

### 3. Run on Simulator

1. In Xcode, select **"Roots" scheme**
2. Choose **"iPhone 15 Pro"** (or similar)
3. Click **"Run"** (⌘R)
4. The iOS app should launch
5. Open the **Watch app** in the Watch simulator (it should auto-pair)

---

## Bundle Identifier Naming Convention

Your current setup follows Apple's convention:

| Platform | Bundle ID | ✅/❌ |
|----------|-----------|-------|
| iOS | `clewisiii.Roots` | ✅ |
| watchOS | `clewisiii.Roots.watchkitapp` | ✅ |
| macOS | `clewisiii.Roots` *(same as iOS)* | ⚠️ Should be different |

**Recommendation**: Change macOS to `clewisiii.Roots.mac` to avoid conflicts.

---

## Troubleshooting

### Error: "Unable to install 'RootsWatch'"
**Solution**: Make sure the iOS app is installed first. The watch app cannot install independently.

### Error: "No devices available for 'RootsWatch'"
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
1. Select **"Roots" target** → **"Signing & Capabilities"**
2. Add **"App Groups"**
3. Create group: `group.clewisiii.Roots`
4. Repeat for **"RootsWatch" target**

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

