#!/usr/bin/env python3
"""
Script to add Dutch (nl) localization entries to Localizable.xcstrings
Marks all entries as needs_review for manual translation
"""

import json
import sys

def add_dutch_to_localizable(file_path):
    """Add Dutch localization entries to xcstrings file"""
    
    # Read the file
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings_updated = 0
    strings_skipped = 0
    
    # Iterate through all strings
    for key, value in data['strings'].items():
        # Skip empty entries
        if not value:
            continue
            
        # Check if localizations exist
        if 'localizations' not in value:
            value['localizations'] = {}
        
        # Skip if Dutch already exists
        if 'nl' in value['localizations']:
            strings_skipped += 1
            continue
        
        # Add Dutch entry marked as needs_review
        # We'll use the English source as placeholder
        value['localizations']['nl'] = {
            'stringUnit': {
                'state': 'needs_review',
                'value': key  # Use key as initial value
            }
        }
        strings_updated += 1
    
    # Write back to file
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f'✅ Dutch localization added to {file_path}')
    print(f'   Strings updated: {strings_updated}')
    print(f'   Strings skipped (already have nl): {strings_skipped}')
    print(f'   Total strings: {len(data["strings"])}')
    return True

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    
    try:
        success = add_dutch_to_localizable(file_path)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f'❌ Error: {e}', file=sys.stderr)
        sys.exit(1)
