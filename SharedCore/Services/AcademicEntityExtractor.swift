import Foundation

// MARK: - Academic Entity Extract Port

// Simple MeetingTime type for extraction
struct MeetingTime {
    let day: String
    let startTime: String
    let endTime: String
}

/// Port for extracting academic entities (courses, assignments, dates) from text
protocol AcademicEntityExtractPort {
    func extract(from text: String, context: ExtractionContext?) async throws -> AcademicExtractionResult
}

// MARK: - Models

struct ExtractionContext {
    let sourceCourse: Course?
    let semester: Semester?
    let knownInstructors: [String]?
    let knownLocations: [String]?
}

struct AcademicExtractionResult {
    let courses: [ExtractedCourse]
    let assignments: [ExtractedAssignment]
    let dates: [ExtractedDate]
    let policies: [ExtractedPolicy]
    let confidence: ExtractionConfidence
}

struct ExtractedCourse {
    let title: String
    let code: String?
    let instructor: String?
    let meetingTimes: [MeetingTime]?
    let location: String?
    let sourceSpan: TextSpan
    let confidence: Double
}

struct ExtractedAssignment {
    let title: String
    let category: AssignmentCategory?
    let dueDate: Date?
    let estimatedDuration: Int?
    let description: String?
    let weight: String?
    let sourceSpan: TextSpan
    let confidence: Double
}

struct ExtractedDate {
    let date: Date
    let context: String
    let type: DateType
    let sourceSpan: TextSpan
}

enum DateType {
    case dueDate
    case examDate
    case startDate
    case endDate
    case holidayDate
    case meetingDate
}

struct ExtractedPolicy {
    let type: PolicyType
    let description: String
    let sourceSpan: TextSpan
}

enum PolicyType {
    case grading
    case attendance
    case latePenalty
    case academicIntegrity
    case participation
    case other(String)
}

struct TextSpan {
    let start: Int
    let end: Int
    let text: String
}

struct ExtractionConfidence {
    let overall: Double
    let courseDetection: Double
    let assignmentDetection: Double
    let dateDetection: Double
}

enum AcademicExtractionError: Error, LocalizedError {
    case noEntitiesFound
    case insufficientContext
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noEntitiesFound:
            return "No academic entities found in document"
        case .insufficientContext:
            return "Insufficient context to extract entities"
        case .parsingFailed(let reason):
            return "Parsing failed: \(reason)"
        }
    }
}

// MARK: - Academic Entity Extractor Service

@MainActor
class AcademicEntityExtractor: AcademicEntityExtractPort {
    
    private let dateDetector = DateDetector()
    private let assignmentDetector = AssignmentDetector()
    private let courseDetector = CourseDetector()
    private let policyDetector = PolicyDetector()
    
    func extract(from text: String, context: ExtractionContext?) async throws -> AcademicExtractionResult {
        // Normalize text
        let normalizedText = normalizeText(text)
        
        // Extract entities in parallel
        async let courses = courseDetector.detectCourses(in: normalizedText, context: context)
        async let assignments = assignmentDetector.detectAssignments(in: normalizedText, context: context)
        async let dates = dateDetector.detectDates(in: normalizedText)
        async let policies = policyDetector.detectPolicies(in: normalizedText)
        
        let extractedCourses = try await courses
        let extractedAssignments = try await assignments
        let extractedDates = try await dates
        let extractedPolicies = try await policies
        
        // Calculate confidence
        let confidence = calculateConfidence(
            courses: extractedCourses,
            assignments: extractedAssignments,
            dates: extractedDates
        )
        
        return AcademicExtractionResult(
            courses: extractedCourses,
            assignments: extractedAssignments,
            dates: extractedDates,
            policies: extractedPolicies,
            confidence: confidence
        )
    }
    
    private func normalizeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func calculateConfidence(
        courses: [ExtractedCourse],
        assignments: [ExtractedAssignment],
        dates: [ExtractedDate]
    ) -> ExtractionConfidence {
        let courseConf = courses.isEmpty ? 0.0 : courses.map(\.confidence).reduce(0, +) / Double(courses.count)
        let assignmentConf = assignments.isEmpty ? 0.0 : assignments.map(\.confidence).reduce(0, +) / Double(assignments.count)
        let dateConf = dates.isEmpty ? 0.0 : 0.8
        
        let overall = (courseConf + assignmentConf + dateConf) / 3.0
        
        return ExtractionConfidence(
            overall: overall,
            courseDetection: courseConf,
            assignmentDetection: assignmentConf,
            dateDetection: dateConf
        )
    }
}

// MARK: - Detector Classes

class DateDetector {
    func detectDates(in text: String) async throws -> [ExtractedDate] {
        var dates: [ExtractedDate] = []
        let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        
        let matches = detector.matches(in: text, range: range)
        
        for match in matches {
            guard let date = match.date,
                  let matchRange = Range(match.range, in: text) else { continue }
            
            let context = extractContext(around: match.range, in: text)
            let type = determineDateType(from: context)
            
            dates.append(ExtractedDate(
                date: date,
                context: context,
                type: type,
                sourceSpan: TextSpan(
                    start: match.range.location,
                    end: match.range.location + match.range.length,
                    text: String(text[matchRange])
                )
            ))
        }
        
        return dates
    }
    
    private func extractContext(around range: NSRange, in text: String) -> String {
        let start = max(0, range.location - 50)
        let end = min(text.count, range.location + range.length + 50)
        let contextRange = NSRange(location: start, length: end - start)
        
        guard let swiftRange = Range(contextRange, in: text) else { return "" }
        return String(text[swiftRange])
    }
    
    private func determineDateType(from context: String) -> DateType {
        let lowercased = context.lowercased()
        
        if lowercased.contains("due") || lowercased.contains("submit") {
            return .dueDate
        } else if lowercased.contains("exam") || lowercased.contains("test") || lowercased.contains("quiz") {
            return .examDate
        } else if lowercased.contains("start") || lowercased.contains("begin") {
            return .startDate
        } else if lowercased.contains("end") || lowercased.contains("finish") {
            return .endDate
        } else if lowercased.contains("holiday") || lowercased.contains("break") || lowercased.contains("recess") {
            return .holidayDate
        } else {
            return .meetingDate
        }
    }
}

class AssignmentDetector {
    private let assignmentKeywords = [
        "homework", "hw", "assignment", "project", "essay", "paper",
        "quiz", "test", "exam", "midterm", "final", "lab", "report",
        "presentation", "reading", "review", "problem set"
    ]
    
    func detectAssignments(in text: String, context: ExtractionContext?) async throws -> [ExtractedAssignment] {
        var assignments: [ExtractedAssignment] = []
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            guard containsAssignmentKeyword(line) else { continue }
            
            let title = extractTitle(from: line)
            let category = extractCategory(from: line)
            let dueDate = extractDueDate(from: line, nextLines: Array(lines.dropFirst(index).prefix(3)))
            let duration = extractDuration(from: line, category: category)
            let weight = extractWeight(from: line)
            
            let confidence = calculateAssignmentConfidence(
                title: title,
                category: category,
                dueDate: dueDate
            )
            
            guard confidence > 0.3 else { continue }
            
            assignments.append(ExtractedAssignment(
                title: title,
                category: category,
                dueDate: dueDate,
                estimatedDuration: duration,
                description: nil,
                weight: weight,
                sourceSpan: TextSpan(start: 0, end: line.count, text: line),
                confidence: confidence
            ))
        }
        
        return assignments
    }
    
    private func containsAssignmentKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return assignmentKeywords.contains { lowercased.contains($0) }
    }
    
    private func extractTitle(from line: String) -> String {
        // Remove common prefixes and clean up
        var title = line
            .replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        // Take first sentence or up to first dash/colon
        if let range = title.range(of: "[.:-]", options: .regularExpression) {
            title = String(title[..<range.lowerBound])
        }
        
        return title.trimmingCharacters(in: .whitespaces)
    }
    
    private func extractCategory(from line: String) -> AssignmentCategory? {
        let lowercased = line.lowercased()
        
        if lowercased.contains("homework") || lowercased.contains("hw") || lowercased.contains("problem set") {
            return .homework
        } else if lowercased.contains("exam") || lowercased.contains("test") || lowercased.contains("midterm") || lowercased.contains("final") {
            return .exam
        } else if lowercased.contains("quiz") {
            return .quiz
        } else if lowercased.contains("project") {
            return .project
        } else if lowercased.contains("reading") {
            return .reading
        } else if lowercased.contains("review") {
            return .review
        }
        
        return nil
    }
    
    private func extractDueDate(from line: String, nextLines: [String]) -> Date? {
        let combinedText = ([line] + nextLines).joined(separator: " ")
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let range = NSRange(combinedText.startIndex..., in: combinedText)
        
        let matches = detector?.matches(in: combinedText, range: range) ?? []
        return matches.first?.date
    }
    
    private func extractDuration(from line: String, category: AssignmentCategory?) -> Int? {
        // Use category defaults from the earlier spec
        guard let category = category else { return nil }
        
        switch category {
        case .reading: return 45
        case .homework: return 75
        case .review: return 60
        case .project: return 120
        case .exam: return 180
        case .quiz: return 30
        }
    }
    
    private func extractWeight(from line: String) -> String? {
        // Look for percentage patterns
        let pattern = "(\\d+)\\s*%"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let range = Range(match.range(at: 0), in: line) else {
            return nil
        }
        
        return String(line[range])
    }
    
    private func calculateAssignmentConfidence(
        title: String,
        category: AssignmentCategory?,
        dueDate: Date?
    ) -> Double {
        var confidence = 0.3
        
        if !title.isEmpty && title.count > 3 {
            confidence += 0.3
        }
        
        if category != nil {
            confidence += 0.2
        }
        
        if dueDate != nil {
            confidence += 0.2
        }
        
        return min(confidence, 1.0)
    }
}

class CourseDetector {
    func detectCourses(in text: String, context: ExtractionContext?) async throws -> [ExtractedCourse] {
        var courses: [ExtractedCourse] = []
        
        // Look for course code patterns (e.g., "CS 101", "MATH-2301", "BIO101")
        let pattern = "([A-Z]{2,4})\\s*[-\\s]?\\s*(\\d{3,4})"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return courses }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            guard let codeRange = Range(match.range, in: text) else { continue }
            let code = String(text[codeRange])
            
            // Try to find course title nearby
            let contextRange = extractContext(around: match.range, in: text, window: 100)
            let title = extractCourseTitle(from: contextRange, code: code)
            
            courses.append(ExtractedCourse(
                title: title,
                code: code,
                instructor: nil,
                meetingTimes: nil,
                location: nil,
                sourceSpan: TextSpan(
                    start: match.range.location,
                    end: match.range.location + match.range.length,
                    text: code
                ),
                confidence: title.isEmpty ? 0.6 : 0.9
            ))
        }
        
        return courses
    }
    
    private func extractContext(around range: NSRange, in text: String, window: Int) -> String {
        let start = max(0, range.location - window)
        let end = min(text.count, range.location + range.length + window)
        let contextRange = NSRange(location: start, length: end - start)
        
        guard let swiftRange = Range(contextRange, in: text) else { return "" }
        return String(text[swiftRange])
    }
    
    private func extractCourseTitle(from context: String, code: String) -> String {
        // Look for title after code (common pattern: "CS 101: Introduction to Programming")
        if let range = context.range(of: code) {
            let afterCode = String(context[range.upperBound...])
            if let titleMatch = afterCode.range(of: "[:–-]\\s*([A-Z][^\\n]{10,80})", options: .regularExpression) {
                return afterCode[titleMatch].trimmingCharacters(in: CharacterSet(charactersIn: ":–- \n"))
            }
        }
        
        return ""
    }
}

class PolicyDetector {
    private let policyKeywords = [
        "grading": ["grade", "grading", "assessment", "evaluation"],
        "attendance": ["attendance", "attendance policy", "absences"],
        "late": ["late", "late submission", "late penalty", "deadline"],
        "integrity": ["academic integrity", "plagiarism", "cheating", "honor code"],
        "participation": ["participation", "class participation", "engagement"]
    ]
    
    func detectPolicies(in text: String) async throws -> [ExtractedPolicy] {
        var policies: [ExtractedPolicy] = []
        let paragraphs = text.components(separatedBy: "\n\n")
        
        for paragraph in paragraphs {
            guard let policyType = detectPolicyType(in: paragraph) else { continue }
            
            policies.append(ExtractedPolicy(
                type: policyType,
                description: paragraph.trimmingCharacters(in: .whitespacesAndNewlines),
                sourceSpan: TextSpan(start: 0, end: paragraph.count, text: paragraph)
            ))
        }
        
        return policies
    }
    
    private func detectPolicyType(in text: String) -> PolicyType? {
        let lowercased = text.lowercased()
        
        if policyKeywords["grading"]!.contains(where: { lowercased.contains($0) }) {
            return .grading
        } else if policyKeywords["attendance"]!.contains(where: { lowercased.contains($0) }) {
            return .attendance
        } else if policyKeywords["late"]!.contains(where: { lowercased.contains($0) }) {
            return .latePenalty
        } else if policyKeywords["integrity"]!.contains(where: { lowercased.contains($0) }) {
            return .academicIntegrity
        } else if policyKeywords["participation"]!.contains(where: { lowercased.contains($0) }) {
            return .participation
        }
        
        return nil
    }
}
