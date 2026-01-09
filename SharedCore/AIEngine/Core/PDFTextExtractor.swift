//
// PDFTextExtractor.swift
// Production-grade PDF extraction with structure preservation
//

import Foundation
import PDFKit

public struct ExtractedPDFText: Sendable {
    public let text: String
    public let pageCount: Int
    public let pageBreaks: [Int] // character indices where pages break
    public let metadata: [String: String]
    public let warnings: [String]

    public init(text: String, pageCount: Int, pageBreaks: [Int], metadata: [String: String], warnings: [String]) {
        self.text = text
        self.pageCount = pageCount
        self.pageBreaks = pageBreaks
        self.metadata = metadata
        self.warnings = warnings
    }
}

/// PDF text extractor with structure preservation
public struct PDFTextExtractor {
    public init() {}

    public func extract(from url: URL) throws -> ExtractedPDFText {
        guard let document = PDFDocument(url: url) else {
            throw PDFExtractionError.cannotOpenDocument
        }

        var fullText = ""
        var pageBreaks: [Int] = []
        var warnings: [String] = []
        var metadata: [String: String] = [:]

        // Extract metadata
        if let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String {
            metadata["title"] = title
        }
        if let author = document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String {
            metadata["author"] = author
        }

        let pageCount = document.pageCount

        // Detect headers/footers
        let headerFooterDetector = HeaderFooterDetector()

        for pageIndex in 0 ..< pageCount {
            guard let page = document.page(at: pageIndex) else {
                warnings.append("Could not read page \(pageIndex + 1)")
                continue
            }

            guard let pageText = page.string else {
                warnings.append("Page \(pageIndex + 1) has no extractable text")
                fullText += "\n[PAGE \(pageIndex + 1)]\n"
                pageBreaks.append(fullText.utf8.count)
                continue
            }

            // Clean and normalize
            var cleanedText = normalizeText(pageText)

            // Detect and mark headers/footers
            headerFooterDetector.addPage(cleanedText)

            // Add page marker
            fullText += "\n[PAGE \(pageIndex + 1)]\n"
            pageBreaks.append(fullText.utf8.count)

            // Detect multi-column layout
            if appearsMultiColumn(cleanedText) {
                warnings.append("Page \(pageIndex + 1) appears to have multiple columns")
                cleanedText = reorderMultiColumn(cleanedText)
            }

            fullText += cleanedText
        }

        // Remove repeating headers/footers
        let (finalText, removedLines) = headerFooterDetector.removeRepeatingLines(from: fullText)
        if !removedLines.isEmpty {
            warnings.append("Removed \(removedLines.count) repeating header/footer lines")
        }

        return ExtractedPDFText(
            text: finalText,
            pageCount: pageCount,
            pageBreaks: pageBreaks,
            metadata: metadata,
            warnings: warnings
        )
    }

    private func normalizeText(_ text: String) -> String {
        var result = text

        // Normalize unicode
        result = result.precomposedStringWithCanonicalMapping

        // Fix common PDF extraction issues
        result = result.replacingOccurrences(of: "\r\n", with: "\n")
        result = result.replacingOccurrences(of: "\r", with: "\n")

        // Remove zero-width characters
        result = result.replacingOccurrences(of: "\u{200B}", with: "") // zero-width space
        result = result.replacingOccurrences(of: "\u{FEFF}", with: "") // BOM

        // Collapse multiple spaces but preserve newlines
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        result = lines.map { line in
            line.split(separator: " ", omittingEmptySubsequences: false)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }.joined(separator: "\n")

        return result
    }

    private func appearsMultiColumn(_ text: String) -> Bool {
        // Simple heuristic: if lines are very short on average, likely multi-column
        let lines = text.split(separator: "\n")
        guard lines.count > 10 else { return false }

        let avgLength = lines.map(\.count).reduce(0, +) / lines.count
        return avgLength < 40 // threshold
    }

    private func reorderMultiColumn(_ text: String) -> String {
        // Very basic: assume 2-column, split at midpoint
        // Production system would use layout analysis
        let lines = text.split(separator: "\n")

        var leftColumn: [String] = []
        var rightColumn: [String] = []

        for line in lines {
            let mid = line.count / 2
            if mid > 0 {
                let left = String(line.prefix(mid)).trimmingCharacters(in: .whitespaces)
                let right = String(line.suffix(from: line.index(line.startIndex, offsetBy: mid)))
                    .trimmingCharacters(in: .whitespaces)
                leftColumn.append(left)
                rightColumn.append(right)
            } else {
                leftColumn.append(String(line))
            }
        }

        return leftColumn.joined(separator: "\n") + "\n\n" + rightColumn.joined(separator: "\n")
    }
}

/// Detects repeating headers/footers across pages
private class HeaderFooterDetector {
    private var pageSamples: [String] = []

    func addPage(_ text: String) {
        // Keep first/last 3 lines of each page
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let sample = Array(lines.prefix(3)) + Array(lines.suffix(3))
        pageSamples.append(sample.joined(separator: "\n"))
    }

    func removeRepeatingLines(from text: String) -> (result: String, removedLines: [String]) {
        // Find lines that appear in 80%+ of pages
        var lineCounts: [String: Int] = [:]

        for sample in pageSamples {
            let lines = Set(sample.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) })
            for line in lines where !line.isEmpty {
                lineCounts[line, default: 0] += 1
            }
        }

        let threshold = Int(Double(pageSamples.count) * 0.8)
        let repeatingLines = lineCounts.filter { $0.value >= threshold }.map(\.key)

        guard !repeatingLines.isEmpty else {
            return (text, [])
        }

        // Remove repeating lines
        var result = text
        for line in repeatingLines {
            result = result.replacingOccurrences(of: line + "\n", with: "")
            result = result.replacingOccurrences(of: "\n" + line, with: "")
        }

        return (result, repeatingLines)
    }
}

public enum PDFExtractionError: Error, LocalizedError {
    case cannotOpenDocument
    case noTextContent
    case malformedStructure

    public var errorDescription: String? {
        switch self {
        case .cannotOpenDocument: "Cannot open PDF document"
        case .noTextContent: "PDF contains no extractable text"
        case .malformedStructure: "PDF structure is malformed"
        }
    }
}
