#!/bin/bash
#
# Export Localizations Script
# Exports all supported languages for translation
#

set -e

LANGUAGES=("en" "zh-Hans" "zh-Hant")
OUTPUT_DIR="./Localizations"
PROJECT="RootsApp.xcodeproj"
SDK="macosx"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Exporting Localizations for Roots"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Export each language
for LANG in "${LANGUAGES[@]}"; do
    echo "📦 Exporting $LANG..."
    xcodebuild -exportLocalizations \
        -project "$PROJECT" \
        -localizationPath "$OUTPUT_DIR" \
        -exportLanguage "$LANG" \
        -sdk "$SDK" 2>&1 | grep -E "(Exporting|xcloc|WARNING|ERROR)" || true
    
    if [ -d "$OUTPUT_DIR/$LANG.xcloc" ]; then
        echo "   ✅ $LANG exported successfully"
    else
        echo "   ❌ $LANG export failed"
        exit 1
    fi
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Export Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Localization files exported to: $OUTPUT_DIR/"
echo ""
echo "Next steps:"
echo "1. Send *.xcloc packages to translators"
echo "2. After translation, use import-localizations.sh"
echo ""
