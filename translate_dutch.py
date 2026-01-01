#!/usr/bin/env python3
"""
Script to translate English strings to Dutch using Google Translate API
Updates Localizable.xcstrings with translated Dutch entries
"""

import json
import sys
import time
from googletrans import Translator

def translate_to_dutch(text, translator):
    """Translate text from English to Dutch"""
    try:
        result = translator.translate(text, src='en', dest='nl')
        return result.text
    except Exception as e:
        print(f"⚠️  Translation failed for '{text[:50]}...': {e}", file=sys.stderr)
        return None

def translate_dutch_localizations(file_path, batch_size=50, delay=0.5):
    """Translate all Dutch entries in xcstrings file"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translator = Translator()
    
    total_strings = len(data['strings'])
    translated_count = 0
    skipped_count = 0
    failed_count = 0
    batch_count = 0
    
    print(f"🌐 Starting translation of {total_strings} strings to Dutch...")
    print(f"   Batch size: {batch_size}, Delay: {delay}s between batches\n")
    
    # Iterate through all strings
    for idx, (key, value) in enumerate(data['strings'].items(), 1):
        # Skip empty entries
        if not value or 'localizations' not in value:
            skipped_count += 1
            continue
        
        # Check if Dutch entry exists and needs translation
        if 'nl' not in value['localizations']:
            skipped_count += 1
            continue
        
        nl_entry = value['localizations']['nl']
        
        # Skip if already translated
        if nl_entry['stringUnit']['state'] == 'translated':
            skipped_count += 1
            continue
        
        # Get the English source text (from the key or en localization)
        source_text = key
        if 'en' in value['localizations']:
            source_text = value['localizations']['en']['stringUnit']['value']
        
        # Skip very short or symbol-only strings
        if len(source_text.strip()) <= 1 or source_text in ['—', '·', ' ', '\n']:
            nl_entry['stringUnit']['value'] = source_text
            nl_entry['stringUnit']['state'] = 'translated'
            translated_count += 1
            continue
        
        # Translate to Dutch
        translated_text = translate_to_dutch(source_text, translator)
        
        if translated_text:
            nl_entry['stringUnit']['value'] = translated_text
            nl_entry['stringUnit']['state'] = 'translated'
            translated_count += 1
            
            # Progress indicator
            if translated_count % 10 == 0:
                percentage = (idx / total_strings) * 100
                print(f"   Progress: {translated_count} translated ({percentage:.1f}% complete)")
        else:
            # Keep original as fallback
            nl_entry['stringUnit']['value'] = source_text
            nl_entry['stringUnit']['state'] = 'needs_review'
            failed_count += 1
        
        # Rate limiting: pause after each batch
        batch_count += 1
        if batch_count >= batch_size:
            print(f"   💤 Batch complete, pausing {delay}s to respect rate limits...")
            time.sleep(delay)
            batch_count = 0
    
    # Write back to file
    print("\n💾 Saving translations...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "="*60)
    print("✅ Dutch translation complete!")
    print("="*60)
    print(f"   Total strings: {total_strings}")
    print(f"   Translated: {translated_count}")
    print(f"   Skipped: {skipped_count}")
    print(f"   Failed: {failed_count}")
    print("="*60)
    
    return True

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    
    print("\n" + "="*60)
    print("🇳🇱  Dutch Translation Tool")
    print("="*60 + "\n")
    
    try:
        success = translate_dutch_localizations(
            file_path,
            batch_size=50,  # Translate 50 strings per batch
            delay=1.0       # Wait 1 second between batches
        )
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Translation interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f'\n❌ Error: {e}', file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
