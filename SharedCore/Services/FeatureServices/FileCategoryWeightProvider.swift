import Foundation

/// Provides weighting scores for file categories used in practice test generation
/// These weights determine the relevance of different file types for generating practice questions
enum FileCategoryWeightProvider {
    /// Get the practice test relevance weight for a file category
    /// - Parameter category: The file category to weight
    /// - Returns: A weight between 0.0 and 1.0, where higher is more relevant
    static func weight(for category: FileCategory) -> Double {
        switch category {
        case .rubric:
            1.00 // Highest: grading criteria are most relevant
        case .syllabus:
            0.90 // Course structure and topics
        case .classNotes:
            0.80 // Lecture notes and materials
        case .practiceTest:
            0.75 // Actual practice materials
        case .test:
            0.70 // Past tests
        case .notes:
            0.40 // Student notes
        case .other:
            0.20 // Generic files
        case .uncategorized:
            0.10 // Lowest: unknown content
        case .assignmentList:
            0.30 // Assignment lists have some relevance
        }
    }

    /// Returns all categories sorted by weight (descending)
    static var categoriesByWeight: [FileCategory] {
        FileCategory.allCases.sorted { weight(for: $0) > weight(for: $1) }
    }

    /// Returns high-signal categories (weight >= 0.70)
    static var highSignalCategories: [FileCategory] {
        FileCategory.allCases.filter { weight(for: $0) >= 0.70 }
    }
}
