# iOS Localization - Quick Reference

## How to Localize a String

### 1. Simple Text
**Before:**
```swift
Text("Dashboard")
```

**After:**
```swift
Text(NSLocalizedString("ios.dashboard.title", comment: "Dashboard"))
```

### 2. Button Labels
**Before:**
```swift
Button("Save") { /* action */ }
```

**After:**
```swift
Button(NSLocalizedString("common.save", comment: "Save")) { /* action */ }
```

### 3. Navigation Titles
**Before:**
```swift
.navigationTitle("Settings")
```

**After:**
```swift
.navigationTitle(NSLocalizedString("ios.settings.title", comment: "Settings"))
```

### 4. Accessibility Labels
**Before:**
```swift
.accessibilityLabel("Jump to today")
```

**After:**
```swift
.accessibilityLabel(NSLocalizedString("ios.dashboard.today", comment: "Jump to today"))
```

### 5. Format Strings (with values)
**Before:**
```swift
Text("\(count) tasks")
```

**After:**
```swift
Text(String(format: NSLocalizedString("ios.dashboard.tasks_label", comment: "Tasks"), count))
```

In Localizable.strings:
```
"ios.dashboard.tasks_label" = "%d tasks";
```

### 6. Multiple Format Arguments
**Before:**
```swift
Text("Due \(date) · \(minutes) min")
```

**After:**
```swift
Text(String(format: NSLocalizedString("ios.planner.due_format", comment: "Due date"), date, minutes))
```

In Localizable.strings:
```
"ios.planner.due_format" = "Due %@ · %d min";
```

## Key Naming Convention

### Structure
```
ios.<section>.<category>.<specific>
```

### Examples
| Context | Key | Value |
|---------|-----|-------|
| Screen title | `ios.dashboard.title` | "Dashboard" |
| Section header | `ios.planner.schedule.title` | "Schedule" |
| Button label | `ios.menu.add_assignment` | "Add Assignment" |
| Empty state | `ios.dashboard.due_soon.no_tasks` | "No tasks due soon." |
| Toast message | `ios.toast.schedule_updated` | "Schedule updated" |
| Accessibility | `ios.dashboard.today` | "Jump to today" |

### Categories
- **title** - Screen/view titles
- **subtitle** - Secondary titles
- **empty** - Empty state messages
- **stats** - Statistics labels
- **greeting** - Time-based greetings
- **toast** - Toast notifications
- **button** - Button labels
- **section** - Section headers
- **placeholder** - Placeholder text

## Finding the Right Key

### 1. Check Existing Keys
```bash
grep -r "ios.dashboard" en.lproj/Localizable.strings
```

### 2. Search by English Text
```bash
grep "Dashboard" en.lproj/Localizable.strings
```

### 3. List All Keys in Category
```bash
grep "^\"ios.dashboard" en.lproj/Localizable.strings
```

## Common Keys

### Navigation
```swift
NSLocalizedString("ios.dashboard.title", comment: "Dashboard")
NSLocalizedString("ios.planner.title", comment: "Planner")
NSLocalizedString("ios.timer.title", comment: "Timer")
NSLocalizedString("ios.settings.title", comment: "Settings")
```

### Buttons
```swift
NSLocalizedString("common.save", comment: "Save")
NSLocalizedString("common.cancel", comment: "Cancel")
NSLocalizedString("common.edit", comment: "Edit")
NSLocalizedString("common.done", comment: "Done")
```

### Empty States
```swift
NSLocalizedString("ios.dashboard.upcoming.no_events", comment: "No events")
NSLocalizedString("ios.dashboard.due_soon.no_tasks", comment: "No tasks")
NSLocalizedString("ios.planner.schedule.empty", comment: "No blocks scheduled")
```

### Menu Items
```swift
NSLocalizedString("ios.menu.add_assignment", comment: "Add Assignment")
NSLocalizedString("ios.menu.add_grade", comment: "Add Grade")
NSLocalizedString("ios.menu.auto_schedule", comment: "Auto Schedule")
NSLocalizedString("ios.menu.settings", comment: "Settings")
```

### Toast Messages
```swift
NSLocalizedString("ios.toast.schedule_updated", comment: "Updated")
NSLocalizedString("ios.toast.no_tasks_schedule", comment: "No tasks")
```

## Format Specifiers

### Types
- `%@` - String (NSString)
- `%d` - Integer (int)
- `%ld` - Long integer
- `%f` - Float/Double
- `%%` - Literal percent sign

### Example Usage
```swift
// Single integer
String(format: NSLocalizedString("key", comment: ""), 5)
// "key" = "%d items";  →  "5 items"

// Multiple values
String(format: NSLocalizedString("key", comment: ""), "Dec 23", 30)
// "key" = "Due %@ · %d min";  →  "Due Dec 23 · 30 min"

// Ordered arguments (for reordering in translations)
String(format: NSLocalizedString("key", comment: ""), firstName, lastName)
// English: "key" = "%1$@ %2$@";  →  "John Smith"
// Hungarian: "key" = "%2$@ %1$@";  →  "Smith John"
```

## Migration Checklist

When converting a file to use localization:

- [ ] Find all user-facing strings
- [ ] Check if key exists in Localizable.strings
- [ ] If not, add new key following naming convention
- [ ] Replace hardcoded string with NSLocalizedString
- [ ] Include descriptive comment
- [ ] Test in UI to verify display
- [ ] Check for proper formatting with dynamic values
- [ ] Verify accessibility labels

## Don't Localize

**Do NOT localize:**
- API keys, URLs
- Debug messages (use English)
- Developer comments in code
- System-provided strings (already localized)
- SF Symbol names
- UserDefaults keys
- Identifiers, tags

**Example - Don't localize:**
```swift
// ❌ Wrong
print(NSLocalizedString("debug.error", comment: "Error"))

// ✓ Correct
print("Error: \(error)") // Debug output stays in English
```

## Testing Localization

### 1. Preview in Xcode
```swift
#Preview {
    Text(NSLocalizedString("ios.dashboard.title", comment: "Dashboard"))
        .environment(\.locale, .init(identifier: "es")) // Spanish
}
```

### 2. Run with Different Language
- Edit Scheme → Run → Options → App Language → Spanish

### 3. Check for Missing Keys
Missing keys display as the key itself:
- "ios.dashboard.title" appears → Key is missing or misspelled

### 4. Pseudo-Localization
Use Xcode's pseudo-localization to find non-localized strings:
- Edit Scheme → Options → App Language → Accented Pseudolanguage

## Common Mistakes

### ❌ Wrong
```swift
// Concatenating localized strings
let text = NSLocalizedString("hello", comment: "") + " " + NSLocalizedString("world", comment: "")

// Using variables in comments
let name = "Dashboard"
Text(NSLocalizedString("ios.\(name).title", comment: "Title"))

// Localizing developer strings
print(NSLocalizedString("debug.log", comment: "Debug"))
```

### ✓ Correct
```swift
// Use format strings
let text = String(format: NSLocalizedString("hello_world", comment: ""), name)

// Use fixed keys
Text(NSLocalizedString("ios.dashboard.title", comment: "Dashboard"))

// Keep debug in English
print("Debug: \(value)")
```

## Adding New Keys

### 1. Open Localizable.strings
```bash
open en.lproj/Localizable.strings
```

### 2. Add Key in Alphabetical Section
```
/* iOS Dashboard */
"ios.dashboard.new_key" = "New Text";
```

### 3. Use in Code
```swift
Text(NSLocalizedString("ios.dashboard.new_key", comment: "New Text"))
```

### 4. Export for Translation
Xcode → Editor → Export for Localization

## Pluralization

For correct plurals, use `.stringsdict`:

### Localizable.stringsdict
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>ios.dashboard.events_count</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@events@</string>
        <key>events</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>zero</key>
            <string>No events</string>
            <key>one</key>
            <string>1 event</string>
            <key>other</key>
            <string>%d events</string>
        </dict>
    </dict>
</dict>
</plist>
```

### Usage
```swift
let count = 5
Text(String(format: NSLocalizedString("ios.dashboard.events_count", comment: "Events"), count))
// Shows: "5 events"
// If count = 1, shows: "1 event"
// If count = 0, shows: "No events"
```

## Resources

- [Apple Localization Guide](https://developer.apple.com/localization/)
- [NSLocalizedString Documentation](https://developer.apple.com/documentation/foundation/nslocalizedstring)
- [String Format Specifiers](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html)
- [Pluralization Rules](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/StringsdictFileFormat/StringsdictFileFormat.html)

## Quick Commands

### Find hardcoded strings
```bash
grep -rn '"[A-Z][a-z].*"' iOS/ --include="*.swift" | grep -v "NSLocalizedString"
```

### Count localization keys
```bash
grep -c "^\"ios\." en.lproj/Localizable.strings
```

### Find missing localization (in code)
```bash
# Find Text("...") without NSLocalizedString
grep -rn 'Text("' iOS/ --include="*.swift" | grep -v NSLocalizedString
```

### Validate Localizable.strings syntax
```bash
plutil -lint en.lproj/Localizable.strings
```

## Support

If you encounter issues:
1. Check key spelling matches exactly
2. Verify key exists in Localizable.strings
3. Check format specifiers match usage (%@, %d, etc.)
4. Test with clean build (Product → Clean Build Folder)
5. Verify `.strings` file is in target membership
