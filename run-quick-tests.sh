#!/bin/bash
# Quick smoke tests - Run before every commit (4 minutes)

echo "🏃 Running Quick Smoke Tests (3 tests, ~4 minutes)..."
echo ""

xcodebuild test \
  -project ItoriApp.xcodeproj \
  -scheme ItoriUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ItoriUITests/QuickSmokeTests \
  2>&1 | grep -E "(Test Case|passed|failed|TEST)"

echo ""
echo "✅ Quick tests complete!"
