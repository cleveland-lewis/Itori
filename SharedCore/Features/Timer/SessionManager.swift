import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    // MARK: - Published State
    
    @Published private(set) var sessions: [LocalTimerSession] = []
    
    // MARK: - Configuration
    
    private let maxSessionHistoryDays = 400
    private let maxSessionCount = 20000
    private let fileURL: URL
    
    // MARK: - Initialization
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("TimerSessions.json")
    }
    
    // MARK: - Public API
    
    func load() async {
        let url = fileURL
        let maxDays = maxSessionHistoryDays
        let maxCount = maxSessionCount
        
        let finalSessions: [LocalTimerSession] = await Task.detached(priority: .userInitiated) {
            let loadedData: [LocalTimerSession]
            do {
                let data = try Data(contentsOf: url)
                loadedData = try JSONDecoder().decode([LocalTimerSession].self, from: data)
            } catch {
                return []
            }
            
            let cutoff = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date()) ?? .distantPast
            var trimmed = loadedData.filter { session in
                let anchor = session.endDate ?? session.startDate
                return anchor >= cutoff
            }
            
            if trimmed.count > maxCount {
                trimmed.sort { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) }
                trimmed = Array(trimmed.prefix(maxCount)).sorted { $0.startDate < $1.startDate }
            }
            
            if trimmed.count != loadedData.count {
                do {
                    let data = try JSONEncoder().encode(trimmed)
                    try data.write(to: url, options: .atomic)
                } catch {
                    print("Failed to compact timer sessions: \(error)")
                }
            }
            
            return trimmed
        }.value
        
        sessions = finalSessions
    }
    
    func add(_ session: LocalTimerSession) {
        sessions.append(session)
        persist()
    }
    
    func clear() {
        sessions.removeAll()
        persist()
    }
    
    func sessions(for activityID: UUID) -> [LocalTimerSession] {
        sessions.filter { $0.activityID == activityID }
    }
    
    func todaySessions() -> [LocalTimerSession] {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { session in
            let sessionDate = Calendar.current.startOfDay(for: session.startDate)
            return sessionDate == today
        }
    }
    
    func resetAll() {
        sessions.removeAll()
    }
    
    // MARK: - Private Persistence
    
    private func persist() {
        let snapshot = sessions
        let url = fileURL
        
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to persist timer sessions: \(error)")
            }
        }
    }
}
