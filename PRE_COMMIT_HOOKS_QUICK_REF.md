# Pre-Commit Hooks Quick Reference

## One-Line Fixes

```bash
# Fix all formatting issues
swiftlint --fix && swiftformat . && git add -u

# Bypass hook (emergency only)
git commit --no-verify -m "Emergency fix"

# Test hook without committing
./.git/hooks/pre-commit

# Install tools
brew install swiftlint swiftformat
```

## Common Errors & Fixes

| Error | Fix |
|-------|-----|
| Trailing whitespace | `git diff --check` then remove spaces |
| SwiftLint errors | `swiftlint --fix` |
| SwiftFormat errors | `swiftformat .` then `git add <files>` |
| Force unwrap | Replace `!` with `guard let` or `if let` |
| Print statement | Replace `print()` with `DebugLogger.log()` |
| "Roots" reference | Replace with "Itori" |
| TODO in production | Remove or move to `/Tests/` |
| Commit message WIP | Write proper message |

## Hook Checklist

Before committing:
- [ ] No trailing whitespace
- [ ] Files < 10MB
- [ ] Swift files formatted (`swiftformat .`)
- [ ] SwiftLint passes (`swiftlint`)
- [ ] No "Roots" in user-facing code
- [ ] No TODO/FIXME in production paths
- [ ] Proper commit message (no "WIP", "temp")

## Bypass Scenarios

✅ **When to bypass:**
- Emergency production hotfix
- Hook system is broken
- Reverting broken commit

❌ **Never bypass for:**
- "Too lazy to fix linting"
- "Hook is slow"
- "I'll fix it later"

## Tools Installation

```bash
# macOS
brew install swiftlint swiftformat

# Verify
which swiftlint swiftformat
swiftlint version
swiftformat --version
```

## Hook Performance

Target: < 15 seconds

If slow:
1. Check `time ./.git/hooks/pre-commit`
2. Only stage files you changed
3. Consider disabling build check temporarily

## Support

Read full guide: `PRE_COMMIT_HOOKS_GUIDE_V2.md`
