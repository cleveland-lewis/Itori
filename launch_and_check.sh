#!/bin/bash

echo "=== Attempting to launch app and capture logs ==="

# Kill any existing instance
pkill -9 -f "Itori" || true

# Build and install
echo "Building..."
xcodebuild build -scheme Itori \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -quiet

# Get the app path
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/ItoriApp-*/Build/Products/Debug-iphonesimulator -name "Itori.app" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ App not found in DerivedData"
    exit 1
fi

echo "✅ Found app at: $APP_PATH"

# Get simulator UDID
SIM_UDID=$(xcrun simctl list devices | grep "iPhone 17 Pro" | grep -v "unavailable" | head -1 | grep -oE "\([A-F0-9-]+\)" | tr -d '()')

echo "Simulator UDID: $SIM_UDID"

# Install app
echo "Installing app..."
xcrun simctl install "$SIM_UDID" "$APP_PATH"

# Launch and capture logs
echo "Launching app..."
xcrun simctl launch --console "$SIM_UDID" clewisiii.Itori 2>&1 | head -50

