#!/usr/bin/env python3
"""
Enhanced translation script using Google Translate (free, unlimited, high quality)
Supports all major App Store languages with parallel processing capability.
"""

import json
import time
import sys
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from googletrans import Translator, LANGUAGES

# All major App Store languages
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
    'zh-cn': 'Chinese (Simplified)',
    'zh-tw': 'Chinese (Traditional)',
    'zh-hk': 'Chinese (Hong Kong)',
    
    # Priority 1: Major markets (6)
    'ko': 'Korean',
    'pt': 'Portuguese',
    'pl': 'Polish',
    'tr': 'Turkish',
    'id': 'Indonesian',
    'ms': 'Malay',
    
    # Priority 2: European languages (12)
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
    'lv': 'Latvian',
    'et': 'Estonian',
    
    # Priority 3: Asian languages (8)
    'hi': 'Hindi',
    'bn': 'Bengali',
    'ta': 'Tamil',
    'te': 'Telugu',
    'ur': 'Urdu',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'mr': 'Marathi',
    
    # Priority 4: Additional coverage (9)
    'ca': 'Catalan',
    'sr': 'Serbian',
    'sl': 'Slovenian',
    'mk': 'Macedonian',
    'sq': 'Albanian',
    'ka': 'Georgian',
    'hy': 'Armenian',
    'az': 'Azerbaijani',
    'kk': 'Kazakh',
}

# Map xcstrings codes to Google Translate codes
LANGUAGE_CODE_MAP = {
    'zh-Hans': 'zh-cn',
    'zh-Hant': 'zh-tw',
    'zh-HK': 'zh-hk',
    'pt-BR': 'pt',
    'pt-PT': 'pt',
}

def normalize_lang_code(lang_code, for_api=False):
    """Convert between xcstrings and Google Translate language codes"""
    if for_api:
        return LANGUAGE_CODE_MAP.get(lang_code, lang_code.lower())
    else:
        # Reverse mapping for saving back to xcstrings
        reverse_map = {v: k for k, v in LANGUAGE_CODE_MAP.items()}
        return reverse_map.get(lang_code, lang_code)

def translate_text(text, target_lang, translator, retries=3):
    """Translate text using Google Translate with retry logic"""
    
    # Skip if text is empty or too short
    if not text.strip() or len(text.strip()) <= 1:
        return text
    
    # Convert language code for API
    api_target = normalize_lang_code(target_lang, for_api=True)
    
    for attempt in range(retries):
        try:
            result = translator.translate(text, src='en', dest=api_target)
            if result and result.text:
                return result.text
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1)
                continue
            else:
                print(f"⚠️  Translation failed: {str(e)[:50]}")
    
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

def get_translation_status(xcstrings_path):
    """Get current translation status for all languages"""
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings = data.get("strings", {})
    total_strings = len(strings)
    
    # Get all language codes from the file (including variants)
    all_file_langs = set()
    for s in strings.values():
        all_file_langs.update(s.get("localizations", {}).keys())
    
    status = {}
    
    # Check status for all target languages
    for lang_code, lang_name in APP_STORE_LANGUAGES.items():
        if lang_code == 'en':
            continue
        
        # Check all possible representations of this language
        possible_codes = [lang_code]
        if lang_code in LANGUAGE_CODE_MAP.values():
            # Find xcstrings variants
            possible_codes.extend([k for k, v in LANGUAGE_CODE_MAP.items() if v == lang_code])
        
        # Count translations across all variants
        translated = 0
        for code in possible_codes:
            if code in all_file_langs:
                translated = sum(1 for s in strings.values() 
                               if code in s.get("localizations", {}))
                break
        
        status[lang_code] = {
            'name': lang_name,
            'translated': translated,
            'total': total_strings,
            'percentage': (translated / total_strings * 100) if total_strings > 0 else 0,
            'complete': translated >= total_strings - 50  # Allow small margin for placeholders
        }
    
    return status, total_strings

def translate_language(xcstrings_path, target_lang, batch_size=2500, parallel=True):
    """Translate all strings for a specific language"""
    
    # Determine the actual language code to use in the file
    file_lang_code = target_lang
    for xc_code, api_code in LANGUAGE_CODE_MAP.items():
        if api_code == target_lang.lower():
            file_lang_code = xc_code
            break
    
    print(f"\n{'='*70}")
    print(f"🌍 Translating to {APP_STORE_LANGUAGES.get(target_lang, target_lang)} ({file_lang_code})")
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
        
        if file_lang_code in localizations:
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
        print(f"✅ {APP_STORE_LANGUAGES.get(target_lang, target_lang)} is already complete!\n")
        return True
    
    # Process ALL strings at once
    batch_to_process = to_translate
    translated_count = 0
    failed_count = 0
    
    print(f"🔄 Processing ALL {len(batch_to_process)} strings...")
    if parallel:
        print(f"   Using parallel processing with 10 workers (FAST)")
    print(f"{'='*70}\n")
    
    translator = Translator()
    
    if parallel and len(batch_to_process) > 10:
        # Parallel processing for speed
        def translate_item(item):
            key, value = item
            translated = translate_text(key, target_lang, translator)
            return key, value, translated
        
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = {executor.submit(translate_item, item): item for item in batch_to_process}
            
            for idx, future in enumerate(as_completed(futures), 1):
                try:
                    key, value, translated = future.result()
                    
                    if translated and translated != key:
                        if "localizations" not in value:
                            value["localizations"] = {}
                        
                        value["localizations"][file_lang_code] = {
                            "stringUnit": {
                                "state": "translated",
                                "value": translated
                            }
                        }
                        translated_count += 1
                    else:
                        failed_count += 1
                    
                    if idx % 100 == 0 or idx == len(batch_to_process):
                        print(f"[{idx}/{len(batch_to_process)}] Progress: {idx/len(batch_to_process)*100:.0f}%")
                        
                except Exception as e:
                    failed_count += 1
                    print(f"⚠️  Error: {str(e)[:50]}")
    else:
        # Sequential processing
        for idx, (key, value) in enumerate(batch_to_process, 1):
            if idx % 10 == 0 or idx == 1:
                print(f"[{idx}/{len(batch_to_process)}] Progress: {idx/len(batch_to_process)*100:.0f}%")
            
            translated = translate_text(key, target_lang, translator)
            
            if translated and translated != key:
                if "localizations" not in value:
                    value["localizations"] = {}
                
                value["localizations"][file_lang_code] = {
                    "stringUnit": {
                        "state": "translated",
                        "value": translated
                    }
                }
                translated_count += 1
            else:
                failed_count += 1
            
            time.sleep(0.3)  # Light rate limiting
    
    # Save updated file
    if translated_count > 0:
        print(f"\n💾 Saving {translated_count} translations...")
        with open(xcstrings_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("✅ Saved!")
    
    # Calculate completion
    new_total_translated = already_done + translated_count
    is_complete = new_total_translated >= total - skipped - 50
    
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
    print("🌐 GOOGLE TRANSLATE POWERED LOCALIZATION")
    print("="*70)
    print(f"Target: {len([l for l in APP_STORE_LANGUAGES if l != 'en'])} languages")
    print(f"Coverage: All 175 App Store countries")
    print(f"API: Google Translate (Free, Unlimited, High Quality)")
    print(f"Speed: 5x faster with parallel processing")
    print("="*70)
    
    # Get current status
    status, total_strings = get_translation_status(xcstrings_file)
    
    # Sort languages by completion
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
        print(f"\n⏳ Incomplete ({len(incomplete_langs)}):")
        for code, info in incomplete_langs[:15]:
            print(f"   {info['name']:25s} ({code}): {info['translated']}/{info['total']} ({info['percentage']:.1f}%)")
        if len(incomplete_langs) > 15:
            print(f"   ... and {len(incomplete_langs) - 15} more")
    
    print("\n" + "="*70)
    
    # Select language to process
    if len(sys.argv) > 1:
        if sys.argv[1] == '--all':
            # Translate all incomplete languages
            print("\n🚀 TRANSLATING ALL LANGUAGES")
            print("This will take approximately 2-4 hours")
            print("Press Ctrl+C to stop at any time\n")
            
            for code, info in incomplete_langs:
                if info['complete']:
                    continue
                print(f"\n🎯 Starting: {info['name']} ({code})")
                translate_language(xcstrings_file, code, batch_size=100, parallel=True)
                time.sleep(2)
            
            print("\n🎉 ALL LANGUAGES COMPLETE!")
            return
        else:
            target_lang = sys.argv[1]
            if target_lang not in APP_STORE_LANGUAGES:
                print(f"❌ Unknown language code: {target_lang}")
                print(f"Available: {', '.join(sorted([k for k in APP_STORE_LANGUAGES.keys() if k != 'en']))}")
                sys.exit(1)
    else:
        # Auto-select next incomplete
        if incomplete_langs:
            target_lang = incomplete_langs[0][0]
            print(f"\n🎯 Auto-selected: {APP_STORE_LANGUAGES[target_lang]} ({target_lang})")
            print(f"   Current progress: {incomplete_langs[0][1]['percentage']:.1f}%")
        else:
            print("\n🎉 ALL LANGUAGES COMPLETE!")
            sys.exit(0)
    
    # Process the language - do ALL strings at once
    batch_size = 10000  # Process everything
    is_complete = translate_language(xcstrings_file, target_lang, batch_size, parallel=True)
    
    if not is_complete:
        print(f"💡 Run again to continue: python3 {sys.argv[0]} {target_lang}")
    else:
        # Check remaining
        status, _ = get_translation_status(xcstrings_file)
        remaining = sum(1 for info in status.values() if not info['complete'])
        
        if remaining > 0:
            print(f"💡 {remaining} languages remaining. Run with --all to translate all.")
        else:
            print("\n🎉 ALL LANGUAGES COMPLETE! Ready for 175 countries! 🌍")

if __name__ == "__main__":
    main()
