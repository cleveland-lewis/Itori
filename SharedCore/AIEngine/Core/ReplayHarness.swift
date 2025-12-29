import Foundation

public struct AIPortReplayRecord: Sendable {
    public let port: AIPortID
    public let inputJSON: Data
    public let inputHash: String
    public let timestamp: Date
}

public struct AIPortReplayResult: Sendable {
    public let port: AIPortID
    public let inputHash: String
    public let providerID: AIProviderID?
    public let providerOutputJSON: String?
    public let providerError: String?
    public let fallbackOutputJSON: String?
    public let fallbackError: String?
    public let outputsMatch: Bool?
    public let timestamp: Date
}

#if DEBUG
final class AIPortReplayStore {
    static let shared = AIPortReplayStore()
    
    private let maxRecordsPerPort = 20
    private var records: [AIPortID: [AIPortReplayRecord]] = [:]
    private let lock = NSLock()
    
    func recordInput(port: AIPortID, inputJSON: Data, inputHash: String) {
        let record = AIPortReplayRecord(
            port: port,
            inputJSON: inputJSON,
            inputHash: inputHash,
            timestamp: Date()
        )
        
        lock.lock()
        defer { lock.unlock() }
        
        var existing = records[port] ?? []
        existing.append(record)
        if existing.count > maxRecordsPerPort {
            existing = Array(existing.suffix(maxRecordsPerPort))
        }
        records[port] = existing
    }
    
    func record(for port: AIPortID, index: Int) -> AIPortReplayRecord? {
        lock.lock()
        defer { lock.unlock() }
        guard let list = records[port], !list.isEmpty else { return nil }
        let safeIndex = max(0, min(index, list.count - 1))
        return list[list.count - 1 - safeIndex]
    }
}
#else
final class AIPortReplayStore {
    static let shared = AIPortReplayStore()
    func recordInput(port: AIPortID, inputJSON: Data, inputHash: String) {}
    func record(for port: AIPortID, index: Int) -> AIPortReplayRecord? { nil }
}
#endif
