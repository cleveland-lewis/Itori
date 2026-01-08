#!/usr/bin/env python3
"""
Quick demo of the translation system - translates Korean strings (5 strings only)
"""

import json
import requests
import time
from pathlib import Path

MYMEMORY_URL = "https://api.mymemory.translated.net/get"

def translate_text(text, target_lang="ko"):
    """Translate text to Korean"""
    try:
        params = {"q": text, "langpair": f"en|{target_lang}"}
        response = requests.get(MYMEMORY_URL, params=params, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            if result.get("responseStatus") == 200:
                return result.get("responseData", {}).get("translatedText", text)
    except:
        pass
    return text

def demo_translation():
    """Demo translation of 5 strings to Korean"""
    
    print("\n" + "="*70)
    print("🎯 TRANSLATION SYSTEM DEMO")
    print("="*70)
    print("Translating 5 sample strings to Korean...")
    print()
    
    # Sample strings
    samples = [
        "Calendar",
        "Settings",
        "Add Assignment",
        "Study Session",
        "Complete"
    ]
    
    for idx, text in enumerate(samples, 1):
        print(f"[{idx}/5] Translating: {text:20} ", end="", flush=True)
        translated = translate_text(text, "ko")
        print(f"→ {translated}")
        time.sleep(1.2)  # Rate limiting
    
    print()
    print("="*70)
    print("✅ Demo complete!")
    print()
    print("To run full translation:")
    print("  1. Single language:  python3 translate_all_languages.py ko")
    print("  2. Batch mode:       ./translate_batch_runner.sh")
    print("  3. View status:      python3 translate_all_languages.py")
    print()

if __name__ == "__main__":
    demo_translation()
