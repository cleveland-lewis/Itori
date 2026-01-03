#!/usr/bin/env python3
"""
Add Finnish (fi) localization entries to Localizable.xcstrings
Adds missing entries with "needs_review" state ready for translation
"""

import json
import sys

def add_finnish_entries(file_path):
    """Add Finnish localization entries to xcstrings file"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    added_count = 0
    skipped_count = 0
    
    print("🇫🇮 Adding Finnish (fi) entries...\n")
    
    for key, value in data['strings'].items():
        # Skip if no localizations at all
        if not value or 'localizations' not in value:
            value['localizations'] = {}
        
        # Skip if Finnish already exists
        if 'fi' in value['localizations']:
            skipped_count += 1
            continue
        
        # Get source text (preferably English, otherwise key)
        source_text = key
        if 'en' in value['localizations']:
            source_text = value['localizations']['en']['stringUnit']['value']
        
        # Add Finnish entry with needs_review state
        value['localizations']['fi'] = {
            'stringUnit': {
                'state': 'needs_review',
                'value': source_text
            }
        }
        added_count += 1
    
    # Save the modified file
    print("💾 Saving changes...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "="*60)
    print("✅ Finnish entries added!")
    print("="*60)
    print(f"   Added: {added_count}")
    print(f"   Skipped (already exists): {skipped_count}")
    print(f"   Total Finnish entries: {added_count + skipped_count}")
    print("="*60)
    print("\n💡 Next step: Run translate_finnish.py to translate all entries")
    
    return True

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    
    try:
        success = add_finnish_entries(file_path)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f'\n❌ Error: {e}', file=sys.stderr)
        sys.exit(1)
