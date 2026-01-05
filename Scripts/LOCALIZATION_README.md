# Localization Automation Guide

## 📊 Current Status

- **Total Localized**: 925 strings
- **Remaining**: 146 strings (mostly dynamic content)
- **Progress**: 86% complete
- **Files Modified**: 66+ files
- **✅ Pre-commit Hook**: Enabled - Blocks unlocalizable strings

## ⚠️ Important: Pre-commit Hook Active

A Git pre-commit hook is installed that **blocks commits** containing hardcoded strings.

### First Time Setup

```bash
# Run this once after cloning the repo
./Scripts/setup_git_hooks.sh
```

### What the Hook Does

- ✅ Automatically checks all Swift UI files for hardcoded strings
- 🚫 Blocks commits containing `Text("...")`, `Label("...")`, `Button("...")` without localization
- 💡 Suggests using the localization script to fix issues
- ⏭️ Allows bypass with `git commit --no-verify` (not recommended)

### Quick Fix for Blocked Commits

```bash
# If your commit is blocked, run:
python3 Scripts/localize_swift.py path/to/YourFile.swift

# Then stage and commit again
git add path/to/YourFile.swift
git commit -m "Your message"
```

## 🛠 Automation Script

### Location
`Scripts/localize_swift.py`

### Usage

```bash
# Localize a single file
python3 Scripts/localize_swift.py Platforms/macOS/Views/SomeView.swift

# Localize an entire directory
python3 Scripts/localize_swift.py Platforms/macOS/Views/

# Localize all scenes
python3 Scripts/localize_swift.py Platforms/macOS/Scenes/
```

### What It Does

The script automatically:
1. Finds hardcoded strings in `Text()`, `Label()`, `Button()`, `Toggle()` calls
2. Generates contextual localization keys
3. Wraps strings in `NSLocalizedString()`
4. Adds descriptive comments
5. Skips already localized files

### Example Transformation

**Before:**
```swift
Text("Privacy & Security")
Button("Save Changes")
Label("Notifications", systemImage: "bell")
```

**After:**
```swift
Text(NSLocalizedString("settings.privacy.security", value: "Privacy & Security", comment: "Privacy & Security"))
Button(NSLocalizedString("settings.button.save.changes", value: "Save Changes", comment: "Save Changes"))
Label(NSLocalizedString("settings.label.notifications", value: "Notifications", comment: "Notifications"), systemImage: "bell")
```

## 🔑 Key Naming Convention

Keys follow the pattern: `{category}.{element_type}.{simplified_text}`

### Categories
- `settings.*` - Settings views
- `dashboard.*` - Dashboard related
- `timer.*` - Timer features
- `planner.*` - Planner features
- `grades.*` - Grades views
- `courses.*` - Course management
- `ui.*` - Generic UI elements

### Element Types
- `.title` - Section/page titles
- `.button.{action}` - Button labels
- `.label.{name}` - Label text
- `.toggle.{name}` - Toggle labels
- `.description` - Descriptive text
- `.message` - Alert/message text

## 📝 Manual Localization Needed

Some strings require manual attention:

### 1. String Interpolation
```swift
// Needs manual localization
Text("\(count) items")
Text("Size: \(size)")

// Should be:
Text(String(format: NSLocalizedString("items.count", value: "%d items", comment: "Item count"), count))
```

### 2. Dynamic Content
```swift
// Complex formatting
Text("\(event.task.displayName) • \(event.latencyMs)ms")

// Should use String.localizedStringWithFormat
```

### 3. Plurals
Use `.stringsdict` for proper plural handling:
```xml
<key>items.count</key>
<dict>
    <key>NSStringLocalizedFormatKey</key>
    <string>%#@items@</string>
    <key>items</key>
    <dict>
        <key>NSStringFormatSpecTypeKey</key>
        <string>NSStringPluralRuleType</string>
        <key>NSStringFormatValueTypeKey</key>
        <string>d</string>
        <key>zero</key>
        <string>No items</string>
        <key>one</key>
        <string>1 item</string>
        <key>other</key>
        <string>%d items</string>
    </dict>
</dict>
```

## 🌍 Adding Translations

### Using Xcode String Catalog

1. Open `SharedCore/DesignSystem/Localizable.xcstrings`
2. Click "+" to add a new language
3. Export for translation: Editor → Export Localizations
4. Import translations: Editor → Import Localizations

### Supported Languages
- English (en) - Base
- Spanish (es)
- German (de)
- French (fr)
- Japanese (ja)
- Chinese Simplified (zh-Hans)
- Chinese Traditional (zh-Hant)
- Arabic (ar)
- Dutch (nl)
- Thai (th)

## 🔍 Finding Remaining Hardcoded Strings

```bash
# Find all remaining hardcoded strings
grep -rn 'Text("\|Label("\|Button("' Platforms/macOS --include="*.swift" \
  | grep -v 'NSLocalizedString\|LocalizedStringKey\|\.localized' \
  | grep -v 'Text("\\' > remaining_strings.txt

# Count by file
grep -rn 'Text("\|Label("\|Button("' Platforms/macOS --include="*.swift" \
  | grep -v 'NSLocalizedString' \
  | cut -d: -f1 | sort | uniq -c | sort -rn
```

## ✅ Testing Localizations

### In Xcode
1. Edit Scheme → Options → Application Language
2. Select target language
3. Run app to verify translations

### Programmatically
```swift
// Force a specific language for testing
UserDefaults.standard.set(["de"], forKey: "AppleLanguages")
```

## 🐛 Common Issues

### Issue: "Missing localization key"
**Solution**: The key doesn't exist in Localizable.xcstrings. Add it manually or regenerate the catalog.

### Issue: "Incorrect plural form"
**Solution**: Use `.stringsdict` file for proper plural rules instead of simple NSLocalizedString.

### Issue: "String not updating"
**Solution**: Clean build folder (Cmd+Shift+K) and rebuild.

## 📦 Future Improvements

- [ ] Add support for SwiftUI's `LocalizedStringKey` initializers
- [ ] Handle attributed strings
- [ ] Support for markdown in strings
- [ ] Auto-generate `.stringsdict` for plurals
- [ ] Integration with translation services (Lokalise, Crowdin)
- [ ] Git pre-commit hook to check for new hardcoded strings

## 🤝 Contributing

When adding new UI strings:
1. **Always use NSLocalizedString** from the start
2. Use descriptive keys following the naming convention
3. Add helpful comments explaining context
4. Test with at least one non-English language
5. Run the localization script before committing: `python3 Scripts/localize_swift.py .`

## 📚 Resources

- [Apple Localization Guide](https://developer.apple.com/localization/)
- [String Catalogs Documentation](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [NSLocalizedString Best Practices](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html)
