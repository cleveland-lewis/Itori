# Pre-Commit Hook Quick Reference

## What It Checks

### ✅ Accessibility
- Icon-only buttons need labels
- Decorative images should be hidden
- Use semantic fonts, not fixed sizes
- Toggles need descriptive labels

### ✅ Localization
- No hardcoded user-facing text
- Alerts must be localized
- All keys must exist in Localizable.strings

---

## Common Fixes

### Icon Button Without Label
```swift
// ❌ Before
Button { action() } label: {
    Image(systemName: "plus")
}

// ✅ After
Button { action() } label: {
    Image(systemName: "plus")
}
.accessibilityLabel("Add item")
.accessibilityHint("Opens form to create item")
```

### Decorative Image
```swift
// ❌ Before
Image(systemName: "sparkles")
    .foregroundStyle(.blue)

// ✅ After
Image(systemName: "sparkles")
    .foregroundStyle(.blue)
    .accessibilityHidden(true)
```

### Hardcoded Text
```swift
// ❌ Before
Text("Hello World")

// ✅ After
Text(NSLocalizedString("greeting", value: "Hello World", comment: "Greeting message"))
```

### Fixed Font Size
```swift
// ❌ Before
.font(.system(size: 16))

// ✅ After
.font(.body)
```

---

## Bypass Hook (Emergency Only)

```bash
git commit --no-verify
```

---

## Files Checked
- ✅ `Platforms/iOS/**/*.swift`
- ✅ `Platforms/macOS/**/*.swift`
- ✅ `SharedCore/**/*.swift`
- ❌ `*Tests/` (skipped)
- ❌ `*Model.swift` (skipped)

---

## Hook Response Options

When warnings appear:
- **N** = Cancel commit, fix issues
- **Y** = Proceed anyway
- **Ctrl+C** = Abort

---

## Quick Test

```bash
# Test if hooks work
echo 'Text("test")' > test.swift
git add test.swift
git commit -m "test"
# Should show warning

rm test.swift
```

---

Read full guide: **GIT_HOOKS_GUIDE.md**
