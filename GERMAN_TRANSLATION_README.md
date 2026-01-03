# German Translation Setup

## Overview
German translations are being added to the Itori app using the free MyMemory Translation API.

## Files Created

### 1. `translate_to_german.py`
Main translation script that:
- Reads `Localizable.xcstrings` file
- Identifies strings that need German translation
- Uses MyMemory API (free, no API key required)
- Processes 100 strings per run to respect API rate limits
- Saves translations back to the xcstrings file

### 2. `demo_translation.py`
Demo script that translates 21 sample phrases to verify the API works.

## How to Use

### Run the Demo
```bash
cd Desktop/Itori
python3 demo_translation.py
```

### Translate the Full File
```bash
cd Desktop/Itori
python3 translate_to_german.py
```

The script will:
- Process up to 100 strings in one run (~2 minutes)
- Skip strings that are already translated
- Skip placeholder-only strings (like `%@`, `· %@`, etc.)
- Save progress after each batch

**To complete all translations:** Run the script multiple times until all strings are translated.

## API Information

### MyMemory Translation API
- **URL**: https://api.mymemory.translated.net
- **Free tier**: 5,000 requests/day
- **Rate limit**: ~1 request per second
- **No API key required**
- **Quality**: Good for general translations, uses translation memory

### Example Translation Results
```
Academic          → Akademisches
Academic Year     → Akademisches Jahr  
Active Courses    → Aktivkurse
Activities        → Aktivitäten
Add Assignment    → NEUE AUFGABE HINZUFÜGEN
Add Course        → Training hinzufügen
Calendar          → Kalender
Cancel            → Abbrechen
Daily Goal        → Tagesziel
Dark Mode         → Dunkler Modus
Delete            → Löschen
Due Today         → Heute fällig
Edit              → Bearbeiten
Flashcards        → Karteikarten
Goals             → Ziele
Help              → Hilfe
```

## Progress Tracking

The script reports:
- Total strings in file: ~1261
- Already translated: 0 (initially)
- To translate: ~600-700 (meaningful strings)
- Skipped: ~400-500 (placeholder-only strings)

## Alternative Free Translation APIs

If you need alternatives:

1. **Google Translate (via googletrans library)**
   ```bash
   pip install googletrans==4.0.0rc1
   ```

2. **DeepL Free API** (requires signup)
   - Better quality than MyMemory
   - 500,000 characters/month free
   - https://www.deepl.com/pro-api

3. **LibreTranslate** (self-hosted or public instance)
   - Open source
   - Public instance has strict rate limits
   - https://libretranslate.com

## Notes

- The MyMemory API sometimes returns mixed-case translations (e.g., "NEUE AUFGABE HINZUFÜGEN"). These can be manually corrected in Xcode after bulk translation.
- For critical UI strings, consider professional review of translations
- The script preserves placeholder markers like `%@` in their original positions

## Next Steps

1. Run `translate_to_german.py` multiple times to complete all translations
2. Open project in Xcode
3. Review German translations in `Localizable.xcstrings`
4. Test app in German locale
5. Make manual corrections as needed
