import Foundation
import Combine

// MARK: - Local Model Type

/// Types of local models available
public enum LocalModelType: String, Codable {
    case macOSStandard
    case iOSLite
    
    public var displayName: String {
        switch self {
        case .macOSStandard:
            return "macOS Standard Model"
        case .iOSLite:
            return "iOS Lite Model"
        }
    }
    
    public var estimatedSize: String {
        switch self {
        case .macOSStandard:
            return "800 MB"
        case .iOSLite:
            return "150 MB"
        }
    }
    
    public var estimatedSizeBytes: Int64 {
        switch self {
        case .macOSStandard:
            return 800 * 1024 * 1024  // 800 MB
        case .iOSLite:
            return 150 * 1024 * 1024  // 150 MB
        }
    }
}

// MARK: - Local Model Manager

/// Manages downloading and storage of local AI models
@MainActor
public final class LocalModelManager: ObservableObject {
    public static let shared = LocalModelManager()
    
    @Published public var downloadProgress: [LocalModelType: Double] = [:]
    @Published public var downloadedModels: Set<LocalModelType> = []
    
    private var downloadTasks: [LocalModelType: Task<Void, Error>] = [:]
    
    private init() {
        // Check which models are already downloaded
        checkDownloadedModels()
    }
    
    /// Check if a model is downloaded
    public func isModelDownloaded(_ type: LocalModelType) -> Bool {
        return downloadedModels.contains(type)
    }
    
    /// Check if a model is currently downloading
    public func isDownloading(_ type: LocalModelType) -> Bool {
        return downloadProgress[type] != nil
    }
    
    /// Get download progress for a model
    public func downloadProgress(_ type: LocalModelType) -> Double {
        return downloadProgress[type] ?? 0.0
    }
    
    /// Download a model
    public func downloadModel(_ type: LocalModelType) async throws {
        // Don't download if already downloaded
        guard !isModelDownloaded(type) else { return }
        
        // Don't download if already downloading
        guard !isDownloading(type) else { return }
        
        downloadProgress[type] = 0.0
        
        do {
            let sourceURL = modelURL(for: type)
            let destinationURL = localPath(for: type)
            
            // Create download task with progress tracking
            let downloadTask = Task {
                try await downloadWithProgress(
                    from: sourceURL,
                    to: destinationURL,
                    modelType: type
                )
            }
            
            downloadTasks[type] = downloadTask
            
            try await downloadTask.value
            
            // Verify download
            try await verifyModel(at: destinationURL, type: type)
            
            downloadedModels.insert(type)
            downloadProgress[type] = nil
            downloadTasks.removeValue(forKey: type)
            
            LOG_AI(.info, "LocalModelManager", "Model downloaded successfully", metadata: [
                "type": type.rawValue,
                "size": "\(type.estimatedSize)"
            ])
            
        } catch {
            downloadProgress[type] = nil
            downloadTasks.removeValue(forKey: type)
            
            LOG_AI(.error, "LocalModelManager", "Download failed", metadata: [
                "type": type.rawValue,
                "error": error.localizedDescription
            ])
            
            throw error
        }
    }
    
    /// Download file with progress tracking
    private func downloadWithProgress(
        from sourceURL: URL,
        to destinationURL: URL,
        modelType: LocalModelType
    ) async throws {
        // Create URL session with configuration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300  // 5 minutes
        configuration.timeoutIntervalForResource = 3600  // 1 hour
        
        let session = URLSession(configuration: configuration)
        
        // Create download task
        let (asyncBytes, response) = try await session.bytes(from: sourceURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.generationFailed("Failed to download model: Invalid response")
        }
        
        let expectedLength = httpResponse.expectedContentLength
        var downloadedLength: Int64 = 0
        
        // Create destination file
        guard let fileHandle = FileHandle(forWritingAtPath: destinationURL.path) ??
                (try? FileHandle(forWritingTo: destinationURL)) else {
            // Create file if it doesn't exist
            FileManager.default.createFile(atPath: destinationURL.path, contents: nil)
            guard let handle = try? FileHandle(forWritingTo: destinationURL) else {
                throw AIError.generationFailed("Failed to create destination file")
            }
            try await writeBytes(asyncBytes, to: handle, expectedLength: expectedLength, modelType: modelType)
            try handle.close()
            return
        }
        
        try await writeBytes(asyncBytes, to: fileHandle, expectedLength: expectedLength, modelType: modelType)
        try fileHandle.close()
    }
    
    /// Write bytes to file with progress updates
    private func writeBytes(
        _ asyncBytes: URLSession.AsyncBytes,
        to fileHandle: FileHandle,
        expectedLength: Int64,
        modelType: LocalModelType
    ) async throws {
        var downloadedLength: Int64 = 0
        
        for try await byte in asyncBytes {
            let data = Data([byte])
            try fileHandle.write(contentsOf: data)
            downloadedLength += 1
            
            // Update progress every 1MB
            if downloadedLength % (1024 * 1024) == 0 && expectedLength > 0 {
                await MainActor.run {
                    let progress = Double(downloadedLength) / Double(expectedLength)
                    downloadProgress[modelType] = min(progress, 1.0)
                }
            }
        }
        
        // Final progress update
        await MainActor.run {
            downloadProgress[modelType] = 1.0
        }
    }
    
    /// Verify downloaded model integrity
    private func verifyModel(at url: URL, type: LocalModelType) async throws {
        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AIError.modelNotDownloaded
        }
        
        // Check file size is reasonable
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let size = attributes[.size] as? Int64 else {
            throw AIError.generationFailed("Failed to verify model size")
        }
        
        // Verify size is within expected range (±10%)
        let expectedSize = type.estimatedSizeBytes
        let minSize = Int64(Double(expectedSize) * 0.9)
        let maxSize = Int64(Double(expectedSize) * 1.1)
        
        guard size >= minSize && size <= maxSize else {
            // Delete invalid file
            try? FileManager.default.removeItem(at: url)
            throw AIError.generationFailed("Model file size mismatch: expected ~\(type.estimatedSize), got \(size / 1024 / 1024)MB")
        }
        
        // TODO: Add checksum verification when we have actual model files
        // For now, size check is sufficient
        
        LOG_AI(.info, "LocalModelManager", "Model verified", metadata: [
            "type": type.rawValue,
            "size": "\(size / 1024 / 1024)MB"
        ])
    }
    
    /// Cancel download
    public func cancelDownload(_ type: LocalModelType) {
        LOG_AI(.info, "LocalModelManager", "Cancelling download", metadata: ["type": type.rawValue])
        
        downloadTasks[type]?.cancel()
        downloadTasks.removeValue(forKey: type)
        downloadProgress.removeValue(forKey: type)
        
        // Clean up partial file
        let partialPath = localPath(for: type)
        if FileManager.default.fileExists(atPath: partialPath.path) {
            // Check if file is complete
            if !downloadedModels.contains(type) {
                try? FileManager.default.removeItem(at: partialPath)
            }
        }
    }
    
    /// Delete a model
    public func deleteModel(_ type: LocalModelType) throws {
        let path = localPath(for: type)
        
        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        }
        
        downloadedModels.remove(type)
    }
    
    /// Get model URL for loading
    public func getModelURL(_ type: LocalModelType) throws -> URL {
        let path = localPath(for: type)
        
        guard FileManager.default.fileExists(atPath: path.path) else {
            throw AIError.modelNotDownloaded
        }
        
        return path
    }
    
    /// Get download URL for a model
    private func modelURL(for type: LocalModelType) -> URL {
        #if DEBUG
        if ModelConfig.useTestingURLs {
            return ModelConfig.testingURL(for: type)
        }
        #endif
        return ModelConfig.url(for: type)
    }
    
    /// Get local storage path for a model
    private func localPath(for type: LocalModelType) -> URL {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        
        let modelDir = directory.appendingPathComponent("Models")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: modelDir,
            withIntermediateDirectories: true
        )
        
        let filename = type == .macOSStandard ? "macos-standard.mlmodel" : "ios-lite.mlmodel"
        return modelDir.appendingPathComponent(filename)
    }
    
    /// Check which models are already downloaded
    private func checkDownloadedModels() {
        for type in [LocalModelType.macOSStandard, .iOSLite] {
            let path = localPath(for: type)
            if FileManager.default.fileExists(atPath: path.path) {
                downloadedModels.insert(type)
            }
        }
    }
    
    /// Get total size of downloaded models
    public func totalDownloadedSize() -> Int64 {
        var total: Int64 = 0
        
        for type in downloadedModels {
            let path = localPath(for: type)
            if let attributes = try? FileManager.default.attributesOfItem(atPath: path.path),
               let size = attributes[.size] as? Int64 {
                total += size
            }
        }
        
        return total
    }
}
