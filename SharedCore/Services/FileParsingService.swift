import Foundation
import Combine
import CryptoKit

@MainActor
final class FileParsingService: ObservableObject {
    static let shared = FileParsingService()
    
    @Published private(set) var activeParseJobs: Set<UUID> = []
    
    private var parseQueue: [UUID: CourseFile] = [:]
    private var throttleTimers: [UUID: Timer] = [:]
    
    private init() {}
    
    func queueFileForParsing(_ file: CourseFile) {
        var updatedFile = file
        updatedFile.parseStatus = .queued
        NotificationCenter.default.post(name: .courseFileUpdated, object: updatedFile)
    }
    
    func updateFileCategory(_ file: CourseFile, newCategory: FileCategory) async {
        var updatedFile = file
        updatedFile.category = newCategory
        updatedFile.isSyllabus = (newCategory == .syllabus)
        updatedFile.isPracticeExam = (newCategory == .practiceTest)
        NotificationCenter.default.post(name: .courseFileUpdated, object: updatedFile)
    }
    
    func calculateFingerprint(for file: CourseFile, fileData: Data? = nil) -> String {
        return UUID().uuidString
    }
}

extension Notification.Name {
    static let courseFileUpdated = Notification.Name("courseFileUpdated")
}
