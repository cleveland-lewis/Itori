import Combine
import Foundation

#if canImport(UIKit)
    import UIKit
#endif

/// Manages iCloud sync for course files with offline support
@MainActor
final class CourseFileSyncManager: ObservableObject {
    static let shared = CourseFileSyncManager()

    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var pendingUploads: Int = 0
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: String?

    private let fileManager = FileManager.default
    private var iCloudAvailable: Bool {
        fileManager.ubiquityIdentityToken != nil
    }

    // Local storage URLs
    private var localDocumentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var localFilesURL: URL {
        localDocumentsURL.appendingPathComponent("CourseFiles", isDirectory: true)
    }

    private var pendingUploadsURL: URL {
        localDocumentsURL.appendingPathComponent("PendingUploads", isDirectory: true)
    }

    // iCloud URLs
    private var iCloudContainerURL: URL? {
        fileManager.url(forUbiquityContainerIdentifier: "iCloud.com.cwlewisiii.Itori")
    }

    private var iCloudFilesURL: URL? {
        iCloudContainerURL?.appendingPathComponent("Documents/CourseFiles", isDirectory: true)
    }

    private var metadataQuery: NSMetadataQuery?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupDirectories()
        setupiCloudMonitoring()
        checkPendingUploads()
    }

    // MARK: - Setup

    private func setupDirectories() {
        // Create local directories
        try? fileManager.createDirectory(at: localFilesURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: pendingUploadsURL, withIntermediateDirectories: true)

        // Create iCloud directories if available
        if let iCloudURL = iCloudFilesURL {
            try? fileManager.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
        }
    }

    private func setupiCloudMonitoring() {
        // Monitor iCloud availability changes
        NotificationCenter.default.publisher(for: NSNotification.Name.NSUbiquityIdentityDidChange)
            .sink { [weak self] _ in
                self?.handleiCloudAvailabilityChange()
            }
            .store(in: &cancellables)

        // Setup metadata query for iCloud file changes
        guard iCloudAvailable else { return }

        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "%K LIKE %@", NSMetadataItemPathKey, "*CourseFiles*")
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidFinishGathering),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidUpdate),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )

        query.start()
        metadataQuery = query
    }

    @objc private func metadataQueryDidFinishGathering(_: Notification) {
        LOG_ICLOUD(.info, "FileSyncManager", "Metadata query finished gathering")
        processiCloudChanges()
    }

    @objc private func metadataQueryDidUpdate(_: Notification) {
        LOG_ICLOUD(.debug, "FileSyncManager", "Metadata query updated")
        processiCloudChanges()
    }

    private func processiCloudChanges() {
        guard let query = metadataQuery else { return }

        query.disableUpdates()
        defer { query.enableUpdates() }

        // Check for conflicts or download status changes
        for item in query.results {
            guard let metadataItem = item as? NSMetadataItem else { continue }

            // Check download status
            if let downloadStatus = metadataItem
                .value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
            {
                if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusCurrent {
                    LOG_ICLOUD(
                        .debug,
                        "FileSyncManager",
                        "File downloaded: \(metadataItem.value(forAttribute: NSMetadataItemDisplayNameKey) ?? "unknown")"
                    )
                }
            }

            // Check for conflicts
            if let hasConflict = metadataItem
                .value(forAttribute: NSMetadataUbiquitousItemHasUnresolvedConflictsKey) as? Bool,
                hasConflict
            {
                if let url = metadataItem.value(forAttribute: NSMetadataItemURLKey) as? URL {
                    resolveConflict(at: url)
                }
            }
        }
    }

    // MARK: - File Operations

    /// Save a file and sync to iCloud if available
    func saveFile(_ fileData: Data, filename: String, courseId: UUID) async throws -> CourseFile {
        let fileId = UUID()
        let sanitizedFilename = sanitizeFilename(filename)
        let fileType = (sanitizedFilename as NSString).pathExtension

        // Save locally first (always works, even offline)
        let localFileURL = localFilesURL
            .appendingPathComponent(courseId.uuidString, isDirectory: true)
            .appendingPathComponent(fileId.uuidString, isDirectory: false)
            .appendingPathExtension(fileType.isEmpty ? "file" : fileType)

        try fileManager.createDirectory(at: localFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileData.write(to: localFileURL)

        LOG_ICLOUD(.info, "FileSyncManager", "File saved locally: \(sanitizedFilename)")

        // Create CourseFile metadata
        let courseFile = CourseFile(
            id: fileId,
            courseId: courseId,
            nodeId: nil,
            filename: sanitizedFilename,
            fileType: fileType,
            localURL: localFileURL.path,
            isSyllabus: false,
            isPracticeExam: false
        )

        // Attempt iCloud sync if available
        if iCloudAvailable {
            try await synciCloudFile(localURL: localFileURL, courseFile: courseFile)
        } else {
            // Queue for later upload
            try queuePendingUpload(courseFile: courseFile, localURL: localFileURL)
        }

        return courseFile
    }

    /// Sync a local file to iCloud
    private func synciCloudFile(localURL: URL, courseFile: CourseFile) async throws {
        guard let iCloudURL = iCloudFilesURL else {
            throw FileSyncError.iCloudUnavailable
        }

        let targetURL = iCloudURL
            .appendingPathComponent(courseFile.courseId.uuidString, isDirectory: true)
            .appendingPathComponent(courseFile.id.uuidString, isDirectory: false)
            .appendingPathExtension(courseFile.fileType.isEmpty ? "file" : courseFile.fileType)

        try fileManager.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        // Check if file already exists in iCloud
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }

        // Copy to iCloud
        try fileManager.copyItem(at: localURL, to: targetURL)

        // Mark for iCloud upload
        try (targetURL as NSURL).setResourceValue(true, forKey: .isExcludedFromBackupKey)

        LOG_ICLOUD(.info, "FileSyncManager", "File synced to iCloud: \(courseFile.filename)")

        lastSyncDate = Date()
    }

    /// Queue a file for upload when iCloud becomes available
    private func queuePendingUpload(courseFile: CourseFile, localURL: URL) throws {
        let metadata = PendingUploadMetadata(
            courseFile: courseFile,
            localPath: localURL.path,
            queuedAt: Date()
        )

        let metadataURL = pendingUploadsURL
            .appendingPathComponent(courseFile.id.uuidString)
            .appendingPathExtension("json")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)
        try data.write(to: metadataURL)

        updatePendingUploadsCount()

        LOG_ICLOUD(.info, "FileSyncManager", "File queued for upload: \(courseFile.filename)")
    }

    /// Get a file's data (checks iCloud first, then local)
    func getFileData(for courseFile: CourseFile) async throws -> Data {
        // Try iCloud first if available
        if iCloudAvailable, let iCloudURL = iCloudFilesURL {
            let iCloudFileURL = iCloudURL
                .appendingPathComponent(courseFile.courseId.uuidString, isDirectory: true)
                .appendingPathComponent(courseFile.id.uuidString, isDirectory: false)
                .appendingPathExtension(courseFile.fileType.isEmpty ? "file" : courseFile.fileType)

            if fileManager.fileExists(atPath: iCloudFileURL.path) {
                // Start download if not current
                try await downloadiCloudFileIfNeeded(url: iCloudFileURL)
                return try Data(contentsOf: iCloudFileURL)
            }
        }

        // Fallback to local
        if let localPath = courseFile.localURL, let localURL = URL(string: localPath) {
            if fileManager.fileExists(atPath: localURL.path) {
                return try Data(contentsOf: localURL)
            }
        }

        throw FileSyncError.fileNotFound
    }

    /// Download iCloud file if not current
    private func downloadiCloudFileIfNeeded(url: URL) async throws {
        var isDownloaded = false
        var downloadError: Error?

        do {
            try fileManager.startDownloadingUbiquitousItem(at: url)
        } catch {
            downloadError = error
        }

        // Wait for download with timeout
        let timeout = Date().addingTimeInterval(30)
        while !isDownloaded && Date() < timeout {
            if let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]),
               let status = values.ubiquitousItemDownloadingStatus,
               status == .current
            {
                isDownloaded = true
                break
            }
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        if let error = downloadError {
            throw error
        }

        if !isDownloaded {
            throw FileSyncError.downloadTimeout
        }
    }

    /// Delete a file (from both local and iCloud)
    func deleteFile(_ courseFile: CourseFile) async throws {
        // Delete from local
        if let localPath = courseFile.localURL, let localURL = URL(string: localPath) {
            if fileManager.fileExists(atPath: localURL.path) {
                try fileManager.removeItem(at: localURL)
                LOG_ICLOUD(.info, "FileSyncManager", "File deleted locally: \(courseFile.filename)")
            }
        }

        // Delete from iCloud
        if iCloudAvailable, let iCloudURL = iCloudFilesURL {
            let iCloudFileURL = iCloudURL
                .appendingPathComponent(courseFile.courseId.uuidString, isDirectory: true)
                .appendingPathComponent(courseFile.id.uuidString, isDirectory: false)
                .appendingPathExtension(courseFile.fileType.isEmpty ? "file" : courseFile.fileType)

            if fileManager.fileExists(atPath: iCloudFileURL.path) {
                try fileManager.removeItem(at: iCloudFileURL)
                LOG_ICLOUD(.info, "FileSyncManager", "File deleted from iCloud: \(courseFile.filename)")
            }
        }

        // Remove from pending uploads if exists
        let pendingMetadataURL = pendingUploadsURL
            .appendingPathComponent(courseFile.id.uuidString)
            .appendingPathExtension("json")

        if fileManager.fileExists(atPath: pendingMetadataURL.path) {
            try fileManager.removeItem(at: pendingMetadataURL)
            updatePendingUploadsCount()
        }
    }

    // MARK: - Pending Uploads

    private func checkPendingUploads() {
        updatePendingUploadsCount()

        // Auto-upload if iCloud available
        if iCloudAvailable {
            Task {
                await uploadPendingFiles()
            }
        }
    }

    private func updatePendingUploadsCount() {
        do {
            let files = try fileManager.contentsOfDirectory(at: pendingUploadsURL, includingPropertiesForKeys: nil)
            pendingUploads = files.filter { $0.pathExtension == "json" }.count
        } catch {
            pendingUploads = 0
        }
    }

    /// Upload all pending files to iCloud
    func uploadPendingFiles() async {
        guard iCloudAvailable else {
            LOG_ICLOUD(.info, "FileSyncManager", "iCloud unavailable, cannot upload pending files")
            return
        }

        guard pendingUploads > 0 else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let metadataFiles = try fileManager.contentsOfDirectory(
                at: pendingUploadsURL,
                includingPropertiesForKeys: nil
            )
            .filter { $0.pathExtension == "json" }

            LOG_ICLOUD(.info, "FileSyncManager", "Uploading \(metadataFiles.count) pending files")

            for metadataURL in metadataFiles {
                do {
                    let data = try Data(contentsOf: metadataURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let metadata = try decoder.decode(PendingUploadMetadata.self, from: data)

                    guard let localURL = URL(string: metadata.localPath) else { continue }
                    guard fileManager.fileExists(atPath: localURL.path) else {
                        // Local file gone, remove metadata
                        try? fileManager.removeItem(at: metadataURL)
                        continue
                    }

                    try await synciCloudFile(localURL: localURL, courseFile: metadata.courseFile)

                    // Remove metadata after successful upload
                    try fileManager.removeItem(at: metadataURL)

                    LOG_ICLOUD(.info, "FileSyncManager", "Uploaded pending file: \(metadata.courseFile.filename)")
                } catch {
                    LOG_ICLOUD(
                        .error,
                        "FileSyncManager",
                        "Failed to upload pending file: \(error.localizedDescription)"
                    )
                }
            }

            updatePendingUploadsCount()
            syncError = nil

        } catch {
            syncError = error.localizedDescription
            LOG_ICLOUD(.error, "FileSyncManager", "Failed to process pending uploads: \(error.localizedDescription)")
        }
    }

    // MARK: - Conflict Resolution

    private func resolveConflict(at url: URL) {
        do {
            guard let conflicts = NSFileVersion.unresolvedConflictVersionsOfItem(at: url) else { return }

            LOG_ICLOUD(.warn, "FileSyncManager", "Resolving conflict for: \(url.lastPathComponent)")

            // Keep current version (most recent)
            let currentVersion = NSFileVersion.currentVersionOfItem(at: url)

            // Remove conflicting versions
            for conflict in conflicts {
                conflict.isResolved = true
                try conflict.remove()
            }

            // Save current version
            try currentVersion?.replaceItem(at: url)

            LOG_ICLOUD(.info, "FileSyncManager", "Conflict resolved: kept current version")

        } catch {
            LOG_ICLOUD(.error, "FileSyncManager", "Failed to resolve conflict: \(error.localizedDescription)")
        }
    }

    // MARK: - iCloud Availability

    private func handleiCloudAvailabilityChange() {
        LOG_ICLOUD(.info, "FileSyncManager", "iCloud availability changed: \(iCloudAvailable)")

        if iCloudAvailable {
            // iCloud became available, upload pending files
            Task {
                await uploadPendingFiles()
            }
        }
    }

    // MARK: - Utilities

    private func sanitizeFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
    }
}

// MARK: - Models

private struct PendingUploadMetadata: Codable {
    let courseFile: CourseFile
    let localPath: String
    let queuedAt: Date
}

// MARK: - Errors

enum FileSyncError: LocalizedError {
    case iCloudUnavailable
    case fileNotFound
    case downloadTimeout
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            "iCloud is not available"
        case .fileNotFound:
            "File not found"
        case .downloadTimeout:
            "Download timed out"
        case .uploadFailed:
            "Upload failed"
        }
    }
}

// MARK: - Logging

private func LOG_ICLOUD(_ level: LogLevel, _ category: String, _ message: String, metadata: [String: String] = [:]) {
    #if DEBUG
        let prefix = "📁"
        print("[\(level.emoji) \(prefix)] [\(category)] \(message)")
        if !metadata.isEmpty {
            print("  Metadata: \(metadata)")
        }
    #endif
}

private enum LogLevel {
    case debug, info, warn, error

    var emoji: String {
        switch self {
        case .debug: "🔍"
        case .info: "ℹ️"
        case .warn: "⚠️"
        case .error: "❌"
        }
    }
}
