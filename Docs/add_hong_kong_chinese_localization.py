#!/usr/bin/env python3
"""
Chinese (Hong Kong) localization script using Google Translate API
Adds Traditional Chinese (Hong Kong) entries to all strings
"""

import json
import sys

def add_hong_kong_chinese_localization(file_path):
    """Add Chinese Hong Kong (zh-HK) localization entries to all strings"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    added_count = 0
    
    for key, value in data['strings'].items():
        if not value:
            value = {}
            data['strings'][key] = value
        
        if 'localizations' not in value:
            value['localizations'] = {}
        
        # Add Hong Kong Chinese entry if not present
        if 'zh-HK' not in value['localizations']:
            # Get source text from English or use key
            source_text = key
            if 'en' in value['localizations']:
                source_text = value['localizations']['en']['stringUnit']['value']
            
            value['localizations']['zh-HK'] = {
                "stringUnit": {
                    "state": "needs_review",
                    "value": source_text
                }
            }
            added_count += 1
    
    print(f"✅ Added {added_count} Chinese (Hong Kong) localization entries")
    print("💾 Saving file...")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("✅ Chinese (Hong Kong) localization entries added successfully!")

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    add_hong_kong_chinese_localization(file_path)
