# Localization System Documentation

> **Welcome to the Itori Localization System**
> 
> This directory contains everything you need to understand and work with the automated localization enforcement system.

## 📚 Documentation Files

### For New Developers
1. **[LOCALIZATION_QUICK_REFERENCE.md](./LOCALIZATION_QUICK_REFERENCE.md)** ⭐️ START HERE
   - Quick setup instructions
   - Daily workflow guide
   - Common patterns and shortcuts
   - Troubleshooting tips

### For Deep Understanding
2. **[LOCALIZATION_README.md](./LOCALIZATION_README.md)**
   - Complete system documentation
   - Key naming conventions
   - Manual localization guidelines
   - Testing procedures
   - Adding new languages

### For Team Leads
3. **LOCALIZATION_ENFORCEMENT_SUMMARY.md** (this directory)
   - System architecture
   - Benefits and metrics
   - Team onboarding process
   - Configuration options

## 🛠 Tools

### Scripts in This Directory

- **`localize_swift.py`** - Automated localization tool
  ```bash
  python3 Scripts/localize_swift.py <file_or_directory>
  ```

- **`setup_git_hooks.sh`** - Git hooks installer
  ```bash
  ./Scripts/setup_git_hooks.sh
  ```

## 🚀 Quick Start (30 seconds)

```bash
# 1. Install the pre-commit hook
./Scripts/setup_git_hooks.sh

# 2. Read the quick reference
cat Scripts/LOCALIZATION_QUICK_REFERENCE.md

# 3. Start coding with proper localization!
```

## 📊 System Status

- ✅ **Pre-commit hook**: Active
- ✅ **Automation script**: Ready
- ✅ **Documentation**: Complete
- 📈 **Coverage**: 86% (925/1071 strings)

## 🎯 Common Tasks

### "I'm creating a new UI file"
→ Write localized strings from the start:
```swift
Text(NSLocalizedString("key", value: "Text", comment: "Description"))
```

### "My commit was blocked"
→ Run the auto-fixer:
```bash
python3 Scripts/localize_swift.py path/to/File.swift
```

### "I need to bypass the hook urgently"
→ Use with caution:
```bash
git commit --no-verify
```

### "I want to localize existing files"
→ Process directory:
```bash
python3 Scripts/localize_swift.py Platforms/macOS/Views/
```

## 📖 Reading Order

**For developers new to the project:**
1. LOCALIZATION_QUICK_REFERENCE.md (5 min read)
2. Try writing a localized Text() component
3. Try committing it
4. Read LOCALIZATION_README.md for deeper understanding

**For team leads:**
1. LOCALIZATION_ENFORCEMENT_SUMMARY.md
2. LOCALIZATION_README.md
3. Review Scripts/localize_swift.py

## 🔗 Related Files

- **String Catalog**: `SharedCore/DesignSystem/Localizable.xcstrings`
- **Git Hook**: `.git/hooks/pre-commit`
- **Example**: `Platforms/macOS/Views/AISettingsView.swift` (fully localized)

## 💡 Key Principles

1. **Localize Early** - Write localized from the start
2. **Consistent Keys** - Follow the naming pattern
3. **Good Comments** - Help translators understand context
4. **Test Languages** - Check UI with different languages
5. **Automation First** - Use the script before manual work

## 📞 Getting Help

- **Quick answers**: Check LOCALIZATION_QUICK_REFERENCE.md
- **Technical details**: Check LOCALIZATION_README.md
- **Issues**: Create GitHub issue with `localization` label
- **Questions**: Ask in team chat with `#localization` tag

## 🎓 Success Criteria

You know the system well when you can:
- [ ] Write a new localized Text() without looking it up
- [ ] Fix a blocked commit in under 30 seconds
- [ ] Explain the key naming pattern to a teammate
- [ ] Add a new language to the app

## 🏆 Best Practices

✅ **DO**
- Use descriptive localization keys
- Add helpful comments for translators
- Test with multiple languages
- Run the automation script

❌ **DON'T**
- Hardcode strings (the hook will catch you!)
- Use generic keys like "text1"
- Bypass the hook without good reason
- Forget to test RTL languages

---

**System maintained by**: Development Team  
**Last updated**: 2026-01-04  
**Questions?** Check the docs or ask in chat!
