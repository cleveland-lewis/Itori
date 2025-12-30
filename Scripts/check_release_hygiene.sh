#!/bin/bash
# Release Hygiene Check Script
# Ensures code meets quality standards before release

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "🔍 Checking release hygiene..."
echo ""

# Check 1: User-visible TODO strings
echo "📝 Checking for TODO strings in UI..."
TODO_IN_UI=$(grep -r "TODO" --include="*.swift" Platforms/ SharedCore/ 2>/dev/null | \
    grep -E 'Text\(|\.label|\.title' | \
    grep -v "Deprecated" | \
    grep -v "// TODO" | \
    grep -v "Test" || true)

if [ -n "$TODO_IN_UI" ]; then
    echo -e "${RED}❌ Found TODO strings in user-visible UI:${NC}"
    echo "$TODO_IN_UI"
    ERRORS=$((ERRORS + 1))
    echo ""
else
    echo -e "${GREEN}✅ No TODO strings in UI${NC}"
fi

# Check 2: Backup files
echo "📦 Checking for backup files..."
BACKUP_FILES=$(find . \( -name "*.backup" -o -name "*.bak" -o -name "*.bak*" \) \
    ! -path "./.git/*" \
    ! -path "./.derivedData/*" \
    ! -path "./build/*" 2>/dev/null || true)

if [ -n "$BACKUP_FILES" ]; then
    echo -e "${RED}❌ Found backup files in repository:${NC}"
    echo "$BACKUP_FILES"
    ERRORS=$((ERRORS + 1))
    echo ""
else
    echo -e "${GREEN}✅ No backup files found${NC}"
fi

# Check 3: fatalError in production code (warning only)
echo "💥 Checking for fatalError in production code..."
FATAL_ERRORS=$(grep -r "fatalError" --include="*.swift" SharedCore/ Platforms/ 2>/dev/null | \
    grep -v "#if DEBUG" | \
    grep -v "Test" | \
    grep -v "_Deprecated" || true)

if [ -n "$FATAL_ERRORS" ]; then
    echo -e "${YELLOW}⚠️  Warning: fatalError found in production code paths:${NC}"
    echo "$FATAL_ERRORS"
    WARNINGS=$((WARNINGS + 1))
    echo ""
else
    echo -e "${GREEN}✅ No fatalError in production code${NC}"
fi

# Check 4: Unwired TODOs in action handlers (warning)
echo "🔘 Checking for unwired TODO actions..."
TODO_ACTIONS=$(grep -r "TODO.*implement" --include="*.swift" Platforms/ SharedCore/ 2>/dev/null | \
    grep -E 'Button\(|\.onTapGesture|action:' | \
    grep -v "Test" | \
    grep -v "Deprecated" || true)

if [ -n "$TODO_ACTIONS" ]; then
    echo -e "${YELLOW}⚠️  Warning: Found TODO in action handlers:${NC}"
    echo "$TODO_ACTIONS"
    WARNINGS=$((WARNINGS + 1))
    echo ""
else
    echo -e "${GREEN}✅ No unwired TODO actions${NC}"
fi

# Check 5: Missing localization keys (basic check)
echo "🌍 Checking for hardcoded strings..."
HARDCODED=$(grep -r 'Text("' --include="*.swift" Platforms/ SharedCore/ 2>/dev/null | \
    grep -v ".localized" | \
    grep -v "Test" | \
    grep -v "Deprecated" | \
    grep -v "Debug" | \
    grep -v "systemImage" | \
    wc -l || true)

if [ "$HARDCODED" -gt 50 ]; then
    echo -e "${YELLOW}⚠️  Warning: Found $HARDCODED potentially non-localized strings${NC}"
    echo "   (This is informational - not all strings need localization)"
    WARNINGS=$((WARNINGS + 1))
    echo ""
else
    echo -e "${GREEN}✅ Localization check passed (found $HARDCODED hardcoded strings)${NC}"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
else
    echo -e "${RED}❌ Found $ERRORS critical issue(s)${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $WARNINGS warning(s)${NC}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Exit with error if critical issues found
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Release hygiene check FAILED${NC}"
    echo "Fix critical issues before releasing."
    exit 1
fi

echo -e "${GREEN}Release hygiene check PASSED${NC}"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Consider addressing warnings before release.${NC}"
fi

exit 0
