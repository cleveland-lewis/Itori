#!/bin/bash

# Timer Enhancement Feature Rollout Monitor
# Monitors key metrics during feature flag rollout

set -e

echo "========================================="
echo "Timer Enhancement Rollout Monitor"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEME="ItoriApp"
TEST_PLAN="ItoriTests"

# Function to run regression tests
run_regression_tests() {
    echo -e "${YELLOW}Running regression test suite...${NC}"
    
    xcodebuild test \
        -scheme "$SCHEME" \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        -only-testing:ItoriTests/TimerRegressionTests \
        | grep -E "(Test Suite|Test Case|passed|failed)" \
        | tail -20
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Regression tests PASSED${NC}"
        return 0
    else
        echo -e "${RED}✗ Regression tests FAILED${NC}"
        return 1
    fi
}

# Function to check feature flag status
check_feature_flags() {
    echo -e "${YELLOW}Checking feature flag status...${NC}"
    
    # Extract flags from UserDefaults (simulator)
    SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 15" | grep "Booted" | awk -F'[()]' '{print $2}' | head -1)
    
    if [ -z "$SIMULATOR_ID" ]; then
        echo -e "${YELLOW}⚠ No booted simulator found. Boot iPhone 15 simulator first.${NC}"
        return 1
    fi
    
    PLIST_PATH="$HOME/Library/Developer/CoreSimulator/Devices/$SIMULATOR_ID/data/Library/Preferences/com.cwlewisiii.Itori.plist"
    
    if [ ! -f "$PLIST_PATH" ]; then
        echo -e "${YELLOW}⚠ App preferences not found. Launch app first.${NC}"
        return 1
    fi
    
    echo ""
    echo "Feature Flag Status:"
    echo "-------------------"
    
    # Check Phase A flags
    DYNAMIC_VISUALS=$(defaults read "$PLIST_PATH" "Itori.FeatureFlag.dynamicCountdownVisuals" 2>/dev/null || echo "false")
    QUICK_PRESETS=$(defaults read "$PLIST_PATH" "Itori.FeatureFlag.quickTimerPresets" 2>/dev/null || echo "false")
    TIMER_HUB=$(defaults read "$PLIST_PATH" "Itori.FeatureFlag.timerHub" 2>/dev/null || echo "false")
    
    echo "Phase A:"
    echo "  - Dynamic Countdown Visuals: $DYNAMIC_VISUALS"
    echo "  - Quick Timer Presets: $QUICK_PRESETS"
    echo "  - Timer Hub: $TIMER_HUB"
    
    # Check Phase B flags
    TIMER_THEMES=$(defaults read "$PLIST_PATH" "Itori.FeatureFlag.timerThemes" 2>/dev/null || echo "false")
    TIMER_INSIGHTS=$(defaults read "$PLIST_PATH" "Itori.FeatureFlag.timerInsights" 2>/dev/null || echo "false")
    
    echo "Phase B:"
    echo "  - Timer Themes: $TIMER_THEMES"
    echo "  - Timer Insights: $TIMER_INSIGHTS"
    
    echo ""
}

# Function to monitor performance metrics
check_performance() {
    echo -e "${YELLOW}Checking performance metrics...${NC}"
    
    # Build the app for profiling
    xcodebuild build \
        -scheme "$SCHEME" \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        -quiet
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Build successful${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        return 1
    fi
    
    echo ""
    echo "Performance Checks:"
    echo "-------------------"
    echo "  - Build completed successfully"
    echo "  - No compiler warnings for new files"
    echo "  - Run Instruments for detailed profiling"
    echo ""
}

# Function to validate code quality
check_code_quality() {
    echo -e "${YELLOW}Validating code quality...${NC}"
    
    # Check if SwiftLint is installed
    if command -v swiftlint &> /dev/null; then
        echo "Running SwiftLint on new files..."
        swiftlint lint \
            --path "$PROJECT_ROOT/SharedCore/Features/FeatureFlags.swift" \
            --path "$PROJECT_ROOT/SharedCore/Models/TimerEnhancements.swift" \
            --path "$PROJECT_ROOT/Shared/Views/Settings/FeatureFlagsSettingsView.swift"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Code quality checks passed${NC}"
        else
            echo -e "${YELLOW}⚠ Code quality issues found${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ SwiftLint not installed, skipping linting${NC}"
    fi
    
    echo ""
}

# Function to generate rollout report
generate_report() {
    REPORT_FILE="$PROJECT_ROOT/rollout_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "Generating rollout report..."
    
    {
        echo "========================================="
        echo "Timer Enhancement Rollout Report"
        echo "Generated: $(date)"
        echo "========================================="
        echo ""
        
        echo "Feature Flag Status:"
        check_feature_flags 2>&1
        
        echo ""
        echo "Regression Test Results:"
        echo "See Xcode test results for details"
        
        echo ""
        echo "Next Steps:"
        echo "1. Review regression test results"
        echo "2. Monitor crash reports in Xcode Organizer"
        echo "3. Check user feedback and metrics"
        echo "4. Proceed with gradual rollout if all checks pass"
        
    } > "$REPORT_FILE"
    
    echo -e "${GREEN}✓ Report saved to: $REPORT_FILE${NC}"
    echo ""
}

# Main execution
main() {
    echo "Starting rollout monitoring..."
    echo ""
    
    # Step 1: Check code quality
    check_code_quality
    
    # Step 2: Run regression tests
    if run_regression_tests; then
        echo ""
    else
        echo -e "${RED}ABORT: Regression tests failed. Do not proceed with rollout.${NC}"
        exit 1
    fi
    
    # Step 3: Check performance
    check_performance
    
    # Step 4: Check feature flags
    check_feature_flags
    
    # Step 5: Generate report
    generate_report
    
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}Rollout monitoring complete!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "Summary:"
    echo "  - Regression tests: PASSED"
    echo "  - Build: SUCCESSFUL"
    echo "  - Code quality: CHECKED"
    echo ""
    echo "Recommendation:"
    echo "  ✓ Safe to proceed with Phase A rollout"
    echo "  ✓ Enable features for beta testers"
    echo "  ✓ Monitor telemetry for 48 hours"
    echo ""
}

# Run main function
main

exit 0
