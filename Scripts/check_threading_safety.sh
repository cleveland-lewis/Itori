#!/bin/bash
# Threading Safety Check Script
# Detects potential concurrency issues

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "🧵 Checking threading safety..."
echo ""

# Check 1: @Published without @MainActor in UI-accessed classes
echo "🔒 Checking @Published properties on MainActor..."

# Find classes with @Published that should be @MainActor
PUBLISHED_CLASSES=$(grep -r "@Published" --include="*.swift" SharedCore/State/ 2>/dev/null | \
    cut -d: -f1 | sort -u)

for file in $PUBLISHED_CLASSES; do
    # Check if file has @MainActor class annotation
    HAS_MAINACTOR=$(grep -E "^@MainActor\s+(final\s+)?class|^@MainActor\s+public\s+(final\s+)?class" "$file" || true)
    
    if [ -z "$HAS_MAINACTOR" ]; then
        CLASS_NAME=$(basename "$file" .swift)
        echo -e "${YELLOW}⚠️  $CLASS_NAME has @Published but no @MainActor${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

if [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All @Published classes use @MainActor${NC}"
fi
echo ""

# Check 2: MainActor.run wrapping (informational)
echo "🔄 Checking for manual MainActor.run usage..."
MANUAL_MAIN_ACTOR=$(grep -r "MainActor.run\|await MainActor" --include="*.swift" SharedCore/ Platforms/ 2>/dev/null | \
    grep -v "Test" | \
    wc -l || echo "0")

if [ "$MANUAL_MAIN_ACTOR" -gt 10 ]; then
    echo -e "${YELLOW}⚠️  Found $MANUAL_MAIN_ACTOR manual MainActor.run calls${NC}"
    echo "   (Consider using @MainActor annotations instead)"
    echo ""
else
    echo -e "${GREEN}✅ Limited manual MainActor.run usage ($MANUAL_MAIN_ACTOR calls)${NC}"
    echo ""
fi

# Check 3: DispatchQueue.main in SwiftUI code (warning)
echo "⚠️  Checking for legacy DispatchQueue.main..."
DISPATCH_MAIN=$(grep -r "DispatchQueue.main" --include="*.swift" SharedCore/Views/ SharedCore/State/ Platforms/*/Scenes/ 2>/dev/null | \
    grep -v "Test" | \
    wc -l || echo "0")

if [ "$DISPATCH_MAIN" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $DISPATCH_MAIN DispatchQueue.main usage(s)${NC}"
    echo "   (Consider migrating to async/await + @MainActor)"
    WARNINGS=$((WARNINGS + 1))
    echo ""
else
    echo -e "${GREEN}✅ No legacy DispatchQueue.main in UI code${NC}"
    echo ""
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ No critical threading issues found${NC}"
else
    echo -e "${RED}❌ Found $ERRORS threading error(s)${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $WARNINGS threading warning(s)${NC}"
    echo "   Review these for potential race conditions"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Threading safety check FAILED${NC}"
    exit 1
fi

echo -e "${GREEN}Threading safety check PASSED${NC}"
exit 0
