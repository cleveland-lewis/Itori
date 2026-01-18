import Combine
import Foundation
import PDFKit
import SwiftUI
import UserNotifications

@MainActor
final class SyllabusParsingStore: ObservableObject {
    static let shared = SyllabusParsingStore()

    @Published private(set) var parsingJobs: [SyllabusParsingJob] = []
    @Published private(set) var parsedAssignments: [ParsedAssignment] = []

    private let storageURL: URL

    init(storageURL: URL? = nil) {
        if let storageURL {
            self.storageURL = storageURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupport.appendingPathComponent("Itori", isDirectory: true)
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
            self.storageURL = appDir.appendingPathComponent("syllabus_parsing.json")
        }
        load()
    }

    // MARK: - Job Management

    func createJob(courseId: UUID, fileId: UUID) -> SyllabusParsingJob {
        let job = SyllabusParsingJob(courseId: courseId, fileId: fileId)
        parsingJobs.append(job)
        persist()
        return job
    }

    func startParsing(job: SyllabusParsingJob, file: CourseFile) {
        let fingerprint = FileParsingService.shared.calculateFingerprint(for: file)
        if let jobIndex = parsingJobs.firstIndex(where: { $0.id == job.id }) {
            parsingJobs[jobIndex].contentFingerprint = fingerprint
            persist()
        }

        if fingerprint != file.contentFingerprint {
            var updatedFile = file
            updatedFile.contentFingerprint = fingerprint
            updatedFile.updatedAt = Date()
            CoursesStore.shared?.updateFile(updatedFile)
        }

        if let existing = parsingJobs.first(where: { $0.id == job.id }),
           existing.status == .succeeded,
           existing.contentFingerprint == fingerprint,
           !parsedAssignmentsByJob(job.id).isEmpty
        {
            return
        }

        let fileURL = resolveFileURL(for: file)
        startParsing(job: job, fileURL: fileURL)
    }

    func updateJobStatus(_ jobId: UUID, status: ParsingJobStatus, errorMessage: String? = nil) {
        guard let index = parsingJobs.firstIndex(where: { $0.id == jobId }) else { return }

        parsingJobs[index].status = status
        parsingJobs[index].errorMessage = errorMessage

        switch status {
        case .running:
            parsingJobs[index].startedAt = Date()
        case .succeeded, .failed:
            parsingJobs[index].completedAt = Date()
        default:
            break
        }

        persist()
    }

    func job(for fileId: UUID) -> SyllabusParsingJob? {
        parsingJobs.first { $0.fileId == fileId }
    }

    // MARK: - Parsed Assignments

    func addParsedAssignment(_ assignment: ParsedAssignment) {
        parsedAssignments.append(assignment)
        persist()
    }

    func parsedAssignmentsByCourse(_ courseId: UUID) -> [ParsedAssignment] {
        parsedAssignments.filter { $0.courseId == courseId && !$0.isImported }
    }

    func parsedAssignmentsByJob(_ jobId: UUID) -> [ParsedAssignment] {
        parsedAssignments.filter { $0.jobId == jobId }
    }

    func markAsImported(_ assignmentId: UUID, taskId: UUID) {
        guard let index = parsedAssignments.firstIndex(where: { $0.id == assignmentId }) else { return }
        parsedAssignments[index].isImported = true
        parsedAssignments[index].importedTaskId = taskId
        persist()
    }

    func resetAll() {
        parsingJobs.removeAll()
        parsedAssignments.removeAll()
        try? FileManager.default.removeItem(at: storageURL)
        persist()
    }

    func updateParsedAssignment(_ assignment: ParsedAssignment) {
        guard let index = parsedAssignments.firstIndex(where: { $0.id == assignment.id }) else { return }
        parsedAssignments[index] = assignment
        persist()
    }

    // MARK: - Parsing Logic

    func startParsing(job: SyllabusParsingJob, fileURL: URL?) {
        updateJobStatus(job.id, status: .running)

        // Simulate parsing with basic heuristics
        Task {
            do {
                var didStartSecurityScope = false
                if let fileURL, fileURL.startAccessingSecurityScopedResource() {
                    didStartSecurityScope = true
                }

                defer {
                    if didStartSecurityScope {
                        fileURL?.stopAccessingSecurityScopedResource()
                    }
                }

                let assignments = try await parseFile(fileURL: fileURL, jobId: job.id, courseId: job.courseId)

                for assignment in assignments {
                    addParsedAssignment(assignment)
                }

                updateJobStatus(job.id, status: .succeeded)

                // Send completion notification
                await sendCompletionNotification(courseId: job.courseId)
            } catch {
                updateJobStatus(job.id, status: .failed, errorMessage: error.localizedDescription)
            }
        }
    }

    private func parseFile(fileURL: URL?, jobId: UUID, courseId: UUID) async throws -> [ParsedAssignment] {
        guard let fileURL else {
            throw NSError(
                domain: "SyllabusParser",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "File URL not provided"]
            )
        }

        LOG_DATA(.info, "SyllabusParsingStore", "Starting to parse file: \(fileURL.lastPathComponent)")

        // Extract text from PDF
        let extractor = PDFTextExtractor()
        let extractedText: ExtractedPDFText

        do {
            extractedText = try extractor.extract(from: fileURL)
            LOG_DATA(
                .info,
                "SyllabusParsingStore",
                "Extracted \(extractedText.pageCount) pages, \(extractedText.text.count) characters"
            )
        } catch {
            LOG_DATA(.error, "SyllabusParsingStore", "PDF extraction failed: \(error.localizedDescription)")
            throw NSError(
                domain: "SyllabusParser",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to extract text from PDF: \(error.localizedDescription)"]
            )
        }

        // Parse assignments from text
        var parsedAssignments: [ParsedAssignment] = []
        let text = extractedText.text
        let lines = text.components(separatedBy: .newlines)

        // Look for assignment patterns
        let assignmentPatterns = [
            "assignment",
            "homework",
            "hw",
            "project",
            "essay",
            "paper",
            "quiz",
            "exam",
            "test",
            "midterm",
            "final"
        ]

        let datePattern = try? NSRegularExpression(
            pattern: #"(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})|(\w+ \d{1,2},? \d{4})|(\d{1,2} \w+ \d{4})"#,
            options: [.caseInsensitive]
        )

        for (index, line) in lines.enumerated() {
            let lowercaseLine = line.lowercased()

            // Check if line contains assignment keywords
            guard assignmentPatterns.contains(where: { lowercaseLine.contains($0) }) else {
                continue
            }

            // Extract title (clean up the line)
            var title = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if title.count > 100 {
                title = String(title.prefix(100)) + "..."
            }

            // Try to find a date nearby (within next 3 lines)
            var dueDate: Date?
            let searchRange = index ..< min(index + 4, lines.count)
            for i in searchRange {
                if let date = extractDate(from: lines[i], using: datePattern) {
                    dueDate = date
                    break
                }
            }

            // Infer type
            let inferredType = if lowercaseLine.contains("exam") || lowercaseLine.contains("test") || lowercaseLine
                .contains("midterm") || lowercaseLine.contains("final")
            {
                "Exam"
            } else if lowercaseLine.contains("quiz") {
                "Quiz"
            } else if lowercaseLine.contains("project") || lowercaseLine.contains("essay") || lowercaseLine
                .contains("paper")
            {
                "Project"
            } else {
                "Homework"
            }

            parsedAssignments.append(ParsedAssignment(
                jobId: jobId,
                courseId: courseId,
                title: title,
                dueDate: dueDate,
                inferredType: inferredType,
                provenanceAnchor: line
            ))
        }

        LOG_DATA(.info, "SyllabusParsingStore", "Parsed \(parsedAssignments.count) assignments from file")

        // If no assignments found, return some sample data so user knows parsing ran
        if parsedAssignments.isEmpty {
            LOG_DATA(.info, "SyllabusParsingStore", "No assignments found in file, returning sample data")
            return [
                ParsedAssignment(
                    jobId: jobId,
                    courseId: courseId,
                    title: "No assignments found - check syllabus format",
                    dueDate: nil,
                    inferredType: "Note",
                    provenanceAnchor: "Parsing completed but no assignments detected"
                )
            ]
        }

        return parsedAssignments
    }

    private func extractDate(from text: String, using regex: NSRegularExpression?) -> Date? {
        guard let regex else { return nil }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else {
            return nil
        }

        let matchedString = (text as NSString).substring(with: match.range)

        // Try multiple date formats
        let formatters: [DateFormatter] = {
            let formats = [
                "MM/dd/yyyy",
                "M/d/yyyy",
                "MM-dd-yyyy",
                "M-d-yyyy",
                "MMMM d, yyyy",
                "MMM d, yyyy",
                "d MMMM yyyy",
                "d MMM yyyy"
            ]
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }
        }()

        for formatter in formatters {
            if let date = formatter.date(from: matchedString) {
                return date
            }
        }

        return nil
    }

    private func resolveFileURL(for file: CourseFile) -> URL? {
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

    private func sendCompletionNotification(courseId: UUID) async {
        #if os(macOS)
            let content = UNMutableNotificationContent()
            content.title = "Syllabus Parsing: Complete"
            content.body = "Click to review homework"
            content.sound = .default
            content.userInfo = ["type": "syllabus_parsing_complete", "courseId": courseId.uuidString]

            let request = UNNotificationRequest(
                identifier: "syllabus_parsing_\(courseId.uuidString)",
                content: content,
                trigger: nil // Immediate
            )

            try? await UNUserNotificationCenter.current().add(request)
        #endif
    }

    // MARK: - Persistence

    private struct PersistedData: Codable {
        var parsingJobs: [SyllabusParsingJob]
        var parsedAssignments: [ParsedAssignment]
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode(PersistedData.self, from: data)
            self.parsingJobs = decoded.parsingJobs
            self.parsedAssignments = decoded.parsedAssignments
        } catch {
            DebugLogger.log("Failed to load syllabus parsing data: \(error)")
        }
    }

    private func persist() {
        let snapshot = PersistedData(
            parsingJobs: parsingJobs,
            parsedAssignments: parsedAssignments
        )
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: storageURL, options: [.atomic, .completeFileProtection])
        } catch {
            DebugLogger.log("Failed to persist syllabus parsing data: \(error)")
        }
    }
}
