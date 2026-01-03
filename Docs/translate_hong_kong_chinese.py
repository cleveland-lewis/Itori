#!/usr/bin/env python3
"""
Chinese (Hong Kong) translation script using Google Translate
Translates to Traditional Chinese (Hong Kong variant) in batches with progress saving
"""

import json
import sys
import time
from googletrans import Translator

def translate_hong_kong_chinese(file_path):
    """Translate Chinese Hong Kong entries efficiently"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translator = Translator()
    
    # Collect strings to translate
    to_translate = []
    for key, value in data['strings'].items():
        if not value or 'localizations' not in value:
            continue
        
        if 'zh-HK' not in value['localizations']:
            continue
        
        hk_entry = value['localizations']['zh-HK']
        if hk_entry['stringUnit']['state'] == 'translated':
            continue
        
        # Get source text
        source_text = key
        if 'en' in value['localizations']:
            source_text = value['localizations']['en']['stringUnit']['value']
        
        # Skip symbols and very short strings
        if len(source_text.strip()) <= 1 or source_text in ['—', '·', ' ', '\n', '%@', '%d', '–']:
            hk_entry['stringUnit']['value'] = source_text
            hk_entry['stringUnit']['state'] = 'translated'
            continue
        
        # Skip format strings that are just placeholders
        if source_text.strip() in ['%1$@', '%2$@', '%1$d', '%2$d', '%lld', '%ld']:
            hk_entry['stringUnit']['value'] = source_text
            hk_entry['stringUnit']['state'] = 'translated'
            continue
        
        to_translate.append((key, source_text, hk_entry))
    
    total = len(to_translate)
    print(f"🌐 Translating {total} strings to Traditional Chinese (Hong Kong - zh-HK)...\n")
    
    translated_count = 0
    failed_count = 0
    
    # Translate in batches with progress updates
    for idx, (key, source_text, hk_entry) in enumerate(to_translate, 1):
        try:
            # Translate to Traditional Chinese (Hong Kong uses Traditional Chinese)
            # Google Translate uses 'zh-TW' for Traditional Chinese
            result = translator.translate(source_text, src='en', dest='zh-TW')
            hk_entry['stringUnit']['value'] = result.text
            hk_entry['stringUnit']['state'] = 'translated'
            translated_count += 1
            
            # Progress every 50 strings
            if idx % 50 == 0:
                percentage = (idx / total) * 100
                print(f"   Progress: {idx}/{total} ({percentage:.1f}%) - Last: '{source_text[:40]}'")
                
                # Save progress periodically
                if idx % 200 == 0:
                    print(f"   💾 Saving progress...")
                    with open(file_path, 'w', encoding='utf-8') as f:
                        json.dump(data, f, ensure_ascii=False, indent=2)
                
                # Small delay to respect rate limits
                time.sleep(0.1)
        
        except Exception as e:
            print(f"   ⚠️  Failed to translate '{source_text[:40]}': {e}")
            failed_count += 1
            # Keep as needs_review on failure
            time.sleep(1)  # Longer delay after error
    
    # Final save
    print(f"\n💾 Saving final results...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ Translation complete!")
    print(f"   Translated: {translated_count}")
    print(f"   Failed: {failed_count}")
    print(f"   Total: {total}")

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    translate_hong_kong_chinese(file_path)
