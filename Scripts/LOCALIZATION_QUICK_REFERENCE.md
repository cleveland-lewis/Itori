# Localization Quick Reference

## 🚀 For New Developers

### Setup (Once)
```bash
./Scripts/setup_git_hooks.sh
```

## 📝 Daily Workflow

### When Creating New UI
```swift
// ❌ DON'T DO THIS:
Text("Hello World")
Button("Save") { }
Label("Settings", systemImage: "gear")

// ✅ DO THIS:
Text(NSLocalizedString("greeting", value: "Hello World", comment: "Greeting message"))
Button(NSLocalizedString("button.save", value: "Save", comment: "Save button")) { }
Label(NSLocalizedString("label.settings", value: "Settings", comment: "Settings label"), systemImage: "gear")
```

### When Git Blocks Your Commit

```bash
# Step 1: Run the auto-fix script
python3 Scripts/localize_swift.py path/to/YourFile.swift

# Step 2: Review the changes
git diff path/to/YourFile.swift

# Step 3: Stage and commit
git add path/to/YourFile.swift
git commit -m "Your message"
```

### Localization Script Usage

```bash
# Single file
python3 Scripts/localize_swift.py Platforms/macOS/Views/MyView.swift

# All files in a directory
python3 Scripts/localize_swift.py Platforms/macOS/Views/

# Preview changes without writing (dry run)
python3 Scripts/localize_swift.py --dry-run file.swift
```

## 🔑 Key Naming Pattern

Follow this pattern: `{category}.{type}.{description}`

### Categories
- `settings.*` - Settings screens
- `dashboard.*` - Dashboard
- `planner.*` - Planner features
- `grades.*` - Grades
- `courses.*` - Courses
- `timer.*` - Timer
- `{feature}.*` - Other features

### Types
- `.title` - Screen/section titles
- `.button.{action}` - Buttons
- `.label.{name}` - Labels
- `.toggle.{name}` - Toggles
- `.message` - Messages/descriptions
- `.alert.{name}` - Alert text

### Examples
```swift
// Good keys
"settings.privacy.title"
"dashboard.button.add.task"
"timer.label.duration"
"courses.alert.delete.confirm"

// Bad keys
"text1"
"string"
"hello_world"
```

## 🌍 String Interpolation

### For Simple Format Strings
```swift
// Before
Text("\(count) items")

// After
Text(String(format: NSLocalizedString("items.count", value: "%d items", comment: "Item count"), count))
```

### For Multiple Values
```swift
// Before
Text("\(name) has \(count) items")

// After
String(format: NSLocalizedString("user.items", value: "%@ has %d items", comment: "User's item count"), name, count)
```

## ⚡ Common Shortcuts

### VS Code Snippet (Add to `swift.json`)
```json
"Localized Text": {
    "prefix": "ltext",
    "body": [
        "Text(NSLocalizedString(\"${1:key}\", value: \"${2:text}\", comment: \"${3:description}\"))"
    ]
}
```

### Xcode Snippet
1. Write: `Text(NSLocalizedString("key", value: "Text", comment: ""))`
2. Select it
3. Right-click → Create Code Snippet
4. Title: "Localized Text"
5. Completion: `ltext`

## 🐛 Troubleshooting

### "My commit was blocked"
→ Run: `python3 Scripts/localize_swift.py <file>`

### "I need to commit urgently"
→ Use: `git commit --no-verify` (not recommended)

### "Localization script broke my code"
→ Check the syntax, report issue, revert with `git checkout <file>`

### "Key already exists"
→ Check `SharedCore/DesignSystem/Localizable.xcstrings`, use existing key or create unique one

## 📚 Resources

- Full guide: `Scripts/LOCALIZATION_README.md`
- Script location: `Scripts/localize_swift.py`
- Hook setup: `Scripts/setup_git_hooks.sh`
- String catalog: `SharedCore/DesignSystem/Localizable.xcstrings`

## 💡 Pro Tips

1. **Write localized from the start** - Easier than fixing later
2. **Use descriptive keys** - Future you will thank you
3. **Add good comments** - Helps translators understand context
4. **Test with other languages** - Catches layout issues early
5. **Keep keys organized** - Use consistent prefixes

## ❓ Need Help?

- Check: `Scripts/LOCALIZATION_README.md`
- Run: `python3 Scripts/localize_swift.py --help`
- Ask: Team lead or senior developer
