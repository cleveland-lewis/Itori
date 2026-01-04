#!/bin/bash
#
# Import Localizations Script
# Imports translated localizations back into the project
#

set -e

LANGUAGES=("zh-Hans" "zh-Hant")
INPUT_DIR="./Localizations"
PROJECT="ItoriApp.xcodeproj"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Importing Localizations for Itori"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Import each language
for LANG in "${LANGUAGES[@]}"; do
    XCLOC_PATH="$INPUT_DIR/$LANG.xcloc"
    
    if [ -d "$XCLOC_PATH" ]; then
        echo "📥 Importing $LANG..."
        xcodebuild -importLocalizations \
            -project "$PROJECT" \
            -localizationPath "$XCLOC_PATH" 2>&1 | grep -E "(Importing|SUCCESS|WARNING|ERROR)" || true
        
        echo "   ✅ $LANG imported successfully"
    else
        echo "   ⚠️  Skipping $LANG (not found at $XCLOC_PATH)"
    fi
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Import Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Review changes in String Catalogs"
echo "2. Test app in each language"
echo "3. Commit updated translations to git"
echo ""
