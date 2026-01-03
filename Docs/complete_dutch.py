#!/usr/bin/env python3
import json
from googletrans import Translator
import time

print("Loading localization file...")
with open('SharedCore/DesignSystem/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)

translator = Translator()

# Find keys without Dutch
missing_nl = []
for key, value in data['strings'].items():
    if isinstance(value, dict) and 'localizations' in value:
        if 'nl' not in value['localizations']:
            en_text = key
            if 'en' in value['localizations']:
                en_text = value['localizations']['en']['stringUnit'].get('value', key)
            missing_nl.append((key, en_text))

print(f"Found {len(missing_nl)} keys missing Dutch translation\n")

if len(missing_nl) == 0:
    print("✅ All keys already have Dutch translations!")
    exit(0)

# Translate each one
for i, (key, en_text) in enumerate(missing_nl, 1):
    try:
        if len(en_text.strip()) <= 1 or en_text in ['—', '·', ' ', '\n', '%@', '%d']:
            nl_text = en_text
            print(f"{i:2d}. {key[:50]:50s} → (symbol)")
        else:
            result = translator.translate(en_text, src='en', dest='nl')
            nl_text = result.text
            print(f"{i:2d}. {key[:50]:50s} '{en_text[:25]:25s}' → '{nl_text[:25]}'")
            time.sleep(0.3)
        
        data['strings'][key]['localizations']['nl'] = {
            'stringUnit': {
                'state': 'translated',
                'value': nl_text
            }
        }
        
    except Exception as e:
        print(f"{i:2d}. ⚠️ ERROR on {key}: {e}")
        data['strings'][key]['localizations']['nl'] = {
            'stringUnit': {
                'state': 'needs_review',
                'value': en_text
            }
        }
        time.sleep(0.5)

print("\nSaving updated file...")
with open('SharedCore/DesignSystem/Localizable.xcstrings', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

nl_count = sum(1 for v in data['strings'].values() if isinstance(v, dict) and 'localizations' in v and 'nl' in v['localizations'])
total = len(data['strings'])
print(f"\n✅ Complete! Dutch coverage: {nl_count}/{total} ({nl_count*100//total}%)")
