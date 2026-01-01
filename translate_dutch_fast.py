#!/usr/bin/env python3
"""
Fast Dutch translation script using Google Translate
Translates in batches with progress saving
"""

import json
import sys
import time
from googletrans import Translator

def translate_dutch_fast(file_path):
    """Translate Dutch entries efficiently"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translator = Translator()
    
    # Collect strings to translate
    to_translate = []
    for key, value in data['strings'].items():
        if not value or 'localizations' not in value:
            continue
        
        if 'nl' not in value['localizations']:
            continue
        
        nl_entry = value['localizations']['nl']
        if nl_entry['stringUnit']['state'] == 'translated':
            continue
        
        # Get source text
        source_text = key
        if 'en' in value['localizations']:
            source_text = value['localizations']['en']['stringUnit']['value']
        
        # Skip symbols and very short strings
        if len(source_text.strip()) <= 1 or source_text in ['—', '·', ' ', '\n', '%@', '%d']:
            nl_entry['stringUnit']['value'] = source_text
            nl_entry['stringUnit']['state'] = 'translated'
            continue
        
        to_translate.append((key, source_text, nl_entry))
    
    total = len(to_translate)
    print(f"🌐 Translating {total} strings to Dutch...\n")
    
    translated_count = 0
    failed_count = 0
    
    # Translate in batches with progress updates
    for idx, (key, source_text, nl_entry) in enumerate(to_translate, 1):
        try:
            # Translate
            result = translator.translate(source_text, src='en', dest='nl')
            nl_entry['stringUnit']['value'] = result.text
            nl_entry['stringUnit']['state'] = 'translated'
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
            print(f"   ⚠️  Failed: '{source_text[:40]}' - {str(e)[:50]}")
            nl_entry['stringUnit']['value'] = source_text
            nl_entry['stringUnit']['state'] = 'needs_review'
            failed_count += 1
            time.sleep(0.5)  # Longer delay on error
    
    # Final save
    print("\n💾 Saving final translations...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "="*60)
    print("✅ Translation complete!")
    print("="*60)
    print(f"   Translated: {translated_count}")
    print(f"   Failed: {failed_count}")
    print(f"   Success rate: {(translated_count/(translated_count+failed_count)*100):.1f}%")
    print("="*60)
    
    return True

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    
    try:
        success = translate_dutch_fast(file_path)
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Translation interrupted")
        sys.exit(1)
    except Exception as e:
        print(f'\n❌ Error: {e}', file=sys.stderr)
        sys.exit(1)
