#!/usr/bin/env python3
"""
Quick script to verify Swahili translation status
"""

import json

def check_swahili_status():
    with open('SharedCore/DesignSystem/Localizable.xcstrings', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Count all languages
    all_langs = set()
    sw_entries = {'total': 0, 'translated': 0, 'needs_review': 0, 'new': 0}
    
    for key, value in data['strings'].items():
        if 'localizations' in value:
            all_langs.update(value['localizations'].keys())
            
            if 'sw' in value['localizations']:
                sw_entries['total'] += 1
                state = value['localizations']['sw']['stringUnit']['state']
                if state == 'translated':
                    sw_entries['translated'] += 1
                elif state == 'needs_review':
                    sw_entries['needs_review'] += 1
                elif state == 'new':
                    sw_entries['new'] += 1
    
    print("="*60)
    print("SWAHILI LOCALIZATION STATUS")
    print("="*60)
    print(f"\nSupported Languages ({len(all_langs)}):")
    for lang in sorted(all_langs):
        marker = " ← SWAHILI" if lang == 'sw' else ""
        print(f"  - {lang}{marker}")
    
    print(f"\nSwahili Translation Statistics:")
    print(f"  Total entries:     {sw_entries['total']}")
    print(f"  Translated:        {sw_entries['translated']} ({sw_entries['translated']/sw_entries['total']*100:.1f}%)")
    print(f"  Needs review:      {sw_entries['needs_review']}")
    print(f"  New (untranslated):{sw_entries['new']}")
    print("="*60)
    
    if sw_entries['translated'] > 900:
        print("✅ Swahili localization is COMPLETE and ready for use!")
    else:
        print("⚠️  Swahili localization is incomplete.")
        print(f"   Run: python3 translate_swahili.py")
    print("="*60)

if __name__ == '__main__':
    check_swahili_status()
