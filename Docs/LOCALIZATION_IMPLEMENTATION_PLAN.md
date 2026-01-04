# Localization Implementation Plan

## Current Status

### ✅ What's Already Good
1. **String Catalog**: Using modern `.xcstrings` format with 14 languages
2. **LocaleFormatters**: Comprehensive utility for locale-aware formatting
3. **Localization Infrastructure**: 
   - 761 NSLocalizedString calls
   - 575 .localized calls
   - LocalizedStrings.swift with type-safe helpers
4. **Supported Languages**: ar, en, es, fr, is, it, ja, nl, ru, th, uk, zh-HK, zh-Hans, zh-Hant

### ⚠️ Issues Found

1. **Hardcoded Numbers & Symbols**: Numbers like counts display without localization
2. **Raw DateFormatter**: 118 instances of DateFormatter() instead of LocaleFormatters
3. **Missing .stringsdict**: No pluralization rules for proper grammar
4. **Mixed Formatting**: Some dates/times may not respect locale preferences

## Implementation Tasks

### Phase 1: Audit & Fix Hardcoded Content (Priority: HIGH)

#### Task 1.1: Number Formatting
**Files to Update:**
- `Platforms/macOS/Scenes/DashboardView.swift`
- All views displaying counts, percentages, GPAs

**Changes:**
```swift
// BAD
Text("\(count)")

// GOOD  
Text(LocaleFormatters.integer.string(from: NSNumber(value: count)) ?? "\(count)")

// BETTER (for common cases)
Text("\(count)") // OK for simple counts in UI context
Text(snapshot.remainingPercent, format: .percent) // Use SwiftUI format
```

#### Task 1.2: Date/Time Formatting Audit
**Action:** Replace all DateFormatter() with LocaleFormatters
```bash
grep -rn "DateFormatter()" --include="*.swift" | grep -v "LocaleFormatters"
```

#### Task 1.3: Duration Formatting
**Action:** Use LocaleFormatters.formatDuration() consistently
```swift
// BAD
"\(minutes)m"

// GOOD
LocaleFormatters.formatDuration(seconds: TimeInterval(minutes * 60))
```

### Phase 2: Add Pluralization Rules (Priority: HIGH)

#### Task 2.1: Create Localizable.stringsdict
**File:** `SharedCore/DesignSystem/Localizable.stringsdict`

**Required Pluralization Keys:**
1. `tasks_due_count` - "1 task due" vs "N tasks due"
2. `events_scheduled_count` - "1 event scheduled" vs "N events scheduled"  
3. `assignments_count` - "1 assignment" vs "N assignments"
4. `minutes_remaining` - "1 minute" vs "N minutes"
5. `hours_total` - "1 hour" vs "N hours"
6. `study_sessions_count` - "1 session" vs "N sessions"

**Example Structure:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>tasks_due_count</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@count@</string>
        <key>count</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>zero</key>
            <string>No tasks due</string>
            <key>one</key>
            <string>1 task due</string>
            <key>other</key>
            <string>%d tasks due</string>
        </dict>
    </dict>
</dict>
</plist>
```

#### Task 2.2: Update Code to Use Plurals
```swift
// BAD
Text(dueToday == 1 ? "Task due today" : "Tasks due today")

// GOOD
Text(String.localizedStringWithFormat(
    NSLocalizedString("tasks_due_count", comment: ""), 
    dueToday
))
```

### Phase 3: Locale-Aware Number Display (Priority: MEDIUM)

#### Task 3.1: Add SwiftUI Format Extensions
**File:** `SharedCore/Extensions/FormatStyle+Extensions.swift`

```swift
import SwiftUI

extension FormatStyle where Self == IntegerFormatStyle<Int> {
    static var localizedInteger: IntegerFormatStyle<Int> {
        .init(locale: .autoupdatingCurrent)
    }
}

extension FormatStyle where Self == FloatingPointFormatStyle<Double> {
    static var localizedDecimal: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0...2))
    }
    
    static var localizedGPA: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(2))
    }
}
```

**Usage:**
```swift
Text(count, format: .localizedInteger)
Text(percentage / 100, format: .percent)
Text(gpa, format: .localizedGPA)
```

### Phase 4: Calendar & Time Handling (Priority: HIGH)

#### Task 4.1: Ensure 12h/24h Time Respects Locale
**Check Files:**
- Timer views
- Calendar event displays
- Planner session times

**Verify:**
```swift
// Using LocaleFormatters.shortTime automatically respects locale
let formatter = LocaleFormatters.shortTime
// OR for manual control:
let formatter = LocaleFormatters.timeFormatter(
    use24Hour: Locale.autoupdatingCurrent.uses24HourTime
)
```

#### Task 4.2: Week Start Day
**Ensure:** Calendar.autoupdatingCurrent is used everywhere
```swift
// GOOD
let calendar = Calendar.autoupdatingCurrent
let firstWeekday = calendar.firstWeekday // Respects locale
```

### Phase 5: Testing Infrastructure (Priority: HIGH)

#### Task 5.1: Create Locale Testing Utility
**File:** `Tests/Unit/ItoriTests/LocalizationTestHelper.swift`

```swift
import XCTest
@testable import Itori

class LocalizationTestHelper {
    static func withLocale<T>(
        _ identifier: String,
        _ block: () -> T
    ) -> T {
        let original = Locale.current
        defer {
            // Note: Can't actually change Locale.current in tests
            // This is for documentation purposes
        }
        return block()
    }
    
    static func testLocales() -> [Locale] {
        [
            Locale(identifier: "en_US"),
            Locale(identifier: "es_ES"),
            Locale(identifier: "ja_JP"),
            Locale(identifier: "ar_SA"),
            Locale(identifier: "de_DE")
        ]
    }
}
```

#### Task 5.2: Add Localization Tests
**File:** `Tests/Unit/ItoriTests/LocalizationTests.swift`

```swift
import XCTest
@testable import Itori

final class LocalizationTests: XCTestCase {
    
    func testNumberFormatting() {
        let testCases: [(Locale, Int, String)] = [
            (Locale(identifier: "en_US"), 1234, "1,234"),
            (Locale(identifier: "de_DE"), 1234, "1.234"),
            (Locale(identifier: "fr_FR"), 1234, "1 234"),
        ]
        
        for (locale, number, expected) in testCases {
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.numberStyle = .decimal
            
            let result = formatter.string(from: NSNumber(value: number))
            XCTAssertEqual(result, expected, 
                "Failed for locale \(locale.identifier)")
        }
    }
    
    func testDateFormatting() {
        let date = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021 00:00 UTC
        
        let testCases: [(Locale, String)] = [
            (Locale(identifier: "en_US"), "1/1/21"),
            (Locale(identifier: "ja_JP"), "2021/01/01"),
            (Locale(identifier: "en_GB"), "01/01/2021"),
        ]
        
        for (locale, _) in testCases {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateStyle = .short
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let result = formatter.string(from: date)
            XCTAssertFalse(result.isEmpty, 
                "Should format date for locale \(locale.identifier)")
        }
    }
    
    func testTimeFormatting12h24h() {
        let date = Date(timeIntervalSince1970: 1609491600) // Jan 1, 2021 09:00 UTC
        
        // US uses 12h
        let usFormatter = DateFormatter()
        usFormatter.locale = Locale(identifier: "en_US")
        usFormatter.timeStyle = .short
        usFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let usTime = usFormatter.string(from: date)
        XCTAssertTrue(usTime.contains("AM") || usTime.contains("PM"))
        
        // France uses 24h
        let frFormatter = DateFormatter()
        frFormatter.locale = Locale(identifier: "fr_FR")
        frFormatter.timeStyle = .short
        frFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let frTime = frFormatter.string(from: date)
        XCTAssertFalse(frTime.contains("AM") || frTime.contains("PM"))
    }
    
    func testDurationFormatting() {
        let seconds: TimeInterval = 3665 // 1h 1m 5s
        let result = LocaleFormatters.formatDuration(seconds: seconds)
        
        // Should show hours and minutes for durations over 1 hour
        XCTAssertTrue(result.contains("h") || result.contains("hr"))
        XCTAssertTrue(result.contains("m") || result.contains("min"))
    }
    
    func testPluralRules() {
        // Test English plurals
        let zero = String.localizedStringWithFormat(
            NSLocalizedString("tasks_due_count", comment: ""),
            0
        )
        let one = String.localizedStringWithFormat(
            NSLocalizedString("tasks_due_count", comment: ""),
            1
        )
        let many = String.localizedStringWithFormat(
            NSLocalizedString("tasks_due_count", comment: ""),
            5
        )
        
        XCTAssertNotEqual(one, many, "Plurals should differ")
    }
    
    func testNoRawLocalizationKeys() {
        // This is more of a runtime/UI test
        // We check that common keys are localized
        let testKeys = [
            "dashboard.section.today",
            "dashboard.section.calendar",
            "task.type.homework",
            "common.today"
        ]
        
        for key in testKeys {
            let localized = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localized, key, 
                "Key '\(key)' should be localized, got raw key back")
        }
    }
}
```

### Phase 6: RTL (Right-to-Left) Support (Priority: MEDIUM)

#### Task 6.1: Verify RTL Layout
**Languages:** Arabic (ar), Hebrew (he if added)

**Check:**
- All HStacks use proper leading/trailing instead of left/right
- Text alignment respects natural direction
- Icons flip appropriately (arrows, etc.)

**Test:**
```swift
.environment(\.layoutDirection, .rightToLeft)
```

### Phase 7: Documentation & Guidelines (Priority: LOW)

#### Task 7.1: Create Developer Guidelines
**File:** `Docs/LOCALIZATION_GUIDELINES.md`

**Contents:**
- How to add new strings
- When to use .stringsdict
- Number/date formatting best practices
- Testing checklist
- Common pitfalls

## Validation Checklist

### Manual Testing
- [ ] Switch system language to Spanish - app updates immediately
- [ ] Switch system language to Japanese - dates/numbers format correctly
- [ ] Switch system language to Arabic - layout is RTL
- [ ] Change region to France - numbers use spaces, 24h time
- [ ] Change region to US - numbers use commas, 12h time  
- [ ] Check all main screens for any raw localization keys
- [ ] Verify plurals display correctly (0 items, 1 item, 2 items)

### Automated Testing
- [ ] All LocalizationTests pass
- [ ] No hardcoded strings in UI detected
- [ ] Number formatting tests pass for 3+ locales
- [ ] Date/time formatting tests pass for 3+ locales
- [ ] Duration formatting respects locale
- [ ] Plural rules work correctly

### Code Review
- [ ] No `DateFormatter()` without locale set
- [ ] No `NumberFormatter()` without locale set
- [ ] All user-visible strings use NSLocalizedString
- [ ] Counts use plural rules where appropriate
- [ ] Calendar uses .autoupdatingCurrent
- [ ] No hardcoded "AM/PM" strings

## Implementation Priority

### Week 1: Critical Fixes
1. Add .stringsdict for pluralization
2. Fix hardcoded plurals in DashboardView
3. Audit and fix critical DateFormatter usage
4. Add basic localization tests

### Week 2: Comprehensive Audit
1. Fix all number formatting
2. Update all DateFormatter instances to LocaleFormatters
3. Test in 3+ locales
4. Fix any remaining hardcoded strings

### Week 3: Polish & Testing
1. Add comprehensive test coverage
2. RTL testing and fixes
3. Documentation
4. Final validation across all supported languages

## Files to Create/Update

### New Files
- [ ] `SharedCore/DesignSystem/Localizable.stringsdict`
- [ ] `SharedCore/Extensions/FormatStyle+Extensions.swift`
- [ ] `Tests/Unit/ItoriTests/LocalizationTests.swift`
- [ ] `Tests/Unit/ItoriTests/LocalizationTestHelper.swift`
- [ ] `Docs/LOCALIZATION_GUIDELINES.md`

### Files to Update
- [ ] `Platforms/macOS/Scenes/DashboardView.swift` - Fix plurals & numbers
- [ ] All Timer views - Ensure LocaleFormatters usage
- [ ] All Calendar views - Ensure locale-aware dates
- [ ] All Assignment views - Fix counts and dates
- [ ] `SharedCore/Utilities/LocaleFormatters.swift` - Add any missing helpers

## Success Metrics

1. **Zero visible localization keys** in production UI
2. **100% locale-aware** number/date/time formatting
3. **Correct pluralization** in all supported languages
4. **Immediate language switching** when system language changes
5. **RTL layout** working correctly for Arabic
6. **90%+ test coverage** for localization utilities

## Notes

- Use `.autoupdatingCurrent` for Calendar and Locale to respond to system changes
- SwiftUI's built-in `format:` parameter is preferred for iOS 15+
- Keep LocaleFormatters.swift for backward compatibility and convenience
- String catalogs (.xcstrings) are the modern approach - no need for .strings files
- Plurals MUST use .stringsdict - it's the only way to support all language rules
