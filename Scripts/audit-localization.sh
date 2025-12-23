#!/bin/bash
# Localization Audit Script
# Finds all potential localization issues in the codebase

echo "🔍 Roots Localization Audit"
echo "================================"
echo ""

# Find all hardcoded Text() strings that should be localized
echo "1️⃣ Hardcoded Text() strings:"
grep -rn "Text(\"" iOS/ macOSApp/ macOS/ SharedCore/ --include="*.swift" \
  | grep -v "NSLocalizedString" \
  | grep -v "comment:" \
  | grep -v "Text(verbatim:" \
  | grep -v "//.*Text" \
  | wc -l
echo ""

# Find potential localization keys being displayed
echo "2️⃣ Potential raw keys (contains dots and underscores):"
grep -rn "Text\|Label\|\.navigationTitle" iOS/ macOSApp/ macOS/ SharedCore/ --include="*.swift" \
  | grep -E "\w+\.\w+\.\w+" \
  | grep -v "NSLocalizedString" \
  | grep -v "//" \
  | head -20
echo ""

# Find NSLocalizedString usage without fallback
echo "3️⃣ NSLocalizedString without comments:"
grep -rn "NSLocalizedString(" iOS/ macOSApp/ macOS/ SharedCore/ --include="*.swift" \
  | grep -v "comment:" \
  | wc -l
echo ""

# Check for enum rawValue being used for UI
echo "4️⃣ Enum .rawValue usage (potential UI text):"
grep -rn "\.rawValue" iOS/ macOSApp/ macOS/ SharedCore/ --include="*.swift" \
  | grep -E "Text\(.*\.rawValue\)|Label.*\.rawValue" \
  | wc -l
echo ""

# Check localization file completeness
echo "5️⃣ Localization files:"
echo "English keys:"
grep -c "=" en.lproj/Localizable.strings 2>/dev/null || echo "0"
echo "Chinese (Simplified) keys:"
grep -c "=" zh-Hans.lproj/Localizable.strings 2>/dev/null || echo "0"
echo "Chinese (Traditional) keys:"
grep -c "=" zh-Hant.lproj/Localizable.strings 2>/dev/null || echo "0"
echo ""

# Find accessibility labels that might not be localized
echo "6️⃣ Accessibility labels to check:"
grep -rn "accessibilityLabel\|accessibilityHint" iOS/ macOSApp/ macOS/ --include="*.swift" \
  | grep -v "NSLocalizedString" \
  | grep -v "localized" \
  | wc -l
echo ""

echo "✅ Audit complete"
echo ""
echo "Action items:"
echo "- Replace hardcoded Text() with Text(localizedKey:)"
echo "- Add missing localization keys to .strings files"
echo "- Localize all accessibility labels"
echo "- Never use .rawValue for UI text"
