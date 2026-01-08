#!/bin/bash
#
# Automated Accessibility Audit
# Checks accessibility issues that can be detected programmatically
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
PASSES=0

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║         Automated Accessibility Audit                        ║"
echo "║         (Complement to Xcode Accessibility Inspector)        ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd "$(git rev-parse --show-toplevel)" || exit 1

# ============================================================================
# 1. BUTTON ACCESSIBILITY LABELS
# ============================================================================
echo "🔍 Checking button accessibility labels..."
MISSING_LABELS=$(grep -r "Button.*Image(systemName:" Platforms/iOS/Scenes --include="*.swift" | \
  grep -v "accessibilityLabel\|accessibilityHidden\|Test" | wc -l | tr -d ' ')

if [ "$MISSING_LABELS" -eq 0 ]; then
    echo -e "${GREEN}✅ All icon buttons have accessibility labels${NC}"
    PASSES=$((PASSES + 1))
else
    echo -e "${RED}❌ Found $MISSING_LABELS icon buttons without labels${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# ============================================================================
# 2. DECORATIVE IMAGES
# ============================================================================
echo "🎨 Checking decorative images..."
DECORATIVE=$(grep -r "Image(systemName:" Platforms/iOS/Scenes --include="*.swift" | \
  grep -E "chevron\.|checkmark\.circle|sparkles|circle\.fill" | \
  grep -v "accessibilityHidden\|accessibilityLabel" | wc -l | tr -d ' ')

if [ "$DECORATIVE" -lt 10 ]; then
    echo -e "${GREEN}✅ Most decorative images properly marked ($DECORATIVE remaining)${NC}"
    PASSES=$((PASSES + 1))
elif [ "$DECORATIVE" -lt 30 ]; then
    echo -e "${YELLOW}⚠️  $DECORATIVE decorative images not marked (acceptable if with text)${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${RED}❌ $DECORATIVE decorative images not marked${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# ============================================================================
# 3. TEXTFIELD LABELS
# ============================================================================
echo "📝 Checking TextField accessibility..."
TEXTFIELD_COUNT=$(grep -r "TextField" Platforms/iOS --include="*.swift" | wc -l | tr -d ' ')
TEXTFIELD_LABELED=$(grep -r "TextField.*\"" Platforms/iOS --include="*.swift" | wc -l | tr -d ' ')

PERCENT=$((TEXTFIELD_LABELED * 100 / (TEXTFIELD_COUNT + 1)))
if [ "$PERCENT" -gt 80 ]; then
    echo -e "${GREEN}✅ $TEXTFIELD_LABELED/$TEXTFIELD_COUNT TextFields have placeholders ($PERCENT%)${NC}"
    PASSES=$((PASSES + 1))
else
    echo -e "${YELLOW}⚠️  Only $TEXTFIELD_LABELED/$TEXTFIELD_COUNT TextFields have placeholders ($PERCENT%)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# ============================================================================
# 4. FIXED FONT SIZES
# ============================================================================
echo "🔤 Checking Dynamic Type support..."
FIXED_FONTS=$(grep -r "\.font(.system(size:" Platforms/iOS SharedCore --include="*.swift" | wc -l | tr -d ' ')
SEMANTIC_FONTS=$(grep -r "\.font(\.body\|\.headline\|\.title\|\.caption" Platforms/iOS SharedCore --include="*.swift" | wc -l | tr -d ' ')

TOTAL_FONTS=$((FIXED_FONTS + SEMANTIC_FONTS))
SEMANTIC_PERCENT=$((SEMANTIC_FONTS * 100 / (TOTAL_FONTS + 1)))

if [ "$SEMANTIC_PERCENT" -gt 70 ]; then
    echo -e "${GREEN}✅ $SEMANTIC_PERCENT% use semantic fonts ($SEMANTIC_FONTS/$TOTAL_FONTS)${NC}"
    PASSES=$((PASSES + 1))
elif [ "$SEMANTIC_PERCENT" -gt 50 ]; then
    echo -e "${YELLOW}⚠️  $SEMANTIC_PERCENT% use semantic fonts ($SEMANTIC_FONTS/$TOTAL_FONTS)${NC}"
    echo "   $FIXED_FONTS fixed font sizes remaining"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${RED}❌ Only $SEMANTIC_PERCENT% use semantic fonts${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# ============================================================================
# 5. ACCESSIBILITY ELEMENT GROUPING
# ============================================================================
echo "🔗 Checking accessibility element grouping..."
GROUPED=$(grep -r "accessibilityElement(children:" Platforms/iOS --include="*.swift" | wc -l | tr -d ' ')

if [ "$GROUPED" -gt 5 ]; then
    echo -e "${GREEN}✅ $GROUPED views use element grouping${NC}"
    PASSES=$((PASSES + 1))
else
    echo -e "${YELLOW}⚠️  Only $GROUPED views use element grouping (optional)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# ============================================================================
# 6. ACCESSIBILITY HINTS
# ============================================================================
echo "💡 Checking accessibility hints..."
HINTS=$(grep -r "accessibilityHint" Platforms/iOS --include="*.swift" | wc -l | tr -d ' ')

if [ "$HINTS" -gt 10 ]; then
    echo -e "${GREEN}✅ $HINTS accessibility hints provided${NC}"
    PASSES=$((PASSES + 1))
else
    echo -e "${YELLOW}⚠️  Only $HINTS accessibility hints (could add more)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# ============================================================================
# 7. ACCESSIBILITY VALUES
# ============================================================================
echo "📊 Checking dynamic accessibility values..."
VALUES=$(grep -r "accessibilityValue" Platforms/iOS --include="*.swift" | wc -l | tr -d ' ')

if [ "$VALUES" -gt 3 ]; then
    echo -e "${GREEN}✅ $VALUES dynamic accessibility values${NC}"
    PASSES=$((PASSES + 1))
else
    echo -e "${YELLOW}⚠️  Only $VALUES dynamic values (consider adding more)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# ============================================================================
# 8. COLOR CONTRAST (Basic Check)
# ============================================================================
echo "🌈 Checking color usage..."
HARDCODED_COLORS=$(grep -r "Color(red:\|Color(hue:\|#[0-9A-Fa-f]{6}" Platforms/iOS --include="*.swift" | \
  grep -v "Test\|Preview" | wc -l | tr -d ' ')

if [ "$HARDCODED_COLORS" -lt 10 ]; then
    echo -e "${GREEN}✅ Mostly using semantic colors ($HARDCODED_COLORS hardcoded)${NC}"
    PASSES=$((PASSES + 1))
elif [ "$HARDCODED_COLORS" -lt 30 ]; then
    echo -e "${YELLOW}⚠️  $HARDCODED_COLORS hardcoded colors found${NC}"
    echo "   Consider using semantic colors for better contrast"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${RED}❌ $HARDCODED_COLORS hardcoded colors (use semantic)${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# ============================================================================
# 9. BUTTON SIZE CHECK (Heuristic)
# ============================================================================
echo "👆 Checking button sizes..."
SMALL_BUTTONS=$(grep -r "\.frame(width:.*height:" Platforms/iOS --include="*.swift" | \
  grep -E "width: [0-3][0-9]|height: [0-3][0-9]" | \
  grep "Button" | wc -l | tr -d ' ')

if [ "$SMALL_BUTTONS" -eq 0 ]; then
    echo -e "${GREEN}✅ No obviously small buttons found${NC}"
    PASSES=$((PASSES + 1))
else
    echo -e "${YELLOW}⚠️  $SMALL_BUTTONS potentially small buttons (< 44pt)${NC}"
    echo "   Verify with Accessibility Inspector"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# ============================================================================
# 10. VOICEOVER COVERAGE
# ============================================================================
echo "🔊 Checking VoiceOver coverage..."
FILES_WITH_ACCESSIBILITY=$(find Platforms/iOS/Scenes -name "*.swift" -exec grep -l \
  "accessibilityLabel\|accessibilityHidden\|accessibilityElement" {} \; | wc -l | tr -d ' ')
TOTAL_SCENE_FILES=$(find Platforms/iOS/Scenes -name "*.swift" | wc -l | tr -d ' ')

COVERAGE=$((FILES_WITH_ACCESSIBILITY * 100 / (TOTAL_SCENE_FILES + 1)))

if [ "$COVERAGE" -gt 60 ]; then
    echo -e "${GREEN}✅ $COVERAGE% of scene files have accessibility ($FILES_WITH_ACCESSIBILITY/$TOTAL_SCENE_FILES)${NC}"
    PASSES=$((PASSES + 1))
elif [ "$COVERAGE" -gt 40 ]; then
    echo -e "${YELLOW}⚠️  $COVERAGE% of scene files have accessibility ($FILES_WITH_ACCESSIBILITY/$TOTAL_SCENE_FILES)${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${RED}❌ Only $COVERAGE% of scene files have accessibility${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📊 Audit Summary"
echo ""
echo -e "  ${GREEN}✅ Passed: $PASSES${NC}"
echo -e "  ${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "  ${RED}❌ Errors: $ERRORS${NC}"
echo ""

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}🎉 Accessibility audit passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. ✅ Run Xcode Accessibility Inspector for visual check"
    echo "  2. ✅ Test with VoiceOver on device"
    echo "  3. ✅ Test Dynamic Type at maximum size"
    echo "  4. ✅ Verify contrast ratios"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Accessibility audit found $ERRORS error(s)${NC}"
    echo ""
    echo "Fix these issues, then:"
    echo "  1. Re-run this audit"
    echo "  2. Run Xcode Accessibility Inspector"
    echo "  3. Test with VoiceOver"
    echo ""
    exit 1
fi
