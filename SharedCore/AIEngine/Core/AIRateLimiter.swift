//
// AIRateLimiter.swift
// Global rate limiting with circuit breaker and exponential backoff
//

import Foundation
import OSLog

/// Rate limiter with global and per-port budgets
public actor AIRateLimiter {
    // Global limits
    private let globalRequestsPerMinute: Int
    private let burstBudget: Int
    
    // Per-port budgets
    private let perPortRequestsPerMinute: Int
    
    // Circuit breaker
    private let maxConsecutiveFailures: Int
    private var consecutiveFailures: [String: Int] = [:] // portID -> count
    private var circuitOpenUntil: [String: Date] = [:] // portID -> reopen time
    
    // Tracking
    private var globalRequests: [(portID: String, timestamp: Date)] = []
    private var portRequests: [String: [Date]] = [:] // portID -> timestamps
    
    private let logger = Logger(subsystem: "com.itori.app", category: "AIRateLimit")
    
    public init(
        globalRequestsPerMinute: Int = 30,
        perPortRequestsPerMinute: Int = 10,
        burstBudget: Int = 5,
        maxConsecutiveFailures: Int = 3
    ) {
        self.globalRequestsPerMinute = globalRequestsPerMinute
        self.perPortRequestsPerMinute = perPortRequestsPerMinute
        self.burstBudget = burstBudget
        self.maxConsecutiveFailures = maxConsecutiveFailures
    }
    
    /// Check if a request is allowed
    public func allowRequest(for portID: String) -> Bool {
        let now = Date()
        
        // Check circuit breaker
        if let openUntil = circuitOpenUntil[portID], now < openUntil {
            logger.warning("Circuit breaker open for port \(portID), rejecting request")
            return false
        }
        
        // Clean old requests (> 1 minute ago)
        cleanOldRequests(before: now.addingTimeInterval(-60))
        
        // Check global limit
        let recentGlobalCount = globalRequests.filter { now.timeIntervalSince($0.timestamp) < 60 }.count
        if recentGlobalCount >= globalRequestsPerMinute {
            logger.warning("Global rate limit exceeded: \(recentGlobalCount)/\(self.globalRequestsPerMinute)")
            return false
        }
        
        // Check per-port limit
        let portRequestList = portRequests[portID] ?? []
        let recentPortCount = portRequestList.filter { now.timeIntervalSince($0) < 60 }.count
        if recentPortCount >= perPortRequestsPerMinute {
            logger.warning("Port rate limit exceeded for \(portID): \(recentPortCount)/\(self.perPortRequestsPerMinute)")
            return false
        }
        
        // Allow burst
        if recentGlobalCount >= (globalRequestsPerMinute - burstBudget) {
            logger.info("Using burst budget: \(recentGlobalCount)/\(self.globalRequestsPerMinute)")
        }
        
        // Record request
        globalRequests.append((portID, now))
        portRequests[portID, default: []].append(now)
        
        return true
    }
    
    /// Record a successful request
    public func recordSuccess(for portID: String) {
        consecutiveFailures[portID] = 0
        
        // Close circuit if it was open
        if circuitOpenUntil[portID] != nil {
            circuitOpenUntil.removeValue(forKey: portID)
            logger.info("Circuit breaker closed for \(portID)")
        }
    }
    
    /// Record a failed request (triggers circuit breaker)
    public func recordFailure(for portID: String) {
        let current = consecutiveFailures[portID, default: 0]
        consecutiveFailures[portID] = current + 1
        
        if current + 1 >= maxConsecutiveFailures {
            // Open circuit breaker with exponential backoff
            let backoffSeconds = min(300, pow(2.0, Double(current))) // max 5 min
            let reopenTime = Date().addingTimeInterval(backoffSeconds)
            circuitOpenUntil[portID] = reopenTime
            
            logger.error("Circuit breaker opened for \(portID) after \(current + 1) failures, will retry at \(reopenTime)")
        }
    }
    
    private func cleanOldRequests(before cutoff: Date) {
        globalRequests.removeAll { $0.timestamp < cutoff }
        
        for (portID, timestamps) in portRequests {
            portRequests[portID] = timestamps.filter { $0 >= cutoff }
        }
    }
    
    /// Get current statistics
    public func statistics() -> AIRateLimiterStatistics {
        let now = Date()
        let recentGlobalCount = globalRequests.filter { now.timeIntervalSince($0.timestamp) < 60 }.count
        
        var portStats: [String: Int] = [:]
        for (portID, timestamps) in portRequests {
            portStats[portID] = timestamps.filter { now.timeIntervalSince($0) < 60 }.count
        }
        
        var openCircuits: [String] = []
        for (portID, reopenTime) in circuitOpenUntil where now < reopenTime {
            openCircuits.append(portID)
        }
        
        return AIRateLimiterStatistics(
            globalRequestsLastMinute: recentGlobalCount,
            globalLimit: globalRequestsPerMinute,
            portRequestsLastMinute: portStats,
            openCircuits: openCircuits
        )
    }
    
    /// Reset all limits (for testing)
    public func reset() {
        globalRequests.removeAll()
        portRequests.removeAll()
        consecutiveFailures.removeAll()
        circuitOpenUntil.removeAll()
    }
}

public struct AIRateLimiterStatistics: Codable, Sendable {
    public let globalRequestsLastMinute: Int
    public let globalLimit: Int
    public let portRequestsLastMinute: [String: Int]
    public let openCircuits: [String]
}
