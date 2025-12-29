//
// AIRedaction.swift
// Production-grade redaction with structure preservation
//

import Foundation

public struct RedactionResult: Sendable {
    public let redactedText: String
    public let bytesRemoved: Int
    public let patternsFound: [String: Int] // pattern name -> count
    
    public init(redactedText: String, bytesRemoved: Int, patternsFound: [String: Int]) {
        self.redactedText = redactedText
        self.bytesRemoved = bytesRemoved
        self.patternsFound = patternsFound
    }
}

/// Redactor that preserves text structure for parsing
public struct AIRedactor: Sendable {
    public enum RedactionLevel {
        case light      // only obvious PII
        case moderate   // + student IDs, names
        case aggressive // + dates, addresses
    }
    
    private let level: RedactionLevel
    
    public init(level: RedactionLevel = .moderate) {
        self.level = level
    }
    
    public func redact(_ text: String) -> RedactionResult {
        var result = text
        var bytesRemoved = 0
        var patternsFound: [String: Int] = [:]
        
        // Email addresses
        let emailPattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        let emailResult = replacePattern(
            in: result,
            pattern: emailPattern,
            replacement: "[EMAIL]"
        )
        result = emailResult.result
        bytesRemoved += emailResult.bytesRemoved
        if emailResult.count > 0 { patternsFound["email"] = emailResult.count }
        
        // Phone numbers (various formats)
        let phonePattern = #"\b(?:\+?1[-.\s]?)?(?:\([2-9][0-9]{2}\)|[2-9][0-9]{2})[-.\s]?[2-9][0-9]{2}[-.\s]?[0-9]{4}\b"#
        let phoneResult = replacePattern(
            in: result,
            pattern: phonePattern,
            replacement: "[PHONE]"
        )
        result = phoneResult.result
        bytesRemoved += phoneResult.bytesRemoved
        if phoneResult.count > 0 { patternsFound["phone"] = phoneResult.count }
        
        // SSN
        let ssnPattern = #"\b\d{3}-\d{2}-\d{4}\b"#
        let ssnResult = replacePattern(
            in: result,
            pattern: ssnPattern,
            replacement: "[SSN]"
        )
        result = ssnResult.result
        bytesRemoved += ssnResult.bytesRemoved
        if ssnResult.count > 0 { patternsFound["ssn"] = ssnResult.count }
        
        // Credit card numbers
        let ccPattern = #"\b(?:\d{4}[-\s]?){3}\d{4}\b"#
        let ccResult = replacePattern(
            in: result,
            pattern: ccPattern,
            replacement: "[CREDIT_CARD]"
        )
        result = ccResult.result
        bytesRemoved += ccResult.bytesRemoved
        if ccResult.count > 0 { patternsFound["credit_card"] = ccResult.count }
        
        if level == .moderate || level == .aggressive {
            // Student IDs (various patterns)
            let studentIDPattern = #"\b[A-Z]{1,3}\d{5,9}\b"#
            let idResult = replacePattern(
                in: result,
                pattern: studentIDPattern,
                replacement: "[STUDENT_ID]"
            )
            result = idResult.result
            bytesRemoved += idResult.bytesRemoved
            if idResult.count > 0 { patternsFound["student_id"] = idResult.count }
        }
        
        if level == .aggressive {
            // Street addresses
            let addressPattern = #"\b\d{1,5}\s+[A-Za-z0-9\s.,-]+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr|Court|Ct)\b"#
            let addrResult = replacePattern(
                in: result,
                pattern: addressPattern,
                replacement: "[ADDRESS]",
                options: .caseInsensitive
            )
            result = addrResult.result
            bytesRemoved += addrResult.bytesRemoved
            if addrResult.count > 0 { patternsFound["address"] = addrResult.count }
            
            // Dates of birth (MM/DD/YYYY format)
            let dobPattern = #"\b(?:0[1-9]|1[0-2])/(?:0[1-9]|[12][0-9]|3[01])/(?:19|20)\d{2}\b"#
            let dobResult = replacePattern(
                in: result,
                pattern: dobPattern,
                replacement: "[DATE]"
            )
            result = dobResult.result
            bytesRemoved += dobResult.bytesRemoved
            if dobResult.count > 0 { patternsFound["date_of_birth"] = dobResult.count }
        }
        
        return RedactionResult(
            redactedText: result,
            bytesRemoved: bytesRemoved,
            patternsFound: patternsFound
        )
    }
    
    private func replacePattern(
        in text: String,
        pattern: String,
        replacement: String,
        options: NSRegularExpression.Options = []
    ) -> (result: String, bytesRemoved: Int, count: Int) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return (text, 0, 0)
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        var result = text
        var totalBytesRemoved = 0
        
        // Replace in reverse order to maintain indices
        for match in matches.reversed() {
            if let matchRange = Range(match.range, in: text) {
                let matchedText = String(text[matchRange])
                let originalBytes = matchedText.utf8.count
                let replacementBytes = replacement.utf8.count
                
                result.replaceSubrange(matchRange, with: replacement)
                totalBytesRemoved += (originalBytes - replacementBytes)
            }
        }
        
        return (result, totalBytesRemoved, matches.count)
    }
}

/// Port-specific redaction policies
public struct AIRedactionPolicy: Sendable {
    public func redactionLevel(for portID: AIPortID, privacy: AIPrivacyLevel) -> AIRedactor.RedactionLevel {
        // On-device only: aggressive redaction
        if privacy == .onDeviceOnly {
            return .aggressive
        }
        
        // Sensitive: moderate redaction
        if privacy == .sensitive {
            return .moderate
        }
        
        // Port-specific policies
        switch portID {
        case .documentIngest, .academicEntityExtract, .assignmentCreation:
            return .moderate // These handle user documents
            
        case .estimateTaskDuration, .workloadForecast:
            return .light // Only metadata
            
        case .generateStudyPlan, .schedulePlacement, .conflictResolution:
            return .light // Only metadata
        }
    }
    
    public func shouldRedact(for portID: AIPortID, providerID: AIProviderID) -> Bool {
        // Always redact for remote providers
        if providerID == .bringYourOwn {
            return true
        }
        
        // Local providers: redact sensitive ports
        switch portID {
        case .documentIngest, .academicEntityExtract, .assignmentCreation:
            return true
        default:
            return false
        }
    }
}
