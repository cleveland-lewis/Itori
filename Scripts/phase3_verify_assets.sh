#!/bin/bash
# Phase 3: Asset Verification Script
# Checks that all required assets are ready

set -e

echo "🎨 Epic 3 Phase 3: Asset Verification"
echo "======================================"
echo ""

ISSUES=0

# Check 1: Privacy Policy
echo "📄 Checking Privacy Policy..."
if [ -f "PRIVACY_POLICY.md" ]; then
    echo "✅ Privacy policy file exists"
    echo "⚠️  ACTION REQUIRED: Host at public URL"
    echo "   Options:"
    echo "   1. GitHub Pages: https://[username].github.io/Itori/PRIVACY_POLICY"
    echo "   2. Custom website: https://itori.app/privacy"
    echo ""
else
    echo "❌ Privacy policy missing"
    ((ISSUES++))
fi

# Check 2: Icon Assets
echo "🎨 Checking App Icons..."
if [ -d "itori.icon" ]; then
    echo "✅ Icon directory exists"
    
    # Check for key icon files
    if [ -f "itori.icon/Assets/1024.png" ] || [ -f "itori.icon/Assets/icon_1024x1024.png" ]; then
        echo "✅ App Store icon found"
    else
        echo "⚠️  App Store icon (1024x1024) not found"
        echo "   Check: itori.icon/Assets/ directory"
    fi
else
    echo "❌ Icon directory missing"
    ((ISSUES++))
fi
echo ""

# Check 3: Screenshots
echo "📸 Checking Screenshots..."
if [ -d "Screenshots" ]; then
    echo "✅ Screenshots directory exists"
    
    IPHONE_COUNT=$(find Screenshots/iPhone -type f \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | wc -l | tr -d ' ')
    MAC_COUNT=$(find Screenshots/Mac -type f \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | wc -l | tr -d ' ')
    
    echo "   iPhone screenshots: $IPHONE_COUNT (need 2-10)"
    echo "   Mac screenshots: $MAC_COUNT (need 1-10)"
    
    if [ "$IPHONE_COUNT" -lt 2 ]; then
        echo "⚠️  Need at least 2 iPhone screenshots"
    fi
    
    if [ "$MAC_COUNT" -lt 1 ]; then
        echo "⚠️  Need at least 1 Mac screenshot"
    fi
else
    echo "⚠️  Screenshots directory not found"
    echo "   Create with: mkdir -p Screenshots/{iPhone,Mac}"
fi
echo ""

# Check 4: Metadata Files
echo "📝 Checking Metadata..."

# Check if we have the metadata doc
if [ -f "EPIC3_PHASE3_ASSETS_METADATA.md" ]; then
    echo "✅ Metadata documentation exists"
else
    echo "⚠️  Metadata documentation missing"
fi

# Check README for app description
if [ -f "README.md" ]; then
    echo "✅ README exists (can extract description)"
else
    echo "⚠️  README missing"
fi
echo ""

# Summary
echo "======================================"
echo "📊 PHASE 3 STATUS SUMMARY"
echo "======================================"
echo ""

echo "✅ READY:"
echo "   • Privacy policy document"
echo "   • App icon assets"
echo "   • Metadata templates"
echo ""

echo "⚠️  ACTION REQUIRED:"
echo ""
echo "1. 🌐 HOST PRIVACY POLICY (CRITICAL)"
echo "   • Current: PRIVACY_POLICY.md (local)"
echo "   • Required: Public URL"
echo "   • Options:"
echo "     - GitHub Pages (recommended)"
echo "     - Custom website"
echo "   • Time: 30 minutes"
echo ""

echo "2. 🌐 CREATE SUPPORT PAGE (CRITICAL)"
echo "   • Need public support URL"
echo "   • Options:"
echo "     - Simple HTML page"
echo "     - GitHub wiki"
echo "     - Custom website"
echo "   • Time: 30 minutes"
echo ""

echo "3. 📸 CAPTURE SCREENSHOTS (CRITICAL)"
echo "   • iPhone: Need 2-10 screenshots"
echo "   • Mac: Need 1-10 screenshots"
echo "   • Resolution: Exact sizes required"
echo "   • Time: 1-2 hours"
echo ""

echo "4. ✍️  PREPARE METADATA (CRITICAL)"
echo "   • App description (see template)"
echo "   • Keywords (100 char max)"
echo "   • Subtitle (30 char max)"
echo "   • Promotional text (170 char)"
echo "   • Time: 30 minutes"
echo ""

echo "5. 📝 APP STORE CONNECT DATA ENTRY"
echo "   • Fill all metadata fields"
echo "   • Upload screenshots"
echo "   • Add URLs"
echo "   • Time: 30 minutes"
echo ""

# Checklist
echo "======================================"
echo "📋 PHASE 3 CHECKLIST"
echo "======================================"
echo ""
echo "CRITICAL (Required for Submission):"
echo "[ ] Privacy policy hosted at public URL"
echo "[ ] Support page hosted at public URL"
echo "[ ] 2+ iPhone screenshots (1290x2796)"
echo "[ ] 1+ Mac screenshots (min 1280x800)"
echo "[ ] App description written"
echo "[ ] Keywords finalized (≤100 chars)"
echo "[ ] Category selected (Education)"
echo "[ ] Age rating completed (4+)"
echo ""
echo "RECOMMENDED:"
echo "[ ] Subtitle written (≤30 chars)"
echo "[ ] Promotional text (≤170 chars)"
echo "[ ] 5+ screenshots per platform"
echo "[ ] Screenshots enhanced with text"
echo ""
echo "OPTIONAL:"
echo "[ ] App preview video"
echo "[ ] Marketing URL"
echo "[ ] Localized metadata"
echo ""

# Next steps
echo "======================================"
echo "🚀 NEXT STEPS"
echo "======================================"
echo ""
echo "1. Review full documentation:"
echo "   open EPIC3_PHASE3_ASSETS_METADATA.md"
echo ""
echo "2. Host privacy policy (GitHub Pages recommended)"
echo ""
echo "3. Create support page"
echo ""
echo "4. Capture screenshots:"
echo "   • Run app in Simulator (iPhone 15 Pro Max)"
echo "   • Cmd+S to save screenshots"
echo "   • Run app on Mac and capture windows"
echo ""
echo "5. Use metadata templates from documentation"
echo ""
echo "6. Fill App Store Connect"
echo ""

# Estimate
echo "======================================"
echo "⏱️  TIME ESTIMATE"
echo "======================================"
echo ""
echo "Fast track: 2.5 hours"
echo "Polished: 4.5 hours"
echo ""
echo "Breakdown:"
echo "• Privacy/Support hosting: 30-60 mins"
echo "• Screenshots: 1-2 hours"
echo "• Metadata writing: 30-60 mins"
echo "• App Store Connect: 30 mins"
echo ""

if [ $ISSUES -eq 0 ]; then
    echo "✅ All checks passed! Ready to execute Phase 3."
    exit 0
else
    echo "⚠️  Found $ISSUES issue(s) to address."
    exit 1
fi
