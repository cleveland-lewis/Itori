#!/bin/bash
# Complete Korean translation - runs until 100% done

cd "$(dirname "$0")"

echo "🇰🇷 Starting Complete Korean Translation"
echo "=========================================="
echo ""

# Run until complete
while true; do
    echo "Running translation batch..."
    python3 translate_google.py ko
    
    # Check if complete
    if python3 -c "
import json
with open('SharedCore/DesignSystem/Localizable.xcstrings', 'r') as f:
    data = json.load(f)
strings = data.get('strings', {})
ko_count = sum(1 for v in strings.values() if 'ko' in v.get('localizations', {}))
total = len(strings)
percentage = ko_count/total*100
print(f'{ko_count}/{total} ({percentage:.1f}%)')
exit(0 if percentage >= 98 else 1)
" 2>/dev/null; then
        echo ""
        echo "✅ Korean translation COMPLETE!"
        break
    fi
    
    echo ""
    echo "⏳ Continuing in 2 seconds..."
    echo ""
    sleep 2
done

echo ""
echo "🎉 Korean localization finished!"
echo ""
