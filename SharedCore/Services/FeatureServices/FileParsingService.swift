import Combine
import Foundation
#if canImport(PDFKit)
    import PDFKit
#endif

// MARK: - Parsed Data Models

struct ParsedAssignmentItem: Identifiable, Codable {
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

struct ParsedAssessmentEvent: Identifiable, Codable {
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

struct ParsedTopic: Codable {
    let title: String
    let keywords: [String]
    let sourceFingerprint: String
}

struct ParsedRubric: Codable {
    let criteria: [String]
    let weights: [Double]
    let sourceFingerprint: String
}

struct ParseResults: Codable {
    var assignments: [ParsedAssignmentItem] = []
    var events: [ParsedAssessmentEvent] = []
    var topics: [ParsedTopic] = []
    var rubrics: [ParsedRubric] = []
}

private struct StoredParseResults: Codable {
    let fingerprint: String
    let results: ParseResults
}

// MARK: - File Parsing Service

@MainActor
final class FileParsingService: ObservableObject {
    static let shared = FileParsingService()

    @Published private(set) var activeParsingJobs: Set<UUID> = []
    @Published private(set) var parsingProgress: [UUID: Double] = [:]
    @Published var batchReviewItems: BatchReviewState?

    private var parsingQueue: [UUID: Task<Void, Never>] = [:]
    private let repository = CourseModuleRepository()

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

        var fileToParse = file
        let fingerprint = calculateFingerprint(for: file)
        if fingerprint != file.contentFingerprint {
            fileToParse.contentFingerprint = fingerprint
            fileToParse.updatedAt = Date()
            CoursesStore.shared?.updateFile(fileToParse)
        }

        if !force, let cached = await loadCachedResults(for: fileToParse) {
            let totalItems = cached.assignments.count + cached.events.count
            if totalItems > 200 {
                await MainActor.run {
                    self.batchReviewItems = BatchReviewState(
                        fileId: fileToParse.id,
                        fileName: fileToParse.filename,
                        courseId: fileToParse.courseId,
                        results: cached,
                        fingerprint: fileToParse.contentFingerprint
                    )
                }
            }
            DebugLogger.log("📄 FileParsingService: Using cached parse results for \(fileToParse.displayName)")
            return
        }

        // Cancel existing job if forcing
        if force {
            parsingQueue[file.id]?.cancel()
        }

        activeParsingJobs.insert(fileToParse.id)
        parsingProgress[fileToParse.id] = 0.0

        // Update status to parsing
        await updateFileParseStatus(fileToParse.id, status: .parsing, error: nil)

        let task = Task {
            do {
                // Simulate progress updates
                await updateProgress(fileToParse.id, progress: 0.1)

                let results = try await performParsing(for: fileToParse)

                await updateProgress(fileToParse.id, progress: 0.7)

                await storeParseResults(results, for: fileToParse)

                // Check if we have too many items (batch review threshold)
                let totalItems = results.assignments.count + results.events.count
                if totalItems > 200 {
                    // Create batch review state instead of auto-scheduling
                    await MainActor.run {
                        self.batchReviewItems = BatchReviewState(
                            fileId: fileToParse.id,
                            fileName: fileToParse.filename,
                            courseId: fileToParse.courseId,
                            results: results,
                            fingerprint: fileToParse.contentFingerprint
                        )
                    }
                    DebugLogger.log("⚠️ FileParsingService: \(totalItems) items found - batch review required")
                } else if fileToParse.category == .syllabus || fileToParse.category == .assignmentList {
                    // Auto-schedule for normal amounts
                    await scheduleItems(
                        from: results,
                        courseId: fileToParse.courseId,
                        fingerprint: fileToParse.contentFingerprint
                    )
                }

                await updateProgress(fileToParse.id, progress: 1.0)
                await updateFileParseStatus(fileToParse.id, status: .parsed, error: nil)
                DebugLogger.log("✅ FileParsingService: Successfully parsed file \(fileToParse.displayName)")
            } catch {
                await updateFileParseStatus(fileToParse.id, status: .failed, error: error.localizedDescription)
                DebugLogger.log("❌ FileParsingService: Failed to parse file \(fileToParse.displayName): \(error)")
            }

            activeParsingJobs.remove(fileToParse.id)
            parsingProgress.removeValue(forKey: fileToParse.id)
            parsingQueue.removeValue(forKey: fileToParse.id)
        }

        parsingQueue[fileToParse.id] = task
    }

    private func updateProgress(_ fileId: UUID, progress: Double) async {
        await MainActor.run {
            parsingProgress[fileId] = progress
        }
    }

    private func storeParseResults(_ results: ParseResults, for file: CourseFile) async {
        let stored = StoredParseResults(fingerprint: file.contentFingerprint, results: results)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(stored)
            let json = String(data: data, encoding: .utf8)
            try await repository.saveParseResult(
                fileId: file.id,
                parseType: file.category.rawValue,
                success: true,
                extractedText: nil,
                contentJSON: json,
                errorMessage: nil
            )
        } catch {
            DebugLogger.log("❌ FileParsingService: Failed to store parse results: \(error)")
        }
    }

    private func loadCachedResults(for file: CourseFile) async -> ParseResults? {
        do {
            guard let json = try await repository.fetchLatestParseResult(fileId: file.id),
                  let data = json.data(using: .utf8)
            else { return nil }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let stored = try decoder.decode(StoredParseResults.self, from: data)
            guard stored.fingerprint == file.contentFingerprint else { return nil }
            return stored.results
        } catch {
            DebugLogger.log("❌ FileParsingService: Failed to load cached parse results: \(error)")
            return nil
        }
    }

    // MARK: - Parsing Implementation

    func performParsing(for file: CourseFile) async throws -> ParseResults {
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
            // Start accessing security-scoped resource if needed
            let accessing = file.url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    file.url.stopAccessingSecurityScopedResource()
                }
            }

            // Verify file exists
            guard FileManager.default.fileExists(atPath: file.url.path) else {
                DebugLogger.log("❌ PDF file does not exist at path: \(file.url.path)")
                throw ParsingError.cannotOpenPDF
            }

            guard let pdfDocument = PDFDocument(url: file.url) else {
                DebugLogger.log("❌ PDFDocument failed to initialize from URL: \(file.url.path)")
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
        guard let url = resolveFileURL(from: file) else {
            return file.id.uuidString
        }

        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            return data.sha256Hash()
        } catch {
            DebugLogger.log("❌ FileParsingService: Failed to hash file \(file.filename): \(error)")
            return file.id.uuidString
        }
    }

    private func resolveFileURL(from file: CourseFile) -> URL? {
        guard let urlString = file.localURL else { return nil }

        if let bookmarkData = Data(base64Encoded: urlString) {
            var isStale = false
            if let resolved = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                return resolved
            }
        }

        if let url = URL(string: urlString) {
            if url.isFileURL {
                return url
            }
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        let fileURL = URL(fileURLWithPath: urlString)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
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
            "Cannot open PDF file. The file may be corrupted, password-protected, or you may not have permission to access it."
        case .pdfNotSupported:
            "PDF parsing not supported on this platform"
        }
    }
}
