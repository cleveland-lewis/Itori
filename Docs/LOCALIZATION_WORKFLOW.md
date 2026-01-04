# Localization Workflow with Xcode String Catalogs

## Overview
This guide explains how to use Xcode's modern localization export system to manage translations for the Itori app. The workflow uses `.xcloc` packages and `.xliff` files for professional translation workflows.

## Current Localization Setup

### Supported Languages
- **English (en)** - Base/Development language
- **Simplified Chinese (zh-Hans)**
- **Traditional Chinese (zh-Hant)**

### String Catalog Files
Located in `SharedCore/DesignSystem/`:
- `Localizable.xcstrings` - Main app strings
- `Itori-InfoPlist.xcstrings` - App metadata (name, permissions, etc.)

### Legacy Files
Located in language-specific `.lproj` folders:
- `en.lproj/Localizable.strings` - Legacy English strings
- `zh-Hans.lproj/Localizable.strings` - Legacy Simplified Chinese
- `zh-Hant.lproj/Localizable.strings` - Legacy Traditional Chinese
- `*.stringsdict` - Plural rules

**Note:** These legacy files are maintained for compatibility but new strings should use String Catalogs.

## Localization Workflow

### Step 1: Export Localizations

Export all localizable content for translation:

```bash
# Export English (base language)
xcodebuild -exportLocalizations \
  -project ItoriApp.xcodeproj \
  -localizationPath ./Localizations \
  -exportLanguage en \
  -sdk macosx

# Export Simplified Chinese
xcodebuild -exportLocalizations \
  -project ItoriApp.xcodeproj \
  -localizationPath ./Localizations \
  -exportLanguage zh-Hans \
  -sdk macosx

# Export Traditional Chinese
xcodebuild -exportLocalizations \
  -project ItoriApp.xcodeproj \
  -localizationPath ./Localizations \
  -exportLanguage zh-Hant \
  -sdk macosx
```

### Step 2: Review Exported Content

After export, you'll find:

```
Localizations/
├── en.xcloc/
│   ├── contents.json              # Metadata
│   ├── Localized Contents/
│   │   └── en.xliff              # Translation file
│   ├── Source Contents/
│   │   └── SharedCore/DesignSystem/
│   │       ├── Localizable.xcstrings
│   │       └── Itori-InfoPlist.xcstrings
│   └── Notes/
├── zh-Hans.xcloc/
│   └── ...
└── zh-Hant.xcloc/
    └── ...
```

### Step 3: Translate Using XLIFF

The `.xliff` file format is industry-standard and can be:

1. **Edited in Xcode**
   - Open the `.xcloc` package in Xcode
   - Xcode provides a built-in translation editor
   - Shows source and target side-by-side

2. **Sent to Professional Translators**
   - Send the entire `.xcloc` package
   - Translators can use tools like:
     - **Xcode** (free, for developers)
     - **Crowdin** (cloud-based)
     - **POEditor** (web-based)
     - **Transifex** (enterprise)
     - **SDL Trados** (professional CAT tool)
     - **memoQ** (translation memory system)

3. **Edited with Translation Tools**
   ```bash
   # View XLIFF structure
   cat Localizations/en.xcloc/Localized\ Contents/en.xliff
   ```

### Step 4: Import Translated Localizations

After translation is complete:

```bash
# Import Simplified Chinese translations
xcodebuild -importLocalizations \
  -project ItoriApp.xcodeproj \
  -localizationPath ./Localizations/zh-Hans.xcloc

# Import Traditional Chinese translations
xcodebuild -importLocalizations \
  -project ItoriApp.xcodeproj \
  -localizationPath ./Localizations/zh-Hant.xcloc
```

This will:
- Update `SharedCore/DesignSystem/Localizable.xcstrings` with new translations
- Update `SharedCore/DesignSystem/Itori-InfoPlist.xcstrings` 
- Merge translations into existing string catalogs
- Preserve any existing translations not in the XLIFF

### Step 5: Verify Translations

After import:

1. **Build and run the app**
   ```bash
   xcodebuild -scheme Itori -destination 'platform=macOS' build
   ```

2. **Test each language**
   - Change system language in System Settings
   - Or use scheme language override:
     - Xcode → Product → Scheme → Edit Scheme
     - Run → Options → App Language
     - Select language to test

3. **Check String Catalogs in Xcode**
   - Open `Localizable.xcstrings` in Xcode
   - Review translations in the editor
   - Look for missing or incomplete translations (marked with ⚠️)

## Adding a New Language

To add support for a new language (e.g., Spanish):

### 1. Add Language to Project

In Xcode:
1. Select project in Navigator
2. Select the project (not target)
3. Click "Info" tab
4. Under "Localizations", click "+"
5. Choose language (e.g., "Spanish (es)")
6. Select files to localize
7. Click "Finish"

### 2. Export for Translation

```bash
xcodebuild -exportLocalizations \
  -project ItoriApp.xcodeproj \
  -localizationPath ./Localizations \
  -exportLanguage es \
  -sdk macosx
```

### 3. Translate and Import

Follow Steps 3-5 above.

## Best Practices

### 1. Use Localized Strings in Code

```swift
// ✅ Good - Uses String Catalog
Text("dashboard.welcome", bundle: .main)
Text("settings.title", bundle: .main)

// ✅ Good - With interpolation
Text("user.greeting", bundle: .main)
  .replacingOccurrences(of: "{name}", with: userName)

// ❌ Bad - Hardcoded string
Text("Welcome to Itori")
```

### 2. Add Context Comments

In String Catalogs, add comments to help translators:

```swift
// In Xcode's String Catalog editor:
// Key: "button.save"
// Comment: "Button label for saving user data"
// Translation: "Save"
```

### 3. Handle Plurals Properly

Use `.stringsdict` for proper plural handling:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>tasks.count</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@task_count@</string>
        <key>task_count</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>zero</key>
            <string>No tasks</string>
            <key>one</key>
            <string>1 task</string>
            <key>other</key>
            <string>%d tasks</string>
        </dict>
    </dict>
</dict>
</plist>
```

### 4. Test All Languages Regularly

Create a test checklist:
- [ ] All UI text displays correctly
- [ ] No truncated strings
- [ ] RTL languages display properly (if supported)
- [ ] Dates and numbers use correct locale formatting
- [ ] No untranslated strings (check for English in other languages)

### 5. Export Regularly

Export localizations frequently:
- Before major releases
- After adding new features
- When refactoring UI text
- Before sending to translators

## Automation Scripts

### Quick Export All Languages

Create `scripts/export-localizations.sh`:

```bash
#!/bin/bash

LANGUAGES=("en" "zh-Hans" "zh-Hant")
OUTPUT_DIR="./Localizations"

echo "Exporting localizations..."

for LANG in "${LANGUAGES[@]}"; do
    echo "Exporting $LANG..."
    xcodebuild -exportLocalizations \
        -project ItoriApp.xcodeproj \
        -localizationPath "$OUTPUT_DIR" \
        -exportLanguage "$LANG" \
        -sdk macosx
done

echo "✅ Export complete! Files are in $OUTPUT_DIR/"
```

### Quick Import All Languages

Create `scripts/import-localizations.sh`:

```bash
#!/bin/bash

LANGUAGES=("zh-Hans" "zh-Hant")
INPUT_DIR="./Localizations"

echo "Importing localizations..."

for LANG in "${LANGUAGES[@]}"; do
    if [ -d "$INPUT_DIR/$LANG.xcloc" ]; then
        echo "Importing $LANG..."
        xcodebuild -importLocalizations \
            -project ItoriApp.xcodeproj \
            -localizationPath "$INPUT_DIR/$LANG.xcloc"
    else
        echo "⚠️  Skipping $LANG (not found)"
    fi
done

echo "✅ Import complete!"
```

Make scripts executable:
```bash
chmod +x scripts/export-localizations.sh
chmod +x scripts/import-localizations.sh
```

## Working with Translators

### Preparing Files for Translation

1. **Export clean base language**
   ```bash
   ./scripts/export-localizations.sh
   ```

2. **Package for translator**
   ```bash
   # Create a ZIP with instructions
   zip -r translations.zip \
       Localizations/*.xcloc \
       LOCALIZATION_WORKFLOW.md
   ```

3. **Send with instructions**
   - Include this guide
   - Specify deadline
   - Note any context or special requirements
   - Provide screenshots of UI

### Receiving Translations Back

1. **Unzip received files**
   ```bash
   unzip translations-completed.zip -d Localizations/
   ```

2. **Import translations**
   ```bash
   ./scripts/import-localizations.sh
   ```

3. **Review changes**
   ```bash
   git diff SharedCore/DesignSystem/Localizable.xcstrings
   ```

4. **Test in app**
   - Build and run
   - Switch languages
   - Verify all screens

## Troubleshooting

### Export Warnings

**"Skipping extraction of localizable string with non-literal key"**
- Some strings use dynamic keys
- Check `LocalizationManager.swift` for these cases
- These strings need manual management

**"Key used with multiple comments"**
- Same key has different comment text
- Consolidate comments or use different keys
- Fix in source code before exporting

### Import Issues

**"Could not import localization"**
- Check `.xcloc` package is complete
- Verify XLIFF structure is valid
- Re-export if corrupted

**"Translations not appearing"**
- Clean build folder (Product → Clean Build Folder)
- Delete DerivedData
- Rebuild project

### Missing Translations

Check String Catalogs in Xcode:
- Yellow warning = incomplete translation
- Red error = missing required translation
- Filter by "Not Translated" in editor

## Current Export Location

All localization exports are in:
```
/Users/clevelandlewis/Desktop/Itori/Localizations/
```

Contents:
- `en.xcloc/` - English (base language)
- `zh-Hans.xcloc/` - Simplified Chinese
- `zh-Hant.xcloc/` - Traditional Chinese

## Resources

- [Apple: Exporting Localizations](https://developer.apple.com/documentation/xcode/exporting-localizations)
- [Apple: String Catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [XLIFF Specification](http://docs.oasis-open.org/xliff/v1.2/os/xliff-core.html)
- [Plural Rules by Language](https://www.unicode.org/cldr/charts/43/supplemental/language_plural_rules.html)

## Summary

✅ **Exports created successfully** for all 3 supported languages  
✅ **Professional workflow** using industry-standard XLIFF format  
✅ **Automation scripts** for quick export/import  
✅ **String Catalogs** ready for Xcode's modern localization tools  

The localization system is now set up to support professional translation workflows with easy export/import cycles!
