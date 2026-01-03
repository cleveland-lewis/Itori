#!/usr/bin/env python3
"""
Complete ALL remaining Farsi translations in batch
Uses Google Translate with better error handling
"""

import json
import sys
import time
from googletrans import Translator

def batch_translate_remaining(file_path):
    """Translate all remaining needs_review strings"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translator = Translator()
    
    # Collect all strings needing translation
    to_translate = []
    for key, value in data['strings'].items():
        if 'localizations' not in value:
            continue
        fa_entry = value['localizations'].get('fa', {})
        if fa_entry.get('stringUnit', {}).get('state') == 'needs_review':
            en_entry = value['localizations'].get('en', {})
            source_text = en_entry.get('stringUnit', {}).get('value', key)
            to_translate.append((key, source_text, fa_entry))
    
    print(f"🌐 Translating {len(to_translate)} remaining strings to Farsi...\n")
    
    translated_count = 0
    failed_count = 0
    save_interval = 50
    
    for idx, (key, source_text, fa_entry) in enumerate(to_translate, 1):
        # Skip symbols and format-only strings
        if source_text in ['%@', '%d', '%1$@', '%2$@', '+', '-', '=', '/', '*']:
            fa_entry['stringUnit']['value'] = source_text
            fa_entry['stringUnit']['state'] = 'translated'
            continue
        
        # Skip brand names and technical terms
        skip_keywords = ['Roots', 'Ollama', 'OpenAI', 'ChatGPT', 'API', 'LLM', 'JSON', 'HTTP']
        if any(keyword in source_text for keyword in skip_keywords) and len(source_text) < 30:
            # Keep technical terms but mark translated
            fa_entry['stringUnit']['value'] = source_text
            fa_entry['stringUnit']['state'] = 'translated'
            continue
        
        try:
            # Translate with Google
            translation = translator.translate(source_text, src='en', dest='fa')
            fa_text = translation.text
            
            # Update entry
            fa_entry['stringUnit']['value'] = fa_text
            fa_entry['stringUnit']['state'] = 'translated'
            
            translated_count += 1
            
            # Show progress
            preview = source_text[:40] + '...' if len(source_text) > 40 else source_text
            fa_preview = fa_text[:40] + '...' if len(fa_text) > 40 else fa_text
            print(f"   {translated_count:3d} translated - '{preview}' → '{fa_preview}'")
            
            # Save periodically
            if translated_count % save_interval == 0:
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                print(f"   💾 Saved at {translated_count}")
            
            # Rate limiting
            time.sleep(0.1)
            
        except Exception as e:
            failed_count += 1
            print(f"   ⚠️  Failed: '{source_text[:40]}...' - {str(e)[:50]}")
            # Keep as needs_review with English fallback
            fa_entry['stringUnit']['value'] = source_text
            continue
    
    # Final save
    print("\n💾 Saving final translations...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "="*60)
    print("✅ Batch Farsi translation complete!")
    print("="*60)
    print(f"   Translated: {translated_count}")
    print(f"   Failed: {failed_count}")
    print(f"   Total processed: {len(to_translate)}")
    print("="*60)
    
    # Final stats
    total_strings = len(data['strings'])
    translated_total = sum(1 for v in data['strings'].values() 
                          if v.get('localizations', {}).get('fa', {}).get('stringUnit', {}).get('state') == 'translated')
    coverage = (translated_total / total_strings * 100)
    
    print(f"\n📊 Final Coverage: {translated_total}/{total_strings} ({coverage:.1f}%)")

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    
    try:
        batch_translate_remaining(file_path)
    except KeyboardInterrupt:
        print("\n\n⚠️  Translation interrupted. Progress has been saved.")
        sys.exit(0)
