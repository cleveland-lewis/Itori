# Localization Quick Reference

## Common Commands

### Export All Languages
```bash
./scripts/export-localizations.sh
```

### Import Translations
```bash
./scripts/import-localizations.sh
```

### Export Single Language
```bash
xcodebuild -exportLocalizations \
  -project RootsApp.xcodeproj \
  -localizationPath ./Localizations \
  -exportLanguage [LANG_CODE] \
  -sdk macosx
```

### Import Single Language
```bash
xcodebuild -importLocalizations \
  -project RootsApp.xcodeproj \
  -localizationPath ./Localizations/[LANG_CODE].xcloc
```

## Supported Languages

| Language | Code | Status |
|----------|------|--------|
| English | `en` | ✅ Base |
| Simplified Chinese | `zh-Hans` | ✅ Exported |
| Traditional Chinese | `zh-Hant` | ✅ Exported |

## File Locations

| Item | Path |
|------|------|
| Exports | `Localizations/*.xcloc` |
| String Catalogs | `SharedCore/DesignSystem/*.xcstrings` |
| Scripts | `scripts/` |
| Documentation | `LOCALIZATION_WORKFLOW.md` |

## Translation Stats

- **Total Strings**: 1,129
- **Languages**: 3
- **Format**: XLIFF 1.2
- **Catalog Files**: 2

## Quick Workflow

1. **Export**: `./scripts/export-localizations.sh`
2. **Translate**: Edit `.xcloc` packages
3. **Import**: `./scripts/import-localizations.sh`
4. **Test**: Build and run app
5. **Commit**: Git commit changes

## Testing Translations

### In Xcode
1. Edit Scheme → Run → Options
2. Set "App Language" to test language
3. Build and run

### System-wide
1. System Settings → Language & Region
2. Change Preferred Languages
3. Restart app

## Common Issues

| Issue | Solution |
|-------|----------|
| Export fails | Check project builds successfully |
| Import fails | Verify `.xcloc` structure intact |
| Missing strings | Check String Catalogs in Xcode |
| Wrong translation | Edit XLIFF, re-import |

## Adding a New Language

1. Xcode → Project → Info → Localizations → "+"
2. Select language
3. Run export script
4. Translate `.xcloc`
5. Run import script
6. Update script with new language code

## Translation Tools

- **Xcode** (Free) - Built-in editor
- **Crowdin** - Cloud platform
- **Transifex** - Enterprise
- **POEditor** - Web-based
- **Lokalise** - Continuous localization

## Resources

- Workflow Guide: `LOCALIZATION_WORKFLOW.md`
- Export Summary: `LOCALIZATION_EXPORT_SUMMARY.md`
- Apple Docs: [developer.apple.com/localization](https://developer.apple.com/documentation/xcode/localization)

## Quick Tips

✅ Export before major releases  
✅ Test each language thoroughly  
✅ Use context comments for translators  
✅ Keep String Catalogs in version control  
✅ Automate export/import in CI/CD  

---

**Last Updated**: December 27, 2025  
**Export Version**: Xcode 26.2
