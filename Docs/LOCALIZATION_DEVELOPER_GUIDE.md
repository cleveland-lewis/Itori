# Localization Developer Quick Reference

## ✅ How to Localize Properly

### Pluralization
**Use .stringsdict rules for proper grammar:**
```swift
// ❌ BAD
Text(count == 1 ? "1 item" : "\(count) items")

// ✅ GOOD
Text(String.localizedStringWithFormat(
    NSLocalizedString("items_count", comment: ""),
    count
))
```

### Dates & Times
**Use LocaleFormatters, never raw formatters:**
```swift
// ❌ BAD
let formatter = DateFormatter()
formatter.dateFormat = "MM/dd/yyyy"

// ✅ GOOD
LocaleFormatters.shortDate.string(from: date)        // "12/23/25" or "23.12.25"
LocaleFormatters.shortTime.string(from: date)        // "2:30 PM" or "14:30"
LocaleFormatters.dateAndTime.string(from: date)      // Locale-aware
```

### Numbers
**Use LocaleFormatters for proper grouping:**
```swift
// ❌ BAD
Text("\(1234)")  // Always "1234"

// ✅ GOOD
LocaleFormatters.integer.string(from: NSNumber(value: 1234))
// Result: "1,234" (US) or "1.234" (DE) or "1 234" (FR)
```

### Strings
**Always localize user-facing text:**
```swift
// ❌ BAD
Text("Hello")
Button("Save") { }

// ✅ GOOD
Text(NSLocalizedString("greeting", comment: ""))
Button(NSLocalizedString("action.save", comment: "")) { }
```

## 📋 Available Plural Keys

| Key | Use For | Example Output |
|-----|---------|----------------|
| `tasks_due_count` | Task counts | "No tasks due" / "1 task due" / "5 tasks due" |
| `tasks_due_today` | Today's tasks | "No tasks due today" / "1 task due today" |
| `events_scheduled` | Event counts | "No events scheduled" / "1 event scheduled" |
| `minutes_remaining` | Time remaining | "0 min remaining" / "1 min remaining" |
| `hours_count` | Hour counts | "0 hours" / "1 hour" / "5 hours" |
| `study_sessions_count` | Session counts | "No study sessions" / "1 study session" |

**Usage:**
```swift
let text = String.localizedStringWithFormat(
    NSLocalizedString("tasks_due_count", comment: ""),
    taskCount
)
```

## 📅 Date/Time Formatters

### Dates
```swift
LocaleFormatters.fullDate        // "Monday, December 23, 2025"
LocaleFormatters.longDate        // "December 23, 2025"
LocaleFormatters.mediumDate      // "Dec 23, 2025"
LocaleFormatters.shortDate       // "12/23/25"
LocaleFormatters.monthYear       // "December 2025"
LocaleFormatters.monthDay        // "Dec 23"
```

### Times
```swift
LocaleFormatters.shortTime       // "2:30 PM" or "14:30"
LocaleFormatters.mediumTime      // "2:30:45 PM" or "14:30:45"
LocaleFormatters.hourMinute      // "2:30 PM" or "14:30"
```

### Durations
```swift
LocaleFormatters.formatDuration(seconds: 3665)       // "1h 1m"
LocaleFormatters.formatDurationColons(seconds: 3665) // "1:01:05"
```

## 🔢 Number Formatters

```swift
LocaleFormatters.integer         // "1,234" or "1.234" or "1 234"
LocaleFormatters.decimal         // "3.14" or "3,14"
LocaleFormatters.percentage      // "85%" (locale-aware spacing)
LocaleFormatters.gpa             // "3.67" (always 2 decimals)
LocaleFormatters.currency        // "$5.00" or "5,00 €"
```

## 🌍 Supported Languages (14)

ar, en, es, fr, is, it, ja, nl, ru, th, uk, zh-HK, zh-Hans, zh-Hant

## ⚠️ Common Mistakes

### Don't Hardcode Plurals
```swift
// ❌ Wrong
Text(count == 1 ? "item" : "items")

// ✅ Right
Text(String.localizedStringWithFormat(
    NSLocalizedString("items_count", comment: ""), count))
```

### Don't Concatenate Strings
```swift
// ❌ Wrong - word order varies!
Text(name + " has " + "\(count)" + " items")

// ✅ Right
String(format: NSLocalizedString("user_has_items", comment: ""), name, count)
```

### Don't Use Fixed Date Formats
```swift
// ❌ Wrong
"12/31/2025"  // US-only!

// ✅ Right
LocaleFormatters.shortDate.string(from: date)
```

### Always Use .autoupdatingCurrent
```swift
// ❌ Wrong
let calendar = Calendar.current

// ✅ Right
let calendar = Calendar.autoupdatingCurrent
```

## 🧪 Testing

### Manual
1. System Settings > Language & Region
2. Change language to Spanish
3. Launch app - should update immediately
4. Check: no raw keys, proper plurals, correct formats

### Programmatic
```swift
let testLocales = [
    Locale(identifier: "en_US"),
    Locale(identifier: "es_ES"),
    Locale(identifier: "de_DE"),
]
// Test formatters with each locale
```

## 📚 More Info

- `LOCALIZATION_IMPLEMENTATION_PLAN.md` - Full guide
- `LOCALIZATION_IMPLEMENTATION_SUMMARY.md` - What's done
- `SharedCore/Utilities/LocaleFormatters.swift` - All formatters
- `SharedCore/DesignSystem/Localizable.stringsdict` - Plural rules
