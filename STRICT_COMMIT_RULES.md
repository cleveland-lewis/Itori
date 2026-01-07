# Strict Commit Rules Implementation

This document describes the comprehensive commit validation system implemented for the Itori repository.

## 🎯 Overview

A multi-layered commit validation system has been implemented to enforce **strict commit message standards** across the repository. This ensures a clean, professional, and maintainable git history.

## 📁 Files Created

### 1. GitHub Actions Workflow
**`.github/workflows/commit-validation.yml`**
- Automated validation that runs on every PR and push
- Three validation jobs:
  - **Commit Message Validation**: Format, length, conventions
  - **Commit Content Validation**: File sizes, secret detection
  - **GPG Signature Enforcement**: Checks for signed commits (warning only)

### 2. Commit Guidelines
**`.github/COMMIT_GUIDELINES.md`**
- Comprehensive documentation of all commit rules
- Examples of valid and invalid commits
- Setup instructions for local validation
- Best practices and tips

### 3. Local Git Hook
**`Scripts/commit-msg-hook.sh`**
- Pre-commit validation script
- Validates commit messages locally before push
- Provides immediate feedback to developers

### 4. Hook Installation Script
**`Scripts/install-git-hooks.sh`**
- One-command setup for local git hooks
- Usage: `./Scripts/install-git-hooks.sh`

### 5. Commitlint Configuration
**`commitlint.config.js`**
- Node.js-based commit validation
- For teams using npm/Node tooling
- Stricter validation with commitlint

### 6. Updated Contributing Guide
**`.github/CONTRIBUTING.md`**
- Updated to reference commit guidelines
- Clear expectations for internal contributors

## 🔒 Validation Rules

### Commit Message Format
✅ **REQUIRED**: `type(scope): description`

### Types Allowed (21 types)
- `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`
- `build`, `ci`, `chore`, `revert`, `security`, `deps`
- `i18n`, `a11y`, `analytics`, `config`, `hotfix`, `release`

### Length Requirements
- **Subject**: 10-72 characters
- **Scope**: 2-20 characters (if provided)
- **Header**: Max 100 characters

### Formatting Rules
- Description must start with **lowercase**
- Must **NOT** end with period
- No leading/trailing whitespace
- Scope must be lowercase alphanumeric + hyphens

### Prohibited Content
- ❌ `WIP`, `TODO`, `FIXME`, `HACK`, `XXX`
- ❌ Profanity or unprofessional language
- ❌ Merge commits (use rebase)
- ❌ Files over 5MB
- ❌ Secrets, API keys, tokens

### Breaking Changes
- Must use `!` notation: `feat!: description`
- Must include `BREAKING CHANGE:` in footer
- Must explain migration path

## 🚀 Quick Start

### For Developers

1. **Install local hooks** (recommended):
   ```bash
   ./Scripts/install-git-hooks.sh
   ```

2. **Read the guidelines**:
   ```bash
   cat .github/COMMIT_GUIDELINES.md
   ```

3. **Make a commit**:
   ```bash
   git commit -m "feat(auth): add oauth2 authentication support"
   ```

### For Strict Validation (Optional)

Install commitlint for the strictest validation:

```bash
# Install commitlint
npm install -g @commitlint/cli @commitlint/config-conventional

# Install husky for git hooks
npm install -g husky
npx husky install
npx husky add .git/hooks/commit-msg 'npx commitlint --edit $1'
```

## 📊 Validation Layers

### Layer 1: Local Git Hook (Optional)
- Runs on `git commit`
- Immediate feedback
- Prevents invalid commits locally
- **Setup**: Run `./Scripts/install-git-hooks.sh`

### Layer 2: Commitlint (Optional)
- Runs on `git commit` (if installed)
- Strictest validation
- Industry-standard tool
- **Setup**: See Quick Start above

### Layer 3: GitHub Actions (Automatic)
- Runs on every PR and push
- **Cannot be bypassed**
- Blocks PR merge if validation fails
- Checks all commits in PR

## 🎓 Examples

### ✅ Valid Commits

```bash
feat(auth): add oauth2 authentication support
fix(timer): prevent unexpected pause in background
docs: update installation instructions
refactor(core): simplify state management logic
perf(calendar): optimize event rendering
security(api): patch sql injection vulnerability
feat!(api): remove deprecated v1 endpoints
```

### ❌ Invalid Commits

```bash
# Too short
fix: bug

# Capital letter after colon
feat(auth): Add OAuth2

# Ends with period
docs: update readme.

# Contains prohibited word
WIP: working on feature

# Not conventional format
Update some stuff

# Merge commit
Merge branch 'feature' into main
```

## 🛡️ Security Features

### Secret Detection
Automatically scans for:
- API keys (generic patterns)
- AWS access keys (`AKIA...`)
- GitHub tokens (`ghp_...`, `gho_...`)
- Stripe keys (`sk_live_...`, `pk_live_...`)
- Passwords (`password=...`)

### File Size Limits
- Max file size: **5MB**
- Use Git LFS for larger files

### GPG Signing
- Encouraged but not required
- Provides cryptographic proof of authorship
- Workflow warns about unsigned commits

## 📈 Benefits

1. **Consistency**: All commits follow the same format
2. **Readability**: Easy to scan git history
3. **Automation**: Enable automated changelog generation
4. **Semantic Versioning**: Type system maps to semver
5. **Quality**: Professional, maintainable codebase
6. **Security**: Automatic secret detection
7. **Compliance**: Clear audit trail

## 🔧 Maintenance

### Updating Rules

To modify validation rules:

1. **Local validation**: Edit `Scripts/commit-msg-hook.sh`
2. **CI validation**: Edit `.github/workflows/commit-validation.yml`
3. **Commitlint**: Edit `commitlint.config.js`
4. **Documentation**: Update `.github/COMMIT_GUIDELINES.md`

### Adding New Types

To add a new commit type:

1. Add to `ALLOWED_TYPES` in `commit-validation.yml` (line ~30)
2. Add to `ALLOWED_TYPES` in `commit-msg-hook.sh` (line ~21)
3. Add to `type-enum` in `commitlint.config.js` (line ~17)
4. Document in `COMMIT_GUIDELINES.md`

## 🐛 Troubleshooting

### Commit rejected locally?
- Check message format: `type(scope): description`
- Verify length: 10-72 characters
- Ensure lowercase description
- Remove prohibited words

### CI validation failing?
- Review GitHub Actions logs
- Compare your commit to examples in guidelines
- Use `git commit --amend` to fix message
- Force push if needed: `git push --force-with-lease`

### Hook not running?
- Reinstall: `./Scripts/install-git-hooks.sh`
- Check permissions: `ls -la .git/hooks/commit-msg`
- Verify git hooks enabled: `git config core.hooksPath`

## 📚 Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Commit Best Practices](https://chris.beams.io/posts/git-commit/)
- [GitHub Commit Signature Verification](https://docs.github.com/en/authentication/managing-commit-signature-verification)
- [Semantic Versioning](https://semver.org/)

## ✅ Verification

Test the system:

```bash
# Should succeed
git commit --allow-empty -m "feat(test): verify commit validation system"

# Should fail (too short)
git commit --allow-empty -m "fix: bug"

# Should fail (capital letter)
git commit --allow-empty -m "feat: Add feature"
```

## 📝 Summary

✅ **Automated validation** on every commit  
✅ **Multiple validation layers** (local + CI)  
✅ **Comprehensive rules** (21 commit types)  
✅ **Security scanning** (secrets, file sizes)  
✅ **Clear documentation** and examples  
✅ **Easy setup** with provided scripts  
✅ **Industry standards** (Conventional Commits)  

---

**Status**: ✅ Fully implemented and active  
**Enforcement**: 🔒 Build-blocking on CI  
**Documentation**: 📖 Complete  
**Last Updated**: 2026-01-07
