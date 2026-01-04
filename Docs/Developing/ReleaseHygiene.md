# Release Hygiene Guidelines

## Purpose
Ensure the Itori app maintains high quality standards before any release by preventing common pitfalls that could impact users or degrade the codebase.

---

## Critical Rules (P0 - Must Never Violate)

### 1. No User-Visible TODO Strings
**Rule:** Never ship UI with placeholder text like "TODO:", "Coming soon", or similar development markers.

**Why:** Looks unprofessional and confuses users about feature completeness.

**How to Fix:**
- Replace with real copy
- Hide behind feature flag if incomplete
- Remove the UI element entirely until ready

**Check:**
```bash
# Search for TODO in UI strings
grep -r "TODO" --include="*.swift" . | grep -E 'Text\(|\.label|\.title'
```

---

### 2. No fatalError in Production Code Paths
**Rule:** `fatalError()`, `preconditionFailure()`, and `assertionFailure()` must only be used in DEBUG builds or in truly unrecoverable situations.

**Why:** These crash the app immediately. Users should never experience crashes from initialization failures.

**How to Fix:**
- Log the error with appropriate severity
- Provide safe fallback behavior (in-memory stores, empty states, etc.)
- Degrade gracefully rather than crash

**Acceptable Pattern:**
```swift
guard let resource = loadResource() else {
    LOG_CORE(.error, "Init", "Failed to load resource - using fallback")
    return fallbackResource()
}
```

**Unacceptable Pattern:**
```swift
guard let resource = loadResource() else {
    fatalError("Resource not found")  // ❌ NEVER in production
}
```

---

### 3. No Backup Files in Repository
**Rule:** Never commit `.backup`, `.bak`, `.bak*`, or similar temporary/backup files.

**Why:** 
- Pollutes repository
- Can accidentally get bundled into builds
- Confuses IDE indexing
- Makes searches noisy

**Prevention:**
- `.gitignore` includes patterns for backup files
- Review file list before committing
- Use proper version control instead of manual backups

**Check:**
```bash
# Find backup files
find . -name "*.backup" -o -name "*.bak" -o -name "*.bak*" | grep -v ".git"
```

---

## High Priority Rules (P1 - Should Follow)

### 4. Feature Flags for Incomplete Features
**Rule:** If a feature isn't ready but needs to ship in code, hide it behind a feature flag or build configuration.

**Example:**
```swift
#if DEBUG || FEATURE_EXPERIMENTAL_GRADES
    .navigationDestination(for: Grade.self) { grade in
        GradeDetailView(grade: grade)
    }
#endif
```

---

### 5. No Dead/Unwired UI Actions
**Rule:** Don't ship tappable UI elements that do nothing.

**How to Fix:**
- Implement the action
- Remove the affordance (button/chevron)
- Add "Coming soon" label only if truly intended

**Bad Example:**
```swift
Button("Export") {
    // TODO: implement export
}
```

**Good Example:**
```swift
#if DEBUG
Button("Export (Dev Only)") {
    print("Not yet implemented")
}
#endif
```

---

### 6. Localization Completeness
**Rule:** All user-visible strings must be localized or use `.localized` extension.

**Check:**
```bash
# Find non-localized Text() calls
grep -r 'Text("' --include="*.swift" . | grep -v ".localized"
```

---

## Automated Checks

### Pre-Release CI Script
Create `Scripts/check_release_hygiene.sh`:

```bash
#!/bin/bash
set -e

echo "🔍 Checking release hygiene..."

# Check for user-visible TODOs
echo "Checking for TODO strings in UI..."
if grep -r "TODO" --include="*.swift" . | grep -E 'Text\(|\.label|\.title' | grep -v "Deprecated"; then
    echo "❌ Found TODO strings in UI"
    exit 1
fi

# Check for backup files
echo "Checking for backup files..."
if find . -name "*.backup" -o -name "*.bak" -o -name "*.bak*" | grep -v ".git" | grep .; then
    echo "❌ Found backup files in repository"
    exit 1
fi

# Check for fatalError in production code
echo "Checking for fatalError in production code..."
if grep -r "fatalError" --include="*.swift" SharedCore/ Platforms/ | grep -v "#if DEBUG" | grep -v "test" | grep .; then
    echo "⚠️  Warning: fatalError found in production code paths"
fi

echo "✅ Release hygiene checks passed"
```

Make executable:
```bash
chmod +x Scripts/check_release_hygiene.sh
```

Add to CI pipeline:
```yaml
- name: Release Hygiene Check
  run: ./Scripts/check_release_hygiene.sh
```

---

## Release Checklist

Before shipping any release:

- [ ] Run release hygiene script
- [ ] Build in Release configuration and test manually
- [ ] Review all new/changed UI for placeholder text
- [ ] Verify no crash on fresh install
- [ ] Test with iCloud sync disabled
- [ ] Test with no network connection
- [ ] Review error logs for any CRITICAL messages
- [ ] Verify all feature flags are correctly set

---

## Emergency Exceptions

If you must violate these rules temporarily:

1. **Document it:** Add a `// RELEASE BLOCKER:` comment explaining why
2. **Create tracking issue:** Link to GitHub issue for fix
3. **Set deadline:** Must be fixed before next release
4. **Review with team:** Get explicit approval

Example:
```swift
// RELEASE BLOCKER: Issue #123 - Replace with real implementation before 1.0
// Temporary workaround for demo purposes
Text("TODO: Feature coming soon")
```

---

## Additional Best Practices

### Log Levels
- `.error` - Something that impacts user experience
- `.warning` - Unexpected but handled situation
- `.info` - Normal operational messages (sparingly)
- `.debug` - Development-only information

### Error Handling
Prefer explicit error handling over crashes:
```swift
do {
    try riskyOperation()
} catch {
    LOG_CORE(.error, "Operation", "Failed: \(error.localizedDescription)")
    return fallbackValue
}
```

### Feature Completeness
Before marking a feature "done":
- All copy is finalized
- Error states are handled
- Loading states are shown
- Empty states are implemented
- Accessibility is verified

---

## Consequences of Violations

**P0 violations:**
- Block release
- Require immediate fix
- May trigger rollback if discovered post-release

**P1 violations:**
- Create tracking issue
- Fix in next release
- Review in code review

---

## Questions?

If you're unsure whether something violates release hygiene:
1. Ask in code review
2. Check with team lead
3. When in doubt, be conservative (fix it)

---

**Last Updated:** 2025-12-30  
**Owner:** Development Team  
**Enforcement:** Automated CI + Manual Review
