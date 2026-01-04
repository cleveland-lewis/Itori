# Localization Audit - Summary & Action Plan

## Current Status

### Infrastructure Created ✅
1. **LocalizationManager** (`SharedCore/Utilities/LocalizationManager.swift`)
   - Provides `.localized` extension
   - Falls back to English text (never shows keys)
   - DEBUG assertions for missing keys
   - Pattern detection for localization keys

2. **LocalizedStrings** (`SharedCore/Utilities/LocalizedStrings.swift`)
   - TaskType localization (NEVER use rawValue)
   - AssignmentCategory localization
   - Common string constants
   - Planner/Dashboard/Menu helpers
   - Format string helpers

3. **Unit Tests** (`ItoriTests/LocalizationValidationTests.swift`)
   - Tests that keys never return themselves
   - Tests enum localization
   - Tests fallback behavior
   - Tests completeness of .strings files
   - **Release-blocking** tests

4. **Audit Script** (`Scripts/audit-localization.sh`)
   - Scans codebase for hardcoded strings
   - Finds .rawValue UI usage
   - Checks localization files
   - Validates accessibility labels

5. **Localization Keys Added**
   - Added ~60 new keys to all 3 locales
   - Dashboard empty states
   - Planner strings
   - Task types
   - Common strings
   - Menu/Quick Add strings

### Audit Results

**Critical Issues Found:**
- ✅ **1013 hardcoded Text() strings** (requires manual fixing)
- ✅ **74 .rawValue usages** (infrastructure provided)
- ✅ **44 accessibility labels** (needs fixing)
- ✅ **0 NSLocalizedString without comments** (good!)

### Implementation Status

#### Phase 1: Infrastructure ✅ COMPLETE
- [x] LocalizationManager utility
- [x] Audit script
- [x] Enum localization extensions
- [x] Unit tests
- [x] Added missing localization keys

#### Phase 2: Critical Fixes ⏳ IN PROGRESS
- [ ] Fix IOSDashboardView (18 hardcoded strings)
- [ ] Fix IOSCorePages (50+ hardcoded strings)
- [ ] Fix IOSAssignmentPlansView (12 hardcoded strings)
- [ ] Fix IOSAppShell menu items (8 hardcoded strings)
- [ ] Localize accessibility labels (44 instances)

#### Phase 3: Complete Coverage 📋 TODO
- [ ] Fix remaining 900+ hardcoded strings
- [ ] Add .stringsdict for pluralization
- [ ] Localize all date/number formatters
- [ ] Add runtime validators

#### Phase 4: Automation 📋 TODO
- [ ] Pre-commit hook
- [ ] CI validation
- [ ] UI tests for key detection

## Critical Patterns to Fix

### ❌ NEVER DO THIS:
```swift
Text("Hardcoded string")
Text(taskType.rawValue)
Text(NSLocalizedString("key.name", comment: ""))  // returns key if missing
```

### ✅ ALWAYS DO THIS:
```swift
Text("key.name".localized)  // falls back to English text
Text(taskType.localizedName)  // never uses rawValue
Text(CommonLocalizations.today)  // type-safe constants
```

## Files Requiring Immediate Attention

### High Priority (User-Visible):
1. `iOS/Scenes/IOSDashboardView.swift`
   - Lines with hardcoded empty states
   - "Connect your calendar..." → `DashboardLocalizations.emptyCalendar`
   - "No upcoming events." → `DashboardLocalizations.emptyEvents`
   - "No tasks due soon." → `DashboardLocalizations.emptyTasks`

2. `iOS/Scenes/IOSCorePages.swift` (Planner)
   - "Today" → `PlannerLocalizations.today`
   - "Generate Plan" → `PlannerLocalizations.generate`
   - "How it works" → `PlannerLocalizations.howItWorks`
   - Task type pickers → `taskType.localizedName`
   - "No Course" → `CommonLocalizations.noCourse`

3. `iOS/Root/IOSAppShell.swift`
   - "Menu" → `CommonLocalizations.menu`
   - "Add Assignment" → `QuickAddLocalizations.assignment`
   - "Add Grade" → `QuickAddLocalizations.grade`
   - "Auto Schedule" → `QuickAddLocalizations.schedule`

4. `iOS/Scenes/IOSCorePages.swift` (Settings)
   - "Starred Tabs" → `MenuLocalizations.starredTabs`
   - "You can pin up to 5 pages" → `MenuLocalizations.pinLimit`

5. `iOS/Scenes/IOSAssignmentPlansView.swift`
   - "Assignment Plans" → `"plans.title".localized`
   - "Due \(date)" → `PlannerLocalizations.dueDate(date)`
   - "\(x)/\(y) steps" → `PlannerLocalizations.stepsCount(x, y)`

### Medium Priority:
- All `.rawValue` usages for UI text
- All accessibility labels without localization
- All empty state messages
- All button labels

## Testing Strategy

### Unit Tests ✅
- LocalizationValidationTests ensures no keys visible
- Tests enum localization
- Tests fallback behavior
- **Run before every release**

### Manual Testing
Test in each locale:
1. Launch app in English
2. Launch app in zh-Hans
3. Launch app in zh-Hant
4. Navigate through all screens
5. Verify NO keys visible anywhere
6. Verify all text is properly translated

### Automated Testing (TODO)
```swift
func testNoKeysInUI() {
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
    app.launch()
    
    // Navigate through screens
    // Take screenshots
    // Scan for key patterns (dots, underscores)
    // Assert none found
}
```

## Maintenance Guidelines

### For Developers:
1. **NEVER** hardcode user-facing strings
2. **ALWAYS** add new keys to all 3 .strings files
3. **NEVER** use enum `.rawValue` for UI
4. **ALWAYS** use `Text("key".localized)`
5. **RUN** audit script before committing
6. **RUN** LocalizationValidationTests before release

### Adding New Strings:
1. Add key to `en.lproj/Localizable.strings`
2. Add translations to `zh-Hans.lproj/Localizable.strings`
3. Add translations to `zh-Hant.lproj/Localizable.strings`
4. Use with `.localized` extension
5. Run tests to verify

### Pre-Commit Checklist:
- [ ] No hardcoded Text() strings added
- [ ] New keys added to all .strings files
- [ ] No .rawValue used for UI
- [ ] Accessibility labels localized
- [ ] Tests pass

## Success Metrics

### Current:
- ✅ Infrastructure in place
- ✅ 60+ keys added
- ✅ Unit tests created
- ✅ Audit script created
- ⏳ ~50 critical strings need fixing
- ⏳ ~1000 total strings need fixing

### Target:
- [ ] 0 visible localization keys
- [ ] 0 .rawValue in UI
- [ ] 100% accessibility localized
- [ ] All tests passing
- [ ] CI enforcing standards

## Estimated Effort Remaining

### Critical Fixes (Phase 2):
- IOSDashboardView: 1 hour
- IOSCorePages: 3 hours
- IOSAssignmentPlansView: 1 hour
- IOSAppShell: 30 minutes
- Accessibility labels: 2 hours
**Total: ~8 hours**

### Complete Coverage (Phase 3):
- Remaining 900 strings: 15-20 hours
- Pluralization: 2 hours
- Date/number formatters: 2 hours
**Total: ~20 hours**

### Automation (Phase 4):
- Pre-commit hooks: 1 hour
- CI validation: 2 hours
- UI tests: 3 hours
**Total: ~6 hours**

**GRAND TOTAL: ~34 hours for 100% completion**

## Immediate Next Steps

1. **HIGH PRIORITY** - Fix critical user-facing strings:
   - [ ] IOSDashboardView empty states
   - [ ] IOSCorePages Planner strings
   - [ ] IOSAppShell menu strings
   - [ ] Settings starred tabs strings

2. **MEDIUM PRIORITY** - Fix accessibility:
   - [ ] All accessibility labels
   - [ ] All accessibility hints

3. **TEST** - Validate fixes:
   - [ ] Run LocalizationValidationTests
   - [ ] Manual test in all 3 locales
   - [ ] Verify no keys visible

4. **DOCUMENT** - Update guidelines:
   - [ ] Developer guide for localization
   - [ ] Code review checklist
   - [ ] Release checklist

## Release Blocking Issues

🚨 **CRITICAL**: The following MUST be fixed before release:

1. ✅ LocalizationManager infrastructure (DONE)
2. ✅ Unit tests in place (DONE)
3. ⏳ No visible keys in common user flows:
   - Dashboard
   - Planner
   - Settings
   - Menu
4. ⏳ All enum types use localizedName
5. ⏳ Accessibility labels localized

**Minimum viable fix**: Phase 1 ✅ + Phase 2 Critical Fixes (~8 hours)

## Conclusion

**Infrastructure is complete** ✅  
**~8 hours of critical fixes** needed for MVP  
**~34 hours** for 100% coverage  

The foundation is solid. The LocalizationManager ensures that even if keys are missing, users see English text instead of key names. Unit tests will catch regressions. The audit script helps track progress.

Recommend completing **Phase 2 critical fixes** before next release.
