//
// AIAuditLog.swift
// Non-blocking, bounded audit log for AI operations
//

import Foundation
import OSLog

/// Audit log entry - contains hashes, not raw data
public struct AIAuditEntry: Codable, Sendable {
    public let timestamp: Date
    public let requestID: UUID
    public let portID: String
    public let providerID: String
    public let fallbackUsed: Bool
    public let latencyMs: Int
    public let success: Bool
    public let errorCode: String?
    public let confidence: Double?
    public let inputHash: String
    public let outputHash: String?
    public let redactionDelta: Int // bytes removed
    
    public init(
        timestamp: Date,
        requestID: UUID,
        portID: String,
        providerID: String,
        fallbackUsed: Bool,
        latencyMs: Int,
        success: Bool,
        errorCode: String? = nil,
        confidence: Double? = nil,
        inputHash: String,
        outputHash: String? = nil,
        redactionDelta: Int = 0
    ) {
        self.timestamp = timestamp
        self.requestID = requestID
        self.portID = portID
        self.providerID = providerID
        self.fallbackUsed = fallbackUsed
        self.latencyMs = latencyMs
        self.success = success
        self.errorCode = errorCode
        self.confidence = confidence
        self.inputHash = inputHash
        self.outputHash = outputHash
        self.redactionDelta = redactionDelta
    }
}

/// Non-blocking audit logger with ring buffer
public actor AIAuditLog {
    private let maxEntries: Int
    private let maxFileSizeBytes: Int
    private var entries: [AIAuditEntry] = []
    private let fileURL: URL
    private let logger = Logger(subsystem: "com.roots.app", category: "AIAudit")
    
    public init(maxEntries: Int = 1000, maxFileSizeBytes: Int = 5_000_000) {
        self.maxEntries = maxEntries
        self.maxFileSizeBytes = maxFileSizeBytes
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = docs.appendingPathComponent("ai_audit.jsonl")
        
        Task {
            await loadEntries()
        }
    }
    
    /// Log an entry asynchronously (never blocks caller)
    public func log(_ entry: AIAuditEntry) {
        Task {
            await appendEntry(entry)
        }
    }
    
    private func appendEntry(_ entry: AIAuditEntry) async {
        entries.append(entry)
        
        // Ring buffer: keep only recent entries
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        
        // Log to system
        logger.info("AI Request: port=\(entry.portID) provider=\(entry.providerID) latency=\(entry.latencyMs)ms success=\(entry.success) fallback=\(entry.fallbackUsed)")
        
        // Async write to disk
        await persistEntries()
    }
    
    private func persistEntries() async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            var data = Data()
            for entry in entries {
                let line = try encoder.encode(entry)
                data.append(line)
                data.append("\n".data(using: .utf8)!)
            }
            
            // Check size limit
            if data.count > maxFileSizeBytes {
                // Keep only recent half
                let keep = entries.suffix(maxEntries / 2)
                entries = Array(keep)
                await persistEntries() // recursive call with smaller dataset
                return
            }
            
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Failed to persist audit log: \(error.localizedDescription)")
        }
    }
    
    private func loadEntries() async {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            
            let data = try Data(contentsOf: fileURL)
            let lines = String(data: data, encoding: .utf8)?.split(separator: "\n") ?? []
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            entries = lines.compactMap { line in
                try? decoder.decode(AIAuditEntry.self, from: Data(line.utf8))
            }
            
            logger.info("Loaded \(self.entries.count) audit entries")
        } catch {
            logger.error("Failed to load audit log: \(error.localizedDescription)")
        }
    }
    
    /// Get recent entries (for diagnostics)
    public func recentEntries(limit: Int = 100) -> [AIAuditEntry] {
        Array(entries.suffix(limit))
    }
    
    /// Get statistics
    public func statistics() -> AIAuditStatistics {
        let total = entries.count
        let successful = entries.filter { $0.success }.count
        let fallbacks = entries.filter { $0.fallbackUsed }.count
        let avgLatency = entries.isEmpty ? 0 : entries.map { $0.latencyMs }.reduce(0, +) / entries.count
        
        var portCounts: [String: Int] = [:]
        for entry in entries {
            portCounts[entry.portID, default: 0] += 1
        }
        
        return AIAuditStatistics(
            totalRequests: total,
            successfulRequests: successful,
            fallbackRequests: fallbacks,
            averageLatencyMs: avgLatency,
            portCounts: portCounts
        )
    }
    
    /// Clear all entries
    public func clear() {
        entries.removeAll()
        try? FileManager.default.removeItem(at: fileURL)
        logger.info("Audit log cleared")
    }
}

public struct AIAuditStatistics: Codable, Sendable {
    public let totalRequests: Int
    public let successfulRequests: Int
    public let fallbackRequests: Int
    public let averageLatencyMs: Int
    public let portCounts: [String: Int]
}
