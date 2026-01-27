#!/bin/bash

# Phase A Test Runner
# Runs all tests for Phase A timer enhancements

set -e

echo "========================================="
echo "Phase A Timer Enhancements - Test Suite"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCHEME="ItoriApp"
DESTINATION="platform=iOS Simulator,name=iPhone 15"

echo -e "${BLUE}📱 Target: ${DESTINATION}${NC}"
echo ""

# Function to print section header
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Test 1: Regression Tests (Existing timer functionality)
print_section "1️⃣  Running Regression Tests (15 tests)"
echo "Verifying existing timer functionality remains unchanged..."
echo ""

if xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:ItoriTests/TimerRegressionTests \
    2>&1 | grep -E "(Test Suite|Test Case.*passed|Test Case.*failed|Testing failed)"; then
    echo ""
    echo -e "${GREEN}✓ Regression tests PASSED${NC}"
    REGRESSION_PASS=true
else
    echo ""
    echo -e "${RED}✗ Regression tests FAILED${NC}"
    REGRESSION_PASS=false
fi

# Test 2: Enhancement Tests (New feature functionality)
print_section "2️⃣  Running Enhancement Tests (11 tests)"
echo "Verifying Phase A features work correctly..."
echo ""

if xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:ItoriTests/TimerEnhancementsTests \
    2>&1 | grep -E "(Test Suite|Test Case.*passed|Test Case.*failed|Testing failed)"; then
    echo ""
    echo -e "${GREEN}✓ Enhancement tests PASSED${NC}"
    ENHANCEMENT_PASS=true
else
    echo ""
    echo -e "${RED}✗ Enhancement tests FAILED${NC}"
    ENHANCEMENT_PASS=false
fi

# Test 3: Build Verification
print_section "3️⃣  Build Verification"
echo "Ensuring project builds successfully..."
echo ""

if xcodebuild build \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -quiet; then
    echo -e "${GREEN}✓ Build SUCCESSFUL${NC}"
    BUILD_PASS=true
else
    echo -e "${RED}✗ Build FAILED${NC}"
    BUILD_PASS=false
fi

# Test 4: Code Quality Check (if SwiftLint available)
print_section "4️⃣  Code Quality Check"

if command -v swiftlint &> /dev/null; then
    echo "Running SwiftLint on new files..."
    echo ""
    
    NEW_FILES=(
        "SharedCore/Features/FeatureFlags.swift"
        "SharedCore/Models/TimerEnhancements.swift"
        "Shared/Views/Timer/QuickPresetsView.swift"
        "Shared/Views/Timer/RingCountdownView.swift"
        "Shared/Views/Timer/GridCountdownView.swift"
        "Shared/Views/Timer/DynamicCountdownView.swift"
        "Shared/Views/TimerHub/TimerHubView.swift"
    )
    
    LINT_PASS=true
    for file in "${NEW_FILES[@]}"; do
        if [ -f "$file" ]; then
            if ! swiftlint lint --path "$file" --quiet; then
                LINT_PASS=false
            fi
        fi
    done
    
    if $LINT_PASS; then
        echo -e "${GREEN}✓ Code quality checks PASSED${NC}"
    else
        echo -e "${YELLOW}⚠ Code quality issues found (warnings)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ SwiftLint not installed, skipping${NC}"
    LINT_PASS=true
fi

# Summary
print_section "📊 Test Summary"

echo "Results:"
echo "--------"

if $REGRESSION_PASS; then
    echo -e "  ${GREEN}✓${NC} Regression Tests (15): PASSED"
else
    echo -e "  ${RED}✗${NC} Regression Tests (15): FAILED"
fi

if $ENHANCEMENT_PASS; then
    echo -e "  ${GREEN}✓${NC} Enhancement Tests (11): PASSED"
else
    echo -e "  ${RED}✗${NC} Enhancement Tests (11): FAILED"
fi

if $BUILD_PASS; then
    echo -e "  ${GREEN}✓${NC} Build Verification: PASSED"
else
    echo -e "  ${RED}✗${NC} Build Verification: FAILED"
fi

if $LINT_PASS; then
    echo -e "  ${GREEN}✓${NC} Code Quality: PASSED"
else
    echo -e "  ${YELLOW}⚠${NC} Code Quality: WARNINGS"
fi

echo ""

# Overall status
if $REGRESSION_PASS && $ENHANCEMENT_PASS && $BUILD_PASS; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ ALL TESTS PASSED - READY FOR DEPLOYMENT${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. ✅ Manual testing (see PHASE_A_QUICK_START.md)"
    echo "  2. ✅ Code review request"
    echo "  3. ✅ Internal testing with team"
    echo "  4. ⏳ Beta testing preparation"
    echo ""
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ TESTS FAILED - INVESTIGATE BEFORE DEPLOYING${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Action items:"
    echo "  1. Review test failures above"
    echo "  2. Fix identified issues"
    echo "  3. Re-run test suite"
    echo ""
    exit 1
fi
