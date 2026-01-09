import Combine
import Foundation

/// Manages file synchronization with iCloud Drive for course files
public final class CourseFileCloudSyncManager: ObservableObject {
    public static let shared = CourseFileCloudSyncManager()

    private let moduleRepository: CourseModuleRepository
    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()

    @Published public private(set) var syncStatus: SyncStatus = .idle
    @Published public private(set) var pendingSyncCount: Int = 0

    /// iCloud container directory for course files
    private lazy var cloudDirectory: URL? = fileManager.url(forUbiquityContainerIdentifier: nil)?
        .appendingPathComponent("Documents")
        .appendingPathComponent("CourseFiles")

    /// Local cache directory for offline access
    private lazy var localCacheDirectory: URL = {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CourseFiles")
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()

    public enum SyncStatus {
        case idle
        case syncing(progress: Double)
        case error(String)
    }

    private init(moduleRepository: CourseModuleRepository = CourseModuleRepository()) {
        self.moduleRepository = moduleRepository
        setupCloudDirectory()
        observeCloudAvailability()
    }

    // MARK: - Setup

    private func setupCloudDirectory() {
        guard let cloudDir = cloudDirectory else {
            print("⚠️ iCloud not available for file sync")
            return
        }

        // Create cloud directory if needed
        if !fileManager.fileExists(atPath: cloudDir.path) {
            do {
                try fileManager.createDirectory(at: cloudDir, withIntermediateDirectories: true)
                print("✅ Created iCloud directory for course files")
            } catch {
                print("❌ Failed to create iCloud directory: \(error)")
            }
        }
    }

    private func observeCloudAvailability() {
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] _ in
                self?.checkForUpdates()
            }
            .store(in: &cancellables)
    }

    // MARK: - File Upload

    /// Upload a file to iCloud and update database
    public func uploadFile(
        fileId: UUID,
        localURL: URL,
        courseId: UUID,
        nodeId: UUID? = nil
    ) async throws -> URL {
        guard let cloudDir = cloudDirectory else {
            throw SyncError.cloudNotAvailable
        }

        let fileName = localURL.lastPathComponent
        let cloudURL = cloudDir
            .appendingPathComponent(courseId.uuidString)
            .appendingPathComponent(nodeId?.uuidString ?? "root")
            .appendingPathComponent(fileName)

        // Create parent directories
        let parentDir = cloudURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        // Copy file to iCloud
        if fileManager.fileExists(atPath: cloudURL.path) {
            try fileManager.removeItem(at: cloudURL)
        }

        try fileManager.copyItem(at: localURL, to: cloudURL)

        // Update database with iCloud URL
        try await moduleRepository.updateFileSync(
            id: fileId,
            iCloudURL: cloudURL.path,
            syncStatus: "synced"
        )

        print("✅ Uploaded file to iCloud: \(fileName)")
        return cloudURL
    }

    // MARK: - File Download

    /// Download a file from iCloud to local cache
    public func downloadFile(
        fileId _: UUID,
        iCloudPath: String
    ) async throws -> URL {
        let cloudURL = URL(fileURLWithPath: iCloudPath)
        let fileName = cloudURL.lastPathComponent
        let localURL = localCacheDirectory.appendingPathComponent(fileName)

        // Check if already cached
        if fileManager.fileExists(atPath: localURL.path) {
            // Verify it's up-to-date
            if try isSameFile(localURL, cloudURL) {
                return localURL
            }
            try fileManager.removeItem(at: localURL)
        }

        // Start download
        guard fileManager.fileExists(atPath: cloudURL.path) else {
            throw SyncError.fileNotFound
        }

        try fileManager.copyItem(at: cloudURL, to: localURL)

        print("✅ Downloaded file from iCloud: \(fileName)")
        return localURL
    }

    // MARK: - Bulk Operations

    /// Sync all pending files
    public func syncPendingFiles() async {
        syncStatus = .syncing(progress: 0)

        // This would fetch files with syncStatus == "pending" and upload them
        // Implementation depends on your data flow

        syncStatus = .idle
    }

    /// Check for file updates from iCloud
    private func checkForUpdates() {
        Task {
            // Check for remote changes and update local database
            print("🔄 Checking for iCloud file updates...")
        }
    }

    // MARK: - File Management

    /// Delete file from both local and iCloud
    public func deleteFile(fileId: UUID, iCloudPath: String?) async throws {
        // Delete from iCloud
        if let iCloudPath {
            let cloudURL = URL(fileURLWithPath: iCloudPath)
            if fileManager.fileExists(atPath: cloudURL.path) {
                try fileManager.removeItem(at: cloudURL)
            }
        }

        // Delete from database
        try await moduleRepository.deleteFile(id: fileId)

        print("✅ Deleted file from iCloud and database")
    }

    /// Get local URL for file (download if needed)
    public func getFileURL(fileId: UUID, iCloudPath: String?) async throws -> URL {
        if let iCloudPath {
            return try await downloadFile(fileId: fileId, iCloudPath: iCloudPath)
        }
        throw SyncError.fileNotFound
    }

    // MARK: - Helpers

    private func isSameFile(_ url1: URL, _ url2: URL) throws -> Bool {
        let attrs1 = try fileManager.attributesOfItem(atPath: url1.path)
        let attrs2 = try fileManager.attributesOfItem(atPath: url2.path)

        let size1 = attrs1[.size] as? UInt64 ?? 0
        let size2 = attrs2[.size] as? UInt64 ?? 0

        let date1 = attrs1[.modificationDate] as? Date ?? Date.distantPast
        let date2 = attrs2[.modificationDate] as? Date ?? Date.distantPast

        return size1 == size2 && date1 == date2
    }

    // MARK: - Status

    public var isCloudAvailable: Bool {
        cloudDirectory != nil
    }

    public enum SyncError: LocalizedError {
        case cloudNotAvailable
        case fileNotFound
        case uploadFailed(String)
        case downloadFailed(String)

        public var errorDescription: String? {
            switch self {
            case .cloudNotAvailable:
                "iCloud is not available"
            case .fileNotFound:
                "File not found"
            case let .uploadFailed(msg):
                "Upload failed: \(msg)"
            case let .downloadFailed(msg):
                "Download failed: \(msg)"
            }
        }
    }
}
