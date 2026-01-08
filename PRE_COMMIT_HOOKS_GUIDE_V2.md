# Pre-Commit Hooks System — Itori

**Version 2.0**

This document describes the comprehensive pre-commit hook system that enforces repository hygiene, code quality, and architectural safety before code reaches CI.

---

## Quick Start

The pre-commit hooks are automatically installed in `.git/hooks/`. They run on every commit.

### Installation Verification

```bash
# Check that hooks are executable
ls -la .git/hooks/pre-commit .git/hooks/commit-msg

# Test the hook (without committing)
./.git/hooks/pre-commit
```

### Bypassing Hooks (Emergency Only)

```bash
# Skip pre-commit validation
git commit --no-verify -m "Emergency fix"
```

⚠️ **Use `--no-verify` sparingly** — only in production emergencies or when the hook system itself is broken.

---

## What the Hooks Check

### 1. Repository Hygiene ✨

**Enforced:**
- ✅ No trailing whitespace
- ✅ Newline at end of file
- ✅ File size < 10MB
- ✅ No blocked file types (`.backup`, `.bak`, `.orig`, `.swp`, `.DS_Store`, `.xcuserstate`, `DerivedData/`, `.idea/`, `.vscode/`)
- ✅ No filenames with spaces
- ✅ Naming conventions:
  - Swift files: `UpperCamelCase.swift`
  - Docs/configs: `kebab-case.md` or `UPPER_SNAKE_CASE.md`

**Remediation:**
```bash
# Fix trailing whitespace
git diff --check

# Remove blocked files
git rm --cached .DS_Store
echo ".DS_Store" >> .gitignore
```

---

### 2. Swift Code Quality 🧹

**Enforced with SwiftLint:**
- ✅ No unused imports
- ✅ No force unwraps (unless whitelisted)
- ✅ No force casts
- ✅ Cyclomatic complexity < 25
- ✅ Function body length < 100 lines
- ✅ No `print()` statements (use `DebugLogger` instead)

**Enforced with SwiftFormat:**
- ✅ Consistent indentation (4 spaces)
- ✅ Sorted imports
- ✅ Consistent spacing
- ✅ Code width < 120 chars

**Remediation:**
```bash
# Auto-fix SwiftLint issues
swiftlint --fix

# Auto-format code
swiftformat .

# Re-stage files
git add <files>
```

**Installation (if not installed):**
```bash
brew install swiftlint swiftformat
```

---

### 3. App Rename Enforcement (Roots → Itori) 🏷️

**Blocks commits with "Roots" references in:**
- User-facing strings
- App target source files
- UI copy

**Allowed locations:**
- `_Deprecated_macOS/` (legacy code)
- `Tests/` (test fixtures)
- `Docs/` (documentation)
- Legacy module names: `RootsShared`, `RootsDesignSystem`, `RootsAnalogClock`

**Remediation:**
```bash
# Find all "Roots" references
grep -r "Roots" Platforms/ SharedCore/ --exclude-dir=_Deprecated_macOS

# Replace with "Itori"
# Add // Legacy: comment if it's a legacy module reference
```

---

### 4. Build Sanity Check 🔨

**Validates:**
- ✅ Swift package builds successfully (if `SharedCore/Package.swift` exists)
- ✅ Xcodebuild dry-run succeeds
- ✅ No missing files in targets
- ✅ No broken symbols

**Does NOT:**
- ❌ Run full app builds
- ❌ Run tests
- ❌ Build all platform targets

**Target Runtime:** < 5 seconds

**Remediation:**
```bash
# Build locally to identify issues
xcodebuild -project ItoriApp.xcodeproj -scheme Itori

# Or for Swift packages
cd SharedCore && swift build
```

---

### 5. Architectural Guardrails 🏗️

**Enforces platform boundaries:**

| Rule | Description | Example Violation |
|------|-------------|-------------------|
| SharedCore isolation | SharedCore cannot import app targets | `import Itori` in SharedCore |
| watchOS API safety | watchOS cannot use iOS-only APIs | `import UIKit` in watchOS code |
| macOS API safety | macOS cannot use UIKit | `import UIKit` in Platforms/macOS |

**Remediation:**
```bash
# Move shared code to SharedCore
# Use #if os(iOS) compiler directives for platform-specific code
# Use AppKit for macOS, WatchKit for watchOS
```

---

### 6. TODO/FIXME Policy 📝

**Blocks TODO/FIXME in production paths:**
- `Platforms/iOS/`
- `Platforms/macOS/`
- `SharedCore/Views/`
- `SharedCore/State/`

**Allows TODO/FIXME in:**
- `/Tests/` (test code)
- `/debug/` (debug utilities)
- `/experimental/` (experimental features)
- `Scripts/` (tooling)
- `_Deprecated_macOS/` (deprecated code)

**Remediation:**
```bash
# Create a GitHub issue instead
gh issue create --title "Refactor XYZ" --body "Details..."

# Reference the issue in code
# See: https://github.com/org/repo/issues/123
```

---

### 7. Commit Message Discipline ✍️

**Enforced:**
- ✅ No empty commit messages
- ✅ Subject line ≤ 72 characters (warning)
- ✅ No prohibited terms: `WIP`, `temp`, `fix later`, `temporary`, `test commit`

**Recommended format (Conventional Commits):**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Examples:**
```bash
# Good
git commit -m "feat(timer): add pause/resume functionality"
git commit -m "fix(calendar): resolve crash on event deletion"
git commit -m "docs: update installation guide"

# Bad (will be rejected)
git commit -m "WIP"
git commit -m "temp fix"
git commit -m "asdf"
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `perf`: Performance improvement
- `test`: Tests
- `chore`: Maintenance
- `build`: Build system
- `ci`: CI configuration

---

## Performance

**Target runtime:** < 15 seconds

The hooks are optimized for speed:
- Only check **staged files**
- Skip deprecated directories
- Use lightweight validation
- No full test suites
- No UI tests
- No network access

**Timing breakdown:**
1. Hygiene checks: ~1s
2. SwiftLint: ~3-5s
3. SwiftFormat: ~2-3s
4. Build sanity: ~5-8s
5. Other checks: ~1s

**Total:** ~12-18 seconds on average

---

## Configuration

### SwiftLint Configuration

Edit `.swiftlint.yml` to customize rules:

```yaml
disabled_rules:
  - line_length  # Disable line length check

force_unwrapping:
  severity: warning  # Downgrade to warning
```

### SwiftFormat Configuration

Edit `.swiftformat` to customize formatting:

```bash
--indent 2  # Use 2-space indentation
--maxwidth 100  # Set line width to 100
```

### Hook Configuration

The hooks read from `.git-hooks-config` (legacy) but are self-contained in v2.0.

To temporarily disable specific checks, edit `.git/hooks/pre-commit` directly (not recommended).

---

## Troubleshooting

### Hook is too slow

```bash
# Check what's taking time
time ./.git/hooks/pre-commit

# Temporarily disable build check
# Edit .git/hooks/pre-commit and comment out "Build Sanity Check" section
```

### False positives

```bash
# Add exception comments in code
import UIKit  // ALLOWED: Platform-specific adapter

# Or whitelist in hook script
# Edit ROOTS_WHITELIST or TODO_ALLOWED_PATHS in .git/hooks/pre-commit
```

### Hook not running

```bash
# Check executable permission
chmod +x .git/hooks/pre-commit .git/hooks/commit-msg

# Verify hook path
git config core.hooksPath  # Should be empty or .git/hooks
```

### SwiftLint/SwiftFormat not found

```bash
# Install tools
brew install swiftlint swiftformat

# Verify installation
which swiftlint swiftformat
```

---

## Integration with CI

The pre-commit hooks **do not replace CI**. They are a first line of defense.

**CI should still run:**
- Full test suite
- UI tests
- Multi-platform builds
- Security scans
- Code coverage
- Performance benchmarks

**Pre-commit hooks run:**
- Fast quality checks
- Formatting validation
- Basic build sanity
- Architectural rules

---

## Maintenance

### Updating Hooks

```bash
# Backup current hook
cp .git/hooks/pre-commit .git/hooks/pre-commit.backup

# Edit hook
nano .git/hooks/pre-commit

# Test changes
./.git/hooks/pre-commit
```

### Distributing to Team

Hooks are stored in `.git/hooks/` which is **not tracked by Git**.

To share hooks:

1. Store master copies in `Scripts/git-hooks/`
2. Create installer script:

```bash
#!/bin/bash
# Scripts/install-git-hooks.sh
cp Scripts/git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "✅ Git hooks installed"
```

3. Document in README: "Run `./Scripts/install-git-hooks.sh` after clone"

---

## Bypass Guidelines

### When to use `--no-verify`

✅ **Acceptable:**
- Emergency production hotfix
- Hook system is broken
- Working around hook bug
- Reverting a commit that broke the build

❌ **Not acceptable:**
- "I don't want to fix linting errors"
- "Hook is too slow"
- "I'll fix it later"
- Regular workflow

### Process for bypass

1. Use `--no-verify` to commit
2. Create immediate follow-up issue to fix violations
3. Document reason in commit message:
   ```
   fix: emergency patch for crash
   
   Used --no-verify due to broken hook system.
   Follow-up: #123
   ```

---

## Hook Architecture

```
.git/hooks/
├── pre-commit          # Main validation hook (this document)
├── commit-msg          # Commit message validation
└── prepare-commit-msg  # (optional) Commit message template

Config files:
├── .swiftlint.yml      # SwiftLint rules
└── .swiftformat        # SwiftFormat rules
```

**Hook execution order:**
1. `pre-commit` runs first (validates staged files)
2. User writes commit message
3. `commit-msg` validates message
4. Commit is created

---

## Examples

### Example: Clean commit

```bash
$ git add SharedCore/MyNewFeature.swift
$ git commit -m "feat(core): add MyNewFeature"

╔════════════════════════════════════════════════════════════════╗
║             Itori Pre-Commit Validation v2.0                   ║
╚════════════════════════════════════════════════════════════════╝

━━━ 1. Repository Hygiene ━━━
✅ No trailing whitespace
✅ All files within size limits
✅ No blocked file types
✅ No filenames with spaces
✅ Naming conventions checked

━━━ 2. Swift Code Quality ━━━
✅ SwiftLint passed
✅ SwiftFormat passed
✅ Swift quality checks complete

━━━ 3. App Rename Enforcement ━━━
✅ No 'Roots' references in user-facing code

━━━ 4. Build Sanity Check ━━━
✅ Xcodebuild validation passed

━━━ 5. Architectural Guardrails ━━━
✅ No architectural violations

━━━ 6. TODO/FIXME Policy ━━━
✅ No TODO/FIXME in production code

━━━ 7. Commit Message Check ━━━
✅ Commit message checked

━━━ 8. Additional Checks ━━━
✅ No merge conflict markers
✅ No debug print statements

ℹ️  Hook completed in 8s

╔════════════════════════════════════════════════════════════════╗
║  ✅ All checks passed!                                       ║
║  Proceeding with commit...                                     ║
╚════════════════════════════════════════════════════════════════╝

[main abc1234] feat(core): add MyNewFeature
 1 file changed, 42 insertions(+)
```

### Example: Failed commit

```bash
$ git add Platforms/iOS/BadCode.swift
$ git commit -m "WIP stuff"

╔════════════════════════════════════════════════════════════════╗
║             Itori Pre-Commit Validation v2.0                   ║
╚════════════════════════════════════════════════════════════════╝

━━━ 1. Repository Hygiene ━━━
❌ ERROR: Trailing whitespace detected
  Platforms/iOS/BadCode.swift:15: trailing whitespace

━━━ 2. Swift Code Quality ━━━
❌ ERROR: SwiftLint found 2 error(s)
  Platforms/iOS/BadCode.swift:10:5: error: Force Unwrapping Violation
  Platforms/iOS/BadCode.swift:23:8: error: Print Statement Violation

━━━ 7. Commit Message Check ━━━
❌ ERROR: Commit message contains prohibited terms: WIP

╔════════════════════════════════════════════════════════════════╗
║  ❌ 3 error(s) found                                        ║
║  Fix the errors above and try again.                           ║
║  To bypass (emergencies only):                                 ║
║    git commit --no-verify                                      ║
╚════════════════════════════════════════════════════════════════╝
```

---

## FAQ

**Q: Can I customize the rules?**  
A: Yes, edit `.swiftlint.yml` and `.swiftformat` for linting/formatting. Edit `.git/hooks/pre-commit` for hook logic (advanced).

**Q: Why is SwiftFormat a hard error?**  
A: Consistent formatting reduces merge conflicts and code review friction. Run `swiftformat .` to auto-fix.

**Q: Can I commit without fixing warnings?**  
A: Yes, warnings don't block commits. Only errors block.

**Q: Do hooks run in CI?**  
A: No, these are local hooks. CI should have its own validation pipeline.

**Q: What if I'm not working on Swift code?**  
A: The hooks skip Swift-specific checks if no `.swift` files are staged. Only hygiene checks run.

**Q: Can I run hooks manually?**  
A: Yes: `./.git/hooks/pre-commit` to test without committing.

---

## Support

For issues or questions:
1. Check this documentation
2. Run `./.git/hooks/pre-commit` manually to debug
3. Check `.git/hooks/pre-commit.backup-*` for previous versions
4. File an issue with the dev team

---

## Version History

- **v2.0** (2024-01-08): Complete rewrite with all required checks
  - Added SwiftFormat enforcement
  - Added app rename guard (Roots → Itori)
  - Added architectural guardrails
  - Added TODO/FIXME policy
  - Improved performance (< 15s target)
  - Better error messages

- **v1.0** (2023): Initial comprehensive validation hook
  - Basic SwiftLint integration
  - Build validation
  - Security checks

---

## License

Internal use only — Itori project.
