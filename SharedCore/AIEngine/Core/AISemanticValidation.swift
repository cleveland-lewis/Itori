//
// AISemanticValidation.swift
// Semantic validators that catch "valid JSON but nonsense" outputs
//

import Foundation

public enum AISemanticValidationError: Error, LocalizedError {
    case dateOutOfRange(Date, validRange: ClosedRange<Date>)
    case durationOutOfBounds(Int, validRange: ClosedRange<Int>)
    case emptyRequiredField(String)
    case lowConfidence(Double, minimum: Double)
    case logicalInconsistency(String)
    case invalidRelationship(String)

    public var errorDescription: String? {
        switch self {
        case let .dateOutOfRange(date, range):
            "Date \(date) outside valid academic range \(range.lowerBound)...\(range.upperBound)"
        case let .durationOutOfBounds(dur, range):
            "Duration \(dur) outside valid range \(range.lowerBound)...\(range.upperBound)"
        case let .emptyRequiredField(field):
            "Required field '\(field)' is empty"
        case let .lowConfidence(conf, min):
            "Confidence \(conf) below minimum \(min)"
        case let .logicalInconsistency(msg):
            "Logical inconsistency: \(msg)"
        case let .invalidRelationship(msg):
            "Invalid relationship: \(msg)"
        }
    }
}

/// Semantic validators for AI outputs
public enum AISemanticValidator {
    /// Validate academic date range (6 months ago to 2 years in future)
    public static func validateAcademicDate(_ date: Date) throws {
        let now = Date()
        let minDate = Calendar.current.date(byAdding: .month, value: -6, to: now)!
        let maxDate = Calendar.current.date(byAdding: .year, value: 2, to: now)!

        let validRange = minDate ... maxDate
        guard validRange.contains(date) else {
            throw AISemanticValidationError.dateOutOfRange(date, validRange: validRange)
        }
    }

    /// Validate duration is reasonable (5 min to 12 hours)
    public static func validateDuration(_ minutes: Int, min: Int = 5, max: Int = 720) throws {
        let validRange = min ... max
        guard validRange.contains(minutes) else {
            throw AISemanticValidationError.durationOutOfBounds(minutes, validRange: validRange)
        }
    }

    /// Validate non-empty string
    public static func validateNonEmpty(_ string: String, fieldName: String) throws {
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AISemanticValidationError.emptyRequiredField(fieldName)
        }
    }

    /// Validate confidence threshold
    public static func validateConfidence(_ confidence: Double, minimum: Double = 0.4) throws {
        guard confidence >= minimum else {
            throw AISemanticValidationError.lowConfidence(confidence, minimum: minimum)
        }
    }

    /// Validate date ordering (assigned before due)
    public static func validateDateOrdering(assigned: Date?, due: Date) throws {
        guard let assigned else { return }

        guard assigned <= due else {
            throw AISemanticValidationError.invalidRelationship(
                "Assigned date \(assigned) is after due date \(due)"
            )
        }
    }

    /// Validate duration estimate consistency
    public static func validateDurationEstimate(min: Int, estimated: Int, max: Int) throws {
        guard min <= estimated && estimated <= max else {
            throw AISemanticValidationError.logicalInconsistency(
                "Duration estimate inconsistent: min=\(min) est=\(estimated) max=\(max)"
            )
        }

        guard min > 0 && max > 0 else {
            throw AISemanticValidationError.logicalInconsistency(
                "Duration bounds must be positive: min=\(min) max=\(max)"
            )
        }
    }

    /// Validate assignment category
    public static func validateCategory(_ category: String) throws {
        let valid = ["homework", "reading", "quiz", "review", "project", "exam", "other"]
        guard valid.contains(category.lowercased()) else {
            throw AISemanticValidationError.emptyRequiredField("category")
        }
    }

    /// Validate course reference exists
    public static func validateCourseReference(_ courseID: String, in courses: Set<String>) throws {
        guard courses.contains(courseID) else {
            throw AISemanticValidationError.invalidRelationship(
                "Course ID \(courseID) not found in active courses"
            )
        }
    }
}

/// Confidence-based output policy
public enum AIConfidencePolicy {
    /// Should output be auto-applied?
    public static func shouldAutoApply(confidence: Double) -> Bool {
        confidence >= 0.75
    }

    /// Should output be suggested to user?
    public static func shouldSuggest(confidence: Double) -> Bool {
        confidence >= 0.5 && confidence < 0.75
    }

    /// Should output be held for manual review?
    public static func requiresReview(confidence: Double) -> Bool {
        confidence < 0.5
    }

    /// Describe confidence level for UI
    public static func describe(confidence: Double) -> String {
        switch confidence {
        case 0.9 ... 1.0: "Very confident"
        case 0.75 ..< 0.9: "Confident"
        case 0.5 ..< 0.75: "Moderate confidence"
        case 0.25 ..< 0.5: "Low confidence"
        default: "Very low confidence"
        }
    }
}
