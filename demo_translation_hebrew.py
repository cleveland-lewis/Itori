#!/usr/bin/env python3
"""
Demo Hebrew translation using MyMemory Translation API
Tests the API with sample phrases before running full translation
"""

import requests
import time

MYMEMORY_URL = "https://api.mymemory.translated.net/get"

def translate_text(text, source_lang="en", target_lang="he"):
    """Translate text using MyMemory API"""
    try:
        params = {
            "q": text,
            "langpair": f"{source_lang}|{target_lang}"
        }
        
        response = requests.get(MYMEMORY_URL, params=params, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            if result.get("responseStatus") == 200:
                return result.get("responseData", {}).get("translatedText", text)
        
        return f"[ERROR: {response.status_code}]"
    except Exception as e:
        return f"[ERROR: {str(e)}]"

# Sample app strings to test
sample_strings = [
    "Academic",
    "Academic Year",
    "Active Courses",
    "Activities",
    "Add Assignment",
    "Add Course",
    "Calendar",
    "Cancel",
    "Daily Goal",
    "Dark Mode",
    "Delete",
    "Due Today",
    "Edit",
    "Flashcards",
    "Goals",
    "Help",
    "Settings",
    "Save",
    "Study Session",
    "Tasks",
    "Welcome"
]

print("🌍 Testing Hebrew Translation API")
print("=" * 70)

for text in sample_strings:
    translation = translate_text(text)
    print(f"{text:20} → {translation}")
    time.sleep(1.2)  # Rate limiting

print("=" * 70)
print("✅ Demo complete! If translations look good, run translate_to_hebrew.py")
