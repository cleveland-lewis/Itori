import Foundation

#if canImport(PDFKit)
    import PDFKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

#if canImport(UniformTypeIdentifiers)
    import UniformTypeIdentifiers
#endif

// MARK: - Document Ingest Port

/// Port for normalizing various file formats into structured text + metadata
protocol DocumentIngestPort {
    func ingest(_ fileURL: URL) async throws -> DocumentIngestResult
}

// MARK: - Models

struct DocumentIngestResult {
    let plainText: String
    let metadata: DocumentMetadata
    let sourceFile: URL
}

struct DocumentMetadata {
    let fileType: DocumentFileType
    let pageCount: Int?
    let creationDate: Date?
    let title: String?
    let author: String?
}

enum DocumentFileType: String, CaseIterable {
    case pdf
    case docx
    case txt
    case markdown
    case html
    case rtf

    var supportedExtensions: [String] {
        switch self {
        case .pdf: ["pdf"]
        case .docx: ["docx", "doc"]
        case .txt: ["txt"]
        case .markdown: ["md", "markdown"]
        case .html: ["html", "htm"]
        case .rtf: ["rtf"]
        }
    }

    static func from(fileExtension: String) -> DocumentFileType? {
        allCases.first { $0.supportedExtensions.contains(fileExtension.lowercased()) }
    }
}

enum DocumentIngestError: Error, LocalizedError {
    case unsupportedFileType(String)
    case fileNotReadable
    case extractionFailed(String)
    case emptyContent

    var errorDescription: String? {
        switch self {
        case let .unsupportedFileType(ext):
            "Unsupported file type: .\(ext)"
        case .fileNotReadable:
            "Could not read file"
        case let .extractionFailed(reason):
            "Text extraction failed: \(reason)"
        case .emptyContent:
            "File contains no readable text"
        }
    }
}

// MARK: - Document Ingest Service

@MainActor
class DocumentIngestService: DocumentIngestPort {
    func ingest(_ fileURL: URL) async throws -> DocumentIngestResult {
        guard fileURL.isFileURL else {
            throw DocumentIngestError.fileNotReadable
        }

        let fileExtension = fileURL.pathExtension
        guard let fileType = DocumentFileType.from(fileExtension: fileExtension) else {
            throw DocumentIngestError.unsupportedFileType(fileExtension)
        }

        let plainText: String
        let metadata: DocumentMetadata

        switch fileType {
        case .pdf:
            (plainText, metadata) = try await extractPDF(from: fileURL)
        case .docx:
            (plainText, metadata) = try await extractDOCX(from: fileURL)
        case .txt, .markdown:
            (plainText, metadata) = try await extractPlainText(from: fileURL, fileType: fileType)
        case .html:
            (plainText, metadata) = try await extractHTML(from: fileURL)
        case .rtf:
            (plainText, metadata) = try await extractRTF(from: fileURL)
        }

        guard !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DocumentIngestError.emptyContent
        }

        return DocumentIngestResult(
            plainText: plainText,
            metadata: metadata,
            sourceFile: fileURL
        )
    }

    // MARK: - PDF Extraction

    private func extractPDF(from url: URL) async throws -> (String, DocumentMetadata) {
        #if canImport(PDFKit)
            guard let document = PDFDocument(url: url) else {
                throw DocumentIngestError.extractionFailed("Could not open PDF")
            }

            var fullText = ""
            let pageCount = document.pageCount

            for pageIndex in 0 ..< pageCount {
                guard let page = document.page(at: pageIndex),
                      let pageText = page.string
                else {
                    continue
                }
                fullText += pageText + "\n\n"
            }

            let metadata = DocumentMetadata(
                fileType: .pdf,
                pageCount: pageCount,
                creationDate: document.documentAttributes?[PDFDocumentAttribute.creationDateAttribute] as? Date,
                title: document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String,
                author: document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
            )

            return (fullText, metadata)
        #else
            throw DocumentIngestError.extractionFailed("PDFKit not available on this platform")
        #endif
    }

    // MARK: - DOCX Extraction

    private func extractDOCX(from url: URL) async throws -> (String, DocumentMetadata) {
        // DOCX is a ZIP archive containing XML files
        // For now, we'll use a simplified approach
        // In production, you'd want a proper DOCX parser

        guard let data = try? Data(contentsOf: url) else {
            throw DocumentIngestError.fileNotReadable
        }

        // Try to extract text using RTF fallback or plain text
        let text = String(data: data, encoding: .utf8) ?? ""

        let metadata = DocumentMetadata(
            fileType: .docx,
            pageCount: nil,
            creationDate: try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
            title: url.deletingPathExtension().lastPathComponent,
            author: nil
        )

        return (text, metadata)
    }

    // MARK: - Plain Text Extraction

    private func extractPlainText(
        from url: URL,
        fileType: DocumentFileType
    ) async throws -> (String, DocumentMetadata) {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw DocumentIngestError.fileNotReadable
        }

        let metadata = DocumentMetadata(
            fileType: fileType,
            pageCount: nil,
            creationDate: try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
            title: url.deletingPathExtension().lastPathComponent,
            author: nil
        )

        return (text, metadata)
    }

    // MARK: - HTML Extraction

    private func extractHTML(from url: URL) async throws -> (String, DocumentMetadata) {
        guard let htmlString = try? String(contentsOf: url, encoding: .utf8) else {
            throw DocumentIngestError.fileNotReadable
        }

        // Basic HTML tag stripping
        let plainText = htmlString
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")

        let metadata = DocumentMetadata(
            fileType: .html,
            pageCount: nil,
            creationDate: try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
            title: url.deletingPathExtension().lastPathComponent,
            author: nil
        )

        return (plainText, metadata)
    }

    // MARK: - RTF Extraction

    private func extractRTF(from url: URL) async throws -> (String, DocumentMetadata) {
        #if canImport(AppKit)
            guard let attributedString = try NSAttributedString(rtf: Data(contentsOf: url), documentAttributes: nil)
            else {
                throw DocumentIngestError.extractionFailed("Could not parse RTF")
            }

            let metadata = DocumentMetadata(
                fileType: .rtf,
                pageCount: nil,
                creationDate: try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
                title: url.deletingPathExtension().lastPathComponent,
                author: nil
            )

            return (attributedString.string, metadata)
        #else
            // Fallback for iOS - try basic text extraction
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                throw DocumentIngestError.fileNotReadable
            }

            let metadata = DocumentMetadata(
                fileType: .rtf,
                pageCount: nil,
                creationDate: try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
                title: url.deletingPathExtension().lastPathComponent,
                author: nil
            )

            return (text, metadata)
        #endif
    }
}
