# Localization Enforcement - Implementation Plan

## Current State
- **1013 hardcoded Text() strings** need localization
- **74 .rawValue usages** in UI (potential keys showing)
- **44 accessibility labels** not localized
- **401 keys** in each localization file

## Critical Issues Found

### High Priority (User-Visible Keys)
1. Navigation titles showing keys
2. Empty states showing raw text
3. Button labels not localized
4. Menu items hardcoded
5. Alert/toast messages hardcoded

### Medium Priority
1. Enum rawValues used for display
2. Accessibility labels not localized
3. Context menus hardcoded
4. Placeholder text hardcoded

## Solution Architecture

### 1. LocalizationManager (✅ Created)
- Provides `.localized` extension
- Falls back to English from key structure
- DEBUG assertions for missing keys
- Never returns raw keys

### 2. Required Localization Keys (To Add)
```
// Dashboard
"dashboard.empty.calendar" = "Connect your calendar to see upcoming events.";
"dashboard.empty.events" = "No upcoming events.";
"dashboard.empty.tasks" = "No tasks due soon.";

// Common
"common.due" = "Due";
"common.today" = "Today";
"common.no_date" = "No due date";
"common.no_course" = "No Course";

// Task Types
"task.type.homework" = "Homework";
"task.type.quiz" = "Quiz";
"task.type.exam" = "Exam";
"task.type.reading" = "Reading";
"task.type.review" = "Review";
"task.type.project" = "Project";

// Planner
"planner.today" = "Today";
"planner.generate" = "Generate Plan";
"planner.empty.title" = "No assignments";
"planner.empty.subtitle" = "Add assignments to see their plans";
"planner.help.line1" = "Planner uses your assignment due dates to build a schedule of study blocks.";
"planner.help.line2" = "Generate Plan to create time blocks for today and the next few days.";
"planner.help.line3" = "Tasks without a due date stay in the Unscheduled section.";

// Attributes
"attribute.importance" = "Importance";
"attribute.difficulty" = "Difficulty";

// Time
"time.allowed_hours" = "Allowed hours: %d:00–%d:00";
"time.steps_count" = "%d/%d steps";
"time.minutes_total" = "%d min total";
"time.no_plan" = "No plan yet";
"time.progress" = "%d%%";

// Empty States
"empty.no_sessions" = "No sessions yet.";
"empty.no_tasks" = "No tasks yet.";
"empty.no_assignments" = "No assignments";
"empty.add_assignments" = "Add assignments to see their plans";

// Actions
"action.how_it_works" = "How it works";
"action.edit" = "Edit";
"action.done" = "Done";
"action.updated" = "Updated %@";

// Menu
"menu.title" = "Menu";
"menu.starred_tabs" = "Starred Tabs";
"menu.starred_tabs.footer" = "Select up to 5 pages to show in the tab bar. All pages remain accessible via the menu.";
"menu.pin_limit" = "You can pin up to 5 pages";

// Calendar
"calendar.section.title" = "Calendar";
"calendar.school_calendar" = "School Calendar";
"calendar.all_calendars" = "All Calendars";
"calendar.selection.hint" = "Only events from the selected calendar will be shown throughout the app.";

// Settings - Starred Tabs
"settings.starred_tabs.header" = "Starred Tabs";
"settings.starred_tabs.footer" = "Select up to 5 pages to show in the tab bar. All pages remain accessible via the menu.";

// Grades
"grades.section.overall" = "Overall Status";
"grades.section.by_course" = "By Course";
"grades.section.components" = "Grade Components";
```

### 3. Pattern Replacements

#### Before (❌ Shows Keys):
```swift
Text(NSLocalizedString("settings.section.general", comment: ""))
```

#### After (✅ Shows English):
```swift
Text("settings.section.general".localized)
// or
Text(localizedKey: "settings.section.general")
```

### 4. Enum Display Pattern

#### Before (❌ Shows rawValue):
```swift
Text(taskType.rawValue)
```

#### After (✅ Localized):
```swift
extension TaskType {
    var localizedName: String {
        switch self {
        case .practiceHomework: return "task.type.homework".localized
        case .quiz: return "task.type.quiz".localized
        case .exam: return "task.type.exam".localized
        case .reading: return "task.type.reading".localized
        case .review: return "task.type.review".localized
        case .project: return "task.type.project".localized
        }
    }
}

Text(taskType.localizedName)
```

### 5. Automated Tests

#### Unit Test:
```swift
class LocalizationTests: XCTestCase {
    func testNoKeysVisible() {
        let testStrings = [
            "settings.section.general",
            "timer.label.search",
            "dashboard.empty.tasks"
        ]
        
        for key in testStrings {
            let localized = key.localized
            XCTAssertNotEqual(localized, key, "Key \(key) returned itself - missing translation")
            XCTAssertFalse(LocalizationManager.isLocalizationKey(localized), 
                          "Localized string looks like a key: \(localized)")
        }
    }
    
    func testAllKeysHaveTranslations() {
        // Load all keys from code
        // Verify each exists in Localizable.strings
    }
}
```

#### UI Test:
```swift
class LocalizationUITests: XCTestCase {
    func testNoKeysVisibleInUI() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate through all screens
        let screens = ["Dashboard", "Timer", "Planner", "Settings"]
        
        for screen in screens {
            // Take snapshot
            let screenshot = app.screenshot()
            // Scan for key patterns (dots, underscores)
            // Assert none found
        }
    }
}
```

### 6. Runtime Validator (DEBUG only)

```swift
#if DEBUG
extension Text {
    init(_ string: String) {
        LocalizationValidator.validateNoKeysVisible(in: string)
        self.init(verbatim: string)
    }
}
#endif
```

## Implementation Priority

### Phase 1: Critical (DO IMMEDIATELY)
1. ✅ Create LocalizationManager utility
2. ✅ Create audit script
3. Add missing localization keys to .strings files
4. Fix enum display patterns (TaskType, etc.)
5. Add Text(localizedKey:) extension

### Phase 2: High Priority
1. Fix IOSDashboardView hardcoded strings
2. Fix IOSCorePages (Planner) hardcoded strings
3. Fix menu items in IOSAppShell
4. Fix Settings empty states
5. Localize accessibility labels

### Phase 3: Medium Priority
1. Fix remaining Text() hardcoded strings
2. Add pluralization (.stringsdict)
3. Localize date/number formatters
4. Add runtime validators

### Phase 4: Validation
1. Create unit tests
2. Create UI tests
3. Manual QA in all locales
4. Final audit scan

## Files Requiring Immediate Attention

### Critical:
- `iOS/Scenes/IOSDashboardView.swift` (18 hardcoded)
- `iOS/Scenes/IOSCorePages.swift` (50+ hardcoded)
- `iOS/Scenes/IOSAssignmentPlansView.swift` (12 hardcoded)
- `iOS/Root/IOSAppShell.swift` (menu items)
- `SharedCore/Models/*.swift` (enum rawValues)

### Localization Files:
- `en.lproj/Localizable.strings` (add ~100 keys)
- `zh-Hans.lproj/Localizable.strings` (add ~100 keys)
- `zh-Hant.lproj/Localizable.strings` (add ~100 keys)

## Success Criteria
- [ ] Zero visible localization keys in any screen
- [ ] All user-facing text localized
- [ ] Accessibility parity (labels localized)
- [ ] Automated tests prevent regressions
- [ ] Missing keys fall back to English text (never keys)
- [ ] DEBUG assertions catch missing keys during development

## Maintenance
- Pre-commit hook to scan for hardcoded strings
- CI check for localization completeness
- Developer guide for adding new UI text
- Regular audits with script

## Estimated Effort
- Phase 1: 2-3 hours (critical fixes)
- Phase 2: 4-6 hours (high priority)
- Phase 3: 8-10 hours (complete coverage)
- Phase 4: 2-3 hours (validation)

**Total: ~20 hours for complete implementation**

Given scope, recommend **Phase 1 + Phase 2** as minimum viable fix.
