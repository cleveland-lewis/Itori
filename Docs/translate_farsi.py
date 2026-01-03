#!/usr/bin/env python3
"""
Farsi/Persian (fa) translation with RTL support
Uses Google Translate API
"""

import json
import sys
import time
from googletrans import Translator

def translate_farsi(file_path, max_translations=1500):
    """Translate Farsi entries efficiently with RTL support"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translator = Translator()
    
    translated_count = 0
    failed_count = 0
    skipped_count = 0
    
    print("🌐 Starting Farsi (fa) translation with RTL support...\n")
    
    for idx, (key, value) in enumerate(data['strings'].items(), 1):
        if translated_count >= max_translations:
            break
            
        if not value or 'localizations' not in value:
            continue
        
        # Initialize fa localization if not exists
        if 'fa' not in value['localizations']:
            value['localizations']['fa'] = {
                'stringUnit': {
                    'state': 'needs_review',
                    'value': key
                }
            }
        
        fa_entry = value['localizations']['fa']
        
        # Skip already translated
        if fa_entry['stringUnit']['state'] == 'translated':
            skipped_count += 1
            continue
        
        # Get source text
        source_text = key
        if 'en' in value['localizations']:
            source_text = value['localizations']['en']['stringUnit']['value']
        
        # Skip symbols and very short strings - mark as translated
        if len(source_text.strip()) <= 1 or source_text.strip() in ['—', '·', ' ', '\n', '%@', '%d', '–', ':', '...', '•', '/', '&', '+', '-', '=']:
            fa_entry['stringUnit']['value'] = source_text
            fa_entry['stringUnit']['state'] = 'translated'
            skipped_count += 1
            continue
        
        # Skip format strings - keep as-is for RTL compatibility
        stripped = source_text.strip()
        if stripped in ['%1$@', '%2$@', '%1$d', '%2$d', '%lld', '%ld', '%@', '%d']:
            fa_entry['stringUnit']['value'] = source_text
            fa_entry['stringUnit']['state'] = 'translated'
            skipped_count += 1
            continue
        
        # Skip English-only strings (brand names, technical terms)
        if key.startswith('app.name') or 'Roots' in source_text:
            fa_entry['stringUnit']['value'] = source_text
            fa_entry['stringUnit']['state'] = 'translated'
            skipped_count += 1
            continue
        
        # Translate
        try:
            result = translator.translate(source_text, src='en', dest='fa')
            fa_entry['stringUnit']['value'] = result.text
            fa_entry['stringUnit']['state'] = 'translated'
            translated_count += 1
            
            # Progress every 10 translations
            if translated_count % 10 == 0:
                print(f"   {translated_count} translated - Last: '{source_text[:35]}'... → '{result.text[:35]}'...")
                
                # Save every 25 translations
                if translated_count % 25 == 0:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        json.dump(data, f, ensure_ascii=False, indent=2)
                    print(f"   💾 Saved")
            
            time.sleep(0.15)  # Rate limiting (slightly slower for safety)
            
        except Exception as e:
            print(f"   ⚠️  Failed: '{source_text[:35]}'... - {str(e)[:40]}")
            fa_entry['stringUnit']['value'] = source_text
            fa_entry['stringUnit']['state'] = 'needs_review'
            failed_count += 1
            time.sleep(1.0)
    
    # Final save
    print("\n💾 Saving final translations...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "="*60)
    print("✅ Farsi translation session complete!")
    print("="*60)
    print(f"   Translated: {translated_count}")
    print(f"   Skipped (symbols/already done): {skipped_count}")
    print(f"   Failed: {failed_count}")
    print("="*60)
    print("\n📝 Note: Farsi is RTL - verify layout in Xcode preview")
    print("   SwiftUI will automatically handle RTL when device locale is fa")
    
    return True

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    
    try:
        print("Starting Farsi/Persian translation with RTL support...")
        success = translate_farsi(file_path, max_translations=1500)
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Translation interrupted - progress has been saved")
        sys.exit(0)
    except Exception as e:
        print(f'\n❌ Error: {e}', file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
