#!/bin/bash
# App Store Connect Phase 2 Setup Checklist
# Epic 3 - GitHub Issue #419

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  Epic 3 Phase 2: App Store Connect Setup Checklist          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Current Configuration:${NC}"
echo "  Bundle ID: clewisiii.Itori"
echo "  Version: 1.0 (Build 1)"
echo "  Team: V9ZWYKRGTL"
echo "  Product IDs: com.itori.subscription.monthly, .yearly"
echo ""

# Pre-flight checks
echo -e "${YELLOW}═══ PRE-FLIGHT CHECKS ═══${NC}"
echo ""

read -p "✓ Do you have Apple Developer Program membership active? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}⚠ Please activate Apple Developer Program membership first${NC}"
    echo "  Visit: https://developer.apple.com/programs/"
    exit 1
fi

read -p "✓ Can you log into App Store Connect? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}⚠ Please ensure you have App Store Connect access${NC}"
    echo "  Visit: https://appstoreconnect.apple.com"
    exit 1
fi

read -p "✓ Do you have App Manager or Admin role? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠ Warning: You need Admin or App Manager role to create apps${NC}"
fi

echo ""
echo -e "${GREEN}✓ Pre-flight checks passed!${NC}"
echo ""

# Task checklist
echo -e "${YELLOW}═══ PHASE 2 TASK CHECKLIST ═══${NC}"
echo ""

echo "□ Task 2.1: Create App in App Store Connect"
echo "   URL: https://appstoreconnect.apple.com"
echo "   → Click 'My Apps' → '+' → 'New App'"
echo "   → Bundle ID: clewisiii.Itori"
echo "   → Name: Itori"
echo "   → SKU: ITORI-001"
echo ""

echo "□ Task 2.2: Configure Basic Information"
echo "   → Category: Education (Primary), Productivity (Secondary)"
echo "   → Age Rating: 4+"
echo "   → Privacy Policy URL: (need to host online)"
echo ""

echo "□ Task 2.3: Create Subscription Group"
echo "   → Go to Features → In-App Purchases"
echo "   → Create 'Itori Premium' group"
echo ""

echo "□ Task 2.4: Add Monthly Subscription"
echo "   → Product ID: com.itori.subscription.monthly"
echo "   → Price: $4.99/month"
echo "   → Free Trial: 1 week"
echo ""

echo "□ Task 2.5: Add Yearly Subscription"
echo "   → Product ID: com.itori.subscription.yearly"
echo "   → Price: $49.99/year"
echo "   → Free Trial: 1 week"
echo ""

echo "□ Task 2.6: Submit Subscriptions for Review"
echo "   → Add screenshots of subscription paywall"
echo "   → Submit each subscription"
echo ""

echo "□ Task 2.7: Create Sandbox Test Accounts"
echo "   → Users and Access → Sandbox"
echo "   → Create 2-3 test accounts"
echo ""

echo "□ Task 2.8: Test Locally with StoreKit"
echo "   → Xcode: Edit Scheme → StoreKit Configuration"
echo "   → Run on simulator and verify products load"
echo ""

echo ""
echo -e "${BLUE}═══ QUICK LINKS ═══${NC}"
echo "App Store Connect: https://appstoreconnect.apple.com"
echo "Developer Portal: https://developer.apple.com/account"
echo "StoreKit Testing Guide: https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode"
echo ""

echo -e "${GREEN}═══ NEXT STEPS ═══${NC}"
echo "1. Open App Store Connect in your browser"
echo "2. Follow the checklist above"
echo "3. Mark tasks complete in GitHub Issue #419"
echo "4. When done, run: bash Scripts/appstore_phase2_verify.sh"
echo ""

echo "Documentation: EPIC3_PHASE2_APPSTORE_CONNECT_GUIDE.md"
echo ""
