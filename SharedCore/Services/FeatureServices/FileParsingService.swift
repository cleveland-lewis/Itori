import Combine
import Foundation
#if canImport(PDFKit)
    import PDFKit
#endif

// MARK: - Parsed Data Models

struct ParsedAssignmentItem: Identifiable {
    let id = UUID()
    let title: String
    let dueDate: Date?
    let category: AssignmentCategory
    let estimatedMinutes: Int
    let points: Double?
    let notes: String?
    let sourceFingerprint: String

    var uniqueKey: String {
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let dateString = dueDate.map { ISO8601DateFormatter().string(from: $0) } ?? "nodate"
        return "\(normalizedTitle)_\(category.rawValue)_\(dateString)"
    }
}

struct ParsedAssessmentEvent: Identifiable {
    let id = UUID()
    let title: String
    let date: Date?
    let type: AssignmentCategory // .exam, .quiz
    let estimatedMinutes: Int
    let points: Double?
    let sourceFingerprint: String

    var uniqueKey: String {
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let dateString = date.map { ISO8601DateFormatter().string(from: $0) } ?? "nodate"
        return "\(normalizedTitle)_\(type.rawValue)_\(dateString)"
    }
}

struct ParsedTopic {
    let title: String
    let keywords: [String]
    let sourceFingerprint: String
}

struct ParsedRubric {
    let criteria: [String]
    let weights: [Double]
    let sourceFingerprint: String
}

struct ParseResults {
    var assignments: [ParsedAssignmentItem] = []
    var events: [ParsedAssessmentEvent] = []
    var topics: [ParsedTopic] = []
    var rubrics: [ParsedRubric] = []
}

// MARK: - File Parsing Service

@MainActor
final class FileParsingService: ObservableObject {
    static let shared = FileParsingService()

    @Published private(set) var activeParsingJobs: Set<UUID> = []
    @Published private(set) var parsingProgress: [UUID: Double] = [:]
    @Published var batchReviewItems: BatchReviewState?

    private var parsingQueue: [UUID: Task<Void, Never>] = [:]

    private init() {}

    // MARK: - Public API for Category Updates

    func updateFileCategory(_ file: CourseFile, newCategory: FileCategory) async {
        // Update the file's category in the store
        // Deferred: CourseFileStore integration
        // await MainActor.run {
        //     CourseFileStore.shared.updateCategory(fileId: file.id, category: newCategory)
        // }

        // If the new category triggers parsing, enqueue it
        if newCategory.triggersAutoParsing && file.parseStatus != .parsing {
            await parseFile(file, force: true)
        }
    }

    // MARK: - Main Entry Points

    func parseFile(_ file: CourseFile, force: Bool = false) async {
        guard !activeParsingJobs.contains(file.id) || force else {
            DebugLogger.log("📄 FileParsingService: Already parsing file \(file.id)")
            return
        }

        // Cancel existing job if forcing
        if force {
            parsingQueue[file.id]?.cancel()
        }

        activeParsingJobs.insert(file.id)
        parsingProgress[file.id] = 0.0

        // Update status to parsing
        await updateFileParseStatus(file.id, status: .parsing, error: nil)

        let task = Task {
            do {
                // Simulate progress updates
                await updateProgress(file.id, progress: 0.1)

                let results = try await performParsing(for: file)

                await updateProgress(file.id, progress: 0.7)

                // Check if we have too many items (batch review threshold)
                let totalItems = results.assignments.count + results.events.count
                if totalItems > 200 {
                    // Create batch review state instead of auto-scheduling
                    await MainActor.run {
                        self.batchReviewItems = BatchReviewState(
                            fileId: file.id,
                            fileName: file.filename,
                            courseId: file.courseId,
                            results: results,
                            fingerprint: file.contentFingerprint
                        )
                    }
                    DebugLogger.log("⚠️ FileParsingService: \(totalItems) items found - batch review required")
                } else if file.category == .syllabus || file.category == .assignmentList {
                    // Auto-schedule for normal amounts
                    await scheduleItems(from: results, courseId: file.courseId, fingerprint: file.contentFingerprint)
                }

                await updateProgress(file.id, progress: 1.0)
                await updateFileParseStatus(file.id, status: .parsed, error: nil)
                DebugLogger.log("✅ FileParsingService: Successfully parsed file \(file.displayName)")
            } catch {
                await updateFileParseStatus(file.id, status: .failed, error: error.localizedDescription)
                DebugLogger.log("❌ FileParsingService: Failed to parse file \(file.displayName): \(error)")
            }

            activeParsingJobs.remove(file.id)
            parsingProgress.removeValue(forKey: file.id)
            parsingQueue.removeValue(forKey: file.id)
        }

        parsingQueue[file.id] = task
    }

    private func updateProgress(_ fileId: UUID, progress: Double) async {
        await MainActor.run {
            parsingProgress[fileId] = progress
        }
    }

    // MARK: - Parsing Implementation

    private func performParsing(for file: CourseFile) async throws -> ParseResults {
        // Determine file type and route to appropriate parser
        let fileExtension = file.url.pathExtension.lowercased()

        if fileExtension == "csv" {
            return try await parseCSV(file)
        } else if fileExtension == "pdf" {
            return try await parsePDF(file)
        } else if ["txt", "md", "markdown"].contains(fileExtension) {
            return try await parseText(file)
        } else {
            // Try text parsing as fallback
            return try await parseText(file)
        }
    }

    // MARK: - CSV Parser

    private func parseCSV(_ file: CourseFile) async throws -> ParseResults {
        let data = try Data(contentsOf: file.url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw ParsingError.invalidEncoding
        }

        var results = ParseResults()
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard lines.count > 1 else {
            throw ParsingError.emptyFile
        }

        // Parse header
        let headerLine = lines[0]
        let headers = parseCSVLine(headerLine).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        // Find column indices
        let titleIndex = headers.firstIndex { ["title", "name", "assignment"].contains($0) }
        let typeIndex = headers.firstIndex { ["type", "category"].contains($0) }
        let dueDateIndex = headers.firstIndex { ["due", "duedate", "date"].contains($0) }
        let pointsIndex = headers.firstIndex { ["points", "weight"].contains($0) }
        let notesIndex = headers.firstIndex { ["notes", "description"].contains($0) }

        guard let titleIdx = titleIndex else {
            throw ParsingError.missingRequiredColumn("title")
        }

        // Parse rows
        for line in lines.dropFirst() {
            let values = parseCSVLine(line)

            guard values.count > titleIdx else { continue }

            let title = values[titleIdx]
            guard !title.isEmpty else { continue }

            let typeStr = typeIndex.map { values[$0] } ?? ""
            let category = parseCategory(from: typeStr)

            let dueDateStr = dueDateIndex.map { values[$0] } ?? ""
            let dueDate = Self.parseDate(from: dueDateStr)

            let points = pointsIndex.flatMap { Double(values[$0]) }
            let notes = notesIndex.map { values[$0] } ?? nil

            // Determine if it's an event (exam/quiz) or assignment
            if category == .exam || category == .quiz {
                let event = ParsedAssessmentEvent(
                    title: title,
                    date: dueDate,
                    type: category,
                    estimatedMinutes: category == .exam ? 90 : 45,
                    points: points,
                    sourceFingerprint: file.contentFingerprint
                )
                results.events.append(event)
            } else {
                let assignment = ParsedAssignmentItem(
                    title: title,
                    dueDate: dueDate,
                    category: category,
                    estimatedMinutes: estimateMinutes(for: category),
                    points: points,
                    notes: notes,
                    sourceFingerprint: file.contentFingerprint
                )
                results.assignments.append(assignment)
            }
        }

        return results
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespaces))
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        values.append(currentValue.trimmingCharacters(in: .whitespaces))

        return values
    }

    // MARK: - PDF Parser

    private func parsePDF(_ file: CourseFile) async throws -> ParseResults {
        #if canImport(PDFKit)
            guard let pdfDocument = PDFDocument(url: file.url) else {
                throw ParsingError.cannotOpenPDF
            }

            var fullText = ""
            for pageIndex in 0 ..< pdfDocument.pageCount {
                if let page = pdfDocument.page(at: pageIndex),
                   let pageText = page.string
                {
                    fullText += pageText + "\n"
                }
            }

            return try await parseTextContent(fullText, fingerprint: file.contentFingerprint, category: file.category)
        #else
            throw ParsingError.pdfNotSupported
        #endif
    }

    // MARK: - Text Parser

    private func parseText(_ file: CourseFile) async throws -> ParseResults {
        let data = try Data(contentsOf: file.url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw ParsingError.invalidEncoding
        }

        return try await parseTextContent(content, fingerprint: file.contentFingerprint, category: file.category)
    }

    private func parseTextContent(
        _ text: String,
        fingerprint: String,
        category: FileCategory
    ) async throws -> ParseResults {
        // Use enhanced NLP parser for better results
        EnhancedTextParser.parseTextContent(text, fingerprint: fingerprint, category: category)
    }

    // MARK: - Helper Methods

    private func parseCategory(from string: String) -> AssignmentCategory {
        let lowercased = string.lowercased()

        if lowercased.contains("exam") || lowercased.contains("test") {
            return .exam
        } else if lowercased.contains("quiz") {
            return .quiz
        } else if lowercased.contains("project") {
            return .project
        } else if lowercased.contains("reading") {
            return .reading
        } else if lowercased.contains("review") {
            return .review
        } else {
            return .homework
        }
    }

    private func estimateMinutes(for category: AssignmentCategory) -> Int {
        switch category {
        case .reading: 45
        case .exam: 90
        case .homework: 60
        case .quiz: 30
        case .review: 45
        case .project: 180
        case .practiceTest: 50
        }
    }

    // MARK: - Auto-Scheduling

    private func scheduleItems(from _: ParseResults, courseId _: UUID, fingerprint _: String) async {
        // Deferred: AppTask scheduling integration
        DebugLogger.log("📅 FileParsingService: Auto-scheduling temporarily disabled - needs AppTask refactor")
    }

    private func mapCategoryToTaskType(_ category: AssignmentCategory) -> TaskType {
        switch category {
        case .reading: .reading
        case .exam: .exam
        case .homework: .homework
        case .quiz: .quiz
        case .review: .study
        case .project: .project
        case .practiceTest: .practiceTest
        }
    }

    private func updateFileParseStatus(_: UUID, status _: ParseStatus, error _: String?) async {
        // Deferred: CourseFileStore integration
        // await MainActor.run {
        //     CourseFileStore.shared.updateParseStatus(fileId: fileId, status: status, error: error)
        // }
    }

    // MARK: - Batch Review Support

    func approveBatchReview(_ state: BatchReviewState) async {
        await scheduleItems(from: state.results, courseId: state.courseId, fingerprint: state.fingerprint)
        await MainActor.run {
            self.batchReviewItems = nil
        }
    }

    func cancelBatchReview() async {
        await MainActor.run {
            self.batchReviewItems = nil
        }
    }

    // MARK: - Orphaned Item Management

    /// Find and mark items that are no longer in the current parse
    func cleanupOrphanedItems(courseId _: UUID, currentFingerprint _: String) async -> [AppTask] {
        // TODO: Restore once AppTask interface is stabilized
        DebugLogger.log("🧹 FileParsingService: Cleanup temporarily disabled - needs AppTask refactor")
        return []
    }

    // MARK: - Helper Methods

    func calculateFingerprint(for file: CourseFile) -> String {
        // TODO: Implement fingerprinting logic
        file.id.uuidString
    }

    func queueFileForParsing(_: CourseFile, courseId _: UUID) {
        // TODO: Implement queuing logic
        DebugLogger.log("📄 FileParsingService: Queuing temporarily disabled")
    }

    private static func parseDate(from string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formatters = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "M/d/yyyy",
            "M-d-yyyy"
        ].map { format -> DateFormatter in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }

        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }
}

// MARK: - Batch Review State

struct BatchReviewState: Identifiable {
    let id = UUID()
    let fileId: UUID
    let fileName: String
    let courseId: UUID
    let results: ParseResults
    let fingerprint: String

    var totalItems: Int {
        results.assignments.count + results.events.count
    }
}

// MARK: - Errors

enum ParsingError: LocalizedError {
    case invalidEncoding
    case emptyFile
    case missingRequiredColumn(String)
    case cannotOpenPDF
    case pdfNotSupported

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            "File encoding is not supported"
        case .emptyFile:
            "File is empty"
        case let .missingRequiredColumn(column):
            "Missing required column: \(column)"
        case .cannotOpenPDF:
            "Cannot open PDF file"
        case .pdfNotSupported:
            "PDF parsing not supported on this platform"
        }
    }
}
