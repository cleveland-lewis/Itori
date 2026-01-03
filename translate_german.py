#!/usr/bin/env python3
import json
import time
import urllib.request
import urllib.parse
import sys

def translate_text(text, source_lang='en', target_lang='de'):
    """Translate text using MyMemory Translation API (free, no key required)"""
    try:
        # MyMemory API endpoint
        base_url = 'https://api.mymemory.translated.net/get'
        
        params = {
            'q': text,
            'langpair': f'{source_lang}|{target_lang}'
        }
        
        url = f"{base_url}?{urllib.parse.urlencode(params)}"
        
        with urllib.request.urlopen(url, timeout=10) as response:
            result = json.loads(response.read().decode())
            
            if result.get('responseStatus') == 200:
                return result['responseData']['translatedText']
            else:
                print(f"Translation API error: {result.get('responseDetails', 'Unknown error')}", file=sys.stderr)
                return None
                
    except Exception as e:
        print(f"Translation error for '{text[:50]}...': {e}", file=sys.stderr)
        return None

def add_german_translations():
    """Add German translations to all English strings"""
    
    print("Loading Localizable.xcstrings...")
    with open('./SharedCore/DesignSystem/Localizable.xcstrings', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    total_keys = len(data['strings'])
    translated_count = 0
    skipped_count = 0
    failed_count = 0
    
    print(f"\nFound {total_keys} total keys")
    print("Starting German translation...\n")
    
    for idx, (key, value) in enumerate(data['strings'].items(), 1):
        # Skip if German already exists
        if 'localizations' in value and 'de' in value['localizations']:
            skipped_count += 1
            continue
        
        # Get English text
        if 'localizations' not in value or 'en' not in value['localizations']:
            print(f"⚠️  Skipping {key}: No English source")
            skipped_count += 1
            continue
        
        en_text = value['localizations']['en']['stringUnit']['value']
        
        # Don't translate empty strings or special characters
        if not en_text.strip() or en_text in [' ', '—', '·', '•']:
            data['strings'][key].setdefault('localizations', {})['de'] = {
                'stringUnit': {
                    'state': 'translated',
                    'value': en_text
                }
            }
            translated_count += 1
            print(f"[{idx}/{total_keys}] ✓ {key}: '{en_text}' (kept as-is)")
            continue
        
        # Translate
        print(f"[{idx}/{total_keys}] Translating {key}...", end=' ')
        german_text = translate_text(en_text)
        
        if german_text:
            # Add German translation
            data['strings'][key].setdefault('localizations', {})['de'] = {
                'stringUnit': {
                    'state': 'translated',
                    'value': german_text
                }
            }
            translated_count += 1
            print(f"✓ '{en_text[:40]}...' → '{german_text[:40]}...'")
        else:
            failed_count += 1
            print(f"✗ Failed")
        
        # Rate limiting - be nice to free API
        if idx % 10 == 0:
            print(f"\n--- Progress: {translated_count} translated, {failed_count} failed, {skipped_count} skipped ---\n")
            time.sleep(2)  # Pause every 10 requests
        else:
            time.sleep(0.5)  # Small delay between requests
    
    # Save updated file
    print("\n\nSaving translations...")
    with open('./SharedCore/DesignSystem/Localizable.xcstrings', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')
    
    print(f"\n✅ Translation complete!")
    print(f"   Translated: {translated_count}")
    print(f"   Skipped: {skipped_count}")
    print(f"   Failed: {failed_count}")
    print(f"   Total: {total_keys}")

if __name__ == '__main__':
    try:
        add_german_translations()
    except KeyboardInterrupt:
        print("\n\n⚠️  Translation interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
