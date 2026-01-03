#!/usr/bin/env python3
"""
Vietnamese translation with frequent saves and error recovery
Uses Google Translate API (free)
"""

import json
import sys
import time
from googletrans import Translator

def translate_vietnamese(file_path, max_translations=1232):
    """Translate Vietnamese entries efficiently"""
    
    print("📖 Loading localization file...", flush=True)
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(f"✓ Loaded {len(data.get('strings', {}))} strings", flush=True)
    
    translator = Translator()
    
    translated_count = 0
    failed_count = 0
    skipped_count = 0
    
    print("🌐 Starting Vietnamese (vi) translation...\n", flush=True)
    
    for idx, (key, value) in enumerate(data['strings'].items(), 1):
        if translated_count >= max_translations:
            break
            
        if not value or 'localizations' not in value:
            continue
        
        # Check if vi already exists
        if 'vi' in value['localizations']:
            # Skip if already translated
            if value['localizations']['vi']['stringUnit']['state'] == 'translated':
                skipped_count += 1
                continue
            vi_entry = value['localizations']['vi']
        else:
            # Create new Vietnamese entry
            value['localizations']['vi'] = {
                'stringUnit': {
                    'state': 'new',
                    'value': ''
                }
            }
            vi_entry = value['localizations']['vi']
        
        # Get source text
        source_text = key
        if 'en' in value['localizations']:
            source_text = value['localizations']['en']['stringUnit']['value']
        
        # Skip symbols and very short strings - mark as translated
        if len(source_text.strip()) <= 1 or source_text.strip() in ['—', '·', ' ', '\n', '%@', '%d', '–', ':', '...', '•', '/', '&']:
            vi_entry['stringUnit']['value'] = source_text
            vi_entry['stringUnit']['state'] = 'translated'
            skipped_count += 1
            continue
        
        # Skip format strings - mark as translated
        stripped = source_text.strip()
        if stripped in ['%1$@', '%2$@', '%1$d', '%2$d', '%lld', '%ld', '%@', '%d']:
            vi_entry['stringUnit']['value'] = source_text
            vi_entry['stringUnit']['state'] = 'translated'
            skipped_count += 1
            continue
        
        # Translate
        try:
            result = translator.translate(source_text, src='en', dest='vi')
            vi_entry['stringUnit']['value'] = result.text
            vi_entry['stringUnit']['state'] = 'translated'
            translated_count += 1
            
            # Progress every 10 translations
            if translated_count % 10 == 0:
                print(f"   {translated_count} translated - Last: '{source_text[:35]}'...", flush=True)
                
                # Save every 25 translations
                if translated_count % 25 == 0:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        json.dump(data, f, ensure_ascii=False, indent=2)
                    print(f"   💾 Saved", flush=True)
            
            time.sleep(0.1)  # Rate limiting
            
        except Exception as e:
            print(f"   ⚠️  Failed: '{source_text[:35]}'... - {str(e)[:40]}")
            vi_entry['stringUnit']['value'] = source_text
            vi_entry['stringUnit']['state'] = 'needs_review'
            failed_count += 1
            time.sleep(1.0)
    
    # Final save
    print("\n💾 Saving final translations...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "="*60)
    print("✅ Translation session complete!")
    print("="*60)
    print(f"   Translated: {translated_count}")
    print(f"   Skipped (symbols/already done): {skipped_count}")
    print(f"   Failed: {failed_count}")
    print("="*60)
    
    return True

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    
    try:
        print("Starting Vietnamese translation...")
        success = translate_vietnamese(file_path, max_translations=1232)
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Translation interrupted - progress has been saved")
        sys.exit(0)
    except Exception as e:
        print(f'\n❌ Error: {e}', file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
