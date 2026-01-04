#!/bin/bash

# Localization Audit Script
# Identifies hardcoded UI strings that need localization

OUTPUT_FILE="localization-audit.txt"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$REPO_ROOT"

# Create output file
{
echo "==================================="
echo "Itori Localization Audit"
echo "==================================="
echo ""
echo "Generated: $(date)"
echo ""

echo "## 1. HARDCODED STRINGS IN TEXT() CALLS"
echo "========================================"
echo ""

# Find all Text("...") patterns
echo "### Text(...) instances:"
echo ""
grep -rn 'Text("' --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | \
  grep -v "NSLocalizedString" | \
  grep -v "//" | \
  head -200

echo ""
echo "Total Text() instances with potential hardcoded strings:"
grep -r 'Text("' --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | \
  grep -v "NSLocalizedString" | \
  grep -v "//" | \
  wc -l

echo ""
echo ""

echo "## 2. STRINGS ALREADY LOCALIZED"
echo "================================"
echo ""

echo "### NSLocalizedString usage:"
echo ""
grep -rn "NSLocalizedString" --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | head -50

echo ""
echo "Total NSLocalizedString instances:"
grep -r "NSLocalizedString" --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | wc -l

echo ""
echo ""

echo "## 3. LABEL() CALLS WITH HARDCODED STRINGS"
echo "==========================================="
echo ""

grep -rn 'Label("' --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | \
  grep -v "NSLocalizedString" | \
  head -100

echo ""
echo "Total Label() instances:"
grep -r 'Label("' --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | \
  grep -v "NSLocalizedString" | \
  wc -l

echo ""
echo ""

echo "## 4. BUTTON() CALLS WITH HARDCODED STRINGS"
echo "============================================"
echo ""

grep -rn 'Button("' --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | \
  grep -v "NSLocalizedString" | \
  head -100

echo ""
echo "Total Button() instances:"
grep -r 'Button("' --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | \
  grep -v "NSLocalizedString" | \
  wc -l

echo ""
echo ""

echo "## 5. FILES BY SECTION (Priority Order)"
echo "========================================"
echo ""

echo "### Dashboard:"
find Platforms/macOS/Scenes -name "*Dashboard*" -type f 2>/dev/null
echo ""

echo "### Calendar:"
find Platforms/macOS/Scenes Platforms/macOS/Views -name "*Calendar*" -type f 2>/dev/null
echo ""

echo "### Assignments:"
find Platforms/macOS/Scenes Platforms/macOS/Views -name "*Assignment*" -type f 2>/dev/null
echo ""

echo "### Timer:"
find Platforms/macOS/Scenes Platforms/macOS/Views -name "*Timer*" -type f 2>/dev/null
echo ""

echo "### Settings:"
find Platforms/macOS/Scenes Platforms/macOS/Views -name "*Settings*" -type f 2>/dev/null
echo ""

echo ""
echo "## 6. SUMMARY"
echo "============="
echo ""

TOTAL_TEXT=$(grep -r 'Text("' --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | grep -v "NSLocalizedString" | grep -v "//" | wc -l)
TOTAL_LOCALIZED=$(grep -r "NSLocalizedString" --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | wc -l)
TOTAL_LABEL=$(grep -r 'Label("' --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | grep -v "NSLocalizedString" | wc -l)
TOTAL_BUTTON=$(grep -r 'Button("' --include="*.swift" Platforms/macOS/ SharedCore/ Platforms/iOS/ 2>/dev/null | grep -v "NSLocalizedString" | wc -l)

echo "Hardcoded Text() calls:      $TOTAL_TEXT"
echo "Already localized:           $TOTAL_LOCALIZED"
echo "Hardcoded Label() calls:     $TOTAL_LABEL"
echo "Hardcoded Button() calls:    $TOTAL_BUTTON"
echo ""
TOTAL_NEEDS_WORK=$((TOTAL_TEXT + TOTAL_LABEL + TOTAL_BUTTON))
echo "Total strings needing work:  $TOTAL_NEEDS_WORK"
echo ""

echo ""
echo "## 7. RECOMMENDED PRIORITY"
echo "=========================="
echo ""
echo "1. Dashboard (high visibility, user entry point)"
echo "2. Calendar (core feature)"
echo "3. Assignments (core feature)"
echo "4. Timer/Focus (core feature)"
echo "5. Settings (lower priority)"
echo ""

echo "==================================="
echo "Audit Complete!"
echo "==================================="
} > "$OUTPUT_FILE"

# Print completion message
echo ""
echo "✅ Report saved to: $OUTPUT_FILE"
echo ""
echo "To view the report:"
echo "  cat $OUTPUT_FILE"
