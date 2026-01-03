#!/usr/bin/env python3
"""
Retry Hong Kong Chinese translations using deep-translator
Uses multiple translation backends with automatic fallback
"""

import json
import sys
import time
from deep_translator import GoogleTranslator

def retry_failed_translations(file_path):
    """Retry failed Hong Kong Chinese translations with multiple backends"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Collect strings that need translation
    to_translate = []
    for key, value in data['strings'].items():
        if not value or 'localizations' not in value:
            continue
        
        if 'zh-HK' not in value['localizations']:
            continue
        
        hk_entry = value['localizations']['zh-HK']
        
        # Only retry needs_review or failed translations
        if hk_entry['stringUnit']['state'] != 'needs_review':
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
    print(f"🌐 Retrying {total} failed translations to Traditional Chinese (Hong Kong - zh-HK)...\n")
    print(f"Using deep-translator with GoogleTranslator backend\n")
    
    translated_count = 0
    failed_count = 0
    
    # Initialize translator
    google_translator = GoogleTranslator(source='en', target='zh-TW')
    
    # Translate
    for idx, (key, source_text, hk_entry) in enumerate(to_translate, 1):
        success = False
        
        # Try Google Translator
        try:
            result = google_translator.translate(source_text)
            if result and result != source_text:
                hk_entry['stringUnit']['value'] = result
                hk_entry['stringUnit']['state'] = 'translated'
                translated_count += 1
                success = True
        except Exception as e:
            print(f"   ⚠️  Failed for '{source_text[:40]}': {e}")
            failed_count += 1
        
        # Progress every 10 strings
        if idx % 10 == 0:
            percentage = (idx / total) * 100
            print(f"   Progress: {idx}/{total} ({percentage:.1f}%) - Success: {translated_count}, Failed: {failed_count}")
            
            # Save progress periodically
            if idx % 50 == 0:
                print(f"   💾 Saving progress...")
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
        
        # Small delay to respect rate limits
        time.sleep(0.2)
    
    # Final save
    print(f"\n💾 Saving final results...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ Retry complete!")
    print(f"   Translated: {translated_count}")
    print(f"   Still failed: {failed_count}")
    print(f"   Total attempted: {total}")
    
    # Calculate new overall stats
    total_entries = 0
    total_translated = 0
    for key, value in data['strings'].items():
        if 'localizations' in value and 'zh-HK' in value['localizations']:
            total_entries += 1
            if value['localizations']['zh-HK']['stringUnit']['state'] == 'translated':
                total_translated += 1
    
    print(f"\n📊 Overall zh-HK Statistics:")
    print(f"   Total entries: {total_entries}")
    print(f"   Fully translated: {total_translated}")
    print(f"   Success rate: {(total_translated/total_entries*100):.1f}%")

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    retry_failed_translations(file_path)
