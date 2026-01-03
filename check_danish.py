#!/usr/bin/env python3
"""
Quick script to verify Danish translation status
"""

import json

def check_danish_status():
    with open('SharedCore/DesignSystem/Localizable.xcstrings', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Count all languages
    all_langs = set()
    da_entries = {'total': 0, 'translated': 0, 'needs_review': 0, 'new': 0}
    
    for key, value in data['strings'].items():
        if 'localizations' in value:
            all_langs.update(value['localizations'].keys())
            
            if 'da' in value['localizations']:
                da_entries['total'] += 1
                state = value['localizations']['da']['stringUnit']['state']
                if state == 'translated':
                    da_entries['translated'] += 1
                elif state == 'needs_review':
                    da_entries['needs_review'] += 1
                elif state == 'new':
                    da_entries['new'] += 1
    
    print("="*60)
    print("DANISH LOCALIZATION STATUS")
    print("="*60)
    print(f"\nSupported Languages ({len(all_langs)}):")
    for lang in sorted(all_langs):
        marker = " ← DANISH" if lang == 'da' else ""
        print(f"  - {lang}{marker}")
    
    print(f"\nDanish Translation Statistics:")
    print(f"  Total entries:     {da_entries['total']}")
    print(f"  Translated:        {da_entries['translated']} ({da_entries['translated']/da_entries['total']*100:.1f}%)")
    print(f"  Needs review:      {da_entries['needs_review']}")
    print(f"  New (untranslated):{da_entries['new']}")
    print("="*60)
    
    if da_entries['translated'] > 900:
        print("✅ Danish localization is COMPLETE and ready for use!")
    else:
        print("⚠️  Danish localization is incomplete.")
        print(f"   Run: python3 translate_danish.py")
    print("="*60)

if __name__ == '__main__':
    check_danish_status()
