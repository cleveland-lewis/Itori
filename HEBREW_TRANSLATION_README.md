# Hebrew Translation Setup

## Overview
Hebrew translations are being added to the Itori app using the free MyMemory Translation API.

## Files Created

### 1. `translate_to_hebrew.py`
Main translation script that:
- Reads `Localizable.xcstrings` file
- Identifies strings that need Hebrew translation
- Uses MyMemory API (free, no API key required)
- Processes 100 strings per run to respect API rate limits
- Saves translations back to the xcstrings file

### 2. `demo_translation_hebrew.py`
Demo script that translates 21 sample phrases to verify the API works.

## How to Use

### Run the Demo
```bash
cd Desktop/Itori
python3 demo_translation_hebrew.py
```

### Translate the Full File
```bash
cd Desktop/Itori
python3 translate_to_hebrew.py
```

The script will:
- Process up to 100 strings in one run (~2 minutes)
- Skip strings that are already translated
- Skip placeholder-only strings (like `%@`, `· %@`, etc.)
- Save progress after each batch

**To complete all translations:** Run the script multiple times until all strings are translated.

## Progress

### First Batch Complete ✅
- **Translated**: 100 strings
- **Remaining**: 1,141 strings
- **Skipped** (placeholders only): 20 strings
- **Total strings**: 1,261

To complete Hebrew localization, run `python3 translate_to_hebrew.py` approximately **11 more times**.

## API Information

### MyMemory Translation API
- **URL**: https://api.mymemory.translated.net
- **Free tier**: 5,000 requests/day
- **Rate limit**: ~1 request per second
- **No API key required**
- **Quality**: Good for general translations, uses translation memory
- **Language code**: `he` (Hebrew)

## Example Translation Results

From demo script:
```
Academic          → אקדמי
Academic Year     → שנת לימוד
Active Courses    → קורסים פעילים
Activities        → פעילויות
Add Assignment    → להוסיף משימה
Add Course        → הוסף תכנית לימודים
Calendar          → לוח שנה
Cancel            → בטל
Daily Goal        → מטרה יומית
Dark Mode         → מצב כהה
Delete            → מחיקה
Due Today         → מסתיים היום
Edit              → ערוך
Flashcards        → כרטיסיות
Goals             → יעדים
Help              → עזרה
Settings          → הגדרות
Save              → שמירה
Study Session     → מפגש למידה
Tasks             → משימות
Welcome           → ברוכים הבאים
```

## Hebrew Language Considerations

### Right-to-Left (RTL) Support
Hebrew is written right-to-left. iOS and SwiftUI have built-in RTL support:
- Text automatically aligns right
- UI elements mirror horizontally
- Navigation flows from right to left

### Testing Hebrew Locale
To test the Hebrew localization:
1. Open Xcode
2. Edit Scheme → Options → App Language → Hebrew
3. Run the app
4. UI should automatically flip to RTL layout

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

- The script preserves placeholder markers like `%@` in their original positions
- Some technical strings (like `alarm.pause`, `alarm.work`) are intentionally left in English
- For critical UI strings, consider professional review of translations
- Hebrew translations may need manual adjustments for proper gender/plural forms

## Next Steps

1. Run `translate_to_hebrew.py` approximately **11 more times** to complete all translations (~20-25 minutes total)
2. Open project in Xcode
3. Navigate to `Localizable.xcstrings` to review Hebrew translations
4. Test app in Hebrew locale (Scheme → App Language → Hebrew)
5. Make manual corrections as needed for:
   - Gender-specific translations
   - Plural forms
   - Cultural adaptations
   - Technical terminology

## Batch Progress Tracking

Run this command to check how many Hebrew translations exist:
```bash
cd Desktop/Itori
python3 -c "import json; data=json.load(open('SharedCore/DesignSystem/Localizable.xcstrings')); he_count=sum(1 for s in data['strings'].values() if 'he' in s.get('localizations',{})); print(f'Hebrew translations: {he_count}/1261')"
```

## Complete All Translations

You can create a loop script to run all batches:
```bash
# Run 12 times to complete all translations
for i in {1..12}; do
  echo "=== Batch $i/12 ==="
  python3 translate_to_hebrew.py
  echo ""
  sleep 5
done
```

This will take approximately 25-30 minutes to complete all translations.
