#!/bin/bash
# macOS Voice Control Readiness Check

echo "🎤 macOS Voice Control Readiness Check"
echo "======================================"
echo ""

# Check for unlabeled icon-only buttons
echo "📋 Checking for unlabeled icon-only buttons..."
UNLABELED=$(grep -r "Button.*Image.*systemName" Platforms/macOS --include="*.swift" | \
    grep -v "accessibilityLabel" | \
    grep -v "Label(" | \
    grep -v "//" | \
    wc -l | xargs)

if [ "$UNLABELED" -eq 0 ]; then
    echo "✅ No unlabeled icon-only buttons found"
else
    echo "⚠️  Found $UNLABELED potential unlabeled icon-only buttons"
fi
echo ""

# Check for gesture-only controls
echo "👆 Checking for gesture controls..."
GESTURES=$(grep -r "\.onTapGesture" Platforms/macOS --include="*.swift" | wc -l | xargs)
TRAITS=$(grep -r "\.accessibilityAddTraits(.isButton)" Platforms/macOS --include="*.swift" | wc -l | xargs)

echo "   Total tap gestures: $GESTURES"
echo "   With button traits: $TRAITS"

if [ "$GESTURES" -le "$TRAITS" ]; then
    echo "✅ All tap gestures have accessibility traits"
else
    MISSING=$((GESTURES - TRAITS))
    echo "⚠️  $MISSING tap gestures may need traits (manual verification required)"
fi
echo ""

# Count accessibility features
echo "🏷️  Accessibility Statistics..."
LABELS=$(grep -r "accessibilityLabel" Platforms/macOS --include="*.swift" | wc -l | xargs)
HINTS=$(grep -r "accessibilityHint" Platforms/macOS --include="*.swift" | wc -l | xargs)
TRAITS=$(grep -r "accessibilityAddTraits" Platforms/macOS --include="*.swift" | wc -l | xargs)

echo "   Labels: $LABELS"
echo "   Hints: $HINTS"
echo "   Button traits: $TRAITS"
echo ""

# Summary
echo "======================================"
echo "📊 macOS Voice Control Summary"
echo "======================================"
if [ "$UNLABELED" -eq 0 ] && [ "$GESTURES" -le "$TRAITS" ]; then
    echo "✅ PASS - macOS appears ready for Voice Control"
    echo "   Recommendation: Test on macOS with Voice Control"
else
    echo "⚠️  REVIEW NEEDED"
    if [ "$UNLABELED" -gt 0 ]; then
        echo "   - Unlabeled buttons: $UNLABELED"
    fi
    if [ "$GESTURES" -gt "$TRAITS" ]; then
        echo "   - Gestures without traits: $((GESTURES - TRAITS))"
    fi
fi
echo ""
echo "Next steps:"
echo "1. Test with Voice Control on macOS"
echo "2. System Preferences > Accessibility > Voice Control"
echo "3. Say 'Show numbers' and verify all elements accessible"

