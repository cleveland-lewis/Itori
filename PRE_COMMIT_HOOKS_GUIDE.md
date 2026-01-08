# Pre-Commit Hooks Guide

## 🎯 Overview

Comprehensive pre-commit validation system that runs **13 checks** before each commit to ensure code quality, security, and compliance.

## 📋 Checks Performed

### Critical Checks (Block Commit on Failure)

1. **⚔️  Merge Conflict Markers**
   - Detects: `<<<<<<<`, `=======`, `>>>>>>>` in staged files
   - Why: Prevents committing unresolved conflicts
   - Fix: Resolve conflicts and stage clean files

2. **📦 Large File Detection**
   - Limit: 5MB per file (configurable)
   - Why: Prevents repo bloat
   - Fix: Use Git LFS for large assets

3. **🖨️  Print Statement Detection**
   - Detects: `print(`, `NSLog(`, `debugPrint(` (excluding DebugLogger)
   - Why: Debug statements shouldn't reach production
   - Fix: Use `DebugLogger` or remove prints

4. **🔨 Build Verification**
   - Compiles: iOS scheme on iPhone 15 simulator
   - Why: Ensures code compiles before commit
   - Duration: ~30-60 seconds (cached builds faster)

### Warning Checks (Don't Block Commit)

5. **🔒 Security Sensitive Code**
   - Detects: Hardcoded passwords, API keys, suspicious patterns
   - Why: Prevents credential leaks
   - Action: Review carefully, don't commit secrets

6. **📝 TODO/FIXME Comments**
   - Detects: `TODO`, `FIXME` in Swift files
   - Why: Track technical debt properly
   - Suggestion: Create GitHub issues instead

7. **📦 Swift Package Resolved**
   - Checks: If Package.swift changed, Package.resolved should too
   - Why: Lock dependency versions
   - Fix: Run `swift package resolve`

8. **🎨 Asset Validation**
   - Checks: `.xcassets` structure validity
   - Why: Prevents corrupt asset catalogs
   - Fix: Verify Contents.json files exist

9. **🧹 SwiftLint**
   - Runs: SwiftLint on staged Swift files
   - Why: Enforces code style consistency
   - Install: `brew install swiftlint`
   - Fix: `swiftlint --fix`

10. **🔢 Version Sync**
    - Checks: VERSION file matches Xcode project
    - Script: `Scripts/check_version_sync.sh`
    - Why: Prevents version mismatches

11. **🧵 Threading Safety**
    - Checks: @MainActor usage, potential race conditions
    - Script: `Scripts/check_threading_safety.sh`
    - Why: Catches concurrency bugs early

12. **♿ Accessibility Validation**
    - Checks: VoiceOver labels, semantic sizes, etc.
    - Script: `Scripts/validate-accessibility.sh`
    - Why: Ensures app is accessible

13. **🌍 Localization Validation**
    - Checks: NSLocalizedString usage, missing translations
    - Script: `Scripts/validate-localization.sh`
    - Why: Ensures proper i18n support

## ⚙️ Configuration

### Enable/Disable Specific Checks

Edit `.git-hooks-config` in the repository root:

```bash
# Disable TODO/FIXME warnings
CHECK_TODO_FIXME=false

# Disable build check (faster commits, use with caution)
CHECK_BUILD=false

# Increase file size limit to 10MB
MAX_FILE_SIZE=10485760
```

### Available Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `CHECK_MERGE_CONFLICTS` | `true` | Detect conflict markers |
| `CHECK_LARGE_FILES` | `true` | Check file sizes |
| `CHECK_PRINT_STATEMENTS` | `true` | Detect print statements |
| `CHECK_BUILD` | `true` | Verify code compiles |
| `CHECK_SECURITY` | `true` | Security pattern detection |
| `CHECK_TODO_FIXME` | `true` | TODO/FIXME detection |
| `CHECK_SWIFT_PACKAGE` | `true` | Package.resolved sync |
| `CHECK_ASSETS` | `true` | Asset catalog validation |
| `CHECK_SWIFTLINT` | `true` | SwiftLint style checking |
| `CHECK_VERSION_SYNC` | `true` | Version number consistency |
| `CHECK_THREADING` | `true` | Threading safety checks |
| `CHECK_ACCESSIBILITY` | `true` | Accessibility validation |
| `CHECK_LOCALIZATION` | `true` | Localization validation |
| `MAX_FILE_SIZE` | `5242880` | Max file size (bytes) |
| `BUILD_CACHE_MINUTES` | `5` | Build cache duration |

## 🚀 Quick Start

### First Time Setup

The hook is already installed at `.git/hooks/pre-commit`. Just commit as normal:

```bash
git add .
git commit -m "feat(auth): add oauth2 support"
```

### Bypassing Checks (Emergency Use Only)

If you need to commit despite failures:

```bash
git commit --no-verify -m "your message"
```

⚠️ **Use sparingly!** Bypassing checks can lead to broken code in the repository.

## 📊 Example Output

### ✅ Successful Run

```
╔══════════════════════════════════════════════════════════════╗
║         Itori Comprehensive Pre-Commit Validation            ║
╚══════════════════════════════════════════════════════════════╝

⚔️  Checking for merge conflict markers...
✅ No conflict markers found

📦 Checking file sizes...
✅ All files within size limits

🔒 Checking for security concerns...
✅ No obvious security concerns

🖨️  Checking for debug print statements...
✅ No print statements found

🔨 Building project to verify code compiles...
   (This may take a minute...)
✅ Build successful!

♿ Running accessibility validation...
✅ Accessibility checks passed

🌍 Running localization validation...
✅ Localization checks passed

╔══════════════════════════════════════════════════════════════╗
║  ✅ All critical validations passed!                         ║
║  ⚠️  2 warning(s) found (not blocking)                       ║
║                Proceeding with commit...                     ║
╚══════════════════════════════════════════════════════════════╝
```

### ❌ Failed Run

```
🖨️  Checking for debug print statements...
❌ Found print statements. Use DebugLogger instead:
+        print("Debug: User logged in")
+        print("Token: \(token)")

🔨 Building project to verify code compiles...
❌ Build failed with errors:
error: Use of unresolved identifier 'userService'

╔══════════════════════════════════════════════════════════════╗
║  ❌ 2 critical error(s) found                                ║
║  ⚠️  1 warning(s) found                                      ║
║                                                              ║
║  Fix the errors above or bypass with:                       ║
║  git commit --no-verify                                      ║
╚══════════════════════════════════════════════════════════════╝
```

## ⏱️ Performance

- **Quick checks** (conflict markers, file sizes, etc.): <1 second
- **Code analysis** (SwiftLint, patterns): 1-3 seconds
- **Build verification**: 30-60 seconds (first build), 5-15 seconds (cached)
- **Total**: Typically 40-70 seconds for full validation

### Speed Optimization Tips

1. **Disable build check during rapid iteration**:
   ```bash
   # In .git-hooks-config
   CHECK_BUILD=false
   ```

2. **Use build caching**: The hook respects recent builds (5 min default)

3. **Stage only changed files**: Smaller diffs = faster checks

4. **Skip validation temporarily**: `git commit --no-verify` (use sparingly)

## 🐛 Troubleshooting

### Hook not running?

```bash
# Verify hook is executable
ls -la .git/hooks/pre-commit

# Should show: -rwxr-xr-x

# If not, make it executable
chmod +x .git/hooks/pre-commit
```

### Build check taking too long?

```bash
# Disable for faster commits
echo "CHECK_BUILD=false" >> .git-hooks-config
```

### SwiftLint not found?

```bash
# Install SwiftLint
brew install swiftlint

# Or disable the check
echo "CHECK_SWIFTLINT=false" >> .git-hooks-config
```

### False positives?

Adjust patterns in the hook script:
```bash
# Edit .git/hooks/pre-commit
# Modify the grep patterns for your needs
```

## 📚 Best Practices

1. ✅ **Run full validation before pushing** - Even if you bypass locally
2. ✅ **Keep checks enabled** - They catch bugs early
3. ✅ **Fix warnings** - Don't let them accumulate
4. ✅ **Use --no-verify sparingly** - Only for emergency commits
5. ✅ **Install SwiftLint** - Enforces consistent code style
6. ✅ **Review security warnings** - Always investigate sensitive code flags

## 🔄 Updating the Hook

The hook is not tracked by git (it's in `.git/hooks/`). To update:

1. Make changes to the hook in your editor
2. Or copy from a backup/team shared version
3. Ensure it remains executable: `chmod +x .git/hooks/pre-commit`

## 📝 Related Documentation

- [STRICT_COMMIT_RULES.md](STRICT_COMMIT_RULES.md) - Commit message format rules
- [COMMIT_GUIDELINES.md](.github/COMMIT_GUIDELINES.md) - Detailed commit guidelines
- [GIT_HOOKS_GUIDE.md](GIT_HOOKS_GUIDE.md) - Git hooks overview
- [TESTING_QUICK_START.md](TESTING_QUICK_START.md) - Testing guide

## 🎓 Examples

### Scenario: Adding a New Feature

```bash
# 1. Make changes
vim Platforms/iOS/Scenes/NewFeatureView.swift

# 2. Stage changes
git add Platforms/iOS/Scenes/NewFeatureView.swift

# 3. Commit (hooks run automatically)
git commit -m "feat(ui): add new feature view"

# Output shows all checks passing ✅
# Commit succeeds!
```

### Scenario: Quick Fix, Skip Heavy Checks

```bash
# 1. Make quick documentation fix
vim README.md

# 2. Disable build check temporarily
echo "CHECK_BUILD=false" >> .git-hooks-config

# 3. Commit
git commit -m "docs: fix typo in readme"

# 4. Re-enable for next commit
git checkout .git-hooks-config
```

## 📊 Statistics

Track your code quality over time:

```bash
# Count commits with bypassed hooks
git log --all --grep="--no-verify" --oneline | wc -l

# View recent validation history
git log -20 --pretty=format:"%h %s" | head
```

## ✨ Summary

The pre-commit hook system provides:
- ✅ **13 comprehensive checks**
- ✅ **Configurable** - Enable/disable specific checks
- ✅ **Fast** - Optimized for performance
- ✅ **Informative** - Clear error messages
- ✅ **Bypassable** - For emergency situations
- ✅ **Battle-tested** - Catches real issues

**Result**: Higher code quality, fewer bugs, and professional git history! 🎉

---

**Last Updated**: 2026-01-08  
**Version**: 2.0  
**Status**: ✅ Active
