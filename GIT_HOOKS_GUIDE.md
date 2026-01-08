# Git Pre-Commit Hook Configuration

## Overview

Itori enforces **accessibility** and **localization** standards automatically via Git pre-commit hooks.

Every commit is validated to ensure:
- ✅ Proper VoiceOver accessibility labels
- ✅ Localized user-facing strings
- ✅ No hardcoded text
- ✅ Decorative elements marked appropriately

---

## What Gets Checked

### Accessibility Validation

The pre-commit hook checks for:

1. **Icon-only buttons without labels**
   ```swift
   // ❌ BLOCKED
   Button { action() } label: {
       Image(systemName: "plus")
   }
   
   // ✅ PASSES
   Button { action() } label: {
       Image(systemName: "plus")
   }
   .accessibilityLabel("Add item")
   ```

2. **Decorative images not hidden**
   ```swift
   // ⚠️  WARNING (suggests fix)
   Image(systemName: "sparkles")
       .font(.largeTitle)
   
   // ✅ PASSES
   Image(systemName: "sparkles")
       .font(.largeTitle)
       .accessibilityHidden(true)
   ```

3. **Fixed font sizes instead of semantic**
   ```swift
   // ⚠️  WARNING
   .font(.system(size: 16))
   
   // ✅ PASSES
   .font(.body)
   ```

4. **Toggles without descriptive labels**
   ```swift
   // ⚠️  WARNING
   Toggle(isOn: $setting) {
       Text("Setting")
   }
   
   // ✅ PASSES
   Toggle(isOn: $setting) {
       VStack(alignment: .leading) {
           Text("Setting")
           Text("Description")
               .font(.caption)
       }
   }
   ```

### Localization Validation

The pre-commit hook checks for:

1. **Hardcoded user-facing text**
   ```swift
   // ⚠️  WARNING
   Text("Hello World")
   
   // ✅ PASSES
   Text(NSLocalizedString("greeting", value: "Hello World", comment: ""))
   ```

2. **Alert dialogs with hardcoded strings**
   ```swift
   // ⚠️  WARNING
   .alert("Error", message: "Something went wrong")
   
   // ✅ PASSES
   .alert(NSLocalizedString("error", ...), message: ...)
   ```

3. **Missing localization keys**
   - Validates that all NSLocalizedString keys exist in Localizable.strings

---

## Hook Behavior

### Warnings vs Errors

- **Errors** (❌): Block commit, must be fixed
- **Warnings** (⚠️): Prompt for confirmation, can proceed

Most issues are **warnings** - the hook will ask:
```
⚠️  5 accessibility warning(s) found

These are suggestions for improvement.
Review them and consider making changes.

Continue with commit anyway? (y/N)
```

You can choose to:
- Fix the issues and try again
- Proceed anyway (press `y`)
- Cancel the commit (press `n`)

### Bypassing the Hook

If you need to bypass validation (not recommended):

```bash
git commit --no-verify
```

Use this only for:
- Emergency hotfixes
- Generated code
- Non-UI changes that trigger false positives

---

## Files Checked

The hooks validate:
- ✅ All `.swift` files in `Platforms/iOS/`
- ✅ All `.swift` files in `Platforms/macOS/`
- ✅ All `.swift` files in `SharedCore/`

**Skipped:**
- ❌ Test files (`*Tests/`, `*UITests/`)
- ❌ Model files (`*Model*.swift`)
- ❌ Store files (`*Store*.swift`)
- ❌ Manager files (`*Manager*.swift`)

---

## Scripts Location

```
Scripts/
├── validate-accessibility.sh   # Accessibility checks
└── validate-localization.sh    # Localization checks

.git/hooks/
└── pre-commit                  # Main hook (calls both scripts)
```

---

## Installation

Already installed! The hooks are active and will run automatically.

To verify:
```bash
# Check if hooks are executable
ls -la .git/hooks/pre-commit
ls -la Scripts/validate-*.sh

# Should show -rwxr-xr-x (executable)
```

---

## Testing the Hook

### Test accessibility validation:

```bash
# Create a test file with accessibility issues
cat > test.swift << 'EOF'
import SwiftUI

struct TestView: View {
    var body: some View {
        Button {
            print("Test")
        } label: {
            Image(systemName: "plus")
        }
    }
}
EOF

git add test.swift
git commit -m "Test commit"
# Should warn about missing accessibility label

rm test.swift
```

### Test localization validation:

```bash
# Create a test file with hardcoded strings
cat > test.swift << 'EOF'
import SwiftUI

struct TestView: View {
    var body: some View {
        Text("Hello World")
    }
}
EOF

git add test.swift
git commit -m "Test commit"
# Should warn about hardcoded string

rm test.swift
```

---

## Customizing Rules

### Adding new patterns to check:

Edit `Scripts/validate-accessibility.sh`:

```bash
# Add to the decorative_patterns array
decorative_patterns=(
    "chevron\."
    "\.badge"
    "your-pattern-here"
)
```

### Changing warning/error thresholds:

Edit the scripts to change when warnings become errors:

```bash
# In validate-accessibility.sh or validate-localization.sh
if [ $WARNINGS -gt 10 ]; then
    # Convert to error
    ERRORS=$WARNINGS
fi
```

---

## Troubleshooting

### Hook not running?

```bash
# Ensure hooks directory exists
ls -la .git/hooks/

# Ensure pre-commit is executable
chmod +x .git/hooks/pre-commit
chmod +x Scripts/validate-*.sh
```

### False positives?

Add patterns to skip in the validation scripts:

```bash
# In validate-accessibility.sh, add to skip conditions
if [[ $file == *"YourFile"* ]]; then
    return 0
fi
```

### Hook runs but shows errors?

Check the output carefully:
- File path and line number are provided
- Example of what to fix is shown
- You can proceed anyway if needed

---

## Best Practices

1. **Fix warnings as you go** - Don't accumulate them
2. **Use semantic patterns** - Follow the examples in the warnings
3. **Test before committing** - Run the app and verify accessibility
4. **Ask for review** - If unsure about a warning, ask for help

---

## Benefits

✅ **Consistent quality** - Every commit meets standards  
✅ **Early detection** - Catch issues before code review  
✅ **Learning tool** - Teaches best practices automatically  
✅ **Accessibility-first** - Makes inclusive design automatic  
✅ **Localization-ready** - Ensures app can be translated  

---

## Example Workflow

```bash
# 1. Make changes to code
vim Platforms/iOS/Scenes/MyView.swift

# 2. Stage changes
git add Platforms/iOS/Scenes/MyView.swift

# 3. Attempt commit
git commit -m "Add new feature"

# 4. Hook runs automatically
╔══════════════════════════════════════════════════════════════╗
║         Itori Pre-Commit Validation                          ║
║    Accessibility & Localization Quality Checks               ║
╚══════════════════════════════════════════════════════════════╝

🔍 Validating Accessibility Implementation...

⚠️  WARNING: Button with icon missing accessibility label
   File: Platforms/iOS/Scenes/MyView.swift:42
   Add: .accessibilityLabel("Description")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  1 accessibility warning(s) found

Continue with commit anyway? (y/N)

# 5. Choose to fix or proceed
# If you fix: Cancel (N), fix the issue, stage, commit again
# If you proceed: Press Y, commit goes through
```

---

## Related Documentation

- **VOICEOVER_FINAL_STATUS.md** - VoiceOver implementation status
- **ACCESSIBILITY_STATUS.md** - Overall accessibility status
- **REQUIRED_ACCESSIBILITY_FEATURES.md** - Complete accessibility guide
- **COMPREHENSIVE_LOCALIZATION_GUIDE.md** - Localization best practices

---

## Support

If you have questions or encounter issues:
1. Check this documentation
2. Review the script output carefully
3. Look at existing code for examples
4. Use `git commit --no-verify` only as last resort

**The hooks are your friend!** They help maintain the high quality and accessibility standards that make Itori great for all users.
