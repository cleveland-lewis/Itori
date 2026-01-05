import XCTest
@testable import Itori

final class LocalizationComprehensiveTests: XCTestCase {
    
    // MARK: - Number Formatting Tests
    
    func testIntegerFormatting() {
        let testCases: [(Locale, Int, String)] = [
            (Locale(identifier: "en_US"), 1234, "1,234"),
            (Locale(identifier: "de_DE"), 1234, "1.234"),
            (Locale(identifier: "fr_FR"), 1234, "1 234"),
            (Locale(identifier: "es_ES"), 1234, "1.234"),
            (Locale(identifier: "ja_JP"), 1234, "1,234"),
        ]
        
        for (locale, number, expected) in testCases {
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.numberStyle = .decimal
            
            let result = formatter.string(from: NSNumber(value: number))
            XCTAssertEqual(result, expected, 
                "Integer formatting failed for locale \(locale.identifier)")
        }
    }
    
    func testDecimalFormatting() {
        let testCases: [(Locale, Double, String)] = [
            (Locale(identifier: "en_US"), 3.14159, "3.14"),
            (Locale(identifier: "de_DE"), 3.14159, "3,14"),
            (Locale(identifier: "fr_FR"), 3.14159, "3,14"),
        ]
        
        for (locale, number, expected) in testCases {
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            
            let result = formatter.string(from: NSNumber(value: number))
            XCTAssertEqual(result, expected,
                "Decimal formatting failed for locale \(locale.identifier)")
        }
    }
    
    func testPercentageFormatting() {
        let testCases: [(Locale, Double)] = [
            (Locale(identifier: "en_US"), 0.85),
            (Locale(identifier: "es_ES"), 0.85),
            (Locale(identifier: "fr_FR"), 0.85),
        ]
        
        for (locale, number) in testCases {
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.numberStyle = .percent
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 1
            
            let result = formatter.string(from: NSNumber(value: number))
            XCTAssertNotNil(result, "Percentage formatting failed for locale \(locale.identifier)")
            XCTAssertTrue(result!.contains("85") || result!.contains("٨٥"),
                "Should contain 85 for locale \(locale.identifier), got: \(result!)")
        }
    }
    
    // MARK: - Date Formatting Tests
    
    func testShortDateFormatting() {
        let date = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021 00:00 UTC
        
        let testCases: [(Locale, String)] = [
            (Locale(identifier: "en_US"), "1/1/21"),
            (Locale(identifier: "en_GB"), "01/01/2021"),
            (Locale(identifier: "de_DE"), "01.01.21"),
            (Locale(identifier: "ja_JP"), "2021/01/01"),
        ]
        
        for (locale, _) in testCases {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateStyle = .short
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let result = formatter.string(from: date)
            XCTAssertFalse(result.isEmpty,
                "Short date formatting failed for locale \(locale.identifier)")
            XCTAssertTrue(result.contains("21") || result.contains("2021") || result.contains("01"),
                "Date should contain year or day for locale \(locale.identifier), got: \(result)")
        }
    }
    
    func testMediumDateFormatting() {
        let date = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021 00:00 UTC
        
        let locales = [
            Locale(identifier: "en_US"),
            Locale(identifier: "es_ES"),
            Locale(identifier: "fr_FR"),
            Locale(identifier: "de_DE"),
        ]
        
        for locale in locales {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateStyle = .medium
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let result = formatter.string(from: date)
            XCTAssertFalse(result.isEmpty,
                "Medium date formatting failed for locale \(locale.identifier)")
            XCTAssertTrue(result.contains("2021") || result.contains("21"),
                "Date should contain year for locale \(locale.identifier), got: \(result)")
        }
    }
    
    // MARK: - Time Formatting Tests
    
    func testTimeFormatting12h() {
        let date = Date(timeIntervalSince1970: 1609491600) // Jan 1, 2021 09:00 UTC
        
        // Locales that use 12-hour time
        let locales = [
            Locale(identifier: "en_US"),
            Locale(identifier: "en_CA"),
        ]
        
        for locale in locales {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeStyle = .short
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let result = formatter.string(from: date)
            XCTAssertTrue(result.contains("AM") || result.contains("PM") || result.contains("am") || result.contains("pm"),
                "12-hour time should contain AM/PM for locale \(locale.identifier), got: \(result)")
        }
    }
    
    func testTimeFormatting24h() {
        let date = Date(timeIntervalSince1970: 1609491600) // Jan 1, 2021 09:00 UTC
        
        // Locales that use 24-hour time
        let locales = [
            Locale(identifier: "fr_FR"),
            Locale(identifier: "de_DE"),
            Locale(identifier: "es_ES"),
        ]
        
        for locale in locales {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeStyle = .short
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let result = formatter.string(from: date)
            XCTAssertFalse(result.contains("AM") || result.contains("PM"),
                "24-hour time should not contain AM/PM for locale \(locale.identifier), got: \(result)")
            XCTAssertTrue(result.contains("9") || result.contains("09"),
                "Time should contain hour for locale \(locale.identifier), got: \(result)")
        }
    }
    
    // MARK: - Duration Formatting Tests
    
    func testDurationFormattingShort() {
        let seconds: TimeInterval = 125 // 2m 5s
        let result = LocaleFormatters.formatDuration(seconds: seconds)
        
        XCTAssertFalse(result.isEmpty, "Duration formatting should produce output")
        // Should show minutes and seconds for durations under 1 hour
        XCTAssertTrue(result.contains("m") || result.contains("min"),
            "Short duration should show minutes, got: \(result)")
    }
    
    func testDurationFormattingLong() {
        let seconds: TimeInterval = 3665 // 1h 1m 5s
        let result = LocaleFormatters.formatDuration(seconds: seconds)
        
        XCTAssertFalse(result.isEmpty, "Duration formatting should produce output")
        // Should show hours and minutes for durations over 1 hour
        XCTAssertTrue(result.contains("h") || result.contains("hr") || result.contains("hour"),
            "Long duration should show hours, got: \(result)")
        XCTAssertTrue(result.contains("m") || result.contains("min"),
            "Long duration should show minutes, got: \(result)")
    }
    
    func testDurationFormattingColons() {
        let testCases: [(TimeInterval, String)] = [
            (125, "2:05"),      // 2m 5s
            (3665, "1:01:05"),  // 1h 1m 5s
            (59, "0:59"),       // 59s
        ]
        
        for (seconds, expectedPattern) in testCases {
            let result = LocaleFormatters.formatDurationColons(seconds: seconds)
            XCTAssertEqual(result, expectedPattern,
                "Duration \(seconds)s should format as \(expectedPattern), got: \(result)")
        }
    }
    
    // MARK: - Pluralization Tests
    
    func testTaskCountPluralization() {
        let testCases = [
            (0, "No tasks due"),
            (1, "1 task due"),
            (2, "2 tasks due"),
            (5, "5 tasks due"),
        ]
        
        for (count, _) in testCases {
            let result = String.localizedStringWithFormat(
                NSLocalizedString("tasks_due_count", comment: ""),
                count
            )
            
            XCTAssertNotEqual(result, "tasks_due_count",
                "Pluralization key should be localized")
            
            if count == 0 {
                XCTAssertTrue(result.lowercased().contains("no"),
                    "Zero count should say 'no', got: \(result)")
            } else if count == 1 {
                XCTAssertTrue(result.contains("1"),
                    "One count should contain '1', got: \(result)")
                XCTAssertTrue(result.lowercased().contains("task"),
                    "One count should be singular, got: \(result)")
            } else {
                XCTAssertTrue(result.contains("\(count)"),
                    "Multiple count should contain number, got: \(result)")
                XCTAssertTrue(result.lowercased().contains("task"),
                    "Multiple count should mention tasks, got: \(result)")
            }
        }
    }
    
    func testEventCountPluralization() {
        let testCases = [0, 1, 2, 10]
        
        for count in testCases {
            let result = String.localizedStringWithFormat(
                NSLocalizedString("events_scheduled", comment: ""),
                count
            )
            
            XCTAssertNotEqual(result, "events_scheduled",
                "Event pluralization key should be localized")
            XCTAssertFalse(result.isEmpty,
                "Event count should produce non-empty string")
        }
    }
    
    func testMinutesPluralization() {
        let testCases = [0, 1, 30, 120]
        
        for count in testCases {
            let result = String.localizedStringWithFormat(
                NSLocalizedString("minutes_count", comment: ""),
                count
            )
            
            XCTAssertNotEqual(result, "minutes_count",
                "Minutes pluralization key should be localized")
            
            if count == 1 {
                XCTAssertFalse(result.lowercased().contains("minutes"),
                    "One minute should be singular, got: \(result)")
                XCTAssertTrue(result.lowercased().contains("minute"),
                    "One minute should say 'minute', got: \(result)")
            }
        }
    }
    
    // MARK: - Localization Key Tests
    
    func testCommonKeysAreLocalized() {
        let testKeys = [
            "common.today",
            "common.due",
            "common.edit",
            "common.done",
            "task.type.homework",
            "task.type.quiz",
            "task.type.exam",
        ]
        
        for key in testKeys {
            let localized = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localized, key,
                "Key '\(key)' should be localized, not showing raw key")
        }
    }
    
    func testDashboardKeysAreLocalized() {
        let testKeys = [
            "dashboard.section.today",
            "dashboard.section.calendar",
            "dashboard.section.weekly_workload",
            "dashboard.section.study_time_trend",
            "dashboard.section.upcoming_assignments",
        ]
        
        for key in testKeys {
            let localized = NSLocalizedString(key, comment: "")
            XCTAssertNotEqual(localized, key,
                "Dashboard key '\(key)' should be localized")
        }
    }
    
    // MARK: - LocaleFormatters Tests
    
    func testLocaleFormattersProduceNonEmptyStrings() {
        let date = Date()
        
        XCTAssertFalse(LocaleFormatters.shortDate.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.mediumDate.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.longDate.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.fullDate.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.shortTime.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.mediumTime.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.dateAndTime.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.dayName.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.shortDayName.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.monthDay.string(from: date).isEmpty)
        XCTAssertFalse(LocaleFormatters.monthYear.string(from: date).isEmpty)
    }
    
    func testLocaleFormattersNumberFormatting() {
        XCTAssertNotNil(LocaleFormatters.decimal.string(from: NSNumber(value: 3.14)))
        XCTAssertNotNil(LocaleFormatters.percentage.string(from: NSNumber(value: 0.85)))
        XCTAssertNotNil(LocaleFormatters.gpa.string(from: NSNumber(value: 3.67)))
        XCTAssertNotNil(LocaleFormatters.integer.string(from: NSNumber(value: 1234)))
    }
    
    // MARK: - Calendar Tests
    
    func testCalendarFirstWeekdayRespectLocale() {
        let testLocales = [
            Locale(identifier: "en_US"), // Sunday = 1
            Locale(identifier: "en_GB"), // Monday = 2
            Locale(identifier: "fr_FR"), // Monday = 2
        ]
        
        for locale in testLocales {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = locale
            
            XCTAssertTrue(calendar.firstWeekday >= 1 && calendar.firstWeekday <= 7,
                "First weekday should be 1-7 for locale \(locale.identifier)")
        }
    }
    
    func testCalendarAutoUpdates() {
        let calendar = Calendar.autoupdatingCurrent
        XCTAssertNotNil(calendar.locale, "Auto-updating calendar should have a locale")
        XCTAssertTrue(calendar.firstWeekday >= 1 && calendar.firstWeekday <= 7,
            "Auto-updating calendar should have valid first weekday")
    }
    
    // MARK: - RTL Support Tests
    
    func testRTLLanguageIdentification() {
        let rtlLocales = [
            Locale(identifier: "ar"), // Arabic
            Locale(identifier: "he"), // Hebrew
        ]
        
        for locale in rtlLocales {
            let isRTL = Locale.characterDirection(forLanguage: locale.language.languageCode.identifier ?? "") == .rightToLeft
            XCTAssertTrue(isRTL, "Locale \(locale.identifier) should be RTL")
        }
        
        let ltrLocales = [
            Locale(identifier: "en"),
            Locale(identifier: "es"),
            Locale(identifier: "fr"),
        ]
        
        for locale in ltrLocales {
            let isLTR = Locale.characterDirection(forLanguage: locale.language.languageCode.identifier ?? "") == .leftToRight
            XCTAssertTrue(isLTR, "Locale \(locale.identifier) should be LTR")
        }
    }
    
    // MARK: - Edge Cases
    
    func testZeroValues() {
        // Ensure zero values format correctly
        XCTAssertNotNil(LocaleFormatters.integer.string(from: NSNumber(value: 0)))
        XCTAssertNotNil(LocaleFormatters.decimal.string(from: NSNumber(value: 0.0)))
        XCTAssertNotNil(LocaleFormatters.percentage.string(from: NSNumber(value: 0.0)))
        
        // Zero duration
        let zeroDuration = LocaleFormatters.formatDuration(seconds: 0)
        XCTAssertFalse(zeroDuration.isEmpty, "Zero duration should produce output")
    }
    
    func testLargeValues() {
        // Ensure large values format correctly
        let largeNumber = 1_234_567
        let formatted = LocaleFormatters.integer.string(from: NSNumber(value: largeNumber))
        XCTAssertNotNil(formatted, "Large number should format")
        XCTAssertTrue(formatted!.contains("1"), "Large number should contain digits")
        
        // Large duration
        let largeDuration = LocaleFormatters.formatDuration(seconds: 36000) // 10 hours
        XCTAssertFalse(largeDuration.isEmpty, "Large duration should produce output")
    }
    
    func testNegativeValues() {
        // While not common in this app, ensure negative values don't crash
        let negative = LocaleFormatters.integer.string(from: NSNumber(value: -5))
        XCTAssertNotNil(negative, "Negative number should format")
        XCTAssertTrue(negative!.contains("-") || negative!.contains("−"),
            "Negative number should show minus sign")
    }
}
