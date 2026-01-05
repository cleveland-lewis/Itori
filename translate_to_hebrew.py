#!/usr/bin/env python3
"""
Add Hebrew translations to Localizable.xcstrings using MyMemory Translation API
MyMemory has better free tier: 5000 requests/day, no API key needed
"""

import json
import requests
import time
import sys
from pathlib import Path

# MyMemory Translation API (free, no API key needed)
MYMEMORY_URL = "https://api.mymemory.translated.net/get"

def translate_text(text, source_lang="en", target_lang="he", retries=3):
    """Translate text using MyMemory API"""
    
    # Skip if text is empty, only punctuation, or only placeholders
    if not text.strip() or len(text.strip()) <= 2:
        return text
    
    # Skip strings that are mostly placeholders
    if text.count('%@') > len(text.split()) / 2:
        return text
    
    for attempt in range(retries):
        try:
            params = {
                "q": text,
                "langpair": f"{source_lang}|{target_lang}"
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
                    print(f"✓ '{text[:40]}' -> '{translated[:40]}'")
                    return translated
                else:
                    print(f"⚠ API error: {result.get('responseDetails', 'Unknown error')}")
                    
        except requests.exceptions.RequestException as e:
            print(f"⚠ Request failed (attempt {attempt + 1}/{retries}): {e}")
            if attempt < retries - 1:
                time.sleep(1)
    
    print(f"⚠ Using original: {text[:40]}")
    return text

def should_translate(text):
    """Determine if a string should be translated"""
    # Skip empty or very short strings
    if not text or len(text.strip()) <= 2:
        return False
    
    # Skip strings that are only placeholders and punctuation
    cleaned = text
    for char in ['%@', '%lld', '%ld', '%d', '·', '—', '-', '/', '(', ')', '[', ']', ' ', '•', '●', '%']:
        cleaned = cleaned.replace(char, '')
    
    # If nothing left after removing placeholders, skip it
    return len(cleaned) > 0

def add_hebrew_translations(xcstrings_path, batch_size=100):
    """Add Hebrew translations to xcstrings file in batches"""
    
    print(f"📖 Reading {xcstrings_path}")
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if data.get("sourceLanguage") != "en":
        print("⚠ Source language is not English")
        return
    
    strings = data.get("strings", {})
    total = len(strings)
    translated_count = 0
    skipped_count = 0
    already_done = 0
    
    print(f"\n🌍 Processing {total} strings for Hebrew translation")
    print("=" * 70)
    
    # Filter strings that need translation
    to_translate = []
    for key, value in strings.items():
        localizations = value.get("localizations", {})
        if "he" in localizations:
            already_done += 1
        elif should_translate(key):
            to_translate.append((key, value))
        else:
            skipped_count += 1
    
    print(f"Already translated: {already_done}")
    print(f"To translate: {len(to_translate)}")
    print(f"Skipping (placeholders only): {skipped_count}")
    print("=" * 70)
    
    # Process in batches
    for idx, (key, value) in enumerate(to_translate[:batch_size], 1):
        print(f"\n[{idx}/{min(batch_size, len(to_translate))}] {key[:60]}")
        
        hebrew_text = translate_text(key, "en", "he")
        
        # Add Hebrew localization
        if "localizations" not in value:
            value["localizations"] = {}
        
        value["localizations"]["he"] = {
            "stringUnit": {
                "state": "translated",
                "value": hebrew_text
            }
        }
        
        translated_count += 1
        
        # Rate limiting - MyMemory allows ~1 req/sec
        time.sleep(1.2)
    
    # Save updated file
    print(f"\n💾 Saving translations...")
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print(f"✅ Batch complete!")
    print(f"   Translated in this batch: {translated_count}")
    print(f"   Already had Hebrew: {already_done}")
    print(f"   Skipped (placeholders): {skipped_count}")
    print(f"   Remaining to translate: {len(to_translate) - batch_size if len(to_translate) > batch_size else 0}")
    
    if len(to_translate) > batch_size:
        print(f"\n💡 Run the script again to translate the next {batch_size} strings")

if __name__ == "__main__":
    xcstrings_file = Path(__file__).parent / "SharedCore" / "DesignSystem" / "Localizable.xcstrings"
    
    if not xcstrings_file.exists():
        print(f"❌ File not found: {xcstrings_file}")
        sys.exit(1)
    
    # Process 100 strings per run to respect API limits
    batch_size = 100
    print(f"ℹ️  Batch mode: translating up to {batch_size} strings per run")
    print(f"ℹ️  Run multiple times to complete all translations")
    
    add_hebrew_translations(xcstrings_file, batch_size)
