import Foundation
import Combine
import CryptoKit

@MainActor
final class FileParsingService: ObservableObject {
    static let shared = FileParsingService()
    
    @Published private(set) var activeParseJobs: Set<UUID> = []
    
    private var parseQueue: [(file: CourseFile, priority: Int)] = []
    private var throttleTimers: [UUID: Timer] = [:]
    private var isProcessing = false
    private var categoryChangeThrottleDelay: TimeInterval = 1.0
    
    private init() {}
    
    // MARK: - Public API
    
    func queueFileForParsing(_ file: CourseFile, priority: Int = 0) {
        debugLog("📋 QueueFile: \(file.displayName) (priority: \(priority))")
        
        var updatedFile = file
        updatedFile.parseStatus = .queued
        
        // Add to queue
        parseQueue.append((file: updatedFile, priority: priority))
        parseQueue.sort { $0.priority > $1.priority }
        
        NotificationCenter.default.post(name: .courseFileUpdated, object: updatedFile)
        
        // Start processing if not already running
        if !isProcessing {
            Task {
                await processQueue()
            }
        }
    }
    
    func updateFileCategory(_ file: CourseFile, newCategory: FileCategory) async {
        debugLog("🏷️ CategoryChange: \(file.displayName) → \(newCategory.displayName)")
        
        var updatedFile = file
        updatedFile.category = newCategory
        
        // Sync legacy flags
        updatedFile.isSyllabus = (newCategory == .syllabus)
        updatedFile.isPracticeExam = (newCategory == .practiceTest)
        
        NotificationCenter.default.post(name: .courseFileUpdated, object: updatedFile)
        
        // Queue for parsing if category triggers auto-parse
        if newCategory.triggersAutoParsing {
            // Throttle rapid category changes
            throttleTimers[file.id]?.invalidate()
            
            throttleTimers[file.id] = Timer.scheduledTimer(withTimeInterval: categoryChangeThrottleDelay, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.queueFileForParsing(updatedFile, priority: 1)
                    self?.throttleTimers.removeValue(forKey: file.id)
                }
            }
        }
    }
    
    func calculateFingerprint(for file: CourseFile, fileData: Data? = nil) -> String {
        if let data = fileData {
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        }
        
        // Fallback: hash of metadata
        let metadata = "\(file.displayName)-\(file.addedAt.timeIntervalSince1970)"
        if let data = metadata.data(using: .utf8) {
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        }
        
        return UUID().uuidString
    }
    
    // MARK: - Queue Processing
    
    private func processQueue() async {
        guard !isProcessing, !parseQueue.isEmpty else { return }
        
        isProcessing = true
        debugLog("🔄 Processing queue: \(parseQueue.count) files")
        
        while !parseQueue.isEmpty {
            let item = parseQueue.removeFirst()
            await parseFile(item.file)
        }
        
        isProcessing = false
        debugLog("✅ Queue processing complete")
    }
    
    private func parseFile(_ file: CourseFile) async {
        var updatedFile = file
        updatedFile.parseStatus = .parsing
        activeParseJobs.insert(file.id)
        
        NotificationCenter.default.post(name: .courseFileUpdated, object: updatedFile)
        debugLog("🔍 Parse: \(file.displayName) (\(file.category.displayName))")
        
        do {
            // Attempt to load file data
            guard let fileData = loadFileData(for: file) else {
                throw ParsingError.fileNotFound
            }
            
            // Route to appropriate parser
            let parsedAssignments: [ParsedAssignment]
            
            if file.displayName.lowercased().hasSuffix(".csv") {
                parsedAssignments = try parseCSV(fileData: fileData, file: file)
            } else {
                // For now, delegate to existing document parser or stub
                parsedAssignments = []
                debugLog("⚠️ Non-CSV parsing not yet implemented")
            }
            
            // Auto-schedule if we got results
            if !parsedAssignments.isEmpty {
                try await autoSchedule(parsedAssignments, from: file)
            }
            
            // Mark as parsed
            updatedFile.parseStatus = .parsed
            updatedFile.parsedAt = Date()
            updatedFile.parseError = nil
            
            debugLog("✅ Parsed: \(file.displayName) → \(parsedAssignments.count) items")
            
        } catch {
            updatedFile.parseStatus = .failed
            updatedFile.parseError = error.localizedDescription
            debugLog("❌ ParseFailed: \(file.displayName) - \(error.localizedDescription)")
        }
        
        activeParseJobs.remove(file.id)
        NotificationCenter.default.post(name: .courseFileUpdated, object: updatedFile)
    }
    
    // MARK: - CSV Parsing
    
    private func parseCSV(fileData: Data, file: CourseFile) throws -> [ParsedAssignment] {
        guard let content = String(data: fileData, encoding: .utf8) else {
            throw ParsingError.invalidEncoding
        }
        
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw ParsingError.emptyFile
        }
        
        // Parse header
        let headerLine = lines[0]
        let headers = parseCSVLine(headerLine).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        
        // Detect columns (flexible matching)
        let titleCol = headers.firstIndex { ["title", "name", "assignment"].contains($0) }
        let typeCol = headers.firstIndex { ["type", "category"].contains($0) }
        let dueCol = headers.firstIndex { ["due", "duedate", "date"].contains($0) }
        let pointsCol = headers.firstIndex { ["points", "weight"].contains($0) }
        
        guard titleCol != nil else {
            throw ParsingError.missingRequiredColumn("title/name/assignment")
        }
        
        var results: [ParsedAssignment] = []
        
        // Parse data rows
        for (index, line) in lines.dropFirst().enumerated() {
            let values = parseCSVLine(line)
            
            guard let titleIdx = titleCol, titleIdx < values.count else { continue }
            let title = values[titleIdx].trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            
            let type = typeCol.flatMap { $0 < values.count ? values[$0] : nil }
            let dueString = dueCol.flatMap { $0 < values.count ? values[$0] : nil }
            let pointsString = pointsCol.flatMap { $0 < values.count ? values[$0] : nil }
            
            let dueDate = dueString.flatMap { parseDate($0) }
            
            let assignment = ParsedAssignment(
                id: UUID(),
                jobId: UUID(), // Will be tracked separately if needed
                courseId: file.courseId,
                title: title,
                dueDate: dueDate,
                dueTime: nil,
                inferredType: type,
                inferredCategory: type,
                provenanceAnchor: "CSV row \(index + 2)",
                rawText: line,
                createdAt: Date(),
                isImported: false,
                importedTaskId: nil
            )
            
            results.append(assignment)
        }
        
        debugLog("📊 CSVParse: \(results.count) assignments from \(file.displayName)")
        return results
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        
        return result.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    }
    
    private func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        
        let formatters: [DateFormatter] = [
            // ISO formats
            makeDateFormatter("yyyy-MM-dd"),
            makeDateFormatter("yyyy/MM/dd"),
            
            // US formats
            makeDateFormatter("MM/dd/yyyy"),
            makeDateFormatter("MM-dd-yyyy"),
            
            // European formats
            makeDateFormatter("dd/MM/yyyy"),
            makeDateFormatter("dd-MM-yyyy"),
            
            // Month names
            makeDateFormatter("MMM d, yyyy"),  // Jan 15, 2026
            makeDateFormatter("MMMM d, yyyy"), // January 15, 2026
            makeDateFormatter("d MMM yyyy"),   // 15 Jan 2026
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        
        return nil
    }
    
    private func makeDateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    // MARK: - Auto-Scheduling
    
    private func autoSchedule(_ assignments: [ParsedAssignment], from file: CourseFile) async throws {
        let store = AssignmentsStore.shared
        var createdCount = 0
        var skippedCount = 0
        
        for parsed in assignments {
            // Generate unique key for deduplication
            let uniqueKey = generateUniqueKey(for: parsed)
            
            // Check if already exists
            let existingTask = store.tasks.first { task in
                let taskKey = generateUniqueKeyForTask(task)
                return taskKey == uniqueKey
            }
            
            if existingTask != nil {
                skippedCount += 1
                debugLog("⏭️ Skip duplicate: \(parsed.title)")
                continue
            }
            
            // Map type
            let taskType = mapTypeToTaskType(parsed.inferredType)
            
            // Estimate time based on type
            let estimatedMinutes = estimateTimeForType(taskType)
            
            // Create task
            let task = AppTask(
                id: UUID(),
                title: parsed.title,
                courseId: parsed.courseId,
                due: parsed.dueDate,
                estimatedMinutes: estimatedMinutes,
                minBlockMinutes: 20,
                maxBlockMinutes: 120,
                difficulty: 0.5,
                importance: 0.7,
                type: taskType,
                locked: false,
                attachments: [],
                isCompleted: false,
                gradeWeightPercent: nil,
                gradePossiblePoints: nil,
                gradeEarnedPoints: nil,
                category: taskType,
                dueTimeMinutes: nil,
                recurrence: nil,
                recurrenceSeriesID: nil,
                recurrenceIndex: nil,
                calendarEventIdentifier: nil
            )
            
            store.addTask(task)
            createdCount += 1
            debugLog("➕ Created: \(parsed.title) (\(taskType.rawValue))")
        }
        
        debugLog("✅ AutoSchedule complete: \(createdCount) created, \(skippedCount) skipped")
    }
    
    private func generateUniqueKey(for assignment: ParsedAssignment) -> String {
        let normalizedTitle = assignment.title.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        let dateString = assignment.dueDate.map { "\($0.timeIntervalSince1970)" } ?? "nodate"
        let typeString = assignment.inferredType?.lowercased() ?? "unknown"
        
        return "\(assignment.courseId)-\(normalizedTitle)-\(dateString)-\(typeString)"
    }
    
    private func generateUniqueKeyForTask(_ task: AppTask) -> String {
        let normalizedTitle = task.title.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        let dateString = task.due.map { "\($0.timeIntervalSince1970)" } ?? "nodate"
        let typeString = task.type.rawValue.lowercased()
        let courseString = task.courseId.map { "\($0)" } ?? "nocourse"
        
        return "\(courseString)-\(normalizedTitle)-\(dateString)-\(typeString)"
    }
    
    private func mapTypeToTaskType(_ typeString: String?) -> TaskType {
        guard let type = typeString?.lowercased() else { return .homework }
        
        if type.contains("exam") || type.contains("test") || type.contains("midterm") || type.contains("final") {
            return .exam
        } else if type.contains("quiz") {
            return .quiz
        } else if type.contains("project") || type.contains("paper") || type.contains("essay") || type.contains("lab") {
            return .project
        } else if type.contains("reading") {
            return .reading
        } else if type.contains("review") {
            return .review
        } else {
            return .homework
        }
    }
    
    private func estimateTimeForType(_ type: TaskType) -> Int {
        switch type {
        case .exam: return 180 // 3 hours study
        case .quiz: return 60  // 1 hour
        case .project: return 300 // 5 hours
        case .homework: return 90 // 1.5 hours
        case .reading: return 45  // 45 min
        case .review: return 60   // 1 hour
        }
    }
    
    // MARK: - File Loading
    
    private func loadFileData(for file: CourseFile) -> Data? {
        // Attempt to load from URL
        guard let url = file.url else {
            debugLog("⚠️ No URL for file: \(file.displayName)")
            return nil
        }
        
        do {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            let data = try Data(contentsOf: url)
            return data
        } catch {
            debugLog("❌ Failed to load file data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Debug Logging
    
    private func debugLog(_ message: String) {
        #if DEBUG
        print("[FileParsingService] \(message)")
        #endif
    }
}

// MARK: - Errors

enum ParsingError: LocalizedError {
    case fileNotFound
    case invalidEncoding
    case emptyFile
    case missingRequiredColumn(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found or inaccessible"
        case .invalidEncoding:
            return "Unable to read file (invalid encoding)"
        case .emptyFile:
            return "File is empty"
        case .missingRequiredColumn(let column):
            return "Missing required column: \(column)"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let courseFileUpdated = Notification.Name("courseFileUpdated")
}
