#!/usr/bin/env python3
"""
Add Swahili (sw) localization entries to Localizable.xcstrings
"""

import json
import sys

def add_swahili_localization(file_path):
    """Add Swahili language entries to all strings"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    added_count = 0
    skipped_count = 0
    
    print("🌐 Adding Swahili (sw) entries...\n")
    
    for key, value in data['strings'].items():
        if not value or 'localizations' not in value:
            continue
        
        # Skip if Swahili already exists
        if 'sw' in value['localizations']:
            skipped_count += 1
            continue
        
        # Add Swahili entry with needs_review state
        value['localizations']['sw'] = {
            "stringUnit": {
                "state": "needs_review",
                "value": key  # Default to key, will be translated later
            }
        }
        added_count += 1
        
        if added_count % 100 == 0:
            print(f"   Added {added_count} Swahili entries...")
    
    # Save the updated file
    print("\n💾 Saving updated localization file...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "="*60)
    print("✅ Swahili localization setup complete!")
    print("="*60)
    print(f"   Added: {added_count}")
    print(f"   Skipped (already exists): {skipped_count}")
    print("="*60)
    print("\nNext step: Run ./translate_swahili.py to translate entries")
    
    return True

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    
    try:
        success = add_swahili_localization(file_path)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f'\n❌ Error: {e}', file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
