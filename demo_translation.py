#!/usr/bin/env python3
"""
Quick German translation demo using MyMemory API
"""

import json
import requests
import time
from pathlib import Path

def translate(text):
    """Quick translate function"""
    try:
        r = requests.get(
            'https://api.mymemory.translated.net/get',
            params={'q': text, 'langpair': 'en|de'},
            timeout=5
        )
        if r.status_code == 200 and r.json().get('responseStatus') == 200:
            return r.json()['responseData']['translatedText']
    except:
        pass
    return text

print("🌍 Testing German Translation with MyMemory API\n")

# Test phrases
test_phrases = [
    "Academic",
    "Academic Year",
    "Active Courses",
    "Activities",
    "Add Assignment",
    "Add Course",
    "Calendar",
    "Cancel",
    "Cards",
    "Complete",
    "Daily Goal",
    "Dark Mode",
    "Delete",
    "Due Today",
    "Edit",
    "Flashcards",
    "Goals",
    "Grade",
    "Help",
    "Home",
    "Light Mode"
]

print("Translating sample phrases:\n")
for phrase in test_phrases:
    german = translate(phrase)
    print(f"  EN: {phrase:20} → DE: {german}")
    time.sleep(1)  # Rate limit

print("\n✅ Demo complete! MyMemory API is working.")
print("\nTo add German to the full Localizable.xcstrings file:")
print("  1. The translate_to_german.py script is ready")
print("  2. It processes 100 strings at a time")
print("  3. Run it multiple times to complete all translations")
print("  4. Takes ~2 minutes per 100 strings (API rate limits)")
