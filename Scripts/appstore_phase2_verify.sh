#!/bin/bash
# Verify Phase 2 completion
# Epic 3 - GitHub Issue #419

echo "═══════════════════════════════════════════════════════════"
echo "  Phase 2 Verification Script"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check StoreKit configuration
echo "Checking StoreKit configuration..."
if [ -f "Config/ItoriSubscriptions.storekit" ]; then
    echo "✓ StoreKit configuration file exists"
    
    # Check product IDs
    if grep -q "com.itori.subscription.monthly" Config/ItoriSubscriptions.storekit; then
        echo "✓ Monthly subscription product ID found"
    else
        echo "✗ Monthly subscription product ID missing"
    fi
    
    if grep -q "com.itori.subscription.yearly" Config/ItoriSubscriptions.storekit; then
        echo "✓ Yearly subscription product ID found"
    else
        echo "✗ Yearly subscription product ID missing"
    fi
else
    echo "✗ StoreKit configuration file not found"
fi

echo ""

# Check entitlements
echo "Checking entitlements..."
for file in Config/Itori-iOS.entitlements Config/Itori.entitlements Config/Itori-watchOS.entitlements; do
    if [ -f "$file" ]; then
        if grep -q "com.apple.developer.in-app-payments" "$file"; then
            echo "✓ $file has In-App Purchase entitlement"
        else
            echo "✗ $file missing In-App Purchase entitlement"
        fi
    fi
done

echo ""

# Check SubscriptionManager
echo "Checking SubscriptionManager..."
if grep -q "com.itori.subscription.monthly" SharedCore/Services/SubscriptionManager.swift; then
    echo "✓ SubscriptionManager has correct product IDs"
else
    echo "✗ SubscriptionManager has incorrect product IDs"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Manual Verification Checklist:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "□ App created in App Store Connect"
echo "□ Subscription group 'Itori Premium' created"
echo "□ Monthly subscription added ($4.99)"
echo "□ Yearly subscription added ($49.99)"
echo "□ Subscriptions submitted for review"
echo "□ Sandbox test accounts created"
echo "□ Tested locally in simulator with StoreKit"
echo "□ Products load successfully (2 shown)"
echo "□ Purchase flow works in test mode"
echo ""
echo "If all checks pass, Phase 2 is complete!"
echo "Next: Phase 3 - Assets & Metadata"
echo ""
