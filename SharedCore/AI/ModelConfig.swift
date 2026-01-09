import Foundation

/// Model Configuration
/// Centralized configuration for model URLs and metadata
enum ModelConfig {
    // MARK: - Model URLs

    /// Base CDN URL for model hosting
    /// Deferred: CDN domain configuration
    static let baseCDNURL = "https://models.itori.app"

    /// Model endpoints
    static let models: [LocalModelType: ModelMetadata] = [
        .macOSStandard: ModelMetadata(
            filename: "itori-macos-standard-v1.mlmodel",
            version: "1.0.0",
            size: 838_860_800, // 800 MB
            checksum: nil // Deferred: SHA256 checksums
        ),
        .iOSLite: ModelMetadata(
            filename: "itori-ios-lite-v1.mlmodel",
            version: "1.0.0",
            size: 157_286_400, // 150 MB
            checksum: nil // Deferred: SHA256 checksums
        )
    ]

    // MARK: - Model Metadata

    struct ModelMetadata {
        let filename: String
        let version: String
        let size: Int64
        let checksum: String? // SHA256 hash for verification

        var url: URL {
            URL(string: "\(baseCDNURL)/\(filename)")!
        }
    }

    // MARK: - Helper Methods

    /// Get metadata for a model type
    static func metadata(for type: LocalModelType) -> ModelMetadata {
        guard let metadata = models[type] else {
            fatalError("No metadata configured for model type: \(type)")
        }
        return metadata
    }

    /// Get download URL for a model type
    static func url(for type: LocalModelType) -> URL {
        metadata(for: type).url
    }

    /// Get expected size for a model type
    static func expectedSize(for type: LocalModelType) -> Int64 {
        metadata(for: type).size
    }

    /// Get checksum for a model type (if available)
    static func checksum(for type: LocalModelType) -> String? {
        metadata(for: type).checksum
    }
}

// MARK: - Development/Testing URLs

#if DEBUG
    extension ModelConfig {
        /// Alternative URLs for testing (e.g., localhost, staging)
        static var useTestingURLs = false

        static let testingBaseCDN = "http://localhost:8000/models"

        static func testingURL(for type: LocalModelType) -> URL {
            let metadata = metadata(for: type)
            return URL(string: "\(testingBaseCDN)/\(metadata.filename)")!
        }
    }
#endif
