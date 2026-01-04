#!/bin/bash
set -e

echo "🔨 Building ItoriWatch..."
xcodebuild -project ItoriApp.xcodeproj -scheme ItoriWatch -sdk watchsimulator build

WATCH_APP=$(find ~/Library/Developer/Xcode/DerivedData/ItoriApp-*/Build/Products/Debug-watchsimulator/ItoriWatch.app -maxdepth 0 2>/dev/null | head -1)

if [ ! -f "$WATCH_APP/Info.plist" ]; then
    echo "❌ Watch app not found"
    exit 1
fi

echo "✅ Watch app built"
echo "🔧 Fixing Info.plist..."

# Remove the legacy key
/usr/libexec/PlistBuddy -c "Delete :WKWatchKitApp" "$WATCH_APP/Info.plist" 2>/dev/null && \
    echo "✅ Removed WKWatchKitApp key" || \
    echo "⚠️  Key not found (already removed?)"

# Verify
echo ""
echo "📋 Current WK keys:"
plutil -p "$WATCH_APP/Info.plist" | grep "WK"

echo ""
echo "✅ Watch app ready!"
echo ""
echo "Now build iOS app:"
echo "  xcodebuild -project ItoriApp.xcodeproj -scheme Itori -sdk iphonesimulator build"
