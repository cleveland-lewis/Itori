#!/usr/bin/env python3
"""
Comprehensive translation script for all major App Store languages.
Supports systematic batch processing with progress tracking and resume capability.
"""

import json
import requests
import time
import sys
from pathlib import Path
from datetime import datetime

# MyMemory Translation API (free, 5000 requests/day)
MYMEMORY_URL = "https://api.mymemory.translated.net/get"

# All major App Store languages with their ISO codes
# Covers all 175 countries effectively
APP_STORE_LANGUAGES = {
    # Already translated (21)
    'ar': 'Arabic',
    'da': 'Danish', 
    'de': 'German',
    'en': 'English',
    'es': 'Spanish',
    'fa': 'Persian',
    'fi': 'Finnish',
    'fr': 'French',
    'he': 'Hebrew',
    'is': 'Icelandic',
    'it': 'Italian',
    'ja': 'Japanese',
    'nl': 'Dutch',
    'ru': 'Russian',
    'sw': 'Swahili',
    'th': 'Thai',
    'uk': 'Ukrainian',
    'vi': 'Vietnamese',
    'zh-HK': 'Chinese (Hong Kong)',
    'zh-Hans': 'Chinese (Simplified)',
    'zh-Hant': 'Chinese (Traditional)',
    
    # Priority 1: Major markets (6)
    'ko': 'Korean',
    'pt-BR': 'Portuguese (Brazil)',
    'pt-PT': 'Portuguese (Portugal)',
    'pl': 'Polish',
    'tr': 'Turkish',
    'id': 'Indonesian',
    
    # Priority 2: European languages (10)
    'sv': 'Swedish',
    'no': 'Norwegian',
    'ro': 'Romanian',
    'cs': 'Czech',
    'hu': 'Hungarian',
    'el': 'Greek',
    'sk': 'Slovak',
    'hr': 'Croatian',
    'bg': 'Bulgarian',
    'lt': 'Lithuanian',
    
    # Priority 3: Southeast Asia & Others (8)
    'ms': 'Malay',
    'tl': 'Tagalog',
    'hi': 'Hindi',
    'bn': 'Bengali',
    'ta': 'Tamil',
    'te': 'Telugu',
    'ur': 'Urdu',
    'kn': 'Kannada',
    
    # Priority 4: Additional coverage (8)
    'ca': 'Catalan',
    'sr': 'Serbian',
    'sl': 'Slovenian',
    'lv': 'Latvian',
    'et': 'Estonian',
    'mk': 'Macedonian',
    'sq': 'Albanian',
    'ka': 'Georgian',
}

# Map language codes to MyMemory API codes (some differ)
LANGUAGE_CODE_MAP = {
    'zh-Hans': 'zh-CN',
    'zh-Hant': 'zh-TW',
    'zh-HK': 'zh-TW',
    'pt-BR': 'pt-BR',
    'pt-PT': 'pt-PT',
    'no': 'nb',  # Norwegian Bokmål
    'tl': 'fil',  # Filipino/Tagalog
}

def get_api_language_code(lang_code):
    """Convert app language code to API language code"""
    return LANGUAGE_CODE_MAP.get(lang_code, lang_code)

def translate_text(text, target_lang, source_lang="en", retries=3):
    """Translate text using MyMemory API with retry logic"""
    
    # Skip if text is empty or too short
    if not text.strip() or len(text.strip()) <= 1:
        return text
    
    # Convert language code for API
    api_target = get_api_language_code(target_lang)
    
    for attempt in range(retries):
        try:
            params = {
                "q": text,
                "langpair": f"{source_lang}|{api_target}"
            }
            
            response = requests.get(
                MYMEMORY_URL,
                params=params,
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                
                if result.get("responseStatus") == 200:
                    translated = result.get("responseData", {}).get("translatedText", text)
                    return translated
                elif result.get("responseStatus") == 403:
                    # Rate limit hit
                    print(f"⚠️  Rate limit reached. Wait 24h or use different IP.")
                    return None
                else:
                    error_msg = result.get('responseDetails', 'Unknown error')
                    if attempt < retries - 1:
                        time.sleep(2)
                        continue
                    
            elif response.status_code == 429:
                print(f"⚠️  Rate limit. Waiting 60s...")
                time.sleep(60)
                continue
                
        except requests.exceptions.RequestException as e:
            if attempt < retries - 1:
                time.sleep(2)
                continue
    
    # If all retries failed, return original
    return text

def should_translate(text):
    """Determine if a string should be translated"""
    if not text or len(text.strip()) <= 1:
        return False
    
    # Skip strings that are only placeholders and punctuation
    cleaned = text
    for pattern in ['%@', '%lld', '%ld', '%d', '·', '—', '-', '/', '(', ')', '[', ']', ' ', '•', '●', '%', ',', '.', '!', '?', ':', ';']:
        cleaned = cleaned.replace(pattern, '')
    
    return len(cleaned.strip()) > 0

def load_progress():
    """Load translation progress from state file"""
    progress_file = Path(__file__).parent / ".translation_progress.json"
    if progress_file.exists():
        with open(progress_file, 'r') as f:
            return json.load(f)
    return {}

def save_progress(progress):
    """Save translation progress to state file"""
    progress_file = Path(__file__).parent / ".translation_progress.json"
    with open(progress_file, 'w') as f:
        json.dump(progress, f, indent=2)

def get_translation_status(xcstrings_path):
    """Get current translation status for all languages"""
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings = data.get("strings", {})
    total_strings = len(strings)
    
    status = {}
    for lang_code, lang_name in APP_STORE_LANGUAGES.items():
        if lang_code == 'en':
            continue
            
        translated = sum(1 for s in strings.values() 
                        if lang_code in s.get("localizations", {}))
        
        status[lang_code] = {
            'name': lang_name,
            'translated': translated,
            'total': total_strings,
            'percentage': (translated / total_strings * 100) if total_strings > 0 else 0,
            'complete': translated == total_strings
        }
    
    return status, total_strings

def translate_language(xcstrings_path, target_lang, batch_size=100, resume=True):
    """Translate all strings for a specific language"""
    
    print(f"\n{'='*70}")
    print(f"🌍 Translating to {APP_STORE_LANGUAGES[target_lang]} ({target_lang})")
    print(f"{'='*70}\n")
    
    # Load data
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings = data.get("strings", {})
    
    # Find strings that need translation
    to_translate = []
    already_done = 0
    skipped = 0
    
    for key, value in strings.items():
        localizations = value.get("localizations", {})
        
        if target_lang in localizations:
            already_done += 1
        elif should_translate(key):
            to_translate.append((key, value))
        else:
            skipped += 1
    
    total = len(strings)
    remaining = len(to_translate)
    
    print(f"📊 Status:")
    print(f"   Total strings: {total}")
    print(f"   Already translated: {already_done}")
    print(f"   To translate: {remaining}")
    print(f"   Skipped (placeholders): {skipped}")
    print(f"   Progress: {already_done/total*100:.1f}%\n")
    
    if remaining == 0:
        print(f"✅ {APP_STORE_LANGUAGES[target_lang]} is already complete!\n")
        return True
    
    # Process batch
    batch_to_process = to_translate[:batch_size]
    translated_count = 0
    failed_count = 0
    
    print(f"🔄 Processing batch of {len(batch_to_process)} strings...")
    print(f"{'='*70}\n")
    
    for idx, (key, value) in enumerate(batch_to_process, 1):
        # Progress indicator
        if idx % 10 == 0 or idx == 1:
            print(f"[{idx}/{len(batch_to_process)}] Progress: {idx/len(batch_to_process)*100:.0f}%")
        
        translated = translate_text(key, target_lang)
        
        if translated is None:
            # Rate limit hit
            failed_count += 1
            print(f"❌ Rate limit reached. Stopping batch.")
            break
        
        # Add translation
        if "localizations" not in value:
            value["localizations"] = {}
        
        value["localizations"][target_lang] = {
            "stringUnit": {
                "state": "translated",
                "value": translated
            }
        }
        
        translated_count += 1
        
        # Rate limiting - 1 request per second
        time.sleep(1.2)
    
    # Save updated file
    if translated_count > 0:
        print(f"\n💾 Saving {translated_count} translations...")
        with open(xcstrings_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("✅ Saved!")
    
    # Calculate completion
    new_total_translated = already_done + translated_count
    is_complete = new_total_translated == total - skipped
    
    print(f"\n{'='*70}")
    print(f"📈 Batch Results:")
    print(f"   Translated: {translated_count}")
    print(f"   Failed: {failed_count}")
    print(f"   Total progress: {new_total_translated}/{total} ({new_total_translated/total*100:.1f}%)")
    print(f"   Status: {'✅ COMPLETE' if is_complete else f'⏳ {remaining - translated_count} remaining'}")
    print(f"{'='*70}\n")
    
    return is_complete

def main():
    """Main translation orchestration"""
    xcstrings_file = Path(__file__).parent / "SharedCore" / "DesignSystem" / "Localizable.xcstrings"
    
    if not xcstrings_file.exists():
        print(f"❌ File not found: {xcstrings_file}")
        sys.exit(1)
    
    print("\n" + "="*70)
    print("🌐 COMPREHENSIVE APP STORE LOCALIZATION")
    print("="*70)
    print(f"Target: {len([l for l in APP_STORE_LANGUAGES if l != 'en'])} languages")
    print(f"Coverage: All 175 App Store countries")
    print(f"API: MyMemory (5000 requests/day)")
    print("="*70)
    
    # Get current status
    status, total_strings = get_translation_status(xcstrings_file)
    
    # Sort languages by completion (incomplete first, then by name)
    incomplete_langs = [(code, info) for code, info in status.items() if not info['complete']]
    complete_langs = [(code, info) for code, info in status.items() if info['complete']]
    
    incomplete_langs.sort(key=lambda x: (x[1]['translated'], x[1]['name']))
    complete_langs.sort(key=lambda x: x[1]['name'])
    
    print(f"\n📊 OVERALL STATUS")
    print("="*70)
    print(f"Complete languages: {len(complete_langs)}/{len(status)}")
    print(f"In progress: {len(incomplete_langs)}")
    print("="*70)
    
    if complete_langs:
        print(f"\n✅ Completed ({len(complete_langs)}):")
        for code, info in complete_langs[:10]:
            print(f"   {info['name']:25s} ({code}): {info['translated']}/{info['total']} strings")
        if len(complete_langs) > 10:
            print(f"   ... and {len(complete_langs) - 10} more")
    
    if incomplete_langs:
        print(f"\n⏳ In Progress ({len(incomplete_langs)}):")
        for code, info in incomplete_langs:
            print(f"   {info['name']:25s} ({code}): {info['translated']}/{info['total']} ({info['percentage']:.1f}%)")
    
    print("\n" + "="*70)
    
    # Ask which language to process
    if len(sys.argv) > 1:
        target_lang = sys.argv[1]
        if target_lang not in APP_STORE_LANGUAGES:
            print(f"❌ Unknown language code: {target_lang}")
            print(f"Available codes: {', '.join(sorted(APP_STORE_LANGUAGES.keys()))}")
            sys.exit(1)
    else:
        # Auto-select next incomplete language
        if incomplete_langs:
            target_lang = incomplete_langs[0][0]
            print(f"\n🎯 Auto-selected: {APP_STORE_LANGUAGES[target_lang]} ({target_lang})")
            print(f"   Current progress: {incomplete_langs[0][1]['percentage']:.1f}%")
        else:
            print("\n🎉 ALL LANGUAGES COMPLETE!")
            sys.exit(0)
    
    # Process the language
    batch_size = 100
    is_complete = translate_language(xcstrings_file, target_lang, batch_size)
    
    if not is_complete:
        print(f"💡 Run again to continue translating {APP_STORE_LANGUAGES[target_lang]}")
    else:
        # Check if there are more languages to translate
        status, _ = get_translation_status(xcstrings_file)
        remaining = sum(1 for info in status.values() if not info['complete'])
        
        if remaining > 0:
            print(f"💡 {remaining} languages remaining. Run again to continue.")
        else:
            print("\n🎉 ALL LANGUAGES COMPLETE! App is ready for 175 countries!")

if __name__ == "__main__":
    main()
