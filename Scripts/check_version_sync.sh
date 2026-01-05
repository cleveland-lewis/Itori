#!/bin/bash
# Version Sync Check Script
# Ensures version numbers are consistent across project

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

echo "🔢 Checking version synchronization..."
echo ""

# Check 1: VERSION file exists
if [ ! -f "VERSION" ]; then
    echo -e "${RED}❌ VERSION file not found${NC}"
    ERRORS=$((ERRORS + 1))
    echo "   Create a VERSION file with format: MAJOR.MINOR.PATCH"
    echo ""
else
    VERSION=$(cat VERSION | tr -d '[:space:]')
    echo "📦 VERSION file: $VERSION"
    
    # Validate format
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}❌ VERSION format invalid (expected: MAJOR.MINOR.PATCH)${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✅ VERSION format valid${NC}"
    fi
    echo ""
fi

# Check 2: CHANGELOG.md exists
if [ ! -f "CHANGELOG.md" ]; then
    echo -e "${YELLOW}⚠️  CHANGELOG.md not found${NC}"
    echo "   Consider creating a changelog for release notes"
    echo ""
else
    echo -e "${GREEN}✅ CHANGELOG.md exists${NC}"
    
    # Check if VERSION is mentioned in CHANGELOG
    if [ -f "VERSION" ]; then
        VERSION=$(cat VERSION | tr -d '[:space:]')
        if ! grep -q "$VERSION" CHANGELOG.md; then
            echo -e "${YELLOW}⚠️  Version $VERSION not found in CHANGELOG.md${NC}"
            echo "   Add release notes for current version"
        fi
    fi
    echo ""
fi

# Check 3: Git tag format documentation
if [ ! -f "docs/RELEASE_PROCESS.md" ] && [ ! -f "Docs/RELEASE_PROCESS.md" ]; then
    echo -e "${YELLOW}⚠️  No RELEASE_PROCESS.md documentation${NC}"
    echo "   Document your version/tag/release workflow"
    echo ""
else
    echo -e "${GREEN}✅ Release process documented${NC}"
    echo ""
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Version sync check passed${NC}"
else
    echo -e "${RED}❌ Found $ERRORS version sync issue(s)${NC}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Version sync check FAILED${NC}"
    exit 1
fi

echo -e "${GREEN}Version sync check PASSED${NC}"
exit 0
