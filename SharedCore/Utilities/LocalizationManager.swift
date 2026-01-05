import Foundation
import SwiftUI

/// Localization utility that ensures keys never appear in UI
/// Falls back to English text if key is missing
struct LocalizationManager {
    private static var cachedEnglishTable: [String: String]?
    
    /// Get localized string with guaranteed fallback
    /// Never returns the key itself - always returns human-readable text
    static func string(_ key: String, comment: String = "") -> String {
        // Try main bundle first
        let localized = NSLocalizedString(key, bundle: .main, comment: comment)
        
        // If localization failed, it returns the key itself
        if localized == key {
            if let english = englishString(for: key) {
                return english
            }
            #if DEBUG
            DebugLogger.log("⚠️ LOCALIZATION MISSING in main bundle: \(key)")
            if let stringsPath = Bundle.main.path(forResource: "Localizable", ofType: "strings") {
                DebugLogger.log("   Localizable.strings found at: \(stringsPath)")
            } else {
                DebugLogger.log("   Localizable.strings NOT FOUND in main bundle")
            }
            #endif
            
            // Return English fallback from the key structure
            return englishFallback(for: key)
        }
        
        return localized
    }

    private static func englishString(for key: String) -> String? {
        if cachedEnglishTable == nil {
            guard let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "en"),
                  let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
                cachedEnglishTable = [:]
                return nil
            }
            cachedEnglishTable = dict
        }
        return cachedEnglishTable?[key]
    }
    
    /// Generate English fallback from key structure
    /// e.g., "settings.section.general" -> "General"
    private static func englishFallback(for key: String) -> String {
        let components = key.split(separator: ".")
        guard let lastComponent = components.last else {
            return key
        }
        
        // Convert snake_case to Title Case
        let words = String(lastComponent)
            .split(separator: "_")
            .map { $0.capitalized }
        
        return words.joined(separator: " ")
    }
    
    /// Validate that a string is not a localization key
    static func isLocalizationKey(_ text: String) -> Bool {
        // Check for key-like patterns
        let hasMultipleDots = text.components(separatedBy: ".").count >= 2
        let hasUnderscore = text.contains("_")
        let hasNoSpaces = !text.contains(" ")
        let isLowercase = text.lowercased() == text
        
        return hasMultipleDots && (hasUnderscore || (hasNoSpaces && isLowercase))
    }
}

/// Extension to make localization easier
extension String {
    /// Get localized version of this key
    var localized: String {
        LocalizationManager.string(self)
    }
    
    /// Get localized string with comment
    func localized(comment: String) -> String {
        LocalizationManager.string(self, comment: comment)
    }
}

/// SwiftUI Text extension for safe localization
extension Text {
    /// Create localized Text that never shows keys
    init(localizedKey key: String) {
        self.init(LocalizationManager.string(key))
    }
}

#if DEBUG
/// Development-time validator to catch localization issues
struct LocalizationValidator {
    
    /// Scan view hierarchy for visible localization keys
    static func validateNoKeysVisible(in text: String) {
        if LocalizationManager.isLocalizationKey(text) {
            assertionFailure("🚨 LOCALIZATION KEY VISIBLE IN UI: \(text)")
            DebugLogger.log("🚨 RELEASE BLOCKER: Localization key visible: \(text)")
        }
    }
    
    /// Check all strings in Localizable.strings are valid
    static func auditLocalizationFiles() {
        guard let enPath = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "en") else {
            DebugLogger.log("⚠️ English localization file not found")
            return
        }
        
        guard let dict = NSDictionary(contentsOfFile: enPath) as? [String: String] else {
            DebugLogger.log("⚠️ Could not parse localization file")
            return
        }
        
        DebugLogger.log("✅ Localization audit: \(dict.count) keys in English")
        
        // Check for keys that look like they might be displayed directly
        for (key, value) in dict {
            if value == key {
                DebugLogger.log("⚠️ Key has no translation: \(key)")
            }
            if value.isEmpty {
                DebugLogger.log("⚠️ Empty translation for key: \(key)")
            }
        }
    }
}
#endif
