import Foundation
import NaturalLanguage

/// Enhanced text parser with NLP capabilities for better syllabus parsing
enum EnhancedTextParser {
    /// Parse text content with improved NLP
    static func parseTextContent(_ text: String, fingerprint: String, category: FileCategory) -> ParseResults {
        var results = ParseResults()

        // Use NLTagger for better entity recognition
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text

        let lines = text.components(separatedBy: .newlines)
        var currentContext: ParsingContext = .none

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            // Detect section headers to understand context
            if let detectedContext = detectContext(line) {
                currentContext = detectedContext
                continue
            }

            // Parse based on context and content
            if let assignment = parseAssignmentLine(line, context: currentContext, fingerprint: fingerprint) {
                results.assignments.append(assignment)
            }

            if let event = parseEventLine(line, context: currentContext, fingerprint: fingerprint) {
                results.events.append(event)
            }

            // Extract topics from class notes and syllabi
            if category == .classNotes || category == .syllabus {
                let topics = extractTopics(from: line, tagger: tagger, fingerprint: fingerprint)
                results.topics.append(contentsOf: topics)
            }

            // Extract rubric criteria
            if category == .rubric {
                if let rubric = extractRubric(from: lines[index...], fingerprint: fingerprint) {
                    results.rubrics.append(rubric)
                }
            }
        }

        return results
    }

    // MARK: - Context Detection

    private enum ParsingContext {
        case none
        case schedule
        case assignments
        case exams
        case grading
        case topics
    }

    private static func detectContext(_ line: String) -> ParsingContext? {
        let lowercased = line.lowercased()

        if lowercased.contains("schedule") || lowercased.contains("calendar") {
            return .schedule
        } else if lowercased.contains("assignment") || lowercased.contains("homework") {
            return .assignments
        } else if lowercased.contains("exam") || lowercased.contains("test") || lowercased.contains("quiz") {
            return .exams
        } else if lowercased.contains("grading") || lowercased.contains("rubric") {
            return .grading
        } else if lowercased.contains("topic") || lowercased.contains("chapter") || lowercased.contains("unit") {
            return .topics
        }

        return nil
    }

    // MARK: - Assignment Parsing

    private static func parseAssignmentLine(
        _ line: String,
        context _: ParsingContext,
        fingerprint: String
    ) -> ParsedAssignmentItem? {
        let lowercased = line.lowercased()

        // Keywords that indicate assignments
        let assignmentKeywords = ["assignment", "homework", "hw", "project", "paper", "essay", "lab", "report"]

        guard assignmentKeywords.contains(where: { lowercased.contains($0) }) else {
            return nil
        }

        // Extract title
        let title = extractTitle(from: line)

        // Extract date with multiple patterns
        let date = extractDate(from: line)

        // Determine category
        let category = determineAssignmentCategory(from: lowercased)

        // Extract points if present
        let points = extractPoints(from: line)

        return ParsedAssignmentItem(
            title: title,
            dueDate: date,
            category: category,
            estimatedMinutes: estimateMinutes(for: category, from: line),
            points: points,
            notes: nil,
            sourceFingerprint: fingerprint
        )
    }

    // MARK: - Event Parsing

    private static func parseEventLine(
        _ line: String,
        context _: ParsingContext,
        fingerprint: String
    ) -> ParsedAssessmentEvent? {
        let lowercased = line.lowercased()

        let examKeywords = ["exam", "test", "midterm", "final", "quiz"]

        guard examKeywords.contains(where: { lowercased.contains($0) }) else {
            return nil
        }

        let title = extractTitle(from: line)
        let date = extractDate(from: line)

        let type: AssignmentCategory = lowercased.contains("quiz") ? .quiz : .exam
        let estimatedMinutes = type == .quiz ? 45 : 90
        let points = extractPoints(from: line)

        return ParsedAssessmentEvent(
            title: title,
            date: date,
            type: type,
            estimatedMinutes: estimatedMinutes,
            points: points,
            sourceFingerprint: fingerprint
        )
    }

    // MARK: - Topic Extraction

    private static func extractTopics(from line: String, tagger: NLTagger, fingerprint: String) -> [ParsedTopic] {
        var topics: [ParsedTopic] = []

        tagger.string = line
        let range = line.startIndex ..< line.endIndex
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        var keywords: [String] = []

        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag, tag == .noun || tag == .verb {
                let word = String(line[tokenRange])
                if word.count > 3 { // Filter out short words
                    keywords.append(word.lowercased())
                }
            }
            return true
        }

        // Group keywords into topics (simple heuristic)
        if !keywords.isEmpty {
            let topic = ParsedTopic(
                title: line.trimmingCharacters(in: .whitespacesAndNewlines),
                keywords: Array(Set(keywords)), // Remove duplicates
                sourceFingerprint: fingerprint
            )
            topics.append(topic)
        }

        return topics
    }

    // MARK: - Rubric Extraction

    private static func extractRubric(from lines: ArraySlice<String>, fingerprint: String) -> ParsedRubric? {
        var criteria: [String] = []
        var weights: [Double] = []

        for line in lines.prefix(10) { // Look ahead up to 10 lines
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            // Look for percentage patterns
            if let weight = extractPercentage(from: trimmed) {
                // The criterion is usually the text before the percentage
                if let criterionRange = trimmed.range(of: "\\d+%", options: .regularExpression) {
                    let criterion = String(trimmed[..<criterionRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    if !criterion.isEmpty {
                        criteria.append(criterion)
                        weights.append(weight)
                    }
                }
            }
        }

        guard !criteria.isEmpty else { return nil }

        return ParsedRubric(
            criteria: criteria,
            weights: weights,
            sourceFingerprint: fingerprint
        )
    }

    // MARK: - Helper Methods

    private static func extractTitle(from line: String) -> String {
        var title = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common prefixes
        let prefixes = ["assignment", "homework", "hw", "project", "exam", "test", "quiz"]
        for prefix in prefixes {
            if let range = title.range(of: "\\b\(prefix)\\b", options: [.regularExpression, .caseInsensitive]) {
                title = String(title[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // Remove trailing date/number patterns
        if let colonIndex = title.firstIndex(of: ":") {
            title = String(title[title.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
        }

        return title.isEmpty ? "Unnamed Assignment" : title
    }

    private static func extractDate(from text: String) -> Date? {
        // Enhanced date patterns
        let patterns = [
            // Full date formats
            "(January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{1,2}),?\\s+(\\d{4})",
            "(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\.?\\s+(\\d{1,2}),?\\s+(\\d{4})",

            // Numeric formats
            "(\\d{1,2})/(\\d{1,2})/(\\d{2,4})",
            "(\\d{4})-(\\d{2})-(\\d{2})",

            // Due: prefix variations
            "due:?\\s*([A-Za-z]+\\s+\\d{1,2},?\\s+\\d{4})",
            "due\\s+on:?\\s*([A-Za-z]+\\s+\\d{1,2},?\\s+\\d{4})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = text as NSString
                if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsString.length)) {
                    let matchedString = nsString.substring(with: match.range)
                    if let date = parseDate(from: matchedString) {
                        return date
                    }
                }
            }
        }

        return nil
    }

    private static func parseDate(from string: String) -> Date? {
        let formatters: [DateFormatter] = [
            createFormatter("MMMM d, yyyy"),
            createFormatter("MMM d, yyyy"),
            createFormatter("M/d/yyyy"),
            createFormatter("M/d/yy"),
            createFormatter("yyyy-MM-dd"),
            createFormatter("MMMM d yyyy"),
            createFormatter("MMM d yyyy")
        ]

        let cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "due:?\\s*", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "on\\s*", with: "", options: .regularExpression, range: nil)
            .trimmingCharacters(in: .whitespaces)

        for formatter in formatters {
            if let date = formatter.date(from: cleaned) {
                return date
            }
        }

        return nil
    }

    private static func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    private static func extractPoints(from text: String) -> Double? {
        // Look for patterns like "100 points", "worth 50", "50pts"
        let patterns = [
            "(\\d+)\\s*points?",
            "worth\\s*(\\d+)",
            "(\\d+)\\s*pts?"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = text as NSString
                if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsString.length)),
                   match.numberOfRanges > 1
                {
                    let pointsString = nsString.substring(with: match.range(at: 1))
                    if let points = Double(pointsString) {
                        return points
                    }
                }
            }
        }

        return nil
    }

    private static func extractPercentage(from text: String) -> Double? {
        if let regex = try? NSRegularExpression(pattern: "(\\d+)%", options: []) {
            let nsString = text as NSString
            if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsString.length)),
               match.numberOfRanges > 1
            {
                let percentString = nsString.substring(with: match.range(at: 1))
                if let percent = Double(percentString) {
                    return percent / 100.0
                }
            }
        }
        return nil
    }

    private static func determineAssignmentCategory(from text: String) -> AssignmentCategory {
        if text.contains("project") {
            .project
        } else if text.contains("reading") || text.contains("read") {
            .reading
        } else if text.contains("review") || text.contains("study") {
            .review
        } else if text.contains("quiz") {
            .quiz
        } else if text.contains("exam") || text.contains("test") {
            .exam
        } else {
            .homework
        }
    }

    private static func estimateMinutes(for category: AssignmentCategory, from text: String) -> Int {
        // Check if duration is mentioned in the text
        if let regex = try? NSRegularExpression(pattern: "(\\d+)\\s*(hour|hr|minute|min)", options: .caseInsensitive) {
            let nsString = text as NSString
            if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsString.length)),
               match.numberOfRanges > 2
            {
                let numberString = nsString.substring(with: match.range(at: 1))
                let unitString = nsString.substring(with: match.range(at: 2)).lowercased()

                if let number = Int(numberString) {
                    if unitString.starts(with: "hour") || unitString.starts(with: "hr") {
                        return number * 60
                    } else {
                        return number
                    }
                }
            }
        }

        // Fallback to category defaults
        switch category {
        case .reading: return 45
        case .exam: return 90
        case .homework: return 60
        case .quiz: return 30
        case .review: return 45
        case .project: return 180
        case .practiceTest: return 50
        }
    }
}
