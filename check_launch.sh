#!/bin/bash
# Check for common launch issues

echo "=== Checking for runtime issues ==="

# Check if FeedbackManager import is missing
echo -e "\n1. Checking FeedbackManager import..."
grep -n "import.*FeedbackManager\|@testable import Itori" Platforms/iOS/Scenes/IOSCorePages.swift | head -5

# Check if FeedbackManager is defined
echo -e "\n2. Checking if FeedbackManager exists..."
if [ -f "SharedCore/Services/FeedbackManager.swift" ]; then
    echo "✅ FeedbackManager.swift exists"
else
    echo "❌ FeedbackManager.swift NOT FOUND"
fi

# Check for any @MainActor issues
echo -e "\n3. Checking for MainActor issues..."
grep -n "FeedbackManager" SharedCore/Services/FeedbackManager.swift | head -3

# Check the app entry point
echo -e "\n4. Checking app entry point..."
ls -la Platforms/iOS/App/*.swift

# Check for any compilation issues in modified files
echo -e "\n5. Checking modified files compile independently..."
swiftc -typecheck Platforms/iOS/Scenes/IOSCorePages.swift \
  -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0-simulator 2>&1 | head -10 || echo "Needs full context"

