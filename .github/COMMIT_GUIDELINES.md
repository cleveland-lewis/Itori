# Commit Guidelines

This repository enforces **strict commit message standards** to maintain a clean, readable, and professional git history.

## 📋 Commit Message Format

All commits **must** follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Type

Must be one of the following:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to our CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit
- **security**: Security improvements or fixes
- **deps**: Dependency updates
- **i18n**: Internationalization and localization
- **a11y**: Accessibility improvements
- **analytics**: Analytics or tracking related changes
- **config**: Configuration changes
- **hotfix**: Critical production fixes
- **release**: Release commits

### Scope (Optional but Recommended)

The scope should be the name of the affected component, module, or area:

Examples: `auth`, `api`, `ui`, `core`, `timer`, `calendar`, `settings`

**Scope Rules:**
- 2-20 characters
- Lowercase only
- Use hyphens for multi-word scopes
- Alphanumeric characters only

### Description

- **Minimum**: 10 characters
- **Maximum**: 72 characters
- Must start with a **lowercase** letter
- Must **NOT** end with a period
- Use imperative mood ("add" not "added" or "adds")
- Be concise and descriptive

### Body (Required for feat, fix, refactor, security, perf)

- Separated from subject by a blank line
- Explain **what** and **why**, not **how**
- Wrap at 72 characters
- Can contain multiple paragraphs

### Footer (Optional)

- References to issues/PRs: `Fixes #123`, `Closes #456`
- Breaking changes: `BREAKING CHANGE: <description>`
- Other metadata

## ✅ Valid Examples

```
feat(auth): add oauth2 authentication support

Implemented OAuth2 flow for third-party authentication.
Supports Google, GitHub, and Microsoft providers.

Closes #234
```

```
fix(timer): prevent timer from pausing unexpectedly

The timer was pausing when the app went to background.
Added background execution support to maintain timer state.

Fixes #567
```

```
docs: update installation instructions
```

```
refactor(core): simplify state management logic

Reduced complexity by consolidating state updates into
a single reducer function. Improves maintainability.
```

```
feat!(api): remove deprecated v1 endpoints

BREAKING CHANGE: All v1 API endpoints have been removed.
Clients must migrate to v2 API.
```

## ❌ Invalid Examples

```
❌ Update stuff
   (No type, too vague, too short)

❌ feat(auth): Add OAuth2 support.
   (Capital letter after colon, ends with period)

❌ WIP: working on new feature
   (WIP not allowed, not conventional format)

❌ fix bug
   (Too short, no scope specificity)

❌ Merge branch 'feature/new-ui' into main
   (Merge commits not allowed - use rebase)

❌ feat(a): x
   (Scope too short, description too short)

❌ feat(authentication-and-authorization-system): add
   (Scope too long)
```

## 🚫 Prohibited Elements

The following are **NOT allowed** in commit messages:

- `WIP`, `TODO`, `FIXME`, `HACK`, `XXX`
- Profanity or unprofessional language
- Leading or trailing whitespace
- Merge commit messages (use `git rebase` instead)
- Commits over 5MB in file size
- Secrets, API keys, passwords, or sensitive data

## 🔒 Additional Requirements

### 1. File Size Limits
- No individual file over **5MB**
- Use Git LFS for large files (images, videos, binaries)

### 2. Secret Detection
- Commits are automatically scanned for secrets
- Any detected secrets will **block** the commit
- Never commit:
  - API keys
  - Passwords
  - Access tokens
  - Private keys
  - Database credentials

### 3. Signed Commits (Recommended)
- GPG-signed commits are highly encouraged
- Provides cryptographic proof of authorship
- [Setup guide](https://docs.github.com/en/authentication/managing-commit-signature-verification)

### 4. Breaking Changes
- Must use `!` notation: `feat!: description`
- Must include `BREAKING CHANGE:` in footer
- Must explain migration path

## 🔧 Setup Git Hooks (Optional)

To validate commits locally before pushing:

```bash
# Install commitlint (requires Node.js)
npm install -g @commitlint/cli @commitlint/config-conventional

# Create commitlint config
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js

# Install husky for git hooks
npm install -g husky
npx husky install
npx husky add .git/hooks/commit-msg 'npx commitlint --edit $1'
```

## 🤖 Automated Enforcement

All commits are validated automatically via GitHub Actions:

1. **Commit Message Validation** - Format, length, type, scope
2. **Content Validation** - File sizes, secret detection
3. **Signature Check** - GPG signature verification (warning only)

Pull requests will be **blocked** if any validation fails.

## 📚 Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Commit Best Practices](https://chris.beams.io/posts/git-commit/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Commit Signature Verification](https://docs.github.com/en/authentication/managing-commit-signature-verification)

## 💡 Tips

1. **Write commits as you code** - Don't wait until the end
2. **One logical change per commit** - Makes review easier
3. **Think about the changelog** - Your commits will be read by others
4. **Use the body** - Explain complex changes thoroughly
5. **Reference issues** - Link commits to issue tracking
6. **Test before committing** - Ensure code works
7. **Review your diff** - Double-check what you're committing

## ❓ Questions?

If you have questions about commit guidelines, please:
- Check existing commits for examples
- Refer to this document
- Ask in pull request comments
- Contact the maintainers

---

**Remember**: Good commit messages are a love letter to your future self (and your teammates)! 💌
