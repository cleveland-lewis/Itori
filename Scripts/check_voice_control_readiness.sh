#!/bin/bash
# Voice Control Readiness Check
# Scans iOS code for potential Voice Control issues

echo "🎤 Voice Control Readiness Check"
echo "=================================="
echo ""

# Check for icon-only buttons without labels
echo "📋 Checking for unlabeled icon-only buttons..."
UNLABELED=$(grep -r "Button.*Image.*systemName" Platforms/iOS --include="*.swift" | \
    grep -v "accessibilityLabel" | \
    grep -v "Text(" | \
    grep -v "Label(" | \
    grep -v "//" | \
    wc -l | xargs)

if [ "$UNLABELED" -eq 0 ]; then
    echo "✅ No unlabeled icon-only buttons found"
else
    echo "⚠️  Found $UNLABELED potential unlabeled icon-only buttons"
    echo "   Review these manually:"
    grep -rn "Button.*Image.*systemName" Platforms/iOS --include="*.swift" | \
        grep -v "accessibilityLabel" | \
        grep -v "Text(" | \
        grep -v "Label(" | \
        grep -v "//" | \
        head -10
fi
echo ""

# Check for gesture-only controls
echo "👆 Checking for gesture-only controls..."
GESTURES=$(grep -r "\.gesture\|\.onTapGesture\|\.onLongPressGesture" Platforms/iOS --include="*.swift" | \
    grep -v "accessibilityElement\|accessibilityAction" | \
    wc -l | xargs)

if [ "$GESTURES" -eq 0 ]; then
    echo "✅ No gesture-only controls found"
else
    echo "⚠️  Found $GESTURES potential gesture controls"
    echo "   Verify these have button alternatives"
fi
echo ""

# Count total accessibility labels
echo "🏷️  Accessibility Statistics..."
LABELS=$(grep -r "accessibilityLabel" Platforms/iOS --include="*.swift" | wc -l | xargs)
HINTS=$(grep -r "accessibilityHint" Platforms/iOS --include="*.swift" | wc -l | xargs)
HIDDEN=$(grep -r "accessibilityHidden" Platforms/iOS --include="*.swift" | wc -l | xargs)

echo "   Labels: $LABELS"
echo "   Hints: $HINTS"
echo "   Hidden elements: $HIDDEN"
echo ""

# Check for custom interactive views
echo "🎯 Checking custom interactive views..."
CUSTOM=$(grep -r "\.onTapGesture" Platforms/iOS --include="*.swift" | \
    grep -v "Button\|List\|ForEach" | \
    wc -l | xargs)

if [ "$CUSTOM" -gt 0 ]; then
    echo "⚠️  Found $CUSTOM custom tap gestures"
    echo "   Verify these have .accessibilityElement() and .accessibilityAddTraits(.isButton)"
else
    echo "✅ No problematic custom tap gestures found"
fi
echo ""

# Summary
echo "=================================="
echo "📊 Voice Control Readiness Summary"
echo "=================================="
if [ "$UNLABELED" -eq 0 ] && [ "$GESTURES" -lt 10 ]; then
    echo "✅ PASS - App appears ready for Voice Control"
    echo "   Recommendation: Test on device to verify"
else
    echo "⚠️  REVIEW NEEDED"
    echo "   - Check unlabeled buttons: $UNLABELED issues"
    echo "   - Review gesture controls: $GESTURES locations"
    echo "   - Estimate: 1-2 hours to resolve"
fi
echo ""
echo "Next steps:"
echo "1. Review any warnings above"
echo "2. Test with Voice Control on device"
echo "3. Run: Settings > Accessibility > Voice Control"
echo "4. Say 'Show numbers' and verify all elements accessible"

