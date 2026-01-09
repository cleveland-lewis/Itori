import Foundation

#if os(macOS)
    #if os(macOS)
        import AppKit
    #endif
#endif

/// Manages file attachments - saving, deleting, and organizing files
class AttachmentManager {
    static let shared = AttachmentManager()

    private let fileManager = FileManager.default

    /// The directory where attachments are stored
    private var attachmentsDirectory: URL {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            LOG_UI(.error, "AttachmentManager", "CRITICAL: Could not find documents directory - using temp")
            // Fallback to temp directory
            return fileManager.temporaryDirectory.appendingPathComponent("ItoriAttachments", isDirectory: true)
        }
        return documentsURL.appendingPathComponent("Attachments", isDirectory: true)
    }

    private init() {
        createAttachmentsDirectoryIfNeeded()
    }

    /// Creates the attachments directory if it doesn't exist
    private func createAttachmentsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: attachmentsDirectory.path) {
            do {
                try fileManager.createDirectory(at: attachmentsDirectory, withIntermediateDirectories: true)
            } catch {
                DebugLogger.log("Error creating attachments directory: \(error)")
            }
        }
    }

    /// Saves a file from a source URL to the app's attachments directory
    /// - Parameter sourceURL: The URL of the file to save (e.g., from file picker)
    /// - Returns: The local URL where the file was saved, or nil if it failed
    /// - Throws: FileManager errors if the copy operation fails
    func saveFile(from sourceURL: URL) throws -> URL {
        // Start accessing security-scoped resource
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        // Generate a unique filename to avoid conflicts
        let fileName = sourceURL.lastPathComponent
        let fileExtension = sourceURL.pathExtension
        let baseName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")

        var destinationURL = attachmentsDirectory.appendingPathComponent(fileName)
        var counter = 1

        // If file exists, append a number
        while fileManager.fileExists(atPath: destinationURL.path) {
            let uniqueName = "\(baseName)_\(counter).\(fileExtension)"
            destinationURL = attachmentsDirectory.appendingPathComponent(uniqueName)
            counter += 1
        }

        // Copy the file
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        return destinationURL
    }

    /// Deletes an attachment file
    /// - Parameter attachment: The attachment to delete
    func deleteFile(for attachment: Attachment) {
        do {
            guard let url = attachment.localURL else { return }
            try fileManager.removeItem(at: url)
        } catch {
            DebugLogger.log("Error deleting attachment file: \(error)")
        }
    }

    /// Checks if the file exists at the given URL
    /// - Parameter url: The URL to check
    /// - Returns: True if the file exists, false otherwise
    func fileExists(at url: URL?) -> Bool {
        guard let url else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    /// Returns the size of the file in bytes
    /// - Parameter url: The URL of the file
    /// - Returns: The file size in bytes, or nil if it couldn't be determined
    func fileSize(at url: URL?) -> Int64? {
        guard let url, let attributes = try? fileManager.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }

    /// Opens the file with the default system application
    /// - Parameter attachment: The attachment to open
    func openFile(_ attachment: Attachment) {
        #if os(macOS)
            guard let url = attachment.localURL else { return }
            NSWorkspace.shared.open(url)
        #else
            // For iOS, you'd use a document interaction controller or QuickLook
            DebugLogger.log("Opening files is primarily supported on macOS")
        #endif
    }

    /// Reveals the file in Finder (macOS only)
    /// - Parameter attachment: The attachment to reveal
    func revealInFinder(_ attachment: Attachment) {
        #if os(macOS)
            guard let url = attachment.localURL else { return }
            NSWorkspace.shared.activateFileViewerSelecting([url])
        #endif
    }
}
