# Pre-Commit Hooks Quick Reference

## 🎯 What Gets Checked (13 Checks)

| Check | Type | Time | Fix |
|-------|------|------|-----|
| ⚔️  Merge conflicts | Error | <1s | Resolve conflicts |
| 📦 Large files (>5MB) | Error | <1s | Use Git LFS |
| 🖨️  Print statements | Error | 1-2s | Use DebugLogger |
| 🔨 Build verification | Error | 30-60s | Fix build errors |
| 🔒 Security patterns | Warn | 1s | Review code |
| 📝 TODO/FIXME | Warn | 1s | Create issues |
| 📦 Package.resolved | Warn | <1s | Run resolve |
| 🎨 Asset catalogs | Warn | <1s | Fix structure |
| 🧹 SwiftLint | Warn | 2-5s | swiftlint --fix |
| 🔢 Version sync | Warn | 1s | Update VERSION |
| 🧵 Threading safety | Warn | 2-3s | Add @MainActor |
| ♿ Accessibility | Warn | 5-10s | Add labels |
| 🌍 Localization | Warn | 2-5s | Add translations |

**Total**: ~50-90 seconds

---

## ⚡ Quick Commands

```bash
# Normal commit (all checks)
git commit -m "feat(auth): add oauth2 support"

# Emergency bypass (use sparingly!)
git commit --no-verify -m "hotfix: critical bug"

# Disable build for speed
echo "CHECK_BUILD=false" >> .git-hooks-config

# Re-enable all
git checkout .git-hooks-config

# Test hook manually
.git/hooks/pre-commit
```

---

## 🚨 Common Errors & Quick Fixes

### ❌ Print Statements Found
```swift
// ❌ Bad
print("Debug: \(value)")

// ✅ Good
DebugLogger.log("Debug: \(value)")
```

### ❌ Build Failed
```bash
# Fix build first
xcodebuild -project ItoriApp.xcodeproj \
  -scheme "Itori (iOS)" build

# Then commit
git commit -m "fix: build error"
```

### ❌ Merge Conflict Markers
```bash
# Find conflicts
git diff --check

# Remove <<<<<<<, =======, >>>>>>>
# Stage clean files
git add file.swift
```

### ⚠️  SwiftLint Issues
```bash
# Auto-fix
swiftlint --fix

# Install if missing
brew install swiftlint
```

### ⚠️  Accessibility - Icon Button
```swift
// ❌ Before
Button { action() } label: {
    Image(systemName: "plus")
}

// ✅ After
Button { action() } label: {
    Image(systemName: "plus")
        .accessibilityHidden(true)
}
.accessibilityLabel("Add item")
```

### ⚠️  Localization - Hardcoded Text
```swift
// ❌ Before
Text("Hello World")

// ✅ After
Text(NSLocalizedString("greeting", 
  value: "Hello World", 
  comment: "Greeting"))
```

---

## ⚙️ Configuration (.git-hooks-config)

```bash
# Skip slow build check
CHECK_BUILD=false

# Allow TODOs
CHECK_TODO_FIXME=false

# Increase file limit to 10MB
MAX_FILE_SIZE=10485760

# Disable specific checks
CHECK_SWIFTLINT=false
CHECK_ACCESSIBILITY=false
CHECK_THREADING=false
```

---

## 📊 What Each Symbol Means

- ✅ **Green check** = Passed
- ⚠️  **Yellow warning** = Warning (doesn't block)
- ❌ **Red X** = Error (blocks commit)

---

## 🆘 Emergency Override

Only use when **absolutely necessary**:

```bash
git commit --no-verify -m "emergency: production fix"
```

⚠️ **Warning**: Can break builds and introduce bugs!

---

## 💡 Pro Tips

1. **Run checks before staging**:
   ```bash
   .git/hooks/pre-commit  # Test first
   git add . && git commit -m "msg"
   ```

2. **Speed up commits**:
   - Disable build check during rapid iteration
   - Re-enable before pushing

3. **Fix warnings early**:
   - Don't let them pile up
   - Address TODO/FIXME with GitHub issues

4. **Use SwiftLint auto-fix**:
   ```bash
   swiftlint --fix
   git add .
   git commit -m "style: apply swiftlint fixes"
   ```

---

## 📖 Full Documentation

- **Detailed guide**: `PRE_COMMIT_HOOKS_GUIDE.md`
- **Setup instructions**: `GIT_HOOKS_SETUP_COMPLETE.md`
- **Commit format rules**: `STRICT_COMMIT_RULES.md`

---

**Last Updated**: 2026-01-08  
**Hook Version**: 2.0
