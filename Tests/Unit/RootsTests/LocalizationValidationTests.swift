import XCTest
@testable import Roots

/// Critical tests to ensure NO localization keys ever appear in UI
/// These tests are release-blocking - any failure is a critical bug
final class LocalizationValidationTests: XCTestCase {
    
    // MARK: - Key Detection Tests
    
    func testLocalizationKeysNeverReturnedAsIs() {
        // Test that common localization keys return actual text, not the key itself
        let criticalKeys = [
            "common.today",
            "common.due",
            "planner.generate",
            "dashboard.empty.tasks",
            "timer.label.search",
            "settings.section.general",
            "task.type.homework"
        ]
        
        for key in criticalKeys {
            let localized = key.localized
            XCTAssertNotEqual(localized, key, 
                            "🚨 CRITICAL: Key '\(key)' returned itself - missing translation!")
            XCTAssertFalse(LocalizationManager.isLocalizationKey(localized),
                          "🚨 CRITICAL: Localized string looks like a key: '\(localized)'")
        }
    }
    
    func testKeyPatternDetection() {
        // Test that the key detection pattern works correctly
        let validKeys = [
            "settings.section.general",
            "timer.label.search",
            "dashboard.empty_state"
        ]
        
        for key in validKeys {
            XCTAssertTrue(LocalizationManager.isLocalizationKey(key),
                         "Pattern detector should identify '\(key)' as a key")
        }
        
        // Test that normal text doesn't trigger
        let normalText = [
            "Today",
            "Generate Plan",
            "No tasks due",
            "Settings"
        ]
        
        for text in normalText {
            XCTAssertFalse(LocalizationManager.isLocalizationKey(text),
                          "Pattern detector should NOT flag normal text: '\(text)'")
        }
    }
    
    // MARK: - Enum Localization Tests
    
    func testTaskTypeNeverShowsRawValue() {
        // Ensure TaskType never shows rawValue in UI
        let types: [TaskType] = [.homework, .quiz, .exam, .reading, .review, .project]
        
        for type in types {
            let name = type.localizedName
            XCTAssertNotEqual(name, type.rawValue,
                            "🚨 CRITICAL: TaskType.\(type) showing rawValue in UI!")
            XCTAssertFalse(LocalizationManager.isLocalizationKey(name),
                          "🚨 CRITICAL: TaskType localization looks like a key: '\(name)'")
            XCTAssertFalse(name.isEmpty, "TaskType name must not be empty")
        }
    }
    
    func testAssignmentCategoryNeverShowsRawValue() {
        let categories: [AssignmentCategory] = [.homework, .quiz, .exam, .reading, .review, .project]
        
        for category in categories {
            let name = category.localizedName
            XCTAssertFalse(LocalizationManager.isLocalizationKey(name),
                          "🚨 CRITICAL: AssignmentCategory localization looks like a key: '\(name)'")
            XCTAssertFalse(name.isEmpty, "Category name must not be empty")
        }
    }
    
    // MARK: - Completeness Tests
    
    func testAllLocalizationFilesExist() {
        let bundle = Bundle.main
        
        let languages = ["en", "zh-Hans", "zh-Hant"]
        
        for lang in languages {
            let path = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: lang)
            XCTAssertNotNil(path, "🚨 CRITICAL: Missing \(lang) localization file!")
        }
    }
    
    func testNoEmptyTranslations() {
        guard let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "en") else {
            XCTFail("English localization file not found")
            return
        }
        
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            XCTFail("Could not parse English localization file")
            return
        }
        
        for (key, value) in dict {
            XCTAssertFalse(value.isEmpty, "🚨 CRITICAL: Empty translation for key: \(key)")
            XCTAssertNotEqual(value, key, "🚨 CRITICAL: Translation equals key: \(key)")
        }
    }
    
    // MARK: - Fallback Tests
    
    func testMissingKeysFallbackToEnglish() {
        // Test that missing keys fall back to readable English, not the key
        let fakeKey = "this.key.does.not.exist.in.strings.file"
        let fallback = LocalizationManager.string(fakeKey)
        
        XCTAssertNotEqual(fallback, fakeKey, "Missing keys should fall back to English text")
        XCTAssertFalse(fallback.contains("."), "Fallback should not contain dots")
        XCTAssertTrue(fallback.contains(" ") || fallback.count < 20, "Fallback should be readable")
    }
    
    // MARK: - Format String Tests
    
    func testFormatStringsWork() {
        // Test that format strings work correctly
        let steps = PlannerLocalizations.stepsCount(completed: 3, total: 5)
        XCTAssertTrue(steps.contains("3"), "Steps count should contain the number")
        XCTAssertTrue(steps.contains("5"), "Steps count should contain the total")
        
        let hours = PlannerLocalizations.allowedHours(min: 9, max: 17)
        XCTAssertTrue(hours.contains("9"), "Hours should contain min")
        XCTAssertTrue(hours.contains("17"), "Hours should contain max")
    }
    
    // MARK: - Common Localizations Tests
    
    func testCommonLocalizationsNotEmpty() {
        XCTAssertFalse(CommonLocalizations.today.isEmpty)
        XCTAssertFalse(CommonLocalizations.due.isEmpty)
        XCTAssertFalse(CommonLocalizations.noDate.isEmpty)
        XCTAssertFalse(CommonLocalizations.noCourse.isEmpty)
        XCTAssertFalse(CommonLocalizations.edit.isEmpty)
        XCTAssertFalse(CommonLocalizations.done.isEmpty)
    }
    
    func testPlannerLocalizationsNotEmpty() {
        XCTAssertFalse(PlannerLocalizations.today.isEmpty)
        XCTAssertFalse(PlannerLocalizations.generate.isEmpty)
        XCTAssertFalse(PlannerLocalizations.emptyTitle.isEmpty)
        XCTAssertFalse(PlannerLocalizations.emptySubtitle.isEmpty)
    }
    
    func testDashboardLocalizationsNotEmpty() {
        XCTAssertFalse(DashboardLocalizations.emptyCalendar.isEmpty)
        XCTAssertFalse(DashboardLocalizations.emptyEvents.isEmpty)
        XCTAssertFalse(DashboardLocalizations.emptyTasks.isEmpty)
    }
    
    // MARK: - Performance Test
    
    func testLocalizationPerformance() {
        measure {
            // Localization should be fast
            for _ in 0..<1000 {
                _ = "common.today".localized
            }
        }
    }
}
