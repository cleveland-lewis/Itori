#!/bin/bash
# Finnish Translation Runner
# Run this script to complete Finnish translation

echo "🇫🇮 Starting Finnish Translation..."
echo "=================================="
echo ""

cd "$(dirname "$0")"

# Run multiple rounds to maximize coverage
for i in {1..5}; do
    echo "📍 Round $i of 5"
    python3 translate_finnish.py 2>&1 | tee -a finnish_translation.log
    
    # Brief pause between rounds
    if [ $i -lt 5 ]; then
        echo "⏸️  Pausing 10 seconds before next round..."
        sleep 10
    fi
done

echo ""
echo "=================================="
echo "✅ Finnish translation complete!"
echo "Check finnish_translation.log for details"
echo "=================================="

# Show final stats
python3 -c "
import json
with open('SharedCore/DesignSystem/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)

fi_total = 0
fi_translated = 0

for key, value in data['strings'].items():
    if 'fi' in value.get('localizations', {}):
        fi_total += 1
        if value['localizations']['fi']['stringUnit']['state'] == 'translated':
            fi_translated += 1

print(f'\n📊 Final Finnish Localization:')
print(f'   Total: {fi_total}')
print(f'   Translated: {fi_translated} ({fi_translated/fi_total*100:.1f}%)')
"
