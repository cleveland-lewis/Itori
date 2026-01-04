#!/bin/bash
# Build verification script for macOS and iOS
# Usage: ./build_all.sh

set -e

cd "$(dirname "$0")"

echo "🔨 Building Itori - macOS and iOS"
echo ""

# macOS Build
echo "📦 Building macOS target..."
xcodebuild -scheme Itori \
  -destination 'platform=macOS' \
  build \
  2>&1 | tee build_macos.log | grep -E "BUILD|error:" | tail -5

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ macOS build succeeded"
else
    echo "❌ macOS build failed - check build_macos.log"
    exit 1
fi

echo ""

# iOS Build  
echo "📱 Building iOS target..."
xcodebuild -scheme Itori \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build \
  2>&1 | tee build_ios.log | grep -E "BUILD|error:" | tail -5

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ iOS build succeeded"
else
    echo "❌ iOS build failed - check build_ios.log"
    exit 1
fi

echo ""
echo "🎉 All builds successful!"
echo ""
echo "Logs saved:"
echo "  - build_macos.log"
echo "  - build_ios.log"
